#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/org/recompile/mobile/MobilePlatform.java')
s = p.read_text(encoding='utf-8')

def replace_once(old, new, label):
    global s
    if s.count(old) != 1:
        raise SystemExit('FAIL_CLOSED_%s_COUNT=%d' % (label, s.count(old)))
    s = s.replace(old, new, 1)

replace_once(
'''\t\tboolean isUsingValidEncoding = false;

\t\t// Check whether we're using any of the valid encodings before starting the jar, otherwise we'll be defaulting to ISO_8859_1
\t\tfor (String encoding : Mobile.supportedEncodings)
\t\t{
\t\t\tif (encoding.equals(System.getProperty("file.encoding"))) { isUsingValidEncoding = true; }
\t\t}

\t\tif(!isUsingValidEncoding)
\t\t{
\t\t\tMobile.textEncoding = Mobile.supportedEncodings[Mobile.ISO_8859_1];
\t\t\tcheckFileEncoding();
\t\t}

\t\tresizeLCD(width, height);''',
'''\t\tSystem.out.println("M1_9F_MP_ENCODING_INIT_BEGIN=YES"); System.out.flush();
\t\tboolean isUsingValidEncoding = false;
\t\tSystem.out.println("M1_9F_MP_ENCODING_PROPERTY=" + System.getProperty("file.encoding")); System.out.flush();

\t\t// Check whether we're using any of the valid encodings before starting the jar, otherwise we'll be defaulting to ISO_8859_1
\t\tSystem.out.println("M1_9F_MP_ENCODING_SCAN_BEGIN=YES"); System.out.flush();
\t\tfor (String encoding : Mobile.supportedEncodings)
\t\t{
\t\t\tif (encoding.equals(System.getProperty("file.encoding"))) { isUsingValidEncoding = true; }
\t\t}
\t\tSystem.out.println("M1_9F_MP_ENCODING_SCAN_END=PASS VALID=" + isUsingValidEncoding); System.out.flush();

\t\tif(!isUsingValidEncoding)
\t\t{
\t\t\tSystem.out.println("M1_9F_MP_ENCODING_FALLBACK_BEGIN=YES"); System.out.flush();
\t\t\tMobile.textEncoding = Mobile.supportedEncodings[Mobile.ISO_8859_1];
\t\t\tSystem.out.println("M1_9F_MP_CHECK_FILE_ENCODING_BEGIN=YES"); System.out.flush();
\t\t\tcheckFileEncoding();
\t\t\tSystem.out.println("M1_9F_MP_CHECK_FILE_ENCODING_END=PASS"); System.out.flush();
\t\t\tSystem.out.println("M1_9F_MP_ENCODING_FALLBACK_END=PASS"); System.out.flush();
\t\t}
\t\tSystem.out.println("M1_9F_MP_ENCODING_INIT_END=PASS"); System.out.flush();

\t\tSystem.out.println("M1_9F_MP_RESIZELCD_CALL_BEGIN=YES"); System.out.flush();
\t\tresizeLCD(width, height);
\t\tSystem.out.println("M1_9F_MP_RESIZELCD_CALL_END=PASS"); System.out.flush();''',
'CONSTRUCTOR_ENCODING_AND_RESIZE')

replace_once(
'''\t\tlcdWidth = width;
\t\tlcdHeight = height;

\t\torg.recompile.mobile.PlatformFont.setScreenSize(width, height);

\t\tlcdFrontbuffer = new PlatformImage(width, height);
\t\tlcd = new PlatformImage(width, height);


        gcFrontbuffer = lcdFrontbuffer.getMIDPGraphics();''',
'''\t\tSystem.out.println("M1_9F_MP_RESIZE_DIMENSIONS_BEGIN=YES"); System.out.flush();
\t\tlcdWidth = width;
\t\tlcdHeight = height;
\t\tSystem.out.println("M1_9F_MP_RESIZE_DIMENSIONS_END=PASS"); System.out.flush();

\t\tSystem.out.println("M1_9F_MP_RESIZE_FONT_BEGIN=YES"); System.out.flush();
\t\torg.recompile.mobile.PlatformFont.setScreenSize(width, height);
\t\tSystem.out.println("M1_9F_MP_RESIZE_FONT_END=PASS"); System.out.flush();

\t\tSystem.out.println("M1_9F_MP_FRONTBUFFER_BEGIN=YES"); System.out.flush();
\t\tlcdFrontbuffer = new PlatformImage(width, height);
\t\tSystem.out.println("M1_9F_MP_FRONTBUFFER_END=PASS"); System.out.flush();
\t\tSystem.out.println("M1_9F_MP_BACKBUFFER_BEGIN=YES"); System.out.flush();
\t\tlcd = new PlatformImage(width, height);
\t\tSystem.out.println("M1_9F_MP_BACKBUFFER_END=PASS"); System.out.flush();


        System.out.println("M1_9F_MP_FRONTGRAPHICS_BEGIN=YES"); System.out.flush();
        gcFrontbuffer = lcdFrontbuffer.getMIDPGraphics();
        System.out.println("M1_9F_MP_FRONTGRAPHICS_END=PASS"); System.out.flush();''',
'RESIZE_ALLOCATION_BLOCK')

replace_once(
'''\t\tif (!Mobile.isDoJa)
\t\t{
\t\t\tgc = lcd.getMIDPGraphics();
\t\t\tcom.xce.lcdui.XDisplay.width = width;
\t\t\tcom.xce.lcdui.XDisplay.height2 = height;
\t\t\tcom.xce.lcdui.XDisplay.platformImage = lcd;
\t\t\tcom.xce.lcdui.Toolkit.graphics = (Graphics) gc;''',
'''\t\tif (!Mobile.isDoJa)
\t\t{
\t\t\tSystem.out.println("M1_9F_MP_BACKGRAPHICS_BEGIN=YES"); System.out.flush();
\t\t\tgc = lcd.getMIDPGraphics();
\t\t\tSystem.out.println("M1_9F_MP_BACKGRAPHICS_END=PASS"); System.out.flush();
\t\t\tSystem.out.println("M1_9F_MP_XCE_BRIDGE_BEGIN=YES"); System.out.flush();
\t\t\tcom.xce.lcdui.XDisplay.width = width;
\t\t\tcom.xce.lcdui.XDisplay.height2 = height;
\t\t\tcom.xce.lcdui.XDisplay.platformImage = lcd;
\t\t\tcom.xce.lcdui.Toolkit.graphics = (Graphics) gc;
\t\t\tSystem.out.println("M1_9F_MP_XCE_BRIDGE_END=PASS"); System.out.flush();''',
'RESIZE_XCE_BLOCK')

p.write_text(s, encoding='utf-8')
print('M1_9F_R4_MOBILEPLATFORM_CONSTRUCTOR_DIAGNOSTICS_PATCH=PASS')
