#!/usr/bin/env python3
import pathlib,sys
if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r22r13c_apply_sparse_frame_trace.py <RG35XXGoldenFrameTransport.java>')
p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

# Add sparse sequence/trace helpers. First 8 frames are traced, then every 120th.
anchor='''    private Thread worker;\n\n    private int width;\n'''
insert='''    private Thread worker;\n    private long rg35xxTraceFrameSeq;\n\n    private boolean rg35xxTraceThisFrame(long seq)\n    {\n        return seq <= 8L || (seq % 120L) == 0L;\n    }\n\n    private void rg35xxTrace(long seq, String stage)\n    {\n        if(rg35xxTraceThisFrame(seq))\n            System.err.println("RG35XX-R13C-FRAME seq=" + seq + " stage=" + stage);\n    }\n\n    private int width;\n'''
if s.count(anchor)!=1: raise SystemExit('trace field anchor mismatch')
s=s.replace(anchor,insert,1)

# Thread a trace sequence into snapshotFrame / encodeAndWriteFrame without changing locking.
s=s.replace('''            if(snapshotFrame(sourceWidth, sourceHeight, sourceData, sourceLock, controlSnapshot))\n            {\n                synchronized(encodeLock)\n                {\n                    encodeAndWriteFrame(sourceWidth, sourceHeight, controlSnapshot);\n                }\n            }\n''','''            final long traceSeq = ++rg35xxTraceFrameSeq;\n            rg35xxTrace(traceSeq, "CONTROL_SNAPSHOT_BEGIN");\n            if(snapshotFrame(sourceWidth, sourceHeight, sourceData, sourceLock, controlSnapshot))\n            {\n                rg35xxTrace(traceSeq, "CONTROL_SNAPSHOT_DONE");\n                synchronized(encodeLock)\n                {\n                    encodeAndWriteFrame(sourceWidth, sourceHeight, controlSnapshot, traceSeq);\n                }\n            }\n''',1)

s=s.replace('''                if(snapshotFrame(w, h, data, lock, workerSnapshot))\n                {\n                    synchronized(encodeLock)\n                    {\n                        encodeAndWriteFrame(w, h, workerSnapshot);\n                    }\n                }\n''','''                final long traceSeq = ++rg35xxTraceFrameSeq;\n                rg35xxTrace(traceSeq, "WORKER_SNAPSHOT_BEGIN");\n                if(snapshotFrame(w, h, data, lock, workerSnapshot))\n                {\n                    rg35xxTrace(traceSeq, "WORKER_SNAPSHOT_DONE");\n                    synchronized(encodeLock)\n                    {\n                        encodeAndWriteFrame(w, h, workerSnapshot, traceSeq);\n                    }\n                }\n''',1)

s=s.replace('''    private void encodeAndWriteFrame(int w, int h, int[] snapshot) throws Exception\n    {\n        final int pixels = w * h;\n''','''    private void encodeAndWriteFrame(int w, int h, int[] snapshot, long traceSeq) throws Exception\n    {\n        final int pixels = w * h;\n        rg35xxTrace(traceSeq, "ENCODE_BEGIN");\n''',1)

s=s.replace('''        while(src < pixels) dst = put565(snapshot[src++], dst);\n\n        header[0] = (byte)0xFE;\n''','''        while(src < pixels) dst = put565(snapshot[src++], dst);\n        rg35xxTrace(traceSeq, "ENCODE_DONE");\n\n        header[0] = (byte)0xFE;\n''',1)

s=s.replace('''        synchronized(ipcOut)\n        {\n            ipcOut.write(header, 0, FRAME_HEADER_BYTES);\n            ipcOut.write(rgb565, 0, pixels * 2);\n            ipcOut.flush();\n            if(ipcOut.checkError())\n                System.err.println("RG35XX-VIDEO JAVA IPC write error");\n        }\n''','''        synchronized(ipcOut)\n        {\n            rg35xxTrace(traceSeq, "IPC_BEGIN");\n            ipcOut.write(header, 0, FRAME_HEADER_BYTES);\n            rg35xxTrace(traceSeq, "IPC_HEADER_DONE");\n            ipcOut.write(rgb565, 0, pixels * 2);\n            rg35xxTrace(traceSeq, "IPC_PAYLOAD_DONE");\n            ipcOut.flush();\n            rg35xxTrace(traceSeq, "IPC_FLUSH_DONE");\n            if(ipcOut.checkError())\n                System.err.println("RG35XX-VIDEO JAVA IPC write error");\n        }\n''',1)

# Gates: R1.2a structure must remain intact.
for tok in ('workerSnapshot','controlSnapshot','snapshotFrame(','encodeAndWriteFrame(','worker.setDaemon(true)','RG35XX-R13C-FRAME','IPC_FLUSH_DONE'):
    if tok not in s: raise SystemExit('R1.3C missing '+tok)
if 'sendFrameLocked(' in s: raise SystemExit('R1.3C stale sendFrameLocked survived')
if orig==s: raise SystemExit('R1.3C no mutation')
p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R22-R1.3C_SPARSE_FRAME_TRACE=PASS')
print('TRACE_POLICY=FIRST_8_THEN_EVERY_120')
print('TRACE_STAGES=SNAPSHOT,ENCODE,IPC_HEADER,IPC_PAYLOAD,IPC_FLUSH')
