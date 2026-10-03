package org.recompile.rg35xx;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.recompile.mobile.Mobile;
import org.recompile.mobile.MobilePlatform;

/**
 * Pinned Miyoo frontend policy adapted to the original RG35XX boundary.
 * Owns only physical role selection / hotkey state / pointer / rotation state;
 * J2ME event semantics remain in MobilePlatform/Canvas/GameCanvas.
 */
public final class RG35XXFrontendPolicy {
    private static final int STEP = 6;

    private static final int ROLE_NONE = 0;
    private static final int ROLE_UP = 1;
    private static final int ROLE_DOWN = 2;
    private static final int ROLE_LEFT = 3;
    private static final int ROLE_RIGHT = 4;
    private static final int ROLE_PHONE_LEFT = 5;
    private static final int ROLE_PHONE_RIGHT = 6;
    private static final int ROLE_OK = 7;
    private static final int ROLE_STAR = 8;
    private static final int ROLE_POUND = 9;
    private static final int ROLE_0 = 10;
    private static final int ROLE_1 = 11;
    private static final int ROLE_3 = 12;
    private static final int ROLE_7 = 13;
    private static final int ROLE_9 = 14;

    private final MobilePlatform platform;
    private final File configFile;
    private final File keymapFile;

    private int keyLeft = RG35XXKeyDispatcher.Y;
    private int keyRight = RG35XXKeyDispatcher.A;
    private int keyOk = RG35XXKeyDispatcher.X;
    private int keyStar = RG35XXKeyDispatcher.SELECT;
    private int keyPound = RG35XXKeyDispatcher.START;
    private int key0 = RG35XXKeyDispatcher.B;
    private int key1 = RG35XXKeyDispatcher.L1;
    private int key3 = RG35XXKeyDispatcher.R1;
    private int key7 = RG35XXKeyDispatcher.L2;
    private int key9 = RG35XXKeyDispatcher.R2;

    private char phoneMode = 'p';
    private int rotation;
    private boolean pointerMode;
    private boolean pointerDown;
    private int pointerX;
    private int pointerY;

    public RG35XXFrontendPolicy(MobilePlatform platform, File dataDir, File rootDir,
                                String appName, int width, int height) {
        if (platform == null) throw new IllegalArgumentException("platform");
        this.platform = platform;
        if (dataDir == null) dataDir = new File(".").getAbsoluteFile();
        if (rootDir == null) rootDir = dataDir;
        String safe = sanitizeAppName(appName) + width + height;
        File configDir = new File(new File(dataDir, "config"), safe);
        if (!configDir.isDirectory()) configDir.mkdirs();
        configFile = new File(configDir, "game.conf");
        keymapFile = resolveKeymapFile(dataDir, rootDir);
        loadPhoneMode();
        loadKeymap();
    }

    public int mapPhysicalToMobileKey(int physicalId) {
        int id = rotateDirection(physicalId);
        return roleToMobileKey(roleForPhysical(id));
    }

    public boolean isPointerMode() { return pointerMode; }
    public boolean isPointerDown() { return pointerDown; }
    public int getPointerX() { return pointerX; }
    public int getPointerY() { return pointerY; }
    public int getRotation() { return rotation; }
    public char getPhoneMode() { return phoneMode; }
    public boolean isOkPhysical(int physicalId) { return roleForPhysical(physicalId) == ROLE_OK; }

    public void cyclePhoneMode() {
        switch (phoneMode) {
            case 'p': phoneMode = 'n'; break;
            case 'n': phoneMode = 'e'; break;
            case 'e': phoneMode = 's'; break;
            case 's': phoneMode = 'm'; break;
            default: phoneMode = 'p'; break;
        }
        savePhoneMode();
    }

    public void cycleRotation() {
        rotation = (rotation + 1) % 3;
    }

    public void togglePointerMode() {
        if (pointerMode && pointerDown) {
            platform.pointerReleased(pointerX, pointerY);
            pointerDown = false;
        }
        pointerMode = !pointerMode;
    }

    public boolean movePointer(int physicalId) {
        if (!pointerMode || rotation != 0) return false;
        int maxX = Math.max(0, platform.lcdWidth - 8);
        int maxY = Math.max(0, platform.lcdHeight - 11);
        switch (physicalId) {
            case RG35XXKeyDispatcher.UP:
                pointerY = Math.max(0, pointerY - STEP); return true;
            case RG35XXKeyDispatcher.DOWN:
                pointerY = Math.min(maxY, pointerY + STEP); return true;
            case RG35XXKeyDispatcher.LEFT:
                pointerX = Math.max(0, pointerX - STEP); return true;
            case RG35XXKeyDispatcher.RIGHT:
                pointerX = Math.min(maxX, pointerX + STEP); return true;
            default:
                return false;
        }
    }

