#!/usr/bin/env python3
import pathlib,sys
if len(sys.argv)!=4:
    raise SystemExit('usage: vc7r22r13e_apply_midlet_event_trace.py <Libretro.java> <MobilePlatform.java> <Display.java>')
lib=pathlib.Path(sys.argv[1]); mp=pathlib.Path(sys.argv[2]); disp=pathlib.Path(sys.argv[3])
L=lib.read_text(encoding='utf-8'); M=mp.read_text(encoding='utf-8'); D=disp.read_text(encoding='utf-8')
orig=(L,M,D)

def once(s,old,new,label):
    n=s.count(old)
    if n!=1: raise SystemExit('R13E %s anchor count=%d'%(label,n))
    return s.replace(old,new,1)

# Libretro: raw native->Java input receipt. Sparse by input event count.
L=once(L,
'\tprivate static volatile boolean canPause = false;\n',
'''\tprivate static volatile boolean canPause = false;\n\tprivate static long rg35xxR13EInputRxSeq = 0;\n\n\tprivate static boolean rg35xxR13ETrace(long n) { return n <= 16 || (n % 120L) == 0L; }\n\tprivate static void rg35xxR13ELog(String stage, long n, int code)\n\t{\n\t\tif(rg35xxR13ETrace(n)) System.err.println("RG35XX-R13E-EVENT stage="+stage+" seq="+n+" code="+code);\n\t}\n''','lib state')
L=once(L,
'''\t\t\t\t\t\t\tcase 2:\t// joypad key up\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = false;''',
'''\t\t\t\t\t\t\tcase 2:\t// joypad key up\n\t\t\t\t\t\t\t\trg35xxR13EInputRxSeq++;\n\t\t\t\t\t\t\t\trg35xxR13ELog("LR_RX_UP", rg35xxR13EInputRxSeq, code);\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = false;''','lib up')
L=once(L,
'''\t\t\t\t\t\t\tcase 3: // joypad key down\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = true;''',
'''\t\t\t\t\t\t\tcase 3: // joypad key down\n\t\t\t\t\t\t\t\trg35xxR13EInputRxSeq++;\n\t\t\t\t\t\t\t\trg35xxR13ELog("LR_RX_DOWN", rg35xxR13EInputRxSeq, code);\n\t\t\t\t\t\t\t\tMobilePlatform.pressedKeys[code] = true;''','lib down')

