package org.recompile.mobile;
import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;
public final class M114R4ABoldOnlyMIDlet extends MIDlet implements Runnable {
 private Canvas canvas;
 protected void startApp(){
  final Font plain=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
  final Font bold=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_BOLD,Font.SIZE_MEDIUM);
  System.out.println("M1_14_R4A_PLAIN_STYLE="+plain.getStyle()); System.out.println("M1_14_R4A_BOLD_STYLE="+bold.getStyle());
  System.out.println("M1_14_R4A_PLAIN_HEIGHT="+plain.getHeight()); System.out.println("M1_14_R4A_BOLD_HEIGHT="+bold.getHeight());
  System.out.println("M1_14_R4A_PLAIN_ASCII_WIDTH="+plain.stringWidth("ABC 123")); System.out.println("M1_14_R4A_BOLD_ASCII_WIDTH="+bold.stringWidth("ABC 123"));
  canvas=new Canvas(){protected void paint(Graphics g){g.setColor(0x0000FF);g.fillRect(0,0,getWidth(),getHeight());g.setColor(0xFFFFFF);g.setFont(plain);g.drawString("PLAIN: ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,80,Graphics.TOP|Graphics.LEFT);g.setFont(bold);g.drawString("BOLD : ABC 123 - Ti\u1EBFng Vi\u1EC7t - \u4E2D\u6587",20,150,Graphics.TOP|Graphics.LEFT);g.setFont(plain);g.drawString("R4A BOLD ONLY - compare stroke thickness",20,260,Graphics.TOP|Graphics.LEFT);}};
  canvas.setFullScreenMode(true);Display.getDisplay(this).setCurrent(canvas);System.out.println("M1_14_R4A_CANVAS_VISIBLE_READY=YES");new Thread(this,"m114-r4a-presenter").start();
 }
 public void run(){int rc=M19SdlPresenter.initDisplay();System.out.println("M1_14_R4A_NATIVE_INIT_RC="+rc);if(rc!=0)System.exit(1);long end=System.currentTimeMillis()+12000L;int n=0;while(System.currentTimeMillis()<end){canvas.repaint();canvas.serviceRepaints();PlatformImage im=MobilePlatform.getLcdBackbuffer();if(im!=null){int[] f=im.getMIDPGraphics().getFrameBuffer();if(M19SdlPresenter.presentARGB(f,640,480)!=0)break;n++;}try{Thread.sleep(50);}catch(Exception e){break;}}M19SdlPresenter.shutdownDisplay();System.out.println("M1_14_R4A_PRESENT_COUNT="+n);System.out.println("M1_14_R4A_NORMAL_EXIT=PASS");System.exit(n>0?0:2);}
 protected void pauseApp(){} protected void destroyApp(boolean unconditional){}
}
