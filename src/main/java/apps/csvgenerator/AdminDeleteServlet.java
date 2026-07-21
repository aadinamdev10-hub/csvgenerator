package apps.csvgenerator;

import java.io.*;
import java.net.URLEncoder;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/apps/csvgenerator/AdminDeleteServlet")
public class AdminDeleteServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String folderName = request.getParameter("folder");
        String fileName   = request.getParameter("file");

        if (folderName == null || folderName.trim().isEmpty() ||
            fileName   == null || fileName.trim().isEmpty()) {
            response.sendRedirect("/apps/apps/csvgenerator/admin_index.jsp?error=2");
            return;
        }

        folderName = folderName.trim();
        fileName   = fileName.trim();

        // --- 1. Delete from Tomcat deployed path ---
        String filePath = getServletContext()
                .getRealPath("/apps/csvgenerator/csvfiles/" + folderName + "/" + fileName);
        File csvFile = new File(filePath);

        if (csvFile.exists()) {
            boolean deleted = csvFile.delete();
            System.out.println("[AdminDeleteServlet] Deploy path delete: "
                + filePath + " → " + deleted);
        }

        // --- 2. Delete from database ---
        Connection con = null;
        PreparedStatement ps = null;
        try {
            con = DBConnection.getConnection();

            // Remove from csv_files
            ps = con.prepareStatement(
                "DELETE FROM csv_files WHERE folder_name = ? AND file_name = ?");
            ps.setString(1, folderName);
            ps.setString(2, fileName);
            ps.executeUpdate();
            ps.close();
            ps = null;

            // Remove from csv_generation_status
            ps = con.prepareStatement(
                "DELETE FROM csv_generation_status WHERE folder_name = ? AND file_name = ?");
            ps.setString(1, folderName);
            ps.setString(2, fileName);
            ps.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
            String encodedFolder = URLEncoder.encode(folderName, "UTF-8");
            response.sendRedirect(request.getContextPath()
                + "/apps/csvgenerator/AdminFolderServlet?folder=" + encodedFolder + "&error=delete");
            return;
        } finally {
            try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }

        // --- 3. Redirect back to the folder ---
        String encodedFolder = URLEncoder.encode(folderName, "UTF-8");
        response.sendRedirect(request.getContextPath()
            + "/apps/csvgenerator/AdminFolderServlet?folder=" + encodedFolder + "&deleted=1");
    }
}
