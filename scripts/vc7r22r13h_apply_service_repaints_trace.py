#!/usr/bin/env python3
import pathlib,re,sys
if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r22r13h_apply_service_repaints_trace.py <Canvas.java>')
p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

def once(s,old,new,label):
    n=s.count(old)
    if n!=1: raise SystemExit('R13H %s anchor count=%d'%(label,n))
    return s.replace(old,new,1)

# Trace-only checkpoint. No paint/serviceRepaints semantics are changed.
s=once(s,
'''\tprotected int paintX, paintY, paintW, paintH;\n''',
'''\tprotected int paintX, paintY, paintW, paintH;\n\tprivate static long rg35xxR13HServiceSeq = 0;\n\tprivate static long rg35xxR13HRepaintSeq = 0;\n\tprivate static boolean rg35xxR13HTrace(long n) { return n <= 32 || (n % 120L) == 0L; }\n\tprivate static void rg35xxR13HLog(String stage, long n, int aux)\n\t{\n\t\tif(rg35xxR13HTrace(n)) System.err.println("RG35XX-R13H-LOOP stage="+stage+" seq="+n+" aux="+aux+" thread="+Thread.currentThread().getName());\n\t}\n''','state')

s=once(s,
'''\tpublic void repaintRequest()\n\t{\n''',
'''\tpublic void repaintRequest()\n\t{\n\t\trg35xxR13HRepaintSeq++;\n\t\tlong rg35xxR13HLocalRepaint = rg35xxR13HRepaintSeq;\n\t\trg35xxR13HLog("REPAINT_REQUEST_BEGIN", rg35xxR13HLocalRepaint, needsRepaint ? 1 : 0);\n''','repaint begin')

s=once(s,
'''\t\ttry\n\t\t{\n\t\t\tgraphics.reset(renderX, renderY, renderW, renderH);\n\t\t\tpaint(graphics);\n\t\t}\n''',
'''\t\ttry\n\t\t{\n\t\t\trg35xxR13HLog("PAINT_CALLBACK_BEGIN", rg35xxR13HLocalRepaint, 0);\n\t\t\tgraphics.reset(renderX, renderY, renderW, renderH);\n\t\t\tpaint(graphics);\n\t\t\trg35xxR13HLog("PAINT_CALLBACK_DONE", rg35xxR13HLocalRepaint, 0);\n\t\t}\n''','paint callback')

s=once(s,
'''\t\tMobile.getPlatform().flushGraphics(platformImage, renderX, renderY, renderW, renderH);\n''',
'''\t\trg35xxR13HLog("REPAINT_FLUSH_BEGIN", rg35xxR13HLocalRepaint, 0);\n\t\tMobile.getPlatform().flushGraphics(platformImage, renderX, renderY, renderW, renderH);\n\t\trg35xxR13HLog("REPAINT_FLUSH_DONE", rg35xxR13HLocalRepaint, 0);\n\t\trg35xxR13HLog("REPAINT_REQUEST_DONE", rg35xxR13HLocalRepaint, 0);\n''','repaint flush')

s=once(s,
'''\tpublic void serviceRepaints()\n\t{\n\t\tif (!needsRepaint || !isShown()) { return; }\n''',
'''\tpublic void serviceRepaints()\n\t{\n\t\trg35xxR13HServiceSeq++;\n\t\tlong rg35xxR13HLocalService = rg35xxR13HServiceSeq;\n\t\trg35xxR13HLog("SERVICE_ENTER", rg35xxR13HLocalService, needsRepaint ? 1 : 0);\n\t\tif (!needsRepaint || !isShown())\n\t\t{\n\t\t\trg35xxR13HLog("SERVICE_EARLY_RETURN", rg35xxR13HLocalService, needsRepaint ? 1 : 0);\n\t\t\treturn;\n\t\t}\n''','service begin')

s=once(s,
'''\t\tif (Mobile.getDisplay().isEventThread())\n\t\t{\n\t\t\trepaintRequest();\n\t\t\treturn;\n\t\t}\n\n\t\tsynchronized (paintLock)\n\t\t{\n''',
'''\t\tif (Mobile.getDisplay().isEventThread())\n\t\t{\n\t\t\trg35xxR13HLog("SERVICE_EVENTTHREAD_REPAINT_BEGIN", rg35xxR13HLocalService, 1);\n\t\t\trepaintRequest();\n\t\t\trg35xxR13HLog("SERVICE_EVENTTHREAD_REPAINT_DONE", rg35xxR13HLocalService, 1);\n\t\t\treturn;\n\t\t}\n\n\t\trg35xxR13HLog("SERVICE_LOCK_BEGIN", rg35xxR13HLocalService, 0);\n\t\tsynchronized (paintLock)\n\t\t{\n\t\t\trg35xxR13HLog("SERVICE_LOCK_ACQUIRED", rg35xxR13HLocalService, needsRepaint ? 1 : 0);\n''','service lock')

# The pinned Canvas waits one second before force repaint. Surround the wait so a
# permanently missing WAKE marker identifies a blocked caller/paintLock path.
pat=r'(?m)^(\s*)paintLock\.wait\(1000\);\s*$'
m=re.findall(pat,s)
if len(m)!=1: raise SystemExit('R13H wait anchor count=%d'%len(m))
indent=m[0]
s=re.sub(pat,
    indent+'rg35xxR13HLog("SERVICE_WAIT_BEGIN", rg35xxR13HLocalService, 1);\n'+
    indent+'paintLock.wait(1000);\n'+
    indent+'rg35xxR13HLog("SERVICE_WAIT_WAKE", rg35xxR13HLocalService, needsRepaint ? 1 : 0);',
    s,count=1)

# Log the transition out of the while loop without altering the existing fallback.
pat2=r'(?s)(\t\t\tsynchronized \(paintLock\)\n\t\t\{.*?\t\t\twhile \(needsRepaint\).*?\t\t\t\}\n)(\t\t\})'
# Avoid structural rewrite if upstream formatting differs; WAIT markers plus lock markers
# are sufficient for diagnosis. Only require the primary marker set below.

for tok in ('RG35XX-R13H-LOOP','REPAINT_REQUEST_BEGIN','PAINT_CALLBACK_BEGIN','PAINT_CALLBACK_DONE','REPAINT_FLUSH_BEGIN','REPAINT_FLUSH_DONE','SERVICE_ENTER','SERVICE_EVENTTHREAD_REPAINT_BEGIN','SERVICE_LOCK_BEGIN','SERVICE_LOCK_ACQUIRED','SERVICE_WAIT_BEGIN','SERVICE_WAIT_WAKE'):
    if tok not in s: raise SystemExit('R13H marker missing '+tok)
if s==orig: raise SystemExit('R13H no mutation')
p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R22-R1.3H_SERVICE_REPAINTS_TRACE=PASS')
print('BEHAVIOR_CHANGE=NONE_TRACE_ONLY')
