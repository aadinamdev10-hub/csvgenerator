package apps.csvgenerator;

import java.io.*;
import java.util.List;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * ViewCsvServlet — uses session cache for instant repeat loading.
 */
@WebServlet("/apps/csvgenerator/viewCsvServlet")
public class ViewCsvServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String folderName = request.getParameter("folder");
        String fileName   = request.getParameter("file");

        if (folderName == null || fileName == null ||
            folderName.trim().isEmpty() || fileName.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                               "Invalid request: missing folder or file.");
            return;
        }

        folderName = folderName.trim();
        fileName   = fileName.trim();

        // BUG FIX: path-traversal guard
        if (folderName.contains("..") || fileName.contains("..")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid path.");
            return;
        }

        // Try session cache first (fast path)
        // BUG FIX: session key now includes full folder name without stripping extension
        //          to avoid collision between same-named files in different folders
        String cacheKey = sessionKey(folderName, fileName);

        @SuppressWarnings("unchecked")
        List<List<String>> rows = (List<List<String>>) request.getSession()
                                    .getAttribute(cacheKey);

        // Fallback: read from disk if not cached
        if (rows == null) {
            String root = getServletContext().getRealPath("/apps/csvgenerator/csvfiles");
            File csvFile = new File(root
                             + File.separator + folderName
                             + File.separator + fileName);

            if (!csvFile.exists() || !csvFile.isFile()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND,
                                   "File not found: " + csvFile.getAbsolutePath());
                return;
            }

            rows = CsvReader.readCSV(csvFile.getAbsolutePath());
            request.getSession().setAttribute(cacheKey, rows);
        }

        System.out.println("[ViewCsvServlet] Loaded " + rows.size()
                         + " rows for " + folderName + "/" + fileName);

        // Fetch description from DB
        String description = "";
        try (java.sql.Connection con = DBConnection.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(
                 "SELECT description FROM csv_files WHERE folder_name = ? AND file_name = ?"
             )) {
            ps.setString(1, folderName);
            ps.setString(2, fileName);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    description = rs.getString("description");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("rows",       rows);
        request.setAttribute("fileName",   fileName);
        request.setAttribute("folderName", folderName);
        request.setAttribute("description", description != null ? description : "");

        request.getRequestDispatcher("/apps/csvgenerator/view.jsp")
               .forward(request, response);
    }

    /**
     * BUG FIX: Session key uses full fileName (no extension stripping) and
     * separates folder/file clearly to prevent key collisions.
     * e.g. "folder_A" + "report.csv" → "csv::folder_A::report.csv"
     */
    public static String sessionKey(String folder, String fileName) {
        return "csv::" + folder + "::" + fileName;
    }
}
