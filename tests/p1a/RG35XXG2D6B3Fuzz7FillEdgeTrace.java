package org.recompile.rg35xx.p1a;

import java.awt.geom.Arc2D;
import java.awt.geom.Path2D;
import java.awt.geom.PathIterator;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import sun.java2d.loops.ProcessPath;

/**
 * G2D-6B3 diagnostic-only FUZZ_7 fillArc fixed-edge / active-edge proof.
 *
 * The native AWT oracle was locked by G2D-6B1 as
 * FillPath(AnyColor, SrcNoEa, AnyInt).  OpenJDK8 ProcessPath.java documents
 * itself as the Java implementation kept synchronized with native
 * ProcessPath.[c,h].  This probe first requires ProcessPath.fillPath() to
 * reproduce the native-AWT framebuffer bit-exactly.  Only then does it inspect
 * the pre-FillPolygon fixed-point point list and independently replay the
 * active-edge scan converter, with a detailed trace for scanline y=5.
 *
 * No RG35XX runtime code is exercised or modified here.
 */
public final class RG35XXG2D6B3Fuzz7FillEdgeTrace {
    private static final int W = 48;
    private static final int H = 40;
    private static final int COLOR = 0x3366CC;
    private static final int ARGB = 0xFF3366CC;
    private static final int WHITE = 0xFFFFFFFF;
    private static final int MDP_PREC = 10;
    private static final int MDP_MULT = 1 << MDP_PREC;
    private static final int MDP_W_MASK = -MDP_MULT;
    private static final int CALC_BND = 1 << (30 - MDP_PREC);
    private static final long EXPECTED_CHECKSUM = 0x0d5c73eed02b277dfL;
    private static final int EXPECTED_COUNT = 92;

    private static final class PixelHandler extends ProcessPath.DrawHandler {
        final int[] pixels = new int[W * H];
        PixelHandler() {
            super(0, 0, W, H);
            for (int i = 0; i < pixels.length; i++) pixels[i] = WHITE;
        }
        public void drawLine(int x0, int y0, int x1, int y1) {
            throw new RuntimeException("unexpected drawLine in fillPath");
        }
        public void drawPixel(int x0, int y0) {
            throw new RuntimeException("unexpected drawPixel in fillPath");
        }
        public void drawScanline(int x0, int x1, int y0) {
            if (y0 < 0 || y0 >= H || x0 < 0 || x1 >= W || x0 > x1) {
                throw new RuntimeException("out-of-bounds scanline " + x0 + "," + x1 + "," + y0);
            }
            for (int x = x0; x <= x1; x++) pixels[y0 * W + x] = ARGB;
        }
    }

    private static final class TPoint {
        int x, y;
        boolean lastPoint;
        TPoint prev, next, nextByY;
        TEdge edge;
        TPoint(int ax, int ay, boolean last) { x = ax; y = ay; lastPoint = last; }
    }

    private static final class TEdge {
        int x, dx, dir;
        TPoint p;
        TEdge prev, next;
        TEdge(TPoint ap, int ax, int adx, int adir) {
            p = ap; x = ax; dx = adx; dir = adir;
        }
    }

    private static final class ActiveList {
        TEdge head;

        void insert(TPoint pnt, int cy) {
            TPoint np = pnt.next;
            int x1 = pnt.x, y1 = pnt.y;
            int x2 = np.x, y2 = np.y;
            if (y1 == y2) return;

            int dX = x2 - x1;
            int dY = y2 - y1;
            int x0, dy, dir;
            if (y1 < y2) {
                x0 = x1;
                dy = cy - y1;
                dir = -1;
            } else {
                x0 = x2;
                dy = cy - y2;
                dir = 1;
            }

            int stepx;
            if (dX > CALC_BND || dX < -CALC_BND) {
                stepx = (int)((((double)dX) * MDP_MULT) / dY);
                x0 += (int)((((double)dX) * dy) / dY);
            } else {
                stepx = (dX << MDP_PREC) / dY;
                x0 += (dX * dy) / dY;
            }

            TEdge ne = new TEdge(pnt, x0, stepx, dir);
            ne.next = head;
            ne.prev = null;
            if (head != null) head.prev = ne;
            head = pnt.edge = ne;
        }

