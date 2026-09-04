#!/bin/sh
set -eu

# RGJ-RC1-011BI
# Device-side installer for the exact RG35XX layout proven by prior device logs.
# Run from the root of an RC1 device-test package: sh tools/rc1_install_device.sh
# This installs only the accepted core/JAR/font/SoundFont payloads and never
# marks DEVICE-TEST-PASS.

ROOT=${ROOT:-$(pwd)}
CORE_SRC="$ROOT/core/freej2me_plus_libretro.so"
JAR_SRC="$ROOT/java/freej2me_plus-lr.jar"
FONT_SRC="$ROOT/Java/runtime/DejaVuSans.ttf"
SOUNDFONT_SRC="$ROOT/Java/runtime/GeneralUser-GS.sf2"

CORE_DST=/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so
JAR_DST=/mnt/mmc/BIOS/freej2me-lr.jar
FONT_DST=/mnt/mmc/Java/runtime/DejaVuSans.ttf
SOUNDFONT_DST=/mnt/mmc/Java/runtime/GeneralUser-GS.sf2
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GAMES=/mnt/mmc/Roms/JAVA

CORE_SHA256=3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58
JAR_SHA256=f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b
FONT_SHA256=7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954
SOUNDFONT_SHA256=9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe

fail() { echo "RC1 INSTALL: ERROR: $*" >&2; exit 1; }
have_sha256() { command -v sha256sum >/dev/null 2>&1 || { command -v busybox >/dev/null 2>&1 && busybox sha256sum /dev/null >/dev/null 2>&1; }; }
sha256_file() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else busybox sha256sum "$1" | awk '{print $1}'; fi; }
verify() { [ -f "$1" ] || fail "$3 missing: $1"; got=$(sha256_file "$1"); [ "$got" = "$2" ] || fail "$3 SHA256 mismatch: got $got expected $2"; echo "RC1 INSTALL: $3 SHA256 PASS: $got"; }

have_sha256 || fail "sha256sum unavailable"
[ -x "$JAMVM" ] || fail "JamVM missing/not executable: $JAMVM"
[ -d "$GAMES" ] || fail "Java game directory missing: $GAMES"

verify "$CORE_SRC" "$CORE_SHA256" core
verify "$JAR_SRC" "$JAR_SHA256" jar
verify "$FONT_SRC" "$FONT_SHA256" font
verify "$SOUNDFONT_SRC" "$SOUNDFONT_SHA256" soundfont

backup_once()
{
  dst=$1
  if [ -f "$dst" ] && [ ! -f "$dst.pre-rc1" ]; then
    cp "$dst" "$dst.pre-rc1" || fail "backup failed: $dst"
    sync
    echo "RC1 INSTALL: backup: $dst.pre-rc1"
  fi
}

install_one()
{
  src=$1
  dst=$2
  expected=$3
  label=$4
  dir=$(dirname "$dst")
  mkdir -p "$dir" || fail "cannot create $dir"
  backup_once "$dst"
  tmp="$dst.rc1-new"
  rm -f "$tmp"
  cp "$src" "$tmp" || fail "copy failed: $label"
  sync
  got=$(sha256_file "$tmp")
  [ "$got" = "$expected" ] || { rm -f "$tmp"; fail "$label staged SHA256 mismatch"; }
  mv "$tmp" "$dst" || fail "replace failed: $label"
  chmod 755 "$dst" 2>/dev/null || true
  sync
  got=$(sha256_file "$dst")
  [ "$got" = "$expected" ] || fail "$label installed SHA256 mismatch"
  echo "RC1 INSTALL: installed $label -> $dst"
}

install_one "$CORE_SRC" "$CORE_DST" "$CORE_SHA256" core
install_one "$JAR_SRC" "$JAR_DST" "$JAR_SHA256" jar
install_one "$FONT_SRC" "$FONT_DST" "$FONT_SHA256" font
install_one "$SOUNDFONT_SRC" "$SOUNDFONT_DST" "$SOUNDFONT_SHA256" soundfont

echo "RC1 INSTALL: PASS"
echo "RC1 INSTALL: core=$CORE_DST"
echo "RC1 INSTALL: jar=$JAR_DST"
echo "RC1 INSTALL: jamvm=$JAMVM"
echo "RC1 INSTALL: games=$GAMES"
echo "RC1 INSTALL: DEVICE-TEST-PASS is NOT implied; run real-device validation next."