# MobilePlatform: post and delivery around game callback.
M=once(M,
'\tpublic static boolean appTerminated = false;\n',
'''\tpublic static boolean appTerminated = false;\n\tprivate static long rg35xxR13EPostSeq = 0;\n\tprivate static long rg35xxR13EDeliverSeq = 0;\n\tprivate static boolean rg35xxR13ETrace(long n) { return n <= 16 || (n % 120L) == 0L; }\n\tprivate static void rg35xxR13ELog(String stage, long n, int code)\n\t{\n\t\tif(rg35xxR13ETrace(n)) System.err.println("RG35XX-R13E-EVENT stage="+stage+" seq="+n+" code="+code);\n\t}\n''','mp state')
M=once(M,
'''\t\t\tif (!Mobile.isDoJa && Mobile.getDisplay() != null && (displayable = Mobile.getDisplay().getCurrent()) != null)\n\t\t\t{\n\t\t\t\tMobile.getDisplay().postInputEvent(new Runnable()''',
'''\t\t\tif (!Mobile.isDoJa && Mobile.getDisplay() != null && (displayable = Mobile.getDisplay().getCurrent()) != null)\n\t\t\t{\n\t\t\t\trg35xxR13EPostSeq++;\n\t\t\t\trg35xxR13ELog("MP_POST_DOWN", rg35xxR13EPostSeq, keycode);\n\t\t\t\tMobile.getDisplay().postInputEvent(new Runnable()''','mp post down')
M=once(M,
'''\t\t\t\t\tpublic void run()\n\t\t\t\t\t{\n\t\t\t\t\t\tif(!handleCommands(Mobile.getCanvasAction(keycode)))''',
'''\t\t\t\t\tpublic void run()\n\t\t\t\t\t{\n\t\t\t\t\t\trg35xxR13EDeliverSeq++;\n\t\t\t\t\t\trg35xxR13ELog("MP_DELIVER_DOWN_BEGIN", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t\tif(!handleCommands(Mobile.getCanvasAction(keycode)))''','mp deliver down begin')
M=once(M,
'''\t\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed()) { displayable.keyPressed(keycode); }\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n\t\t\t\t});''',
'''\t\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed()) { displayable.keyPressed(keycode); }\n\t\t\t\t\t\t}\n\t\t\t\t\t\trg35xxR13ELog("MP_DELIVER_DOWN_DONE", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t}\n\t\t\t\t});''','mp deliver down done')
# Release path has an extra MIDletSelected clause, unique anchor.
M=once(M,
'''\t\t\tif (!Mobile.isDoJa && Mobile.getDisplay() != null && (displayable = Mobile.getDisplay().getCurrent()) != null && MIDletLoader.MIDletSelected)\n\t\t\t{\n\t\t\t\tMobile.getDisplay().postInputEvent(new Runnable()''',
'''\t\t\tif (!Mobile.isDoJa && Mobile.getDisplay() != null && (displayable = Mobile.getDisplay().getCurrent()) != null && MIDletLoader.MIDletSelected)\n\t\t\t{\n\t\t\t\trg35xxR13EPostSeq++;\n\t\t\t\trg35xxR13ELog("MP_POST_UP", rg35xxR13EPostSeq, keycode);\n\t\t\t\tMobile.getDisplay().postInputEvent(new Runnable()''','mp post up')
M=once(M,
'''\t\t\t\t\tpublic void run()\n\t\t\t\t\t{\n\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed()) { displayable.keyReleased(keycode); }\n\t\t\t\t\t}\n\t\t\t\t});''',
'''\t\t\t\t\tpublic void run()\n\t\t\t\t\t{\n\t\t\t\t\t\trg35xxR13EDeliverSeq++;\n\t\t\t\t\t\trg35xxR13ELog("MP_DELIVER_UP_BEGIN", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed()) { displayable.keyReleased(keycode); }\n\t\t\t\t\t\trg35xxR13ELog("MP_DELIVER_UP_DONE", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t}\n\t\t\t\t});''','mp deliver up')

