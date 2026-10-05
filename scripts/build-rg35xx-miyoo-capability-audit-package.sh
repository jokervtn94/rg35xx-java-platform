#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="$ROOT/out/rg35xx-miyoo-capability-audit"
PKGROOT="$OUT/RG35XX-MIYOO-CAPABILITY-AUDIT"
SDROOT="$PKGROOT/SD"
APPDIR="$SDROOT/Roms/APPS/RG35XX-MIYOO-CAPABILITY-AUDIT"
APP="$SDROOT/Roms/APPS/RG35XX-MIYOO-CAPABILITY-AUDIT.sh"
PROBE_SRC="$ROOT/tests/capability/rg35xx_platform_capability_probe.c"
PROBE_BIN="$APPDIR/rg35xx-platform-capability-probe"
CC="${RG35XX_AUDIT_ARM_CC:-${P4_ARM_CC:-arm-miyoo-linux-uclibcgnueabi-gcc}}"

fail(){ echo "RG35XX_MIYOO_CAPABILITY_AUDIT_BUILD_FAIL=$*" >&2; exit 1; }

command -v "$CC" >/dev/null 2>&1 || fail "missing_cross_compiler:$CC"
test -f "$PROBE_SRC" || fail "missing_probe_source:$PROBE_SRC"
test -f scripts/build-p4-capability-decision-package.sh || fail "missing_p4_decision_builder"

# Reuse the already-reviewed P4 EGL/GLES diagnostics. The full capability
# audit extends them; it does not introduce another 3D implementation path.
P4_ARM_CC="$CC" bash scripts/build-p4-capability-decision-package.sh | tee /tmp/rg35xx-p4-decision-build.log
grep -q '^P4_CAPABILITY_DECISION_BUILD=PASS$' /tmp/rg35xx-p4-decision-build.log || fail p4_decision_build

rm -rf "$OUT"
mkdir -p "$APPDIR"

"$CC" -std=c99 -O2 -Wall -Wextra \
  "$PROBE_SRC" -o "$PROBE_BIN" -ldl -lpthread
chmod +x "$PROBE_BIN"

# Merge the P4 diagnostics into the same SD tree so the user performs one
# physical capability cycle, not one package per hardware question.
P4_SD="$ROOT/out/p4-capability-decision/RG35XX-P4-CAPABILITY-DECISION/SD"
test -d "$P4_SD" || fail missing_p4_sd_tree
cp -a "$P4_SD"/. "$SDROOT"/

mkdir -p "$(dirname "$APP")"
cat > "$APP" <<'EOF_APP'
#!/bin/sh
set +e

EVID=/mnt/mmc/RG35XX-MIYOO-CAPABILITY-AUDIT-EVIDENCE
APPBASE=/mnt/mmc/Roms/APPS/RG35XX-MIYOO-CAPABILITY-AUDIT
PROBE="$APPBASE/rg35xx-platform-capability-probe"
SUMMARY="$EVID/00-SUMMARY.log"
SYSTEM="$EVID/10-SYSTEM.log"
DEVICES="$EVID/20-DEVICE-NODES.log"
LIBS="$EVID/30-LIBRARIES.log"
JAVA="$EVID/40-JAVA-RUNTIME.log"
NATIVE="$EVID/50-NATIVE-ACTIVE.log"
P4WRAP="$EVID/60-P4-WRAPPER.log"
NETWORK="$EVID/70-NETWORK.log"

mkdir -p "$EVID"
: > "$SUMMARY"
: > "$SYSTEM"
: > "$DEVICES"
: > "$LIBS"
: > "$JAVA"
: > "$NATIVE"
: > "$P4WRAP"
: > "$NETWORK"

emit(){ echo "$*" >> "$SUMMARY"; }

emit "PROJECT=RG35XX-AWEIGIT-R1"
emit "AUDIT=RG35XX_MIYOO_FULL_PLATFORM_CAPABILITY"
emit "CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63"
emit "AUDIT_PARENT_CHECKPOINT=4fab682c15b4944b0d87952e164190a8bd784a30"
emit "AUDIT_MODE=DIAGNOSTIC_ONLY"
emit "RUNTIME_SEMANTIC_DELTA=NONE"
emit "M3G_REENABLED=NO"
emit "MICRO3D_REENABLED=NO"
emit "LWJGL_OPENGL_REENABLED=NO"
emit "DEVICE_PASS=NO"
emit "STABLE=NO"
emit "AUDIT_BEGIN=$(date 2>/dev/null || echo UNKNOWN)"

