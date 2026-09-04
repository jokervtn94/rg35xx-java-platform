#!/bin/sh
set -eu

# RGJ-RC1-011BN / 011BP / 011BQ / 011BT
# Build an SD-card-root overlay for direct RG35XX installation by file copy/merge.
# This is packaging only and never marks DEVICE-TEST-PASS.

CORE_FILE=${CORE_FILE:-}
RUNTIME_JAR_FILE=${RUNTIME_JAR_FILE:-}
DEVICE_TEST_JAR=${DEVICE_TEST_JAR:-}
SWITCH_PROBE_JAR=${SWITCH_PROBE_JAR:-}
BOOT_PROBE_JAR=${BOOT_PROBE_JAR:-}
FONT_FILE=${FONT_FILE:-}
SOUNDFONT_FILE=${SOUNDFONT_FILE:-}
OUT=${OUT:-./RG35XX_Java_RC1_SD_Overlay}
MAKE_ZIP=${MAKE_ZIP:-0}

# Accepted 011BR diagnostic consolidated build (run 33904619868).
CORE_SHA256=a506e202e3586293fb7e1a2fbc0c291af8611dc8def282813eff21fccd683929
RUNTIME_JAR_SHA256=ea145eb7e1f891a08624f45f4cd06e402bd4683cdf47a2b2cc0a39390a39f8a2
DEVICE_TEST_SHA256=dc99dd5a777dc68d45f3aef543b211d9dc6bddc6ddfa79f5cd30a0ea1859e773
SWITCH_PROBE_SHA256=c1a9bd2fbb6cbb5ec90cbf5da31702f58c2421fd4dcf4e97ac6ab99ad0690aa3
BOOT_PROBE_SHA256=7a93146eae3f60305cfce65f9a24ade6877f11ddd5dd3e76974fd6aae30cae3c
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
mkdir -p "$OUT/CFW/retroarch/.retroarch/cores" "$OUT/BIOS" "$OUT/Java/runtime" "$OUT/Java/test-evidence" "$OUT/Roms/JAVA"

# 011BT: deploy both core basenames. Historical RG35XX installs used the _plus
# basename, while some menu/playlist variants may still reference the old name.
cp "$CORE_FILE" "$OUT/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so"
cp "$CORE_FILE" "$OUT/CFW/retroarch/.retroarch/cores/freej2me_libretro.so"

# 011BT: the accepted core binary literally requests freej2me_plus-lr.jar.
# Keep freej2me-lr.jar only as a compatibility alias for older cores/scripts.
cp "$RUNTIME_JAR_FILE" "$OUT/BIOS/freej2me_plus-lr.jar"
cp "$RUNTIME_JAR_FILE" "$OUT/BIOS/freej2me-lr.jar"

cp "$DEVICE_TEST_JAR" "$OUT/Roms/JAVA/RG35XX_RC1_Device_Test.jar"
cp "$SWITCH_PROBE_JAR" "$OUT/Roms/JAVA/RG35XX_RC1_Switch_Probe.jar"
if [ -n "$BOOT_PROBE_JAR" ]; then
  need_file "$BOOT_PROBE_JAR" BOOT_PROBE_JAR
  verify "$BOOT_PROBE_JAR" "$BOOT_PROBE_SHA256" boot-probe
  cp "$BOOT_PROBE_JAR" "$OUT/Roms/JAVA/RG35XX_RC1_Boot_Probe.jar"
fi

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
RG35XX Java RC1 — SD-card overlay 011BT

Cach cai khong can terminal:
1. Tat RG35XX va thao the nho.
2. Mo file ZIP tren may tinh.
3. Chep/merge TOAN BO cac thu muc CFW, BIOS, Java, Roms vao GOC cua the nho.
4. Chap nhan ghi de core/runtime JAR khi he dieu hanh hoi.
5. Lap the vao RG35XX, vao muc Java va chay RG35XX RC1 Boot Probe truoc.

Runtime authoritative: /mnt/mmc/BIOS/freej2me_plus-lr.jar
Compatibility alias: /mnt/mmc/BIOS/freej2me-lr.jar
Core aliases are both installed in CFW/retroarch/.retroarch/cores/.
JamVM giu nguyen tai /mnt/mmc/CFW/java/bin/jamvm.
Font state: $font_state
SoundFont state: $soundfont_state
Process log: /mnt/mmc/Java/freej2me-java.log
Boot Probe log: /mnt/mmc/Java/test-evidence/rg35xx-boot-probe.log

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
