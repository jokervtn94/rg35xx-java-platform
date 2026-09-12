#!/usr/bin/env python3
import pathlib,sys
if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r22r13f_apply_setcurrent_trace.py <Display.java>')
p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

def once(s,old,new,label):
    n=s.count(old)
    if n!=1: raise SystemExit('R13F %s anchor count=%d'%(label,n))
    return s.replace(old,new,1)

# Fine-grained localization of the second setCurrent() runnable. Keep behavior unchanged.
s=once(s,
'''\t\t\t\trg35xxR13ELog("SETCURRENT_RUN_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\tDisplayable prev = current;''',
'''\t\t\t\trg35xxR13ELog("SETCURRENT_RUN_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\trg35xxR13ELog("SC_PREV_READ_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\tDisplayable prev = current;\n\t\t\t\trg35xxR13ELog("SC_PREV_READ_DONE", rg35xxR13ESetCurrentSeq, prev == null ? 0 : 1);''','prev')

s=once(s,
'''\t\t\t\ttry\n\t\t\t\t{\n\t\t\t\t\tif(next instanceof Alert) { ((Alert) next).setNextScreen(current); }\n\n\t\t\t\t\t// Call upon showNotify right before the new canvas is made visible\n\t\t\t\t\tif (next instanceof Canvas) { ((Canvas) next).showNotify(); }\n\t\t\t\t}''',
'''\t\t\t\trg35xxR13ELog("SC_PREP_BEGIN", rg35xxR13ESetCurrentSeq, next instanceof Canvas ? 1 : 0);\n\t\t\t\ttry\n\t\t\t\t{\n\t\t\t\t\tif(next instanceof Alert) { ((Alert) next).setNextScreen(current); }\n\n\t\t\t\t\t// Call upon showNotify right before the new canvas is made visible\n\t\t\t\t\tif (next instanceof Canvas)\n\t\t\t\t\t{\n\t\t\t\t\t\trg35xxR13ELog("SC_SHOW_BEGIN", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\t\t((Canvas) next).showNotify();\n\t\t\t\t\t\trg35xxR13ELog("SC_SHOW_DONE", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\t}\n\t\t\t\t}''','prep')

s=once(s,
'''\t\t\t\tcatch (Exception e)\n\t\t\t\t{\n\t\t\t\t\tMobile.log(Mobile.LOG_ERROR, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "SetCurrent Alert/Canvas preparation block failed: " + e.getMessage());\n\t\t\t\t\te.printStackTrace();\n\t\t\t\t}\n\n\t\t\t\t// displayable setup and hideNotify''',
'''\t\t\t\tcatch (Exception e)\n\t\t\t\t{\n\t\t\t\t\tMobile.log(Mobile.LOG_ERROR, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "SetCurrent Alert/Canvas preparation block failed: " + e.getMessage());\n\t\t\t\t\te.printStackTrace();\n\t\t\t\t}\n\t\t\t\trg35xxR13ELog("SC_PREP_DONE", rg35xxR13ESetCurrentSeq, 0);\n\n\t\t\t\t// displayable setup and hideNotify''','prepdone')

s=once(s,
'''\t\t\t\ttry\n\t\t\t\t{\n\t\t\t\t\t// Make the new displayable effective\n\t\t\t\t\tcurrent = next;\n\n\t\t\t\t\t// Call upon hideNotify right after removing the previous canvas from the display\n\t\t\t\t\tif (prev instanceof Canvas) { ((Canvas) prev).hideNotify(); }\n\t\t\t\t}''',
'''\t\t\t\trg35xxR13ELog("SC_ASSIGN_BLOCK_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\ttry\n\t\t\t\t{\n\t\t\t\t\t// Make the new displayable effective\n\t\t\t\t\trg35xxR13ELog("SC_ASSIGN_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\t\tcurrent = next;\n\t\t\t\t\trg35xxR13ELog("SC_ASSIGN_DONE", rg35xxR13ESetCurrentSeq, 0);\n\n\t\t\t\t\t// Call upon hideNotify right after removing the previous canvas from the display\n\t\t\t\t\tif (prev instanceof Canvas)\n\t\t\t\t\t{\n\t\t\t\t\t\trg35xxR13ELog("SC_HIDE_BEGIN", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\t\t((Canvas) prev).hideNotify();\n\t\t\t\t\t\trg35xxR13ELog("SC_HIDE_DONE", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\t}\n\t\t\t\t}''','assign')

