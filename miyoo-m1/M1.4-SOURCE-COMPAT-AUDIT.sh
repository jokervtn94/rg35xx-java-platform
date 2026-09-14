#!/usr/bin/env bash
set -euo pipefail
SRC=${1:-upstream-miyoo}
OUT=${2:-M1.4-SOURCE-COMPAT-REPORT.txt}
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63

if [ ! -d "$SRC/src" ]; then
  echo "ERROR: source tree not found: $SRC" >&2
  exit 2
fi

cd "$SRC"
ACTUAL=$(git rev-parse HEAD 2>/dev/null || true)
{
  echo "RG35XX MIYOO M1.4 JVM SOURCE COMPATIBILITY AUDIT"
  echo "PIN_EXPECTED=$PIN"
  echo "PIN_ACTUAL=$ACTUAL"
  [ "$ACTUAL" = "$PIN" ] && echo "PIN_MATCH=YES" || echo "PIN_MATCH=NO"
  echo
  echo "== BUILD CONTRACT =="
  grep -nE '<javac|source=|target=|release=' build.xml || true
  grep -n -E 'JDK ?17|jdk17' README.md || true
  echo
  echo "== SOURCE COUNTS =="
  echo "JAVA_FILES_TOTAL=$(find src -name '*.java' | wc -l | tr -d ' ')"
  echo "JAVA_FILES_CORE2D=$(find src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition -name '*.java' 2>/dev/null | grep -v '/m3g/' | wc -l | tr -d ' ')"
  echo "JAVA_FILES_LWJGL_3D=$(find src/org/lwjgl src/javax/microedition/m3g -name '*.java' 2>/dev/null | wc -l | tr -d ' ')"
  echo

  patterns=(
    'java\.nio\.file'
    'java\.util\.function'
    'java\.util\.stream'
    'java\.time\.'
    'java\.util\.Optional'
    'java\.util\.Base64'
    'java\.nio\.charset\.StandardCharsets'
    'java\.util\.Objects'
  )
  labels=(NIO_FILE UTIL_FUNCTION UTIL_STREAM JAVA_TIME OPTIONAL BASE64 STANDARD_CHARSETS UTIL_OBJECTS)
  modern_core_sum=0

  # Zero grep matches are valid audit data. Disable pipefail only for count pipelines.
  set +o pipefail

  echo "== MODERN API IMPORT/REFERENCE COUNTS =="
  for i in "${!patterns[@]}"; do
    p=${patterns[$i]}; label=${labels[$i]}
    total=$(grep -RIlE "$p" src --include='*.java' 2>/dev/null | wc -l | tr -d ' ')
    core=$(grep -RIlE "$p" src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | wc -l | tr -d ' ')
    opt=$(grep -RIlE "$p" src/org/lwjgl src/javax/microedition/m3g --include='*.java' 2>/dev/null | wc -l | tr -d ' ')
    modern_core_sum=$((modern_core_sum + core))
    echo "$label total_files=$total core2d_files=$core lwjgl3d_files=$opt"
  done
  echo "MODERN_API_CORE2D_SUM=$modern_core_sum"
  echo

  echo "== JAVA-7+ SYNTAX HEURISTICS =="
  diamond_total=$(grep -RIlE 'new[[:space:]]+[A-Za-z0-9_.$]+<>' src --include='*.java' 2>/dev/null | wc -l | tr -d ' ')
  diamond_core=$(grep -RIlE 'new[[:space:]]+[A-Za-z0-9_.$]+<>' src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | wc -l | tr -d ' ')
  lambda_total=$(grep -RIlE -- '->[[:space:]]*[^/]' src --include='*.java' 2>/dev/null | wc -l | tr -d ' ')
  lambda_core=$(grep -RIlE -- '->[[:space:]]*[^/]' src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | wc -l | tr -d ' ')
  twr_total=$(grep -RIlE 'try[[:space:]]*\(' src --include='*.java' 2>/dev/null | wc -l | tr -d ' ')
  twr_core=$(grep -RIlE 'try[[:space:]]*\(' src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | wc -l | tr -d ' ')
  echo "DIAMOND files_total=$diamond_total files_core2d=$diamond_core"
  echo "LAMBDA_HEURISTIC files_total=$lambda_total files_core2d=$lambda_core"
  echo "TRY_WITH_RESOURCES_HEURISTIC files_total=$twr_total files_core2d=$twr_core"
  echo

  set -o pipefail

  echo "== CORE2D FILES USING java.nio.file =="
  grep -RIlE 'java\.nio\.file' src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | sort || true
  echo
  echo "== CORE2D FILES USING java.util.function/stream =="
  grep -RIlE 'java\.util\.(function|stream)' src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | sort || true
  echo
  echo "== CORE2D DIAMOND FILES =="
  grep -RIlE 'new[[:space:]]+[A-Za-z0-9_.$]+<>' src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition --include='*.java' 2>/dev/null | grep -v '/m3g/' | sort || true
  echo
  echo "== KEY MANDATORY FILE EXCERPTS =="
  for f in src/org/recompile/freej2me/SDLConfig.java src/org/recompile/mobile/MIDletLoader.java src/org/recompile/mobile/PlatformPlayer.java; do
    if [ -f "$f" ]; then
      echo "--- $f"
      grep -nE 'java\.nio\.file|java\.util\.(function|stream)|new[[:space:]]+[A-Za-z0-9_.$]+<>|FileSystems|Files\.|Paths\.' "$f" || true
    fi
  done
  echo
  echo "== CLASSIFICATION =="
  if [ "$modern_core_sum" = "0" ] && [ "$diamond_core" = "0" ] && [ "$lambda_core" = "0" ] && [ "$twr_core" = "0" ]; then
    echo "CORE2D_JAVA5_COMPAT_RISK=LOW"
  else
    echo "CORE2D_JAVA5_COMPAT_RISK=CONFIRMED"
  fi
  echo "JAMVM_DROP_IN_AS_IS=NO"
  echo "MODERN_JVM_DEVICE_EVIDENCE=NO"
  echo "AUDIT_ONLY=YES"
  echo "DEVICE_PASS=NOT_APPLICABLE"
  echo "STABLE=NO"
} > "../$OUT"

cd ..
cat "$OUT"
