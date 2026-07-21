package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/apps/csvgenerator/AdminFolderServlet")
public class AdminFolderServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String folderName = request.getParameter("folder");

        if (folderName == null || folderName.trim().isEmpty()) {
            // BUG FIX: use context path so redirect works regardless of deployment root
            response.sendRedirect("/apps/apps/csvgenerator/admin_index.jsp");
            return;
        }

        folderName = folderName.trim();

        // Get CSV files from disk
        String basePath = getServletContext().getRealPath("/apps/csvgenerator/csvfiles/" + folderName);
        File folder = new File(basePath);
        File[] files = folder.listFiles();

        List<String> csvFiles = new ArrayList<>();
        if (files != null) {
            for (File f : files) {
                if (f.getName().toLowerCase().endsWith(".csv")) {
                    csvFiles.add(f.getName());
                }
            }
            Collections.sort(csvFiles);
        }

        // Get descriptions from database
        Map<String, String> descriptions = new HashMap<>();

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();

            String sql = "SELECT file_name, description FROM csv_files WHERE folder_name = ?";
            ps = con.prepareStatement(sql);
            ps.setString(1, folderName);
            rs = ps.executeQuery();

            while (rs.next()) {
                descriptions.put(rs.getString("file_name"), rs.getString("description"));
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
            try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }

        // Set attributes and forward to admin_folder.jsp
        request.setAttribute("folder", folderName);
        request.setAttribute("csvFiles", csvFiles);
        request.setAttribute("descriptions", descriptions);

        RequestDispatcher rd = request.getRequestDispatcher("/apps/csvgenerator/admin_folder.jsp");
        rd.forward(request, response);
    }
}
