package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/apps/csvgenerator/folderCsvServlet")
public class FolderCsvServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static volatile boolean dbOffline = false;

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String folderName = request.getParameter("folder");
        if (folderName == null || folderName.trim().isEmpty()) {
            response.sendRedirect("/apps/apps/csvgenerator/fileListServlet");
            return;
        }

        String deployPath = getServletContext()
                              .getRealPath("/apps/csvgenerator/csvfiles/" + folderName);
        File deployFolder = new File(deployPath);

        Set<String> fileSet = new LinkedHashSet<>();
        if (deployFolder.exists() && deployFolder.isDirectory()) {
            File[] files = deployFolder.listFiles();
            if (files != null) {
                for (File f : files) {
                    if (f.getName().toLowerCase().endsWith(".csv")) {
                        fileSet.add(f.getName());
                    }
                }
            }
        }

        List<String> allDiskFiles = new ArrayList<>(fileSet);
        Collections.sort(allDiskFiles);

        Map<String, String>             descriptions = new LinkedHashMap<>();
        Map<String, Map<String,String>> statusMap    = new LinkedHashMap<>();

        // Try DB query if DB is not marked offline
        if (!dbOffline) {
            Connection con = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            try {
                con = DBConnection.getConnection();

                ps = con.prepareStatement(
                    "SELECT file_name, description FROM csv_files WHERE folder_name = ?"
                );
                ps.setString(1, folderName);
                rs = ps.executeQuery();
                while (rs.next()) {
                    descriptions.put(rs.getString("file_name"), rs.getString("description"));
                }
                rs.close(); ps.close();

                ps = con.prepareStatement(
                    "SELECT file_name, status, " +
                    "DATE_FORMAT(created_at,  '%d %b %Y|%H:%i:%s') AS createdAt, " +
                    "DATE_FORMAT(modified_at, '%d %b %Y|%H:%i:%s') AS modifiedAt, " +
                    "total_rows, processed_rows " +
                    "FROM csv_generation_status WHERE folder_name = ?"
                );
                ps.setString(1, folderName);
                rs = ps.executeQuery();
                while (rs.next()) {
                    String fn = rs.getString("file_name");
                    Map<String,String> info = new HashMap<>();
                    info.put("status",        rs.getString("status"));
                    info.put("createdAt",     rs.getString("createdAt"));
                    info.put("modifiedAt",    rs.getString("modifiedAt"));
                    info.put("totalRows",     String.valueOf(rs.getInt("total_rows")));
                    info.put("processedRows", String.valueOf(rs.getInt("processed_rows")));
                    statusMap.put(fn, info);
                }

            } catch (Exception e) {
                dbOffline = true;
                System.out.println("[FolderCsvServlet] MySQL unavailable, falling back to StatusStore.");
            } finally {
                try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
                try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
                try { if (con != null) con.close(); } catch (Exception ignored) {}
            }
        }

        // Overlay in-memory StatusStore data for real-time responsiveness
        for (String fn : allDiskFiles) {
            StatusStore.StatusInfo memInfo = StatusStore.get(folderName, fn);
            if (memInfo != null) {
                Map<String, String> info = statusMap.computeIfAbsent(fn, k -> new HashMap<>());
                info.put("status", memInfo.status);
                info.put("createdAt", memInfo.createdAt);
                info.put("modifiedAt", memInfo.modifiedAt);
                info.put("totalRows", String.valueOf(memInfo.totalRows));
                info.put("processedRows", String.valueOf(memInfo.processedRows));
            }
        }

        // Build pending files list for dropdown
        List<String> pendingFiles = new ArrayList<>();
        for (String fileName : allDiskFiles) {
            Map<String,String> info = statusMap.get(fileName);
            String st = (info != null) ? info.get("status") : null;
            if (!"generated".equals(st) && !"generating".equals(st)) {
                pendingFiles.add(fileName);
            }
        }

        request.setAttribute("allFiles",     allDiskFiles);
        request.setAttribute("pendingFiles", pendingFiles);
        request.setAttribute("descriptions", descriptions);
        request.setAttribute("statusMap",    statusMap);
        request.setAttribute("folder",       folderName);

        request.getRequestDispatcher("/apps/csvgenerator/folder.jsp")
               .forward(request, response);
    }
}
