import java.io.InputStream;
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
    private TestCanvas canvas;
    protected void startApp() {
        if (canvas == null) canvas = new TestCanvas(this);
        Display.getDisplay(this).setCurrent(canvas);
        canvas.start();
    }
    protected void pauseApp() { if (canvas != null) canvas.pauseLoop(); }
    protected void destroyApp(boolean unconditional) { if (canvas != null) canvas.stopAll(); }
    void exit() { try { destroyApp(true); } catch (Throwable t) {} notifyDestroyed(); }

    static final class TestCanvas extends Canvas implements Runnable, PlayerListener {
        private static final int PAGE_HOME=0, PAGE_VIDEO=1, PAGE_GRAPHICS=2, PAGE_FONT=3, PAGE_INPUT=4, PAGE_RMS=5, PAGE_MEDIA=6, PAGE_COUNT=7;
        private final RG35XXDeviceTest midlet;
        private Thread loop;
        private boolean running;
        private int page,tick,lastKey,lastAction,pressCount,releaseCount,repeatCount,rmsBootCount=-1,mediaMode;
        private String rmsStatus="not run",mediaStatus="FIRE: play tone",mediaEvent="none";
        private Player player;
        private Image trnsImage,spriteImage;
        private int[] alphaPixels;

        TestCanvas(RG35XXDeviceTest m) { midlet=m; setFullScreenMode(true); prepareGraphicsFixtures(); runRmsTest(); }
        void start() { running=true; if(loop==null){ loop=new Thread(this,"RG35XXDeviceTest"); loop.start(); } }
        void pauseLoop(){ running=false; }
        void stopAll(){ running=false; closePlayer(); }
        public void run(){ while(loop==Thread.currentThread()){ if(running){ tick++; repaint(); serviceRepaints(); } try{Thread.sleep(50);}catch(InterruptedException e){} } }

        private void prepareGraphicsFixtures(){
            alphaPixels=new int[]{0x00FF0000,0x40FF0000,0x80FF0000,0xFFFF0000,0x0000FF00,0x4000FF00,0x8000FF00,0xFF00FF00,0x000000FF,0x400000FF,0x800000FF,0xFF0000FF,0x00FFFFFF,0x40FFFFFF,0x80FFFFFF,0xFFFFFFFF};
            try{trnsImage=Image.createImage("/trns.png");}catch(Throwable t){trnsImage=null;}
            try{spriteImage=Image.createImage("/sprite.png");}catch(Throwable t){spriteImage=null;}
        }

        protected void paint(Graphics g){
            int w=getWidth(),h=getHeight(); g.setColor(0x101820); g.fillRect(0,0,w,h); drawHeader(g,w); int top=36;
            if(page==PAGE_HOME)drawHome(g,top,w,h); else if(page==PAGE_VIDEO)drawVideo(g,top,w,h); else if(page==PAGE_GRAPHICS)drawGraphics(g,top,w,h); else if(page==PAGE_FONT)drawFont(g,top,w,h); else if(page==PAGE_INPUT)drawInput(g,top,w,h); else if(page==PAGE_RMS)drawRms(g,top,w,h); else if(page==PAGE_MEDIA)drawMedia(g,top,w,h); drawFooter(g,w,h);
        }
        private void drawHeader(Graphics g,int w){ g.setColor(0x162A3A); g.fillRect(0,0,w,30); g.setColor(0xFFFFFF); g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM)); g.drawString("RG35XX RC1 DEVICE TEST",8,5,Graphics.TOP|Graphics.LEFT); }
        private void drawFooter(Graphics g,int w,int h){ g.setColor(0x162A3A); g.fillRect(0,h-28,w,28); g.setColor(0xFFFFFF); g.setFont(Font.getDefaultFont()); g.drawString("LEFT/RIGHT page   FIRE run   0 exit",8,h-23,Graphics.TOP|Graphics.LEFT); }
        private void title(Graphics g,String s,int y){ g.setColor(0xFFD166); g.setFont(Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_LARGE)); g.drawString(s,10,y,Graphics.TOP|Graphics.LEFT); }
        private void text(Graphics g,String s,int x,int y){ g.setColor(0xE8EEF2); g.setFont(Font.getDefaultFont()); g.drawString(s,x,y,Graphics.TOP|Graphics.LEFT); }

        private void drawHome(Graphics g,int y,int w,int h){ title(g,"1/7 Overview",y); text(g,"Open this JAR from the normal Java game menu.",10,y+34); text(g,"No terminal is required for test execution.",10,y+54); text(g,"RMS boot counter: "+rmsBootCount,10,y+86); text(g,"RMS status: "+rmsStatus,10,y+106); text(g,"Pages: video / graphics / font / input / RMS / media",10,y+138); text(g,"Visual/audio pages require your eyes/ears for final PASS.",10,y+158); }
        private void drawVideo(Graphics g,int y,int w,int h){ title(g,"2/7 Video / frame",y); int usableH=h-y-90; int x=10+(tick*5)%Math.max(1,w-90); int by=y+60+(tick*3)%Math.max(1,usableH-40); g.setColor(0x2EC4B6); g.fillRect(x,by,70,30); g.setColor(0xFF9F1C); g.fillRect(w-80-x/4,y+100,45,45); text(g,"Expected: smooth motion, no black/stale frames.",10,y+34); text(g,"tick="+tick+" screen="+w+"x"+h,10,h-62); }
        private void drawGraphics(Graphics g,int y,int w,int h){
            title(g,"3/7 Graphics",y); text(g,"drawRGB alpha (transparent -> solid):",10,y+34); g.setColor(0x446688); g.fillRect(10,y+55,160,80); g.drawRGB(alphaPixels,0,4,18,y+63,4,4,true);
            g.setClip(190,y+55,120,65); g.setColor(0xD62828); g.fillRect(170,y+40,180,100); g.setColor(0xFFFFFF); g.drawRect(190,y+55,119,64); g.setClip(0,0,w,h); text(g,"clip box",200,y+120);
            if(trnsImage!=null){ text(g,"PNG tRNS:",10,y+155); g.setColor(0x355070); g.fillRect(90,y+148,80,45); g.drawImage(trnsImage,100,y+154,Graphics.TOP|Graphics.LEFT); } else text(g,"PNG tRNS resource FAILED to load",10,y+155);
            if(spriteImage!=null){ text(g,"drawRegion transforms:",10,y+210); int sx=150,sy=y+205; g.drawRegion(spriteImage,0,0,spriteImage.getWidth(),spriteImage.getHeight(),Sprite.TRANS_NONE,sx,sy,Graphics.TOP|Graphics.LEFT); g.drawRegion(spriteImage,0,0,spriteImage.getWidth(),spriteImage.getHeight(),Sprite.TRANS_ROT90,sx+55,sy,Graphics.TOP|Graphics.LEFT); g.drawRegion(spriteImage,0,0,spriteImage.getWidth(),spriteImage.getHeight(),Sprite.TRANS_MIRROR,sx+110,sy,Graphics.TOP|Graphics.LEFT); } else text(g,"Sprite resource FAILED to load",10,y+210);
        }
        private void drawFont(Graphics g,int y,int w,int h){ title(g,"4/7 Font",y); Font small=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL),medium=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM),large=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_ITALIC,Font.SIZE_LARGE); String sample="Java RG35XX AaBb 123"; drawFontLine(g,small,sample,y+45); drawFontLine(g,medium,sample,y+95); drawFontLine(g,large,sample,y+155); g.setFont(Font.getDefaultFont()); text(g,"Expected: widths match text; baseline stable; no glyph crash.",10,y+230); }
        private void drawFontLine(Graphics g,Font f,String s,int y){ g.setFont(f); g.setColor(0xE8EEF2); g.drawString(s,12,y,Graphics.TOP|Graphics.LEFT); int sw=f.stringWidth(s),base=f.getBaselinePosition(),ht=f.getHeight(); g.setColor(0x2EC4B6); g.drawLine(12,y+base,12+sw,y+base); g.setColor(0xFFD166); g.drawRect(12,y,sw,ht); }
        private void drawInput(Graphics g,int y,int w,int h){ title(g,"5/7 Input",y); text(g,"Press D-pad/buttons. Hold one key to test repeats.",10,y+38); text(g,"last keyCode="+lastKey,10,y+75); text(g,"last gameAction="+actionName(lastAction),10,y+95); text(g,"pressed="+pressCount+" released="+releaseCount+" repeats="+repeatCount,10,y+125); text(g,"Expected: one press/release; repeats grow only while held.",10,y+155); }
        private void drawRms(Graphics g,int y,int w,int h){ title(g,"6/7 RMS",y); text(g,"This JAR increments one persistent counter at startup.",10,y+40); text(g,"boot counter="+rmsBootCount,10,y+75); text(g,"status="+rmsStatus,10,y+95); text(g,"Exit to menu, reopen this JAR: counter must +1.",10,y+130); text(g,"FIRE reruns same-session read/write verification.",10,y+150); }
        private void drawMedia(Graphics g,int y,int w,int h){ title(g,"7/7 Media",y); String[] names={"Manager.playTone","WAV 8 kHz","MIDI","ToneControl"}; text(g,"UP/DOWN choose, FIRE play",10,y+38); for(int i=0;i<names.length;i++){ g.setColor(i==mediaMode?0xFFD166:0xE8EEF2); g.drawString((i==mediaMode?"> ":"  ")+names[i],18,y+70+i*25,Graphics.TOP|Graphics.LEFT); } text(g,"status="+mediaStatus,10,y+190); text(g,"event="+mediaEvent,10,y+212); text(g,"Expected: sound, correct duration/pitch, END_OF_MEDIA.",10,y+245); }

        public void keyPressed(int keyCode){ lastKey=keyCode; lastAction=safeAction(keyCode); pressCount++; if(keyCode==KEY_NUM0){midlet.exit();return;} if(lastAction==LEFT)page=(page+PAGE_COUNT-1)%PAGE_COUNT; else if(lastAction==RIGHT)page=(page+1)%PAGE_COUNT; else if(page==PAGE_MEDIA&&lastAction==UP)mediaMode=(mediaMode+3)%4; else if(page==PAGE_MEDIA&&lastAction==DOWN)mediaMode=(mediaMode+1)%4; else if(lastAction==FIRE){ if(page==PAGE_RMS)runRmsTest(); else if(page==PAGE_MEDIA)runMediaTest(); } repaint(); }
        public void keyRepeated(int keyCode){ lastKey=keyCode; lastAction=safeAction(keyCode); repeatCount++; repaint(); }
        public void keyReleased(int keyCode){ lastKey=keyCode; lastAction=safeAction(keyCode); releaseCount++; repaint(); }
        private int safeAction(int keyCode){ try{return getGameAction(keyCode);}catch(Throwable t){return 0;} }
        private String actionName(int a){ if(a==UP)return"UP"; if(a==DOWN)return"DOWN"; if(a==LEFT)return"LEFT"; if(a==RIGHT)return"RIGHT"; if(a==FIRE)return"FIRE"; return String.valueOf(a); }

        private void runRmsTest(){ RecordStore rs=null; try{ rs=RecordStore.openRecordStore("rg35xx_rc1_device_test",true); int value=0; if(rs.getNumRecords()==0){byte[] first=intBytes(1);rs.addRecord(first,0,first.length);value=1;}else{byte[] old=rs.getRecord(1);value=bytesInt(old)+1;byte[] next=intBytes(value);rs.setRecord(1,next,0,next.length);} byte[] verify=rs.getRecord(1);rmsBootCount=bytesInt(verify);rmsStatus=rmsBootCount==value?"PASS read/write":"FAIL verify mismatch";}catch(Throwable t){rmsStatus="FAIL "+t.getClass().getName();}finally{if(rs!=null)try{rs.closeRecordStore();}catch(Throwable t){}} repaint(); }
        private byte[] intBytes(int v){return new byte[]{(byte)(v>>>24),(byte)(v>>>16),(byte)(v>>>8),(byte)v};}
        private int bytesInt(byte[] b){if(b==null||b.length<4)return 0;return((b[0]&255)<<24)|((b[1]&255)<<16)|((b[2]&255)<<8)|(b[3]&255);}

        private void runMediaTest(){ closePlayer();mediaEvent="none";try{
            if(mediaMode==0){Manager.playTone(69,600,90);mediaStatus="playTone called";mediaEvent="listen for A4 tone";}
            else if(mediaMode==1){InputStream in=getClass().getResourceAsStream("/test.wav");if(in==null)throw new Exception("test.wav missing");player=Manager.createPlayer(in,"audio/x-wav");player.addPlayerListener(this);player.realize();player.prefetch();player.start();mediaStatus="WAV started";}
            else if(mediaMode==2){InputStream in=getClass().getResourceAsStream("/test.mid");if(in==null)throw new Exception("test.mid missing");player=Manager.createPlayer(in,"audio/midi");player.addPlayerListener(this);player.realize();player.prefetch();player.start();mediaStatus="MIDI started";}
            else{player=Manager.createPlayer(Manager.TONE_DEVICE_LOCATOR);player.addPlayerListener(this);player.realize();ToneControl tc=(ToneControl)player.getControl("ToneControl");if(tc==null)throw new Exception("ToneControl unavailable");byte[] seq=new byte[]{ToneControl.VERSION,1,ToneControl.TEMPO,30,ToneControl.RESOLUTION,64,ToneControl.SET_VOLUME,90,ToneControl.C4,8,(byte)(ToneControl.C4+4),8,(byte)(ToneControl.C4+7),8,(byte)(ToneControl.C4+12),16};tc.setSequence(seq);player.prefetch();player.start();mediaStatus="ToneControl started";}
        }catch(Throwable t){mediaStatus="FAIL "+t.getClass().getName();mediaEvent=t.getMessage()==null?"":t.getMessage();closePlayer();} repaint(); }
        public void playerUpdate(Player p,String event,Object data){mediaEvent=event;if(PlayerListener.END_OF_MEDIA.equals(event))mediaStatus="PASS END_OF_MEDIA";else if(PlayerListener.ERROR.equals(event))mediaStatus="FAIL media error";repaint();}
        private void closePlayer(){Player p=player;player=null;if(p!=null){try{p.stop();}catch(Throwable t){}try{p.close();}catch(Throwable t){}}}
    }
}
