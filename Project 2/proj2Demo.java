import java.sql.*;
import oracle.jdbc.*;
import java.math.*;
import java.io.*;
import java.awt.*;
import oracle.jdbc.pool.OracleDataSource;

public class proj2Demo {
	private static Connection connection;
	private static BufferedReader br = new BufferedReader(new InputStreamReader(System.in));

    public static void main (String args []) throws SQLException {
		try {
			OracleDataSource ds = new oracle.jdbc.pool.OracleDataSource();
			ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:acad111");
			connection = ds.getConnection("user", "pass");
			int choice = 1;
			String tableName;
			while(true){
				System.out.println("Please select a option:");
				System.out.println("1 - List the tables");
				System.out.println("2 - Display all the entries in a table");
				System.out.println("3 - Add a student");
				System.out.println("4 - Delete a student");
				System.out.println("5 - List students in a class");
				System.out.println("6 - Show prerequisites of a course");
				System.out.println("7 - Enroll student in a class");
				System.out.println("8 - Drop student from a class");
				System.out.println("0 - Exit");
				choice = Integer.parseInt(br.readLine());
				if(choice == 0){
					break;
				}
				//switch case to call respective functions
				switch(choice){
					case 0:
						connection.close();
						break;
					case 1:
						listTableNames();
						break;
					case 2:
						displayTable();
						break;
					case 3:
						addStudent();
						break;
					case 4:
						deleteStudent();
						break;
					case 5:
						studentsInAClass();
						break;
					case 6:
						showPrerequisites();
						break;
					case 7:
						enrollStudent();
						break;
					case 8:
						dropStudent();
						break;
				}
			}
		}
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void listTableNames() throws SQLException
	{
		//list of tables
		System.out.println("Tables:");
		System.out.println("STUDENTS");
		System.out.println("COURSES");
		System.out.println("COURSE_CREDIT");
		System.out.println("CLASSES");
		System.out.println("G_ENROLLMENTS");
		System.out.println("SCORE_GRADE");
		System.out.println("PREREQUISITES");
		System.out.println("LOGS");
	}

	public static void displayTable() throws SQLException
	{
		//display all tuples in a table... single function for all tables
		try {
			System.out.print("Enter the table name :: ");
			String tableName = br.readLine();
			CallableStatement callableStatement = connection.prepareCall("begin student_operations.showTuples(?,?); end;");
			callableStatement.setString(1,tableName.toUpperCase());  
			callableStatement.registerOutParameter(2,OracleTypes.CURSOR);
			callableStatement.execute();
			ResultSet resultset = (ResultSet)callableStatement.getObject(2);
			ResultSetMetaData resultsetmeta = resultset.getMetaData();
			int columnCount = resultsetmeta.getColumnCount();
			//dynamically loop based on column count
			for (int i = 1; i <= columnCount; i++ ) {
				System.out.print(resultsetmeta.getColumnName(i)+"\t\t");
			}
			System.out.print("\n");
			while(resultset.next()) {
				for (int i = 1; i <= columnCount; i++ ) {
					System.out.print(resultset.getString(i)+" \t\t");
				}
				System.out.print("\n");
			}
		}	
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void addStudent() throws SQLException
	{
		//add a new student
		try {
			System.out.print("Enter the B# :: ");
			String bid = br.readLine();
			System.out.print("Enter the First Name :: ");
			String fname = br.readLine();
			System.out.print("Enter the Last Name :: ");
			String lname = br.readLine();
			System.out.print("Enter the level :: ");
			String level = br.readLine();
			System.out.print("Enter the GPA :: ");
			float gpa = Float.parseFloat(br.readLine());
			System.out.print("Enter the email :: ");
			String email = br.readLine();
			System.out.print("Enter the DOB :: ");
			String dob = br.readLine();
			CallableStatement callableStatement = connection.prepareCall("insert into students values(?,?,?,?,?,?,?)");
			callableStatement.setString(1, bid);
			callableStatement.setString(2, fname);
			callableStatement.setString(3, lname);
			callableStatement.setString(4, level);
			callableStatement.setFloat(5, gpa);
			callableStatement.setString(6, email);
			callableStatement.setString(7, dob);
			callableStatement.execute();
			System.out.println("Student with B# : "+bid+" was inserted successfully");
		}	
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void enrollStudent() throws SQLException
	{
		//enroll a student in a class
		try {
			System.out.print("Enter the B# :: ");
			String bid = br.readLine();
			System.out.print("Enter the Class# :: ");
			String classid = br.readLine();
			System.out.print("Enter the score :: ");
			float gpa = Float.parseFloat(br.readLine());
			CallableStatement callableStatement = connection.prepareCall("begin student_operations.enrollStudent1(?,?,?); end;");
			callableStatement.setString(1, bid);
			callableStatement.setString(2, classid);
			callableStatement.setFloat(3, gpa);
			callableStatement.execute();
			System.out.println("Student with B# : "+bid+" was enrolled successfully");
		}	
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void studentsInAClass() throws SQLException
	{
		//list all students in a class
		try {
			System.out.print("Enter the Class # :: ");
			String classid = br.readLine();
			CallableStatement callableStatement = connection.prepareCall("begin student_operations.showClassDetails(?,?); end;");
			callableStatement.setString(1,classid);  
			callableStatement.registerOutParameter(2,OracleTypes.CURSOR);
			callableStatement.execute();
			ResultSet resultset = (ResultSet)callableStatement.getObject(2);
			ResultSetMetaData resultsetmeta = resultset.getMetaData();
			int columnCount = resultsetmeta.getColumnCount();
			int rowCount = 0;
			for (int i = 1; i <= columnCount; i++ ) {
				System.out.print(resultsetmeta.getColumnName(i)+"\t\t");
			}
			System.out.print("\n");
			while(resultset.next()) {
				rowCount++;
				for (int i = 1; i <= columnCount; i++ ) {
					System.out.print(resultset.getString(i)+" \t\t");
				}
				System.out.print("\n");
			}
			if(rowCount < 1){
				System.out.println("No students enrolled in "+classid);
			}			
		}	
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void showPrerequisites() throws SQLException
	{
		// to show the direct and indirect prerequisites
		try {
			System.out.print("Enter the Dept code :: ");
			String deptCode = br.readLine();
			System.out.print("Enter the Course # :: ");
			int courseid = Integer.parseInt(br.readLine());
			CallableStatement callableStatement = connection.prepareCall("SELECT (pre_dept_code || pre_course#) FROM PREREQUISITES START WITH dept_code=? AND course#=? CONNECT BY PRIOR pre_dept_code = dept_code AND PRIOR pre_course# = course#");
			callableStatement.setString(1,deptCode);  
			callableStatement.setInt(2,courseid); 
			ResultSet resultset = callableStatement.executeQuery();
			ResultSetMetaData resultsetmeta = resultset.getMetaData();
			int columnCount = resultsetmeta.getColumnCount();
			int rowCount = 0;
			while(resultset.next()) {
				for (int i = 1; i <= columnCount; i++ ) {
					System.out.print(resultset.getString(i)+" \t\t");
					rowCount++;
				}
				System.out.print("\n");
			} 
			if(rowCount == 0){
				System.out.println("No prerequisites for "+deptCode+""+courseid);
			}
		}	
		catch (SQLException ex) { 
			ex.printStackTrace();
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void deleteStudent() throws SQLException
	{
		// to delete a student and from enrollments too
		try {
			System.out.print("Enter the student B# :: ");
			String Bid = br.readLine();
			CallableStatement callableStatement = connection.prepareCall("delete from g_enrollments where G_B#=?");
			callableStatement.setString(1,Bid);  
			callableStatement.execute();
			callableStatement = connection.prepareCall("delete from students where B#=?");
			callableStatement.setString(1,Bid);  
			callableStatement.execute();
			System.out.println("Student deleted successfully");
		}	
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}

	public static void dropStudent() throws SQLException
	{
		// delete student record from enrollments table
		try {
			System.out.print("Enter the student B# :: ");
			String Bid = br.readLine();
			System.out.print("Enter the classid :: ");
			String classid = br.readLine();
			CallableStatement callableStatement = connection.prepareCall("delete from g_enrollments where G_B#=? and classid=? ");
			callableStatement.setString(1,Bid);  
			callableStatement.setString(2,classid);  
			callableStatement.execute();
			System.out.println(Bid + " dropped from "+ classid +".");
		}	
		catch (SQLException ex) { 
			System.out.println("SQLException ::\n"+ex);
		}
		catch (Exception e) {
			System.out.println("Other Exception ::\n"+e);
		}
	}
}