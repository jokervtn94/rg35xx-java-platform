import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Font;
import javax.microedition.lcdui.Graphics;
import javax.microedition.media.Manager;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.RecordStore;

public final class RG35XXSwitchProbe extends MIDlet {
    private ProbeCanvas canvas;

    protected void startApp() {
        if (canvas == null) canvas = new ProbeCanvas(this);
        Display.getDisplay(this).setCurrent(canvas);
    }
    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) {}
    void exit() { notifyDestroyed(); }

    static final class ProbeCanvas extends Canvas {
        private final RG35XXSwitchProbe midlet;
        private int bootCount;
        private String rms = "not run";
        private String tone = "FIRE: play tone";
        private int presses;

        ProbeCanvas(RG35XXSwitchProbe m) {
            midlet = m;
            setFullScreenMode(true);
            rmsTest();
        }

        protected void paint(Graphics g) {
            int w=getWidth(), h=getHeight();
            g.setColor(0x3A0CA3); g.fillRect(0,0,w,h);
            g.setColor(0xF72585); g.fillRect(0,0,w,45);
            g.setColor(0xFFFFFF);
            g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_LARGE));
            g.drawString("RC1 SWITCH PROBE B",12,10,Graphics.TOP|Graphics.LEFT);
            g.setFont(Font.getDefaultFont());
            g.drawString("Unique purple screen = Probe B is active",12,75,Graphics.TOP|Graphics.LEFT);
            g.drawString("RMS boot counter: "+bootCount,12,110,Graphics.TOP|Graphics.LEFT);
            g.drawString("RMS: "+rms,12,135,Graphics.TOP|Graphics.LEFT);
            g.drawString("Input presses: "+presses,12,170,Graphics.TOP|Graphics.LEFT);
            g.drawString(tone,12,205,Graphics.TOP|Graphics.LEFT);
            g.drawString("Switch back to RG35XX RC1 Device Test via menu.",12,250,Graphics.TOP|Graphics.LEFT);
            g.drawString("Repeat A <-> B at least 5 times.",12,275,Graphics.TOP|Graphics.LEFT);
            g.drawString("Expected: no stuck key, stale image/audio, lost RMS.",12,310,Graphics.TOP|Graphics.LEFT);
            g.drawString("FIRE tone   0 exit",12,h-35,Graphics.TOP|Graphics.LEFT);
        }

        public void keyPressed(int keyCode) {
            presses++;
            if (keyCode == KEY_NUM0) { midlet.exit(); return; }
            int a=0; try { a=getGameAction(keyCode); } catch(Throwable t) {}
            if (a == FIRE) {
                try { Manager.playTone(76,450,90); tone="tone called"; }
                catch(Throwable t) { tone="FAIL "+t.getClass().getName(); }
            }
            repaint();
        }

        private void rmsTest() {
            RecordStore rs=null;
            try {
                rs=RecordStore.openRecordStore("rg35xx_rc1_switch_probe",true);
                int v=0;
                if (rs.getNumRecords()==0) {
                    byte[] b=bytes(1); rs.addRecord(b,0,b.length); v=1;
                } else {
                    v=toInt(rs.getRecord(1))+1;
                    byte[] b=bytes(v); rs.setRecord(1,b,0,b.length);
                }
                bootCount=toInt(rs.getRecord(1));
                rms=(bootCount==v)?"PASS":"FAIL verify";
            } catch(Throwable t) { rms="FAIL "+t.getClass().getName(); }
            finally { if(rs!=null) try{rs.closeRecordStore();}catch(Throwable t){} }
        }
        private byte[] bytes(int v) { return new byte[]{(byte)(v>>>24),(byte)(v>>>16),(byte)(v>>>8),(byte)v}; }
        private int toInt(byte[] b) { if(b==null||b.length<4)return 0; return ((b[0]&255)<<24)|((b[1]&255)<<16)|((b[2]&255)<<8)|(b[3]&255); }
    }
}
