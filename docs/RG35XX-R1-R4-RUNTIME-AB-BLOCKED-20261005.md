# RG35XX R1 R4 Runtime A/B — BLOCKED — 2026-10-05

Project: RG35XX-AWEIGIT-R1
Device: original RG35XX
Branch: physical-test/rg35xx-r1-p6-p7-20261005

## Trigger

R4 P6 physical acceptance is PASS. R4 P7 Tier-0 regression is FAIL only at God of War audible audio continuity: menu audio is audible, but gameplay music/SFX becomes inaudible. Vua Cuop Bien passes display/input/gameplay/no-hang/exit. GoW passes display/input/gameplay/no-hang/exit but fails gameplay audio continuity.

## Evidence classification

- R4 A1P5 audio-route prime: PASS.
- R4 P6 WAV audible: PASS.
- R4 P6 MIDI audible: PASS.
- R4 GoW menu audio: PASS.
- R4 GoW gameplay audio continuity: FAIL.
- R4 GoW Java/API MIDI load/play markers continue to PASS after the physical audio disappears.
- A8 Golden GoW control contains the same ALSA underrun marker and same MIDI loop progression; therefore the underrun is not sufficient evidence to assign the failure to libaudio.so.
- R4 PlatformPlayer and SdlMixerManager class bytes were compared against A8 Golden and are identical.
- R4 libaudio.so, video native and A1P5 zero-PCM prime retain Golden identities.

## Proposed controlled diagnostic

The next legal diagnostic was a one-variable A/B: keep the R4 platform/native/prime/game exact and switch only the JVM/class-library lineage to the protected A8 runtime:

- JamVM SHA256: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip SHA256: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

The user reported that those files have been completely deleted from the SD card and no backup exists.

## Golden-byte recovery audit

A repository / historical CI audit was performed before considering any substitute:

1. A8 Golden GoW control Actions artifact was inspected. It carries the A8 platform/native/prime control payload but does not carry the protected JamVM/glibj bytes.
2. Historical `rg35xx-garlicos-java-baseline-v1.3-runtime-restore` workflow was inspected. It treats the core Java runtime as pre-existing/preserved state rather than bundling a Golden JamVM/glibj payload.
3. Historical `rg35xx-garlicos-java-baseline-v1` packaging was inspected. It packages the FreeJ2ME JAR/core and creates Java paths, but does not package the protected JamVM/glibj bytes.
4. Historical Golden/from-zero workflows provide build/rebuild recipes, not an exact retained copy proven to match the accepted physical Golden byte identities.
5. GitHub Releases for the repository are empty; there is no release asset containing a recoverable exact Golden runtime.
6. Repository history contains runtime rebuild/assembly work, but a rebuilt semantic-equivalent artifact is not authorized to replace the exact physical Golden identity under the locked ruler.

## Decision

RUNTIME_AB_DIAGNOSTIC=BLOCKED_MISSING_PROTECTED_GOLDEN_BYTES
RUNTIME_FAILURE_OWNER=NOT_PROVEN
MMAPI_CHANGE_AUTHORIZED=NO
PLATFORMPLAYER_CHANGE_AUTHORIZED=NO
SDLMIXERMANAGER_CHANGE_AUTHORIZED=NO
NATIVE_AUDIO_CHANGE_AUTHORIZED=NO
REBUILT_GOLDEN_SUBSTITUTE_AUTHORIZED=NO

P6_PHYSICAL_ACCEPTANCE=PASS
VUA_TIER0_PHYSICAL=PASS
GOW_NON_AUDIO_PHYSICAL=PASS
GOW_GAMEPLAY_AUDIO_CONTINUITY=FAIL
P7_PHYSICAL_REGRESSION=FAIL
P8_PLATFORM_BASELINE_PROMOTION=BLOCKED
DEVICE_PASS=NO
STABLE=NO

## Next legal engineering unit

Do not claim runtime ownership and do not patch MMAPI/native audio speculatively. Continue diagnostics only with evidence that can be produced from retained exact artifacts. The next diagnostic should isolate remaining launcher/frontend/platform-lineage differences without requiring the missing Golden JamVM/glibj bytes, or recover the exact protected Golden bytes from an independently verified source if one later becomes available.
