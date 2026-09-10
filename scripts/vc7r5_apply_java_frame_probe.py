#!/usr/bin/env python3
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

if 'RG35XX-VC7R5-JAVA-COLOR' in s:
    raise SystemExit('VC7R5 Java color probe already applied')

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('VC7R5 JAVA COLOR FAIL: %s count=%d' % (label, n))
    s = s.replace(old, new, 1)

once('''    private Thread worker;\n\n    private int width;''',
     '''    private Thread worker;\n\n    /* RG35XX-VC7R5-JAVA-COLOR: diagnostic only. */\n    private int vc7r5ProbeFrames;\n\n    private int width;''',
     'probe field')

helper = r'''
    private static int vc7r5Direct565(int argb)
    {
        return ((argb >> 8) & 0xF800) |
               ((argb >> 5) & 0x07E0) |
               ((argb >> 3) & 0x001F);
    }

    private static String vc7r5Hex8(int v)
    {
        String h = Integer.toHexString(v).toUpperCase();
        while(h.length() < 8) h = "0" + h;
        return h;
    }

    private static String vc7r5Hex4(int v)
    {
        String h = Integer.toHexString(v & 0xFFFF).toUpperCase();
        while(h.length() < 4) h = "0" + h;
        return h;
    }

    private int vc7r5Encoded565At(int pixelIndex)
    {
        int o = pixelIndex * 2;
        return ((rgb565[o] & 0xFF) << 8) | (rgb565[o + 1] & 0xFF);
    }

    private void vc7r5LogSamples(String phase, int w, int h, int pixels, boolean encoded)
    {
        if(vc7r5ProbeFrames >= 8 || pixels <= 0) return;
        int[] idx = new int[] {
            0,
            w > 1 ? w - 1 : 0,
            pixels / 4,
            pixels / 2,
            (pixels * 3) / 4,
            pixels - 1
        };
        StringBuffer b = new StringBuffer(320);
        b.append("RG35XX-VC7R5-JAVA-COLOR: ").append(phase)
         .append(" frame=").append(vc7r5ProbeFrames + 1)
         .append(" size=").append(w).append('x').append(h);
        for(int n = 0; n < idx.length; n++)
        {
            int i = idx[n];
            if(i < 0) i = 0;
            if(i >= pixels) i = pixels - 1;
            int a = argbSnapshot[i];
            int direct = vc7r5Direct565(a);
            b.append(" i").append(i)
             .append("=ARGB:").append(vc7r5Hex8(a))
             .append(" direct565:").append(vc7r5Hex4(direct));
            if(encoded)
                b.append(" encoded565:").append(vc7r5Hex4(vc7r5Encoded565At(i)))
                 .append(" match:").append(direct == vc7r5Encoded565At(i));
        }
        System.err.println(b.toString());
    }

'''
once('''    private void sendFrameLocked(int w, int h, int[] data, Object lock) throws Exception\n    {''',
     helper + '''    private void sendFrameLocked(int w, int h, int[] data, Object lock) throws Exception\n    {''',
     'helper insertion')

once('''        System.err.println("RG35XX-JAVA-DIAG: snapshot COPIED");\n\n        int src = 0;''',
     '''        System.err.println("RG35XX-JAVA-DIAG: snapshot COPIED");\n        vc7r5LogSamples("SNAPSHOT", w, h, pixels, false);\n\n        int src = 0;''',
     'snapshot probe')

once('''        while(src < pixels) dst = put565(argbSnapshot[src++], dst);\n        System.err.println("RG35XX-JAVA-DIAG: RGB565 ENCODED bytes=" + (pixels * 2));''',
     '''        while(src < pixels) dst = put565(argbSnapshot[src++], dst);\n        vc7r5LogSamples("ENCODED", w, h, pixels, true);\n        vc7r5ProbeFrames++;\n        System.err.println("RG35XX-JAVA-DIAG: RGB565 ENCODED bytes=" + (pixels * 2));''',
     'encoded probe')

for req in ('RG35XX-VC7R5-JAVA-COLOR', 'vc7r5Direct565', 'direct565:', 'encoded565:', 'match:'):
    if req not in s:
        raise SystemExit('VC7R5 JAVA COLOR FAIL missing ' + req)
if s == orig:
    raise SystemExit('VC7R5 JAVA COLOR FAIL no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R5 JAVA FRAMEBUFFER COLOR PROBE=PASS')
print('PROBE=ARGB_SNAPSHOT,DIRECT_RGB565,LUT_ENCODED_RGB565')
print('FRAMES=8')
