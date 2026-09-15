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
s=s.replace('echo M1_4A_5_SDLMIXER_BOOT_DECOUPLE_AUDIT','echo M1_4A_8_MYMETHODVISITOR_JAVA5_AUDIT',1)
s=s.replace('echo PRIMARY_VARIABLE=REMOVE_SDLMIXER_BOOT_LIFECYCLE_COUPLING_FROM_NO_AUDIO_M1_SLICE','echo PRIMARY_VARIABLE=BACKPORT_ACTIVE_MYMETHODVISITOR_SYNTAX_TO_JAVA5_PRESERVING_ASM_SEMANTICS',1)
# One flat transform, inserted directly into the known A.5 baseline Python block.
anchor="for path,repls in exact.items(): edit(path,repls)\n"
extra=r'''# M1.4A.6: unused RMS import boundary.
p=Path('src/javax/microedition/midlet/MIDlet.java'); t=p.read_text(); t=t.replace('import javax.microedition.rms.*;\n',''); p.write_text(t)
# M1.4A.7: inactive M3G imports in the 2D slice.
for rel in ('src/org/recompile/mobile/Mobile.java','src/org/recompile/mobile/MobilePlatform.java'):
    p=Path(rel); t=p.read_text(); t=t.replace('import javax.microedition.m3g.Graphics3D;\n',''); p.write_text(t)
# M1.4A.8: preserve active ASM visitor semantics, backport only String-switch syntax.
p=Path('src/org/recompile/mobile/MyMethodVisitor.java'); t=p.read_text()
old='\t\tswitch (owner)\n\t\t{\n'
if old not in t: raise SystemExit('MYMETHODVISITOR_STRING_SWITCH_NOT_FOUND')
owners=['java/lang/Class','java/lang/Thread','java/lang/String','java/io/InputStreamReader','java/io/OutputStreamWriter','java/io/ByteArrayOutputStream','java/io/PrintStream','com/siemens/mp/io/Connection','java/util/Timer','java/util/TimerTask','java/lang/Runtime']
pre='\t\tint ownerCase = 0;\n'
for i,o in enumerate(owners,1): pre += '\t\t%s (owner.equals("%s")) ownerCase = %d;\n' % ('if' if i==1 else 'else if',o,i)
pre += '\t\tswitch (ownerCase)\n\t\t{\n'
t=t.replace(old,pre,1)
for i,o in enumerate(owners,1):
    case='case "%s":' % o
    if case not in t: raise SystemExit('MYMETHODVISITOR_CASE_NOT_FOUND:'+o)
    t=t.replace(case,'case %d:' % i,1)
p.write_text(t)
'''
if anchor not in s: raise SystemExit('FLAT_TRANSFORM_ANCHOR_NOT_FOUND')
s=s.replace(anchor,anchor+extra,1)
# Include active visitor; keep RMS implementation and all other deferred boundaries excluded.
s=s.replace("! -path 'src/javax/microedition/rms/*' ! -name 'MyMethodVisitor.java' \\","! -path 'src/javax/microedition/rms/*' \\",1)
s=s.replace('MyMethodVisitor = deferred bytecode-rewrite boundary','MyMethodVisitor = active ASM instrumentation path; Java5 syntax backport under M1.4A.8',1)
# Append deterministic gates immediately after the existing SDL mixer gate.
gate_anchor="if grep -E '(Display|MIDlet|Anbu)\\.java.*SdlMixerManager|symbol:[[:space:]]+(class|variable)[[:space:]]+SdlMixerManager' ../\"$OUT\"/JAVAC-ERRORS.txt >/dev/null; then echo SDLMIXER_BOOT_GATE=FAIL; RC=1; else echo SDLMIXER_BOOT_GATE=PASS; fi\n"
gates="""if grep -E 'MIDlet\\.java.*javax\\.microedition\\.rms|package javax\\.microedition\\.rms does not exist' ../\"$OUT\"/JAVAC-ERRORS.txt >/dev/null; then echo MIDLET_RMS_IMPORT_GATE=FAIL; RC=1; else echo MIDLET_RMS_IMPORT_GATE=PASS; fi
if grep -E '(Mobile|MobilePlatform)\\.java.*javax\\.microedition\\.m3g|package javax\\.microedition\\.m3g does not exist' ../\"$OUT\"/JAVAC-ERRORS.txt >/dev/null; then echo M3G_2D_IMPORT_GATE=FAIL; RC=1; else echo M3G_2D_IMPORT_GATE=PASS; fi
if grep -E 'MyMethodVisitor\\.java.*error:|cannot find symbol.*MyMethodVisitor' ../\"$OUT\"/JAVAC-ERRORS.txt >/dev/null; then echo MYMETHODVISITOR_JAVA5_GATE=FAIL; RC=1; else echo MYMETHODVISITOR_JAVA5_GATE=PASS; fi
"""
if gate_anchor not in s: raise SystemExit('FLAT_GATE_ANCHOR_NOT_FOUND')
s=s.replace(gate_anchor,gate_anchor+gates,1)
s=s.replace('echo M1_4A_5_RESULT=PASS','echo M1_4A_8_RESULT=PASS',1)
s=s.replace('echo M1_4A_5_RESULT=FAIL_CLOSED','echo M1_4A_8_RESULT=FAIL_CLOSED',1)
p.write_text(s)
PY
bash "$TMP" "$OUT"
