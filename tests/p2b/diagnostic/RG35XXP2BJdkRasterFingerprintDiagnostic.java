import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;

/** Diagnostic only. Fingerprints the exact occupied-pixel set produced by
 * pinned Miyoo's JDK8/AWT backing. No runtime ownership. */
public final class RG35XXP2BJdkRasterFingerprintDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "ABCxyz09", "iiiiWWWW", "Tieng Viet", "Tiếng Việt", "Đặng", "中文"
    };
    private static final long FNV_OFFSET = 0xcbf29ce484222325L;
    private static final long FNV_PRIME = 0x100000001b3L;

    private static long mix(long h, int v) {
        h ^= (v >>> 24) & 255; h *= FNV_PRIME;
        h ^= (v >>> 16) & 255; h *= FNV_PRIME;
        h ^= (v >>> 8) & 255; h *= FNV_PRIME;
        h ^= v & 255; h *= FNV_PRIME;
        return h;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("usage: <font.ttf>");
        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0])).deriveFont(Font.PLAIN, 12f);
        int[] sizes = new int[] {12,14,16};
        System.out.println("P2B_JDK_RASTER_FP_BOOT=PASS");
        for (int style=0; style<=7; style++) {
            for (int zi=0; zi<sizes.length; zi++) {
                int size=sizes[zi];
                Font f=root.deriveFont(style,(float)size);
                BufferedImage mi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
                Graphics2D mg=mi.createGraphics(); mg.setFont(f); FontMetrics fm=mg.getFontMetrics(); mg.dispose();
                for (int si=0; si<SAMPLES.length; si++) {
                    String s=SAMPLES[si];
                    int bx=16, by=24+fm.getAscent();
                    int w=Math.max(160,fm.stringWidth(s)+64), h=Math.max(80,fm.getHeight()+48);
                    BufferedImage bi=new BufferedImage(w,h,BufferedImage.TYPE_INT_ARGB);
                    Graphics2D g=bi.createGraphics(); g.setFont(f); g.setColor(new java.awt.Color(0,0,0,255)); g.drawString(s,bx,by); g.dispose();
                    int ink=0,x0=99999,y0=99999,x1=-99999,y1=-99999; long fp=FNV_OFFSET;
                    for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
                        int a=(bi.getRGB(x,y)>>>24)&255;
                        if(a!=0) {
                            int rx=x-bx, ry=y-by; ink++;
                            if(rx<x0)x0=rx; if(rx>x1)x1=rx; if(ry<y0)y0=ry; if(ry>y1)y1=ry;
                            fp=mix(fp,rx); fp=mix(fp,ry);
                        }
                    }
                    if(ink==0)x0=y0=x1=y1=-1;
                    System.out.println("P2B_JDK_RASTER_FP STYLE="+style+" NORMALIZED="+f.getStyle()+" SIZE="+size+" SAMPLE="+si+
                        " WIDTH="+fm.stringWidth(s)+" INK="+ink+" BOUNDS="+x0+","+y0+","+x1+","+y1+" FP="+Long.toHexString(fp));
                }
            }
        }
        System.out.println("P2B_JDK_RASTER_FP_CASES=144");
        System.out.println("P2B_JDK_RASTER_FP_RESULT=PASS");
    }
}
