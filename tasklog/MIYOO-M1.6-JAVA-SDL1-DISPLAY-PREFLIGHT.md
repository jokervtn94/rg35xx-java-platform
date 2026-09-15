# MIYOO M1.6 — JAVA -> SDL1/FBCON DISPLAY PREFLIGHT

## Mandatory tasklog-first review

CURRENT_SYMPTOM = M1.5_JAVA_BOOT_DEVICE_PASS_BUT_NO_DISPLAY_INTEGRATION
HISTORY_FOUND = YES
PREVIOUS_FIX = SDL1_1.2_FBCON_DIRECT_DISPLAY
PREVIOUS_EVIDENCE_LEVEL = M1.2A_SDL1_VIDEO_DEVICE_PASS_PLUS_M1.5_JAVA_BOOT_DEVICE_PASS
REGRESSION_RISK = MEDIUM
PRIMARY_VARIABLE = CONNECT_M1_5_JAVA_BOOT_PATH_TO_DEVICE_PROVEN_SDL1_FBCON_DISPLAY_ONLY

Historical constraints:
- M1.2 SDL2 video failed on the RG35XX with no usable video device. Do not restore SDL2 video.
- M1.2A SDL1/fbcon produced the physical RED -> GREEN -> BLUE -> WHITE sequence on the RG35XX and is the admitted display foundation.
- M1.5 Java5 boot/linkage slice passed on the real RG35XX with protected JamVM L and glibj hashes unchanged.

## Minimal change

Build one Java5 display probe plus one minimal JNI native bridge. The bridge dynamically loads the device system SDL 1.2 library and uses the same fbcon path as M1.2A. Java requests RED, GREEN, BLUE, WHITE frames through JNI. No game JAR is launched in this checkpoint.

## Forbidden in M1.6

- no SDL2 video fallback
- no /dev/input/js0 integration
- no audio, SDL_mixer, MIDI, JavaSound or worker/ring
- no font, transparency, NoMask, VC7, Libretro video transport
- no JamVM or glibj replacement/patch
- no RMS/3D/LWJGL/M3G expansion
- no modification of installed production runtime/core

## Build gates

- pinned ARM uClibc toolchain
- ELF32 ARM EABI soft-float native bridge
- Java probe class major 49
- flat GarlicOS `Roms/APPS` package
- protected JamVM/glibj hashes embedded in launcher
- package checksums verified

## Device acceptance

- JamVM/glibj protected hashes match before and after
- Java marker reached
- JNI library loads
- SDL1 initializes video using fbcon
- 640x480 surface obtained
- Java-driven RED -> GREEN -> BLUE -> WHITE is visibly confirmed on physical LCD
- process exits without hard hang

BUILD-PASS is not DEVICE-PASS. Visual confirmation is required. Full platform remains STABLE=NO.