    public boolean setPointerConfirm(boolean down) {
        if (!pointerMode) return false;
        if (down && !pointerDown) {
            platform.pointerPressed(pointerX, pointerY);
            pointerDown = true;
        } else if (!down && pointerDown) {
            platform.pointerReleased(pointerX, pointerY);
            pointerDown = false;
        }
        return true;
    }

    public void drawPointerCursor(int[] pixels, int width, int height) {
        if (!pointerMode || rotation != 0 || pixels == null) return;
        int[] cursor = CURSOR;
        for (int y = 0; y < 21; y++) {
            int py = pointerY + y;
            if (py < 0 || py >= height) continue;
            for (int x = 0; x < 17; x++) {
                int px = pointerX + x;
                if (px < 0 || px >= width) continue;
                int v = cursor[y * 17 + x];
                if (v == 1) pixels[py * width + px] = 0xFF000000;
                else if (v == 2) pixels[py * width + px] = 0xFFFFFFFF;
            }
        }
    }

    private int rotateDirection(int id) {
        if (rotation == 1) {
            if (id == RG35XXKeyDispatcher.UP) return RG35XXKeyDispatcher.RIGHT;
            if (id == RG35XXKeyDispatcher.DOWN) return RG35XXKeyDispatcher.LEFT;
            if (id == RG35XXKeyDispatcher.LEFT) return RG35XXKeyDispatcher.UP;
            if (id == RG35XXKeyDispatcher.RIGHT) return RG35XXKeyDispatcher.DOWN;
        } else if (rotation == 2) {
            if (id == RG35XXKeyDispatcher.UP) return RG35XXKeyDispatcher.LEFT;
            if (id == RG35XXKeyDispatcher.DOWN) return RG35XXKeyDispatcher.RIGHT;
            if (id == RG35XXKeyDispatcher.LEFT) return RG35XXKeyDispatcher.DOWN;
            if (id == RG35XXKeyDispatcher.RIGHT) return RG35XXKeyDispatcher.UP;
        }
        return id;
    }

    private int roleForPhysical(int id) {
        if (id == RG35XXKeyDispatcher.UP) return ROLE_UP;
        if (id == RG35XXKeyDispatcher.DOWN) return ROLE_DOWN;
        if (id == RG35XXKeyDispatcher.LEFT) return ROLE_LEFT;
        if (id == RG35XXKeyDispatcher.RIGHT) return ROLE_RIGHT;

        if (id == keyRight) return ROLE_PHONE_RIGHT;
        if (id == key0) return ROLE_0;
        if (id == keyOk) return ROLE_OK;
        if (id == keyLeft) return ROLE_PHONE_LEFT;
        if (id == keyPound) return ROLE_POUND;
        if (id == keyStar) return ROLE_STAR;
        if (id == key1) return ROLE_1;
        if (id == key7) return ROLE_7;
        if (id == key3) return ROLE_3;
        if (id == key9) return ROLE_9;
        return ROLE_NONE;
    }

    private int roleToMobileKey(int role) {
        if (phoneMode == 'n' || phoneMode == 'e') {
            if (role == ROLE_UP) return Mobile.NOKIA_UP;
            if (role == ROLE_DOWN) return Mobile.NOKIA_DOWN;
            if (role == ROLE_LEFT) return Mobile.NOKIA_LEFT;
            if (role == ROLE_RIGHT) return Mobile.NOKIA_RIGHT;
            if (role == ROLE_OK) return Mobile.NOKIA_SOFT3;
        } else if (phoneMode == 's') {
            if (role == ROLE_UP) return Mobile.SIEMENS_UP;
            if (role == ROLE_DOWN) return Mobile.SIEMENS_DOWN;
            if (role == ROLE_LEFT) return Mobile.SIEMENS_LEFT;
            if (role == ROLE_RIGHT) return Mobile.SIEMENS_RIGHT;
            if (role == ROLE_PHONE_LEFT) return Mobile.SIEMENS_SOFT1;
            if (role == ROLE_PHONE_RIGHT) return Mobile.SIEMENS_SOFT2;
            if (role == ROLE_OK) return Mobile.SIEMENS_FIRE;
        } else if (phoneMode == 'm') {
            if (role == ROLE_UP) return Mobile.MOTOROLA_UP;
            if (role == ROLE_DOWN) return Mobile.MOTOROLA_DOWN;
            if (role == ROLE_LEFT) return Mobile.MOTOROLA_LEFT;
            if (role == ROLE_RIGHT) return Mobile.MOTOROLA_RIGHT;
            if (role == ROLE_PHONE_LEFT) return Mobile.MOTOROLA_SOFT1;
            if (role == ROLE_PHONE_RIGHT) return Mobile.MOTOROLA_SOFT2;
            if (role == ROLE_OK) return Mobile.MOTOROLA_FIRE;
        }

        if (phoneMode == 'e') {
            if (role == ROLE_0) return 109;
            if (role == ROLE_1) return 114;
            if (role == ROLE_3) return 121;
            if (role == ROLE_7) return 118;
            if (role == ROLE_9) return 110;
            if (role == ROLE_STAR) return 117;
            if (role == ROLE_POUND) return 106;
        }

        switch (role) {
            case ROLE_UP: return Mobile.KEY_NUM2;
            case ROLE_DOWN: return Mobile.KEY_NUM8;
            case ROLE_LEFT: return Mobile.KEY_NUM4;
            case ROLE_RIGHT: return Mobile.KEY_NUM6;
            case ROLE_PHONE_LEFT: return Mobile.NOKIA_SOFT1;
            case ROLE_PHONE_RIGHT: return Mobile.NOKIA_SOFT2;
            case ROLE_OK: return Mobile.KEY_NUM5;
            case ROLE_STAR: return Mobile.KEY_STAR;
            case ROLE_POUND: return Mobile.KEY_POUND;
            case ROLE_0: return Mobile.KEY_NUM0;
            case ROLE_1: return Mobile.KEY_NUM1;
            case ROLE_3: return Mobile.KEY_NUM3;
            case ROLE_7: return Mobile.KEY_NUM7;
            case ROLE_9: return Mobile.KEY_NUM9;
            default: return 0;
        }
    }

