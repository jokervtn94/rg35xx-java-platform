#!/bin/sh
set -eu

# RGJ-RC1-011N/011R/011AC/011BC/011BD/011BR/011BU deterministic assembly driver.
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PIN_FREEJ2ME="13ec186903087156c145268f8706eecfaf9f1e50"
: "${RG35XX_FREEJ2ME_ROOT:?set RG35XX_FREEJ2ME_ROOT to the pinned FreeJ2ME checkout}"
: "${RG35XX_ASSEMBLY_ROOT:?set RG35XX_ASSEMBLY_ROOT to a disposable output directory}"
: "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to a disposable GNU Classpath 0.99 source tree}"
: "${RG35XX_FONT_FILE:?set RG35XX_FONT_FILE to materialized DejaVuSans.ttf}"
: "${RG35XX_FONT_SHA256:?set RG35XX_FONT_SHA256 to the recorded SHA-256 for the exact DejaVuSans.ttf input}"
: "${RG35XX_FONT_RUNTIME_PATH:?set RG35XX_FONT_RUNTIME_PATH to the absolute target-device DejaVuSans.ttf path}"
: "${RG35XX_SOUNDFONT_FILE:?set RG35XX_SOUNDFONT_FILE to the pinned GeneralUser-GS.sf2 input}"
fail() { echo "RC1 ASSEMBLY: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 ASSEMBLY: $*"; }

[ -d "$RG35XX_FREEJ2ME_ROOT/.git" ] || fail "FreeJ2ME root is not a Git checkout"
HEAD=$(git -C "$RG35XX_FREEJ2ME_ROOT" rev-parse HEAD)
[ "$HEAD" = "$PIN_FREEJ2ME" ] || fail "FreeJ2ME HEAD $HEAD != pinned $PIN_FREEJ2ME"
[ "$RG35XX_ASSEMBLY_ROOT" != "$RG35XX_FREEJ2ME_ROOT" ] || fail "assembly root must not be the upstream checkout"
[ "$RG35XX_CLASSPATH_ROOT" != "$RG35XX_FREEJ2ME_ROOT" ] || fail "Classpath tree must be separate from FreeJ2ME"
[ "$RG35XX_CLASSPATH_ROOT" != "$RG35XX_ASSEMBLY_ROOT" ] || fail "Classpath tree must be separate from FreeJ2ME assembly output"
sh "$ROOT/scripts/rc1_prebuild_gate.sh" --build-ready

sh "$ROOT/scripts/rc1_classpath_preflight.sh"
sh "$ROOT/runtime/classpath/apply_rg35xx_font_overlay.sh"

grep -q 'new OpenTypeFontPeer(logical, attrKey)' \
  "$RG35XX_CLASSPATH_ROOT/gnu/java/awt/peer/headless/HeadlessToolkit.java" \
  || fail "GNU Classpath font overlay was not materialized"
grep -q 'throw new RuntimeException("RG35XX: unable to initialize OpenType font peer", ex);' \
  "$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/OpenTypeFontPeer.java" \
  || fail "GNU Classpath OpenType constructor is not fail-closed"

rm -rf "$RG35XX_ASSEMBLY_ROOT" && mkdir -p "$RG35XX_ASSEMBLY_ROOT"
( cd "$RG35XX_FREEJ2ME_ROOT" && tar --exclude=.git -cf - . ) | ( cd "$RG35XX_ASSEMBLY_ROOT" && tar -xf - )

mkdir -p "$RG35XX_ASSEMBLY_ROOT/src/org/recompile/mobile"
for src in "$ROOT"/src/org/recompile/mobile/RG35XX*.java; do [ -f "$src" ] && cp "$src" "$RG35XX_ASSEMBLY_ROOT/src/org/recompile/mobile/"; done
[ ! -e "$RG35XX_ASSEMBLY_ROOT/src/org/recompile/mobile/RG35XXFontEngine.java" ] || fail "superseded RG35XXFontEngine was assembled"

NATIVE_DST="$RG35XX_ASSEMBLY_ROOT/src/libretro/rg35xx"
mkdir -p "$NATIVE_DST/vendor/TinySoundFont"
for f in \
 rg35xx_audio_protocol.h rg35xx_media_cache.h rg35xx_media_cache.c rg35xx_media_events.h \
 rg35xx_media_event_queue.h rg35xx_media_event_queue.c rg35xx_audio_dispatch.h rg35xx_audio_dispatch.c \
 rg35xx_audio_pipe.h rg35xx_audio_pipe.c rg35xx_mixer.h rg35xx_mixer.c \
 rg35xx_midi_backend.h rg35xx_midi_backend.c rg35xx_tsf_worker.h rg35xx_tsf_worker.c \
 rg35xx_tsf_impl.c rg35xx_soundfont_source.h rg35xx_soundfont_source.c rg35xx_media_runtime.h rg35xx_media_runtime.c