# 10 - System / ABI / memory / mounts
{
  echo "=== UNAME ==="
  uname -a 2>&1
  echo "=== RELEASE ==="
  for f in /etc/os-release /etc/buildroot-release /etc/version /etc/issue /proc/version; do
    if [ -f "$f" ]; then echo "--- $f"; cat "$f" 2>&1; fi
  done
  echo "=== CPUINFO ==="
  cat /proc/cpuinfo 2>&1
  echo "=== MEMINFO ==="
  cat /proc/meminfo 2>&1
  echo "=== GETCONF ==="
  if command -v getconf >/dev/null 2>&1; then
    echo "LONG_BIT=$(getconf LONG_BIT 2>/dev/null)"
    echo "PAGESIZE=$(getconf PAGESIZE 2>/dev/null)"
  else
    echo "GETCONF=UNAVAILABLE"
  fi
  echo "=== MOUNTS ==="
  cat /proc/mounts 2>&1
  echo "=== DF ==="
  df -h 2>&1 || df 2>&1
  echo "=== ULIMIT ==="
  ulimit -a 2>&1
  echo "=== ENVIRONMENT_RELEVANT ==="
  env 2>/dev/null | grep -E '^(PATH|LD_LIBRARY_PATH|JAVA_HOME|JAVA_TOOL_OPTIONS|SDL_|EGL_|DISPLAY|HOME|PWD)=' | sort
} >> "$SYSTEM" 2>&1

