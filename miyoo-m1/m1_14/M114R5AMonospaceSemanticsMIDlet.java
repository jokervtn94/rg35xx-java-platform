package org.recompile.mobile;

import javax.microedition.lcdui.*;
import javax.microedition.midlet.MIDlet;
import java.io.*;

public final class M114R5AMonospaceSemanticsMIDlet extends MIDlet {
    private ProbeCanvas canvas;
    public void startApp() {
        System.out.println("M1_14_R5A_PRIMARY_VARIABLE=MONOSPACE_LAYOUT_SEMANTICS_ONLY");
        Font sys=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
        Font mono=Font.getFont(Font.FACE_MONOSPACE,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
        log("SYSTEM",sys); log("MONOSPACE",mono);
        canvas=new ProbeCanvas(sys,mono); Display.getDisplay(this).setCurrent(canvas);
        System.out.println("M1_14_R5A_CANVAS_VISIBLE_READY=YES");
        Thread t=new Thread(new Runnable(){ public void run(){ runPresenter(); }}); t.start();
    }
    private static void log(String n,Font f) {
        System.out.println("M1_14_R5A_"+n+"_FACE="+f.getFace());
        System.out.println("M1_14_R5A_"+n+"_STYLE="+f.getStyle());
        System.out.println("M1_14_R5A_"+n+"_SIZE="+f.getSize());
        System.out.println("M1_14_R5A_"+n+"_HEIGHT="+f.getHeight());
        System.out.println("M1_14_R5A_"+n+"_BASELINE="+f.getBaselinePosition());
        System.out.println("M1_14_R5A_"+n+"_ASCII_WIDTH="+f.stringWidth("ABC 123"));
        System.out.println("M1_14_R5A_"+n+"_III_WIDTH="+f.stringWidth("iii"));
        System.out.println("M1_14_R5A_"+n+"_WWW_WIDTH="+f.stringWidth("WWW"));
        System.out.println("M1_14_R5A_"+n+"_VN_WIDTH="+f.stringWidth("Tiếng Việt"));
        System.out.println("M1_14_R5A_"+n+"_CJK_WIDTH="+f.stringWidth("中文"));
    }
    private void runPresenter() {
        int rc=M19SdlPresenter.initDisplay(640,480); System.out.println("M1_14_R5A_NATIVE_INIT_RC="+rc);
        int count=0; long end=System.currentTimeMillis()+12000L;
        while(rc==0 && System.currentTimeMillis()<end) {
            canvas.repaint(); canvas.serviceRepaints();
            int[] p=Mobile.getPlatform().getLCD();
            M19SdlPresenter.present(p,640,480); count++;
            if(count==20) capture(p,640,480,count);
            try { Thread.sleep(250L); } catch(Exception e) {}
        }
        M19SdlPresenter.shutdownDisplay();
        System.out.println("M1_14_R5A_PRESENT_COUNT="+count);
        System.out.println("M1_14_R5A_NORMAL_EXIT=PASS"); notifyDestroyed();
    }
    private static void capture(int[] p,int w,int h,int frame) {
        String shot="/mnt/mmc/RG35XX-MIYOO-M1.14-R5A-SCREENSHOT.bmp";
        String meta="/mnt/mmc/RG35XX-MIYOO-M1.14-R5A-LIVE-FRAME.txt";
        try {
            DataOutputStream o=new DataOutputStream(new FileOutputStream(shot));
            int row=w*3, pad=(4-(row&3))&3, image=(row+pad)*h, size=54+image;
            o.writeByte('B');o.writeByte('M');le32(o,size);le32(o,0);le32(o,54);le32(o,40);le32(o,w);le32(o,h);le16(o,1);le16(o,24);le32(o,0);le32(o,image);le32(o,2835);le32(o,2835);le32(o,0);le32(o,0);
            for(int y=h-1;y>=0;y--){ for(int x=0;x<w;x++){int c=p[y*w+x];o.writeByte(c&255);o.writeByte((c>>>8)&255);o.writeByte((c>>>16)&255);} for(int q=0;q<pad;q++)o.writeByte(0); }
            o.close();
            PrintStream m=new PrintStream(new FileOutputStream(meta));
            m.println("M1_14_R5A_LIVE_CAPTURE=PASS");m.println("M1_14_R5A_CAPTURE_METHOD=JAVA_ARGB_BEFORE_PRESENTER");m.println("M1_14_R5A_SCREENSHOT=PASS");m.println("M1_14_R5A_SCREENSHOT_PATH="+shot);m.println("M1_14_R5A_FRAME="+frame);m.println("M1_14_R5A_WIDTH="+w);m.println("M1_14_R5A_HEIGHT="+h);m.close();
            System.out.println("M1_14_R5A_LIVE_CAPTURE=PASS FRAME="+frame); System.out.println("M1_14_R5A_SCREENSHOT=PASS PATH="+shot);
        } catch(Throwable t) { System.out.println("M1_14_R5A_CAPTURE=FAIL "+t); }
    }
    private static void le16(DataOutputStream o,int v)throws IOException{o.writeByte(v);o.writeByte(v>>>8);}
    private static void le32(DataOutputStream o,int v)throws IOException{o.writeByte(v);o.writeByte(v>>>8);o.writeByte(v>>>16);o.writeByte(v>>>24);}
    protected void pauseApp(){} protected void destroyApp(boolean u){}
    static final class ProbeCanvas extends Canvas {
        final Font sys,mono; ProbeCanvas(Font s,Font m){sys=s;mono=m;setFullScreenMode(true);}
        protected void paint(Graphics g){
            g.setColor(0x123050);g.fillRect(0,0,getWidth(),getHeight());g.setColor(0xFFFFFF);
            g.setFont(sys);g.drawString("SYSTEM: ABC 123 - iii - WWW",24,80,Graphics.TOP|Graphics.LEFT);g.drawString("SYSTEM: Tiếng Việt - 中文",24,112,Graphics.TOP|Graphics.LEFT);
            g.setFont(mono);g.drawString("MONO: ABC 123 - iii - WWW",24,176,Graphics.TOP|Graphics.LEFT);g.drawString("MONO: Tiếng Việt - 中文",24,208,Graphics.TOP|Graphics.LEFT);
            g.setFont(sys);g.drawString("r5A: MONOSPACE fixed 12-cell A/B",24,288,Graphics.TOP|Graphics.LEFT);
        }
    }
}
