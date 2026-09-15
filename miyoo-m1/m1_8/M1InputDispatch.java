package org.recompile.mobile;

/** Single-owner RG35XX semantic input -> canonical FreeJ2ME MIDP adapter. */
public final class M1InputDispatch {
    public static final int UP=1, DOWN=2, LEFT=3, RIGHT=4;
    public static final int A=5, B=6, X=7, Y=8, L1=9, R1=10, START=11, SELECT=12;
    private static final int REPEAT_DELAY_MS=400, REPEAT_PERIOD_MS=100;
    private int previous;
    private final long[] nextRepeat=new long[13];
    public void poll(long nowMs) { dispatchState(M1Input.rawGetState(), nowMs); }
    void dispatchState(int state,long nowMs) {
        for(int id=UP;id<=SELECT;id++) {
            int bit=1<<(id-1); boolean was=(previous&bit)!=0, down=(state&bit)!=0;
            int slot=toLibretroSlot(id); if(slot<0) continue;
            int key=Mobile.getMobileKey(slot);
            if(!was&&down) { MobilePlatform.keyPressed(key); nextRepeat[id]=repeatable(id)?nowMs+REPEAT_DELAY_MS:0; }
            else if(was&&!down) { MobilePlatform.keyReleased(key); nextRepeat[id]=0; }
            else if(down&&repeatable(id)&&nextRepeat[id]!=0&&nowMs>=nextRepeat[id]) {
                MobilePlatform.keyRepeated(key); nextRepeat[id]=nowMs+REPEAT_PERIOD_MS;
            }
        }
        previous=state;
    }
    private static boolean repeatable(int id) { return id==UP||id==DOWN||id==LEFT||id==RIGHT||id==A; }
    private static int toLibretroSlot(int id) {
        switch(id) {
            case UP:return 0; case DOWN:return 1; case LEFT:return 2; case RIGHT:return 3;
            case A:return 7; case B:return 8; case X:return 5; case Y:return 4;
            case L1:return 12; case R1:return 13; case START:return 9; case SELECT:return 6;
            default:return -1;
        }
    }
}
