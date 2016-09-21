import java.sql.*;
import java.io.*;
import java.util.*;
import java.text.SimpleDateFormat;

public class RideSharing {

    private DBConnection db;

    public RideSharing() {
        this.db = new DBConnection();
		this.db.connect();
    }

    public void add_request(int pid, int num_riders, float pickup_lat, float pickup_lon, float dropoff_lat, float dropoff_lon) {
        //create a new rides tuple for a requested ride
        try {
            String sql = "INSERT INTO rides VALUES(DEFAULT, ?, NULL, ?, ?, ?, ?, ?, DEFAULT, NULL, NULL, 'requested');";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setInt(1, pid);
            ps.setInt(2, num_riders);
            ps.setFloat(3, pickup_lat);
            ps.setFloat(4, pickup_lon);
            ps.setFloat(5, dropoff_lat);
            ps.setFloat(6, dropoff_lon);
            ps.executeUpdate();
            get_messages(ps);
            ps.close();
			
        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }
    }

    public void add_rating(int rid, int rating) {
        //create a new rating for rid
        //should only be able to rate "completed" ratings
        try {
            String sql = "INSERT INTO ratings VALUES(?, ?);";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setInt(1, rid);
            ps.setInt(2, rating);
            ps.executeUpdate();
            get_messages(ps);
            ps.close();

        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }
    }

