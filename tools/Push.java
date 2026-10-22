import com.ibm.as400.access.*;
import java.nio.file.*;

/**
 * Upload files from the local repo to an IFS directory as UTF-8 (CCSID 1208) stream files.
 * Usage: IBMI_PWD=... java -cp tools/jt400.jar tools/Push.java <host> <user> <remoteDir> <file>...
 */
public class Push {
    public static void main(String[] a) throws Exception {
        AS400 sys = new AS400(a[0], a[1], System.getenv("IBMI_PWD").toCharArray());
        sys.setGuiAvailable(false);
        String remote = a[2];
        for (int i = 3; i < a.length; i++) {
            String rel = a[i];
            String target = remote + "/" + rel;
            new IFSFile(sys, target.substring(0, target.lastIndexOf('/'))).mkdirs();
            IFSFile f = new IFSFile(sys, target);
            if (f.exists()) f.delete();
            try (IFSFileOutputStream out = new IFSFileOutputStream(sys, target, IFSFileOutputStream.SHARE_ALL, false, 1208)) {
                out.write(Files.readAllBytes(Path.of(rel)));
            }
            System.out.println("pushed " + rel + " -> " + target);
        }
        sys.disconnectAllServices();
    }
}
