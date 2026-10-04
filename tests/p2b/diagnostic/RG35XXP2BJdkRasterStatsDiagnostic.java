import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;

/** Diagnostic only: normalized JDK8 raster geometry for comparison with the
 * exact pinned-toolchain FreeType backend. */
public final class RG35XXP2BJdkRasterStatsDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "ABCxyz09", "iiiiWWWW", "Tieng Viet", "Tiếng Việt", "Đặng", "中文"
    };

    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("usage: <font.ttf>");
        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0])).deriveFont(Font.PLAIN, 12f);
        int[] sizes = new int[] {12,14,16};
        System.out.println("P2B_JDK_RASTER_STATS_BOOT=PASS");
        for (int style = 0; style <= 7; style++) {
            for (int zi = 0; zi < sizes.length; zi++) {
                int size = sizes[zi];
                Font f = root.deriveFont(style, (float)size);
                BufferedImage metricImage = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
                Graphics2D mg = metricImage.createGraphics();
                mg.setFont(f);
                FontMetrics fm = mg.getFontMetrics();
                mg.dispose();
                for (int si = 0; si < SAMPLES.length; si++) {
                    String s = SAMPLES[si];
                    int width = Math.max(64, fm.stringWidth(s) + 32);
                    int height = Math.max(64, fm.getHeight() + 32);
                    BufferedImage bi = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
                    Graphics2D g = bi.createGraphics();
                    g.setFont(f);
                    g.setColor(new java.awt.Color(0,0,0,255));
                    int bx = 8;
                    int by = 8 + fm.getAscent();
                    g.drawString(s, bx, by);
                    g.dispose();
                    long ink = 0, alphaSum = 0;
                    int x0=99999,y0=99999,x1=-99999,y1=-99999;
                    int alphaLevels = 0;
                    boolean[] seen = new boolean[256];
                    for (int y=0; y<height; y++) {
                        for (int x=0; x<width; x++) {
                            int a = (bi.getRGB(x,y) >>> 24) & 255;
                            if (a != 0) {
                                ink++; alphaSum += a; seen[a] = true;
                                int rx=x-bx, ry=y-by;
                                if (rx<x0) x0=rx; if (rx>x1) x1=rx;
                                if (ry<y0) y0=ry; if (ry>y1) y1=ry;
                            }
                        }
                    }
                    if (ink==0) x0=y0=x1=y1=-1;
                    for (int i=1;i<256;i++) if (seen[i]) alphaLevels++;
                    System.out.println("P2B_JDK_STYLE="+style+" NORMALIZED="+f.getStyle()+" SIZE="+size+" SAMPLE="+si
                        +" WIDTH="+fm.stringWidth(s)+" INK="+ink+" ALPHA_SUM="+alphaSum+" ALPHA_LEVELS="+alphaLevels
                        +" BOUNDS="+x0+","+y0+","+x1+","+y1);
                }
            }
        }
        System.out.println("P2B_JDK_RASTER_STATS_RESULT=PASS");
    }
}
