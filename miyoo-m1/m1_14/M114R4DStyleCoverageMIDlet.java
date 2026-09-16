package org.recompile.mobile;

import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M114R4DStyleCoverageMIDlet extends MIDlet implements Runnable {
    private Canvas canvas;
    private static void report(String tag, Font f) {
        System.out.println("M1_14_R4D_"+tag+"_FACE="+f.getFace());
        System.out.println("M1_14_R4D_"+tag+"_STYLE="+f.getStyle());
        System.out.println("M1_14_R4D_"+tag+"_SIZE="+f.getSize());
        System.out.println("M1_14_R4D_"+tag+"_HEIGHT="+f.getHeight());
        System.out.println("M1_14_R4D_"+tag+"_BASELINE="+f.getBaselinePosition());
        System.out.println("M1_14_R4D_"+tag+"_ASCII_WIDTH="+f.stringWidth("ABC 123"));
        System.out.println("M1_14_R4D_"+tag+"_VN_WIDTH="+f.stringWidth("Ti\u1EBFng Vi\u1EC7t"));
        System.out.println("M1_14_R4D_"+tag+"_CJK_WIDTH="+f.stringWidth("\u4E2D\u6587"));
    }
    protected void startApp() {
        final Font plain=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
        final Font bold=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM);
        final Font italic=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_ITALIC,Font.SIZE_MEDIUM);
        final Font under=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_UNDERLINED,Font.SIZE_MEDIUM);
        final Font combo=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD|Font.STYLE_ITALIC|Font.STYLE_UNDERLINED,Font.SIZE_MEDIUM);
        report("PLAIN",plain); report("BOLD",bold); report("ITALIC",italic); report("UNDER",under); report("COMBO",combo);
        canvas=new Canvas(){ protected void paint(Graphics g){
            g.setColor(0x0000FF); g.fillRect(0,0,getWidth(),getHeight()); g.setColor(0xFFFFFF);
            g.setFont(plain); g.drawString("PLAIN: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,30,Graphics.TOP|Graphics.LEFT);
            g.setFont(bold); g.drawString("BOLD: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,90,Graphics.TOP|Graphics.LEFT);
            g.setFont(italic); g.drawString("ITALIC: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,150,Graphics.TOP|Graphics.LEFT);
            g.setFont(under); g.drawString("UNDER: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,210,Graphics.TOP|Graphics.LEFT);
            g.setFont(combo); g.drawString("COMBO: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,270,Graphics.TOP|Graphics.LEFT);
            g.setFont(plain); g.drawString("R4D DIAGNOSTIC ONLY - NO STYLE RASTER PATCH",20,380,Graphics.TOP|Graphics.LEFT);
        }};
        canvas.setFullScreenMode(true); Display.getDisplay(this).setCurrent(canvas);
        System.out.println("M1_14_R4D_CANVAS_VISIBLE_READY=YES");
        new Thread(this,"m114-r4d-presenter").start();
    }
    public void run(){int rc=M19SdlPresenter.initDisplay();System.out.println("M1_14_R4D_NATIVE_INIT_RC="+rc);if(rc!=0)System.exit(1);long end=System.currentTimeMillis()+12000L;int n=0;while(System.currentTimeMillis()<end){canvas.repaint();canvas.serviceRepaints();PlatformImage im=MobilePlatform.getLcdBackbuffer();if(im!=null){int[] f=im.getMIDPGraphics().getFrameBuffer();if(M19SdlPresenter.presentARGB(f,640,480)!=0)break;n++;}try{Thread.sleep(50);}catch(Exception e){break;}}M19SdlPresenter.shutdownDisplay();System.out.println("M1_14_R4D_PRESENT_COUNT="+n);System.out.println("M1_14_R4D_NORMAL_EXIT=PASS");System.exit(n>0?0:2);}
    protected void pauseApp(){} protected void destroyApp(boolean unconditional){}
}
