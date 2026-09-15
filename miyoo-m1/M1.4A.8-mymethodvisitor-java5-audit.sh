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
# A.7 injects source transforms into the A.6 wrapper. Append the active visitor syntax backport there.
needle="replacement=replacement+m3g\n"
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
addition=needle+"dispatch="+repr(dispatch)+"\nreplacement=replacement+dispatch\n"
if needle not in s: raise SystemExit('MYMETHODVISITOR_TRANSFORM_ANCHOR_NOT_FOUND')
s=s.replace(needle,addition,1)
# Include MyMethodVisitor in the bounded source list instead of deferring it.
needle2="s=s.replace('echo M1_4A_6_RESULT=PASS','echo M1_4A_7_RESULT=PASS')\n"
extra="s=s.replace(\"! -path 'src/javax/microedition/rms/*' ! -name 'MyMethodVisitor.java'\",\"! -path 'src/javax/microedition/rms/*'\")\ns=s.replace('MyMethodVisitor = deferred bytecode-rewrite boundary','MyMethodVisitor = active ASM instrumentation path; Java5 syntax backport under M1.4A.8')\n"
if needle2 not in s: raise SystemExit('MYMETHODVISITOR_INCLUDE_ANCHOR_NOT_FOUND')
s=s.replace(needle2,extra+needle2,1)
# Add a strict visitor compiler gate while preserving A.4-A.7 gates.
needle3="replacement2=replacement2+\"if grep -E '(Mobile|MobilePlatform)\\\\.java.*javax\\\\.microedition\\\\.m3g|package javax\\\\.microedition\\\\.m3g does not exist' ../\\\"$OUT\\\"/JAVAC-ERRORS.txt >/dev/null; then echo M3G_2D_IMPORT_GATE=FAIL; RC=1; else echo M3G_2D_IMPORT_GATE=PASS; fi\\n\"\n"
addition3=needle3+"replacement2=replacement2+\"if grep -E 'MyMethodVisitor\\\\.java.*(error:|switch|case)|cannot find symbol.*MyMethodVisitor' ../\\\"$OUT\\\"/JAVAC-ERRORS.txt >/dev/null; then echo MYMETHODVISITOR_JAVA5_GATE=FAIL; RC=1; else echo MYMETHODVISITOR_JAVA5_GATE=PASS; fi\\n\"\n"
if needle3 not in s: raise SystemExit('MYMETHODVISITOR_GATE_ANCHOR_NOT_FOUND')
s=s.replace(needle3,addition3,1)
s=s.replace('echo M1_4A_7_RESULT=PASS','echo M1_4A_8_RESULT=PASS')
s=s.replace('echo M1_4A_7_RESULT=FAIL_CLOSED','echo M1_4A_8_RESULT=FAIL_CLOSED')
p.write_text(s)
PY
bash "$TMP" "$OUT"
