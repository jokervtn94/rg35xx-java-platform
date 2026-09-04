#!/bin/sh
set -eu

# RGJ-RC1-011R — GNU Classpath/JamVM JNI machine-header target guard.
# Cross-compiling the runtime with an x86-selected jni_md.h can survive source
# assembly and fail much later with ABI/type problems. Reject that state before
# compile. This script does not choose or rewrite the JNI header; configure/build
# remains the authoritative selector.

: "${RG35XX_RUNTIME_ASSEMBLY_ROOT:?set RG35XX_RUNTIME_ASSEMBLY_ROOT to the disposable GNU Classpath runtime tree}"

fail() { echo "RC1 JNI PREFLIGHT: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 JNI PREFLIGHT: $*"; }

[ -d "$RG35XX_RUNTIME_ASSEMBLY_ROOT" ] || fail "runtime assembly root missing: $RG35XX_RUNTIME_ASSEMBLY_ROOT"

FOUND=0
for link in $(find "$RG35XX_RUNTIME_ASSEMBLY_ROOT" -type l -name jni_md.h -print 2>/dev/null); do
  FOUND=$((FOUND + 1))
  target=$(readlink "$link" || true)
  [ -n "$target" ] || fail "cannot resolve JNI machine-header symlink: $link"
  case "$target" in
    *x86*|*X86*|*i386*|*i486*|*i586*|*i686*|*amd64*|*AMD64*)
      fail "$link selects non-ARM JNI machine header: $target"
      ;;
  esac
  note "JNI symlink accepted: $link -> $target"
done

# Some configured trees copy rather than symlink jni_md.h. If configure records
# an explicitly x86-named source in generated files, reject it as well. Limit the
# scan to generated/configuration files to avoid matching dormant architecture
# headers that legitimately coexist in the Classpath source distribution.
for f in \
  "$RG35XX_RUNTIME_ASSEMBLY_ROOT/config.status" \
  "$RG35XX_RUNTIME_ASSEMBLY_ROOT/config.log" \
  "$RG35XX_RUNTIME_ASSEMBLY_ROOT/Makefile" \
  "$RG35XX_RUNTIME_ASSEMBLY_ROOT/include/Makefile"
do
  [ -f "$f" ] || continue
  if grep -E 'jni_md-(x86|i[3-6]86|amd64)[^[:space:]]*\.h' "$f" >/dev/null 2>&1; then
    fail "generated runtime configuration selects an x86 JNI machine header: $f"
  fi
done

if [ "$FOUND" -eq 0 ]; then
  note "No jni_md.h symlink is materialized yet; generated config files contain no x86 JNI selection."
else
  note "JNI TARGET PREFLIGHT PASS: checked $FOUND materialized jni_md.h symlink(s)."
fi