s=once(s,
'''\t\t\t\tcatch (Exception e)\n\t\t\t\t{\n\t\t\t\t\tMobile.log(Mobile.LOG_ERROR, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "SetCurrent displayable setup and hideNotify block failed: " + e.getMessage());\n\t\t\t\t\te.printStackTrace();\n\t\t\t\t}\n\n\t\t\t\t// Paint displayable block''',
'''\t\t\t\tcatch (Exception e)\n\t\t\t\t{\n\t\t\t\t\tMobile.log(Mobile.LOG_ERROR, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "SetCurrent displayable setup and hideNotify block failed: " + e.getMessage());\n\t\t\t\t\te.printStackTrace();\n\t\t\t\t}\n\t\t\t\trg35xxR13ELog("SC_ASSIGN_BLOCK_DONE", rg35xxR13ESetCurrentSeq, 0);\n\n\t\t\t\t// Paint displayable block''','assigndone')

s=once(s,
'''\t\t\t\ttry\n\t\t\t\t{\n\t\t\t\t\t// Displayables other than canvas have drawing dictated''',
'''\t\t\t\trg35xxR13ELog("SC_PAINT_BLOCK_BEGIN", rg35xxR13ESetCurrentSeq, current instanceof Canvas ? 1 : 0);\n\t\t\t\ttry\n\t\t\t\t{\n\t\t\t\t\t// Displayables other than canvas have drawing dictated''','paintbegin')

s=once(s,
'''\t\t\t\t\tif(!(current instanceof Canvas)) { current.notifySetCurrent(); }''',
'''\t\t\t\t\tif(!(current instanceof Canvas))\n\t\t\t\t\t{\n\t\t\t\t\t\trg35xxR13ELog("SC_NOTIFYSETCURRENT_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\t\t\tcurrent.notifySetCurrent();\n\t\t\t\t\t\trg35xxR13ELog("SC_NOTIFYSETCURRENT_DONE", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\t\t}''','notify')

s=once(s,
'''\t\t\t\t\t\tif(current instanceof Canvas)\n\t\t\t\t\t\t\t{ ((Canvas) current).repaint(0, 0, current.getWidth(), current.getHeight()); }''',
'''\t\t\t\t\t\tif(current instanceof Canvas)\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\trg35xxR13ELog("SC_REPAINT_BEGIN", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\t\t\t((Canvas) current).repaint(0, 0, current.getWidth(), current.getHeight());\n\t\t\t\t\t\t\trg35xxR13ELog("SC_REPAINT_DONE", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\t\t}''','repaint')

s=once(s,
'''\t\t\t\t\t\tMobile.getPlatform().flushGraphics(current.platformImage,\n\t\t\t\t\t\t\t0, 0, current.getWidth(), current.getHeight()\n\t\t\t\t\t\t);''',
'''\t\t\t\t\t\trg35xxR13ELog("SC_FLUSH_BEGIN", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\t\t\tMobile.getPlatform().flushGraphics(current.platformImage,\n\t\t\t\t\t\t\t0, 0, current.getWidth(), current.getHeight()\n\t\t\t\t\t\t);\n\t\t\t\t\t\trg35xxR13ELog("SC_FLUSH_DONE", rg35xxR13ESetCurrentSeq, 0);''','flush')

s=once(s,
'''\t\t\t\tcatch (Exception e)\n\t\t\t\t{\n\t\t\t\t\tMobile.log(Mobile.LOG_ERROR, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "SetCurrent paint block failed: " + e.getMessage());\n\t\t\t\t\te.printStackTrace();\n\t\t\t\t}\n\n\t\t\t\tMobile.log(Mobile.LOG_DEBUG,''',
'''\t\t\t\tcatch (Exception e)\n\t\t\t\t{\n\t\t\t\t\tMobile.log(Mobile.LOG_ERROR, Display.class.getPackage().getName() + "." + Display.class.getSimpleName() + ": " + "SetCurrent paint block failed: " + e.getMessage());\n\t\t\t\t\te.printStackTrace();\n\t\t\t\t}\n\t\t\t\trg35xxR13ELog("SC_PAINT_BLOCK_DONE", rg35xxR13ESetCurrentSeq, 0);\n\n\t\t\t\tMobile.log(Mobile.LOG_DEBUG,''','paintdone')

if s==orig: raise SystemExit('R13F no mutation')
for tok in ('SC_PREP_BEGIN','SC_SHOW_BEGIN','SC_SHOW_DONE','SC_ASSIGN_BEGIN','SC_ASSIGN_DONE','SC_HIDE_BEGIN','SC_HIDE_DONE','SC_PAINT_BLOCK_BEGIN','SC_NOTIFYSETCURRENT_BEGIN','SC_REPAINT_BEGIN','SC_FLUSH_BEGIN','SC_PAINT_BLOCK_DONE'):
    if tok not in s: raise SystemExit('R13F marker missing '+tok)
p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R22-R1.3F_SETCURRENT_TRACE=PASS')
print('BEHAVIOR_CHANGE=NONE_TRACE_ONLY')
