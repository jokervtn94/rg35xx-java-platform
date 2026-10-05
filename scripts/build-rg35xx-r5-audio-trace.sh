#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R5_DEVICE_ZIP="${R5_DEVICE_ZIP:-}"
R5_AUDIO_SO="${R5_AUDIO_SO:-}"
EXPECTED_R5_AUDIO="bf6fbdd24fb6ef37dba60438be9992441e4ce8567313f7df3fdebdbea8cd32e5"
fail(){ echo "R5_AUDIO_TRACE_BUILD_FAIL=$*" >&2; exit 2; }

[ -f "$R5_DEVICE_ZIP" ] || fail R5_DEVICE_ZIP_MISSING
[ -f "$R5_AUDIO_SO" ] || fail R5_AUDIO_SO_MISSING

WORK="$ROOT/build/r5-audio-trace"
OUT="$ROOT/out/r5-audio-trace"
FINAL="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-AUDIO-TRACE"
rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/unpacked" "$FINAL"
unzip -q "$R5_DEVICE_ZIP" -d "$WORK/unpacked"
R5ROOT="$(find "$WORK/unpacked" -mindepth 1 -maxdepth 2 -type d -name 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-OWNER' -print -quit)"
[ -n "$R5ROOT" ] || fail R5_ROOT_MISSING
cp -a "$R5ROOT"/. "$FINAL"/

PKG="$FINAL/SD/Roms/APPS/FreeJ2ME-RG35XX"
[ -f "$PKG/libaudio.so" ] || fail PACKAGE_AUDIO_MISSING
[ "$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')" = "$EXPECTED_R5_AUDIO" ] || fail R5_PARENT_AUDIO_HASH

install -m 0755 "$R5_AUDIO_SO" "$PKG/libaudio.so"
TRACE_AUDIO_SHA="$(sha256sum "$PKG/libaudio.so"|awk '{print $1}')"
[ "$TRACE_AUDIO_SHA" != "$EXPECTED_R5_AUDIO" ] || fail TRACE_AUDIO_NOT_CHANGED
strings "$PKG/libaudio.so" | grep -q 'RG35XX_AUDIO_TRACE event=' || fail TRACE_MARKER_MISSING
strings "$PKG/libaudio.so" | grep -q 'RG35XX_R5_AUDIO_OWNER_PLAY=' || fail TRACE_PLAY_MARKER_MISSING

# The diagnostic native payload has a new identity. Rebind only the two
# physical-test launchers that intentionally hash-gate libaudio.so.
for launcher in \
  "$FINAL/SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh" \
  "$FINAL/SD/Roms/APPS/RG35XX-R1-P7-TIER0.sh"; do
  [ -f "$launcher" ] || fail "LAUNCHER_MISSING:$launcher"
  sed -i "s/$EXPECTED_R5_AUDIO/$TRACE_AUDIO_SHA/g" "$launcher"
  grep -q "EXPECTED_AUDIO=$TRACE_AUDIO_SHA" "$launcher" || fail "AUDIO_HASH_REBIND:$launcher"
done

# Keep the diagnostic useful when Vua crashes in its RecordStore path: record
# the failure, continue to God of War, and return nonzero at the end.
P7_LAUNCHER="$FINAL/SD/Roms/APPS/RG35XX-R1-P7-TIER0.sh"
python3 - "$P7_LAUNCHER" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
old = '[ "$VRC" -eq 0 ] || fail "VUA_JVM_EXIT:$VRC"\necho \'VUA_PHYSICAL_REVIEW=REQUIRED\' >>"$SUMMARY"'
new = '''if [ "$VRC" -eq 0 ]; then
  echo 'VUA_PHYSICAL_REVIEW=REQUIRED' >>"$SUMMARY"
else
  echo "VUA_RUNTIME_FAILURE=JVM_EXIT:$VRC" >>"$MASTER"
  echo "VUA_RUNTIME_FAILURE=JVM_EXIT:$VRC" >>"$SUMMARY"
  echo 'P7_VUA_CONTINUE_TO_GOW=YES' >>"$MASTER"
fi'''
if s.count(old) != 1:
    raise SystemExit('P7_TRACE_HARNESS_VUA_BLOCK_NOT_FOUND')
s = s.replace(old, new, 1)
old = "echo 'P7_PROGRAMMATIC_IDENTITY_AND_LAUNCH=PASS' >>\"$SUMMARY\"\necho 'P7_PHYSICAL_REGRESSION=NOT_TESTED' >>\"$SUMMARY\""
new = '''if [ "$VRC" -ne 0 ]; then
  echo 'P7_PROGRAMMATIC_IDENTITY_AND_LAUNCH=PARTIAL_VUA_RUNTIME_FAILURE' >>"$SUMMARY"
  echo 'P7_PHYSICAL_REGRESSION=BLOCKED_BY_VUA_RUNTIME_FAILURE' >>"$SUMMARY"
  echo 'DEVICE_PASS=NO' >>"$SUMMARY"
  echo 'STABLE=NO' >>"$SUMMARY"
  sync
  exit 20
fi
echo 'P7_PROGRAMMATIC_IDENTITY_AND_LAUNCH=PASS' >>"$SUMMARY"
echo 'P7_PHYSICAL_REGRESSION=NOT_TESTED' >>"$SUMMARY"'''
if s.count(old) != 1:
    raise SystemExit('P7_TRACE_HARNESS_FINAL_BLOCK_NOT_FOUND')
