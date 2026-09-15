#!/usr/bin/env bash
set -euo pipefail
OUT=${1:-m1_4a_audit}
BASE=miyoo-m1/M1.4A-java5-boot-slice-audit.sh
TMP=$(mktemp)
cp "$BASE" "$TMP"
python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
s=s.replace('echo M1_4A_5_SDLMIXER_BOOT_DECOUPLE_AUDIT','echo M1_4A_6_RMS_IMPORT_BOUNDARY_AUDIT')
s=s.replace('echo PRIMARY_VARIABLE=REMOVE_SDLMIXER_BOOT_LIFECYCLE_COUPLING_FROM_NO_AUDIO_M1_SLICE','echo PRIMARY_VARIABLE=REMOVE_UNUSED_MIDLET_RMS_IMPORT_ONLY')
# Anchor specifically inside the MIDlet transformation. The prior wrapper used the first
# SdlMixerManager import-removal occurrence, which belongs to Display.java, so RMS was never removed.
needle="p=Path('src/javax/microedition/midlet/MIDlet.java'); s=p.read_text()\ns=s.replace('import org.recompile.mobile.SdlMixerManager;\\n','')\n"
replacement=needle+"s=s.replace('import javax.microedition.rms.*;\\n','')\n"
if needle not in s: raise SystemExit('MIDLET_TRANSFORM_ANCHOR_NOT_FOUND')
s=s.replace(needle,replacement,1)
needle2="if grep -E '(Display|MIDlet|Anbu)\\.java.*SdlMixerManager|symbol:[[:space:]]+(class|variable)[[:space:]]+SdlMixerManager' ../\"$OUT\"/JAVAC-ERRORS.txt >/dev/null; then echo SDLMIXER_BOOT_GATE=FAIL; RC=1; else echo SDLMIXER_BOOT_GATE=PASS; fi\n"
replacement2=needle2+"if grep -E 'MIDlet\\.java.*javax\\.microedition\\.rms|package javax\\.microedition\\.rms does not exist' ../\"$OUT\"/JAVAC-ERRORS.txt >/dev/null; then echo MIDLET_RMS_IMPORT_GATE=FAIL; RC=1; else echo MIDLET_RMS_IMPORT_GATE=PASS; fi\n"
if needle2 not in s: raise SystemExit('GATE_ANCHOR_NOT_FOUND')
s=s.replace(needle2,replacement2,1)
s=s.replace('echo M1_4A_5_RESULT=PASS','echo M1_4A_6_RESULT=PASS')
s=s.replace('echo M1_4A_5_RESULT=FAIL_CLOSED','echo M1_4A_6_RESULT=FAIL_CLOSED')
p.write_text(s)
PY
bash "$TMP" "$OUT"
