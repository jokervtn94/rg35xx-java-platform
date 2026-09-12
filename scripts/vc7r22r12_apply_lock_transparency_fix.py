#!/usr/bin/env python3
import pathlib,re,sys
if len(sys.argv)!=3:
    raise SystemExit('usage: vc7r22r12_apply_lock_transparency_fix.py <PlatformImage.java> <RG35XXGoldenFrameTransport.java>')
pi=pathlib.Path(sys.argv[1]); ft=pathlib.Path(sys.argv[2])
i=pi.read_text(encoding='utf-8'); f=ft.read_text(encoding='utf-8')
orig_i,orig_f=i,f

# ---- Transparency: ColorModel.hasAlpha() is not enough on GNU Classpath. ----
old='''\t\tfinal boolean sourceHasAlpha=image.getColorModel().hasAlpha();\n\t\tfinal boolean hasTrns=rg35xxVC7R20PngTransparency.get()!=null;\n\t\tfinal int[] pixels=image.getRGB(0,0,w,h,null,0,w);\n\t\tfinal int trnsChanged=rg35xxVC7R20ApplyPngTransparency(pixels);\n'''
new='''\t\tfinal boolean sourceHasAlpha=image.getColorModel().hasAlpha();\n\t\tfinal boolean hasTrns=rg35xxVC7R20PngTransparency.get()!=null;\n\t\tfinal int[] pixels=image.getRGB(0,0,w,h,null,0,w);\n\t\tboolean hasMeaningfulAlpha=false;\n\t\tfor(int ai=0;ai<pixels.length;ai++)\n\t\t{\n\t\t\tif(((pixels[ai]>>>24)&0xFF)!=0xFF) { hasMeaningfulAlpha=true; break; }\n\t\t}\n\t\tfinal int trnsChanged=rg35xxVC7R20ApplyPngTransparency(pixels);\n'''
if i.count(old)!=1: raise SystemExit('R1.2 transparency alpha anchor count=%d'%i.count(old))
i=i.replace(old,new,1)
i=i.replace('if(!sourceHasAlpha && !hasTrns)','if(!hasMeaningfulAlpha && !hasTrns)',1)
i=i.replace('''\t\t * 1. real alpha channel -> preserve decoder alpha;\n''','''\t\t * 1. meaningful per-pixel alpha -> preserve decoder alpha;\n''',1)

# Remove bounded transparency logs from runtime hot path after diagnosis.
i=re.sub(r'\n\t\tif\(changed>0 && rg35xxVC7R21WhiteKeyLogCount\+\+<16\)\n\t\t\tSystem\.err\.println\(\"RG35XX-VC7R21-LEGACY-WHITEKEY:.*?;\n', '\n', i, count=1, flags=re.S)
i=re.sub(r'\n\t\tif\(rg35xxVC7R20TrnsLogCount\+\+<16\)\n\t\t\tSystem\.err\.println\(\"RG35XX-VC7R20-PNG-TRNS:.*?;\n', '\n', i, count=1, flags=re.S)

# ---- Frame transport: structural lock fix FIRST. ----
f=f.replace('''    private final int[] argbSnapshot = new int[MAX_PIXELS];\n''','''    private final int[] workerSnapshot = new int[MAX_PIXELS];\n    private final int[] controlSnapshot = new int[MAX_PIXELS];\n''',1)

old_control='''        try\n        {\n            synchronized(encodeLock)\n            {\n                sendFrameLocked(sourceWidth, sourceHeight, sourceData, sourceLock);\n            }\n        }\n'''
new_control='''        try\n        {\n            if(snapshotFrame(sourceWidth, sourceHeight, sourceData, sourceLock, controlSnapshot))\n            {\n                synchronized(encodeLock)\n                {\n                    encodeAndWriteFrame(sourceWidth, sourceHeight, controlSnapshot);\n                }\n            }\n        }\n'''
if f.count(old_control)!=1: raise SystemExit('R1.2 control lock anchor count=%d'%f.count(old_control))
f=f.replace(old_control,new_control,1)

old_worker='''            try\n            {\n                synchronized(encodeLock)\n                {\n                    sendFrameLocked(w, h, data, lock);\n                }\n            }\n'''
new_worker='''            try\n            {\n                if(snapshotFrame(w, h, data, lock, workerSnapshot))\n                {\n                    synchronized(encodeLock)\n                    {\n                        encodeAndWriteFrame(w, h, workerSnapshot);\n                    }\n                }\n            }\n'''
if f.count(old_worker)!=1: raise SystemExit('R1.2 worker lock anchor count=%d'%f.count(old_worker))
f=f.replace(old_worker,new_worker,1)

