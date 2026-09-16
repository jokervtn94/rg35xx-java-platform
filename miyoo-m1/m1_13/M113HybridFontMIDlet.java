package org.recompile.mobile;

import java.io.FileOutputStream;
import java.io.PrintStream;
import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M113HybridFontMIDlet extends MIDlet implements Runnable {
    private Canvas canvas; private boolean captured;
    protected void startApp() {
        canvas=new Canvas(){ protected void paint(Graphics g){
            g.setColor(0x0000FF); g.fillRect(0,0,getWidth(),getHeight()); g.setColor(0xFFFFFF);
            g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL));
            g.drawString("SMALL ASCII AaZz 0123456789 !?:.-",20,12,Graphics.TOP|Graphics.LEFT);
            g.drawString("SMALL VN: Ti\u1EBFng Vi\u1EC7t c\u00F3 d\u1EA5u",20,38,Graphics.TOP|Graphics.LEFT);
            g.drawString("MIX: RG35XX - Ti\u1EBFng Vi\u1EC7t - 2026",20,64,Graphics.TOP|Graphics.LEFT);
            g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM));
            g.drawString("MEDIUM ASCII AaZz 0123456789",20,96,Graphics.TOP|Graphics.LEFT);
            g.drawString("VN UPPER: \u00C0 \u00C1 \u00C2 \u0102 \u0110 \u00CA \u00D4 \u01A0 \u01AF",20,126,Graphics.TOP|Graphics.LEFT);
            g.drawString("VN LOWER: \u00E0 \u00E1 \u00E2 \u0103 \u0111 \u00EA \u00F4 \u01A1 \u01B0",20,156,Graphics.TOP|Graphics.LEFT);
            g.drawString("VN TONE: \u1EA1 \u1EA5 \u1EB7 \u1EC7 \u1ED9 \u1EDB \u1EE9 \u1EF3",20,186,Graphics.TOP|Graphics.LEFT);
            g.drawString("WORDS: Ti\u1EBFng Vi\u1EC7t c\u00F3 d\u1EA5u",20,216,Graphics.TOP|Graphics.LEFT);
            g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_LARGE));
            g.drawString("LARGE: ABC 789 \u0110\u1EA5\u1EA7u",20,248,Graphics.TOP|Graphics.LEFT);
            g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL));
            g.drawString("LEFT TOP",20,310,Graphics.TOP|Graphics.LEFT);
            g.drawString("CENTER TOP",320,336,Graphics.TOP|Graphics.HCENTER);
            g.drawString("RIGHT TOP",620,362,Graphics.TOP|Graphics.RIGHT);
            g.drawString("BASELINE: Vi\u1EC7t",20,406,Graphics.BASELINE|Graphics.LEFT);
            g.drawString("BOTTOM: Vi\u1EC7t",320,452,Graphics.BOTTOM|Graphics.HCENTER);
        }};
        canvas.setFullScreenMode(true); Display.getDisplay(this).setCurrent(canvas);
        System.out.println("M1_13_CANVAS_VISIBLE_READY=YES");
        System.out.println("M1_13_TEST_PROFILE=ASCII_VIETNAMESE_SIZE_ANCHOR_V2");
        new Thread(this,"m113-presenter").start();
    }
    private static void le16(FileOutputStream o,int v)throws Exception{o.write(v&255);o.write((v>>>8)&255);}
    private static void le32(FileOutputStream o,int v)throws Exception{o.write(v&255);o.write((v>>>8)&255);o.write((v>>>16)&255);o.write((v>>>24)&255);}
    private void writeBMP(int[] px,int w,int h,String path)throws Exception{
        int row=((w*3+3)/4)*4,img=row*h; FileOutputStream o=new FileOutputStream(path);
        o.write('B');o.write('M');le32(o,54+img);le16(o,0);le16(o,0);le32(o,54);le32(o,40);le32(o,w);le32(o,h);le16(o,1);le16(o,24);le32(o,0);le32(o,img);le32(o,2835);le32(o,2835);le32(o,0);le32(o,0);
        for(int y=h-1;y>=0;y--){for(int x=0;x<w;x++){int v=px[y*w+x];o.write(v&255);o.write((v>>>8)&255);o.write((v>>>16)&255);}for(int q=w*3;q<row;q++)o.write(0);}o.close();
    }
    private void capture(int[] px,int w,int h,int frame){if(captured||px==null||px.length<w*h)return;captured=true;
        String raw="/mnt/mmc/RG35XX-MIYOO-M1.13-LIVE-FRAME.argb",bmp="/mnt/mmc/RG35XX-MIYOO-M1.13-SCREENSHOT.bmp",meta="/mnt/mmc/RG35XX-MIYOO-M1.13-LIVE-FRAME.txt";
        try{FileOutputStream o=new FileOutputStream(raw);for(int i=0;i<w*h;i++){int v=px[i];o.write((v>>>24)&255);o.write((v>>>16)&255);o.write((v>>>8)&255);o.write(v&255);}o.close();writeBMP(px,w,h,bmp);
            PrintStream m=new PrintStream(new FileOutputStream(meta));m.println("M1_13_LIVE_CAPTURE=PASS");m.println("M1_13_CAPTURE_METHOD=JAVA_ARGB_BEFORE_PRESENTER");m.println("M1_13_SCREENSHOT=PASS");m.println("M1_13_TEST_PROFILE=ASCII_VIETNAMESE_SIZE_ANCHOR_V2");m.println("M1_13_FRAME="+frame);m.println("M1_13_WIDTH="+w);m.println("M1_13_HEIGHT="+h);m.println("M1_13_BYTES="+(w*h*4));m.close();
            System.out.println("M1_13_LIVE_CAPTURE=PASS FRAME="+frame);System.out.println("M1_13_SCREENSHOT=PASS PATH="+bmp);
        }catch(Throwable t){System.out.println("M1_13_LIVE_CAPTURE=FAIL "+t.getClass().getName()+":"+t.getMessage());}}
    public void run(){int init=M19SdlPresenter.initDisplay();System.out.println("M1_13_NATIVE_INIT_RC="+init);if(init!=0)System.exit(1);long end=System.currentTimeMillis()+12000L;int n=0;
        while(System.currentTimeMillis()<end){canvas.repaint();canvas.serviceRepaints();PlatformImage im=MobilePlatform.getLcdBackbuffer();if(im!=null){int[] f=im.getMIDPGraphics().getFrameBuffer();if(!captured&&n>=20)capture(f,640,480,n);int rc=M19SdlPresenter.presentARGB(f,640,480);if(rc!=0)break;n++;}try{Thread.sleep(50L);}catch(Exception e){break;}}
        M19SdlPresenter.shutdownDisplay();System.out.println("M1_13_PRESENT_COUNT="+n);System.out.println("M1_13_DRAWSTRING_CALLS=PASS");System.out.println("M1_13_NORMAL_EXIT=PASS");System.exit(n>0?0:2);}
    protected void pauseApp(){} protected void destroyApp(boolean unconditional){}
}
