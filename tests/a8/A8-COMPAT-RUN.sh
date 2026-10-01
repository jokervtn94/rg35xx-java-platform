#!/bin/sh
# A8 compatibility test wrapper for original RG35XX.
# This script does not modify the accepted A8 runtime or production launcher.

PROD_LAUNCHER=/mnt/mmc/Roms/APPS/RG35XX-AWEIGIT-R1.sh
PROD_RESULT=/mnt/mmc/RG35XX-AWEIGIT-R1-RESULT.txt
EVIDENCE_ROOT=/mnt/mmc/A8-COMPAT-EVIDENCE

GAME="$1"
CANDIDATE="$2"

usage() {
  echo "Usage: $0 /path/to/game.jar A8-COMP-01"
  exit 2
}

[ -n "$GAME" ] || usage
[ -n "$CANDIDATE" ] || usage
[ -f "$GAME" ] || { echo "ERROR: game JAR not found: $GAME"; exit 3; }
[ -f "$PROD_LAUNCHER" ] || { echo "ERROR: A8 production launcher not found: $PROD_LAUNCHER"; exit 4; }

SAFE_ID=$(printf '%s' "$CANDIDATE" | tr -c 'A-Za-z0-9._-' '_')
[ -n "$SAFE_ID" ] || SAFE_ID=A8-COMP-UNKNOWN
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || true)
[ -n "$STAMP" ] || STAMP=NO-DATE
OUTDIR="$EVIDENCE_ROOT/${SAFE_ID}-${STAMP}"
mkdir -p "$OUTDIR" || { echo "ERROR: cannot create evidence directory: $OUTDIR"; exit 5; }

JAR_NAME=$(basename "$GAME")
JAR_SHA256=$(sha256sum "$GAME" 2>/dev/null | awk '{print $1}')
[ -n "$JAR_SHA256" ] || JAR_SHA256=UNAVAILABLE

{
  echo "PROJECT=RG35XX-AWEIGIT-R1"
  echo "BASELINE=A8"
  echo "CANDIDATE_ID=$CANDIDATE"
  echo "JAR_FILENAME=$JAR_NAME"
  echo "JAR_PATH=$GAME"
  echo "JAR_SHA256=$JAR_SHA256"
  echo "DEVICE=ORIGINAL_RG35XX"
  echo "TEST_WRAPPER=A8-COMPAT-RUN"
  echo "TIMESTAMP=$STAMP"
} >"$OUTDIR/IDENTITY.txt"

cat >"$OUTDIR/OBSERVATION.txt" <<EOF
CANDIDATE_ID=$CANDIDATE
JAR_FILENAME=$JAR_NAME
JAR_SHA256=$JAR_SHA256

BOOT=NOT_TESTED
GRAPHICS=NOT_TESTED
INPUT=NOT_TESTED
GAMEPLAY=NOT_TESTED
AUDIO=NOT_TESTED
MEDIA=NOT_TESTED
RMS=NOT_TESTED
LIFECYCLE=NOT_TESTED
PERFORMANCE=NOT_TESTED
HANG_CRASH=NOT_TESTED
EXIT=NOT_TESTED

RESULT=NEEDS_REPRO
FAILURE_OWNER=UNASSIGNED
NOTES=
EOF

rm -f "$PROD_RESULT"
echo "A8 compatibility run: $CANDIDATE"
echo "JAR: $JAR_NAME"
echo "SHA256: $JAR_SHA256"
echo "Evidence: $OUTDIR"

sh "$PROD_LAUNCHER" "$GAME"
RC=$?

if [ -f "$PROD_RESULT" ]; then
  cp "$PROD_RESULT" "$OUTDIR/RUNTIME-RESULT.txt"
else
  {
    echo "PROJECT=RG35XX-AWEIGIT-R1"
    echo "CANDIDATE_ID=$CANDIDATE"
    echo "HARNESS_ERROR=PRODUCTION_RESULT_MISSING"
    echo "WRAPPER_EXIT_CODE=$RC"
  } >"$OUTDIR/RUNTIME-RESULT.txt"
fi

{
  echo "WRAPPER_EXIT_CODE=$RC"
  echo "EVIDENCE_DIR=$OUTDIR"
} >>"$OUTDIR/IDENTITY.txt"

sync

echo "Run complete. Wrapper exit code: $RC"
echo "Review and complete: $OUTDIR/OBSERVATION.txt"
exit "$RC"
