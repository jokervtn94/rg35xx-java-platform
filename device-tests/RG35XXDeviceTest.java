import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Font;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;
import javax.microedition.lcdui.game.Sprite;
import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.media.PlayerListener;
import javax.microedition.media.control.ToneControl;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.RecordStore;

public final class RG35XXDeviceTest extends MIDlet {
    private static final String LOG_DIR="/mnt/mmc/Java/test-evidence";
    private static final String LOG_FILE=LOG_DIR+"/rg35xx-device-test.log";
    private TestCanvas canvas;

    protected void startApp() {
        log("startApp ENTER");
        try {
            if (canvas == null) canvas = new TestCanvas(this);
            log("canvas constructed");
            Display.getDisplay(this).setCurrent(canvas);
            log("canvas set current");
            canvas.start();
            log("canvas loop started");
        } catch (Throwable t) {
            logThrowable("startApp", t);
            try { Display.getDisplay(this).setCurrent(new FailureCanvas()); }
            catch (Throwable ignored) { logThrowable("failure canvas", ignored); }
        }
    }
    protected void pauseApp(){ log("pauseApp"); if(canvas!=null)canvas.pauseLoop(); }
    protected void destroyApp(boolean unconditional){ log("destroyApp"); if(canvas!=null)canvas.stopAll(); }
    void exit(){ try{destroyApp(true);}catch(Throwable t){logThrowable("exit",t);} notifyDestroyed(); }

    static void log(String s) {
        FileOutputStream out=null;
        try {
            File d=new File(LOG_DIR); if(!d.exists()) d.mkdirs();
            out=new FileOutputStream(LOG_FILE,true);
            String line=System.currentTimeMillis()+" "+s+"\n";
            out.write(line.getBytes("UTF-8")); out.flush();
        } catch(Throwable ignored) {} finally { if(out!=null)try{out.close();}catch(Throwable ignored){} }
    }
    static void logThrowable(String where, Throwable t) {
        FileOutputStream out=null; PrintStream ps=null;
        try {
            File d=new File(LOG_DIR); if(!d.exists()) d.mkdirs();
            out=new FileOutputStream(LOG_FILE,true); ps=new PrintStream(out);
            ps.println(System.currentTimeMillis()+" ERROR "+where+": "+t);
            t.printStackTrace(ps); ps.flush();
        } catch(Throwable ignored) {} finally { if(ps!=null)ps.close(); else if(out!=null)try{out.close();}catch(Throwable ignored){} }
    }

    static final class FailureCanvas extends Canvas {
        protected void paint(Graphics g){
            int w=getWidth(),h=getHeight();
            g.setClip(0,0,w,h); g.setColor(0x8B0000); g.fillRect(0,0,w,h);
            g.setColor(0xFFFFFF); g.fillRect(20,20,w-40,20); g.fillRect(20,h-40,w-40,20);
        }
    }

    static final class TestCanvas extends Canvas implements Runnable,PlayerListener {
        private static final int HOME=0,VIDEO=1,GRAPHICS=2,FONT=3,INPUT=4,RMS=5,MEDIA=6,SUMMARY=7,PAGES=8;
        private final RG35XXDeviceTest midlet;
        private Thread loop; private boolean running,initialized,paintFailed;
        private int page,tick,lastKey,lastAction,pressCount,releaseCount,repeatCount,rmsBoot=-1,mediaMode;
        private String rmsStatus="PENDING",mediaStatus="PENDING",mediaEvent="none",initStatus="BOOT";
        private Player player; private Image trnsImage,spriteImage; private int[] alphaPixels;
        private boolean playToneCalled,wavPass,midiPass,tonePass; private int activeMedia=-1;