do cp "$ROOT/native/$f" "$NATIVE_DST/$f"; done
cp "$ROOT/native/vendor/TinySoundFont/tml.h" "$NATIVE_DST/vendor/TinySoundFont/tml.h"
cp "$ROOT/native/vendor/TinySoundFont/tsf.h" "$NATIVE_DST/vendor/TinySoundFont/tsf.h"

# Authoritative active source-mutation order.
# Superseded historical contracts: 0004->0016, 0005->0010/0017,
# 0006->0018, 0014->0017/0018, 0009->0021 policy baseline, 0012/0013->0020.
# 0021 is intentionally NOT applied: it verifies that pinned upstream synchronous
# multi-file RecordStore remains authoritative and requires no source mutation.
# 0022 is materialized by the Classpath overlay above.
# 0017 is intentionally applied before 0015: it establishes graceful EOF and
# event helpers; 0015 owns subsequent mixer/runtime init/reset/close against that
# already-defined process boundary.
# 0023 is diagnostics-only and persists JamVM stderr before the first frame.
# 0024 is applied after 0023 and replaces PATH-dependent execvp("java") with the
# validated absolute RG35XX JamVM executable path.
PATCH_ORDER="
0003-manager-rg35xx-media-profile.patch
0007-platformgraphics-rg35xx-fast-drawrgb.patch
0008-platformgraphics-transform-cache.patch
0010-libretro-platform-lifecycle.patch
0011-platformimage-rg35xx-cache.patch
0016-libretro-java-audio-fd-exact.patch
0017-libretro-media-process-boundary.patch
0015-libretro-native-media-runtime.patch
0018-manager-platformplayer-rg35xx-direct-media.patch
0019-platformplayer-tonecontrol-rg35xx.patch
0020-pinned-graphics-input-lifecycle-consolidation.patch
0023-libretro-persistent-jamvm-stderr.patch
0024-libretro-absolute-jamvm-launcher.patch
"

normalize_patch_targets()
{
  patch_file="$1"
  awk '/^--- a\// { sub(/^--- a\//, ""); print }' "$patch_file" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    target="$RG35XX_ASSEMBLY_ROOT/$rel"
    [ -f "$target" ] || fail "patch target missing before normalization: $rel"
    sed -i 's/\r$//' "$target"
  done
}

apply_patch_strict()
{
  patch_file="$1"
  patch_name="$2"
  dry_log="$RG35XX_ASSEMBLY_ROOT/.rc1-${patch_name}.dry.log"
  apply_log="$RG35XX_ASSEMBLY_ROOT/.rc1-${patch_name}.apply.log"

  if ! patch -d "$RG35XX_ASSEMBLY_ROOT" -p1 --batch --forward --fuzz=0 --dry-run \
      < "$patch_file" >"$dry_log" 2>&1; then
    cat "$dry_log" >&2
    fail "zero-fuzz dry-run failed: $patch_name"
  fi
  if grep -Eiq 'reversed|previously applied|skipping patch|ignored|FAILED|reject' "$dry_log"; then
    cat "$dry_log" >&2
    fail "zero-fuzz dry-run reported skipped/reversed/rejected hunk: $patch_name"
  fi

  if ! patch -d "$RG35XX_ASSEMBLY_ROOT" -p1 --batch --forward --fuzz=0 \
      < "$patch_file" >"$apply_log" 2>&1; then
    cat "$apply_log" >&2
    fail "zero-fuzz apply failed: $patch_name"
  fi
  if grep -Eiq 'reversed|previously applied|skipping patch|ignored|FAILED|reject' "$apply_log"; then
    cat "$apply_log" >&2
    fail "zero-fuzz apply reported skipped/reversed/rejected hunk: $patch_name"
  fi
}

for p in $PATCH_ORDER; do
 [ -f "$ROOT/patches/$p" ] || fail "missing integration contract: $p"
 normalize_patch_targets "$ROOT/patches/$p"
 apply_patch_strict "$ROOT/patches/$p" "$p"
done
[ -f "$ROOT/patches/0021-pinned-rms-safe-baseline.patch" ] || fail "missing verified pinned RMS policy baseline 0021"
[ -f "$ROOT/patches/0022-pinned-headless-font-peer-consolidation.patch" ] || fail "missing GNU Classpath font contract 0022"

