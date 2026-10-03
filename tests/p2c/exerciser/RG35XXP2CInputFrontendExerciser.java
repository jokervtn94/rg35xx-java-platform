import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Graphics;
import javax.microedition.midlet.MIDlet;
import javax.microedition.midlet.MIDletStateChangeException;

/**
 * Generated/non-commercial P2C Input/Frontend module exerciser.
 *
 * Device interaction uses public MIDP Canvas key/pointer callbacks only.
 * Physical hotkeys are exercised by the human tester; the exerciser verifies
 * the resulting canonical key/pointer events and logical launch resolution.
 */
public final class RG35XXP2CInputFrontendExerciser extends MIDlet {
    private P2CCanvas canvas;

    protected void startApp() throws MIDletStateChangeException {
        if (canvas == null) {
            canvas = new P2CCanvas(this);
            Display.getDisplay(this).setCurrent(canvas);
            canvas.begin();
        } else {
            Display.getDisplay(this).setCurrent(canvas);
        }
    }

    protected void pauseApp() { }
    protected void destroyApp(boolean unconditional) throws MIDletStateChangeException { }

    private static final class P2CCanvas extends Canvas {
        private static final int LOGICAL_W = 176;
        private static final int LOGICAL_H = 208;
        private static final int BG = 0x00101820;
        private static final int PASS = 0x0000A840;
        private static final int FAIL = 0x00B02030;
        private static final int TEXT = 0x00FFFFFF;

        private static final String[] DEFAULT_NAMES = {
            "UP", "DOWN", "LEFT", "RIGHT", "Y", "A", "X", "B",
            "SELECT", "START", "L1", "R1", "L2", "R2"
        };
        private static final int[] DEFAULT_CODES = {
            50, 56, 52, 54, -6, -7, 53, 48, 42, 35, 49, 51, 55, 57
        };

        private final RG35XXP2CInputFrontendExerciser app;
        private final int phase;
        private int stage;
        private int pressedCode;
        private boolean pressed;
        private boolean pointerPressedSeen;
        private boolean finished;
        private boolean overall = true;
        private String detail = "NONE";

        P2CCanvas(RG35XXP2CInputFrontendExerciser owner) {
            app = owner;
            setFullScreenMode(true);
            phase = parsePhase(System.getProperty("p2c.exerciser.phase"));
            System.out.println("P2C_EXERCISER_BOOT=PASS");
            System.out.println("P2C_EXERCISER_PHASE=" + phase);
        }

        void begin() {
            if (getWidth() != LOGICAL_W || getHeight() != LOGICAL_H) {
                fail("RESOLUTION expected=" + LOGICAL_W + "x" + LOGICAL_H +
                     " actual=" + getWidth() + "x" + getHeight());
                return;
            }
            System.out.println("P2C_EXERCISER_RESOLUTION=" + getWidth() + "x" + getHeight() + " RESULT=PASS");
            repaint();
            serviceRepaints();
        }

        protected void paint(Graphics g) {
            int w = getWidth();
            int h = getHeight();
            g.setColor(finished ? (overall ? PASS : FAIL) : BG);
            g.fillRect(0, 0, w, h);
            g.setColor(TEXT);
            g.drawString("P2C INPUT/FRONTEND", w / 2, 8, Graphics.HCENTER | Graphics.TOP);
            g.drawString("PHASE " + phase, w / 2, 28, Graphics.HCENTER | Graphics.TOP);
            if (finished) {
                g.drawString(overall ? "PASS" : "FAIL", w / 2, 62, Graphics.HCENTER | Graphics.TOP);
                if (!overall) g.drawString(shortText(detail, 23), w / 2, 88, Graphics.HCENTER | Graphics.TOP);
                g.drawString("Press A to continue", w / 2, 126, Graphics.HCENTER | Graphics.TOP);
                g.drawString("Return must be normal", w / 2, 150, Graphics.HCENTER | Graphics.TOP);
                return;
            }
            g.drawString(shortText(prompt(), 27), w / 2, 62, Graphics.HCENTER | Graphics.TOP);
            g.drawString(shortText(prompt2(), 27), w / 2, 88, Graphics.HCENTER | Graphics.TOP);
            g.drawString("Step " + stage, w / 2, 124, Graphics.HCENTER | Graphics.TOP);
            drawOrientation(g, w, h);
        }

        private void drawOrientation(Graphics g, int w, int h) {
            g.drawString("TOP", w / 2, 160, Graphics.HCENTER | Graphics.TOP);
            g.drawString("L", 4, h - 18, Graphics.LEFT | Graphics.TOP);
            g.drawString("R", w - 4, h - 18, Graphics.RIGHT | Graphics.TOP);
        }

        public void keyPressed(int keyCode) {
            if (finished) {
                System.out.println("P2C_EXERCISER_EXIT_REQUEST=PASS PHASE=" + phase);
                app.notifyDestroyed();
                return;
            }
            if (isChordStage()) {
                return;
            }
            if (phase == 2 && stage == 17) {
                return; // pointer mode owns D-pad/X; pointer callbacks are the authority.
            }
            int expected = expectedKeyCode();
            if (expected == Integer.MIN_VALUE) {
                fail("unexpected key event stage=" + stage + " code=" + keyCode);
                return;
            }
            if (keyCode != expected) {
                fail("key press stage=" + stage + " expected=" + expected + " actual=" + keyCode);
                return;
            }
            pressed = true;
            pressedCode = keyCode;
        }

