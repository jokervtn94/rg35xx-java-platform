#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/scripts/build-p2c-input-frontend-candidate.sh"
JAVA8="${JAVA8:-${JAVA_HOME:-}}"
EXACT_PARENT="aa7f84dac5ff24b5fd30fc6158ca3be0327675a0"
# Historical raw JAR SHA from the exact physical package accepted on original RG35XX.
# ZIP/JAR container bytes are not a reproducible rebuild identity because entry timestamps vary.
ACCEPTED_P2B_PHYSICAL_JAR_SHA="6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4"
# Stable semantic digest from accepted P2B host/module artifact 11274023262.
EXPECTED_P2B_SEMANTIC_SHA="4a9419720837c58ff3d3a5ce928e791318eb3c800b452fdd7c2411b536f7348f"
EXPECTED_FONT_NATIVE_SHA="29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b"
EXPECTED_VIDEO_SHA="c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"

semantic_digest() {
  python3 - "$1" <<'PY'
import hashlib,struct,sys,zipfile
h=hashlib.sha256()
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in sorted(z.namelist()):
        b=z.read(n); nb=n.encode('utf-8')
        h.update(struct.pack('>I',len(nb))); h.update(nb)
        h.update(struct.pack('>Q',len(b))); h.update(b)
print(h.hexdigest())
PY
}

[ -n "$JAVA8" ] || { echo 'P2C_R1_V2_FAIL=JAVA8/JAVA_HOME not set' >&2; exit 1; }
[ -f "$BASE" ] || { echo 'P2C_R1_V2_FAIL=base build script missing' >&2; exit 1; }

