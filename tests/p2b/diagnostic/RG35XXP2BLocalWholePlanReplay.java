import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.lang.reflect.Method;

/**
 * Audit-only bridge for the final P2B planner -> ARM backend composition gate.
 *
 * The exact JDK8 whole-string TSV remains the width/raster oracle only. For
 * complex rows this bridge discards the oracle LAYOUT_FLAGS/RUNS and invokes
 * the already-proven source-derived local planner to regenerate those fields
 * from UTF-16 input. The resulting TSV is what the ARM backend consumes.
 *
 * No runtime/production code depends on this class.
 */
public final class RG35XXP2BLocalWholePlanReplay {
    private static char[] parseUtf16(String s) {
        if ((s.length() & 3) != 0) {
            throw new IllegalArgumentException("bad UTF16HEX length");
        }
        char[] out = new char[s.length() / 4];
        for (int i = 0; i < out.length; i++) {
            out[i] = (char)Integer.parseInt(s.substring(i * 4, i * 4 + 4), 16);
        }
        return out;
    }

    private static String joinPrefix(String[] c, int count) {
        StringBuffer b = new StringBuffer();
        for (int i = 0; i < count; i++) {
            if (i != 0) b.append('\t');
            b.append(c[i]);
        }
        return b.toString();
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            throw new IllegalArgumentException("usage: <jdk-whole-raster.tsv> <local-plan.tsv>");
        }

        Method plan = RG35XXP2BLocalComponentPlanDiagnostic.class.getDeclaredMethod(
            "plan", new Class[] { char[].class });
        plan.setAccessible(true);

        BufferedReader in = new BufferedReader(new FileReader(args[0]));
        BufferedWriter out = new BufferedWriter(new FileWriter(args[1]));
        String header = in.readLine();
        String expected = "CASE\tSTYLE\tNORMALIZED\tSIZE\tSAMPLE\tDRAW_COMPLEX\tUTF16HEX\tWIDTH\tINK\tX0\tY0\tX1\tY1\tFP\tLAYOUT_FLAGS\tRUNS";
        if (!expected.equals(header)) {
            throw new IllegalArgumentException("unexpected whole-raster header");
        }
        out.write(header);
        out.newLine();

        int cases = 0;
        int directCases = 0;
        int complexCases = 0;
        int rtlCases = 0;
        int planMismatch = 0;
        String line;
        while ((line = in.readLine()) != null) {
            if (line.length() == 0) continue;
            String[] c = line.split("\t", -1);
            if (c.length != 16) {
                throw new IllegalArgumentException("bad whole-raster columns=" + c.length);
            }

            boolean complex = "1".equals(c[5]);
            String localFlags;
            String localRuns;
            if (!complex) {
                directCases++;
                localFlags = "0";
                localRuns = "-";
            } else {
                complexCases++;
                char[] chars = parseUtf16(c[6]);
                String[] p = (String[])plan.invoke(null, new Object[] { chars });
                String components = p[4];
                if (components.indexOf(';') >= 0) {
                    throw new IllegalStateException(
                        "established 336 complex corpus unexpectedly produced multiple local components case=" + c[0]);
                }
                String[] f = components.split(":", 6);
                if (f.length != 6) {
                    throw new IllegalStateException("bad local component serialization case=" + c[0]);
                }
                int start = Integer.parseInt(f[1]);
                int len = Integer.parseInt(f[2]);
                if (!"0".equals(f[0]) || start != 0 || len != chars.length) {
                    throw new IllegalStateException(
                        "unexpected local component slice case=" + c[0] + " component=" + components);
                }
                localFlags = f[4];
                localRuns = f[5];
                if ((Integer.parseInt(localFlags) & 1) != 0) rtlCases++;
            }

            if (!c[14].equals(localFlags) || !c[15].equals(localRuns)) {
                planMismatch++;
                if (planMismatch <= 24) {
                    System.out.println(
                        "P2B_LOCAL_WHOLE_PLAN_MISMATCH CASE=" + c[0] +
                        " REF_FLAGS=" + c[14] + " LOC_FLAGS=" + localFlags +
                        " REF_RUNS=" + c[15] + " LOC_RUNS=" + localRuns);
                }
            }

            out.write(joinPrefix(c, 14));
            out.write('\t');
            out.write(localFlags);
            out.write('\t');
            out.write(localRuns);
            out.newLine();
            cases++;
        }
        in.close();
        out.close();

        System.out.println("P2B_LOCAL_WHOLE_PLAN_BOOT=PASS");
        System.out.println("P2B_LOCAL_WHOLE_PLAN_CASES=" + cases);
        System.out.println("P2B_LOCAL_WHOLE_PLAN_DIRECT_CASES=" + directCases);
        System.out.println("P2B_LOCAL_WHOLE_PLAN_COMPLEX_CASES=" + complexCases);
        System.out.println("P2B_LOCAL_WHOLE_PLAN_RTL_CASES=" + rtlCases);
        System.out.println("P2B_LOCAL_WHOLE_PLAN_MISMATCH_COUNT=" + planMismatch);
        if (cases != 336 || directCases != 144 || complexCases != 192 || rtlCases != 72 || planMismatch != 0) {
            throw new RuntimeException("local whole-plan replay failed");
        }
        System.out.println("P2B_LOCAL_WHOLE_PLAN_GENERATION=PASS");
        System.out.println("P2B_LOCAL_WHOLE_PLAN_SOURCE=SOURCE_DERIVED_JDK8_PLANNER");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
        System.out.println("P2B_DEVICE_PACKAGE=FORBIDDEN");
    }
}
