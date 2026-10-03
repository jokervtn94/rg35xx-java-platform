import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.lang.reflect.Method;

/**
 * Audit-only exact JDK8 Graphics2D.drawString raster reference for the full
 * established P2B 14-string corpus. Runtime code must not depend on this.
 */
public final class RG35XXP2BJdkWholeStringRasterDiagnostic {
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
    private static final int[] SIZES = new int[] {12,14,16};
    private static final int W=512, H=192, X=64, BASE=112;
    private static final long FNV_OFFSET=0xcbf29ce484222325L;
    private static final long FNV_PRIME=0x100000001b3L;

    private static Method findMethod(Class<?> c,String name,Class<?>[] sig) throws Exception {
        for(Class<?> k=c;k!=null;k=k.getSuperclass()) {
            try { Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m; }
            catch(NoSuchMethodException e) { }
        }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }
    private static long mix(long h,int v) {
        h^=(v>>>24)&255;h*=FNV_PRIME; h^=(v>>>16)&255;h*=FNV_PRIME;
        h^=(v>>>8)&255;h*=FNV_PRIME; h^=v&255;h*=FNV_PRIME; return h;
    }
    private static String hex4(int v) {
        String s=Integer.toHexString(v&0xffff).toUpperCase(); while(s.length()<4)s="0"+s; return s;
    }
    private static String utf16Hex(char[] a) {
        StringBuilder b=new StringBuilder(a.length*4); for(int i=0;i<a.length;i++)b.append(hex4(a[i])); return b.toString();
    }
    private static boolean drawComplex(Method charsToGlyphsNS,Object mapper,char[] chars) throws Exception {
        int[] glyphs=new int[chars.length];
        return ((Boolean)charsToGlyphsNS.invoke(mapper,new Object[]{Integer.valueOf(chars.length),chars,glyphs})).booleanValue();
    }

    public static void main(String[] args) throws Exception {
        if(args.length!=2) throw new IllegalArgumentException("usage: <font.ttf> <reference.tsv>");
        Font root=Font.createFont(Font.TRUETYPE_FONT,new File(args[0]));
        Class<?> fu=Class.forName("sun.font.FontUtilities");
        Method getFont2D=fu.getDeclaredMethod("getFont2D",new Class<?>[]{Font.class}); getFont2D.setAccessible(true);
        BufferedWriter out=new BufferedWriter(new FileWriter(args[1]));
        out.write("CASE\tSTYLE\tNORMALIZED\tSIZE\tSAMPLE\tDRAW_COMPLEX\tUTF16HEX\tWIDTH\tINK\tX0\tY0\tX1\tY1\tFP\n");
        int cases=0,complexCases=0,directCases=0;
        System.out.println("P2B_JDK8_WHOLE_RASTER_BOOT=PASS");
        for(int style=0;style<=7;style++) for(int zi=0;zi<SIZES.length;zi++) {
            int size=SIZES[zi]; Font f=root.deriveFont(style,(float)size);
            BufferedImage mi=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
            Graphics2D mg=mi.createGraphics(); mg.setFont(f); FontMetrics fm=mg.getFontMetrics(); mg.dispose();
            Object f2d=getFont2D.invoke(null,new Object[]{f});
            Method gm=findMethod(f2d.getClass(),"getMapper",new Class<?>[0]);
            Object mapper=gm.invoke(f2d,new Object[0]);
            Method c2g=findMethod(mapper.getClass(),"charsToGlyphsNS",new Class<?>[]{Integer.TYPE,char[].class,int[].class});
            for(int si=0;si<SAMPLES.length;si++) {
                String s=SAMPLES[si]; char[] ca=s.toCharArray(); boolean complex=drawComplex(c2g,mapper,ca);
                if(complex) complexCases++; else directCases++;
                BufferedImage bi=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
                Graphics2D g=bi.createGraphics(); g.setFont(f); g.setColor(new java.awt.Color(0,0,0,255)); g.drawString(s,X,BASE); g.dispose();
                int ink=0,x0=99999,y0=99999,x1=-99999,y1=-99999; long fp=FNV_OFFSET;
                for(int y=0;y<H;y++) for(int x=0;x<W;x++) {
                    if(((bi.getRGB(x,y)>>>24)&255)!=0) {
                        int rx=x-X, ry=y-BASE; ink++;
                        if(rx<x0)x0=rx; if(rx>x1)x1=rx; if(ry<y0)y0=ry; if(ry>y1)y1=ry;
                        fp=mix(fp,rx); fp=mix(fp,ry);
                    }
                }
                if(ink==0)x0=y0=x1=y1=-1;
                out.write(Integer.toString(cases));out.write('\t');
                out.write(Integer.toString(style));out.write('\t');
                out.write(Integer.toString(f.getStyle()));out.write('\t');
                out.write(Integer.toString(size));out.write('\t');
                out.write(Integer.toString(si));out.write('\t');
                out.write(complex?"1":"0");out.write('\t');
                out.write(utf16Hex(ca));out.write('\t');
                out.write(Integer.toString(fm.stringWidth(s)));out.write('\t');
                out.write(Integer.toString(ink));out.write('\t');
                out.write(Integer.toString(x0));out.write('\t');out.write(Integer.toString(y0));out.write('\t');
                out.write(Integer.toString(x1));out.write('\t');out.write(Integer.toString(y1));out.write('\t');
                out.write(Long.toHexString(fp));out.newLine();
                cases++;
            }
        }
        out.close();
        System.out.println("P2B_JDK8_WHOLE_RASTER_CASES="+cases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_COMPLEX_CASES="+complexCases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_DIRECT_CASES="+directCases);
        System.out.println("P2B_JDK8_WHOLE_RASTER_RESULT=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
    }
}
