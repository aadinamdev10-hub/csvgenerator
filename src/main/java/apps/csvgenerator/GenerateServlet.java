package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * GenerateServlet
 * URL: /apps/csvgenerator/generateServlet?folder=FOLDER&file=FILENAME
 *
 * Reads the uploaded CSV file line by line in a background thread.
 * Updates progress in DB / StatusStore every N rows.
 * User can leave the page — generation continues in background.
 */
@WebServlet(urlPatterns = "/apps/csvgenerator/generateServlet", asyncSupported = true)
public class GenerateServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // Update progress every N rows
    private static final int DB_UPDATE_INTERVAL = 100;

    // Circuit breaker: Disable DB queries if MySQL is not available to avoid pool timeouts
    private static volatile boolean dbDisabled = false;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String folderName = request.getParameter("folder");
        String fileName   = request.getParameter("file");

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // Validate
        if (isEmpty(folderName) || isEmpty(fileName)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.write("{\"status\":\"error\",\"message\":\"Missing folder or file\"}");
            return;
        }

        // Basic path-traversal guard
        if (folderName.contains("..") || fileName.contains("..")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.write("{\"status\":\"error\",\"message\":\"Invalid path\"}");
            return;
        }

        File csvFile = findCsvFile(folderName, fileName);
        if (csvFile == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.write("{\"status\":\"error\",\"message\":\"CSV file not found on disk\"}");
            return;
        }

        System.out.println("[GenerateServlet] Found CSV at: " + csvFile.getAbsolutePath());

        int totalRows = countRows(csvFile);
        if (totalRows < 0) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.write("{\"status\":\"error\",\"message\":\"Could not count rows\"}");
            return;
        }

        System.out.println("[GenerateServlet] Starting -> folder=" + folderName
                + " | file=" + fileName + " | totalRows=" + totalRows);

        String nowStr = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());

        // Respond immediately so UI updates instantly (0ms delay)
        out.write("{\"status\":\"started\","
                + "\"totalRows\":" + totalRows + ","
                + "\"description\":\"\","
                + "\"file\":\"" + fileName + "\"}");
        out.flush();

        // Process CSV asynchronously in background thread
        AsyncContext asyncContext = request.startAsync();
        asyncContext.setTimeout(0);

        final String finalFolder   = folderName;
        final String finalFileName = fileName;
        final File   finalCsvFile  = csvFile;
        final int    finalTotal    = totalRows;
        final String finalNow      = nowStr;

        new Thread(() -> {
            try {
                markGenerating(finalFolder, finalFileName, finalTotal, finalNow);
                processCSV(finalCsvFile, finalFolder, finalFileName, finalTotal);

                String ts = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
                markGenerated(finalFolder, finalFileName, finalTotal, ts);

                System.out.println("[GenerateServlet] Done: " + finalFileName);

            } catch (Exception e) {
                e.printStackTrace();
                markError(finalFolder, finalFileName);
            } finally {
                asyncContext.complete();
            }
        }).start();
    }

    private File findCsvFile(String folderName, String fileName) {
        String deployBase = getServletContext().getRealPath("/apps/csvgenerator/csvfiles");
        File f = new File(deployBase
            + File.separator + folderName
            + File.separator + fileName);
        return (f.exists() && f.isFile()) ? f : null;
    }

    private int countRows(File file) {
        int count = 0;
        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(new FileInputStream(file), "UTF-8"))) {
            String line;
            boolean firstLine = true;
            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                if (firstLine) { firstLine = false; continue; }
                count++;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
        return count;
    }

    private void processCSV(File csvFile, String folderName,
                            String fileName, int totalRows) throws Exception {

        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(new FileInputStream(csvFile), "UTF-8"))) {

            String line;
            int processed = 0;
            boolean firstLine = true;

            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                if (firstLine) { firstLine = false; continue; }

                processed++;

                if (processed % DB_UPDATE_INTERVAL == 0) {
                    updateProgress(folderName, fileName, processed);
                }
            }

            updateProgress(folderName, fileName, processed);
        }
    }

    private void markGenerating(String folder, String file,
                                int totalRows, String now) {
        StatusStore.StatusInfo info = new StatusStore.StatusInfo();
        info.status = "generating";
        info.totalRows = totalRows;
        info.processedRows = 0;
        info.createdAt = now;
        info.modifiedAt = now;
        StatusStore.put(folder, file, info);

        exec(
            "CREATE TABLE IF NOT EXISTS csv_generation_status (" +
            "  id INT AUTO_INCREMENT PRIMARY KEY, " +
            "  folder_name VARCHAR(255) NOT NULL, " +
            "  file_name VARCHAR(255) NOT NULL, " +
            "  status VARCHAR(50) NOT NULL DEFAULT 'pending', " +
            "  total_rows INT DEFAULT 0, " +
            "  processed_rows INT DEFAULT 0, " +
            "  created_at DATETIME, " +
            "  modified_at DATETIME, " +
            "  UNIQUE KEY uk_folder_file (folder_name, file_name)" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );
        exec(
            "INSERT INTO csv_generation_status " +
            "  (folder_name, file_name, status, total_rows, processed_rows, created_at, modified_at) " +
            "VALUES (?, ?, 'generating', ?, 0, ?, ?) " +
            "ON DUPLICATE KEY UPDATE " +
            "  status='generating', total_rows=VALUES(total_rows), " +
            "  processed_rows=0, created_at=?, modified_at=?",
            folder, file, String.valueOf(totalRows), now, now, now, now
        );
    }

    private void updateProgress(String folder, String file, int processed) {
        StatusStore.StatusInfo info = StatusStore.get(folder, file);
        if (info != null) {
            info.processedRows = processed;
            info.modifiedAt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
        }

        exec(
            "UPDATE csv_generation_status " +
            "SET processed_rows=?, modified_at=NOW() " +
            "WHERE folder_name=? AND file_name=?",
            String.valueOf(processed), folder, file
        );
    }

    private void markGenerated(String folder, String file,
                               int total, String ts) {
        StatusStore.StatusInfo info = StatusStore.get(folder, file);
        if (info != null) {
            info.status = "generated";
            info.processedRows = total;
            info.modifiedAt = ts;
        }

        exec(
            "UPDATE csv_generation_status " +
            "SET status='generated', processed_rows=?, " +
            "    created_at=IFNULL(created_at,?), modified_at=? " +
            "WHERE folder_name=? AND file_name=?",
            String.valueOf(total), ts, ts, folder, file
        );
    }

    private void markError(String folder, String file) {
        StatusStore.StatusInfo info = StatusStore.get(folder, file);
        if (info != null) {
            info.status = "error";
        }

        exec(
            "UPDATE csv_generation_status SET status='error', modified_at=NOW() " +
            "WHERE folder_name=? AND file_name=?",
            folder, file
        );
    }

    private void exec(String sql, String... params) {
        if (dbDisabled) return; // Circuit breaker: skip DB calls if MySQL is unreachable

        Connection con = null;
        PreparedStatement ps = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            for (int i = 0; i < params.length; i++) ps.setString(i + 1, params[i]);
            ps.executeUpdate();
        } catch (Exception e) {
            dbDisabled = true; // Disable DB queries to prevent pool timeout logs
            System.out.println("[GenerateServlet] MySQL unavailable. Using in-memory StatusStore (no further DB queries).");
        } finally {
            try { if (ps  != null) ps.close(); } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }
    }

    private boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
}
