#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2A_PHYSICAL_PACKAGE_BUILD_FAIL=$*" >&2; exit 1; }
OUT="$ROOT/out/p2a-image-decode-candidate"
CAND="$OUT/freej2me-rg35xx.jar"
EX="$OUT/RG35XX-Platform-Exerciser-P2A-Image.jar"
INPUT="$OUT/librg35xx_input.so"; VIDEO="$OUT/librg35xx_video.so"
AUDIO="$ROOT/out/p2a-protected-audio/libaudio.so"
MID="$OUT/P2A-MODULE-INTEGRATION-IDENTITY.txt"
CID="$OUT/P2A-IMAGE-DECODE-IDENTITY.txt"
EID="$OUT/P2A-IMAGE-EXERCISER-IDENTITY.txt"
PKGROOT="$OUT/RG35XX-P2A-IMAGE-DECODE-PHYSICAL-R1"
PAYLOAD="$PKGROOT/SD/Roms/APPS/RG35XX-P2A-IMAGE-DECODE"
ZIP="$OUT/RG35XX-P2A-IMAGE-DECODE-PHYSICAL-R1.zip"
HEAD="${GITHUB_SHA:-$(git rev-parse HEAD)}"
EXPECTED_INPUT=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
EXPECTED_VIDEO=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
EXPECTED_AUDIO=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
for f in "$CAND" "$EX" "$INPUT" "$VIDEO" "$AUDIO" "$MID" "$CID" "$EID"; do [ -f "$f" ] || fail "missing $(basename "$f")"; done
EXPECTED_PLATFORM="$(sed -n 's/^CANDIDATE_PLATFORM_JAR_SHA256=//p' "$CID")"
EXPECTED_EX="$(sed -n 's/^EXERCISER_SHA256=//p' "$EID")"
[ -n "$EXPECTED_PLATFORM" ] || fail candidate_identity_hash_missing
[ -n "$EXPECTED_EX" ] || fail exerciser_identity_hash_missing
[ "$(sha256sum "$CAND"|awk '{print $1}')" = "$EXPECTED_PLATFORM" ] || fail candidate_hash
[ "$(sha256sum "$EX"|awk '{print $1}')" = "$EXPECTED_EX" ] || fail exerciser_hash
[ "$(sha256sum "$INPUT"|awk '{print $1}')" = "$EXPECTED_INPUT" ] || fail input_hash
[ "$(sha256sum "$VIDEO"|awk '{print $1}')" = "$EXPECTED_VIDEO" ] || fail video_hash
[ "$(sha256sum "$AUDIO"|awk '{print $1}')" = "$EXPECTED_AUDIO" ] || fail audio_hash

grep -q "^CANDIDATE_HEAD=$HEAD$" "$MID" || fail module_head
grep -q '^HOST_MODULE_GATE=PASS$' "$MID" || fail host_module_gate
grep -q '^COVERAGE_MATRIX_GATE=PASS$' "$MID" || fail coverage_gate
grep -q '^HOST_DIFFERENTIAL_REGRESSIONS=PASS$' "$MID" || fail differential_gate
grep -q '^PNG_FIXTURE_COUNT=150$' "$MID" || fail fixture_count
grep -q '^EXPECTED_DEVICE_DECODES=450$' "$MID" || fail decode_count
grep -q '^A9_PARENT=NO$' "$MID" || fail a9_parent
grep -q '^AUDIT_BRANCH_PARENT=NO$' "$MID" || fail audit_parent
grep -q '^GAME_SPECIFIC_CODE=NO$' "$MID" || fail game_scope
grep -q '^DEVICE-PASS=NO$' "$MID" || fail premature_device_pass

# P2A inherits the accepted lazy A7 audio-loader boundary; this is dependency proof only.
LAUNCHER_STRINGS="$(mktemp)"; trap 'rm -f "$LAUNCHER_STRINGS"' EXIT
unzip -p "$CAND" org/recompile/rg35xx/RG35XXLauncher.class | strings > "$LAUNCHER_STRINGS" || fail candidate_launcher_extract
grep -qx 'libaudio.so' "$LAUNCHER_STRINGS" || fail a7_audio_loader_path_missing
grep -q 'RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER' "$LAUNCHER_STRINGS" || fail a7_audio_loader_marker_missing
echo P2A_A7_AUDIO_LOADER_DEPENDENCY=PROVEN_IN_CANDIDATE

rm -rf "$PKGROOT" "$ZIP"; mkdir -p "$PAYLOAD"
cp "$ROOT/packaging/p2a/RG35XX-P2A-IMAGE-DECODE.sh" "$PKGROOT/SD/Roms/APPS/RG35XX-P2A-IMAGE-DECODE.sh"
cp "$ROOT/packaging/p2a/INSTALL-RG35XX-P2A-IMAGE-DECODE.ps1" "$ROOT/packaging/p2a/COLLECT-RG35XX-P2A-IMAGE-DECODE-EVIDENCE.ps1" "$ROOT/packaging/p2a/README-FIRST.txt" "$PKGROOT/"
python3 - "$PKGROOT/SD/Roms/APPS/RG35XX-P2A-IMAGE-DECODE.sh" "$PKGROOT/INSTALL-RG35XX-P2A-IMAGE-DECODE.ps1" "$PKGROOT/README-FIRST.txt" "$HEAD" "$EXPECTED_PLATFORM" "$EXPECTED_EX" <<'PY'
from pathlib import Path
import sys
launcher,installer,readme,head,platform,ex=sys.argv[1:]
for f in (launcher,installer,readme):
    p=Path(f); s=p.read_text(encoding='utf-8')
    for old,new in [('__P2A_CANDIDATE_HEAD__',head),('__P2A_PLATFORM_SHA256__',platform),('__P2A_EXERCISER_SHA256__',ex)]:
        if old in s: s=s.replace(old,new)
    p.write_text(s,encoding='utf-8')
