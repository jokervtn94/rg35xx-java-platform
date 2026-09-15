# MIYOO M1.4A.5 SDL Mixer Boot Decouple — PREFLIGHT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Pinned upstream: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## IDENTIFY_CURRENT_SYMPTOM
M1.4A.4 achieved MIDLETLOADER_NIO_GATE=PASS, but the Java5 2D/no-audio boot compile remains FAIL_CLOSED with 14 errors. A major family is direct SdlMixerManager coupling from Display, MIDlet and Anbu after the audio implementation was intentionally excluded.

## SEARCH_TASKLOG_AND_HISTORY
Reviewed M1.4A.3/M1.4A.4 history before change. M1 boot explicitly defers audio. Earlier RG35XX history also requires Lazy Media and forbids eager media/audio boot. No Miyoo audio implementation has DEVICE-PASS on original RG35XX. Device audit showed SDL2_mixer is absent on the original device, while only SDL_mixer 1.2 is present.

## COMPARE_WITH_PREVIOUS_OCCURRENCES
M1.4A.3 exposed SdlMixerManager as a compile-boundary leak. M1.4A.4 intentionally did not alter it and successfully isolated MIDletLoader NIO. This checkpoint addresses only that already-classified leak; it is not an audio implementation checkpoint.

## CHECK_PREVIOUS_FIX_AND_DEVICE_EVIDENCE
Historical Golden Audio belongs to the separate Libretro/R2.x architecture and must not be transplanted into this Miyoo branch. Current Miyoo branch has no audio DEVICE-PASS. SDL1/fbcon video and raw js0 input remain DEVICE-PASS but unrelated to this Java source change.

## SOURCE CHECK
Pinned SdlMixerManager directly declares native SDL2_mixer/haptic methods and has a compile-time type dependency on PlatformPlayer.sdlPlayer. Therefore compiling it as a harmless no-audio class would still drag the deferred PlatformPlayer/audio surface into M1. The minimal boundary is to remove boot/lifecycle/haptic references to SdlMixerManager from the CI boot slice, not to invent an audio stub or initialize native audio.

## CLASSIFY_CURRENT_STATE
CURRENT_SYMPTOM = NO_AUDIO_BOOT_SLICE_DIRECTLY_REFERENCES_SDLMIXERMANAGER
HISTORY_FOUND = YES
PREVIOUS_FIX = NONE_DEVICE_PROVEN_ON_MIYOO_BRANCH
CURRENT_EVIDENCE = CI_FAIL_CLOSED

## CHOOSE_MINIMAL_CHANGE
For the M1 Java5 no-audio compile experiment only, remove SdlMixerManager import/calls from Display, MIDlet and Anbu. Vibrate becomes a no-op/false-capability path for this compile slice; shutdown calls are omitted because no audio subsystem is initialized in M1. Do not add SdlMixerManager or PlatformPlayer back to the source list.

## PRIMARY VARIABLE
REMOVE_SDLMIXER_BOOT_LIFECYCLE_COUPLING_FROM_NO_AUDIO_M1_SLICE

## FORBIDDEN
- no audio implementation or audio stub
- no SDL2_mixer dependency
- no PlatformPlayer backport
- no JamVM/glibj change
- no native SDL/video/input change
- no RMS change
- no M3G change
- no MyMethodVisitor change
- no R2.3 change
- no device installer

## ACCEPTANCE
1. Compiler no longer reports SdlMixerManager errors from Display/MIDlet/Anbu.
2. SdlMixerManager and PlatformPlayer remain excluded.
3. Remaining RMS/M3G/MyMethodVisitor errors remain visible and fail closed.
4. MIDLETLOADER_NIO_GATE remains PASS.
5. This checkpoint does not imply audio support, DEVICE-PASS or STABLE.

BUILD-PASS = NO until complete compile evidence.
DEVICE-PASS = NO.
STABLE = NO.
