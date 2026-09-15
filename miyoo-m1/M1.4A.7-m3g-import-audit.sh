#!/usr/bin/env bash
set -euo pipefail
OUT=${1:-m1_4a_audit}
BASE=miyoo-m1/M1.4A.6-rms-import-audit.sh
TMP=$(mktemp)
cp "$BASE" "$TMP"
python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
s=s.replace('echo M1_4A_6_RMS_IMPORT_BOUNDARY_AUDIT','echo M1_4A_7_M3G_2D_IMPORT_BOUNDARY_AUDIT')
s=s.replace('echo PRIMARY_VARIABLE=REMOVE_UNUSED_MIDLET_RMS_IMPORT_ONLY','echo PRIMARY_VARIABLE=REMOVE_INACTIVE_GRAPHICS3D_IMPORTS_FROM_2D_BOOT_SLICE_ONLY')
# A.6 is itself a wrapper, so anchor to its exact MIDlet replacement expression.
needle="replacement=needle+\"s=s.replace('import javax.microedition.rms.*;\\\\n','')\\n\"\n"
addition=needle+"m3g=\"for rel in ('src/org/recompile/mobile/Mobile.java','src/org/recompile/mobile/MobilePlatform.java'):\\n    q=Path(rel); t=q.read_text(); t=t.replace('import javax.microedition.m3g.Graphics3D;\\\\n',''); q.write_text(t)\\n\"\nreplacement=replacement+m3g\n"
if needle not in s: raise SystemExit('M3G_TRANSFORM_ANCHOR_NOT_FOUND')
s=s.replace(needle,addition,1)
# Preserve prior gates and append the M3G gate after A.6's RMS gate construction.
needle2="replacement2=needle2+\"if grep -E 'MIDlet\\\\.java.*javax\\\\.microedition\\\\.rms|package javax\\\\.microedition\\\\.rms does not exist' ../\\\"$OUT\\\"/JAVAC-ERRORS.txt >/dev/null; then echo MIDLET_RMS_IMPORT_GATE=FAIL; RC=1; else echo MIDLET_RMS_IMPORT_GATE=PASS; fi\\n\"\n"
addition2=needle2+"replacement2=replacement2+\"if grep -E '(Mobile|MobilePlatform)\\\\.java.*javax\\\\.microedition\\\\.m3g|package javax\\\\.microedition\\\\.m3g does not exist' ../\\\"$OUT\\\"/JAVAC-ERRORS.txt >/dev/null; then echo M3G_2D_IMPORT_GATE=FAIL; RC=1; else echo M3G_2D_IMPORT_GATE=PASS; fi\\n\"\n"
if needle2 not in s: raise SystemExit('M3G_GATE_ANCHOR_NOT_FOUND')
s=s.replace(needle2,addition2,1)
s=s.replace('echo M1_4A_6_RESULT=PASS','echo M1_4A_7_RESULT=PASS')
s=s.replace('echo M1_4A_6_RESULT=FAIL_CLOSED','echo M1_4A_7_RESULT=FAIL_CLOSED')
p.write_text(s)
PY
bash "$TMP" "$OUT"
