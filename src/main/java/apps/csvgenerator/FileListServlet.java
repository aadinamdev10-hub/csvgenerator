package apps.csvgenerator;

import java.io.*;
import java.sql.*;
import java.util.*;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/apps/csvgenerator/fileListServlet")
public class FileListServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static volatile boolean dbOffline = false;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String deployPath = getServletContext().getRealPath("/apps/csvgenerator/csvfiles");
        File deployBase   = new File(deployPath);

        Set<String> folderSet = new LinkedHashSet<>();
        if (deployBase.exists() && deployBase.isDirectory()) {
            File[] dirs = deployBase.listFiles(File::isDirectory);
            if (dirs != null) {
                for (File dir : dirs) {
                    folderSet.add(dir.getName());
                }
            }
        }

        List<String> folderList = new ArrayList<>(folderSet);
        Collections.sort(folderList);

        Map<String, Integer> generatedCountMap = new HashMap<>();

        if (!dbOffline) {
            Connection con = null;
            PreparedStatement ps = null;
            ResultSet rs = null;

            try {
                con = DBConnection.getConnection();
                ps = con.prepareStatement(
                    "SELECT folder_name, COUNT(*) AS cnt " +
                    "FROM csv_generation_status " +
                    "WHERE status = 'generated' " +
                    "GROUP BY folder_name"
                );
                rs = ps.executeQuery();
                while (rs.next()) {
                    generatedCountMap.put(
                        rs.getString("folder_name"),
                        rs.getInt("cnt")
                    );
                }
            } catch (Exception e) {
                dbOffline = true;
                System.out.println("[FileListServlet] MySQL unavailable, using StatusStore counts.");
            } finally {
                try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
                try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
                try { if (con != null) con.close(); } catch (Exception ignored) {}
            }
        }

        // Overlay generated counts from StatusStore so dashboard reflects newly generated files instantly
        Map<String, Integer> memCounts = StatusStore.getGeneratedCounts();
        for (Map.Entry<String, Integer> entry : memCounts.entrySet()) {
            int current = generatedCountMap.getOrDefault(entry.getKey(), 0);
            generatedCountMap.put(entry.getKey(), Math.max(current, entry.getValue()));
        }

        request.setAttribute("folderList",        folderList);
        request.setAttribute("generatedCountMap", generatedCountMap);

        RequestDispatcher rd = request.getRequestDispatcher("/apps/csvgenerator/index.jsp");
        rd.forward(request, response);
    }
}
