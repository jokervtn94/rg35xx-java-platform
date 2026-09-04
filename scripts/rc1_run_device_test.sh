#!/bin/sh
set -u

# RGJ-RC1-011BJ
# Exact-path real-device launch harness for one RG35XX Java RC1 validation session.
# Test tooling only. Never marks DEVICE-TEST-PASS automatically.

RETROARCH_PATH=${RETROARCH_PATH:-/mnt/mmc/CFW/retroarch/retroarch}
CORE_PATH=${CORE_PATH:-/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so}
RUNTIME_JAR_PATH=${RUNTIME_JAR_PATH:-/mnt/mmc/BIOS/freej2me-lr.jar}
GAMES_PATH=${GAMES_PATH:-/mnt/mmc/Roms/JAVA}
EVIDENCE_SCRIPT=${EVIDENCE_SCRIPT:-}
SESSION_ROOT=${SESSION_ROOT:-/mnt/mmc/Java/test-evidence}

CORE_SHA256=3e416345711891f7edeb4fe04bba82acc674b3c27f50863255376053a3974d58
RUNTIME_JAR_SHA256=f9b96e4490a154b3d58632bf482e0ad9d324a264bd82c8c5bf3a81186a2cfe4b

fail() { echo "RC1 DEVICE TEST: ERROR: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

sha256_file()
{
    if have sha256sum; then
        sha256sum "$1" | awk '{print $1}'
    elif have busybox && busybox sha256sum "$1" >/dev/null 2>&1; then
        busybox sha256sum "$1" | awk '{print $1}'
    else
        fail "sha256sum unavailable"
    fi
}

resolve_game()
{
    arg=$1
    if [ -f "$arg" ]; then
        printf '%s\n' "$arg"
        return 0
    fi
    if [ -f "$GAMES_PATH/$arg" ]; then
        printf '%s\n' "$GAMES_PATH/$arg"
        return 0
    fi
    if [ -f "$GAMES_PATH/$arg.jar" ]; then
        printf '%s\n' "$GAMES_PATH/$arg.jar"
        return 0
    fi
    return 1
}

[ "$#" -eq 1 ] || fail "usage: $0 <game.jar | game-basename>"
[ -x "$RETROARCH_PATH" ] || fail "RetroArch missing/not executable: $RETROARCH_PATH"
[ -f "$CORE_PATH" ] || fail "core missing: $CORE_PATH"
[ -f "$RUNTIME_JAR_PATH" ] || fail "runtime JAR missing: $RUNTIME_JAR_PATH"
[ -d "$GAMES_PATH" ] || fail "games directory missing: $GAMES_PATH"

GAME_PATH=$(resolve_game "$1") || fail "game JAR not found: $1"
case "$GAME_PATH" in
    *.jar|*.JAR) ;;
    *) fail "selected content is not a .jar file: $GAME_PATH" ;;
esac

core_sha=$(sha256_file "$CORE_PATH")
[ "$core_sha" = "$CORE_SHA256" ] || fail "core SHA256 mismatch: got $core_sha expected $CORE_SHA256"
jar_sha=$(sha256_file "$RUNTIME_JAR_PATH")
[ "$jar_sha" = "$RUNTIME_JAR_SHA256" ] || fail "runtime JAR SHA256 mismatch: got $jar_sha expected $RUNTIME_JAR_SHA256"
game_sha=$(sha256_file "$GAME_PATH")

stamp=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)
base=$(basename "$GAME_PATH")
safe_base=$(printf '%s' "$base" | tr ' /' '__' | tr -cd 'A-Za-z0-9._-')
[ -n "$safe_base" ] || safe_base=game
SESSION_DIR="$SESSION_ROOT/$stamp-$safe_base"
mkdir -p "$SESSION_DIR" || fail "cannot create session directory: $SESSION_DIR"

if [ -z "$EVIDENCE_SCRIPT" ]; then
    script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
    if [ -f "$script_dir/rc1_device_evidence.sh" ]; then
        EVIDENCE_SCRIPT="$script_dir/rc1_device_evidence.sh"
    elif [ -f "/mnt/mmc/Java/tools/rc1_device_evidence.sh" ]; then
        EVIDENCE_SCRIPT=/mnt/mmc/Java/tools/rc1_device_evidence.sh
    fi
fi

{
    echo "RG35XX RC1 REAL-DEVICE TEST SESSION"
    echo "timestamp=$stamp"
    echo "game_path=$GAME_PATH"
    echo "game_sha256=$game_sha"
    echo "retroarch_path=$RETROARCH_PATH"
    echo "core_path=$CORE_PATH"
    echo "core_sha256=$core_sha"
    echo "runtime_jar_path=$RUNTIME_JAR_PATH"
    echo "runtime_jar_sha256=$jar_sha"
    echo "build_commit=086d4987c0d60b5eb9abc3887e73638b24a1b964"
    echo "build_run=33883673553"
    echo "build_artifact=9940954185"
} > "$SESSION_DIR/session.txt"

if [ -n "$EVIDENCE_SCRIPT" ] && [ -f "$EVIDENCE_SCRIPT" ]; then
    sh "$EVIDENCE_SCRIPT" pre "$SESSION_DIR/pre" > "$SESSION_DIR/pre-evidence.log" 2>&1 || true
else
    echo "evidence collector not found" > "$SESSION_DIR/pre-evidence.log"
fi

(ps 2>&1 || true) > "$SESSION_DIR/processes-before.txt"

echo "RC1 DEVICE TEST: launching $GAME_PATH"
echo "RC1 DEVICE TEST: session=$SESSION_DIR"

"$RETROARCH_PATH" -L "$CORE_PATH" "$GAME_PATH" > "$SESSION_DIR/retroarch-stdout.log" 2> "$SESSION_DIR/retroarch-stderr.log"
rc=$?

echo "$rc" > "$SESSION_DIR/retroarch-exit-code.txt"
(ps 2>&1 || true) > "$SESSION_DIR/processes-after.txt"

if [ -n "$EVIDENCE_SCRIPT" ] && [ -f "$EVIDENCE_SCRIPT" ]; then
    sh "$EVIDENCE_SCRIPT" post "$SESSION_DIR/post" > "$SESSION_DIR/post-evidence.log" 2>&1 || true
fi

{
    echo "BOOT_VIDEO=NOT_REVIEWED"
    echo "INPUT=NOT_REVIEWED"
    echo "GRAPHICS_FONT=NOT_REVIEWED"
    echo "PCM_WAV=NOT_REVIEWED"
    echo "MIDI=NOT_REVIEWED"
    echo "TONE=NOT_REVIEWED"
    echo "END_OF_MEDIA=NOT_REVIEWED"
    echo "GAME_SWITCH=NOT_REVIEWED"
    echo "RMS_SAVE_REOPEN=NOT_REVIEWED"
    echo "SHUTDOWN=NOT_REVIEWED"
    echo "RETROARCH_EXIT_CODE=$rc"
    echo "OVERALL=NOT_REVIEWED"
    echo ""
    echo "Notes:"
} > "$SESSION_DIR/results-template.txt"

sync 2>/dev/null || true

echo "RC1 DEVICE TEST: RetroArch exit code=$rc"
echo "RC1 DEVICE TEST: evidence saved to $SESSION_DIR"
echo "RC1 DEVICE TEST: DEVICE-TEST-PASS is NOT implied; review all mandatory gates manually."
exit "$rc"