    private static File resolveKeymapFile(File dataDir, File rootDir) {
        String explicit = System.getProperty("rg35xx.keymap");
        if (explicit != null && explicit.length() > 0) return new File(explicit).getAbsoluteFile();
        File f = new File(dataDir, "keymap.cfg");
        if (f.isFile()) return f;
        f = new File(rootDir, "keymap.cfg");
        if (f.isFile()) return f;
        return new File("keymap.cfg").getAbsoluteFile();
    }

    private void loadKeymap() {
        setDefaultKeymap();
        if (!keymapFile.isFile()) return;
        try {
            String text = readAll(keymapFile);
            int left = keyNameToId(jsonStringValue(text, "\u5de6\u952e"));
            int right = keyNameToId(jsonStringValue(text, "\u53f3\u952e"));
            int ok = keyNameToId(jsonStringValue(text, "OK"));
            int star = keyNameToId(jsonStringValue(text, "*"));
            int pound = keyNameToId(jsonStringValue(text, "#"));
            int zero = keyNameToId(jsonStringValue(text, "0"));
            int one = keyNameToId(jsonStringValue(text, "1"));
            int three = keyNameToId(jsonStringValue(text, "3"));
            int seven = keyNameToId(jsonStringValue(text, "7"));
            int nine = keyNameToId(jsonStringValue(text, "9"));
            if (left == 0 || right == 0 || ok == 0 || star == 0 || pound == 0 || zero == 0 ||
                one == 0 || three == 0 || seven == 0 || nine == 0) {
                setDefaultKeymap();
                return;
            }
            keyLeft = left; keyRight = right; keyOk = ok; keyStar = star; keyPound = pound;
            key0 = zero; key1 = one; key3 = three; key7 = seven; key9 = nine;
        } catch (Exception e) {
            setDefaultKeymap();
        }
    }

    private void setDefaultKeymap() {
        keyLeft = RG35XXKeyDispatcher.Y;
        keyRight = RG35XXKeyDispatcher.A;
        keyOk = RG35XXKeyDispatcher.X;
        keyStar = RG35XXKeyDispatcher.SELECT;
        keyPound = RG35XXKeyDispatcher.START;
        key0 = RG35XXKeyDispatcher.B;
        key1 = RG35XXKeyDispatcher.L1;
        key3 = RG35XXKeyDispatcher.R1;
        key7 = RG35XXKeyDispatcher.L2;
        key9 = RG35XXKeyDispatcher.R2;
    }

    private static int keyNameToId(String name) {
        if (name == null) return 0;
        String n = name.trim().toUpperCase(Locale.US);
        if ("A".equals(n)) return RG35XXKeyDispatcher.A;
        if ("B".equals(n)) return RG35XXKeyDispatcher.B;
        if ("X".equals(n)) return RG35XXKeyDispatcher.X;
        if ("Y".equals(n)) return RG35XXKeyDispatcher.Y;
        if ("SELECT".equals(n)) return RG35XXKeyDispatcher.SELECT;
        if ("START".equals(n)) return RG35XXKeyDispatcher.START;
        if ("L".equals(n) || "L1".equals(n)) return RG35XXKeyDispatcher.L1;
        if ("R".equals(n) || "R1".equals(n)) return RG35XXKeyDispatcher.R1;
        if ("L2".equals(n)) return RG35XXKeyDispatcher.L2;
        if ("R2".equals(n)) return RG35XXKeyDispatcher.R2;
        return 0;
    }

