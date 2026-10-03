#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a6-rg35xx-parent-trace-r4t.py <repo-root>')
root = Path(sys.argv[1]).resolve()

core = root / 'adapter/java/org/recompile/rg35xx/RG35XXCore2D.java'
launcher = root / 'adapter/java/org/recompile/rg35xx/RG35XXLauncher.java'

ct = core.read_text(encoding='utf-8')
old = '        if (interlace == 1) return decodeAdam7(width, height, bitDepth, colorType, palette, transparency, idat.toByteArray());\n'
new = '''        if (interlace == 1) {\n            boolean trace = Boolean.getBoolean("rg35xx.a6.parenttrace");\n            if (trace) {\n                System.out.println("RG35XX_A6_TRACE_ADAM7_BEGIN=" + width + "x" + height + ":ct" + colorType + ":bd" + bitDepth);\n                System.out.flush();\n            }\n            RawImage decoded = decodeAdam7(width, height, bitDepth, colorType, palette, transparency, idat.toByteArray());\n            if (trace) {\n                System.out.println("RG35XX_A6_TRACE_ADAM7_RETURN=" + decoded.width + "x" + decoded.height);\n                System.out.flush();\n            }\n            return decoded;\n        }\n'''
if ct.count(old) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL core Adam7 anchor count=%d' % ct.count(old))
core.write_text(ct.replace(old, new, 1), encoding='utf-8')

lt = launcher.read_text(encoding='utf-8')

old = '    private static final int INPUT_POLL_MS = 10;\n'
new = '''    private static final int INPUT_POLL_MS = 10;\n    private static final String PARENT_TRACE_PROPERTY = "rg35xx.a6.parenttrace";\n'''
if lt.count(old) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL launcher constant anchor')
lt = lt.replace(old, new, 1)

old = '''        platform.runJar();\n        input.start();\n'''
new = '''        startParentTraceWatchdog();\n        platform.runJar();\n        input.start();\n'''
if lt.count(old) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL launcher runJar anchor')
lt = lt.replace(old, new, 1)

anchor = '    private static final class FramePresenter implements Runnable {\n'
helper = '''    private static boolean parentTraceEnabled() {\n        return Boolean.getBoolean(PARENT_TRACE_PROPERTY);\n    }\n\n    private static void parentTrace(String message) {\n        if (!parentTraceEnabled()) return;\n        System.out.println(message);\n        System.out.flush();\n    }\n\n    private static void parentTraceWatchdogLoop() {\n        long tick = 0;\n        while (true) {\n            tick++;\n            Runtime runtime = Runtime.getRuntime();\n            parentTrace("RG35XX_A6_TRACE_WATCHDOG=" + tick +\n                    " free=" + runtime.freeMemory() +\n                    " total=" + runtime.totalMemory());\n            try {\n                Thread.sleep(2000);\n            } catch (InterruptedException e) {\n                // keep diagnostic heartbeat alive\n            }\n        }\n    }\n\n    private static void parentTraceFrame(long frames, int rc, int width, int height) {\n        parentTrace("RG35XX_A6_TRACE_FRAME=" + frames + " rc=" + rc +\n                " source=" + width + "x" + height);\n    }\n\n    private static void parentTraceInput(long polls) {\n        parentTrace("RG35XX_A6_TRACE_INPUT_POLL=" + polls);\n    }\n\n    private static void startParentTraceWatchdog() {\n        if (!parentTraceEnabled()) return;\n        parentTrace("RG35XX_A6_PARENT_TRACE=ENABLED");\n        Thread watchdog = new Thread(new Runnable() {\n            public void run() {\n                parentTraceWatchdogLoop();\n            }\n        }, "rg35xx-a6-watchdog");\n        watchdog.setDaemon(true);\n        watchdog.start();\n    }\n\n'''
if lt.count(anchor) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL FramePresenter anchor')
lt = lt.replace(anchor, helper + anchor, 1)

old = '''        private int lastError = Integer.MIN_VALUE;\n        private boolean rawInvokeErrorLogged;\n'''
new = '''        private int lastError = Integer.MIN_VALUE;\n        private boolean rawInvokeErrorLogged;\n        private long traceFrames;\n'''
if lt.count(old) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL presenter fields anchor')
lt = lt.replace(old, new, 1)

old = '''                    lastError = rc;\n                    return;\n'''
new = '''                    lastError = rc;\n                    traceFrames++;\n                    if (parentTraceEnabled() && (traceFrames == 1 || (traceFrames % 60) == 0)) {\n                        parentTraceFrame(traceFrames, rc, width, height);\n                    }\n                    return;\n'''
if lt.count(old) < 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL raw presenter return anchor')
lt = lt.replace(old, new, 1)

old = '''        private volatile boolean running;\n        private Thread thread;\n'''
new = '''        private volatile boolean running;\n        private Thread thread;\n        private long tracePolls;\n'''
if lt.count(old) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL input fields anchor')
lt = lt.replace(old, new, 1)

old = '''                dispatcher.poll(System.currentTimeMillis());\n                try {\n'''
new = '''                dispatcher.poll(System.currentTimeMillis());\n                tracePolls++;\n                if (parentTraceEnabled() && (tracePolls == 1 || (tracePolls % 200) == 0)) {\n                    parentTraceInput(tracePolls);\n                }\n                try {\n'''
if lt.count(old) != 1:
    raise SystemExit('A6_PARENT_TRACE_STAGE_FAIL input poll anchor')
lt = lt.replace(old, new, 1)

launcher.write_text(lt, encoding='utf-8')
print('A6_PARENT_TRACE_R4T_STAGE=PASS')
print('A6_PARENT_TRACE_R4T_SCOPE=ADAM7_BEGIN_RETURN+WATCHDOG+FRAME_HEARTBEAT+INPUT_HEARTBEAT')
print('A6_PARENT_TRACE_R4T_SEMANTIC_CHANGE=NO')
