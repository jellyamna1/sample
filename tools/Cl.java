import com.ibm.as400.access.*;

/**
 * Run CL commands on IBM i and print the returned messages. Exit code 1 if any command fails.
 * Usage: IBMI_PWD=... java -cp tools/jt400.jar tools/Cl.java <host> <user> "<cmd>"...
 */
public class Cl {
    public static void main(String[] a) throws Exception {
        AS400 sys = new AS400(a[0], a[1], System.getenv("IBMI_PWD").toCharArray());
        sys.setGuiAvailable(false);
        boolean ok = true;
        CommandCall cc = new CommandCall(sys);
        for (int k = 2; k < a.length; k++) {
            System.out.println("-- " + a[k]);
            boolean r = cc.run(a[k]);
            for (AS400Message m : cc.getMessageList()) System.out.println("  " + m.getID() + " " + m.getText());
            System.out.println(r ? "  OK" : "  FAILED");
            ok &= r;
        }
        sys.disconnectAllServices();
        System.exit(ok ? 0 : 1);
    }
}
