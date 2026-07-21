package apps.csvgenerator;

import java.sql.Connection;

public class DBConnection {
    public static Connection getConnection() throws Exception {
        Connection con = apps.dbservice.DbConnection.getConnection();
        con.setCatalog("App2026");
        return con;
    }
}
