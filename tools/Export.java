import java.nio.file.*;
import java.sql.*;
import java.util.*;

/** Export all source members in a library to <outDir>/<srcfile lower>/<member lower>.<type lower>. Read-only (alias in QTEMP). */
public class Export {
    public static void main(String[] a) throws Exception {
        String lib = a[2].toUpperCase();
        Path out = Path.of(a[3]);
        try (Connection c = DriverManager.getConnection("jdbc:as400://" + a[0] + ";naming=sql;errors=full;translate binary=true", a[1], System.getenv("IBMI_PWD"));
             Statement st = c.createStatement()) {
            List<String[]> mbrs = new ArrayList<>();
            try (ResultSet rs = st.executeQuery("SELECT SYSTEM_TABLE_NAME, SYSTEM_TABLE_MEMBER, COALESCE(SOURCE_TYPE,'') "
                    + "FROM QSYS2.SYSPARTITIONSTAT WHERE SYSTEM_TABLE_SCHEMA='" + lib + "' AND SOURCE_TYPE IS NOT NULL ORDER BY 1,2")) {
                while (rs.next()) mbrs.add(new String[]{rs.getString(1).trim(), rs.getString(2).trim(), rs.getString(3).trim()});
            }
            for (String[] m : mbrs) {
                st.execute("CREATE OR REPLACE ALIAS QTEMP.X_SRC FOR \"" + lib + "\".\"" + m[0] + "\"(\"" + m[1] + "\")");
                StringBuilder sb = new StringBuilder();
                try (ResultSet rs = st.executeQuery("SELECT SRCDTA FROM QTEMP.X_SRC ORDER BY SRCSEQ")) {
                    while (rs.next()) sb.append(rs.getString(1).replaceAll("\\s+$", "")).append('\n');
                }
                Path f = out.resolve(m[0].toLowerCase()).resolve(m[1].toLowerCase() + "." + (m[2].isEmpty() ? "txt" : m[2].toLowerCase()));
                Files.createDirectories(f.getParent());
                Files.writeString(f, sb.toString());
                System.out.println("exported " + m[0] + "(" + m[1] + ") -> " + out.relativize(f));
            }
        }
    }
}
