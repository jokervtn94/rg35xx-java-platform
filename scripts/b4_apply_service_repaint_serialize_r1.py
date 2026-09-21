#!/usr/bin/env python3
import pathlib, re, sys

if len(sys.argv) != 2:
    raise SystemExit("usage: b4_apply_service_repaint_serialize_r1.py <Canvas.java>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s

if "RG35XX-B4-SERVICE-SERIAL" in s:
    raise SystemExit("B4 SERVICE SERIAL R1 FAIL already applied")

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("B4 SERVICE SERIAL R1 FAIL %s count=%d" % (label, n))
    s = s.replace(old, new, 1)

anchor = """	private static long rg35xxR13HRepaintSeq = 0;
"""
insert = """	private static long rg35xxR13HRepaintSeq = 0;
	private long rg35xxB4PaintCompletionGeneration = 0L;
	private boolean rg35xxB4PaintCallbackActive = false;

	private static void rg35xxB4ServiceSerialLog(String stage, long seq,
		long genBefore, long genAfter, boolean active, boolean needs)
	{
		if(rg35xxR13HTrace(seq))
		{
			System.err.println("RG35XX-B4-SERVICE-SERIAL stage=" + stage
				+ " seq=" + seq
				+ " genBefore=" + genBefore
				+ " genAfter=" + genAfter
				+ " completionObserved=" + (genAfter != genBefore)
				+ " paintActive=" + active
				+ " needsRepaint=" + needs
				+ " thread=" + Thread.currentThread().getName());
		}
	}
"""
once(anchor, insert, "state insertion")

old_try = """		try
		{
			rg35xxR13HLog("PAINT_CALLBACK_BEGIN", rg35xxR13HLocalRepaint, 0);
"""
new_try = """		synchronized (paintLock)
		{
			rg35xxB4PaintCallbackActive = true;
		}
		try
		{
			rg35xxR13HLog("PAINT_CALLBACK_BEGIN", rg35xxR13HLocalRepaint, 0);
"""
once(old_try, new_try, "paint active begin")

old_finally = """		finally
		{
			// Unblock any threads waiting in serviceRepaints()
			synchronized (paintLock)
			{
				paintLock.notifyAll();
			}
		}
"""
new_finally = """		finally
		{
			// Unblock any threads waiting in serviceRepaints().
			// Publish completion before notify so a waiter can distinguish a real
			// paint-completion wake from timeout/spurious wake.
			synchronized (paintLock)
			{
				rg35xxB4PaintCallbackActive = false;
				rg35xxB4PaintCompletionGeneration++;
				if(rg35xxB4PaintCompletionGeneration <= 0L)
					rg35xxB4PaintCompletionGeneration = 1L;
				paintLock.notifyAll();
			}
		}
"""
once(old_finally, new_finally, "paint completion generation")

pat = re.compile(
    r'(?s)(?P<indent>\\s*)rg35xxR13HLog\\("SERVICE_WAIT_BEGIN", rg35xxR13HLocalService, 1\\);'
    r'\\s*paintLock\\.wait\\(1000\\);'
    r'\\s*rg35xxR13HLog\\("SERVICE_WAIT_WAKE", rg35xxR13HLocalService, needsRepaint \\? 1 : 0\\);'
    r'\\s*// If it timed out and still needs repaint, force a repaint'
    r'.*?if \\(needsRepaint && isShown\\(\\)\\)'
    r'\\s*\\{\\s*repaintRequest\\(\\);\\s*break;\\s*\\}'
)
m = list(pat.finditer(s))
if len(m) != 1:
    raise SystemExit("B4 SERVICE SERIAL R1 FAIL service wait decision count=%d" % len(m))

new_wait = """\t\t\t\t\t// Wait for a whole second before considering the rescue path.
\t\t\t\t\t// A normal paint completion increments generation before notify.
\t\t\t\t\t// If a newer repaint was queued while that paint was finishing,
\t\t\t\t\t// serviceRepaints must keep waiting instead of stealing paint()
\t\t\t\t\t// onto the caller thread.
\t\t\t\t\tlong rg35xxB4GenBefore = rg35xxB4PaintCompletionGeneration;
\t\t\t\t\trg35xxR13HLog("SERVICE_WAIT_BEGIN", rg35xxR13HLocalService, 1);
\t\t\t\t\tpaintLock.wait(1000);
\t\t\t\t\tlong rg35xxB4GenAfter = rg35xxB4PaintCompletionGeneration;
\t\t\t\t\tboolean rg35xxB4CompletionObserved = (rg35xxB4GenAfter != rg35xxB4GenBefore);
\t\t\t\t\trg35xxR13HLog("SERVICE_WAIT_WAKE", rg35xxR13HLocalService, needsRepaint ? 1 : 0);
\t\t\t\t\trg35xxB4ServiceSerialLog("WAIT_WAKE", rg35xxR13HLocalService,
\t\t\t\t\t\trg35xxB4GenBefore, rg35xxB4GenAfter,
\t\t\t\t\t\trg35xxB4PaintCallbackActive, needsRepaint);

\t\t\t\t\tif (needsRepaint && isShown())
\t\t\t\t\t{
\t\t\t\t\t\tif (rg35xxB4CompletionObserved)
\t\t\t\t\t\t{
\t\t\t\t\t\t\trg35xxB4ServiceSerialLog("SUPPRESS_AFTER_COMPLETION", rg35xxR13HLocalService,
\t\t\t\t\t\t\t\trg35xxB4GenBefore, rg35xxB4GenAfter,
\t\t\t\t\t\t\t\trg35xxB4PaintCallbackActive, needsRepaint);
\t\t\t\t\t\t\tcontinue;
\t\t\t\t\t\t}
\t\t\t\t\t\tif (rg35xxB4PaintCallbackActive)
\t\t\t\t\t\t{
\t\t\t\t\t\t\trg35xxB4ServiceSerialLog("SUPPRESS_WHILE_PAINT_ACTIVE", rg35xxR13HLocalService,
\t\t\t\t\t\t\t\trg35xxB4GenBefore, rg35xxB4GenAfter, true, needsRepaint);
\t\t\t\t\t\t\tcontinue;
\t\t\t\t\t\t}

\t\t\t\t\t\t// No paint completed during the wait and no paint callback is
\t\t\t\t\t\t// active: preserve the upstream one-second rescue fallback.
\t\t\t\t\t\trg35xxB4ServiceSerialLog("FORCE_FALLBACK", rg35xxR13HLocalService,
\t\t\t\t\t\t\trg35xxB4GenBefore, rg35xxB4GenAfter, false, needsRepaint);
\t\t\t\t\t\trepaintRequest();
\t\t\t\t\t\tbreak;
\t\t\t\t\t}
"""
s = s[:m[0].start()] + new_wait + s[m[0].end():]

for tok in (
    "RG35XX-B4-SERVICE-SERIAL",
    "SUPPRESS_AFTER_COMPLETION",
    "SUPPRESS_WHILE_PAINT_ACTIVE",
    "FORCE_FALLBACK",
    "rg35xxB4PaintCompletionGeneration",
    "rg35xxB4PaintCallbackActive",
):
    if tok not in s:
        raise SystemExit("B4 SERVICE SERIAL R1 FAIL missing token: " + tok)

if s == orig:
    raise SystemExit("B4 SERVICE SERIAL R1 FAIL no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("B4_DRAGON_SERVICE_REPAINT_SERIALIZE_R1_PATCH=PASS")
print("PRIMARY_VARIABLE=SERVICEREPAINTS_COMPLETION_WAKE_AND_ACTIVE_PAINT_SERIALIZATION")
print("NORMAL_EDT_REPAINT_PATH=UNCHANGED")
print("ONE_SECOND_FALLBACK=PRESERVED_WHEN_NO_COMPLETION_AND_NO_ACTIVE_PAINT")
