package org.recompile.rg35xx.p2b;

import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.HashSet;
import org.recompile.rg35xx.RG35XXCore2D;

/** Host differential for the owner-scoped P2B runtime boundary. JDK8/AWT is
 * the semantic reference required by the locked Miyoo-first audit. */
public final class RG35XXP2BFontTextHostGate {
    private static final String[] SIMPLE = new String[] {
        "ABCxyz09", "iiiiWWWW", "Tieng Viet", "Tiếng Việt", "Đặng", "中文"
    };
    private static final String[] COMPLEX = new String[] {
        "Tie\u0302\u0301ng Vie\u0323\u0302t", "A\u0301", "\u0633\u0644\u0627\u0645", "\u0644\u0627",
        "\u05e9\u05dc\u05d5\u05dd", "\u0928\u092e\u0938\u094d\u0924\u0947", "\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22", "A\u200DB"
    };

    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("usage: gate <font.ttf>");
        File file = new File(args[0]);
        Font loaded = Font.createFont(Font.TRUETYPE_FONT, file);
        Font global = loaded.deriveFont(Font.PLAIN, 12f);
        int[] points = {12,14,16};
        int[] midpSizes = {8,0,16};
        int metricCases=0, simpleCases=0, complexCases=0, failures=0;

        for (int st=0; st<8; st++) for (int zi=0; zi<points.length; zi++) {
            int point=points[zi], midp=midpSizes[zi];
            Font f=global.deriveFont(st,(float)point);
            BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_BYTE_BINARY);
            Graphics2D g=bi.createGraphics(); g.setFont(f); FontMetrics fm=g.getFontMetrics();
            if (RG35XXCore2D.fontHeight(midp)!=fm.getHeight()) failures++;
            if (RG35XXCore2D.fontAscent(midp)!=fm.getAscent()) failures++;
            if (RG35XXCore2D.fontDescent(midp)!=fm.getDescent()) failures++;
            metricCases++;
            for (int i=0;i<SIMPLE.length;i++) {
                String s=SIMPLE[i];
                if (RG35XXCore2D.stringWidth(s,midp,0,st)!=fm.stringWidth(s)) failures++;
                if (!rasterMatches(f,s,RG35XXCore2D.textRaster(s,midp,0,st))) failures++;
                simpleCases++;
            }
            for (int i=0;i<COMPLEX.length;i++) {
                String s=COMPLEX[i];
                if (RG35XXCore2D.stringWidth(s,midp,0,st)!=fm.stringWidth(s)) failures++;
                if (!rasterMatches(f,s,RG35XXCore2D.textRaster(s,midp,0,st))) failures++;
                complexCases++;
            }
            g.dispose();
        }

        // Integration spot-check for exact JDK8 char-width rounding and missing-glyph handling.
        int[] chars={0,9,13,'A','i','W',0x00e1,0x0110,0x4e2d,0x200d,0xffff};
        for(int zi=0;zi<points.length;zi++) {
            Font f=global.deriveFont(Font.PLAIN,(float)points[zi]);
            BufferedImage bi=new BufferedImage(1,1,BufferedImage.TYPE_BYTE_BINARY);
            Graphics2D g=bi.createGraphics(); g.setFont(f); FontMetrics fm=g.getFontMetrics();
            for(int i=0;i<chars.length;i++) {
                int got=RG35XXCore2D.charWidth((char)chars[i],midpSizes[zi],0,0);
                if(got!=fm.charWidth((char)chars[i])) failures++;
            }
            g.dispose();
        }

        System.out.println("P2B_HOST_METRIC_CASES="+metricCases);
        System.out.println("P2B_HOST_SIMPLE_RASTER_CASES="+simpleCases);
        System.out.println("P2B_HOST_COMPLEX_RASTER_CASES="+complexCases);
        System.out.println("P2B_HOST_FAILURE_COUNT="+failures);
        if(failures!=0) throw new RuntimeException("P2B host differential failures="+failures);
        System.out.println("P2B_HOST_FONT_METRICS_GATE=PASS");
        System.out.println("P2B_HOST_SIMPLE_RASTER_GATE=PASS");
        System.out.println("P2B_HOST_COMPLEX_LAYOUT_GATE=PASS");
        System.out.println("P2B_HOST_FONT_TEXT_GATE=PASS");
    }

    private static boolean rasterMatches(Font font,String s,int[] raw) {
        final int W=640,H=192,baseX=128,baseY=96;
        BufferedImage bi=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
        Graphics2D g=bi.createGraphics(); g.setFont(font); g.setColor(new java.awt.Color(0,0,0,255)); g.drawString(s,baseX,baseY); g.dispose();
        HashSet ref=new HashSet();
        for(int y=0;y<H;y++) for(int x=0;x<W;x++) if((bi.getRGB(x,y)>>>24)!=0) ref.add(Integer.valueOf(y*W+x));
        HashSet got=new HashSet();
        if(raw==null || raw.length<2 || raw.length!=2+raw[1]*2) return false;
        for(int i=0;i<raw[1];i++) {
            int x=baseX+raw[2+i*2], y=baseY+raw[3+i*2];
            if(x>=0&&x<W&&y>=0&&y<H) got.add(Integer.valueOf(y*W+x));
        }
        return ref.equals(got);
    }
}
