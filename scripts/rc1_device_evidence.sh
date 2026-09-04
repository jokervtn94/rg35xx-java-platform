#!/bin/sh
set -u

# RGJ-RC1-011BG
# Read-only evidence collector for real RG35XX validation sessions.
# This script never marks DEVICE-TEST-PASS by itself.

MODE=${1:-snapshot}
OUT=${2:-"./rg35xx-device-evidence-$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)"}
CORE_PATH=${CORE_PATH:-}
JAR_PATH=${JAR_PATH:-}
FONT_PATH=${FONT_PATH:-/mnt/mmc/Java/runtime/DejaVuSans.ttf}
SOUNDFONT_PATH=${SOUNDFONT_PATH:-/mnt/mmc/Java/runtime/GeneralUser-GS.sf2}

mkdir -p "$OUT" || exit 1

note() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

{
  echo "RG35XX RC1 DEVICE EVIDENCE"
  echo "mode=$MODE"
  echo "timestamp=$(date 2>/dev/null || echo unavailable)"
  echo "core_path=$CORE_PATH"
  echo "jar_path=$JAR_PATH"
  echo "font_path=$FONT_PATH"
  echo "soundfont_path=$SOUNDFONT_PATH"
  echo "build_commit=086d4987c0d60b5eb9abc3887e73638b24a1b964"
  echo "build_run=33883673553"
  echo "build_artifact=9940954185"
  echo "build_artifact_sha256=e2f3e70634026a1916f9cd75af5875b32c087fdae9622349d9f18afad943b630"
} > "$OUT/session.txt"

(uname -a 2>&1 || true) > "$OUT/uname.txt"
(cat /proc/cpuinfo 2>&1 || true) > "$OUT/cpuinfo.txt"
(cat /proc/meminfo 2>&1 || true) > "$OUT/meminfo.txt"
(mount 2>&1 || true) > "$OUT/mounts.txt"
(df -h 2>&1 || df 2>&1 || true) > "$OUT/df.txt"
(ps 2>&1 || true) > "$OUT/processes.txt"

hash_one()
{
  p=$1
  label=$2
  if [ -z "$p" ]; then
    echo "$label: NOT SET"
    return
  fi
  if [ ! -f "$p" ]; then
    echo "$label: MISSING: $p"
    return
  fi
  if have sha256sum; then
    sha256sum "$p"
  elif have busybox && busybox sha256sum "$p" >/dev/null 2>&1; then
    busybox sha256sum "$p"
  else
    echo "$label: SHA256 TOOL UNAVAILABLE: $p"
  fi
}

{
  hash_one "$CORE_PATH" core
  hash_one "$JAR_PATH" jar
  hash_one "$FONT_PATH" font
  hash_one "$SOUNDFONT_PATH" soundfont
} > "$OUT/hashes.txt"

{
  for p in "$CORE_PATH" "$JAR_PATH" "$FONT_PATH" "$SOUNDFONT_PATH"; do
    [ -n "$p" ] || continue
    if [ -e "$p" ]; then
      echo "--- $p"
      ls -l "$p" 2>&1 || true
      if have file; then file "$p" 2>&1 || true; fi
    fi
  done
} > "$OUT/files.txt"

if [ -n "$CORE_PATH" ] && [ -f "$CORE_PATH" ]; then
  if have readelf; then
    readelf -h "$CORE_PATH" > "$OUT/core-readelf.txt" 2>&1 || true
  fi
  if have strings; then
    strings "$CORE_PATH" 2>/dev/null | grep -E 'freej2me\.rg35xx|GeneralUser-GS|RG35XX' > "$OUT/core-strings.txt" 2>/dev/null || true
  fi
fi

{
  echo "Manual gate results — fill after test"
  echo "BOOT_VIDEO=NOT_REVIEWED"
  echo "INPUT=NOT_REVIEWED"
  echo "GRAPHICS_FONT=NOT_REVIEWED"
  echo "PCM_WAV=NOT_REVIEWED"
  echo "MIDI=NOT_REVIEWED"
  echo "TONE=NOT_REVIEWED"
  echo "END_OF_MEDIA=NOT_REVIEWED"
  echo "GAME_SWITCH=NOT_REVIEWED"
  echo "RMS_SAVE_REOPEN=NOT_REVIEWED"
  echo "SHUTDOWN=NOT_REVIEWED"
  echo "OVERALL=NOT_REVIEWED"
  echo ""
  echo "Notes:"
} > "$OUT/results-template.txt"

note "RC1 DEVICE EVIDENCE: snapshot written to $OUT"
note "RC1 DEVICE EVIDENCE: this is evidence collection only; DEVICE-TEST-PASS requires manual real-device review."