    public void print_closest(int rid) {
		
		try {
			String sql = "SELECT * FROM drivers LIMIT 5;";
			Statement stmt = this.db.getConnection().createStatement();
			ResultSet rs = stmt.executeQuery(sql);
			SQLWarning w = rs.getWarnings();
			if (w!=null){
				System.out.println(w.getMessage());
			}
			while(rs.next()){
				System.out.println("| DID: "+rs.getInt("did")+" | NAME: "+rs.getString("name")+" | PLATE: "+rs.getString("plate")+" | PHONE: "+rs.getString("phone")+" |");
			}
			rs.close();
		} catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }
    }
    
    public void print_rid(){
    	
    }

    public void print_rid(int rid) {
        // print all the stuff in rid

        try {
            String sql = "SELECT * FROM rides WHERE rid=?;";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setInt(1, rid);
            ResultSet rs = ps.executeQuery();
			
            if (rs==null){
            	System.out.println("RID("+rid+") NOT FOUND");
            }
            
			while(rs.next()){
				System.out.println("------------------------------------");
				System.out.println("Rid:            "+rs.getInt("rid"));
				System.out.println("Pid:            "+rs.getInt("pid"));
				Integer did = rs.getInt("did");
				if (!rs.wasNull()){
					System.out.println("Did:            "+rs.getInt("did"));
				} else {
					System.out.println("Did:            "+"NULL");
				}
				System.out.println("Num of Riders:  "+rs.getInt("num_riders"));
				System.out.println("Pickup Lat:     "+rs.getDouble("pickup_lat"));
				System.out.println("Pickup Lon:     "+rs.getDouble("pickup_lon"));
				Timestamp S = rs.getTimestamp("pickup_time");
				if (!rs.wasNull()){
					System.out.println("Pickup Time:    "+new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(S));
				} else {
					System.out.println("Pickup Time:    "+"NULL");
				}
				System.out.println("Dropoff Lat:    "+rs.getDouble("dropoff_lat"));
				System.out.println("Dropoff Lon:    "+rs.getDouble("dropoff_lon"));
				Timestamp D = rs.getTimestamp("dropoff_time");
				if (!rs.wasNull()){
					System.out.println("Dropoff Time:   "+new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(D));
				} else {
					System.out.println("Dropoff Time:   "+"NULL");
				}
				System.out.println("Fare:           "+rs.getDouble("fare"));
				System.out.println("Status:         "+rs.getString("status"));
				System.out.println("------------------------------------");
			}

            rs.close();
            ps.close();

        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }

    }

    public void drivers() {
		// get a drivers/rating relation from sql and print all driver info by descending rating
		 try {
			String sql = "SELECT * FROM driver_rating;";
			Statement stmt = this.db.getConnection().createStatement();
			ResultSet rs = stmt.executeQuery(sql);
			SQLWarning w = rs.getWarnings();
			if (w!=null){
				System.out.println(w.getMessage());
			}
			while(rs.next()){
				String rate;
				if (rs.getDouble("rated")==0.0){
					rate="NULL";
				} else {
					rate=rs.getDouble("rated")+"";
				}
				System.out.println("| DID: "+rs.getInt("did")+" | NAME: "+rs.getString("name")+" | PLATE: "+rs.getString("plate")+" | PHONE: "+rs.getString("phone")+" | RATING: "+rate+" |");
			}
			rs.close();
		} catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }

    }

    public void accept(int rid, int did) {
        // change status of rid to accepted with driver did
        try {
            String sql = "UPDATE rides SET did=? WHERE rid=?;";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setInt(1, did);
            ps.setInt(2, rid);
            ps.executeUpdate();
            get_messages(ps);
            ps.close();

        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }
    }

    public void pickup(int rid, Timestamp time) { //String?
        // change status to enroute and add pickup timestamp
        try {
            String sql = "UPDATE rides SET pickup_time=? WHERE rid=?;";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setTimestamp(1, time);
            ps.setInt(2, rid);
            ps.executeUpdate();
            get_messages(ps);
            ps.close();

        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }

    }

    public void dropoff(int rid, Timestamp time) {
        //change status to "completed" and add dropoff timestamp
        try {

            String sql = "UPDATE rides SET dropoff_time=? WHERE rid=?;";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setTimestamp(1, time);
            ps.setInt(2, rid);
            ps.executeUpdate();
            get_messages(ps);
            ps.close();

        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }

    }

    public void cancel(int rid) {
        //try to cancel rid if allowed to do so
        try {

            String sql = "UPDATE rides SET status='cancelled' WHERE rid=?;";
            PreparedStatement ps = this.db.getConnection().prepareStatement(sql);
            ps.setInt(1, rid);
            ps.executeUpdate();
            get_messages(ps);
            ps.close();

        } catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }

    }
	
	public void disc() throws SQLException{
		this.db.disconnect();
	}

	private void get_messages(PreparedStatement p){
		try{
			SQLWarning w = p.getWarnings();
			if (w!=null){
				System.out.println(w.getMessage());
			}
			
		} catch (SQLException e) {
            System.err.println("Exception: " + e.getMessage());
        }
	}

    public static void main(String[] args) {
        RideSharing app = new RideSharing();

        try {
            BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
            String line = "";
            while (line != null) {
				try{	
						System.out.println();
						System.out.println("Enter a Command:");
						line = in.readLine();
		                String[] argv = line.split(" ");
		                String input = argv[0].toLowerCase();
		                
		                switch(input){
		                	case "request":
		                		//USE: request <pid> <num_riders> <pickup_lat> <pickup_lon> <dropoff_lat> <dropoff_lon>
		                		app.add_request(Integer.parseInt(argv[1]), Integer.parseInt(argv[2]), Float.parseFloat(argv[3]), Float.parseFloat(argv[4]), Float.parseFloat(argv[5]), Float.parseFloat(argv[6]));
		                		break;
		                		
		                	case "rate":
		                		//USE: rate <rid> <rating>
		                		app.add_rating(Integer.parseInt(argv[1]), Integer.parseInt(argv[2]));
		                		break;
		                		
		                	case "search":
		                		//USE: search <rid>
		                		app.print_closest(Integer.parseInt(argv[1]));
		                		break;
		                		
		                	case "print":
		                		//USE: print <rid>
		                		app.print_rid(Integer.parseInt(argv[1]));
		                		break;
		                		
		                	case "drivers":
		                		//USE: drivers
		                		app.drivers();
		                		break;
		                		
		                	case "accept":
		                		//USE: accept <rid> <did>
		                		app.accept(Integer.parseInt(argv[1]), Integer.parseInt(argv[2]));
		                		break;
		                		
		                	case "pickup":
		                		//USE: pickup <rid> <datetime>
		                		String time = argv[2]+" "+argv[3];
			                	Timestamp t = Timestamp.valueOf(time);
			                    app.pickup(Integer.parseInt(argv[1]), t);
			                    break;
		                		
		                	case "dropoff":
		                		//USE: dropoff <rid> <datetime>
		                		String ti = argv[2]+" "+argv[3];
			                	Timestamp x = Timestamp.valueOf(ti);
			                    app.dropoff(Integer.parseInt(argv[1]), x);
			                    break;
		                		
		                	case "cancel":
		                		//cancel <rid>
		                		app.cancel(Integer.parseInt(argv[1]));
		                		break;
		                		
		                	case "exit":
		                		try{
									app.disc();
								} catch (SQLException e) {
									System.err.println("Exception: " + e.getMessage());
								}
								line=null;
			                    break;
		                		
		                	default:
		                		System.out.println("");
			                    System.out.println("Unknown command");
			                    break;
		                }
				} catch (Exception e) {
							if (line==null){
								break;
							} else {
								e.printStackTrace();
								System.err.println("INVALID COMMAND");
							}
		       	}
            }

            in.close();

        } catch (Exception e) {
            System.err.println("Exception: " + e.getMessage());
        }
    }
}
