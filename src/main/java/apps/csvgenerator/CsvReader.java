package apps.csvgenerator;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class CsvReader {

    public static List<List<String>> readCSV(String filePath) {
        List<List<String>> data = new ArrayList<>();

        try (BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(filePath), "UTF-8"))) {
            List<String> currentRow = new ArrayList<>();
            StringBuilder currentField = new StringBuilder();
            boolean inQuotes = false;
            int c;

            while ((c = br.read()) != -1) {
                char ch = (char) c;

                if (inQuotes) {
                    if (ch == '\"') {
                        // Lookahead for double double-quote ""
                        br.mark(1);
                        int next = br.read();
                        if (next == '\"') {
                            currentField.append('\"');
                        } else {
                            inQuotes = false;
                            if (next != -1) {
                                br.reset();
                            }
                        }
                    } else {
                        currentField.append(ch);
                    }
                } else {
                    if (ch == '\"') {
                        inQuotes = true;
                    } else if (ch == ',') {
                        currentRow.add(currentField.toString().trim());
                        currentField.setLength(0);
                    } else if (ch == '\r') {
                        br.mark(1);
                        int next = br.read();
                        if (next != '\n' && next != -1) {
                            br.reset();
                        }
                        currentRow.add(currentField.toString().trim());
                        currentField.setLength(0);
                        data.add(currentRow);
                        currentRow = new ArrayList<>();
                    } else if (ch == '\n') {
                        currentRow.add(currentField.toString().trim());
                        currentField.setLength(0);
                        data.add(currentRow);
                        currentRow = new ArrayList<>();
                    } else {
                        currentField.append(ch);
                    }
                }
            }

            // Handle trailing fields / records
            if (currentField.length() > 0 || !currentRow.isEmpty()) {
                currentRow.add(currentField.toString().trim());
                data.add(currentRow);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // Clean up empty records at the end
        if (!data.isEmpty()) {
            List<String> lastRow = data.get(data.size() - 1);
            if (lastRow.size() == 1 && lastRow.get(0).isEmpty()) {
                data.remove(data.size() - 1);
            }
        }

        return data;
    }
}