# 20 - Hardware-visible nodes. Presence is evidence only; it is not module PASS.
node(){
  n="$1"
  if [ -e "$n" ]; then
    echo "CAP_NODE=$n PRESENT=YES READABLE=$([ -r "$n" ] && echo YES || echo NO) WRITABLE=$([ -w "$n" ] && echo YES || echo NO)" >> "$DEVICES"
  else
    echo "CAP_NODE=$n PRESENT=NO" >> "$DEVICES"
  fi
}
for n in /dev/fb0 /dev/input/js0 /dev/dsp /dev/mixer /dev/mali /dev/ump /dev/gpu /dev/disp /dev/cedar_dev; do node "$n"; done
for n in /dev/input/event* /dev/input/js* /dev/snd/* /dev/dri/*; do [ -e "$n" ] && node "$n"; done
{
  echo "=== /proc/bus/input/devices ==="; cat /proc/bus/input/devices 2>&1
  echo "=== framebuffer sysfs ==="
  for f in /sys/class/graphics/fb0/name /sys/class/graphics/fb0/virtual_size /sys/class/graphics/fb0/bits_per_pixel /sys/class/graphics/fb0/stride; do
    [ -f "$f" ] && echo "$f=$(cat "$f" 2>/dev/null)"
  done
  echo "=== optional hardware classes ==="
  for d in /sys/class/bluetooth /sys/class/rfkill /sys/bus/iio/devices /sys/class/thermal /sys/class/power_supply; do
    if [ -d "$d" ]; then echo "CAP_SYSFS=$d PRESENT=YES"; ls -la "$d" 2>&1; else echo "CAP_SYSFS=$d PRESENT=NO"; fi
  done
  echo "=== audio proc ==="
  if [ -d /proc/asound ]; then find /proc/asound -maxdepth 2 -type f -print -exec cat {} \; 2>&1; else echo "PROC_ASOUND=ABSENT"; fi
} >> "$DEVICES" 2>&1

# 30 - Library/provider inventory. This is intentionally broader than P4.
{
  echo "=== LIBRARY INVENTORY ==="
  for root in /lib /usr/lib /usr/local/lib /mnt/mmc/CFW/java /mnt/mmc/Roms/APPS; do
    [ -d "$root" ] || continue
    find "$root" \
      \( -name 'libSDL*.so*' -o -name 'libEGL.so*' -o -name 'libGLES*.so*' -o \
         -name 'libGL.so*' -o -name 'libMali.so*' -o -name 'libz.so*' -o \
         -name 'libpng*.so*' -o -name 'libjpeg*.so*' -o -name 'libfreetype*.so*' -o \
         -name 'libasound*.so*' -o -name 'libbluetooth*.so*' -o -name 'libssl*.so*' -o \
         -name 'libcrypto*.so*' -o -name 'libstdc++*.so*' -o -name 'libjawt*.so*' -o \
         -name 'libgtkpeer*.so*' \) -print 2>/dev/null
  done | sort -u | while IFS= read -r lib; do
    [ -n "$lib" ] || continue
    echo "CAP_LIBRARY_FILE=$lib"
    command -v file >/dev/null 2>&1 && file "$lib" 2>&1
    command -v sha256sum >/dev/null 2>&1 && sha256sum "$lib" 2>&1
  done
  echo "=== LDCONFIG ==="
  if command -v ldconfig >/dev/null 2>&1; then ldconfig -p 2>&1; else echo "LDCONFIG=UNAVAILABLE"; fi
} >> "$LIBS" 2>&1

# 40 - JamVM/glibj/class-library substrate. A class existing in glibj is logged
# as PRESENT only; this audit never equates class presence with usable AWT/etc.
{
  echo "=== JAVA COMMANDS ==="
  for c in java jamvm; do
    if command -v "$c" >/dev/null 2>&1; then
      p=$(command -v "$c")
      echo "CAP_JAVA_COMMAND=$c PATH=$p"
      "$p" -version 2>&1
    else
      echo "CAP_JAVA_COMMAND=$c PATH=NOT_FOUND"
    fi
  done

  echo "=== PROTECTED RUNTIME SEARCH ==="
  for root in /mnt/mmc/CFW/java /mnt/mmc/Roms/APPS/FreeJ2ME-RG35XX /mnt/mmc/Roms/APPS; do
    [ -d "$root" ] || continue
    find "$root" \( -name jamvm -o -name glibj.zip -o -name glibj.jar -o -name 'freej2me-rg35xx.jar' -o -name 'librg35xx_input.so' -o -name 'librg35xx_video.so' -o -name 'libaudio.so' \) -print 2>/dev/null
  done | sort -u | while IFS= read -r f; do
    [ -f "$f" ] || continue
    echo "CAP_RUNTIME_FILE=$f"
    command -v sha256sum >/dev/null 2>&1 && sha256sum "$f" 2>&1
  done

  echo "EXPECTED_JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34"
  echo "EXPECTED_GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea"
  echo "EXPECTED_A8_FREEJ2ME_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c"
  echo "EXPECTED_A8_INPUT_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d"
  echo "EXPECTED_A8_VIDEO_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"
  echo "EXPECTED_A8_AUDIO_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644"

  GLIBJ=""
  for root in /mnt/mmc/CFW/java /usr/share/java /usr/lib /usr/local/lib; do
    [ -d "$root" ] || continue
    candidate=$(find "$root" \( -name glibj.zip -o -name glibj.jar \) -print 2>/dev/null | head -n 1)
    if [ -n "$candidate" ]; then GLIBJ="$candidate"; break; fi
  done
  if [ -n "$GLIBJ" ]; then
    echo "CAP_GLIBJ_ARCHIVE=$GLIBJ"
    CLASSLIST="$EVID/.glibj-classlist.tmp"
    if command -v unzip >/dev/null 2>&1; then
      unzip -l "$GLIBJ" 2>/dev/null > "$CLASSLIST"
      echo "CAP_GLIBJ_LIST_METHOD=unzip"
    elif command -v jar >/dev/null 2>&1; then
      jar tf "$GLIBJ" 2>/dev/null > "$CLASSLIST"
      echo "CAP_GLIBJ_LIST_METHOD=jar"
    else
      : > "$CLASSLIST"
      echo "CAP_GLIBJ_LIST_METHOD=UNAVAILABLE"
    fi
    for cls in \
      java/awt/Graphics2D.class \
      java/awt/image/BufferedImage.class \
      java/awt/Font.class \
      javax/imageio/ImageIO.class \
      javax/sound/sampled/AudioSystem.class \
      java/net/Socket.class \
      java/net/DatagramSocket.class \
      java/net/HttpURLConnection.class \
      javax/net/ssl/HttpsURLConnection.class \
      java/nio/ByteBuffer.class \
      java/util/prefs/Preferences.class \
      java/util/zip/Inflater.class \
      java/lang/Thread.class \
      java/lang/reflect/Method.class; do
      if grep -F "$cls" "$CLASSLIST" >/dev/null 2>&1; then
        echo "CAP_GLIBJ_CLASS=$cls PRESENT=YES"
      else
        echo "CAP_GLIBJ_CLASS=$cls PRESENT=NO_OR_UNLISTED"
      fi
    done
    rm -f "$CLASSLIST"
  else
    echo "CAP_GLIBJ_ARCHIVE=NOT_FOUND"
  fi
} >> "$JAVA" 2>&1

# 50 - Safe active substrate tests: ABI, pthread, mmap/mprotect, SD filesystem,
# loopback sockets/DNS and dlopen+dlsym. It does not initialize SDL video/audio.
if [ -x "$PROBE" ]; then
  "$PROBE" "$EVID" > "$NATIVE" 2>&1
  rc=$?
  emit "NATIVE_ACTIVE_PROBE_RC=$rc"
else
  echo "NATIVE_PROBE_MISSING=$PROBE" >> "$NATIVE"
  emit "NATIVE_ACTIVE_PROBE_RC=127"
fi

# 60 - Reuse P4 active EGL/GLES probes for deferred 3D capability only.
P4APP=/mnt/mmc/Roms/APPS/RG35XX-P4-CAPABILITY-DECISION.sh
if [ -x "$P4APP" ]; then
  "$P4APP" > "$P4WRAP" 2>&1
  p4rc=$?
  emit "P4_COMPONENT_RC=$p4rc"
else
  echo "P4_COMPONENT_MISSING=$P4APP" >> "$P4WRAP"
  emit "P4_COMPONENT_RC=127"
fi

collect(){
  src="$1"; dst="$2"
  if [ -f "$src" ]; then cp "$src" "$EVID/$dst"; emit "COLLECTED=$dst"; else emit "MISSING_EVIDENCE=$src"; fi
}
collect /mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE/P4-CAPABILITY-DECISION.log 61-P4-CAPABILITY-DECISION.log
collect /mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE/P4-EGL-GLES-PROBE.log 62-P4-EGL-GLES-PROBE.log
collect /mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE/P4-EGL-GLES-CONTEXT.log 63-P4-EGL-GLES-CONTEXT.log
collect /mnt/mmc/RG35XX-P4-CAPABILITY-DECISION-EVIDENCE/P4-EGL-PLATFORM.log 64-P4-EGL-PLATFORM.log

# 70 - Network inventory only. No external host is contacted.
{
  echo "=== /proc/net/dev ==="; cat /proc/net/dev 2>&1
  echo "=== /proc/net/route ==="; cat /proc/net/route 2>&1
  echo "=== resolv.conf ==="; cat /etc/resolv.conf 2>&1
  echo "=== interfaces ==="
  if command -v ip >/dev/null 2>&1; then ip addr 2>&1; ip route 2>&1
  elif command -v ifconfig >/dev/null 2>&1; then ifconfig -a 2>&1
  else echo "NETWORK_TOOL=UNAVAILABLE"; fi
} >> "$NETWORK" 2>&1

# Copy the requirement manifest next to the evidence so source requirements and
# measured device capabilities can be joined after the physical run.
if [ -f "$APPBASE/MIYOO-REQUIREMENTS.tsv" ]; then
  cp "$APPBASE/MIYOO-REQUIREMENTS.tsv" "$EVID/MIYOO-REQUIREMENTS.tsv"
fi

emit "AUDIT_RESULT=REVIEW_REQUIRED"
emit "RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO"
emit "STABLE=NO"
emit "AUDIT_END=$(date 2>/dev/null || echo UNKNOWN)"
sync
cat "$SUMMARY"
exit 0
EOF_APP
chmod +x "$APP"

cat > "$APPDIR/MIYOO-REQUIREMENTS.tsv" <<'EOF_TSV'
MODULE	PINNED_MIYOO_REQUIREMENT	DEVICE_EVIDENCE	DECISION_POLICY
CORE_JVM	ARM/Linux Java runtime + threads + class library	10-SYSTEM;40-JAVA-RUNTIME;50-NATIVE-ACTIVE	Keep Miyoo semantics; adapt only measured RG35XX runtime gaps
SDL_FRONTEND	Miyoo native frontend links SDL2 + pthread	30-LIBRARIES;50-NATIVE-ACTIVE;accepted P2 evidence	Original Miyoo frontend reusable only if actual provider/ABI fits; otherwise keep RG35XX video/input boundary
LCdui_GRAPHICS	MIDP/Canvas/GameCanvas/Image/Font semantics; Miyoo may delegate desktop/AWT paths	40-JAVA-RUNTIME;accepted P1/P2 evidence	Preserve canonical semantics; Raw2D RG35XX boundary only where AWT path is unavailable
INPUT	Handheld SDL/input frontend	20-DEVICE-NODES;accepted P2 evidence	Keep canonical key semantics; adapt physical acquisition/mapping only
RMS_FILECONNECTION	Writable persistent filesystem	10-SYSTEM;50-NATIVE-ACTIVE;accepted P3 evidence	Keep Miyoo/J2ME semantics; adapt device filesystem paths only
IO_NETWORK	TCP/UDP/DNS and optional TLS provider	50-NATIVE-ACTIVE;70-NETWORK	Do not claim protocol support from interface presence alone; map Connector implementation after evidence
MMAPI_AUDIO	Miyoo libaudio links SDL2 + SDL2_mixer	20-DEVICE-NODES;30-LIBRARIES;50-NATIVE-ACTIVE;accepted P3 audible evidence	Existing RG35XX audio boundary remains authority unless exact incompatibility is proven
IMAGE_CODECS	Java image path and/or PNG/JPEG/zlib substrate	30-LIBRARIES;40-JAVA-RUNTIME;accepted P2 evidence	Preserve accepted image behavior; external codec presence alone is not permission to rewrite
FONT_TEXT	font.ttf + text/font rendering substrate	30-LIBRARIES;40-JAVA-RUNTIME;accepted P2 evidence	Preserve accepted font/text behavior
M3G_JSR184	EGL + GLES1 + zlib native provider	50-NATIVE-ACTIVE;61-64 P4 logs	REENABLE=NO until exact pinned source/native call surface maps to measured context
MASCOTCAPSULE_MICRO3D	EGL + GLES2 native provider	50-NATIVE-ACTIVE;61-64 P4 logs	REENABLE=NO until exact pinned source/native call surface maps to measured context
LWJGL_OPENGL	OpenGL/EGL/GLES provider plus compatible native binding	30-LIBRARIES;50-NATIVE-ACTIVE;61-64 P4 logs	Do not re-enable blindly; require exact provider/API mapping
BLUETOOTH_JSR82	Kernel/device + userspace Bluetooth provider + Java implementation	20-DEVICE-NODES;30-LIBRARIES;50-NATIVE-ACTIVE	Hardware/provider absence may justify unsupported/deferred; presence alone is not module PASS
SENSOR_JSR256	Actual sensor/input/IIO provider plus Java implementation	20-DEVICE-NODES	Classify only after measured device provider and pinned source mapping
PIM	Pinned Java implementation plus any required host/provider backing	40-JAVA-RUNTIME	Do not infer contacts/calendar capability from generic filesystem; inspect exact source owner
PKI_TLS	Class-library crypto/TLS plus native/provider dependencies if any	30-LIBRARIES;40-JAVA-RUNTIME;50-NATIVE-ACTIVE	Verify exact Connector/PKI implementation before claiming HTTPS/TLS
VENDOR_NOKIA	Pinned com.nokia semantics	accepted module evidence + source audit	Keep original when pure/canonical; only measured hardware boundary may change
VENDOR_SAMSUNG	Pinned com.samsung semantics	source audit	Keep original when pure/canonical; hardware-dependent calls require owner-scoped decision
VENDOR_SIEMENS	Pinned com.siemens semantics	source audit	Keep original when pure/canonical; hardware-dependent calls require owner-scoped decision
NATIVE_LOADING	ELF ABI + dynamic loader + JNI library path	10-SYSTEM;30-LIBRARIES;50-NATIVE-ACTIVE	Match exact RG35XX ABI; do not substitute rebuilt golden artifacts silently
EOF_TSV

cat > "$PKGROOT/README-FIRST.txt" <<'EOF_README'
RG35XX Miyoo Full Platform Capability Audit

Purpose:
  Measure the real original-RG35XX/GarlicOS substrate before continuing the
  Miyoo/Aweigit port. This is a diagnostic-only package. It does not replace,
  patch or promote the production FreeJ2ME runtime.

Install:
  Copy the SD/ tree to the root of the GarlicOS SD card.

Run exactly one launcher:
  /mnt/mmc/Roms/APPS/RG35XX-MIYOO-CAPABILITY-AUDIT.sh

Return the complete directory:
  /mnt/mmc/RG35XX-MIYOO-CAPABILITY-AUDIT-EVIDENCE/

Expected evidence:
  00-SUMMARY.log
  10-SYSTEM.log
  20-DEVICE-NODES.log
  30-LIBRARIES.log
  40-JAVA-RUNTIME.log
  50-NATIVE-ACTIVE.log
  60-P4-WRAPPER.log
  61-P4-CAPABILITY-DECISION.log
  62-P4-EGL-GLES-PROBE.log
  63-P4-EGL-GLES-CONTEXT.log
  64-P4-EGL-PLATFORM.log
  70-NETWORK.log
  MIYOO-REQUIREMENTS.tsv

Interpretation levels:
  PRESENT       file/device/class exists only
  LOADABLE      provider can be dlopen'd and required symbols are visible
  ACTIVE PASS   a controlled local operation actually succeeded
  REVIEW_REQUIRED  source-to-hardware mapping is still required

The package deliberately does not initialize SDL video/audio because those
boundaries already have accepted RG35XX evidence and should not be needlessly
retested. The existing P4 EGL/GLES probes are reused because 3D capability is
still unresolved.

No external network host is contacted. Network testing is local socket/DNS
substrate plus interface inventory only.
EOF_README

cat > "$PKGROOT/RG35XX-MIYOO-CAPABILITY-AUDIT-IDENTITY.txt" <<'EOF_ID'
PROJECT=RG35XX-AWEIGIT-R1
PACKAGE=RG35XX-MIYOO-CAPABILITY-AUDIT
CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
AUDIT_PARENT_CHECKPOINT=4fab682c15b4944b0d87952e164190a8bd784a30
AUDIT_SCOPE=FULL_PLATFORM_CAPABILITY_SUBSTRATE
RUNTIME_SEMANTIC_DELTA=NONE
DIAGNOSTIC_ONLY=YES
REUSES_ACCEPTED_P1_P2_P3_EVIDENCE=YES
P4_ACTIVE_DIAGNOSTIC_INCLUDED=YES
M3G_REENABLED=NO
MICRO3D_REENABLED=NO
LWJGL_OPENGL_REENABLED=NO
AUDIT_RESULT=REVIEW_REQUIRED
DEVICE_PASS=NO
STABLE=NO
EOF_ID

cp "$APPDIR/MIYOO-REQUIREMENTS.tsv" "$PKGROOT/MIYOO-REQUIREMENTS.tsv"

(cd "$PKGROOT" && find . -type f -print | sort | xargs sha256sum > PAYLOAD-SHA256SUMS.txt)
(cd "$OUT" && zip -qr RG35XX-MIYOO-CAPABILITY-AUDIT.zip RG35XX-MIYOO-CAPABILITY-AUDIT)

echo "RG35XX_MIYOO_CAPABILITY_AUDIT_BUILD=PASS"
echo "RG35XX_MIYOO_CAPABILITY_AUDIT_RUNTIME_SEMANTIC_DELTA=NONE"
echo "RG35XX_MIYOO_CAPABILITY_AUDIT_RESULT=REVIEW_REQUIRED"
echo "RG35XX_MIYOO_CAPABILITY_AUDIT_PACKAGE=$OUT/RG35XX-MIYOO-CAPABILITY-AUDIT.zip"
sha256sum "$OUT/RG35XX-MIYOO-CAPABILITY-AUDIT.zip"
