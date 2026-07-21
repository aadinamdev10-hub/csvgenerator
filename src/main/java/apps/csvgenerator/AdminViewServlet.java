package apps.csvgenerator;

import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/apps/csvgenerator/AdminViewServlet")
public class AdminViewServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String folder = request.getParameter("folder");
        String file   = request.getParameter("file");

        if (folder == null || folder.trim().isEmpty() ||
            file   == null || file.trim().isEmpty()) {
            response.sendRedirect("/apps/apps/csvgenerator/admin_index.jsp");
            return;
        }

        folder = folder.trim();
        file   = file.trim();

        String filePath = getServletContext()
                .getRealPath("/apps/csvgenerator/csvfiles/" + folder + "/" + file);

        File csvFile = new File(filePath);

        List<List<String>> csvData = new ArrayList<>();

        if (csvFile.exists() && csvFile.isFile()) {
            csvData = readCSV(csvFile);
        } else {
            System.err.println("[AdminViewServlet] CSV not found: " + filePath);
        }

        // Fetch description from DB
        String description = "";
        try (java.sql.Connection con = DBConnection.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(
                 "SELECT description FROM csv_files WHERE folder_name = ? AND file_name = ?"
             )) {
            ps.setString(1, folder);
            ps.setString(2, file);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    description = rs.getString("description");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("csvData",     csvData);
        request.setAttribute("folder",      folder);
        request.setAttribute("file",        file);
        request.setAttribute("description", description != null ? description : "");

        RequestDispatcher rd = request.getRequestDispatcher("/apps/csvgenerator/admin_view.jsp");
        rd.forward(request, response);
    }

    /**
     * RFC-4180-compatible CSV reader.
     * Handles quoted fields (including embedded commas and newlines).
     */
    private List<List<String>> readCSV(File file) throws IOException {
        List<List<String>> rows = new ArrayList<>();

        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(new FileInputStream(file), "UTF-8"))) {

            String line;
            while ((line = br.readLine()) != null) {

                if (line.trim().isEmpty()) continue;

                List<String> row    = new ArrayList<>();
                StringBuilder field = new StringBuilder();
                boolean inQuotes    = false;

                for (int i = 0; i < line.length(); i++) {
                    char c = line.charAt(i);

                    if (inQuotes) {
                        if (c == '"') {
                            if (i + 1 < line.length() && line.charAt(i + 1) == '"') {
                                field.append('"');
                                i++;
                            } else {
                                inQuotes = false;
                            }
                        } else {
                            field.append(c);
                        }
                    } else {
                        if (c == '"') {
                            inQuotes = true;
                        } else if (c == ',') {
                            row.add(field.toString().trim());
                            field.setLength(0);
                        } else {
                            field.append(c);
                        }
                    }
                }
                row.add(field.toString().trim());
                rows.add(row);
            }
        }
        return rows;
    }
}
