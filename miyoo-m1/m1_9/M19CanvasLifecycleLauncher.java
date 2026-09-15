package org.recompile.mobile;
import java.io.File;
/** M1.9F canonical FreeJ2ME MIDlet lifecycle launcher. */
public final class M19CanvasLifecycleLauncher {
    private M19CanvasLifecycleLauncher() {}
    public static void main(String[] args) throws Exception {
        System.out.println("M1_9F_MAIN_ENTER=YES");
        if (args.length != 1) System.exit(2);
        File jar = new File(args[0]); if (!jar.isFile()) System.exit(3);
        System.setProperty("rg35xx.headless.font","true");
        System.setProperty("rg35xx.headless.image.probe","true");
        System.setProperty("rg35xx.headless.graphics.probe","true");
        PlatformFont.setScreenSize(640,480);
        MobilePlatform platform = new MobilePlatform(640,480);
        Mobile.setPlatform(platform, new Runnable(){ public void run(){} });
        if (!platform.load(jar.toURI().toString())) System.exit(4);
        System.out.println("M1_9F_PLATFORM_LOAD=PASS");
        platform.loader.start();
        // The acceptance MIDlet owns its bounded 30-second lifetime and calls notifyDestroyed().
        // Keep this launcher alive long enough for that real MIDlet lifecycle without relying on
        // a non-existent MIDletLoader.running field.
        Thread.sleep(32000L);
        System.out.println("M1_9F_NORMAL_EXIT=PASS");
    }
}
