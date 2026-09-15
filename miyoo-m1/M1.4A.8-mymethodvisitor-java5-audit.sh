#!/usr/bin/env bash
set -euo pipefail
OUT=${1:-m1_4a_audit}
BASE=miyoo-m1/M1.4A.7-m3g-import-audit.sh
TMP=$(mktemp)
cp "$BASE" "$TMP"
python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
s=s.replace('echo M1_4A_7_M3G_2D_IMPORT_BOUNDARY_AUDIT','echo M1_4A_8_MYMETHODVISITOR_JAVA5_AUDIT')
s=s.replace('echo PRIMARY_VARIABLE=REMOVE_INACTIVE_GRAPHICS3D_IMPORTS_FROM_2D_BOOT_SLICE_ONLY','echo PRIMARY_VARIABLE=BACKPORT_ACTIVE_MYMETHODVISITOR_SYNTAX_TO_JAVA5_PRESERVING_ASM_SEMANTICS')
# A.7 builds its generated transform in `addition`; append A.8 to that exact generated transform.
needle='addition=needle+"m3g=' 
pos=s.find(needle)
if pos < 0: raise SystemExit('MYMETHODVISITOR_TRANSFORM_ANCHOR_NOT_FOUND')
line_end=s.find('\n',pos)
if line_end < 0: raise SystemExit('MYMETHODVISITOR_TRANSFORM_LINE_END_NOT_FOUND')
dispatch="""mv=Path('src/org/recompile/mobile/MyMethodVisitor.java')
t=mv.read_text()
old='\\t\\tswitch (owner)\\n\\t\\t{\\n'
if old not in t: raise SystemExit('MYMETHODVISITOR_STRING_SWITCH_NOT_FOUND')
owners=['java/lang/Class','java/lang/Thread','java/lang/String','java/io/InputStreamReader','java/io/OutputStreamWriter','java/io/ByteArrayOutputStream','java/io/PrintStream','com/siemens/mp/io/Connection','java/util/Timer','java/util/TimerTask','java/lang/Runtime']
pre='\\t\\tint ownerCase = 0;\\n'
for i,o in enumerate(owners,1): pre += ('\\t\\t' + ('if' if i==1 else 'else if') + ' (owner.equals(\\\"'+o+'\\\")) ownerCase = '+str(i)+';\\n')
pre += '\\t\\tswitch (ownerCase)\\n\\t\\t{\\n'
t=t.replace(old,pre,1)
for i,o in enumerate(owners,1): t=t.replace('case \\\"'+o+'\\\":','case '+str(i)+':')
mv.write_text(t)
"""
insert="\n# M1.4A.8 append active MyMethodVisitor Java5 syntax transform to A.7 generated payload.\naddition=addition+\"dispatch=\"+repr("+repr(dispatch)+")+\"\\nreplacement=replacement+dispatch\\n\"\n"
s=s[:line_end+1]+insert+s[line_end+1:]
# Include MyMethodVisitor in the bounded source list by modifying the generated A.6 wrapper text directly.
marker="# Preserve prior gates and append the M3G gate after A.6's RMS gate construction.\n"
extra="s=s.replace(\"! -path 'src/javax/microedition/rms/*' ! -name 'MyMethodVisitor.java'\",\"! -path 'src/javax/microedition/rms/*'\")\ns=s.replace('MyMethodVisitor = deferred bytecode-rewrite boundary','MyMethodVisitor = active ASM instrumentation path; Java5 syntax backport under M1.4A.8')\n"
if marker not in s: raise SystemExit('MYMETHODVISITOR_INCLUDE_ANCHOR_NOT_FOUND')
s=s.replace(marker,extra+marker,1)
# Add compiler gate by extending A.7's generated M3G gate payload.
needle3="addition2=needle2+\"replacement2=replacement2+"
pos3=s.find(needle3)
if pos3 < 0: raise SystemExit('MYMETHODVISITOR_GATE_ANCHOR_NOT_FOUND')
end3=s.find('\n',pos3)
if end3 < 0: raise SystemExit('MYMETHODVISITOR_GATE_LINE_END_NOT_FOUND')
gate="replacement2=replacement2+\"if grep -E 'MyMethodVisitor\\\\.java.*(error:|switch|case)|cannot find symbol.*MyMethodVisitor' ../\\\"$OUT\\\"/JAVAC-ERRORS.txt >/dev/null; then echo MYMETHODVISITOR_JAVA5_GATE=FAIL; RC=1; else echo MYMETHODVISITOR_JAVA5_GATE=PASS; fi\\n\"\n"
s=s[:end3+1]+gate+s[end3+1:]
s=s.replace('echo M1_4A_7_RESULT=PASS','echo M1_4A_8_RESULT=PASS')
s=s.replace('echo M1_4A_7_RESULT=FAIL_CLOSED','echo M1_4A_8_RESULT=FAIL_CLOSED')
p.write_text(s)
PY
bash "$TMP" "$OUT"