        void delete(TEdge e) {
            TEdge prevp = e.prev;
            TEdge nextp = e.next;
            if (prevp != null) prevp.next = nextp;
            else head = nextp;
            if (nextp != null) nextp.prev = prevp;
        }

        void sort() {
            if (head == null || head.next == null) return;
            TEdge p, q, r, s = null, temp;
            boolean wasSwap = true;
            while (s != head.next && wasSwap) {
                r = p = head;
                q = p.next;
                wasSwap = false;
                while (p != s) {
                    if (p.x >= q.x) {
                        wasSwap = true;
                        if (p == head) {
                            temp = q.next;
                            q.next = p;
                            p.next = temp;
                            head = q;
                            r = q;
                        } else {
                            temp = q.next;
                            q.next = p;
                            p.next = temp;
                            r.next = q;
                            r = q;
                        }
                    } else {
                        r = p;
                        p = p.next;
                    }
                    q = p.next;
                    if (q == s) s = p;
                }
            }
            p = head;
            q = null;
            while (p != null) {
                p.prev = q;
                q = p;
                p = p.next;
            }
        }
    }

    public static void main(String[] args) throws Exception {
        Arc2D.Float arc = new Arc2D.Float(8, -4, 26, 9, 1191, 230, Arc2D.PIE);
        Path2D.Float path = new Path2D.Float(arc);

        PixelHandler canonicalJava = new PixelHandler();
        boolean javaOk = ProcessPath.fillPath(canonicalJava, path, 0, 0);
        if (!javaOk) throw new RuntimeException("ProcessPath.fillPath returned false");

        int javaCount = count(canonicalJava.pixels);
        long javaChecksum = checksum(canonicalJava.pixels);
        int javaTarget = canonicalJava.pixels[5 * W + 21];
        System.out.println("G2D6B3_CASE=FUZZ_7");
        System.out.println("G2D6B3_FILLARC=8,-4,26,9,1191,230");
        System.out.println("G2D6B3_PROCESSPATH_JAVA_COUNT=" + javaCount);
        System.out.println("G2D6B3_PROCESSPATH_JAVA_CHECKSUM=" + Long.toHexString(javaChecksum));
        System.out.println("G2D6B3_PROCESSPATH_JAVA_PIXEL_21_5=" + hex(javaTarget));
        if (javaCount != EXPECTED_COUNT || javaChecksum != EXPECTED_CHECKSUM || javaTarget != WHITE) {
            throw new RuntimeException("Java ProcessPath does not reproduce native AWT oracle");
        }
        System.out.println("G2D6B3_PROCESSPATH_JAVA_REPRODUCES_AWT=PASS");

        ArrayList<TPoint> points = extractFixedPoints(path);
        System.out.println("G2D6B3_FIXED_POINT_COUNT=" + points.size());
        for (int i = 0; i < points.size(); i++) {
            TPoint p = points.get(i);
            System.out.println("G2D6B3_POINT I=" + i + " X=" + p.x + " Y=" + p.y + " LAST=" + p.lastPoint);
        }
        for (int i = 0; i + 1 < points.size(); i++) {
            TPoint p = points.get(i);
            TPoint q = points.get(i + 1);
            if (!p.lastPoint) {
                System.out.println("G2D6B3_FIXED_EDGE I=" + i + " X0=" + p.x + " Y0=" + p.y +
                                   " X1=" + q.x + " Y1=" + q.y);
            }
        }

        int[] sim = simulateFillPolygon(points);
        int simCount = count(sim);
        long simChecksum = checksum(sim);
        int simTarget = sim[5 * W + 21];
        System.out.println("G2D6B3_EDGE_SIM_COUNT=" + simCount);
        System.out.println("G2D6B3_EDGE_SIM_CHECKSUM=" + Long.toHexString(simChecksum));
        System.out.println("G2D6B3_EDGE_SIM_PIXEL_21_5=" + hex(simTarget));

        if (!samePixels(canonicalJava.pixels, sim)) {
            firstDiff(canonicalJava.pixels, sim);
            throw new RuntimeException("independent edge simulator differs from ProcessPath.fillPath");
        }
        if (simCount != EXPECTED_COUNT || simChecksum != EXPECTED_CHECKSUM || simTarget != WHITE) {
            throw new RuntimeException("edge simulator does not reproduce native AWT oracle");
        }
        System.out.println("G2D6B3_EDGE_SIM_REPRODUCES_AWT=PASS");
        System.out.println("G2D6B3_Y5_TRACE=PASS");
        System.out.println("G2D6B3_FIRST_DIVERGENCE_PROOF=FILLPATH_FIXED_EDGE_ACTIVE_EDGE_SCAN_CONVERSION");
    }

