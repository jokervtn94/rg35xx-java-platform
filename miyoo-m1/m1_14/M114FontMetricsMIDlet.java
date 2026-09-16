package org.recompile.mobile;

import java.io.FileOutputStream;
import java.io.PrintStream;
import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M114FontMetricsMIDlet extends MIDlet implements Runnable {
    private Canvas canvas; private boolean captured;
    private static void metric(String tag, Font f) {
        String ascii="ABC 123";
        String vn="Ti\u1EBFng Vi\u1EC7t";
        String wide="\u4E2D\u6587";
        System.out.println("M1_14_METRIC_"+tag+"_HEIGHT="+f.getHeight());
        System.out.println("M1_14_METRIC_"+tag+"_BASELINE="+f.getBaselinePosition());
        System.out.println("M1_14_METRIC_"+tag+"_ASCII_WIDTH="+f.stringWidth(ascii));
        System.out.println("M1_14_METRIC_"+tag+"_VN_WIDTH="+f.stringWidth(vn));
        System.out.println("M1_14_METRIC_"+tag+"_WIDE_WIDTH="+f.stringWidth(wide));
        System.out.println("M1_14_METRIC_"+tag+"_I_WIDTH="+f.charWidth('I'));
        System.out.println("M1_14_METRIC_"+tag+"_VIET_WIDTH="+f.charWidth('\u1EC7'));
        System.out.println("M1_14_METRIC_"+tag+"_CJK_WIDTH="+f.charWidth('\u4E2D'));
    }
    protected void startApp() {
        final Font small=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL);
        final Font medium=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
        final Font large=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_LARGE);
        metric("SMALL",small); metric("MEDIUM",medium); metric("LARGE",large);
        canvas=new Canvas(){ protected void paint(Graphics g){
            g.setColor(0x0000FF);g.fillRect(0,0,getWidth(),getHeight());g.setColor(0xFFFFFF);
            g.setFont(small);g.drawString("SMALL ASCII AaZz 0123456789 !?:.-",20,12,Graphics.TOP|Graphics.LEFT);
            g.drawString("SMALL VN: Ti\u1EBFng Vi\u1EC7t c\u00F3 d\u1EA5u",20,38,Graphics.TOP|Graphics.LEFT);
            g.drawString("MIX: RG35XX - Ti\u1EBFng Vi\u1EC7t - 2026",20,64,Graphics.TOP|Graphics.LEFT);
            g.setFont(medium);g.drawString("MEDIUM ASCII AaZz 0123456789",20,96,Graphics.TOP|Graphics.LEFT);
            g.drawString("VN UPPER: \u00C0 \u00C1 \u00C2 \u0102 \u0110 \u00CA \u00D4 \u01A0 \u01AF",20,126,Graphics.TOP|Graphics.LEFT);
            g.drawString("VN LOWER: \u00E0 \u00E1 \u00E2 \u0103 \u0111 \u00EA \u00F4 \u01A1 \u01B0",20,156,Graphics.TOP|Graphics.LEFT);
            g.drawString("CJK WIDTH: \u4E2D\u6587",20,186,Graphics.TOP|Graphics.LEFT);
            g.setFont(large);g.drawString("LARGE: ABC 789 \u0110\u1EA5u",20,218,Graphics.TOP|Graphics.LEFT);
            g.setFont(small);g.drawString("LEFT TOP",20,300,Graphics.TOP|Graphics.LEFT);
            g.drawString("CENTER TOP",320,326,Graphics.TOP|Graphics.HCENTER);
            g.drawString("RIGHT TOP",620,352,Graphics.TOP|Graphics.RIGHT);
            g.drawString("BASELINE: Vi\u1EC7t",20,406,Graphics.BASELINE|Graphics.LEFT);
            g.drawString("BOTTOM: Vi\u1EC7t",320,452,Graphics.BOTTOM|Graphics.HCENTER);
        }};
        canvas.setFullScreenMode(true);Display.getDisplay(this).setCurrent(canvas);
        System.out.println("M1_14_CANVAS_VISIBLE_READY=YES");
        System.out.println("M1_14_TEST_PROFILE=FONT_METRICS_SEMANTICS_V1");
        new Thread(this,"m114-presenter").start();
    }
    private static void le16(FileOutputStream o,int v)throws Exception{o.write(v&255);o.write((v>>>8)&255);}
    private static void le32(FileOutputStream o,int v)throws Exception{o.write(v&255);o.write((v>>>8)&255);o.write((v>>>16)&255);o.write((v>>>24)&255);}
    private void bmp(int[] p,int w,int h,String path)throws Exception{int row=((w*3+3)/4)*4,img=row*h;FileOutputStream o=new FileOutputStream(path);o.write('B');o.write('M');le32(o,54+img);le16(o,0);le16(o,0);le32(o,54);le32(o,40);le32(o,w);le32(o,h);le16(o,1);le16(o,24);le32(o,0);le32(o,img);le32(o,2835);le32(o,2835);le32(o,0);le32(o,0);for(int y=h-1;y>=0;y--){for(int x=0;x<w;x++){int v=p[y*w+x];o.write(v&255);o.write((v>>>8)&255);o.write((v>>>16)&255);}for(int q=w*3;q<row;q++)o.write(0);}o.close();}
    private void capture(int[] p,int w,int h,int frame){if(captured||p==null||p.length<w*h)return;captured=true;try{String raw="/mnt/mmc/RG35XX-MIYOO-M1.14-LIVE-FRAME.argb",shot="/mnt/mmc/RG35XX-MIYOO-M1.14-SCREENSHOT.bmp",meta="/mnt/mmc/RG35XX-MIYOO-M1.14-LIVE-FRAME.txt";FileOutputStream o=new FileOutputStream(raw);for(int i=0;i<w*h;i++){int v=p[i];o.write((v>>>24)&255);o.write((v>>>16)&255);o.write((v>>>8)&255);o.write(v&255);}o.close();bmp(p,w,h,shot);PrintStream m=new PrintStream(new FileOutputStream(meta));m.println("M1_14_LIVE_CAPTURE=PASS");m.println("M1_14_CAPTURE_METHOD=JAVA_ARGB_BEFORE_PRESENTER");m.println("M1_14_SCREENSHOT=PASS");m.println("M1_14_FRAME="+frame);m.println("M1_14_WIDTH="+w);m.println("M1_14_HEIGHT="+h);m.close();System.out.println("M1_14_LIVE_CAPTURE=PASS FRAME="+frame);System.out.println("M1_14_SCREENSHOT=PASS");}catch(Throwable t){System.out.println("M1_14_CAPTURE=FAIL "+t);}}
    public void run(){int rc=M19SdlPresenter.initDisplay();System.out.println("M1_14_NATIVE_INIT_RC="+rc);if(rc!=0)System.exit(1);long end=System.currentTimeMillis()+12000L;int n=0;while(System.currentTimeMillis()<end){canvas.repaint();canvas.serviceRepaints();PlatformImage im=MobilePlatform.getLcdBackbuffer();if(im!=null){int[] f=im.getMIDPGraphics().getFrameBuffer();if(!captured&&n>=20)capture(f,640,480,n);if(M19SdlPresenter.presentARGB(f,640,480)!=0)break;n++;}try{Thread.sleep(50);}catch(Exception e){break;}}M19SdlPresenter.shutdownDisplay();System.out.println("M1_14_PRESENT_COUNT="+n);System.out.println("M1_14_NORMAL_EXIT=PASS");System.exit(n>0?0:2);}
    protected void pauseApp(){} protected void destroyApp(boolean unconditional){}
}
