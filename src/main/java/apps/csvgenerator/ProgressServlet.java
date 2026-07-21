package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * ProgressServlet
 * URL: /apps/csvgenerator/progressServlet?folder=X&file=Y
 *
 * Returns JSON:
 * {
 *   "status"        : "generating" | "generated" | "pending" | "error",
 *   "processedRows" : 1500,
 *   "totalRows"     : 5000,
 *   "percent"       : 30,
 *   "createdAt"     : "29 May 2026|14:30:00",
 *   "modifiedAt"    : "29 May 2026|14:35:00"
 * }
 */
@WebServlet("/apps/csvgenerator/progressServlet")
public class ProgressServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String folder = request.getParameter("folder");
        String file   = request.getParameter("file");

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (folder == null || file == null) {
            response.getWriter().write(
                "{\"status\":\"error\",\"message\":\"Missing params\"}");
            return;
        }

        StatusStore.StatusInfo memInfo = StatusStore.get(folder, file);

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();

            ps = con.prepareStatement(
                "SELECT status, total_rows, processed_rows, " +
                "DATE_FORMAT(created_at,  '%d %b %Y|%H:%i:%s') AS createdAt, " +
                "DATE_FORMAT(modified_at, '%d %b %Y|%H:%i:%s') AS modifiedAt " +
                "FROM csv_generation_status " +
                "WHERE folder_name=? AND file_name=?"
            );
            ps.setString(1, folder);
            ps.setString(2, file);
            rs = ps.executeQuery();

            if (rs.next()) {
                String status     = rs.getString("status");
                int    total      = rs.getInt("total_rows");
                int    processed  = rs.getInt("processed_rows");
                String createdAt  = rs.getString("createdAt");
                String modifiedAt = rs.getString("modifiedAt");

                if (processed > total && total > 0) processed = total;

                int percent = (total > 0)
                    ? (int) Math.round((processed * 100.0) / total)
                    : (("generated".equals(status)) ? 100 : 0);

                String safeCreated  = (createdAt  != null) ? createdAt  : "";
                String safeModified = (modifiedAt != null) ? modifiedAt : "";

                response.getWriter().write(
                    "{\"status\":\""      + status      + "\"," +
                     "\"processedRows\":" + processed   + "," +
                     "\"totalRows\":"     + total       + "," +
                     "\"percent\":"       + percent     + "," +
                     "\"createdAt\":\""   + safeCreated  + "\"," +
                     "\"modifiedAt\":\"" + safeModified + "\"}"
                );
                return;
            }

        } catch (Exception e) {
            System.out.println("[ProgressServlet] DB query exception, using memory fallback: " + e.getMessage());
        } finally {
            try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
            try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }

        // In-memory fallback if DB row not present or DB offline
        if (memInfo != null) {
            int total = memInfo.totalRows;
            int processed = memInfo.processedRows;
            if (processed > total && total > 0) processed = total;
            int percent = (total > 0)
                ? (int) Math.round((processed * 100.0) / total)
                : (("generated".equals(memInfo.status)) ? 100 : 0);

            response.getWriter().write(
                "{\"status\":\""      + memInfo.status      + "\"," +
                 "\"processedRows\":" + processed           + "," +
                 "\"totalRows\":"     + total               + "," +
                 "\"percent\":"       + percent             + "," +
                 "\"createdAt\":\""   + memInfo.createdAt   + "\"," +
                 "\"modifiedAt\":\"" + memInfo.modifiedAt  + "\"}"
            );
        } else {
            response.getWriter().write(
                "{\"status\":\"pending\",\"processedRows\":0," +
                 "\"totalRows\":0,\"percent\":0," +
                 "\"createdAt\":\"\",\"modifiedAt\":\"\"}");
        }
    }
}