        TestCanvas(RG35XXDeviceTest m){midlet=m;setFullScreenMode(true);}
        void start(){running=true;if(loop==null){loop=new Thread(this,"RG35XXDeviceTestV3");loop.start();}}
        void pauseLoop(){running=false;} void stopAll(){running=false;closePlayer();}
        public void run(){
            log("loop ENTER");
            while(loop==Thread.currentThread()){
                if(running){
                    tick++;
                    repaint(); serviceRepaints();
                    if(!initialized && tick>=6) initializeAfterFirstFrames();
                }
                try{Thread.sleep(50);}catch(InterruptedException e){}
            }
        }
        private void initializeAfterFirstFrames(){
            initialized=true; initStatus="INIT"; log("deferred init BEGIN");
            try{prepareGraphics();log("graphics resources init done");}catch(Throwable t){logThrowable("prepareGraphics",t);}
            try{runRms();log("RMS init done: "+rmsStatus);}catch(Throwable t){logThrowable("runRms init",t);rmsStatus="FAIL";}
            initStatus="READY"; log("deferred init END"); repaint();
        }
        private void prepareGraphics(){
            alphaPixels=new int[]{0x00FF0000,0x40FF0000,0x80FF0000,0xFFFF0000,0x0000FF00,0x4000FF00,0x8000FF00,0xFF00FF00,0x000000FF,0x400000FF,0x800000FF,0xFF0000FF,0x00FFFFFF,0x40FFFFFF,0x80FFFFFF,0xFFFFFFFF};
            try{trnsImage=Image.createImage("/trns.png");}catch(Throwable t){logThrowable("trns load",t);trnsImage=null;}
            try{spriteImage=Image.createImage("/sprite.png");}catch(Throwable t){logThrowable("sprite load",t);spriteImage=null;}
        }
        protected void paint(Graphics g){
            try{paintNormal(g);}
            catch(Throwable t){
                if(!paintFailed){paintFailed=true;logThrowable("paint",t);}
                int w=getWidth(),h=getHeight(); g.setClip(0,0,w,h);g.setColor(0x8B0000);g.fillRect(0,0,w,h);g.setColor(0xFFFFFF);g.fillRect(16,16,w-32,16);g.fillRect(16,h-32,w-32,16);
            }
        }
        private void paintNormal(Graphics g){
            int w=getWidth(),h=getHeight(); g.setClip(0,0,w,h);
            if(!initialized){
                g.setColor(0x003366);g.fillRect(0,0,w,h);g.setColor(0x00AA88);g.fillRect(0,h/3,w,h/3);g.setColor(0xFFFFFF);g.fillRect(20,h/2-8,Math.max(20,(w-40)*(tick%6)/5),16);return;
            }
            g.setColor(0x101820);g.fillRect(0,0,w,h);header(g,w);int y=36;
            if(page==HOME)home(g,y);else if(page==VIDEO)video(g,y,w,h);else if(page==GRAPHICS)graphics(g,y,w,h);else if(page==FONT)font(g,y);else if(page==INPUT)input(g,y);else if(page==RMS)rms(g,y);else if(page==MEDIA)media(g,y);else summary(g,y);footer(g,w,h);
        }
        private void header(Graphics g,int w){g.setColor(0x162A3A);g.fillRect(0,0,w,30);g.setColor(0xFFFFFF);g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM));g.drawString("RG35XX RC1 DEVICE TEST v3",8,5,Graphics.TOP|Graphics.LEFT);}
        private void footer(Graphics g,int w,int h){g.setColor(0x162A3A);g.fillRect(0,h-28,w,28);g.setColor(0xFFFFFF);g.setFont(Font.getDefaultFont());g.drawString("LEFT/RIGHT page  FIRE run  0 exit",8,h-23,Graphics.TOP|Graphics.LEFT);}
        private void title(Graphics g,String s,int y){g.setColor(0xFFD166);g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_LARGE));g.drawString(s,10,y,Graphics.TOP|Graphics.LEFT);}
        private void text(Graphics g,String s,int x,int y){g.setColor(0xE8EEF2);g.setFont(Font.getDefaultFont());g.drawString(s,x,y,Graphics.TOP|Graphics.LEFT);}
        private void state(Graphics g,String name,String value,int y){if("PASS".equals(value))g.setColor(0x2EC4B6);else if("FAIL".equals(value))g.setColor(0xFF5D73);else g.setColor(0xFFD166);g.drawString(name+": "+value,16,y,Graphics.TOP|Graphics.LEFT);}
        private void home(Graphics g,int y){title(g,"1/8 Overview",y);text(g,"Boot status: "+initStatus,10,y+36);text(g,"Log: /mnt/mmc/Java/test-evidence/",10,y+56);text(g,"rg35xx-device-test.log",10,y+76);text(g,"RMS boot counter: "+rmsBoot,10,y+110);text(g,"Use LEFT/RIGHT through all pages.",10,y+140);}
        private void video(Graphics g,int y,int w,int h){title(g,"2/8 Video / frame",y);text(g,"Expected: smooth motion, no stale/black frames.",10,y+34);int x=10+(tick*5)%Math.max(1,w-90);int by=y+65+(tick*3)%Math.max(1,h-y-150);g.setColor(0x2EC4B6);g.fillRect(x,by,70,30);g.setColor(0xFF9F1C);g.fillRect(Math.max(0,w-90-x/4),y+120,45,45);text(g,"tick="+tick+" screen="+w+"x"+h,10,h-62);}
        private void graphics(Graphics g,int y,int w,int h){title(g,"3/8 Graphics",y);text(g,"drawRGB alpha:",10,y+34);g.setColor(0x446688);g.fillRect(10,y+55,160,80);if(alphaPixels!=null)g.drawRGB(alphaPixels,0,4,18,y+63,4,4,true);g.setClip(190,y+55,120,65);g.setColor(0xD62828);g.fillRect(170,y+40,180,100);g.setClip(0,0,w,h);if(trnsImage!=null){text(g,"PNG tRNS loaded",10,y+155);g.drawImage(trnsImage,150,y+150,Graphics.TOP|Graphics.LEFT);}else text(g,"PNG tRNS FAILED",10,y+155);if(spriteImage!=null){text(g,"Sprite transforms loaded",10,y+210);g.drawRegion(spriteImage,0,0,spriteImage.getWidth(),spriteImage.getHeight(),Sprite.TRANS_NONE,170,y+205,Graphics.TOP|Graphics.LEFT);g.drawRegion(spriteImage,0,0,spriteImage.getWidth(),spriteImage.getHeight(),Sprite.TRANS_ROT90,230,y+205,Graphics.TOP|Graphics.LEFT);g.drawRegion(spriteImage,0,0,spriteImage.getWidth(),spriteImage.getHeight(),Sprite.TRANS_MIRROR,290,y+205,Graphics.TOP|Graphics.LEFT);}else text(g,"Sprite resource FAILED",10,y+210);}
        private void font(Graphics g,int y){title(g,"4/8 Font",y);Font a=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL),b=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM),c=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_ITALIC,Font.SIZE_LARGE);fontLine(g,a,"Java RG35XX AaBb 123",y+45);fontLine(g,b,"Java RG35XX AaBb 123",y+100);fontLine(g,c,"Java RG35XX AaBb 123",y+165);text(g,"Expected: clean glyphs, stable baselines/widths.",10,y+245);}
        private void fontLine(Graphics g,Font f,String s,int y){g.setFont(f);g.setColor(0xE8EEF2);g.drawString(s,12,y,Graphics.TOP|Graphics.LEFT);int sw=f.stringWidth(s),base=f.getBaselinePosition(),ht=f.getHeight();g.setColor(0x2EC4B6);g.drawLine(12,y+base,12+sw,y+base);g.setColor(0xFFD166);g.drawRect(12,y,sw,ht);}
        private void input(Graphics g,int y){title(g,"5/8 Input",y);text(g,"Press buttons; hold one key for repeats.",10,y+38);text(g,"last key="+lastKey+" action="+actionName(lastAction),10,y+76);text(g,"pressed="+pressCount+" released="+releaseCount+" repeats="+repeatCount,10,y+110);}
        private void rms(Graphics g,int y){title(g,"6/8 RMS",y);text(g,"Persistent boot counter="+rmsBoot,10,y+44);text(g,"status="+rmsStatus,10,y+72);text(g,"Exit/reopen JAR: counter must increase.",10,y+110);}
        private void media(Graphics g,int y){title(g,"7/8 Media",y);String[] n={"Manager.playTone","WAV 8 kHz","MIDI","ToneControl"};text(g,"UP/DOWN choose, FIRE play",10,y+38);for(int i=0;i<n.length;i++){g.setColor(i==mediaMode?0xFFD166:0xE8EEF2);g.drawString((i==mediaMode?"> ":"  ")+n[i],18,y+70+i*25,Graphics.TOP|Graphics.LEFT);}text(g,"status="+mediaStatus,10,y+190);text(g,"event="+mediaEvent,10,y+215);}
        private void summary(Graphics g,int y){title(g,"8/8 SUMMARY",y);g.setFont(Font.getDefaultFont());state(g,"VIDEO",tick>20?"PASS":"PENDING",y+42);state(g,"GRAPHICS",(trnsImage!=null&&spriteImage!=null)?"PASS":"FAIL",y+67);Font f=Font.getDefaultFont();state(g,"FONT",(f.getHeight()>0&&f.stringWidth("RG35XX")>0)?"PASS":"FAIL",y+92);state(g,"INPUT",(pressCount>0&&releaseCount>0&&repeatCount>0)?"PASS":"PENDING",y+117);state(g,"RMS",rmsStatus.indexOf("PASS")==0?"PASS":"FAIL",y+142);state(g,"PLAYTONE",playToneCalled?"PASS":"PENDING",y+167);state(g,"WAV",wavPass?"PASS":"PENDING",y+192);state(g,"MIDI",midiPass?"PASS":"PENDING",y+217);state(g,"TONE CONTROL",tonePass?"PASS":"PENDING",y+242);text(g,"Diagnostic only - review device log if FAIL.",10,y+280);}
        public void keyPressed(int k){lastKey=k;lastAction=safeAction(k);pressCount++;log("keyPressed "+k+" action="+lastAction);if(k==KEY_NUM0){midlet.exit();return;}if(lastAction==LEFT)page=(page+PAGES-1)%PAGES;else if(lastAction==RIGHT)page=(page+1)%PAGES;else if(page==MEDIA&&lastAction==UP)mediaMode=(mediaMode+3)%4;else if(page==MEDIA&&lastAction==DOWN)mediaMode=(mediaMode+1)%4;else if(lastAction==FIRE){if(page==RMS)runRms();else if(page==MEDIA)runMedia();}repaint();}
        public void keyRepeated(int k){lastKey=k;lastAction=safeAction(k);repeatCount++;repaint();}
        public void keyReleased(int k){lastKey=k;lastAction=safeAction(k);releaseCount++;repaint();}
        private int safeAction(int k){try{return getGameAction(k);}catch(Throwable t){logThrowable("getGameAction",t);return 0;}}
        private String actionName(int a){if(a==UP)return"UP";if(a==DOWN)return"DOWN";if(a==LEFT)return"LEFT";if(a==RIGHT)return"RIGHT";if(a==FIRE)return"FIRE";return String.valueOf(a);}
        private void runRms(){RecordStore rs=null;try{rs=RecordStore.openRecordStore("rg35xx_rc1_device_test",true);int v=0;if(rs.getNumRecords()==0){byte[] b=intBytes(1);rs.addRecord(b,0,b.length);v=1;}else{v=bytesInt(rs.getRecord(1))+1;byte[] b=intBytes(v);rs.setRecord(1,b,0,b.length);}rmsBoot=bytesInt(rs.getRecord(1));rmsStatus=rmsBoot==v?"PASS read/write":"FAIL verify mismatch";}catch(Throwable t){rmsStatus="FAIL "+t.getClass().getName();logThrowable("RMS",t);}finally{if(rs!=null)try{rs.closeRecordStore();}catch(Throwable t){logThrowable("RMS close",t);}}repaint();}
        private byte[] intBytes(int v){return new byte[]{(byte)(v>>>24),(byte)(v>>>16),(byte)(v>>>8),(byte)v};}
        private int bytesInt(byte[] b){if(b==null||b.length<4)return 0;return((b[0]&255)<<24)|((b[1]&255)<<16)|((b[2]&255)<<8)|(b[3]&255);}
        private void runMedia(){closePlayer();mediaEvent="none";activeMedia=mediaMode;try{if(mediaMode==0){Manager.playTone(69,600,90);playToneCalled=true;mediaStatus="PASS playTone called";mediaEvent="listen for A4 tone";}else if(mediaMode==1){startResource("/test.wav","audio/x-wav","WAV started");}else if(mediaMode==2){startResource("/test.mid","audio/midi","MIDI started");}else{player=Manager.createPlayer(Manager.TONE_DEVICE_LOCATOR);player.addPlayerListener(this);player.realize();ToneControl tc=(ToneControl)player.getControl("ToneControl");if(tc==null)throw new Exception("ToneControl unavailable");byte[] seq=new byte[]{ToneControl.VERSION,1,ToneControl.TEMPO,30,ToneControl.RESOLUTION,64,ToneControl.SET_VOLUME,90,ToneControl.C4,8,(byte)(ToneControl.C4+4),8,(byte)(ToneControl.C4+7),8,(byte)(ToneControl.C4+12),16};tc.setSequence(seq);player.prefetch();player.start();mediaStatus="ToneControl started";}}catch(Throwable t){mediaStatus="FAIL "+t.getClass().getName();mediaEvent=t.getMessage()==null?"":t.getMessage();logThrowable("media",t);closePlayer();}repaint();}
        private void startResource(String path,String type,String status)throws Exception{InputStream in=getClass().getResourceAsStream(path);if(in==null)throw new Exception(path+" missing");player=Manager.createPlayer(in,type);player.addPlayerListener(this);player.realize();player.prefetch();player.start();mediaStatus=status;}
        public void playerUpdate(Player p,String event,Object data){mediaEvent=event;log("media event "+event);if(PlayerListener.END_OF_MEDIA.equals(event)){mediaStatus="PASS END_OF_MEDIA";if(activeMedia==1)wavPass=true;else if(activeMedia==2)midiPass=true;else if(activeMedia==3)tonePass=true;}else if(PlayerListener.ERROR.equals(event))mediaStatus="FAIL media error";repaint();}
        private void closePlayer(){Player p=player;player=null;if(p!=null){try{p.stop();}catch(Throwable t){logThrowable("player stop",t);}try{p.close();}catch(Throwable t){logThrowable("player close",t);}}}
    }
}