        public void keyReleased(int keyCode) {
            if (finished) return;
            if (isChordStage()) {
                int expected = chordReleaseCode();
                if (keyCode == expected) passStep("HOTKEY_" + stage);
                return;
            }
            if (phase == 2 && stage == 17) return;
            if (!pressed || keyCode != pressedCode) {
                fail("unbalanced release stage=" + stage + " code=" + keyCode);
                return;
            }
            int expected = expectedKeyCode();
            if (keyCode != expected) {
                fail("key release stage=" + stage + " expected=" + expected + " actual=" + keyCode);
                return;
            }
            pressed = false;
            pressedCode = 0;
            passStep(stepName());
        }

        public void keyRepeated(int keyCode) {
            // Repeats are permitted by canonical Canvas semantics but are not needed
            // to establish this physical module contract.
        }

        public void pointerPressed(int x, int y) {
            if (finished) return;
            if (phase != 2 || stage != 17) {
                fail("unexpected pointerPressed " + x + "," + y + " stage=" + stage);
                return;
            }
            if (x != 6 || y != 6) {
                fail("pointer press expected=6,6 actual=" + x + "," + y);
                return;
            }
            pointerPressedSeen = true;
            System.out.println("P2C_EXERCISER_POINTER_PRESS=6,6 RESULT=PASS");
        }

        public void pointerReleased(int x, int y) {
            if (finished) return;
            if (phase != 2 || stage != 17 || !pointerPressedSeen) {
                fail("unexpected pointerReleased " + x + "," + y + " stage=" + stage);
                return;
            }
            if (x != 6 || y != 6) {
                fail("pointer release expected=6,6 actual=" + x + "," + y);
                return;
            }
            pointerPressedSeen = false;
            System.out.println("P2C_EXERCISER_POINTER_RELEASE=6,6 RESULT=PASS");
            passStep("POINTER_RIGHT_DOWN_X");
        }

        private boolean isChordStage() {
            if (phase == 1) return stage == 14 || stage == 16 || stage == 18 || stage == 20 || stage == 22 || stage == 24;
            if (phase == 2) return stage == 1 || stage == 2 || stage == 3 || stage == 4 ||
                                  stage == 16 || stage == 18 || stage == 19 || stage == 21 || stage == 23;
            return false;
        }

        private int chordReleaseCode() {
            if (phase == 1) {
                if (stage == 18) return 117; // e-mode SELECT is Ericsson '*'.
                return 42;
            }
            if (phase == 2) return stage <= 4 ? (stage == 2 ? 117 : 42) : 35;
            return Integer.MIN_VALUE;
        }

        private int expectedKeyCode() {
            if (phase == 1) {
                if (stage >= 0 && stage < DEFAULT_CODES.length) return DEFAULT_CODES[stage];
                if (stage == 15) return -5;  // n-mode X -> Nokia soft3
                if (stage == 17) return 109; // e-mode B -> Ericsson 0
                if (stage == 19) return -59; // s-mode Up
                if (stage == 21) return -21; // m-mode Y -> Motorola soft1
                if (stage == 23) return 50;  // p-mode Up
                if (stage == 25) return -5;  // final n-mode persistence anchor
            } else if (phase == 2) {
                if (stage == 0) return -5;   // persisted n-mode X
                if (stage == 5) return -6;   // custom A -> left phone
                if (stage == 6) return -7;   // custom Y -> right phone
                if (stage == 7) return 53;   // custom B -> OK
                if (stage == 8) return 42;   // custom START -> *
                if (stage == 9) return 35;   // custom SELECT -> #
                if (stage == 10) return 48;  // custom X -> 0
                if (stage == 11) return 49;  // custom R1 -> 1
                if (stage == 12) return 51;  // custom L1 -> 3
                if (stage == 13) return 55;  // custom R2 -> 7
                if (stage == 14) return 57;  // custom L2 -> 9
                if (stage == 15) return 50;  // p-mode Up
                if (stage == 20) return 54;  // rotation 1: physical Up -> logical Right
                if (stage == 22) return 52;  // rotation 2: physical Up -> logical Left
                if (stage == 24) return 50;  // rotation 0 restored
            } else if (phase == 3) {
                int[] codes = {-7, -6, 53, 48, 55, 57};
                if (stage >= 0 && stage < codes.length) return codes[stage];
            }
            return Integer.MIN_VALUE;
        }

