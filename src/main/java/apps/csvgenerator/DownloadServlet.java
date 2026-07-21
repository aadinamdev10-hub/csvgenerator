package apps.csvgenerator;

import java.io.*;
import java.util.List;

import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/apps/csvgenerator/download")
public class DownloadServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String folder = request.getParameter("folder");
        String file   = request.getParameter("file");
        String type   = request.getParameter("type");

        // BUG FIX: Validate all required parameters — prevents NullPointerException
        if (folder == null || folder.trim().isEmpty() ||
            file   == null || file.trim().isEmpty()   ||
            type   == null || type.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                               "Missing required parameter: folder, file, or type.");
            return;
        }

        // BUG FIX: Basic path-traversal guard
        if (folder.contains("..") || file.contains("..")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid path.");
            return;
        }

        String path = getServletContext()
                        .getRealPath("/apps/csvgenerator/csvfiles")
                      + File.separator
                      + folder.trim()
                      + File.separator
                      + file.trim();

        File downloadFile = new File(path);

        if (!downloadFile.exists() || !downloadFile.isFile()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,
                               "File not found: " + file);
            return;
        }

        if ("excel".equals(type)) {
            response.setContentType("application/vnd.ms-excel; charset=UTF-8");
            response.setCharacterEncoding("UTF-8");
            response.setHeader("Content-Disposition",
                               "attachment; filename=" + file.replace(".csv", ".xls"));

            List<List<String>> rows = CsvReader.readCSV(downloadFile.getAbsolutePath());
            StringBuilder xml = new StringBuilder();
            xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
            xml.append("<?mso-application progid=\"Excel.Sheet\"?>\n");
            xml.append("<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\"\n");
            xml.append(" xmlns:o=\"urn:schemas-microsoft-com:office:office\"\n");
            xml.append(" xmlns:x=\"urn:schemas-microsoft-com:office:excel\"\n");
            xml.append(" xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\"\n");
            xml.append(" xmlns:html=\"http://www.w3.org/TR/REC-html40\">\n");
            xml.append(" <Styles>\n");
            xml.append("  <Style ss:ID=\"Default\" ss:Name=\"Normal\">\n");
            xml.append("   <Alignment ss:Vertical=\"Bottom\"/>\n");
            xml.append("   <Borders/>\n");
            xml.append("   <Font ss:FontName=\"Segoe UI\" ss:Size=\"11\" ss:Color=\"#333333\"/>\n");
            xml.append("   <Interior/>\n");
            xml.append("   <NumberFormat/>\n");
            xml.append("   <Protection/>\n");
            xml.append("  </Style>\n");
            xml.append("  <Style ss:ID=\"Header\">\n");
            xml.append("   <Font ss:FontName=\"Segoe UI\" ss:Size=\"11\" ss:Bold=\"1\" ss:Color=\"#FFFFFF\"/>\n");
            xml.append("   <Interior ss:Color=\"#1E90FF\" ss:Pattern=\"Solid\"/>\n");
            xml.append("   <Alignment ss:Horizontal=\"Center\" ss:Vertical=\"Center\"/>\n");
            xml.append("  </Style>\n");
            xml.append(" </Styles>\n");

            String sheetName = file.replace(".csv", "");
            if (sheetName.length() > 30) sheetName = sheetName.substring(0, 30);
            sheetName = sheetName.replaceAll("[\\*\\?:/\\\\\\\\[\\\\]]", "_"); // clean illegal chars

            xml.append(" <Worksheet ss:Name=\"").append(sheetName).append("\">\n");
            xml.append("  <Table>\n");

            boolean isHeader = true;
            for (List<String> row : rows) {
                xml.append("   <Row>\n");
                for (String cellValue : row) {
                    String cleanVal = cellValue == null ? "" : cellValue
                        .replace("&", "&amp;")
                        .replace("<", "&lt;")
                        .replace(">", "&gt;")
                        .replace("\"", "&quot;")
                        .replace("'", "&apos;");

                    String style = isHeader ? " ss:StyleID=\"Header\"" : "";
                    
                    // Simple numeric check to render native excel numbers
                    boolean isNumeric = false;
                    if (!isHeader && !cleanVal.isEmpty()) {
                        try {
                            Double.parseDouble(cleanVal);
                            isNumeric = true;
                        } catch (NumberFormatException ignored) {}
                    }

                    if (isNumeric) {
                        xml.append("    <Cell").append(style).append("><Data ss:Type=\"Number\">").append(cleanVal).append("</Data></Cell>\n");
                    } else {
                        xml.append("    <Cell").append(style).append("><Data ss:Type=\"String\">").append(cleanVal).append("</Data></Cell>\n");
                    }
                }
                xml.append("   </Row>\n");
                isHeader = false;
            }

            xml.append("  </Table>\n");
            xml.append("  <WorksheetOptions xmlns=\"urn:schemas-microsoft-com:office:excel\">\n");
            xml.append("   <Selected/>\n");
            xml.append("   <ProtectObjects>False</ProtectObjects>\n");
            xml.append("   <ProtectScenarios>False</ProtectScenarios>\n");
            xml.append("  </WorksheetOptions>\n");
            xml.append(" </Worksheet>\n");
            xml.append("</Workbook>\n");

            byte[] bytes = xml.toString().getBytes("UTF-8");
            response.setContentLength(bytes.length);
            try (OutputStream out = response.getOutputStream()) {
                out.write(bytes);
            }
        } else {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition",
                               "attachment; filename=" + file);
            response.setContentLengthLong(downloadFile.length());

            // BUG FIX: try-with-resources ensures streams close even on exception
            try (FileInputStream inStream  = new FileInputStream(downloadFile);
                 OutputStream    outStream = response.getOutputStream()) {

                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = inStream.read(buffer)) != -1) {
                    outStream.write(buffer, 0, bytesRead);
                }
            }
        }
    }
}
