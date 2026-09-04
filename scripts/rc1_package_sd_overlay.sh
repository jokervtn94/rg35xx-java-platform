#!/bin/sh
set -eu

# RGJ-RC1-011BN
# Build an SD-card-root overlay for direct RG35XX installation by file copy/merge.
# This is packaging only and never marks DEVICE-TEST-PASS.

CORE_FILE=${CORE_FILE:-}
RUNTIME_JAR_FILE=${RUNTIME_JAR_FILE:-}
DEVICE_TEST_JAR=${DEVICE_TEST_JAR:-}
SWITCH_PROBE_JAR=${SWITCH_PROBE_JAR:-}
FONT_FILE=${FONT_FILE:-}
SOUNDFONT_FILE=${SOUNDFONT_FILE:-}
OUT=${OUT:-./RG35XX_Java_RC1_SD_Overlay}
MAKE_ZIP=${MAKE_ZIP:-0}

CORE_SHA256=3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58
RUNTIME_JAR_SHA256=f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b
DEVICE_TEST_SHA256=0ec90c9cba4343789ee9bb1a034ef4b3061230a6c1047129162628ebbe31ee9e
SWITCH_PROBE_SHA256=c1a9bd2fbb6cbb5ec90cbf5da31702f58c2421fd4dcf4e97ac6ab99ad0690aa3
FONT_SHA256=7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954
SOUNDFONT_SHA256=9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe

fail() { echo "RC1 SD OVERLAY: ERROR: $*" >&2; exit 1; }
need_file() { [ -n "$1" ] || fail "$2 is not set"; [ -f "$1" ] || fail "$2 missing: $1"; }
sha_file() { sha256sum "$1" | awk '{print $1}'; }
verify() { got=$(sha_file "$1"); [ "$got" = "$2" ] || fail "$3 SHA256 mismatch: got $got expected $2"; }

command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
need_file "$CORE_FILE" CORE_FILE
need_file "$RUNTIME_JAR_FILE" RUNTIME_JAR_FILE
need_file "$DEVICE_TEST_JAR" DEVICE_TEST_JAR
need_file "$SWITCH_PROBE_JAR" SWITCH_PROBE_JAR
verify "$CORE_FILE" "$CORE_SHA256" core
verify "$RUNTIME_JAR_FILE" "$RUNTIME_JAR_SHA256" runtime-jar
verify "$DEVICE_TEST_JAR" "$DEVICE_TEST_SHA256" device-test
verify "$SWITCH_PROBE_JAR" "$SWITCH_PROBE_SHA256" switch-probe

rm -rf "$OUT"
mkdir -p "$OUT/CFW/retroarch/.retroarch/cores" "$OUT/BIOS" "$OUT/Java/runtime" "$OUT/Roms/JAVA"
cp "$CORE_FILE" "$OUT/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so"
cp "$RUNTIME_JAR_FILE" "$OUT/BIOS/freej2me-lr.jar"
cp "$DEVICE_TEST_JAR" "$OUT/Roms/JAVA/RG35XX_RC1_Device_Test.jar"
cp "$SWITCH_PROBE_JAR" "$OUT/Roms/JAVA/RG35XX_RC1_Switch_Probe.jar"

font_state=MISSING
if [ -n "$FONT_FILE" ]; then
  need_file "$FONT_FILE" FONT_FILE
  verify "$FONT_FILE" "$FONT_SHA256" font
  cp "$FONT_FILE" "$OUT/Java/runtime/DejaVuSans.ttf"
  font_state=INCLUDED
fi

soundfont_state=MISSING
if [ -n "$SOUNDFONT_FILE" ]; then
  need_file "$SOUNDFONT_FILE" SOUNDFONT_FILE
  verify "$SOUNDFONT_FILE" "$SOUNDFONT_SHA256" soundfont
  cp "$SOUNDFONT_FILE" "$OUT/Java/runtime/GeneralUser-GS.sf2"
  soundfont_state=INCLUDED
fi

cat > "$OUT/README-CHEP-VAO-THE-NHO.txt" <<EOF
RG35XX Java RC1 — SD-card overlay

Cach cai khong can terminal:
1. Tat RG35XX va thao the nho.
2. Mo file ZIP tren may tinh.
3. Chep/merge TOAN BO cac thu muc CFW, BIOS, Java, Roms vao GOC cua the nho.
4. Chap nhan ghi de core/runtime JAR khi he dieu hanh hoi.
5. Lap the vao RG35XX, vao muc Java va chay RG35XX RC1 Device Test.

JamVM khong nam trong goi nay; giu nguyen runtime hien co tai /mnt/mmc/CFW/java/bin/jamvm.
Font state: $font_state
SoundFont state: $soundfont_state

Neu Font/SoundFont ghi MISSING, goi nay khong thay the bang asset khac. Can co dung file pinned o /mnt/mmc/Java/runtime truoc khi kiem media/font day du.
DEVICE-TEST-PASS chi duoc ghi nhan sau khi test tren may that.
EOF

(
  cd "$OUT"
  find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort | while IFS= read -r f; do sha256sum "$f"; done > SHA256SUMS
)

if [ "$MAKE_ZIP" = "1" ]; then
  command -v zip >/dev/null 2>&1 || fail "zip unavailable"
  parent=$(dirname "$OUT")
  base=$(basename "$OUT")
  (cd "$parent" && rm -f "$base.zip" && zip -qr "$base.zip" "$base")
  echo "RC1 SD OVERLAY: zip=$OUT.zip"
fi

echo "RC1 SD OVERLAY: PASS: $OUT"
echo "RC1 SD OVERLAY: font=$font_state soundfont=$soundfont_state"
