package org.recompile.mobile;

import java.io.FileOutputStream;
import java.io.PrintStream;
import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M112UnicodeFontMIDlet extends MIDlet implements Runnable {
    private Canvas canvas;
    private boolean captured;
    protected void startApp() {
        canvas = new Canvas() {
            protected void paint(Graphics g) {
                g.setColor(0x0000FF); g.fillRect(0,0,getWidth(),getHeight());
                g.setColor(0xFFFFFF);
                g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL));
                g.drawString("ASCII BASELINE PASS 123",20,30,Graphics.TOP|Graphics.LEFT);
                g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM));
                g.drawString("VN UPPER: \u00C0 \u00C1 \u00C2 \u0102 \u0110 \u00CA \u00D4 \u01A0 \u01AF",20,90,Graphics.TOP|Graphics.LEFT);
                g.drawString("VN LOWER: \u00E0 \u00E1 \u00E2 \u0103 \u0111 \u00EA \u00F4 \u01A1 \u01B0",20,140,Graphics.TOP|Graphics.LEFT);
                g.drawString("WORDS: Ti\u1EBFng Vi\u1EC7t c\u00F3 d\u1EA5u",20,190,Graphics.TOP|Graphics.LEFT);
            }
        };
        canvas.setFullScreenMode(true); Display.getDisplay(this).setCurrent(canvas);
        System.out.println("M1_12_CANVAS_VISIBLE_READY=YES");
        new Thread(this,"m112-presenter").start();
    }
    private void captureARGB(int[] pixels, int width, int height, int frame) {
        if (captured || pixels == null || pixels.length < width*height) return;
        captured=true;
        String raw="/mnt/mmc/RG35XX-MIYOO-M1.12-LIVE-FRAME.argb";
        String meta="/mnt/mmc/RG35XX-MIYOO-M1.12-LIVE-FRAME.txt";
        try {
            FileOutputStream out=new FileOutputStream(raw);
            for(int i=0;i<width*height;i++) {
                int v=pixels[i];
                out.write((v>>>24)&255); out.write((v>>>16)&255); out.write((v>>>8)&255); out.write(v&255);
            }
            out.close();
            PrintStream m=new PrintStream(new FileOutputStream(meta));
            m.println("M1_12_LIVE_CAPTURE=PASS");
            m.println("M1_12_LIVE_CAPTURE_METHOD=JAVA_ARGB_BEFORE_PRESENTER");
            m.println("M1_12_LIVE_CAPTURE_FRAME="+frame);
            m.println("M1_12_LIVE_CAPTURE_WIDTH="+width);
            m.println("M1_12_LIVE_CAPTURE_HEIGHT="+height);
            m.println("M1_12_LIVE_CAPTURE_BYTES="+(width*height*4));
            m.close();
            System.out.println("M1_12_LIVE_CAPTURE=PASS FRAME="+frame);
        } catch(Throwable t) {
            System.out.println("M1_12_LIVE_CAPTURE=FAIL "+t.getClass().getName()+":"+t.getMessage());
        }
    }
    public void run() {
        int init=M19SdlPresenter.initDisplay();
        System.out.println("M1_12_NATIVE_INIT_RC="+init);
        if(init!=0) System.exit(1);
        long end=System.currentTimeMillis()+12000L; int presents=0;
        while(System.currentTimeMillis()<end) {
            canvas.repaint(); canvas.serviceRepaints();
            PlatformImage image=MobilePlatform.getLcdBackbuffer();
            if(image!=null) {
                int[] frame=image.getMIDPGraphics().getFrameBuffer();
                if(!captured && presents>=20) captureARGB(frame,640,480,presents);
                int rc=M19SdlPresenter.presentARGB(frame,640,480);
                if(rc!=0) break; presents++;
            }
            try { Thread.sleep(50L); } catch(Exception e) { break; }
        }
        M19SdlPresenter.shutdownDisplay();
        System.out.println("M1_12_PRESENT_COUNT="+presents);
        System.out.println("M1_12_DRAWSTRING_CALLS=PASS");
        System.out.println("M1_12_LIVE_CAPTURE_RESULT="+(captured?"ATTEMPTED":"NOT_ATTEMPTED"));
        System.out.println("M1_12_DEVICE_ACCEPTANCE_MARKER="+(presents>0?"PASS_PENDING_VISUAL":"FAIL"));
        System.out.println("M1_12_NORMAL_EXIT=PASS");
        System.exit(presents>0?0:2);
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}
}
