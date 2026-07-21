package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * ViewListServlet
 * URL: /apps/csvgenerator/viewListServlet
 *
 * Returns JSON array of all MySQL VIEW names in the current schema:
 * ["v_booking_report", "v_sales_summary", ...]
 *
 * Called by folder.jsp on page load to populate the view dropdown.
 */
@WebServlet("/apps/csvgenerator/viewListServlet")
public class ViewListServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuilder json = new StringBuilder("[");

        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(
                "SELECT TABLE_NAME " +
                "FROM INFORMATION_SCHEMA.VIEWS " +
                "WHERE TABLE_SCHEMA = DATABASE() " +
                "ORDER BY TABLE_NAME"
            );
            rs = ps.executeQuery();

            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                String name = rs.getString("TABLE_NAME");
                json.append("\"").append(name.replace("\"", "\\\"")).append("\"");
                first = false;
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("{\"error\":\"DB error: " + e.getMessage() + "\"}");
            return;
        } finally {
            try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
            try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }

        json.append("]");
        response.getWriter().write(json.toString());
    }
}
