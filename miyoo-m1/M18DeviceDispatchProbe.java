package org.recompile.mobile;

import javax.microedition.lcdui.game.GameCanvas;

/** M1.8 device probe: raw js0 transition -> semantic adapter -> actual MobilePlatform owner. */
public final class M18DeviceDispatchProbe {
    static { System.loadLibrary("m1_8_input"); }
    private static native int openInput();
    private static native int nextTransition(int timeoutMs);
    private static native void closeInput();
    private static final String[] N={"UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","L","R"};
    private static final int[] MASK={GameCanvas.UP_PRESSED,GameCanvas.DOWN_PRESSED,GameCanvas.LEFT_PRESSED,GameCanvas.RIGHT_PRESSED,GameCanvas.FIRE_PRESSED,0,GameCanvas.GAME_A_PRESSED,GameCanvas.GAME_B_PRESSED,0,0,GameCanvas.GAME_C_PRESSED,GameCanvas.GAME_D_PRESSED};

    private static int waitFor(int control, int action) {
        long end=System.currentTimeMillis()+15000L;
        while(System.currentTimeMillis()<end) {
            int v=nextTransition(1000); if(v<0)continue;
            int c=v&255, a=(v>>8)&1;
            if(c==control && a==action)return 0;
        }
        return 1;
    }
    public static void main(String[] args) {
        System.out.println("M1_8_JAVA_MARKER=PASS");
        MobilePlatform p=new MobilePlatform(240,320);
        p.suppressKeyEvents=true; /* isolate owner state; callback device gate remains separate */
        int rc=openInput(); System.out.println("M1_8_INPUT_OPEN_RC="+rc); if(rc!=0)System.exit(10);
        for(int i=0;i<N.length;i++) {
            System.out.println("M1_8_WAIT_PRESS="+N[i]); if(waitFor(i,1)!=0){closeInput();System.exit(20+i);}
            M18SemanticKeyAdapter.press(p,i);
            int ks=p.getKeyState(); if(MASK[i]!=0 && (ks&MASK[i])==0){System.out.println("M1_8_STATE_PRESS_FAIL="+N[i]+":"+ks);closeInput();System.exit(40+i);}
            M18SemanticKeyAdapter.repeat(p,i); /* one bounded repeat call; no second dispatcher */
            System.out.println("M1_8_WAIT_RELEASE="+N[i]); if(waitFor(i,0)!=0){closeInput();System.exit(60+i);}
            M18SemanticKeyAdapter.release(p,i);
            ks=p.getKeyState(); if(MASK[i]!=0 && (ks&MASK[i])!=0){System.out.println("M1_8_STATE_RELEASE_FAIL="+N[i]+":"+ks);closeInput();System.exit(80+i);}
            System.out.println("M1_8_CONTROL_"+N[i]+"=PASS");
        }
        closeInput();
        System.out.println("M1_8_MOBILEPLATFORM_STATE_SEQUENCE=PASS");
        System.out.println("M1_8_CALLBACK_GATE=PENDING");
    }
}
