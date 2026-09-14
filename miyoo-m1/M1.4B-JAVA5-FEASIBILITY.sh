#!/usr/bin/env bash
set -euo pipefail
SRC=${1:-upstream-miyoo}
OUT=${2:-M1.4B-JAVA5-FEASIBILITY-REPORT.txt}
PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63

[ -d "$SRC/src" ] || { echo "SOURCE_TREE_MISSING" >&2; exit 2; }
cd "$SRC"
ACTUAL=$(git rev-parse HEAD)
[ "$ACTUAL" = "$PIN" ] || { echo "PIN_MISMATCH" >&2; exit 3; }

CORE_PATHS=(src/org/recompile/freej2me src/org/recompile/mobile src/javax/microedition)

count_files() {
  local pattern=$1
  set +o pipefail
  local n
  n=$(grep -RIlE --include='*.java' -- "$pattern" "${CORE_PATHS[@]}" 2>/dev/null | grep -v '/m3g/' | wc -l | tr -d ' ')
  set -o pipefail
  echo "$n"
}

{
  echo "RG35XX MIYOO M1.4B JAVA5 BACKPORT FEASIBILITY"
  echo "PIN_MATCH=YES"
  echo "SOURCE_PATCHED=NO"
  echo

  echo "== CORE2D MODERN API FILE COUNTS =="
  echo "NIO_FILE_FILES=$(count_files 'java\.nio\.file|Files\.|Paths\.|FileSystems\.|StandardOpenOption|DirectoryStream|StandardCopyOption')"
  echo "UTIL_FUNCTION_FILES=$(count_files 'java\.util\.function')"
  echo "UTIL_STREAM_FILES=$(count_files 'java\.util\.stream')"
  echo "DIAMOND_FILES=$(count_files 'new[[:space:]]+[A-Za-z0-9_.$]+<>')"
  echo "TRY_WITH_RESOURCES_FILES=$(count_files 'try[[:space:]]*\(')"
  echo "LAMBDA_OR_METHODREF_FILES=$(count_files '->|::')"
  echo

  echo "== NIO EXACT LINES =="
  grep -RInE --include='*.java' 'java\.nio\.file|Files\.|Paths\.|FileSystems\.|StandardOpenOption|DirectoryStream|StandardCopyOption' "${CORE_PATHS[@]}" 2>/dev/null | grep -v '/m3g/' || true
  echo

  echo "== DIAMOND EXACT LINES =="
  grep -RInE --include='*.java' 'new[[:space:]]+[A-Za-z0-9_.$]+<>' "${CORE_PATHS[@]}" 2>/dev/null | grep -v '/m3g/' || true
  echo

  echo "== TRY-WITH-RESOURCES CANDIDATE LINES =="
  grep -RInE --include='*.java' 'try[[:space:]]*\(' "${CORE_PATHS[@]}" 2>/dev/null | grep -v '/m3g/' || true
  echo

  echo "== LAMBDA OR METHOD-REFERENCE CANDIDATE LINES =="
  grep -RInE --include='*.java' -- '->|::' "${CORE_PATHS[@]}" 2>/dev/null | grep -v '/m3g/' || true
  echo

  echo "== BOUNDED REPLACEMENT CLASSIFICATION =="
  echo "CATEGORY_A=diamond syntax -> explicit generic arguments"
  echo "CATEGORY_A=try-with-resources -> explicit close/finally where true code"
  echo "CATEGORY_B=SDLConfig.java java.nio.file -> java.io.File.mkdirs"
  echo "CATEGORY_B=PlatformPlayer.java java.nio.file -> java.io.File.mkdirs"
  echo "CATEGORY_B=MIDletLoader.java NIO zip filesystem -> java.util.jar.JarFile/java.util.zip.ZipFile + java.io streams"
  echo

  function_files=$(count_files 'java\.util\.function')
  stream_files=$(count_files 'java\.util\.stream')
  nio_files=$(count_files 'java\.nio\.file|Files\.|Paths\.|FileSystems\.|StandardOpenOption|DirectoryStream|StandardCopyOption')
  if [ "$function_files" = "0" ] && [ "$stream_files" = "0" ] && [ "$nio_files" -le 3 ]; then
    echo "BOUNDED_JAVA5_BACKPORT_CANDIDATE=YES"
    echo "RECOMMENDED_NEXT=CORE2D_JAVA5_BACKPORT_BUILD_AB"
  else
    echo "BOUNDED_JAVA5_BACKPORT_CANDIDATE=NO"
    echo "RECOMMENDED_NEXT=MODERN_JVM_ABI_MEMORY_EVALUATION"
  fi
  echo "DEVICE_PASS=NOT_APPLICABLE"
  echo "STABLE=NO"
} > "../$OUT"

cd ..
cat "$OUT"