    private void loadPhoneMode() {
        phoneMode = 'p';
        if (!configFile.isFile()) return;
        BufferedReader r = null;
        try {
            r = new BufferedReader(new InputStreamReader(new FileInputStream(configFile), "UTF-8"));
            String line;
            while ((line = r.readLine()) != null) {
                int c = line.indexOf(':');
                if (c <= 0) continue;
                String key = line.substring(0, c).trim();
                String value = line.substring(c + 1).trim();
                if ("phone".equals(key) && value.length() == 1 && validMode(value.charAt(0))) {
                    phoneMode = value.charAt(0);
                }
            }
        } catch (Exception e) {
            phoneMode = 'p';
        } finally {
            if (r != null) try { r.close(); } catch (Exception e) { }
        }
    }

    private void savePhoneMode() {
        List<String> lines = new ArrayList<String>();
        boolean replaced = false;
        if (configFile.isFile()) {
            BufferedReader r = null;
            try {
                r = new BufferedReader(new InputStreamReader(new FileInputStream(configFile), "UTF-8"));
                String line;
                while ((line = r.readLine()) != null) {
                    int c = line.indexOf(':');
                    if (c > 0 && "phone".equals(line.substring(0, c).trim())) {
                        lines.add("phone:" + phoneMode);
                        replaced = true;
                    } else {
                        lines.add(line);
                    }
                }
            } catch (Exception e) {
                lines.clear();
                replaced = false;
            } finally {
                if (r != null) try { r.close(); } catch (Exception e) { }
            }
        }
        if (!replaced) lines.add("phone:" + phoneMode);
        BufferedWriter w = null;
        try {
            File parent = configFile.getParentFile();
            if (parent != null && !parent.isDirectory()) parent.mkdirs();
            w = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(configFile), "UTF-8"));
            for (int i = 0; i < lines.size(); i++) {
                w.write(lines.get(i));
                w.write('\n');
            }
        } catch (Exception e) {
            // Persistence failure must not replace input semantics.
        } finally {
            if (w != null) try { w.close(); } catch (Exception e) { }
        }
    }

    private static boolean validMode(char c) {
        return c == 'p' || c == 'n' || c == 'e' || c == 's' || c == 'm';
    }

    private static String readAll(File file) throws Exception {
        BufferedReader r = new BufferedReader(new InputStreamReader(new FileInputStream(file), "UTF-8"));
        StringBuilder b = new StringBuilder();
        try {
            char[] buf = new char[2048];
            int n;
            while ((n = r.read(buf)) >= 0) b.append(buf, 0, n);
        } finally {
            r.close();
        }
        return b.toString();
    }

    private static String jsonStringValue(String text, String key) {
        String quoted = "\"" + key + "\"";
        int p = text.indexOf(quoted);
        if (p < 0) return null;
        p = text.indexOf(':', p + quoted.length());
        if (p < 0) return null;
        p = text.indexOf('"', p + 1);
        if (p < 0) return null;
        int e = text.indexOf('"', p + 1);
        if (e < 0) return null;
        return text.substring(p + 1, e);
    }

    private static String sanitizeAppName(String name) {
        if (name == null || name.length() == 0) return "app";
        String n = name;
        if (n.toLowerCase(Locale.US).endsWith(".jar")) n = n.substring(0, n.length() - 4);
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < n.length(); i++) {
            char c = n.charAt(i);
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.') b.append(c);
            else b.append('_');
        }
        return b.length() == 0 ? "app" : b.toString();
    }

    private static final int[] CURSOR = new int[] {
        0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,1,2,2,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,1,2,2,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,1,2,2,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,1,2,2,1,1,1,0,0,0,0,0,0,0,
        0,0,0,0,1,2,2,1,2,2,1,1,1,0,0,0,0,
        0,0,0,0,1,2,2,1,2,2,1,2,2,1,1,0,0,
        0,0,0,0,1,2,2,1,2,2,1,2,2,1,2,1,0,
        1,1,1,0,1,2,2,1,2,2,1,2,2,1,2,2,1,
        1,2,2,1,1,2,2,2,2,2,2,2,2,1,2,2,1,
        1,2,2,2,1,2,2,2,2,2,2,2,2,2,2,2,1,
        0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,
        0,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,
        0,0,1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,
        0,0,0,1,2,2,2,2,2,2,2,2,2,2,2,2,1,
        0,0,0,1,2,2,2,2,2,2,2,2,2,2,2,1,0,
        0,0,0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,
        0,0,0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,
        0,0,0,0,0,1,2,2,2,2,2,2,2,2,1,0,0,
        0,0,0,0,0,1,2,2,2,2,2,2,2,2,1,0,0,
        0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0
    };
}
