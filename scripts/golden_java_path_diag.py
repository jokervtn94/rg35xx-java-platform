#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: golden_java_path_diag.py <Libretro.java>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
orig = s

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit('JAVA PATH DIAG FAIL: %s marker count=%d' % (label, n))
    s = s.replace(old, new, 1)

once(
    '\tpublic static void main(String args[])\n\t{\n',
    '\tpublic static void main(String args[])\n\t{\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: main ENTER args=" + args.length);\n',
    'main')

once(
    '\tpublic Libretro(String args[])\n\t{\n',
    '\tpublic Libretro(String args[])\n\t{\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: constructor ENTER");\n',
    'constructor')

once(
    '\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\t\trg35xxFrames = new RG35XXGoldenFrameTransport(ipcOut);',
    '\t\tlcdData = Mobile.getPlatform().getLcdFrontbuffer().getDataBuffer();\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: platform READY lcd=" + lcdWidth + "x" + lcdHeight + " pixels=" + lcdData.length);\n\t\trg35xxFrames = new RG35XXGoldenFrameTransport(ipcOut);\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: frame transport CREATED");',
    'platform ready')

once(
    '\t\tlio.start();\n\n\t\tipcOut.println("+READY");',
    '\t\tlio.start();\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: IO thread START requested");\n\n\t\tipcOut.println("+READY");',
    'lio start')

once(
    '\t\tipcOut.flush();\n\t}',
    '\t\tipcOut.flush();\n\t\tSystem.err.println("RG35XX-JAVA-DIAG: READY sent");\n\t}',
    'ready sent')

once(
    '\t\tpublic void run()\n\t\t{\n\t\t\tint bin;',
    '\t\tpublic void run()\n\t\t{\n\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: IO thread ENTER");\n\t\t\tint bin;',
    'io enter')

once(
    '\t\t\t\t\tif(bin==-1) { return; }',
    '\t\t\t\t\tif(bin==-1) { System.err.println("RG35XX-JAVA-DIAG: stdin EOF"); return; }',
    'stdin eof')

once(
    '\t\t\t\t\t\t\tcase 10: // load jar\n',
    '\t\t\t\t\t\t\tcase 10: // load jar\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD10 LOAD bytes=" + code);\n',
    'cmd10')

once(
    '\t\t\t\t\t\t\t\tpath = new String(buffer, 0, bytesRead);\n',
    '\t\t\t\t\t\t\t\tpath = new String(buffer, 0, bytesRead);\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD10 path=" + path + " bytesRead=" + bytesRead);\n',
    'cmd10 path')

load_expr = 'if(Mobile.getPlatform().load(getFormattedLocation(URLDecoder.decode(path, Mobile.textEncoding))))\n\t\t\t\t\t\t\t\t{\n'
once(
    load_expr,
    load_expr + '\t\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD10 load PASS restart=" + Mobile.libretroRestartRequested);\n',
    'cmd10 load pass')

once(
    '\t\t\t\t\t\t\t\telse\n\t\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\tMobile.log(',
    '\t\t\t\t\t\t\t\telse\n\t\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD10 load FAIL path=" + path);\n\t\t\t\t\t\t\t\t\tMobile.log(',
    'cmd10 load fail')

once(
    '\t\t\t\t\t\t\tcase 13: // Run jar\n',
    '\t\t\t\t\t\t\tcase 13: // Run jar\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD13 RUN bytes=" + code);\n',
    'cmd13')

# This occurrence is unique because CMD13 immediately follows buffer read.
once(
    '\t\t\t\t\t\t\t\tbytesRead = System.in.read(buffer);\n\t\t\t\t\t\t\t\tMobile.getPlatform().runJar();\n\t\t\t\t\t\t\tbreak;\n\n\t\t\t\t\t\t\tcase 15:',
    '\t\t\t\t\t\t\t\tbytesRead = System.in.read(buffer);\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD13 before runJar bytesRead=" + bytesRead);\n\t\t\t\t\t\t\t\tMobile.getPlatform().runJar();\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD13 after runJar");\n\t\t\t\t\t\t\tbreak;\n\n\t\t\t\t\t\t\tcase 15:',
    'cmd13 run')

once(
    '\t\t\t\t\t\t\tcase 15: // Libretro core requested a new frame.\n',
    '\t\t\t\t\t\t\tcase 15: // Libretro core requested a new frame.\n\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD15 FRAME ack=" + din[3] + " ff=" + din[4]);\n',
    'cmd15')

once(
    '\t\t\t\t\t\t\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n',
    '\t\t\t\t\t\t\t\tSystem.err.println("RG35XX-JAVA-DIAG: CMD15 requestFrame lcd=" + lcdWidth + "x" + lcdHeight + " data=" + (lcdData == null ? -1 : lcdData.length));\n\t\t\t\t\t\t\t\trg35xxFrames.requestFrame(lcdWidth, lcdHeight, lcdData,\n',
    'request frame')

for token in ('CMD10 LOAD', 'CMD13 RUN', 'CMD15 FRAME', 'READY sent'):
    if token not in s:
        raise SystemExit('JAVA PATH DIAG FAIL: required token missing ' + token)

if s == orig:
    raise SystemExit('JAVA PATH DIAG FAIL: no mutation')

p.write_text(s, encoding='utf-8', newline='\n')
print('JAVA PATH DIAG PASS:', p)
