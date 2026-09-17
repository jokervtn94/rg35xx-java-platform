package org.recompile.mobile;

import javax.microedition.lcdui.*;
import javax.microedition.lcdui.game.*;
import javax.microedition.midlet.MIDlet;

public final class M116R1GameLayerDiagnosticMIDlet extends MIDlet implements Runnable {
    private Thread worker;
    private volatile boolean running;

    protected void startApp() {
        System.out.println("M1_16_R1_PRIMARY_VARIABLE=GAME_LAYER_SEMANTICS_ONLY");
        System.out.println("M1_16_R1_GAME_LAYER_IMPLEMENTATION_CHANGE=NONE");
        System.out.println("M1_16_R1_RENDERER_CHANGE=NONE");
        running = true;
        worker = new Thread(this, "m116-r1");
        worker.start();
    }

    protected void pauseApp() {}
    protected void destroyApp(boolean unconditional) { running = false; }

    private static void require(boolean v, String name) throws Exception {
        if (!v) throw new Exception(name);
        System.out.println(name + "=PASS");
    }

    private static Image makeSheet() throws Exception {
        Image img = Image.createImage(16, 8);
        Graphics g = img.getGraphics();
        g.setColor(0x000000); g.fillRect(0, 0, 16, 8);
        g.setColor(0xFF0000); g.fillRect(0, 0, 8, 8);
        g.setColor(0x00FF00); g.fillRect(8, 0, 8, 8);
        g.setColor(0xFFFFFF); g.fillRect(0, 0, 2, 2);
        return img;
    }

    private static int pixel(Image img, int x, int y) {
        int[] p = new int[1];
        img.getRGB(p, 0, 1, x, y, 1, 1);
        return p[0] & 0x00FFFFFF;
    }

    private static void testSprite() throws Exception {
        Image sheet = makeSheet();
        Sprite s = new Sprite(sheet, 8, 8);
        require(s.getFrameSequenceLength() == 2, "M1_16_R1_SPRITE_FRAME_COUNT");
        s.setFrame(1);
        require(s.getFrame() == 1, "M1_16_R1_SPRITE_SET_FRAME");
        s.setPosition(10, 20);
        require(s.getX() == 10 && s.getY() == 20 && s.getWidth() == 8 && s.getHeight() == 8, "M1_16_R1_SPRITE_BOUNDS");
        s.defineCollisionRectangle(1, 1, 6, 6);
        Sprite other = new Sprite(Image.createImage(8, 8));
        other.setPosition(12, 22);
        require(s.collidesWith(other, false), "M1_16_R1_SPRITE_COLLISION");
        other.setPosition(40, 40);
        require(!s.collidesWith(other, false), "M1_16_R1_SPRITE_NONCOLLISION");

        Image target = Image.createImage(16, 16);
        Graphics tg = target.getGraphics();
        tg.setColor(0); tg.fillRect(0, 0, 16, 16);
        s.setFrame(0); s.setPosition(0, 0); s.setTransform(Sprite.TRANS_NONE); s.paint(tg);
        require(pixel(target, 0, 0) == 0xFFFFFF && pixel(target, 7, 7) == 0xFF0000, "M1_16_R1_SPRITE_TRANS_NONE");
        s.setTransform(Sprite.TRANS_MIRROR);
        tg.setColor(0); tg.fillRect(0, 0, 16, 16); s.paint(tg);
        require(pixel(target, 7, 0) == 0xFFFFFF && pixel(target, 0, 7) == 0xFF0000, "M1_16_R1_SPRITE_TRANS_MIRROR");
        s.setTransform(Sprite.TRANS_ROT90);
        tg.setColor(0); tg.fillRect(0, 0, 16, 16); s.paint(tg);
        require(pixel(target, 7, 0) == 0xFFFFFF && pixel(target, 0, 0) == 0xFF0000, "M1_16_R1_SPRITE_TRANS_ROT90");
        System.out.println("M1_16_R1_SPRITE_GATE=PASS");
    }

    private static void testTiledLayer() throws Exception {
        Image tiles = makeSheet();
        TiledLayer t = new TiledLayer(3, 2, tiles, 8, 8);
        t.setCell(0, 0, 1); t.setCell(1, 0, 2); t.setCell(2, 0, 1);
        t.setCell(0, 1, 2); t.setCell(1, 1, 1); t.setCell(2, 1, 2);
        require(t.getCell(0,0)==1 && t.getCell(1,0)==2 && t.getCell(2,1)==2, "M1_16_R1_TILE_MAPPING");
        int anim = t.createAnimatedTile(1);
        t.setCell(1, 1, anim);
        require(t.getAnimatedTile(anim)==1, "M1_16_R1_TILE_ANIM_CREATE");
        t.setAnimatedTile(anim, 2);
        require(t.getAnimatedTile(anim)==2, "M1_16_R1_TILE_ANIM_UPDATE");
        t.setPosition(4, 5);
        require(t.getX()==4 && t.getY()==5 && t.getWidth()==24 && t.getHeight()==16, "M1_16_R1_TILE_BOUNDS");

        Image target = Image.createImage(32, 24);
        Graphics g = target.getGraphics();
        g.setColor(0); g.fillRect(0,0,32,24);
        g.setClip(4,5,16,8);
        t.paint(g);
        require(pixel(target,4,5)==0xFFFFFF && pixel(target,12,5)==0x00FF00, "M1_16_R1_TILE_PAINT_CLIP");
        require(pixel(target,21,5)==0x000000, "M1_16_R1_TILE_CLIP_OUTSIDE");
        System.out.println("M1_16_R1_TILEDLAYER_GATE=PASS");
    }

    public void run() {
        try {
            testSprite();
            testTiledLayer();
            System.out.println("M1_16_R1_GAME_LAYER_GATE=PASS");
            System.out.println("M1_16_R1_RUNTIME_GATE=PASS");
            notifyDestroyed();
            System.exit(0);
        } catch (Throwable t) {
            System.out.println("M1_16_R1_GAME_LAYER_GATE=FAIL");
            System.out.println("M1_16_R1_RUNTIME_GATE=FAIL");
            System.out.println("M1_16_R1_EXCEPTION=" + t.getClass().getName() + ":" + t.getMessage());
            t.printStackTrace();
            notifyDestroyed();
            System.exit(2);
        }
    }
}
