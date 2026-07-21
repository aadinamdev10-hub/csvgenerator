package apps.csvgenerator;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class StatusStore {

    public static class StatusInfo {
        public String status = "pending";
        public int totalRows = 0;
        public int processedRows = 0;
        public String createdAt = "";
        public String modifiedAt = "";
    }

    private static final Map<String, StatusInfo> store = new ConcurrentHashMap<>();

    private static String key(String folder, String file) {
        return folder + "::" + file;
    }

    public static StatusInfo get(String folder, String file) {
        return store.get(key(folder, file));
    }

    public static void put(String folder, String file, StatusInfo info) {
        store.put(key(folder, file), info);
    }

    public static Map<String, Integer> getGeneratedCounts() {
        Map<String, Integer> counts = new HashMap<>();
        for (Map.Entry<String, StatusInfo> entry : store.entrySet()) {
            if ("generated".equals(entry.getValue().status)) {
                String[] parts = entry.getKey().split("::");
                if (parts.length > 0) {
                    String folder = parts[0];
                    counts.put(folder, counts.getOrDefault(folder, 0) + 1);
                }
            }
        }
        return counts;
    }
}
