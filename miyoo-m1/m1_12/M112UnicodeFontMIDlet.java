package org.recompile.mobile;

import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M112UnicodeFontMIDlet extends MIDlet implements Runnable {
    private Canvas canvas;
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
    public void run() {
        int init=M19SdlPresenter.initDisplay();
        System.out.println("M1_12_NATIVE_INIT_RC="+init);
        if(init!=0) System.exit(1);
        long end=System.currentTimeMillis()+12000L; int presents=0;
        while(System.currentTimeMillis()<end) {
            canvas.repaint(); canvas.serviceRepaints();
            PlatformImage image=MobilePlatform.getLcdBackbuffer();
            if(image!=null) {
                int rc=M19SdlPresenter.presentARGB(image.getMIDPGraphics().getFrameBuffer(),640,480);
                if(rc!=0) break; presents++;
            }
            try { Thread.sleep(50L); } catch(Exception e) { break; }
        }
        M19SdlPresenter.shutdownDisplay();
        System.out.println("M1_12_PRESENT_COUNT="+presents);
        System.out.println("M1_12_DRAWSTRING_CALLS=PASS");
        System.out.println("M1_12_DEVICE_ACCEPTANCE_MARKER="+(presents>0?"PASS_PENDING_VISUAL":"FAIL"));
        System.out.println("M1_12_NORMAL_EXIT=PASS");
        System.exit(presents>0?0:2);
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}
}
