import java.sql.*;

public class DBConnection {

    //jdbc:postgresql:database
    //jdbc:postgresql://host/database
    //jdbc:postgresql://host:port/database
    //port = 5432
	public static final String URL      = "jdbc:postgresql:metradb.cycty0ftp5lo.us-west-2.rds.amazonaws.com:5432";
	public static final String DRIVER   = "org.postgresql.Driver";
    public static final String UID      = "";
    public static final String PASSWORD = "";

    private Connection con = null;

    public DBConnection() {
    }

    public void connect() {
        try {
            Class.forName(DRIVER);
            this.con = DriverManager.getConnection(URL, UID, PASSWORD);
        } catch(ClassNotFoundException e) {
            System.err.println("ClassNotFoundException: " + e.getMessage());
            this.con = null;
        } catch(SQLException e) {
            System.err.println("SQLException: " + e.getMessage());
            this.con = null;
        }
    }

    public void disconnect() {
        try {
            this.con.close();
        } catch (SQLException e) {
            System.err.println("SQLException: " + e.getMessage());
        }
    }

    public Connection getConnection() {
        return this.con;
    }
    
}
