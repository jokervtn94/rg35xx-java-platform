# MIYOO M1.5 MINIMAL JAVA DEVICE BOOT — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.8 reached JAVAC_RC=0 with 245 Java 5 class-major-49 classes, but the bounded Java slice has never been launched on the real original RG35XX. The next unknown is runtime boot compatibility with the device-proven JamVM L / GNU Classpath baseline.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed before implementation:
- M1.4 JVM strategy explicitly requires retaining device-proven JamVM L and GNU Classpath for the first Java boot checkpoint.
- JamVM L SHA256 eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34 = DEVICE-PROVEN.
- glibj.zip SHA256 d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea = DEVICE-PROVEN.
- M1.2 SDL2 video failed on device; do not use it as video baseline.
- M1.2A SDL1/fbcon independently reached real-device video evidence and physical LCD RED/GREEN/BLUE/WHITE.
- M1.3A raw /dev/input/js0 and M1.3C semantic keymap have real-device evidence.
- M1.4A.4 through A.8 compile gates now PASS; M1.4A.8 BUILD-PASS is bounded only.
- No previous M1.5 integrated Java boot package exists in current tasklog.

## COMPARE_WITH_PREVIOUS OCCURRENCES
Historical RG35XX regressions came from integrating multiple subsystems before isolating boot. Therefore M1.5 must not combine Java boot with new audio, SDL2 video, 3D, font, transparency, Libretro RGB565 IPC, or VC7 diagnostics. The first device run must answer only whether the Java5-compatible Miyoo 2D/no-audio slice can start under the proven JVM/class library baseline.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
JamVM L / glibj: DEVICE-PROVEN independently.
SDL1/fbcon: DEVICE-PROVEN independently.
raw js0 semantic input: DEVICE-PROVEN independently.
M1.4A.8 Java slice: BUILD-PASS only.
Integrated Miyoo Java boot on original RG35XX: NO DEVICE EVIDENCE.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = BOUNDED_JAVA5_SLICE_BUILD_PASS_BUT_DEVICE_BOOT_UNKNOWN
HISTORY_FOUND = YES
PREVIOUS_FIX = KEEP_PROVEN_JVM_AND_NATIVE_FOUNDATION; TEST_JAVA_BOOT_AS_NEXT_SINGLE_UNKNOWN
PREVIOUS_EVIDENCE_LEVEL = COMPONENT_DEVICE_PROVEN_PLUS_JAVA_SLICE_BUILD_PASS
REGRESSION_RISK = MEDIUM

## CHOOSE_MINIMAL CHANGE
PRIMARY_VARIABLE = LAUNCH_M1_4A_8_JAVA5_2D_NO_AUDIO_SLICE_ON_DEVICE_PROVEN_JAMVM_L_GLIBJ

Create a self-contained M1.5 device-test package that:
1. uses the exact M1.4A.8 source pin/transforms and class-major-49 output;
2. does not overwrite the installed production runtime/core;
3. verifies JamVM L and glibj hashes before launch and fails closed on mismatch;
4. stages test files in an isolated M1.5 directory;
5. uses bounded boot logging and a timeout/watchdog so a hard hang produces evidence rather than an indefinite lock;
6. records exit code, JVM version, memory snapshot, and before/after protected hashes;
7. initially tests Java boot only. Native SDL1/js0 integration may be wired only after Java boot is proven, as a separate variable/checkpoint.

## FORBIDDEN CHANGES
- no JamVM binary replacement or patch;
- no glibj patch;
- no audio worker/ring, SDL_mixer/SDL2_mixer, JavaSound or MIDI changes;
- no SDL2 video fallback;
- no 3D/LWJGL/M3G activation;
- no RMS implementation expansion;
- no font/transparency/NoMask/VC7/Libretro transport import;
- no modification of R2.3 fallback;
- no claim of DEVICE-PASS from CI.

## ACCEPTANCE GATES
BUILD package gate:
- exact source pin and A.4-A.8 transforms reproduced;
- class major version 49 only;
- protected JamVM/glibj expected hashes embedded in test script;
- package contains rollback-safe isolated launcher and bounded logger.

DEVICE gate on original RG35XX:
- protected hashes match before launch;
- JamVM starts the staged Java entry path without VerifyError/UnsupportedClassVersionError/NoClassDefFoundError on an excluded boot dependency;
- process reaches an explicit bounded M1.5 boot marker and exits or remains responsive according to the test contract;
- no hard hang;
- protected hashes unchanged after test.

Only this M1.5 Java boot slice may become DEVICE-PASS after real-device evidence. Full platform remains STABLE=NO.
