#!/usr/bin/env python3
import pathlib, sys

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

old_wait = """					// Wait for a whole second before forcefully repainting
					// below. Should be way more than enough time for the EDT
					// to dispatch non-deadlocked paints on any modern system.
					rg35xxR13HLog("SERVICE_WAIT_BEGIN", rg35xxR13HLocalService, 1);
					paintLock.wait(1000);
					rg35xxR13HLog("SERVICE_WAIT_WAKE", rg35xxR13HLocalService, needsRepaint ? 1 : 0);

					// If it timed out and still needs repaint, force a repaint
					// to occur as if it this was called from the EDT in order
					// to rescue any stalled frames.
					if (needsRepaint && isShown())
					{
						repaintRequest();
						break;
					}
"""
new_wait = """					// Wait for a whole second before considering the rescue path.
					// A normal paint completion increments generation before notify.
					// If a newer repaint was queued while that paint was finishing,
					// serviceRepaints must keep waiting instead of stealing paint()
					// onto the caller thread.
					long rg35xxB4GenBefore = rg35xxB4PaintCompletionGeneration;
					rg35xxR13HLog("SERVICE_WAIT_BEGIN", rg35xxR13HLocalService, 1);
					paintLock.wait(1000);
					long rg35xxB4GenAfter = rg35xxB4PaintCompletionGeneration;
					boolean rg35xxB4CompletionObserved = (rg35xxB4GenAfter != rg35xxB4GenBefore);
					rg35xxR13HLog("SERVICE_WAIT_WAKE", rg35xxR13HLocalService, needsRepaint ? 1 : 0);
					rg35xxB4ServiceSerialLog("WAIT_WAKE", rg35xxR13HLocalService,
						rg35xxB4GenBefore, rg35xxB4GenAfter,
						rg35xxB4PaintCallbackActive, needsRepaint);

					if (needsRepaint && isShown())
					{
						if (rg35xxB4CompletionObserved)
						{
							rg35xxB4ServiceSerialLog("SUPPRESS_AFTER_COMPLETION", rg35xxR13HLocalService,
								rg35xxB4GenBefore, rg35xxB4GenAfter,
								rg35xxB4PaintCallbackActive, needsRepaint);
							continue;
						}
						if (rg35xxB4PaintCallbackActive)
						{
							rg35xxB4ServiceSerialLog("SUPPRESS_WHILE_PAINT_ACTIVE", rg35xxR13HLocalService,
								rg35xxB4GenBefore, rg35xxB4GenAfter, true, needsRepaint);
							continue;
						}

						// No paint completed during the wait and no paint callback is
						// active: preserve the upstream one-second rescue fallback.
						rg35xxB4ServiceSerialLog("FORCE_FALLBACK", rg35xxR13HLocalService,
							rg35xxB4GenBefore, rg35xxB4GenAfter, false, needsRepaint);
						repaintRequest();
						break;
					}
"""
once(old_wait, new_wait, "service wait decision")

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
