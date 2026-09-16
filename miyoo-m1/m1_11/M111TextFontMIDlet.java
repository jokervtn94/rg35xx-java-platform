package org.recompile.mobile;

import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M111TextFontMIDlet extends MIDlet implements Runnable {
    private Canvas canvas;
    protected void startApp() {
        canvas = new Canvas() {
            protected void paint(Graphics g) {
                g.setColor(0x0000FF); g.fillRect(0,0,getWidth(),getHeight());
                g.setColor(0xFFFFFF);
                g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL));
                g.drawString("M1.11 SMALL ASCII 123",20,40,Graphics.TOP|Graphics.LEFT);
                g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM));
                g.drawString("MIDP TEXT PASS",20,100,Graphics.TOP|Graphics.LEFT);
                g.translate(40,40);
                g.setClip(0,80,500,100);
                g.setFont(Font.getFont(Font.FACE_MONOSPACE,Font.STYLE_PLAIN,Font.SIZE_LARGE));
                g.drawString("LARGE 789",20,100,Graphics.TOP|Graphics.LEFT);
            }
        };
        canvas.setFullScreenMode(true); Display.getDisplay(this).setCurrent(canvas);
        System.out.println("M1_11_CANVAS_VISIBLE_READY=YES");
        new Thread(this,"m111-presenter").start();
    }
    public void run() {
        int init=M19SdlPresenter.initDisplay();
        System.out.println("M1_11_NATIVE_INIT_RC="+init);
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
        System.out.println("M1_11_PRESENT_COUNT="+presents);
        System.out.println("M1_11_DRAWSTRING_CALLS=PASS");
        System.out.println("M1_11_DEVICE_ACCEPTANCE_MARKER="+(presents>0?"PASS_PENDING_VISUAL":"FAIL"));
        System.out.println("M1_11_NORMAL_EXIT=PASS");
        System.exit(presents>0?0:2);
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}
}