pat=re.compile(r'    private void sendFrameLocked\(int w, int h, int\[\] data, Object lock\) throws Exception\n    \{.*?\n    \}\n\n    private int put565',re.S)
m=pat.search(f)
if not m: raise SystemExit('R1.2 sendFrameLocked method not found')
replacement='''    private boolean snapshotFrame(int w, int h, int[] data, Object lock, int[] snapshot)\n    {\n        final int pixels = w * h;\n        if(pixels <= 0 || pixels > MAX_PIXELS || data == null ||\n           data.length < pixels || snapshot == null || snapshot.length < pixels)\n        {\n            System.err.println("RG35XX-VIDEO JAVA invalid snapshot pixels=" + pixels);\n            return false;\n        }\n        /* Critical ordering rule: never hold encodeLock while waiting for the\n         * MIDlet/frontbuffer lock. Snapshot first, then serialize encode/write. */\n        synchronized(lock)\n        {\n            System.arraycopy(data, 0, snapshot, 0, pixels);\n        }\n        return true;\n    }\n\n    private void encodeAndWriteFrame(int w, int h, int[] snapshot) throws Exception\n    {\n        final int pixels = w * h;\n        int src = 0;\n        int dst = 0;\n        final int bulk = pixels & ~7;\n        while(src < bulk)\n        {\n            int p0 = snapshot[src++]; int p1 = snapshot[src++];\n            int p2 = snapshot[src++]; int p3 = snapshot[src++];\n            int p4 = snapshot[src++]; int p5 = snapshot[src++];\n            int p6 = snapshot[src++]; int p7 = snapshot[src++];\n            dst = put565(p0, dst); dst = put565(p1, dst);\n            dst = put565(p2, dst); dst = put565(p3, dst);\n            dst = put565(p4, dst); dst = put565(p5, dst);\n            dst = put565(p6, dst); dst = put565(p7, dst);\n        }\n        while(src < pixels) dst = put565(snapshot[src++], dst);\n\n        header[0] = (byte)0xFE;\n        header[1] = (byte)((w >> 8) & 0xFF); header[2] = (byte)(w & 0xFF);\n        header[3] = (byte)((h >> 8) & 0xFF); header[4] = (byte)(h & 0xFF);\n        header[5] = (byte)(Mobile.rotateDisplay / 90);\n        final int vibrationDuration = Mobile.vibrationDuration;\n        final int vibrationStrength = Mobile.vibrationStrength;\n        putInt32(header, 6, vibrationDuration);\n        putInt32(header, 10, vibrationStrength);\n        header[14] = Mobile.libretroRestartRequested;\n        header[15] = Mobile.libretroEncodingRequested;\n        Mobile.vibrationDuration = 0;\n\n        synchronized(ipcOut)\n        {\n            ipcOut.write(header, 0, FRAME_HEADER_BYTES);\n            ipcOut.write(rgb565, 0, pixels * 2);\n            ipcOut.flush();\n            if(ipcOut.checkError())\n                System.err.println("RG35XX-VIDEO JAVA IPC write error");\n        }\n    }\n\n    private int put565'''
f=f[:m.start()]+replacement+f[m.end():]
f=f.replace('worker.setDaemon(false);','worker.setDaemon(true);',1)