    private static ArrayList<TPoint> extractFixedPoints(Path2D.Float path) throws Exception {
        Class<?> fphClass = Class.forName("sun.java2d.loops.ProcessPath$FillProcessHandler");
        Constructor<?> ctor = fphClass.getDeclaredConstructor(new Class[]{ProcessPath.DrawHandler.class});
        ctor.setAccessible(true);
        PixelHandler h = new PixelHandler();
        Object fph = ctor.newInstance(new Object[]{h});

        Method doProcess = ProcessPath.class.getDeclaredMethod(
            "doProcessPath",
            new Class[]{ProcessPath.ProcessHandler.class, Path2D.Float.class, Float.TYPE, Float.TYPE});
        doProcess.setAccessible(true);
        Boolean ok = (Boolean)doProcess.invoke(null, new Object[]{fph, path, Float.valueOf(0.0f), Float.valueOf(0.0f)});
        if (!ok.booleanValue()) throw new RuntimeException("reflected doProcessPath returned false");

        Field fdField = fphClass.getDeclaredField("fd");
        fdField.setAccessible(true);
        Object fd = fdField.get(fph);
        Class<?> fdClass = fd.getClass();
        Field listField = fdClass.getDeclaredField("plgPnts");
        listField.setAccessible(true);
        List<?> raw = (List<?>)listField.get(fd);

        ArrayList<TPoint> out = new ArrayList<TPoint>();
        Field fx = null, fy = null, flast = null;
        for (int i = 0; i < raw.size(); i++) {
            Object rp = raw.get(i);
            if (fx == null) {
                Class<?> pc = rp.getClass();
                fx = pc.getDeclaredField("x"); fx.setAccessible(true);
                fy = pc.getDeclaredField("y"); fy.setAccessible(true);
                flast = pc.getDeclaredField("lastPoint"); flast.setAccessible(true);
            }
            out.add(new TPoint(fx.getInt(rp), fy.getInt(rp), flast.getBoolean(rp)));
        }
        return out;
    }

