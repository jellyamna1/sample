import java.sql.*;
public class Sql {
    public static void main(String[] a) throws Exception {
        try (Connection c = DriverManager.getConnection("jdbc:as400://" + a[0] + ";naming=sql;errors=full;translate binary=true", a[1], System.getenv("IBMI_PWD"));
             Statement st = c.createStatement()) {
            for (int k = 2; k < a.length; k++) {
                System.out.println("-- " + a[k]);
                try (ResultSet rs = st.executeQuery(a[k])) {
                    ResultSetMetaData md = rs.getMetaData(); int n = md.getColumnCount();
                    StringBuilder h = new StringBuilder("  "); for (int i = 1; i <= n; i++) h.append(i > 1 ? " | " : "").append(md.getColumnName(i)); System.out.println(h);
                    while (rs.next()) { StringBuilder sb = new StringBuilder("  ");
                        for (int i = 1; i <= n; i++) sb.append(i > 1 ? " | " : "").append(String.valueOf(rs.getString(i)).replaceAll("\\s+$", ""));
                        System.out.println(sb); }
                } catch (SQLException e) { System.out.println("  ERR " + e.getMessage()); }
            }
        }
    }
}
