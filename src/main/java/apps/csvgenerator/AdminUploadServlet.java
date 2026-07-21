package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;

/**
 * AdminUploadServlet
 * Saves uploaded CSV files to the Tomcat deployed path.
 *
 * NOTE: The original dual-write to a hardcoded Eclipse source path has been
 * removed because it is developer-machine-specific and breaks on any other
 * environment. Files are saved only to the Tomcat getRealPath() location,
 * which is the correct, portable approach.
 */
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize       = 50 * 1024 * 1024,
    maxRequestSize    = 55 * 1024 * 1024
)
@WebServlet("/apps/csvgenerator/AdminUploadServlet")
public class AdminUploadServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Part   filePart  = request.getPart("csvFile");
        String fileName  = (filePart != null) ? getSubmittedFileName(filePart) : null;
        String folderName   = request.getParameter("folderName");
        String description  = request.getParameter("description");

        String ctx = "/apps";

        // Basic validation
        if (fileName == null || fileName.trim().isEmpty()) {
            response.sendRedirect(ctx + "/apps/csvgenerator/admin_index.jsp?error=1");
            return;
        }
        if (folderName == null || folderName.trim().isEmpty()) {
            response.sendRedirect(ctx + "/apps/csvgenerator/admin_index.jsp?error=1");
            return;
        }

        // Sanitize: strip path separators from filename (security)
        fileName   = new File(fileName.trim()).getName();
        folderName = folderName.trim();

        // Validate CSV extension
        if (!fileName.toLowerCase().endsWith(".csv")) {
            response.sendRedirect(ctx + "/apps/csvgenerator/admin_index.jsp?error=1");
            return;
        }

        try {
            // Save to Tomcat deployed path
            String deployPath = getServletContext()
                .getRealPath("/apps/csvgenerator/csvfiles/" + folderName);
            File deployDir = new File(deployPath);
            if (!deployDir.exists()) deployDir.mkdirs();

            String deployFilePath = deployPath + File.separator + fileName;
            filePart.write(deployFilePath);

            System.out.println("[AdminUploadServlet] Saved: " + deployFilePath);

            // Save description + status to DB
            saveToDatabase(folderName, fileName, description);

            response.sendRedirect(ctx + "/apps/csvgenerator/AdminFolderServlet?folder="
                + java.net.URLEncoder.encode(folderName, "UTF-8") + "&success=1");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(ctx + "/apps/csvgenerator/admin_index.jsp?error=1");
        }
    }

    /**
     * Portable filename extraction — Part.getSubmittedFileName() is Servlet 3.1+.
     * Falls back to parsing Content-Disposition for older containers.
     */
    private String getSubmittedFileName(Part part) {
        // Servlet 3.1+ native method
        try {
            java.lang.reflect.Method m = part.getClass().getMethod("getSubmittedFileName");
            Object result = m.invoke(part);
            if (result != null) return result.toString();
        } catch (Exception ignored) {}

        // Fallback: parse Content-Disposition header
        for (String cd : part.getHeader("content-disposition").split(";")) {
            cd = cd.trim();
            if (cd.startsWith("filename")) {
                return cd.substring(cd.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return null;
    }

    private void saveToDatabase(String folderName, String fileName, String description) {
        Connection con = null;
        PreparedStatement ps = null;
        try {
            con = DBConnection.getConnection();

            String sql =
                "INSERT INTO csv_files (folder_name, file_name, description, uploaded_at) " +
                "VALUES (?, ?, ?, NOW()) " +
                "ON DUPLICATE KEY UPDATE description = VALUES(description), uploaded_at = NOW()";
            ps = con.prepareStatement(sql);
            ps.setString(1, folderName);
            ps.setString(2, fileName);
            ps.setString(3, description != null ? description : "");
            ps.executeUpdate();
            ps.close();
            ps = null;

            String sql2 =
                "INSERT INTO csv_generation_status " +
                "  (folder_name, file_name, status, total_rows, processed_rows) " +
                "VALUES (?, ?, 'pending', 0, 0) " +
                "ON DUPLICATE KEY UPDATE " +
                "  status='pending', total_rows=0, processed_rows=0";
            ps = con.prepareStatement(sql2);
            ps.setString(1, folderName);
            ps.setString(2, fileName);
            ps.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }
    }
}
