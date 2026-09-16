package org.recompile.mobile;

import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;

public final class M111TextFontMIDlet extends MIDlet {
    protected void startApp() {
        final Canvas c = new Canvas() {
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
                System.out.println("M1_11_DRAWSTRING_CALLS=PASS");
            }
        };
        c.setFullScreenMode(true); Display.getDisplay(this).setCurrent(c);
        System.out.println("M1_11_CANVAS_VISIBLE_READY=YES");
        new Thread(new Runnable(){ public void run(){
            try { Thread.sleep(12000); } catch(Exception e) {}
            System.out.println("M1_11_NORMAL_EXIT=PASS");
            System.exit(0);
        }}).start();
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}
}
