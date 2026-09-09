#!/bin/sh
set -eu

# B5 — Canonical RG35XX SD staging
# Inputs are explicit and fail-closed. This script never mutates a mounted SD card.
# It creates a deterministic staging tree that B6 installer/recovery tooling can consume.

JAMVM=${B5_INPUT_JAMVM:-}
GLIBJ=${B5_INPUT_GLIBJ:-}
RUNTIME=${B5_INPUT_RUNTIME:-}
CORE=${B5_INPUT_CORE:-}
OUT=${B5_OUTPUT_DIR:-}

REQ_JAMVM_SHA=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
REQ_GLIBJ_SHA=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
REQ_RUNTIME_SHA=e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed
REQ_CORE_SHA=56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
B3_RUNTIME_CONTENT_SHA=52e809ecf5d23f4c2c0989075270680248299bbc02e7cb8ca665bee002942783
FREEJ2ME_PIN=13ec186903087156c145268f8706eecfaf9f1e50
TOOLCHAIN_DIGEST=sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e

fail() { echo "B5 FAIL: $*" >&2; exit 1; }
sha() { sha256sum "$1" | awk '{print $1}'; }
require_file() { [ -n "$1" ] || fail "$2 is not set"; [ -f "$1" ] || fail "$2 missing: $1"; }
check_sha() { actual=$(sha "$1"); [ "$actual" = "$2" ] || fail "$3 SHA mismatch: expected=$2 actual=$actual file=$1"; }

require_file "$JAMVM" B5_INPUT_JAMVM
require_file "$GLIBJ" B5_INPUT_GLIBJ
require_file "$RUNTIME" B5_INPUT_RUNTIME
require_file "$CORE" B5_INPUT_CORE
[ -n "$OUT" ] || fail "B5_OUTPUT_DIR is not set"

check_sha "$JAMVM" "$REQ_JAMVM_SHA" JamVM-L
check_sha "$GLIBJ" "$REQ_GLIBJ_SHA" glibj
check_sha "$RUNTIME" "$REQ_RUNTIME_SHA" B4-runtime
check_sha "$CORE" "$REQ_CORE_SHA" B4-core

rm -rf "$OUT"
mkdir -p \
  "$OUT/CFW/java/bin" \
  "$OUT/CFW/java/share/classpath" \
  "$OUT/CFW/java/share/freej2me" \
  "$OUT/CFW/retroarch/.retroarch/cores" \
  "$OUT/CFW/retroarch/.retroarch/system" \
  "$OUT/CFW/retroarch/system" \
  "$OUT/BIOS" \
  "$OUT/manifests"

# One source payload fans out to every historically observed alias.
cp "$JAMVM" "$OUT/CFW/java/bin/jamvm"
cp "$GLIBJ" "$OUT/CFW/java/share/classpath/glibj.zip"

cp "$CORE" "$OUT/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so"
cp "$CORE" "$OUT/CFW/retroarch/.retroarch/cores/freej2me_libretro.so"

cp "$RUNTIME" "$OUT/BIOS/freej2me-lr.jar"
cp "$RUNTIME" "$OUT/BIOS/freej2me_plus-lr.jar"
cp "$RUNTIME" "$OUT/CFW/java/share/freej2me/freej2me-lr.jar"
cp "$RUNTIME" "$OUT/CFW/retroarch/.retroarch/system/freej2me-lr.jar"
cp "$RUNTIME" "$OUT/CFW/retroarch/system/freej2me-lr.jar"

chmod 0755 "$OUT/CFW/java/bin/jamvm"
chmod 0644 \
  "$OUT/CFW/java/share/classpath/glibj.zip" \
  "$OUT/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so" \
  "$OUT/CFW/retroarch/.retroarch/cores/freej2me_libretro.so" \
  "$OUT/BIOS/freej2me-lr.jar" \
  "$OUT/BIOS/freej2me_plus-lr.jar" \
  "$OUT/CFW/java/share/freej2me/freej2me-lr.jar" \
  "$OUT/CFW/retroarch/.retroarch/system/freej2me-lr.jar" \
  "$OUT/CFW/retroarch/system/freej2me-lr.jar"

# Verify alias identity after staging.
[ "$(sha "$OUT/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so")" = "$REQ_CORE_SHA" ] || fail "core plus alias mismatch"
[ "$(sha "$OUT/CFW/retroarch/.retroarch/cores/freej2me_libretro.so")" = "$REQ_CORE_SHA" ] || fail "core alias mismatch"
for f in \
  "$OUT/BIOS/freej2me-lr.jar" \
  "$OUT/BIOS/freej2me_plus-lr.jar" \
  "$OUT/CFW/java/share/freej2me/freej2me-lr.jar" \
  "$OUT/CFW/retroarch/.retroarch/system/freej2me-lr.jar" \
  "$OUT/CFW/retroarch/system/freej2me-lr.jar"
do
  [ "$(sha "$f")" = "$REQ_RUNTIME_SHA" ] || fail "runtime alias mismatch: $f"
done

cat > "$OUT/STATUS.txt" <<EOF
RG35XX VERIFIED CLEAN B5 CANONICAL SD TREE
STATUS=STAGING-PASS-DEVICE-ACCEPTANCE-PENDING
FREEJ2ME_PIN=$FREEJ2ME_PIN
TOOLCHAIN_DIGEST=$TOOLCHAIN_DIGEST
JAMVM_L_SHA256=$REQ_JAMVM_SHA
GLIBJ_SHA256=$REQ_GLIBJ_SHA
B3_RUNTIME_CONTENT_SHA256=$B3_RUNTIME_CONTENT_SHA
B4_RUNTIME_FILE_SHA256=$REQ_RUNTIME_SHA
B4_CORE_SHA256=$REQ_CORE_SHA
EARLY_NATIVE_LOG=/mnt/mmc/freej2me-vc3-early.log
PNG_COMPAT=NOT_ADMITTED
FONT_REWORK=NOT_ADMITTED
AUDIO_REWORK=NOT_ADMITTED
EOF

cat > "$OUT/manifests/CANONICAL-TARGETS.txt" <<'EOF'
CFW/java/bin/jamvm
CFW/java/share/classpath/glibj.zip
CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so
CFW/retroarch/.retroarch/cores/freej2me_libretro.so
BIOS/freej2me-lr.jar
BIOS/freej2me_plus-lr.jar
CFW/java/share/freej2me/freej2me-lr.jar
CFW/retroarch/.retroarch/system/freej2me-lr.jar
CFW/retroarch/system/freej2me-lr.jar
EOF

(
  cd "$OUT"
  find . -type f ! -path './manifests/SHA256SUMS.txt' -print0 \
    | sort -z \
    | xargs -0 sha256sum
) > "$OUT/manifests/SHA256SUMS.txt"

# Final self-check of the manifest without hashing the manifest itself.
(
  cd "$OUT"
  sha256sum -c manifests/SHA256SUMS.txt >/dev/null
) || fail "manifest verification failed"

echo "B5 PASS: canonical SD staging created at $OUT"
echo "B5 JAMVM=$REQ_JAMVM_SHA"
echo "B5 GLIBJ=$REQ_GLIBJ_SHA"
echo "B5 RUNTIME=$REQ_RUNTIME_SHA"
echo "B5 CORE=$REQ_CORE_SHA"