# Display EDT: queue ingress, dispatch, paint heartbeat, setCurrent lifecycle.
D=once(D,
'\tprivate final Object eventLock = new Object();\n',
'''\tprivate final Object eventLock = new Object();\n\tprivate long rg35xxR13EInputEnqueueSeq = 0;\n\tprivate long rg35xxR13EInputDispatchSeq = 0;\n\tprivate long rg35xxR13EPaintDispatchSeq = 0;\n\tprivate long rg35xxR13ESetCurrentSeq = 0;\n\tprivate boolean rg35xxR13ETrace(long n) { return n <= 16 || (n % 120L) == 0L; }\n\tprivate void rg35xxR13ELog(String stage, long n, int aux)\n\t{\n\t\tif(rg35xxR13ETrace(n)) System.err.println("RG35XX-R13E-EVENT stage="+stage+" seq="+n+" aux="+aux);\n\t}\n''','display state')
D=once(D,
'''\t\tsynchronized (eventLock)\n\t\t{\n\t\t\tinputEvents.add(r);\n\t\t\teventLock.notifyAll();\n\t\t}\n\t}\n\n\tprivate void processEvents()''',
'''\t\tsynchronized (eventLock)\n\t\t{\n\t\t\tinputEvents.add(r);\n\t\t\trg35xxR13EInputEnqueueSeq++;\n\t\t\trg35xxR13ELog("DISPLAY_ENQUEUE_INPUT", rg35xxR13EInputEnqueueSeq, inputEvents.size());\n\t\t\teventLock.notifyAll();\n\t\t}\n\t}\n\n\tprivate void processEvents()''','display enqueue')
D=once(D,
'''\t\t\t\tif (inputTask != null) { inputTask.run(); }\n\n\t\t\t\tinputCount--;''',
'''\t\t\t\tif (inputTask != null)\n\t\t\t\t{\n\t\t\t\t\trg35xxR13EInputDispatchSeq++;\n\t\t\t\t\trg35xxR13ELog("DISPLAY_DISPATCH_INPUT_BEGIN", rg35xxR13EInputDispatchSeq, inputCount);\n\t\t\t\t\tinputTask.run();\n\t\t\t\t\trg35xxR13ELog("DISPLAY_DISPATCH_INPUT_DONE", rg35xxR13EInputDispatchSeq, inputCount);\n\t\t\t\t}\n\n\t\t\t\tinputCount--;''','display dispatch input')
D=once(D,
'''\t\t\t// Service paints, then serial calls\n\t\t\tif (pendingPaint != null) { pendingPaint.run(); }''',
'''\t\t\t// Service paints, then serial calls\n\t\t\tif (pendingPaint != null)\n\t\t\t{\n\t\t\t\trg35xxR13EPaintDispatchSeq++;\n\t\t\t\trg35xxR13ELog("DISPLAY_PAINT_BEGIN", rg35xxR13EPaintDispatchSeq, 0);\n\t\t\t\tpendingPaint.run();\n\t\t\t\trg35xxR13ELog("DISPLAY_PAINT_DONE", rg35xxR13EPaintDispatchSeq, 0);\n\t\t\t}''','display paint')
D=once(D,
'''\tpublic void setCurrent(final Displayable next)\n\t{\n\t\tRunnable runnable = new Runnable()''',
'''\tpublic void setCurrent(final Displayable next)\n\t{\n\t\trg35xxR13ESetCurrentSeq++;\n\t\trg35xxR13ELog("SETCURRENT_REQUEST", rg35xxR13ESetCurrentSeq, next == null ? 0 : 1);\n\t\tRunnable runnable = new Runnable()''','setcurrent request')
D=once(D,
'''\t\t\tpublic void run()\n\t\t\t{\n\t\t\t\tDisplayable prev = current;''',
'''\t\t\tpublic void run()\n\t\t\t{\n\t\t\t\trg35xxR13ELog("SETCURRENT_RUN_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\tDisplayable prev = current;''','setcurrent run')
D=once(D,
'''\t\t\t\tMobile.log(Mobile.LOG_DEBUG, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "Set Current "+current.width+", "+current.height);\n\t\t\t}\n\t\t};''',
'''\t\t\t\tMobile.log(Mobile.LOG_DEBUG, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "Set Current "+current.width+", "+current.height);\n\t\t\t\trg35xxR13ELog("SETCURRENT_RUN_DONE", rg35xxR13ESetCurrentSeq, current == null ? 0 : 1);\n\t\t\t}\n\t\t};''','setcurrent done')

for name,s in [('Libretro',L),('MobilePlatform',M),('Display',D)]:
    if 'RG35XX-R13E-EVENT' not in s: raise SystemExit('R13E marker missing in '+name)
if (L,M,D)==orig: raise SystemExit('R13E no mutation')
lib.write_text(L,encoding='utf-8',newline='\n'); mp.write_text(M,encoding='utf-8',newline='\n'); disp.write_text(D,encoding='utf-8',newline='\n')
print('VC7R22-R1.3E_MIDLET_EVENT_TRACE=PASS')
print('TRACE_POLICY=FIRST_16_THEN_EVERY_120')
print('AUDIO_VIDEO_TRANSPARENCY_SEMANTICS=UNCHANGED')
