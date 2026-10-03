package org.recompile.rg35xx.p2b;

import java.util.HashSet;
import javax.microedition.lcdui.Font;
import javax.microedition.lcdui.Graphics;
import org.recompile.mobile.PlatformGraphics;
import org.recompile.mobile.PlatformImage;
import org.recompile.rg35xx.RG35XXCore2D;

/** Integration gate through the actual staged MIDP Font + PlatformGraphics raw path. */
public final class RG35XXP2BFontTextModuleGate {
    public static void main(String[] args) throws Exception {
        System.setProperty("rg35xx.raw2d", "true");
        int failures=0;
        int cases=0;
        int[] sizes={Font.SIZE_SMALL,Font.SIZE_MEDIUM,Font.SIZE_LARGE};
        int[] styles={Font.STYLE_PLAIN,Font.STYLE_BOLD,Font.STYLE_ITALIC,
                      Font.STYLE_BOLD|Font.STYLE_ITALIC,Font.STYLE_UNDERLINED};
        String[] strings={"ABCxyz09","Tiếng Việt","Đặng","中文","A\u0301","\u0644\u0627"};
        int[] anchors={Graphics.TOP|Graphics.LEFT,Graphics.BASELINE|Graphics.LEFT,
                       Graphics.BOTTOM|Graphics.LEFT,Graphics.VCENTER|Graphics.HCENTER};

        for(int si=0;si<sizes.length;si++) for(int ti=0;ti<styles.length;ti++) {
            Font f=Font.getFont(Font.FACE_SYSTEM,styles[ti],sizes[si]);
            int expectedBase = sizes[si]==Font.SIZE_SMALL?12:(sizes[si]==Font.SIZE_LARGE?16:14);
            if(f.getBaselinePosition()!=expectedBase) failures++;
            if(f.getHeight()!=RG35XXCore2D.fontHeight(sizes[si])) failures++;
            for(int q=0;q<strings.length;q++) {
                String s=strings[q];
                if(f.stringWidth(s)!=RG35XXCore2D.stringWidth(s,sizes[si],Font.FACE_SYSTEM,styles[ti])) failures++;
                for(int ai=0;ai<anchors.length;ai++) {
                    PlatformImage image=new PlatformImage(320,128);
                    PlatformGraphics g=image.getGraphics();
                    g.setFont(f); g.setColor(0x000000);
                    int x=(anchors[ai]&Graphics.HCENTER)!=0?160:24;
                    int y=(anchors[ai]&Graphics.VCENTER)!=0?64:((anchors[ai]&Graphics.BOTTOM)!=0?104:((anchors[ai]&Graphics.BASELINE)!=0?72:20));
                    g.drawString(s,x,y,anchors[ai]);
                    if(!matchesExpected(image,s,f,x,y,anchors[ai])) failures++;
                    cases++;
                }
            }
        }

        System.out.println("P2B_MODULE_INTEGRATION_CASES="+cases);
        System.out.println("P2B_MODULE_INTEGRATION_FAILURE_COUNT="+failures);
        if(failures!=0) throw new RuntimeException("P2B module failures="+failures);
        System.out.println("P2B_FONT_BASELINE_CANONICAL_GATE=PASS");
        System.out.println("P2B_PLATFORMGRAPHICS_ANCHOR_GATE=PASS");
        System.out.println("P2B_WHOLE_STRING_RAW_RASTER_GATE=PASS");
        System.out.println("P2B_MODULE_GATE=PASS");
    }

    private static boolean matchesExpected(PlatformImage image,String s,Font f,int x,int y,int anchor) {
        int total=RG35XXCore2D.stringWidth(s,f.getSize(),f.getFace(),f.getStyle());
        int ascent=RG35XXCore2D.fontAscent(f.getSize());
        int descent=RG35XXCore2D.fontDescent(f.getSize());
        if((anchor&Graphics.RIGHT)>0) x-=total;
        else if((anchor&Graphics.HCENTER)>0) x-=total/2;
        if((anchor&Graphics.BOTTOM)>0) y-=descent;
        else if((anchor&Graphics.VCENTER)>0) y-=(descent+ascent)/2;
        else if((anchor&Graphics.BASELINE)==0) y+=ascent;
        int[] r=RG35XXCore2D.textRaster(s,f.getSize(),f.getFace(),f.getStyle());
        HashSet expected=new HashSet();
        int w=image.getRG35XXWidth(), h=image.getRG35XXHeight();
        for(int i=0;i<r[1];i++) {
            int px=x+r[2+i*2], py=y+r[3+i*2];
            if(px>=0&&px<w&&py>=0&&py<h) expected.add(Integer.valueOf(py*w+px));
        }
        HashSet actual=new HashSet();
        int[] p=image.getRG35XXPixels();
        for(int yy=0;yy<h;yy++) for(int xx=0;xx<w;xx++) if((p[yy*w+xx]&0x00ffffff)==0) actual.add(Integer.valueOf(yy*w+xx));
        return expected.equals(actual);
    }
}