    private static int[] simulateFillPolygon(ArrayList<TPoint> pnts) {
        int[] pixels = new int[W * H];
        for (int i = 0; i < pixels.length; i++) pixels[i] = WHITE;
        int n = pnts.size();
        if (n <= 1) return pixels;

        int yMin = pnts.get(0).y;
        int yMax = yMin;
        for (int i = 1; i < n; i++) {
            int y = pnts.get(i).y;
            if (y < yMin) yMin = y;
            if (y > yMax) yMax = y;
        }
        int hashSize = ((yMax - yMin) >> MDP_PREC) + 4;
        int hashOffset = ((yMin - 1) & MDP_W_MASK);
        TPoint[] yHash = new TPoint[hashSize];

        TPoint curpt = pnts.get(0);
        curpt.prev = null;
        for (int i = 0; i < n - 1; i++) {
            curpt = pnts.get(i);
            TPoint nextpt = pnts.get(i + 1);
            int hi = (curpt.y - hashOffset - 1) >> MDP_PREC;
            curpt.nextByY = yHash[hi];
            yHash[hi] = curpt;
            curpt.next = nextpt;
            nextpt.prev = curpt;
            curpt.edge = null;
        }
        TPoint ept = pnts.get(n - 1);
        int ehi = (ept.y - hashOffset - 1) >> MDP_PREC;
        ept.nextByY = yHash[ehi];
        yHash[ehi] = ept;
        ept.next = null;
        ept.edge = null;

        ActiveList active = new ActiveList();
        int rightBnd = W - 1;
        for (int y = hashOffset + MDP_MULT, k = 0;
             y <= yMax && k < hashSize;
             y += MDP_MULT, k++) {
            for (TPoint pt = yHash[k]; pt != null; pt = pt.nextByY) {
                if (pt.prev != null && !pt.prev.lastPoint) {
                    if (pt.prev.edge != null && pt.prev.y <= y) {
                        active.delete(pt.prev.edge);
                        pt.prev.edge = null;
                    } else if (pt.prev.y > y) {
                        active.insert(pt.prev, y);
                    }
                }
                if (!pt.lastPoint && pt.next != null) {
                    if (pt.edge != null && pt.next.y <= y) {
                        active.delete(pt.edge);
                        pt.edge = null;
                    } else if (pt.next.y > y) {
                        active.insert(pt, y);
                    }
                }
            }

            if (active.head == null) continue;
            active.sort();

            int screenY = y >> MDP_PREC;
            if (screenY == 5) {
                int ei = 0;
                for (TEdge e = active.head; e != null; e = e.next) {
                    System.out.println("G2D6B3_Y5_EDGE I=" + ei + " X_FIXED=" + e.x +
                                       " DX=" + e.dx + " DIR=" + e.dir +
                                       " SEG_X0=" + e.p.x + " SEG_Y0=" + e.p.y +
                                       " SEG_X1=" + e.p.next.x + " SEG_Y1=" + e.p.next.y);
                    ei++;
                }
            }

            int counter = 0;
            boolean drawing = false;
            int xl = 0;
            for (TEdge e = active.head; e != null; e = e.next) {
                counter += e.dir;
                if (counter != 0 && !drawing) {
                    xl = (e.x + MDP_MULT - 1) >> MDP_PREC;
                    drawing = true;
                    if (screenY == 5) {
                        System.out.println("G2D6B3_Y5_ENTER X_FIXED=" + e.x + " XL=" + xl + " COUNTER=" + counter);
                    }
                }
                if (counter == 0 && drawing) {
                    int xr = (e.x - 1) >> MDP_PREC;
                    if (xl <= xr) {
                        drawSpan(pixels, xl, xr, screenY);
                        if (screenY == 5) {
                            System.out.println("G2D6B3_Y5_SPAN XL=" + xl + " XR=" + xr);
                        }
                    }
                    drawing = false;
                }
                e.x += e.dx;
            }
            if (drawing && xl <= rightBnd) {
                drawSpan(pixels, xl, rightBnd, screenY);
                if (screenY == 5) {
                    System.out.println("G2D6B3_Y5_SPAN XL=" + xl + " XR=" + rightBnd + " RIGHT_CLAMP=YES");
                }
            }
        }
        return pixels;
    }

    private static void drawSpan(int[] pixels, int xl, int xr, int y) {
        if (y < 0 || y >= H) return;
        if (xl < 0) xl = 0;
        if (xr >= W) xr = W - 1;
        if (xl > xr) return;
        for (int x = xl; x <= xr; x++) pixels[y * W + x] = ARGB;
    }

    private static int count(int[] p) {
        int n = 0;
        for (int i = 0; i < p.length; i++) if ((p[i] & 0x00FFFFFF) == COLOR) n++;
        return n;
    }

    private static long checksum(int[] p) {
        long h = 1469598103934665603L;
        for (int i = 0; i < p.length; i++) {
            h ^= (p[i] & 0xFFFFFFFFL);
            h *= 1099511628211L;
        }
        return h;
    }

    private static boolean samePixels(int[] a, int[] b) {
        if (a.length != b.length) return false;
        for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    private static void firstDiff(int[] a, int[] b) {
        for (int i = 0; i < a.length && i < b.length; i++) {
            if (a[i] != b[i]) {
                System.out.println("G2D6B3_FIRST_DIFF X=" + (i % W) + " Y=" + (i / W) +
                                   " A=" + hex(a[i]) + " B=" + hex(b[i]));
                return;
            }
        }
    }

    private static String hex(int v) {
        String s = Integer.toHexString(v);
        while (s.length() < 8) s = "0" + s;
        return s;
    }
}
