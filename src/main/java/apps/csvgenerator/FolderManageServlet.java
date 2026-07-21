package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * FolderManageServlet
 * Handles create and delete of folders.
 *
 * BUG FIX: Removed hardcoded Eclipse source path — it was developer-machine-specific
 * and caused FileNotFound errors on any other environment. Folders are now created
 * and deleted only under the Tomcat getRealPath() deploy location.
 *
 * POST /apps/csvgenerator/folderManageServlet
 *   action=create  &  folderName=XYZ
 *   action=delete  &  folderName=XYZ
 *
 * Returns JSON:
 *   { "status": "ok",    "message": "Folder created." }
 *   { "status": "error", "message": "Reason here."   }
 */
@WebServlet("/apps/csvgenerator/folderManageServlet")
public class FolderManageServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String action     = request.getParameter("action");
        String folderName = request.getParameter("folderName");

        // Basic validation
        if (action == null || folderName == null || folderName.trim().isEmpty()) {
            writeJson(response, "error", "Missing action or folder name.");
            return;
        }

        folderName = folderName.trim();

        // Only allow letters, digits, underscores, hyphens — no path traversal
        if (!folderName.matches("[\\w\\-]+")) {
            writeJson(response, "error",
                "Invalid folder name. Use only letters, numbers, underscores or hyphens.");
            return;
        }

        // Resolve base path via servlet context (portable — works on any server)
        File baseDir = new File(getServletContext().getRealPath("/apps/csvgenerator/csvfiles"));
        File target  = new File(baseDir, folderName);

        // Prevent path traversal
        if (!target.getCanonicalPath().startsWith(baseDir.getCanonicalPath() + File.separator)
                && !target.getCanonicalPath().equals(baseDir.getCanonicalPath())) {
            writeJson(response, "error", "Invalid folder path.");
            return;
        }

        switch (action) {
            case "create":
                doCreate(target, folderName, response);
                break;
            case "delete":
                doDelete(target, folderName, response);
                break;
            default:
                writeJson(response, "error", "Unknown action: " + action);
        }
    }

    // ── CREATE ────────────────────────────────────────────────────────
    private void doCreate(File target, String folderName,
                          HttpServletResponse response) throws IOException {

        if (target.exists()) {
            writeJson(response, "error", "Folder '" + folderName + "' already exists.");
            return;
        }

        boolean created = target.mkdirs();

        if (created) {
            System.out.println("[FolderManageServlet] Created folder: " + target.getAbsolutePath());
            writeJson(response, "ok", "Folder '" + folderName + "' created successfully.");
        } else {
            writeJson(response, "error", "Failed to create folder. Check server permissions.");
        }
    }

    // ── DELETE ────────────────────────────────────────────────────────
    private void doDelete(File target, String folderName,
                          HttpServletResponse response) throws IOException {

        if (!target.exists()) {
            writeJson(response, "error", "Folder '" + folderName + "' does not exist.");
            return;
        }

        // Count CSV files before deletion
        File[] csvFiles = target.listFiles((d, n) -> n.toLowerCase().endsWith(".csv"));
        int csvCount = (csvFiles != null) ? csvFiles.length : 0;

        boolean deleted = deleteRecursive(target);

        if (deleted) {
            cleanDb(folderName);
            System.out.println("[FolderManageServlet] Deleted folder: "
                + folderName + " (" + csvCount + " CSV files removed)");
            writeJson(response, "ok", "Folder '" + folderName + "' and " + csvCount
                + " file(s) deleted successfully.");
        } else {
            writeJson(response, "error",
                "Could not fully delete folder. Some files may be locked.");
        }
    }

    // Recursively delete a directory and all its contents
    private boolean deleteRecursive(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    if (!deleteRecursive(child)) return false;
                }
            }
        }
        return file.delete();
    }

    // Remove all DB rows for the deleted folder
    private void cleanDb(String folderName) {
        Connection con = null;
        PreparedStatement ps = null;
        try {
            con = DBConnection.getConnection();

            ps = con.prepareStatement(
                "DELETE FROM csv_generation_status WHERE folder_name = ?");
            ps.setString(1, folderName);
            ps.executeUpdate();
            ps.close();
            ps = null;

            ps = con.prepareStatement(
                "DELETE FROM csv_files WHERE folder_name = ?");
            ps.setString(1, folderName);
            ps.executeUpdate();

        } catch (Exception e) {
            System.err.println("[FolderManageServlet] DB cleanup error: " + e.getMessage());
        } finally {
            try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }
    }

    /**
     * Writes a JSON response with proper escaping for both backslash and double-quote.
     * BUG FIX: original only escaped backslash and double-quote but missed other
     * control characters that can break JSON (newline, carriage return, tab).
     */
    private void writeJson(HttpServletResponse response,
                           String status, String message) throws IOException {
        String safe = message
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t");
        response.getWriter().write(
            "{\"status\":\"" + status + "\",\"message\":\"" + safe + "\"}");
    }
}