BACKUP="$(mktemp)"
cp "$BASE" "$BACKUP"
PARENT_DIR="$(mktemp -d)"
rmdir "$PARENT_DIR"
cleanup() {
  cp "$BACKUP" "$BASE" || true
  rm -f "$BACKUP"
  if git -C "$ROOT" worktree list --porcelain | grep -Fqx "worktree $PARENT_DIR"; then
    git -C "$ROOT" worktree remove --force "$PARENT_DIR" >/dev/null 2>&1 || true
  fi
  rm -rf "$PARENT_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Reconstruct the accepted P2B parent only from an exact clean official-main
# worktree. P2C changes to Launcher/dispatcher/input must never participate in
# historical P1/P2A/P2B staging anchors.
git -C "$ROOT" worktree add --detach "$PARENT_DIR" "$EXACT_PARENT"
git -C "$PARENT_DIR" submodule update --init --recursive
test "$(git -C "$PARENT_DIR" rev-parse HEAD)" = "$EXACT_PARENT"
test "$(git -C "$PARENT_DIR/upstream/freej2me-miyoomini" rev-parse HEAD)" = "ca11dfe8ea1cc273d92460f9a83bbf192023fa63"
test -z "$(git -C "$PARENT_DIR" status --porcelain --untracked-files=no)"

echo P2C_R1_V2_PARENT_WORKTREE_IDENTITY=PASS

(
  cd "$PARENT_DIR"
  bash ./scripts/build-a4-raw2d-java.sh
  python3 ./scripts/stage-a6-rg35xx-video-perf-p1.py "$PARENT_DIR"
  python3 ./scripts/stage-a6-rg35xx-video-perf-p2.py "$PARENT_DIR"
  python3 ./scripts/stage-a6-rg35xx-video-perf-p3.py "$PARENT_DIR"
  python3 ./scripts/stage-a6-rg35xx-perf-a1-async-native.py "$PARENT_DIR"
  ./scripts/build-a3.sh native
  bash ./scripts/build-a5-core2d-java.sh
  JAVA8="$JAVA8" bash ./scripts/build-p2b-font-text-candidate-v2.sh | tee /tmp/p2c-r1-v2-parent.log
)

grep -q '^P2B_FONT_TEXT_BUILD=PASS$' /tmp/p2c-r1-v2-parent.log
grep -q '^P2B_MODULE_GATE=PASS$' /tmp/p2c-r1-v2-parent.log
PARENT_OUT="$PARENT_DIR/out/p2b-font-text-candidate-r1"
test -f "$PARENT_OUT/freej2me-rg35xx.jar"
PARENT_RAW_SHA="$(sha256sum "$PARENT_OUT/freej2me-rg35xx.jar" | awk '{print $1}')"
PARENT_SEMANTIC_SHA="$(semantic_digest "$PARENT_OUT/freej2me-rg35xx.jar")"
test "$PARENT_SEMANTIC_SHA" = "$EXPECTED_P2B_SEMANTIC_SHA"
test "$(sha256sum "$PARENT_OUT/librg35xx_font.so" | awk '{print $1}')" = "$EXPECTED_FONT_NATIVE_SHA"
test "$(sha256sum "$PARENT_OUT/librg35xx_video.so" | awk '{print $1}')" = "$EXPECTED_VIDEO_SHA"
echo "P2C_R1_V2_P2B_REBUILT_RAW_JAR_SHA256=$PARENT_RAW_SHA"
echo "P2C_R1_V2_P2B_SEMANTIC_SHA256=$PARENT_SEMANTIC_SHA"
echo "P2C_R1_V2_P2B_PHYSICAL_JAR_SHA256=$ACCEPTED_P2B_PHYSICAL_JAR_SHA"
echo P2C_R1_V2_P2B_SEMANTIC_IDENTITY=PASS

rm -rf "$ROOT/out/p2b-font-text-candidate-r1"
mkdir -p "$ROOT/out/p2b-font-text-candidate-r1"
cp -a "$PARENT_OUT/." "$ROOT/out/p2b-font-text-candidate-r1/"
echo P2C_R1_V2_ACCEPTED_P2B_ISOLATED_REBUILD=PASS

# The base build still owns every P2C semantic/build gate. Replace only its
# parent-reconstruction invocation and non-reproducible raw-JAR rejection.
# The isolated wrapper above has already verified the stable P2B semantic digest
# plus font/video native identities. The base script is restored by the trap.
python3 - "$BASE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old='''# 1. Reconstruct the already accepted P2B runtime lineage exactly.\nJAVA8="$JAVA8" bash "$ROOT/scripts/build-p2b-font-text-candidate-v2.sh" | tee "$OUT/P2C-P2B-PARENT-REBUILD.txt"\ngrep -q '^P2B_FONT_TEXT_BUILD=PASS$' "$OUT/P2C-P2B-PARENT-REBUILD.txt" || fail "P2B parent build"\ngrep -q '^P2B_MODULE_GATE=PASS$' "$OUT/P2C-P2B-PARENT-REBUILD.txt" || fail "P2B parent module gate"\n[ -f "$PARENT_JAR" ] || fail "P2B parent jar missing"\n'''
new='''# 1. Consume the accepted P2B runtime reconstructed and semantic-gated by the V2 isolation wrapper.\nprintf '%s\\n' P2C_P2B_PARENT_REBUILD=PASS P2B_FONT_TEXT_BUILD=PASS P2B_MODULE_GATE=PASS > "$OUT/P2C-P2B-PARENT-REBUILD.txt"\n[ -f "$PARENT_JAR" ] || fail "P2B parent jar missing"\n'''
if s.count(old) != 1:
    raise SystemExit('P2C_R1_V2_PARENT_PATCH_FAIL count=%d' % s.count(old))
s=s.replace(old,new)
raw='''[ "$(sha256sum "$PARENT_JAR" | awk '{print $1}')" = "$EXPECTED_P2B_JAR_SHA" ] || fail "accepted P2B jar identity"'''
replacement='''echo P2C_ACCEPTED_P2B_SEMANTIC_IDENTITY=PASS'''
if s.count(raw) != 1:
    raise SystemExit('P2C_R1_V2_RAW_JAR_GATE_PATCH_FAIL count=%d' % s.count(raw))
s=s.replace(raw,replacement)
identity='''ACCEPTED_P2B_PLATFORM_JAR_SHA256=$EXPECTED_P2B_JAR_SHA'''
identity_new='''ACCEPTED_P2B_PHYSICAL_PACKAGE_JAR_SHA256=$EXPECTED_P2B_JAR_SHA\nACCEPTED_P2B_SEMANTIC_SHA256=4a9419720837c58ff3d3a5ce928e791318eb3c800b452fdd7c2411b536f7348f'''
if s.count(identity) != 1:
    raise SystemExit('P2C_R1_V2_IDENTITY_LABEL_PATCH_FAIL count=%d' % s.count(identity))
s=s.replace(identity,identity_new)
p.write_text(s,encoding='utf-8')
print('P2C_R1_V2_PARENT_ENTRYPOINT_PATCH=PASS')
print('P2C_R1_V2_RAW_JAR_GATE_REPLACED=PASS')
PY

JAVA8="$JAVA8" bash "$BASE"
