package org.recompile.mobile;

/**
 * RG35XX Java Platform target-specific MMAPI capability table.
 *
 * This class deliberately reports only formats that the RG35XX path can
 * actually route to a proven decoder/backend. Generic FreeJ2ME desktop
 * capabilities must not leak into Manager.getSupportedContentTypes().
 *
 * Tasklog: RGJ-B1-008, RGJ-B3-002
 */
public final class RG35XXMediaProfile
{
    private static final String[] TYPES = new String[] {
        "audio/midi",
        "audio/x-midi",
        "audio/wav",
        "audio/x-wav"
    };

    private RG35XXMediaProfile() { }

    public static String[] getSupportedTypes()
    {
        String[] copy = new String[TYPES.length];
        System.arraycopy(TYPES, 0, copy, 0, TYPES.length);
        return copy;
    }

    public static String[] getSupportedTypes(String protocol)
    {
        /*
         * The current RG35XX target does not expose network capture or
         * streaming protocols through MMAPI. Null protocol means all content
         * types. Resource/file-like streams terminate in createPlayer(stream,
         * type) and therefore use the same decoder truth table.
         */
        return getSupportedTypes();
    }

    public static boolean supports(String type)
    {
        if(type == null) { return false; }

        String t = normalize(type);

        if(t.equals("audio/midi") || t.equals("audio/x-midi"))
            return RG35XXPlatformProfile.AUDIO_MIDI;

        if(t.equals("audio/wav") || t.equals("audio/x-wav"))
            return RG35XXPlatformProfile.AUDIO_PCM;

        /* ToneControl conversion is a separate gate. Do not advertise it until
         * the JavaSound-free A-BNF/vendor conversion path is source-audited. */
        if(t.equals("audio/x-tone-seq")) return false;

        /* Explicitly false until a target decoder is proven. */
        if(t.indexOf("amr") >= 0)
            return RG35XXPlatformProfile.AUDIO_AMR;

        if(t.indexOf("mpeg") >= 0 || t.indexOf("mp3") >= 0)
            return RG35XXPlatformProfile.AUDIO_MPEG;

        return false;
    }

    public static boolean isMidi(String type)
    {
        if(type == null) { return false; }
        String t = normalize(type);
        return t.equals("audio/midi") || t.equals("audio/x-midi");
    }

    public static boolean isTone(String type)
    {
        if(type == null) { return false; }
        return normalize(type).equals("audio/x-tone-seq");
    }

    public static boolean isWav(String type)
    {
        if(type == null) { return false; }
        String t = normalize(type);
        return t.equals("audio/wav") || t.equals("audio/x-wav");
    }

    public static String canonicalType(String type)
    {
        if(type == null) { return ""; }
        String t = normalize(type);

        if(t.equals("audio/x-midi")) return "audio/midi";
        if(t.equals("audio/wav")) return "audio/x-wav";
        return t;
    }

    private static String normalize(String type)
    {
        return type.trim().toLowerCase();
    }
}
