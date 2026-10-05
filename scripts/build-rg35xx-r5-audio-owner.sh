#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R4_DEVICE_ZIP="${R4_DEVICE_ZIP:-}"
R5_AUDIO_SO="${R5_AUDIO_SO:-}"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
R4_SHA=0e739da19b7f6078e8c9b1b2223cf3fb55a9f95e187830502320a1987282792d
OLD_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
fail(){ echo "R5_AUDIO_OWNER_BUILD_FAIL=$*" >&2; exit 2; }
[ -f "$R4_DEVICE_ZIP" ] || fail R4_DEVICE_ZIP_MISSING
[ "$(sha256sum "$R4_DEVICE_ZIP"|awk '{print $1}')" = "$R4_SHA" ] || fail R4_PARENT_HASH
[ -f "$R5_AUDIO_SO" ] || fail R5_AUDIO_SO_MISSING
[ -n "$JAVA8" ] && [ -x "$JAVA8/bin/javac" ] && [ -x "$JAVA8/bin/jar" ] || fail JAVA8_MISSING

WORK="$ROOT/build/r5-audio-owner"
OUT="$ROOT/out/r5-audio-owner"
FINAL="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-OWNER"
rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/r4" "$WORK/classes" "$FINAL"
unzip -q "$R4_DEVICE_ZIP" -d "$WORK/r4"
R4ROOT="$(find "$WORK/r4" -mindepth 1 -maxdepth 1 -type d -name 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R4' -print -quit)"
[ -n "$R4ROOT" ] || fail R4_ROOT_MISSING
cp -a "$R4ROOT"/. "$FINAL"/
PKG="$FINAL/SD/Roms/APPS/FreeJ2ME-RG35XX"
APPS="$FINAL/SD/Roms/APPS"

# R4 parent identities must be exact before any mutation.
[ "$(sha256sum "$PKG/freej2me-rg35xx.jar"|awk '{print $1}')" = a72df91165616bb87d1821ab9fb8641bd2c168b53175043ccd691bffe9504f00 ] || fail PLATFORM_PARENT
[ "$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')" = "$OLD_AUDIO" ] || fail AUDIO_PARENT
[ "$(sha256sum "$PKG/librg35xx_input.so"|awk '{print $1}')" = 6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c ] || fail INPUT_PARENT
[ "$(sha256sum "$PKG/librg35xx_video.so"|awk '{print $1}')" = c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d ] || fail VIDEO_PARENT
[ "$(sha256sum "$PKG/a7-a1p5-rw-silence-prime.s32le"|awk '{print $1}')" = 8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e ] || fail PRIME_PARENT

install -m 0755 "$R5_AUDIO_SO" "$PKG/libaudio.so"
R5_AUDIO_SHA="$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')"
[ "$R5_AUDIO_SHA" != "$OLD_AUDIO" ] || fail AUDIO_CANDIDATE_NOT_CHANGED
strings "$PKG/libaudio.so" | grep -q 'RG35XX_R5_AUDIO_OWNER_BIND=PASS' || fail R5_OWNER_MARKER_MISSING
strings "$PKG/libaudio.so" | grep -q 'RG35XX_R5_AUDIO_OWNER_RESUME=IGNORED_NONOWNER' || fail R5_RESUME_MARKER_MISSING

# Generic, generated LOW/HIGH MIDI fixtures; no commercial game bytes.
python3 - "$WORK/classes/owner-a-low.mid" "$WORK/classes/owner-b-high.mid" <<'PY'
import struct,sys

def vlq(n):
    b=[n&0x7f]; n>>=7
    while n: b.append((n&0x7f)|0x80); n>>=7
    return bytes(reversed(b))
def tone(note):
    ev=bytearray()
    ev += b'\x00\xff\x51\x03\x07\xa1\x20'  # 120 BPM
    ev += b'\x00\xc0\x50'                    # synth lead
    for _ in range(8):
        ev += b'\x00\x90'+bytes([note,110])
        ev += vlq(480)+b'\x80'+bytes([note,0])
    ev += b'\x00\xff\x2f\x00'
    return b'MThd'+struct.pack('>IHHH',6,0,1,96)+b'MTrk'+struct.pack('>I',len(ev))+bytes(ev)
open(sys.argv[1],'wb').write(tone(48))
open(sys.argv[2],'wb').write(tone(84))
PY

SRC="$ROOT/tests/diagnostics/RG35XXMidiOwnershipDiagnostic.java"
"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 -classpath "$PKG/freej2me-rg35xx.jar" -d "$WORK/classes" "$SRC"
cat >"$WORK/MANIFEST.MF" <<'EOF'
Manifest-Version: 1.0
MIDlet-Name: RG35XX MIDI Ownership R5
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Diagnostics
MIDlet-1: RG35XX MIDI Ownership R5,,RG35XXMidiOwnershipDiagnostic
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF
JAR="$PKG/test/RG35XX-Midi-Ownership-R5.jar"
"$JAVA8/bin/jar" cfm "$JAR" "$WORK/MANIFEST.MF" -C "$WORK/classes" RG35XXMidiOwnershipDiagnostic.class -C "$WORK/classes" 'RG35XXMidiOwnershipDiagnostic$DiagnosticCanvas.class' -C "$WORK/classes" owner-a-low.mid -C "$WORK/classes" owner-b-high.mid
JAR_SHA="$(sha256sum "$JAR"|awk '{print $1}')"

