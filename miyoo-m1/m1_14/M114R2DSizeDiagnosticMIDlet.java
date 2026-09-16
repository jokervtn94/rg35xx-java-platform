package org.recompile.mobile;
import javax.microedition.midlet.MIDlet;
import javax.microedition.lcdui.*;
public final class M114R2DSizeDiagnosticMIDlet extends MIDlet {
  protected void startApp(){
    final Font s=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_SMALL);
    final Font m=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_MEDIUM);
    final Font l=Font.getFont(Font.FACE_SYSTEM,Font.STYLE_PLAIN,Font.SIZE_LARGE);
    dump("SMALL",s); dump("MEDIUM",m); dump("LARGE",l);
    Canvas c=new Canvas(){protected void paint(Graphics g){
      g.setColor(0x0000FF);g.fillRect(0,0,getWidth(),getHeight());g.setColor(0xFFFFFF);
      g.setFont(s);g.drawString("SMALL: Ti\u1EBFng Vi\u1EC7t 123",20,30,Graphics.TOP|Graphics.LEFT);
      g.setFont(m);g.drawString("MEDIUM: Ti\u1EBFng Vi\u1EC7t 123",20,100,Graphics.TOP|Graphics.LEFT);
      g.setFont(l);g.drawString("LARGE: Ti\u1EBFng Vi\u1EC7t 123",20,180,Graphics.TOP|Graphics.LEFT);
    }}; c.setFullScreenMode(true); Display.getDisplay(this).setCurrent(c);
    System.out.println("M1_14_R2D_CANVAS_READY=YES");
  }
  private static void dump(String t,Font f){
    System.out.println("M1_14_R2D_"+t+"_SIZE_ENUM="+f.getSize());
    System.out.println("M1_14_R2D_"+t+"_HEIGHT="+f.getHeight());
    System.out.println("M1_14_R2D_"+t+"_BASELINE="+f.getBaselinePosition());
    System.out.println("M1_14_R2D_"+t+"_ASCII_WIDTH="+f.stringWidth("ABC 123"));
  }
  protected void pauseApp(){} protected void destroyApp(boolean u){}
}