s = s.replace(old, new, 1)
p.write_text(s)
PY
grep -q 'P7_VUA_CONTINUE_TO_GOW=YES' "$P7_LAUNCHER" || fail P7_TRACE_HARNESS_MISSING

# Enable tracing only in this diagnostic package. Production R5 remains unchanged.
for launcher in \
  "$FINAL/SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh" \
  "$FINAL/SD/Roms/APPS/RG35XX-R1-P7-TIER0.sh"; do
  [ -f "$launcher" ] || fail "LAUNCHER_MISSING:$launcher"
  python3 - "$launcher" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
if 'export RG35XX_AUDIO_TRACE=1' not in s:
    if not s.startswith('#!/bin/sh'):
        raise SystemExit('TRACE_LAUNCHER_SHEBANG')
    s = s.replace('#!/bin/sh\n', '#!/bin/sh\nexport RG35XX_AUDIO_TRACE=1\n', 1)
    p.write_text(s)
PY
  chmod 0755 "$launcher"
done

PARENT_SHA="$(sha256sum "$R5_DEVICE_ZIP"|awk '{print $1}')"
cat > "$FINAL/R5-AUDIO-TRACE-IDENTITY.txt" <<EOF
PROJECT=RG35XX-AWEIGIT-R1
STAGE=R5P1_AUDIO_LIFECYCLE_TRACE
PARENT_R5_DEVICE_ZIP_SHA256=$PARENT_SHA
PARENT_AUDIO_SHA256=$EXPECTED_R5_AUDIO
TRACE_AUDIO_SHA256=$TRACE_AUDIO_SHA
TRACE_CONTROL=RG35XX_AUDIO_TRACE=1
TRACE_SCOPE=GENERIC_MIDI_WAV_LIFECYCLE_OWNER_STATE_AND_POSTMIX_BUFFER_COUNTERS
TRACE_POSTMIX_COUNTERS=CALLBACKS_BYTES_NONZERO_BUFFERS_LAST_BUFFER
TRACE_MIX_SPEC=QUERY_ACTUAL_FREQUENCY_FORMAT_CHANNELS
P7_HARNESS_DELTA=CONTINUE_TO_GOW_AFTER_VUA_RUNTIME_FAILURE
CANONICAL_PLATFORMPLAYER=UNCHANGED
CANONICAL_MMAPI=UNCHANGED
RUNTIME_SEMANTIC_DELTA=NONE
PLATFORM_JAVA_DELTA=NONE
NATIVE_AUDIO_DELTA=DIAGNOSTIC_TRACE_AND_POSTMIX_COUNTERS_ONLY
GAME_SPECIFIC_CODE=NO
COMMERCIAL_GAME_CONTENT=NO
P6_PHYSICAL_ACCEPTANCE=RETEST_NOT_REQUIRED_TRACE_ONLY
P7_PHYSICAL_REGRESSION=REQUIRED_GOD_OF_WAR_AUDIO_TRACE
DEVICE_PASS=NO
STABLE=NO
EOF

cat > "$FINAL/README-R5-AUDIO-TRACE.txt" <<EOF
R5.2 native audio lifecycle and post-mix diagnostic package.

This package preserves the R5 owner candidate and enables RG35XX_AUDIO_TRACE=1
only for the Full Port and Tier-0 test launchers. It does not change Java,
runtime, video, input, or production audio routing semantics.

The native trace installs an SDL_mixer post-mix counter callback without
logging from the audio thread. The log reports postmix_cb, postmix_nz,
postmix_bytes, postmix_last_len, postmix_last_nonzero, and the actual
Mix_QuerySpec result.

Run RG35XX-R1-P7-TIER0.sh with the same external Vua Cướp Biển and God of War
JARs. Reproduce the God of War menu -> gameplay transition, then collect:
  /mnt/mmc/RG35XX-R1-P7-EVIDENCE/GOW-R1.log
  /mnt/mmc/RG35XX-R1-P7-EVIDENCE/P7-TIER0-RUN.log

TRACE_AUDIO_SHA256=$TRACE_AUDIO_SHA
DEVICE_PASS=NO
STABLE=NO
EOF

(cd "$PKG" && find . -type f ! -name PAYLOAD-SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$PKG/PAYLOAD-SHA256SUMS.txt"

ZIP="$OUT/RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-AUDIO-TRACE.zip"
(cd "$OUT" && zip -qr -X "$(basename "$ZIP")" "$(basename "$FINAL")")
echo R5_AUDIO_TRACE_BUILD=PASS
echo R5_AUDIO_TRACE_PARENT_SHA256=$PARENT_SHA
echo R5_AUDIO_TRACE_SHA256=$TRACE_AUDIO_SHA
echo R5_AUDIO_TRACE_DEVICE_ZIP_SHA256=$(sha256sum "$ZIP"|awk '{print $1}')
echo R5_AUDIO_TRACE_JAVA_DELTA=NONE
echo R5_AUDIO_TRACE_GAME_SPECIFIC_CODE=NO
echo DEVICE_PASS=NO
echo STABLE=NO
