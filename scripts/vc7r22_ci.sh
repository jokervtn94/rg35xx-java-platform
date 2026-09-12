#!/usr/bin/env bash
set -euo pipefail

# Rebuild accepted VC7R21 Java/graphics state.  Its native core is intentionally
# NOT released by this checkpoint because the current source-built audio path is
# not byte-identical to the device-proven Golden/CN core.
bash scripts/vc7r21_ci.sh

OUT="$RUNNER_TEMP/vc7r18"
PG="$OUT/src/org/recompile/mobile/PlatformGraphics.java"
FT="$OUT/src/org/recompile/freej2me/RG35XXGoldenFrameTransport.java"
python3 scripts/vc7r22_apply_hotpath_cleanup.py "$PG" "$FT"

# Production gates: diagnostic sampling/writes must be gone while real error
# reporting stays available.
grep -Fq 'RG35XX-VC7R22-HOTPATH-CLEAN' "$PG"
! grep -Fq 'System.err.println(b.toString())' "$PG"
! grep -Fq 'System.err.println(b.toString())' "$FT"
! grep -Fq 'RG35XX-JAVA-DIAG:' "$FT"
grep -Fq 'RG35XX-VIDEO JAVA worker error' "$FT"
grep -Fq 'RG35XX-VIDEO JAVA control-frame error' "$FT"

(cd "$OUT" && ant)
python3 - "$OUT/build/classes" <<'PY'
import os,struct,sys
n=0
for b,_,fs in os.walk(sys.argv[1]):
  for f in fs:
    if f.endswith('.class'):
      n+=1
      h=open(os.path.join(b,f),'rb').read(8)
      if len(h)!=8 or h[:4]!=b'\xca\xfe\xba\xbe' or struct.unpack('>H',h[6:8])[0]!=50:
        raise SystemExit('VC7R22 Java major gate failed: '+os.path.join(b,f))
print('VC7R22_CLASS_COUNT=%d'%n)
PY

rm -rf /tmp/vc7r22-out
mkdir -p /tmp/vc7r22-out
cp "$OUT/build/freej2me_plus-lr.jar" /tmp/vc7r22-out/freej2me-lr-vc7r22.jar
cp /tmp/vc7r21-out/VC7R21-FONT-MANIFEST.json /tmp/vc7r22-out/VC7R22-FONT-MANIFEST.json

cat > /tmp/vc7r22-out/CORE-POLICY.txt <<'EOF'
VC7R22_CORE_POLICY=EXACT_DEVICE_PROVEN_ONLY
GOLDEN_CORE_SHA256=4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf
CN_CORE_SHA256=9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40
SOURCE_BUILT_VC7R3_AUDIO_CORE=REJECT_FOR_STABLE_AUDIO_RESTORE
CORE_PACKAGED=NO
REASON=current source audio is frame-coupled and not byte-identical to device-proven worker-ring core
EOF

cat > /tmp/vc7r22-out/STATUS.txt <<'EOF'
STATUS=BUILD-PASS-PENDING-CI-AND-DEVICE
CHECKPOINT=VC7R22-GOLDEN-AUDIO-RESTORE-HOTPATH-CLEANUP
JAVA_RUNTIME=VC7R21_PLUS_PRODUCTION_HOTPATH_CLEANUP
VC7R9_IMAGE_PIXEL_SAMPLER=DISABLED
VC7R5_FRAME_COLOR_SAMPLER=DISABLED
FRAME_JAVA_DIAG_PER_FRAME_WRITES=REMOVED
ERROR_DIAGNOSTICS=PRESERVED
VC7R21_LEGACY_WHITEKEY=PRESERVED
VC7R20_PNG_TRNS=PRESERVED
VC7R19_SOFTWARE_TRANSFORMS=PRESERVED
LAZY_MEDIA_BOOT=PRESERVED
AUDIO_CORE=NOT_REBUILT_NOT_PACKAGED
AUDIO_RESTORE_REQUIRED_HASH=GOLDEN_4ba55a_OR_CN_9c248b
DEVICE_TEST=PENDING
EOF

(cd /tmp/vc7r22-out && sha256sum * > SHA256SUMS.txt)
echo 'VC7R22_BUILD=PASS'
echo 'VC7R22_CORE_PACKAGED=NO'