CORE_C="$RG35XX_ASSEMBLY_ROOT/src/libretro/freej2me_libretro.c"
grep -q '^#define NUM_ARGUMENTS 9$' "$CORE_C" || fail "assembled core missing 0016 NUM_ARGUMENTS 9"
grep -q -- '-Dfreej2me.rg35xx=true' "$CORE_C" || fail "assembled core missing RG35XX JVM selector"
grep -q -- '-Dfreej2me.rg35xx.audio.fd=%d' "$CORE_C" || fail "assembled core missing dedicated audio-FD JVM property"
[ "$(grep -Fxc 'static struct rg35xx_audio_pipe rg35xx_java_audio_pipe = { -1, -1 };' "$CORE_C")" = 1 ] || fail "assembled core fail-closed audio-pipe declaration count is not one"
grep -q 'rg35xx_audio_pipe_create(&rg35xx_java_audio_pipe)' "$CORE_C" || fail "assembled core missing dedicated audio pipe creation"
grep -q 'rg35xx_mixer_init(rg35xx_core_media_event);' "$CORE_C" || fail "assembled core missing native mixer init hook"
[ "$(grep -Fxc '			rg35xx_audio_drain_start();' "$CORE_C")" = 1 ] || fail "assembled core audio drain start call count is not one"
awk '
  /rg35xx_audio_pipe_parent_after_fork\(&rg35xx_java_audio_pipe\);/ { parent = NR }
  /rg35xx_audio_drain_start\(\);/ { drain = NR }
  END { exit !(parent > 0 && drain == parent + 1) }
' "$CORE_C" || fail "assembled core audio drain start is not immediately after parent audio-pipe handoff"
grep -q 'rg35xx_native_media_shutdown();' "$CORE_C" || fail "assembled core missing final native media shutdown hook"
grep -Fq 'fopen("/mnt/mmc/Java/freej2me-java.log", "a")' "$CORE_C" || fail "assembled core missing persistent JamVM diagnostic path"
grep -Fq 'dup2(rg35xx_java_log_fd, 2)' "$CORE_C" || fail "assembled core missing stderr-only diagnostic redirect"
if grep -Fq 'dup2(rg35xx_java_log_fd, 1)' "$CORE_C"; then fail "diagnostic log must never replace binary stdout video IPC"; fi
grep -Fq '"/mnt/mmc/CFW/java/bin/jamvm"' "$CORE_C" || fail "assembled core missing absolute RG35XX JamVM path"
grep -Fq 'execv(rg35xx_jamvm_path, params);' "$CORE_C" || fail "assembled core missing absolute JamVM execv"
if grep -Fq 'execvp(cmd, params);' "$CORE_C"; then fail "assembled core still contains PATH-dependent java execvp"; fi
grep -Fq 'RG35XX execv failed for %s: errno=%d (%s)' "$CORE_C" || fail "assembled core missing JamVM execv failure diagnostic"

cat > "$NATIVE_DST/rc1_sources.mk" <<'EOF'
RG35XX_NATIVE_SRCS := \
  rg35xx/rg35xx_media_cache.c \
  rg35xx/rg35xx_media_event_queue.c \
  rg35xx/rg35xx_audio_dispatch.c \
  rg35xx/rg35xx_audio_pipe.c \
  rg35xx/rg35xx_mixer.c \
  rg35xx/rg35xx_midi_backend.c \
  rg35xx/rg35xx_tsf_worker.c \
  rg35xx/rg35xx_tsf_impl.c \
  rg35xx/rg35xx_soundfont_source.c \
  rg35xx/rg35xx_media_runtime.c
RG35XX_NATIVE_CFLAGS := -Irg35xx -Irg35xx/vendor/TinySoundFont
EOF

[ "$(find "$RG35XX_ASSEMBLY_ROOT" -name RG35XXFontEngine.java | wc -l | tr -d ' ')" = 0 ] || fail "superseded font engine present"
[ "$(find "$RG35XX_ASSEMBLY_ROOT/src/libretro" -maxdepth 1 -name freej2me_libretro.c | wc -l | tr -d ' ')" = 1 ] || fail "expected one libretro core entrypoint"
TSF_COUNT=$(grep -l '^[[:space:]]*#define[[:space:]][[:space:]]*TSF_IMPLEMENTATION' "$NATIVE_DST"/*.c | wc -l | tr -d ' ')
TML_COUNT=$(grep -l '^[[:space:]]*#define[[:space:]][[:space:]]*TML_IMPLEMENTATION' "$NATIVE_DST"/*.c | wc -l | tr -d ' ')
[ "$TSF_COUNT" = 1 ] || fail "assembled TSF implementation owner count is $TSF_COUNT"
[ "$TML_COUNT" = 1 ] || fail "assembled TML implementation owner count is $TML_COUNT"
note "ASSEMBLY PASS: $RG35XX_ASSEMBLY_ROOT"
note "CLASSPATH FONT OVERLAY PASS: $RG35XX_CLASSPATH_ROOT"
note "ZERO-FUZZ PATCH/MARKER PASS: all active integration hunks and native lifecycle markers are present"
note "JAMVM STDERR DIAGNOSTIC PASS: /mnt/mmc/Java/freej2me-java.log is assembled without touching stdout video IPC"
note "ABSOLUTE JAMVM LAUNCH PASS: /mnt/mmc/CFW/java/bin/jamvm is used directly; PATH-dependent java execvp removed"
note "Next: compile the modified GNU Classpath tree, then run rc1_runtime_build_overlay.sh + rc1_compile.sh; no DEVICE-TEST-PASS claimed."