cat >"$APPS/RG35XX-R5-MIDI-OWNER-DIAG.sh" <<'SH'
#!/bin/sh
APPS="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APPS/FreeJ2ME-RG35XX"
LOG=/mnt/mmc/RG35XX-R5-MIDI-OWNER-DIAG.log
PRIMELOG=/mnt/mmc/RG35XX-R5-MIDI-OWNER-PRIME.log
OBS=/mnt/mmc/RG35XX-R5-MIDI-OWNER-OBSERVATION.txt
cat >"$OBS" <<'EOF'
A1_LOW_AUDIBLE=NOT_TESTED
B_HIGH_AUDIBLE=NOT_TESTED
A2_LOW_RETURN_AUDIBLE=NOT_TESTED
OWNER_SWITCH_PHYSICAL=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF
FREEJ2ME_LOG="$LOG" RG35XX_AUDIO_ROUTE_LOG="$PRIMELOG" "$APPS/FreeJ2ME-RG35XX.sh" "$PKG/test/RG35XX-Midi-Ownership-R5.jar" 240 320
RC=$?
echo "MIDI_OWNER_WRAPPER_EXIT=$RC" >>"$LOG"
echo "MIDI_OWNER_PHYSICAL_REVIEW_REQUIRED=YES" >>"$LOG"
sync
exit "$RC"
SH
chmod +x "$APPS/RG35XX-R5-MIDI-OWNER-DIAG.sh"

# Rebind only identity gates that legitimately include the changed native audio owner.
sed -i "s/$OLD_AUDIO/$R5_AUDIO_SHA/g" \
  "$APPS/RG35XX-FULL-PORT-R1-TEST.sh" \
  "$APPS/RG35XX-R1-P7-TIER0.sh" \
  "$PKG/FULL-PORT-R1-IDENTITY.txt" \
  "$APPS/RG35XX-R1-P7/P7-TIER0-IDENTITY.txt"

# Recompute payload manifest after candidate native + generic test insertion.
(cd "$PKG" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$PKG/PAYLOAD-SHA256SUMS.txt"

cat >"$FINAL/AUDIO-OWNER-R5-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=R5_NATIVE_MIDI_PLAYER_OWNERSHIP
PARENT_R4_ZIP_SHA256=$R4_SHA
PARENT_AUDIO_SHA256=$OLD_AUDIO
R5_AUDIO_SHA256=$R5_AUDIO_SHA
R5_OWNER_TEST_JAR_SHA256=$JAR_SHA
CANONICAL_PLATFORMPLAYER=UNCHANGED
CANONICAL_MMAPI=UNCHANGED
RUNTIME_SEMANTIC_DELTA=NONE
PLATFORM_JAVA_DELTA=NONE
NATIVE_AUDIO_DELTA=PLAYER_MANAGER_OWNERSHIP_ONLY
INPUT_DELTA=NONE
VIDEO_DELTA=NONE
A1P5_PRIME_DELTA=NONE
GAME_SPECIFIC_CODE=NO
COMMERCIAL_GAME_CONTENT=NO
P6_PHYSICAL_ACCEPTANCE=RETEST_REQUIRED_NATIVE_CHANGED
P7_PHYSICAL_REGRESSION=RETEST_REQUIRED_NATIVE_CHANGED
DEVICE_PASS=NO
STABLE=NO
EOF
cat >"$FINAL/README-R5.txt" <<EOF
R5 native MIDI player ownership candidate. Diagnostic/physical-test candidate only.
Run RG35XX-R5-MIDI-OWNER-DIAG first and verify LOW A -> HIGH B -> LOW A returns.
If that passes, rerun RG35XX-FULL-PORT-R1-TEST, then RG35XX-R1-P7-TIER0.
R5_AUDIO_SHA256=$R5_AUDIO_SHA
DEVICE_PASS=NO
STABLE=NO
EOF

# Commercial Tier-0 JARs must remain external.
if find "$FINAL" -type f -iname '*.jar' -print | grep -Eq 'God-of-War|Vua-Cuop-Bien'; then fail COMMERCIAL_JAR_EMBEDDED; fi

ZIP="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-OWNER.zip"
(cd "$OUT" && zip -qr -X "$(basename "$ZIP")" "$(basename "$FINAL")")
echo R5_AUDIO_OWNER_BUILD=PASS
echo R5_AUDIO_SHA256=$R5_AUDIO_SHA
echo R5_OWNER_TEST_JAR_SHA256=$JAR_SHA
echo R5_DEVICE_ZIP_SHA256=$(sha256sum "$ZIP"|awk '{print $1}')
echo R5_CANONICAL_JAVA_DELTA=NONE
echo R5_RUNTIME_SEMANTIC_DELTA=NONE
echo R5_GAME_SPECIFIC_CODE=NO
