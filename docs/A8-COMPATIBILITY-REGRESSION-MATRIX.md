# A8 Compatibility / Regression Matrix

This document defines the next test layer after the accepted A8 production baseline.
It is a test contract, not a claim of universal J2ME compatibility.

## Baseline under test

| Item | Reference |
|---|---|
| Baseline | A8 |
| Stable parent | `rg35xx-aweigit-r1-stable` |
| Baseline commit | `8c5b44037cded170acf4bed59f4eb0a16e5e4eaa` |
| Device | Original Anbernic RG35XX / GarlicOS-class environment |
| A8 status | DEVICE-PASS |
| Full platform status | Not yet stable |

## Existing accepted parent regression

| Test | Expected evidence | Status |
|---|---|---|
| Vua Cướp Biển | Display, input, gameplay, no hang | PASS |
| God of War | Display, input, gameplay, no hang, audible/normal audio | PASS |
| Runtime identity | Protected runtime/native identities match | PASS |
| A1P5 audio prime | Zero-PCM pre-Java prime exits successfully | PASS |
| Normal exit | Game/runtime exits without hang | PASS |

## New compatibility test protocol

Every new JAR is treated as an external test input. It must not be bundled into the production runtime package.

For each game, record:

1. Exact JAR filename.
2. SHA256 of the JAR.
3. Original RG35XX device and firmware/OS context.
4. Screen/display result.
5. Input/control result.
6. Gameplay progression result.
7. Audio result, when the game uses audio.
8. Hang/crash/black-screen behavior.
9. Exit behavior.
10. Launcher/runtime log evidence.
11. Failure owner, if a failure is reproducible.

### Result vocabulary

- `PASS` — tested behavior works within the declared scope.
- `FAIL` — reproducible hard failure, hang, crash, unusable display/input, or other blocking regression.
- `PARTIAL` — game launches but one or more tested capabilities are incomplete.
- `NOT_TESTED` — no device evidence yet.
- `NEEDS_REPRO` — reported failure has not yet been reproduced with a known JAR hash.

## Failure triage order

Do not modify a protected subsystem merely because a new game fails.

Use this order:

game/JAR identity -> launcher/package -> canonical J2ME behavior -> RG35XX adapter boundary -> graphics/input/audio/media subsystem -> protected runtime component

A runtime change requires reproducible evidence identifying the affected boundary.

## Compatibility categories

| Category | Examples | First evidence |
|---|---|---|
| Boot | launch, class loading, startup screen | launch log + device |
| Graphics | LCD presentation, PNG/alpha, drawRegion, ClipTranslate | device display |
| Input | keypad, lifecycle, repeated controls | device gameplay |
| Audio | WAV/MIDI/native playback | device audio + logs |
| Media | Java 6 media compatibility, supported formats | device + runtime log |
| Persistence | RMS save/load | save/reload test |
| Lifecycle | pause/resume, exit, relaunch | device |
| Performance | sustained gameplay, presenter/runtime stability | device |
| Optional APIs | networking, SMS/payment, 3D/M3G/Mascot | dedicated evidence |

## Game record template

GAME:
JAR:
JAR_SHA256:
SOURCE:
DEVICE:
DATE:

BOOT:
GRAPHICS:
INPUT:
GAMEPLAY:
AUDIO:
MEDIA:
RMS:
LIFECYCLE:
PERFORMANCE:
HANG/CRASH:

RESULT:
FAILURE_OWNER:
LOG/EVIDENCE:
NOTES:

## Promotion rule

A new game passing does not change the A8 baseline by itself.

A compatibility finding may justify an A9 runtime change only when:

- the failure is reproducible;
- the exact JAR/input is identified;
- the failure boundary is understood;
- the smallest required change is identified;
- parent regression remains intact;
- CI/build gates pass; and
- the resulting candidate is tested on the original RG35XX before DEVICE-PASS is claimed.

## Current queue

The next game corpus can be filled with the user's real Chinese/J2ME JARs. Prioritize games that exercise different APIs rather than multiple games with identical behavior.

No A9 runtime change is implied by this document.