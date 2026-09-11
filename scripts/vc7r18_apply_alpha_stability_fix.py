#!/usr/bin/env python3
import pathlib, sys
if len(sys.argv) != 3:
    raise SystemExit('usage: vc7r18_apply_alpha_stability_fix.py <PlatformImage.java> <RG35XXGoldenFrameTransport.java>')
img=pathlib.Path(sys.argv[1]); trn=pathlib.Path(sys.argv[2])
s=img.read_text(encoding='utf-8'); t=trn.read_text(encoding='utf-8')
anchor='\t\tfinal int[] pixels = image.getRGB(0, 0, w, h, null, 0, w);\n'
if s.count(anchor)!=1: raise SystemExit('alpha anchor mismatch')
s=s.replace(anchor, anchor+'\t\tfinal boolean sourceHasAlpha = image.getColorModel().hasAlpha();\n\t\tif(!sourceHasAlpha)\n\t\t{\n\t\t\tfor(int i=0;i<pixels.length;i++) pixels[i] |= 0xFF000000;\n\t\t}\n',1)
field='\tprivate static final String RG35XX_VC7R10_LOG = "/mnt/mmc/freej2me-vc7r10-java.log";\n\n'
if s.count(field)!=1: raise SystemExit('log field mismatch')
s=s.replace(field,field+'\tprivate static int rg35xxVC7R18ImageLogCount;\n\n',1)
method='\tprivate static void rg35xxVC7R10Log(String message)\n\t{\n'
if s.count(method)!=1: raise SystemExit('log method mismatch')
s=s.replace(method,method+'\t\tif(rg35xxVC7R18ImageLogCount++ >= 96) return;\n',1)
old='" sourceType=" + image.getType() + " first=" + Integer.toHexString(first) + " mid=" + Integer.toHexString(mid) + " last=" + Integer.toHexString(last));'
new='" sourceType=" + image.getType() + " sourceHasAlpha=" + sourceHasAlpha + " first=" + Integer.toHexString(first) + " mid=" + Integer.toHexString(mid) + " last=" + Integer.toHexString(last) + " RG35XX-VC7R18-ALPHA");'
if s.count(old)!=1: raise SystemExit('normalize log mismatch')
s=s.replace(old,new,1)
class_anchor='public final class RG35XXGoldenFrameTransport\n{\n'
if t.count(class_anchor)!=1: raise SystemExit('transport class mismatch')
t=t.replace(class_anchor,class_anchor+'    private static int rg35xxVC7R18DiagCount;\n    private static void rg35xxVC7R18Diag(String message)\n    {\n        if(rg35xxVC7R18DiagCount++ < 48) System.err.println(message);\n    }\n\n',1)
count=t.count('System.err.println("RG35XX-JAVA-DIAG:')
if count<8: raise SystemExit('transport diag count=%d'%count)
t=t.replace('System.err.println("RG35XX-JAVA-DIAG:','rg35xxVC7R18Diag("RG35XX-JAVA-DIAG:')
img.write_text(s,encoding='utf-8',newline='\n'); trn.write_text(t,encoding='utf-8',newline='\n')
print('VC7R18_ALPHA_STABILITY_FIX=PASS')
