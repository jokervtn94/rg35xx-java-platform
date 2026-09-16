package org.recompile.mobile;
import java.io.FileOutputStream;
import java.io.PrintStream;
import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;
public final class M114R4ABoldOnlyMIDlet extends MIDlet implements Runnable {
 private Canvas canvas; private boolean captured;
 protected void startApp(){
  final Font plain=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
  final Font bold=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM);
  System.out.println("M1_14_R4A_PLAIN_STYLE="+plain.getStyle()); System.out.println("M1_14_R4A_BOLD_STYLE="+bold.getStyle());
  System.out.println("M1_14_R4A_PLAIN_HEIGHT="+plain.getHeight()); System.out.println("M1_14_R4A_BOLD_HEIGHT="+bold.getHeight());
  System.out.println("M1_14_R4A_PLAIN_ASCII_WIDTH="+plain.stringWidth("ABC 123")); System.out.println("M1_14_R4A_BOLD_ASCII_WIDTH="+bold.stringWidth("ABC 123"));
  canvas=new Canvas(){protected void paint(Graphics g){g.setColor(0x0000FF);g.fillRect(0,0,getWidth(),getHeight());g.setColor(0xFFFFFF);g.setFont(plain);g.drawString("PLAIN: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,80,Graphics.TOP|Graphics.LEFT);g.setFont(bold);g.drawString("BOLD : ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,150,Graphics.TOP|Graphics.LEFT);g.setFont(plain);g.drawString("R4A.1 BOLD ONLY - compare stroke thickness",20,260,Graphics.TOP|Graphics.LEFT);}};
  canvas.setFullScreenMode(true);Display.getDisplay(this).setCurrent(canvas);System.out.println("M1_14_R4A_CANVAS_VISIBLE_READY=YES");new Thread(this,"m114-r4a-presenter").start();
 }
 private static void le16(FileOutputStream o,int v)throws Exception{o.write(v&255);o.write((v>>>8)&255);}
 private static void le32(FileOutputStream o,int v)throws Exception{o.write(v&255);o.write((v>>>8)&255);o.write((v>>>16)&255);o.write((v>>>24)&255);}
 private void bmp(int[] p,int w,int h,String path)throws Exception{int row=((w*3+3)/4)*4,img=row*h;FileOutputStream o=new FileOutputStream(path);o.write('B');o.write('M');le32(o,54+img);le16(o,0);le16(o,0);le32(o,54);le32(o,40);le32(o,w);le32(o,h);le16(o,1);le16(o,24);le32(o,0);le32(o,img);le32(o,2835);le32(o,2835);le32(o,0);le32(o,0);for(int y=h-1;y>=0;y--){for(int x=0;x<w;x++){int v=p[y*w+x];o.write(v&255);o.write((v>>>8)&255);o.write((v>>>16)&255);}for(int q=w*3;q<row;q++)o.write(0);}o.close();}
 private void capture(int[] p,int w,int h,int frame){if(captured||p==null||p.length<w*h)return;captured=true;try{String raw="/mnt/mmc/RG35XX-MIYOO-M1.14-R4A-LIVE-FRAME.argb",shot="/mnt/mmc/RG35XX-MIYOO-M1.14-R4A-SCREENSHOT.bmp",meta="/mnt/mmc/RG35XX-MIYOO-M1.14-R4A-LIVE-FRAME.txt";FileOutputStream o=new FileOutputStream(raw);for(int i=0;i<w*h;i++){int v=p[i];o.write((v>>>24)&255);o.write((v>>>16)&255);o.write((v>>>8)&255);o.write(v&255);}o.close();bmp(p,w,h,shot);PrintStream m=new PrintStream(new FileOutputStream(meta));m.println("M1_14_R4A_LIVE_CAPTURE=PASS");m.println("M1_14_R4A_CAPTURE_METHOD=JAVA_ARGB_BEFORE_PRESENTER");m.println("M1_14_R4A_SCREENSHOT=PASS");m.println("M1_14_R4A_SCREENSHOT_PATH="+shot);m.println("M1_14_R4A_FRAME="+frame);m.println("M1_14_R4A_WIDTH="+w);m.println("M1_14_R4A_HEIGHT="+h);m.close();System.out.println("M1_14_R4A_LIVE_CAPTURE=PASS FRAME="+frame);System.out.println("M1_14_R4A_SCREENSHOT=PASS PATH="+shot);}catch(Throwable t){System.out.println("M1_14_R4A_CAPTURE=FAIL "+t);}}
 public void run(){int rc=M19SdlPresenter.initDisplay();System.out.println("M1_14_R4A_NATIVE_INIT_RC="+rc);if(rc!=0)System.exit(1);long end=System.currentTimeMillis()+12000L;int n=0;while(System.currentTimeMillis()<end){canvas.repaint();canvas.serviceRepaints();PlatformImage im=MobilePlatform.getLcdBackbuffer();if(im!=null){int[] f=im.getMIDPGraphics().getFrameBuffer();if(!captured&&n>=20)capture(f,640,480,n);if(M19SdlPresenter.presentARGB(f,640,480)!=0)break;n++;}try{Thread.sleep(50);}catch(Exception e){break;}}M19SdlPresenter.shutdownDisplay();System.out.println("M1_14_R4A_PRESENT_COUNT="+n);System.out.println("M1_14_R4A_NORMAL_EXIT=PASS");System.exit(n>0&&captured?0:2);}
 protected void pauseApp(){} protected void destroyApp(boolean unconditional){}
}
