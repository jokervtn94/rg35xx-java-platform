#!/bin/sh

OUT=/mnt/mmc/RG35XX-AWEIGIT-R1-A5-CORE-RESULT.txt
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PKG="$APP/RG35XX-AWEIGIT-R1-A5-CORE"
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
DATA="$PKG/data"

: >"$OUT"
echo 'PROJECT=RG35XX-AWEIGIT-R1' >>"$OUT"
echo 'STAGE=A5-CORE-INTEGRATION' >>"$OUT"
echo 'AWEIGIT_COMMIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63' >>"$OUT"
echo 'A5_SCOPE=RESIZE+RESOURCE+IMAGE+TRANSPARENCY+FONT_TEXT+SPRITE_8_TRANSFORMS+COLLISION+TILEDLAYER+LAYERMANAGER+RMS_PERSISTENCE' >>"$OUT"
echo 'AUDIO=HOLD' >>"$OUT"
echo 'MEDIA=HOLD' >>"$OUT"

a5_fail() {
    echo "A5_LAUNCH_PRECONDITION=FAIL:$1" >>"$OUT"
    echo 'DEVICE_PASS=NO' >>"$OUT"
    echo 'STABLE=NO' >>"$OUT"
    sync
    exit 20
}

[ -x "$JAMVM" ] || a5_fail 'JAMVM_MISSING'
[ -f "$GLIBJ" ] || a5_fail 'GLIBJ_MISSING'
[ -d "$PKG" ] || a5_fail 'PAYLOAD_DIR_MISSING'
[ -f "$PKG/freej2me-rg35xx.jar" ] || a5_fail 'PLATFORM_JAR_MISSING'
[ -f "$PKG/rg35xx-a5-core.jar" ] || a5_fail 'CORE_JAR_MISSING'
[ -f "$PKG/librg35xx_input.so" ] || a5_fail 'INPUT_NATIVE_MISSING'
[ -f "$PKG/librg35xx_video.so" ] || a5_fail 'VIDEO_NATIVE_MISSING'
[ -f "$PKG/PAYLOAD-SHA256SUMS.txt" ] || a5_fail 'PAYLOAD_SUMS_MISSING'

JB=$(sha256sum "$JAMVM" | awk '{print $1}')
GB=$(sha256sum "$GLIBJ" | awk '{print $1}')
echo "JAMVM_SHA256_BEFORE=$JB" >>"$OUT"
echo "GLIBJ_SHA256_BEFORE=$GB" >>"$OUT"
[ "$JB" = "$EXPECTED_JAMVM" ] || a5_fail 'JAMVM_HASH_MISMATCH'
[ "$GB" = "$EXPECTED_GLIBJ" ] || a5_fail 'GLIBJ_HASH_MISMATCH'

(
    cd "$PKG" || exit 1
    sha256sum -c PAYLOAD-SHA256SUMS.txt
) >>"$OUT" 2>&1 || a5_fail 'PAYLOAD_HASH_MISMATCH'
echo 'A5_PAYLOAD_HASHES=PASS' >>"$OUT"
mkdir -p "$DATA" || a5_fail 'DATA_DIR_CREATE_FAIL'

run_phase() {
    PHASE="$1"
    echo "A5_PROCESS_PHASE_${PHASE}=START" >>"$OUT"
    LD_LIBRARY_PATH="$PKG${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$JAMVM" -Xmx64m \
        -Drg35xx.raw2d=true \
        -Drg35xx.a5.phase="$PHASE" \
        -Drg35xx.native.dir="$PKG" \
        -cp "$GLIBJ:$PKG/freej2me-rg35xx.jar" \
        org.recompile.rg35xx.RG35XXLauncher \
        "$PKG/rg35xx-a5-core.jar" 240 320 "$DATA" "$DATA" >>"$OUT" 2>&1
    RC=$?
    echo "A5_PHASE_${PHASE}_EXIT_CODE=$RC" >>"$OUT"
    return "$RC"
}

run_phase A
RCA=$?
run_phase B
RCB=$?

JA=$(sha256sum "$JAMVM" | awk '{print $1}')
GA=$(sha256sum "$GLIBJ" | awk '{print $1}')
echo "JAMVM_SHA256_AFTER=$JA" >>"$OUT"
echo "GLIBJ_SHA256_AFTER=$GA" >>"$OUT"
if [ "$JB" = "$JA" ] && [ "$GB" = "$GA" ] && [ "$JA" = "$EXPECTED_JAMVM" ] && [ "$GA" = "$EXPECTED_GLIBJ" ]; then
    echo 'A5_PROTECTED_HASHES=PASS' >>"$OUT"
else
    echo 'A5_PROTECTED_HASHES=FAIL' >>"$OUT"
fi

PROGRAMMATIC=PASS
[ "$RCA" -eq 0 ] || PROGRAMMATIC=FAIL
[ "$RCB" -eq 0 ] || PROGRAMMATIC=FAIL
for MARKER in \
    A5_RESIZE_CANVAS=PASS \
    A5_RESOURCE_STREAM=PASS \
    A5_IMAGE_RGB_ALPHA=PASS \
    A5_IMAGE_RESOURCE_PNG=PASS \
    A5_IMAGE_MUTABLE_COPY=PASS \
    A5_FONT_METRICS_TEXT=PASS \
    A5_SPRITE_TRANSFORMS=PASS \
    A5_SPRITE_COLLISION=PASS \
    A5_TILEDLAYER=PASS \
    A5_LAYERMANAGER=PASS \
    A5_RMS_PHASE_A=PASS \
    A5_PHASE_A_GATE=PASS \
    A5_RMS_PERSISTENCE=PASS \
    A5_PHASE_B_GATE=PASS \
    A5_PROTECTED_HASHES=PASS
do
    grep -q "^${MARKER}$" "$OUT" || PROGRAMMATIC=FAIL
done

echo "A5_CORE_PROGRAMMATIC_RESULT=$PROGRAMMATIC" >>"$OUT"
echo 'DEVICE_PASS=NO_PENDING_REAL_DEVICE_REVIEW' >>"$OUT"
echo 'STABLE=NO' >>"$OUT"
echo 'FULL_PLATFORM_STABLE=NO' >>"$OUT"
sync

[ "$PROGRAMMATIC" = PASS ] && exit 0
exit 2
