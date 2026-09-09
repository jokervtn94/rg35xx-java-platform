#!/bin/sh
set -u
OUT_BASE="/mnt/mmc/Java/rg35xx-platform-architecture-audit"
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)
OUT="$OUT_BASE/$STAMP"
mkdir -p "$OUT" || exit 1
R="$OUT/REPORT.txt"

say(){ echo "$*" | tee -a "$R"; }
hash(){ if [ -f "$1" ]; then sha256sum "$1" 2>/dev/null | awk '{print $1}'; else echo MISSING; fi; }
meta(){ p="$1"; say "PATH=$p"; if [ -e "$p" ]; then ls -l "$p" >>"$R" 2>&1; file "$p" >>"$R" 2>&1 || true; say "SHA256=$(hash "$p")"; else say "MISSING"; fi; }

say "RG35XX JAVA PLATFORM ARCHITECTURE AUDIT v2"
say "TIME=$STAMP"
say "MODE=READ-ONLY"
say ""

say "=== 1. DEVICE ==="
uname -a >>"$R" 2>&1 || true
cat /proc/meminfo >>"$OUT/meminfo.txt" 2>/dev/null || true
mount >"$OUT/mounts.txt" 2>/dev/null || true

say "=== 2. CANONICAL COMPONENTS ==="
for p in \
 /mnt/mmc/CFW/java/bin/jamvm \
 /mnt/mmc/CFW/java/share/classpath/glibj.zip \
 /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so \
 /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_libretro.so \
 /mnt/mmc/BIOS/freej2me-lr.jar \
 /mnt/mmc/BIOS/freej2me_plus-lr.jar \
 /mnt/mmc/CFW/java/share/freej2me/freej2me-lr.jar \
 /mnt/mmc/CFW/retroarch/.retroarch/system/freej2me-lr.jar \
 /mnt/mmc/CFW/retroarch/system/freej2me-lr.jar \
 /mnt/mmc/BIOS/freej2me.sf2 \
 /mnt/mmc/BIOS/freej2me-midi.cmd; do meta "$p"; done

say "=== 3. ALIAS CONSISTENCY ==="
CORE1=$(hash /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so)
CORE2=$(hash /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_libretro.so)
[ "$CORE1" = "$CORE2" ] && say "CORE_ALIASES=PASS" || say "CORE_ALIASES=FAIL"
J0=$(hash /mnt/mmc/BIOS/freej2me-lr.jar)
J1=$(hash /mnt/mmc/BIOS/freej2me_plus-lr.jar)
J2=$(hash /mnt/mmc/CFW/java/share/freej2me/freej2me-lr.jar)
J3=$(hash /mnt/mmc/CFW/retroarch/.retroarch/system/freej2me-lr.jar)
J4=$(hash /mnt/mmc/CFW/retroarch/system/freej2me-lr.jar)
if [ "$J0" = "$J1" ] && [ "$J0" = "$J2" ] && [ "$J0" = "$J3" ] && [ "$J0" = "$J4" ]; then say "RUNTIME_ALIASES=PASS"; else say "RUNTIME_ALIASES=FAIL"; fi

say "=== 4. KNOWN VERIFIED HASHES ==="
say "JAMVM_L_EXPECTED=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34"
say "GLIBJ_BASELINE_EXPECTED=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea"
say "VC3_RUNTIME_EXPECTED=eeb08e6b325b032c84776e2374b665c73461ca0d97f796907d3817691046f1e6"
say "VC3_CORE_EXPECTED=3d7b9daac6be2058b8a669d943cf996984ba9a01127964067cda1c74fb1278a2"
[ "$(hash /mnt/mmc/CFW/java/bin/jamvm)" = "eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34" ] && say "JAMVM_L=PASS" || say "JAMVM_L=OTHER"
[ "$(hash /mnt/mmc/CFW/java/share/classpath/glibj.zip)" = "d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea" ] && say "GLIBJ_BASELINE=PASS" || say "GLIBJ_BASELINE=OTHER"
[ "$J0" = "eeb08e6b325b032c84776e2374b665c73461ca0d97f796907d3817691046f1e6" ] && say "VC3_RUNTIME=PASS" || say "VC3_RUNTIME=OTHER"
[ "$CORE1" = "3d7b9daac6be2058b8a669d943cf996984ba9a01127964067cda1c74fb1278a2" ] && say "VC3_CORE=PASS" || say "VC3_CORE=OTHER"

say "=== 5. BINARY MARKERS ==="
strings /mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so >"$OUT/core.strings.txt" 2>/dev/null || true
strings /mnt/mmc/BIOS/freej2me-lr.jar >"$OUT/runtime-container.strings.txt" 2>/dev/null || true
for x in RG35XX-CV RG35XX-PNG-COMPAT RG35XX-MediaWarmup freej2me-java-error.log /mnt/mmc/CFW/java/bin/jamvm; do
 grep -F "$x" "$OUT/core.strings.txt" "$OUT/runtime-container.strings.txt" >>"$OUT/marker-hits.txt" 2>/dev/null || true
done

say "=== 6. LOGGING PATHS ==="
for p in /mnt/mmc/freej2me-core.log /mnt/mmc/freej2me-java-error.log /mnt/mmc/freej2me-java-control.log; do
 if [ -e "$p" ]; then say "LOG_PRESENT=$p size=$(wc -c < "$p" 2>/dev/null)"; cp "$p" "$OUT/" 2>/dev/null || true; else say "LOG_MISSING=$p"; fi
done

say "=== 7. JAVA ROM CORPUS ==="
find /mnt/mmc/Roms/JAVA -maxdepth 1 -type f -name '*.jar' -print >"$OUT/game-jars.txt" 2>/dev/null || true
say "GAME_JAR_COUNT=$(wc -l < "$OUT/game-jars.txt" 2>/dev/null || echo 0)"

say "=== 8. STANDARD FLOW ==="
say "RetroArch -> libretro core -> pipe/fork -> JamVM L -> GNU Classpath -> freej2me-lr.jar -> Libretro IO -> MobilePlatform -> MIDlet"
say "VIDEO: Java ARGB framebuffer -> async FrameWorker -> RGB565 framed IPC -> native receiver -> front/back publish -> Smart-Fit -> 640x480"
say "BOOT: load JAR -> runJar -> loader.start; NO eager prepareMediaEngine"
say "MEDIA: lazy initialization only; boot-time ALSA sequencer probing forbidden"
say "LOGGING: native early log must exist before Java launch in final clean platform"
say ""
say "AUDIT_COMPLETE=$OUT"
