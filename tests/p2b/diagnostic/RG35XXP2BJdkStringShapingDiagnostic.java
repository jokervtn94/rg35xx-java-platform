import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;

/** Diagnostic only: detects string-level behavior in the exact JDK8/AWT path
 * that cannot be reproduced by independently drawing UTF-16 chars at integer
 * FontMetrics.charWidth advances. */
public final class RG35XXP2BJdkStringShapingDiagnostic {
    private static final String[] SAMPLES = new String[] {
        "ABCxyz09",
        "AVATAR",
        "ToTo",
        "ffi",
        "Tiếng Việt",
        "Tie\u0302\u0301ng Vie\u0323\u0302t",
        "A\u0301",
        "سلام",
        "لا",
        "שלום",
        "नमस्ते",
        "ภาษาไทย",
        "中文",
        "A\u200DB"
    };
    private static final int W=512,H=160,X=64,BASE=96;
    private static final long FNV_OFFSET=0xcbf29ce484222325L;
    private static final long FNV_PRIME=0x100000001b3L;

    private static long mix(long h,int v) {
        h^=(v>>>24)&255;h*=FNV_PRIME; h^=(v>>>16)&255;h*=FNV_PRIME;
        h^=(v>>>8)&255;h*=FNV_PRIME; h^=v&255;h*=FNV_PRIME; return h;
    }
    private static boolean[] renderWhole(Font f,String s) {
        BufferedImage bi=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics(); g.setFont(f); g.setColor(new java.awt.Color(0,0,0,255)); g.drawString(s,X,BASE); g.dispose();
        return mask(bi);
    }
    private static boolean[] renderChars(Font f,FontMetrics fm,String s) {
        BufferedImage bi=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics(); g.setFont(f); g.setColor(new java.awt.Color(0,0,0,255));
        int pen=X;
        for(int i=0;i<s.length();i++) { char ch=s.charAt(i); g.drawString(String.valueOf(ch),pen,BASE); pen+=fm.charWidth(ch); }
        g.dispose(); return mask(bi);
    }
    private static boolean[] mask(BufferedImage bi) {
        boolean[] a=new boolean[W*H];
        for(int y=0;y<H;y++) for(int x=0;x<W;x++) a[y*W+x]=((bi.getRGB(x,y)>>>24)&255)!=0;
        return a;
    }
    private static long fp(boolean[] a) {
        long h=FNV_OFFSET;
        for(int y=0;y<H;y++) for(int x=0;x<W;x++) if(a[y*W+x]) { h=mix(h,x-X);h=mix(h,y-BASE); }
        return h;
    }
    private static int ink(boolean[] a) { int n=0; for(int i=0;i<a.length;i++) if(a[i])n++; return n; }
    private static int xor(boolean[] a,boolean[] b) { int n=0; for(int i=0;i<a.length;i++) if(a[i]!=b[i])n++; return n; }
    public static void main(String[] args) throws Exception {
        if(args.length!=1)throw new IllegalArgumentException("usage: <font.ttf>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0])).deriveFont(Font.PLAIN,12f);
        int[] sizes={12,14,16}; int cases=0,widthDiff=0,rasterDiff=0;
        System.out.println("P2B_JDK_SHAPING_BOOT=PASS");
        for(int style=0;style<=7;style++) for(int zi=0;zi<sizes.length;zi++) {
            Font f=root.deriveFont(style,(float)sizes[zi]);
            BufferedImage mi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB); Graphics2D mg=mi.createGraphics(); mg.setFont(f); FontMetrics fm=mg.getFontMetrics(); mg.dispose();
            for(int si=0;si<SAMPLES.length;si++) {
                String s=SAMPLES[si]; int sum=0; for(int i=0;i<s.length();i++)sum+=fm.charWidth(s.charAt(i));
                int sw=fm.stringWidth(s); boolean[] whole=renderWhole(f,s), chars=renderChars(f,fm,s); int xd=xor(whole,chars);
                if(sw!=sum)widthDiff++; if(xd!=0)rasterDiff++; cases++;
                System.out.println("P2B_JDK_SHAPING STYLE="+style+" NORMALIZED="+f.getStyle()+" SIZE="+sizes[zi]+" SAMPLE="+si+
                    " UTF16="+s.length()+" CODEPOINTS="+s.codePointCount(0,s.length())+" STRING_WIDTH="+sw+" SUM_CHAR_WIDTH="+sum+
                    " WIDTH_DELTA="+(sw-sum)+" WHOLE_INK="+ink(whole)+" CHAR_INK="+ink(chars)+" XOR="+xd+
                    " WHOLE_FP="+Long.toHexString(fp(whole))+" CHAR_FP="+Long.toHexString(fp(chars)));
            }
        }
        System.out.println("P2B_JDK_SHAPING_CASES="+cases);
        System.out.println("P2B_JDK_SHAPING_WIDTH_DIFF_CASES="+widthDiff);
        System.out.println("P2B_JDK_SHAPING_RASTER_DIFF_CASES="+rasterDiff);
        System.out.println("P2B_JDK_SHAPING_RESULT=PASS");
    }
}