for f in (launcher,installer,readme):
    s=Path(f).read_text(encoding='utf-8')
    if '__P2A_' in s: raise SystemExit('P2A_PHYSICAL_PLACEHOLDER_FAIL '+f)
PY
cp "$CAND" "$EX" "$INPUT" "$VIDEO" "$AUDIO" "$MID" "$CID" "$EID" "$PAYLOAD/"
chmod +x "$PKGROOT/SD/Roms/APPS/RG35XX-P2A-IMAGE-DECODE.sh"
cat > "$PAYLOAD/PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2A_IMAGE_DECODE
PACKAGE=RG35XX-P2A-IMAGE-DECODE-PHYSICAL-R1
CANDIDATE_HEAD=$HEAD
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
EXACT_RUNTIME_PARENT=7c0ae595fa05dd3c23157c241cc641e8d43411d5
CANDIDATE_PLATFORM_JAR_SHA256=$EXPECTED_PLATFORM
EXERCISER_SHA256=$EXPECTED_EX
INPUT_NATIVE_SHA256=$EXPECTED_INPUT
VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
HOST_MODULE_GATE=PASS
PHYSICAL_TEST_LEVEL=MODULE
PHYSICAL_ACCEPTANCE_SURFACE=ONE_P2A_IMAGE_DECODE_EXERCISER
DECLARED_IMAGE_FORMAT=PNG
PNG_FIXTURE_COUNT=150
EXPECTED_DEVICE_DECODES=450
RUNTIME_HASH_LOGGING=REQUIRED_AND_IMPLEMENTED_BY_LAUNCHER
CASE_LOGGING=REQUIRED_AND_IMPLEMENTED
A7_AUDIO_LOADER_DEPENDENCY=PROVEN_IN_CANDIDATE_AND_PROTECTED_LIBAUDIO_INCLUDED
EVIDENCE_DIRECTORY=/mnt/mmc/RG35XX-P2A-IMAGE-DECODE-EVIDENCE
NORMAL_RETURN_TO_GARLICOS=REQUIRED_MANUAL_OBSERVATION
HUMAN_PHYSICAL_OBSERVATION=FINAL_AUTHORITY
A8_PRODUCTION_PATH_REPLACED=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
DEVICE_PASS=NO_PENDING_PHYSICAL_ACCEPTANCE
STABLE=NO
EOF_ID
(cd "$PAYLOAD" && sha256sum freej2me-rg35xx.jar RG35XX-Platform-Exerciser-P2A-Image.jar librg35xx_input.so librg35xx_video.so libaudio.so P2A-MODULE-INTEGRATION-IDENTITY.txt P2A-IMAGE-DECODE-IDENTITY.txt P2A-IMAGE-EXERCISER-IDENTITY.txt PHYSICAL-PACKAGE-IDENTITY.txt > PAYLOAD-SHA256SUMS.txt)
python3 - "$PKGROOT" "$ZIP" <<'PY'
import os,sys,zipfile
root,out=sys.argv[1:]; base=os.path.dirname(root)
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for dp,ds,fs in os.walk(root):
        ds.sort();fs.sort()
        for f in fs:
            p=os.path.join(dp,f);z.write(p,os.path.relpath(p,base))
PY
ZIP_SHA="$(sha256sum "$ZIP"|awk '{print $1}')"
cat > "$OUT/P2A-PHYSICAL-PACKAGE-IDENTITY.txt" <<EOF_OUT
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2A_IMAGE_DECODE
PACKAGE_FILE=RG35XX-P2A-IMAGE-DECODE-PHYSICAL-R1.zip
PACKAGE_SHA256=$ZIP_SHA
CANDIDATE_HEAD=$HEAD
CANDIDATE_PLATFORM_JAR_SHA256=$EXPECTED_PLATFORM
EXERCISER_SHA256=$EXPECTED_EX
INPUT_NATIVE_SHA256=$EXPECTED_INPUT
VIDEO_NATIVE_SHA256=$EXPECTED_VIDEO
AUDIO_NATIVE_SHA256=$EXPECTED_AUDIO
HOST_MODULE_GATE=PASS
PHYSICAL_PACKAGE_GATE=PASS
A7_AUDIO_LOADER_DEPENDENCY=PASS_PROVEN_IN_CANDIDATE_AND_PROTECTED_LIBAUDIO_INCLUDED
RUNTIME_HASH_LOGGING=PASS_CONTRACT
ONE_EVIDENCE_DIRECTORY=PASS_CONTRACT
NORMAL_EXIT_CHECK=PASS_CONTRACT_PENDING_DEVICE
HUMAN_PHYSICAL_OBSERVATION=REQUIRED
DEVICE_PASS=NO
STABLE=NO
EOF_OUT
echo "P2A_PHYSICAL_PACKAGE_SHA256=$ZIP_SHA"
echo P2A_PHYSICAL_PACKAGE_BUILD=PASS
cat "$OUT/P2A-PHYSICAL-PACKAGE-IDENTITY.txt"
