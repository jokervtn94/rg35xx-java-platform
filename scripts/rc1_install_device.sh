#!/bin/sh
set -eu

# RGJ-RC1-011BI / RGJ-RC1-011BM
# Unified device-side installer for the exact RG35XX layout proven by prior device logs.
# Installs the accepted platform payload and direct-device test MIDlets.
# JamVM remains the existing runtime at /mnt/mmc/CFW/java/bin/jamvm.
# This installer never marks DEVICE-TEST-PASS.

ROOT=${ROOT:-$(pwd)}
CORE_SRC="$ROOT/core/freej2me_plus_libretro.so"
JAR_SRC="$ROOT/java/freej2me_plus-lr.jar"
FONT_SRC="$ROOT/Java/runtime/DejaVuSans.ttf"
SOUNDFONT_SRC="$ROOT/Java/runtime/GeneralUser-GS.sf2"
TEST_MAIN_SRC="$ROOT/Roms/JAVA/RG35XX_RC1_Device_Test.jar"
TEST_SWITCH_SRC="$ROOT/Roms/JAVA/RG35XX_RC1_Switch_Probe.jar"

CORE_DST=/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so
JAR_DST=/mnt/mmc/BIOS/freej2me-lr.jar
FONT_DST=/mnt/mmc/Java/runtime/DejaVuSans.ttf
SOUNDFONT_DST=/mnt/mmc/Java/runtime/GeneralUser-GS.sf2
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GAMES=/mnt/mmc/Roms/JAVA
TEST_MAIN_DST="$GAMES/RG35XX_RC1_Device_Test.jar"
TEST_SWITCH_DST="$GAMES/RG35XX_RC1_Switch_Probe.jar"

CORE_SHA256=3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58
JAR_SHA256=f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b
FONT_SHA256=7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954
SOUNDFONT_SHA256=9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe
TEST_MAIN_SHA256=0ec90c9cba4343789ee9bb1a034ef4b3061230a6c1047129162628ebbe31ee9e
TEST_SWITCH_SHA256=c1a9bd2fbb6cbb5ec90cbf5da31702f58c2421fd4dcf4e97ac6ab99ad0690aa3

fail() { echo "RC1 INSTALL: ERROR: $*" >&2; exit 1; }
have_sha256() { command -v sha256sum >/dev/null 2>&1 || { command -v busybox >/dev/null 2>&1 && busybox sha256sum /dev/null >/dev/null 2>&1; }; }
sha256_file() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else busybox sha256sum "$1" | awk '{print $1}'; fi; }
verify() { [ -f "$1" ] || fail "$3 missing: $1"; got=$(sha256_file "$1"); [ "$got" = "$2" ] || fail "$3 SHA256 mismatch: got $got expected $2"; echo "RC1 INSTALL: $3 SHA256 PASS: $got"; }

have_sha256 || fail "sha256sum unavailable"
[ -x "$JAMVM" ] || fail "JamVM missing/not executable: $JAMVM"
mkdir -p "$GAMES" || fail "cannot create Java game directory: $GAMES"

verify "$CORE_SRC" "$CORE_SHA256" core
verify "$JAR_SRC" "$JAR_SHA256" jar
verify "$TEST_MAIN_SRC" "$TEST_MAIN_SHA256" device-test
verify "$TEST_SWITCH_SRC" "$TEST_SWITCH_SHA256" switch-probe

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
  sync
  got=$(sha256_file "$dst")
  [ "$got" = "$expected" ] || fail "$label installed SHA256 mismatch"
  echo "RC1 INSTALL: installed $label -> $dst"
}

ensure_optional_asset()
{
  src=$1
  dst=$2
  expected=$3
  label=$4
  if [ -f "$src" ]; then
    verify "$src" "$expected" "$label"
    install_one "$src" "$dst" "$expected" "$label"
    return
  fi
  if [ -f "$dst" ]; then
    got=$(sha256_file "$dst")
    [ "$got" = "$expected" ] || fail "$label package file absent and installed copy hash mismatches: got $got expected $expected"
    echo "RC1 INSTALL: keeping verified existing $label -> $dst"
    return
  fi
  fail "$label missing from package and device: expected $src or verified $dst"
}

install_one "$CORE_SRC" "$CORE_DST" "$CORE_SHA256" core
install_one "$JAR_SRC" "$JAR_DST" "$JAR_SHA256" jar
ensure_optional_asset "$FONT_SRC" "$FONT_DST" "$FONT_SHA256" font
ensure_optional_asset "$SOUNDFONT_SRC" "$SOUNDFONT_DST" "$SOUNDFONT_SHA256" soundfont
install_one "$TEST_MAIN_SRC" "$TEST_MAIN_DST" "$TEST_MAIN_SHA256" device-test
install_one "$TEST_SWITCH_SRC" "$TEST_SWITCH_DST" "$TEST_SWITCH_SHA256" switch-probe

echo "RC1 INSTALL: PASS"
echo "RC1 INSTALL: core=$CORE_DST"
echo "RC1 INSTALL: jar=$JAR_DST"
echo "RC1 INSTALL: jamvm=$JAMVM"
echo "RC1 INSTALL: device_test=$TEST_MAIN_DST"
echo "RC1 INSTALL: switch_probe=$TEST_SWITCH_DST"
echo "RC1 INSTALL: open the Java menu and run RG35XX RC1 Device Test next."
echo "RC1 INSTALL: DEVICE-TEST-PASS is NOT implied."