        private String stepName() {
            if (phase == 1) {
                if (stage < DEFAULT_NAMES.length) return "DEFAULT_" + DEFAULT_NAMES[stage];
                if (stage == 15) return "PHONE_N_X";
                if (stage == 17) return "PHONE_E_B";
                if (stage == 19) return "PHONE_S_UP";
                if (stage == 21) return "PHONE_M_Y";
                if (stage == 23) return "PHONE_P_UP";
                if (stage == 25) return "PHONE_N_PERSIST_ANCHOR";
            } else if (phase == 2) {
                String[] names = {"PERSISTED_N_X", "", "", "", "", "CUSTOM_A_LEFT", "CUSTOM_Y_RIGHT",
                    "CUSTOM_B_OK", "CUSTOM_START_STAR", "CUSTOM_SELECT_POUND", "CUSTOM_X_ZERO",
                    "CUSTOM_R1_ONE", "CUSTOM_L1_THREE", "CUSTOM_R2_SEVEN", "CUSTOM_L2_NINE",
                    "CUSTOM_UP", "", "POINTER", "", "", "ROT1_UP_RIGHT", "", "ROT2_UP_LEFT", "", "ROT0_UP"};
                if (stage >= 0 && stage < names.length && names[stage].length() > 0) return names[stage];
            } else if (phase == 3) {
                String[] names = {"FALLBACK_A", "FALLBACK_Y", "FALLBACK_X", "FALLBACK_B", "FALLBACK_L2", "FALLBACK_R2"};
                if (stage >= 0 && stage < names.length) return names[stage];
            }
            return "STEP_" + stage;
        }

        private void passStep(String name) {
            System.out.println("P2C_EXERCISER_STEP=" + name + " RESULT=PASS");
            stage++;
            repaint();
            serviceRepaints();
            if (phase == 1 && stage > 25) finishPass();
            else if (phase == 2 && stage > 24) finishPass();
            else if (phase == 3 && stage > 5) finishPass();
        }

        private void finishPass() {
            finished = true;
            overall = true;
            System.out.println("P2C_EXERCISER_RESULT=PASS PHASE=" + phase);
            repaint();
            serviceRepaints();
        }

        private void fail(String why) {
            finished = true;
            overall = false;
            detail = why;
            System.out.println("P2C_EXERCISER_RESULT=FAIL PHASE=" + phase + " DETAIL=" + why);
            repaint();
            serviceRepaints();
        }

        private String prompt() {
            if (phase == 1) {
                if (stage < DEFAULT_NAMES.length) return "Press+release " + DEFAULT_NAMES[stage];
                if (stage == 14) return "SELECT+START -> n";
                if (stage == 15) return "Press X (n mode)";
                if (stage == 16) return "SELECT+START -> e";
                if (stage == 17) return "Press B (e mode)";
                if (stage == 18) return "SELECT+START -> s";
                if (stage == 19) return "Press UP (s mode)";
                if (stage == 20) return "SELECT+START -> m";
                if (stage == 21) return "Press Y (m mode)";
                if (stage == 22) return "SELECT+START -> p";
                if (stage == 23) return "Press UP (p mode)";
                if (stage == 24) return "SELECT+START -> n";
                if (stage == 25) return "Press X, leave n persisted";
            } else if (phase == 2) {
                if (stage == 0) return "Persisted n: press X";
                if (stage >= 1 && stage <= 4) return "SELECT+START cycle " + stage + "/4";
                if (stage == 5) return "Custom map: press A";
                if (stage == 6) return "Custom map: press Y";
                if (stage == 7) return "Custom map: press B";
                if (stage == 8) return "Custom map: press START";
                if (stage == 9) return "Custom map: press SELECT";
                if (stage == 10) return "Custom map: press X";
                if (stage == 11) return "Custom map: press R1";
                if (stage == 12) return "Custom map: press L1";
                if (stage == 13) return "Custom map: press R2";
                if (stage == 14) return "Custom map: press L2";
                if (stage == 15) return "Custom map: press UP";
                if (stage == 16) return "SELECT+Y -> pointer ON";
                if (stage == 17) return "RIGHT, DOWN, then X";
                if (stage == 18) return "SELECT+Y -> pointer OFF";
                if (stage == 19) return "SELECT+B -> rotation 1";
                if (stage == 20) return "Press physical UP";
                if (stage == 21) return "SELECT+B -> rotation 2";
                if (stage == 22) return "Press physical UP";
                if (stage == 23) return "SELECT+B -> rotation 0";
                if (stage == 24) return "Press physical UP";
            } else if (phase == 3) {
                String[] names = {"A", "Y", "X", "B", "L2", "R2"};
                if (stage >= 0 && stage < names.length) return "Invalid keymap: press " + names[stage];
            }
            return "Await input";
        }

        private String prompt2() {
            if (isChordStage()) return "Hold SELECT, tap partner, release";
            if (phase == 2 && stage == 17) return "Expect pointer at 6,6";
            if (phase == 2 && (stage == 20 || stage == 22 || stage == 24)) return "Observe screen orientation too";
            return "Release each tested control";
        }

        private static int parsePhase(String s) {
            try {
                int p = Integer.parseInt(s == null ? "1" : s);
                if (p >= 1 && p <= 3) return p;
            } catch (Exception e) { }
            return 1;
        }

        private static String shortText(String s, int max) {
            if (s == null) return "";
            return s.length() <= max ? s : s.substring(0, max);
        }
    }
}
