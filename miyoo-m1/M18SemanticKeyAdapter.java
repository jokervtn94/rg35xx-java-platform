package org.recompile.mobile;

/** M1.8: explicit adapter from locked M1.7 RG35XX semantic controls to MIDP keycodes. */
public final class M18SemanticKeyAdapter {
    public static final int UP=0, DOWN=1, LEFT=2, RIGHT=3, A=4, B=5, X=6, Y=7, START=8, SELECT=9, L=10, R=11;
    private M18SemanticKeyAdapter() { }

    public static int toMidpKey(int control) {
        switch(control) {
            case UP: return Mobile.KEY_NUM2;
            case DOWN: return Mobile.KEY_NUM8;
            case LEFT: return Mobile.KEY_NUM4;
            case RIGHT: return Mobile.KEY_NUM6;
            case A: return Mobile.KEY_NUM5;
            case B: return Mobile.KEY_NUM0;
            case X: return Mobile.KEY_NUM7;
            case Y: return Mobile.KEY_NUM9;
            case START: return Mobile.NOKIA_SOFT1;
            case SELECT: return Mobile.NOKIA_SOFT2;
            case L: return Mobile.KEY_STAR;
            case R: return Mobile.KEY_POUND;
            default: throw new IllegalArgumentException("unknown RG35XX control: " + control);
        }
    }

    public static void press(MobilePlatform platform, int control) {
        platform.keyPressed(toMidpKey(control));
    }
    public static void release(MobilePlatform platform, int control) {
        platform.keyReleased(toMidpKey(control));
    }
    public static void repeat(MobilePlatform platform, int control) {
        platform.keyRepeated(toMidpKey(control));
    }
}