# ---- Strip VC7R18 diagnostic CALLS only after structural patching. ----
# Do not use DOTALL regex here: some calls are multiline and regex can consume
# neighboring control-flow. Parse one standalone Java call statement at a time,
# balancing parentheses and respecting string/char literals.
def strip_standalone_calls(text, token):
    removed=0
    search_from=0
    while True:
        pos=text.find(token, search_from)
        if pos<0: break
        line_start=text.rfind('\n',0,pos)+1
        prefix=text[line_start:pos]
        # Method declaration/reference is not a standalone call statement.
        if prefix.strip()!='':
            search_from=pos+len(token)
            continue
        paren=text.find('(',pos+len(token))
        if paren<0:
            raise SystemExit('R1.2 malformed diagnostic call')
        depth=0; p=paren; in_str=False; in_char=False; esc=False
        close=-1
        while p<len(text):
            c=text[p]
            if in_str:
                if esc: esc=False
                elif c=='\\': esc=True
                elif c=='"': in_str=False
            elif in_char:
                if esc: esc=False
                elif c=='\\': esc=True
                elif c=="'": in_char=False
            else:
                if c=='"': in_str=True
                elif c=="'": in_char=True
                elif c=='(': depth+=1
                elif c==')':
                    depth-=1
                    if depth==0:
                        close=p; break
            p+=1
        if close<0: raise SystemExit('R1.2 unterminated diagnostic call')
        q=close+1
        while q<len(text) and text[q] in ' \t\r': q+=1
        if q>=len(text) or text[q]!=';':
            search_from=pos+len(token)
            continue
        q+=1
        while q<len(text) and text[q] in ' \t\r': q+=1
        if q<len(text) and text[q]=='\n': q+=1
        text=text[:line_start]+text[q:]
        removed+=1
        search_from=line_start
    return text,removed

helper_token='rg35xxVC7R18Diag'
helper_calls_before=len(re.findall(r'\brg35xxVC7R18Diag\s*\(',f))
f,helper_removed=strip_standalone_calls(f,helper_token)

# Make the helper itself a no-op so even a future accidental call cannot write.
helper_sig='    private static void rg35xxVC7R18Diag(String msg)'
start=f.find(helper_sig)
if start>=0:
    brace=f.find('{',start+len(helper_sig))
    if brace<0: raise SystemExit('R1.2 diag helper opening brace not found')
    depth=0; p=brace; in_str=False; in_char=False; esc=False
    close=-1
    while p<len(f):
        c=f[p]
        if in_str:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=='"': in_str=False
        elif in_char:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=="'": in_char=False
        else:
            if c=='"': in_str=True
            elif c=="'": in_char=True
            elif c=='{': depth+=1
            elif c=='}':
                depth-=1
                if depth==0:
                    close=p; break
        p+=1
    if close<0: raise SystemExit('R1.2 diag helper closing brace not found')
    f=f[:brace]+'{\n        /* VC7R22-R1.2a: production no-op; diagnostics removed from hot path. */\n    }'+f[close+1:]

# Remove direct JAVA-DIAG println statements if any historical variant remains.
f=re.sub(r'\n\s*System\.err\.println\(\"RG35XX-JAVA-DIAG:.*?\);\s*', '\n', f, flags=re.S)

# ---- Gates ----
for tok in ('hasMeaningfulAlpha','if(!hasMeaningfulAlpha && !hasTrns)','workerSnapshot','controlSnapshot','snapshotFrame(','encodeAndWriteFrame(','worker.setDaemon(true)'):
    if tok not in i+f: raise SystemExit('R1.2 missing '+tok)
if 'sendFrameLocked(' in f: raise SystemExit('R1.2 old sendFrameLocked survived')
remaining_calls=len(re.findall(r'\brg35xxVC7R18Diag\s*\(',f))
allowed_decl=1 if helper_sig in f else 0
if remaining_calls!=allowed_decl:
    raise SystemExit('R1.2 helper diagnostic callsites survived: %d (allowed declaration=%d)'%(remaining_calls,allowed_decl))
if 'System.err.println("RG35XX-JAVA-DIAG:' in f:
    raise SystemExit('R1.2 direct JAVA-DIAG println survived')
if helper_calls_before>allowed_decl and helper_removed<1:
    raise SystemExit('R1.2 expected helper diagnostic call removal did not occur')
if orig_i==i or orig_f==f: raise SystemExit('R1.2 no mutation')
pi.write_text(i,encoding='utf-8',newline='\n')
ft.write_text(f,encoding='utf-8',newline='\n')
print('VC7R22-R1.2 LOCK_TRANSPARENCY_FIX=PASS')
print('JAVA_DIAG_HELPER_CALLS_BEFORE=%d'%helper_calls_before)
print('JAVA_DIAG_HELPER_CALLS_REMOVED=%d'%helper_removed)
print('JAVA_DIAG_EXECUTABLE_SURVIVORS=0')
print('LOCK_ORDER=FRONTBUFFER_SNAPSHOT_THEN_ENCODE')
print('TRANSPARENCY=MEANINGFUL_PIXEL_ALPHA_THEN_TRNS_THEN_LEGACY_WHITEKEY')
print('FRAME_WORKER_DAEMON=TRUE')
