#!/bin/sh
OUT=/mnt/mmc/RG35XX-MIYOO-M1.14-R4C-RESULT.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm; GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip; FONTJAR=/mnt/mmc/BIOS/freej2me-lr.jar
EXP=20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9
SHOT=/mnt/mmc/RG35XX-MIYOO-M1.14-R4C-SCREENSHOT.bmp; META=/mnt/mmc/RG35XX-MIYOO-M1.14-R4C-LIVE-FRAME.txt
rm -f "$SHOT" "$META"; : >"$OUT"
echo 'RG35XX M1.14-r4C UNDERLINE ONLY AB' >>"$OUT"; echo M1_14_R4C_PRIMARY_VARIABLE=UNDERLINE_RASTER_ONLY >>"$OUT"; echo M1_14_R4C1_PACKAGING_FIX=M19_LAUNCHER_CLASSES_ONLY >>"$OUT"; echo M1_14_R4A_BOLD_BASELINE=PRESERVED_DEVICE_PASS >>"$OUT"; echo M1_14_R4B_ITALIC_BASELINE=PRESERVED_DEVICE_PASS >>"$OUT"; echo M1_14_RESOURCE_CLASSIFICATION=EXPERIMENTAL_NOT_GOLDEN >>"$OUT"
TMP=/tmp/m114r4c-font.bin; unzip -p "$FONTJAR" org/recompile/mobile/rg35xx-font.bin >"$TMP" 2>/dev/null || true; FS=$(wc -c <"$TMP"|tr -d ' '); FH=$(sha256sum "$TMP"|awk '{print $1}'); echo M1_14_FONT_SIZE=$FS >>"$OUT"; echo M1_14_FONT_SHA256=$FH >>"$OUT"; [ "$FS" = 727008 ] && [ "$FH" = "$EXP" ] || { echo M1_14_RESOURCE_GATE=FAIL_CLOSED >>"$OUT"; exit 22; }; echo M1_14_RESOURCE_GATE=PASS_EXPERIMENTAL_20C2 >>"$OUT"
JB=$(sha256sum "$JAMVM"|awk '{print $1}'); GB=$(sha256sum "$GLIBJ"|awk '{print $1}'); echo JAMVM_SHA256_BEFORE=$JB >>"$OUT"; echo GLIBJ_SHA256_BEFORE=$GB >>"$OUT"
LD_LIBRARY_PATH="$APP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$JAMVM" -Xmx64m -cp "$GLIBJ:$APP/m1.14-r4c-freej2me-platform.jar:$FONTJAR" org.recompile.mobile.M19CanvasLifecycleLauncher "$APP/m1.14-r4c-underline-only.jar" >>"$OUT" 2>&1
RC=$?; echo JAMVM_EXIT_CODE=$RC >>"$OUT"; JA=$(sha256sum "$JAMVM"|awk '{print $1}'); GA=$(sha256sum "$GLIBJ"|awk '{print $1}'); echo JAMVM_SHA256_AFTER=$JA >>"$OUT"; echo GLIBJ_SHA256_AFTER=$GA >>"$OUT"; [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && echo M1_14_R4C_PROTECTED_HASHES=PASS >>"$OUT" || echo M1_14_R4C_PROTECTED_HASHES=FAIL >>"$OUT"
if [ -s "$SHOT" ] && [ -s "$META" ]; then echo M1_14_R4C_SCREENSHOT_GATE=PASS >>"$OUT"; echo M1_14_R4C_SCREENSHOT_SHA256=$(sha256sum "$SHOT"|awk '{print $1}') >>"$OUT"; cat "$META" >>"$OUT"; else echo M1_14_R4C_SCREENSHOT_GATE=FAIL >>"$OUT"; fi
grep -q 'M1_14_R4C_UNDERLINE_STYLE=4' "$OUT" && grep -q 'M1_14_R4C_NORMAL_EXIT=PASS' "$OUT" && grep -q 'M1_14_R4C_SCREENSHOT_GATE=PASS' "$OUT" && echo M1_14_R4C_RUNTIME_GATE=PASS >>"$OUT" || echo M1_14_R4C_RUNTIME_GATE=FAIL >>"$OUT"
echo DEVICE_PASS=NO_VISUAL_REVIEW_PENDING >>"$OUT"; echo FULL_PLATFORM_STABLE=NO >>"$OUT"; sync
