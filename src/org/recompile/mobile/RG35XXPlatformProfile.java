/*
 * RG35XX Original / GarlicOS platform profile for FreeJ2ME.
 *
 * This class intentionally contains only target constants and no game logic.
 * Runtime subsystems should depend on this profile instead of scattering
 * RG35XX-specific magic numbers across unrelated classes.
 */
package org.recompile.mobile;

public final class RG35XXPlatformProfile
{
    private RG35XXPlatformProfile() { }

    public static final String NAME = "RG35XX Original / ATM7059A / GarlicOS";
    public static final String ACTIVE_PROPERTY = "freej2me.rg35xx";

    public static final int LCD_MAX_WIDTH = 800;
    public static final int LCD_MAX_HEIGHT = 800;

    public static final long FRAME_DIRTY_RECHECK_MS = 250L;

    public static final int FRAME_STATS_INTERVAL = 600;
    public static final boolean HOTPATH_LOGGING = false;

    public static final int IMAGE_CACHE_MAX_BYTES = 12 * 1024 * 1024;
    public static final int IMAGE_CACHE_MAX_ENTRIES = 192;

    public static final long KEY_REPEAT_DELAY_MS = 340L;
    public static final long KEY_REPEAT_INTERVAL_MS = 75L;

    public static final boolean AUDIO_PCM = true;
    public static final boolean AUDIO_IMA_ADPCM = true;
    public static final boolean AUDIO_ALAW = true;
    public static final boolean AUDIO_ULAW = true;
    public static final boolean AUDIO_MIDI = true;
    public static final boolean AUDIO_AMR = false;
    public static final boolean AUDIO_MPEG = false;

    public static final int STATS_LOG_INTERVAL_MS = 30000;

    /**
     * Explicit target selector used by shared upstream facades such as Manager
     * and PlatformPlayer. The RG35XX libretro core supplies this JVM property
     * before -jar. Desktop/AWT runs remain false and retain upstream behavior.
     */
    public static boolean isActive()
    {
        String value = System.getProperty(ACTIVE_PROPERTY);
        return "1".equals(value) || "true".equalsIgnoreCase(value);
    }
}
