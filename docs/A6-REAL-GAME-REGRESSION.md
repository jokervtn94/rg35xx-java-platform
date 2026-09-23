# A6 — REAL GAME REGRESSION (NON-AUDIO)

Date: 2026-09-23
Project: RG35XX-AWEIGIT-R1
Production baseline: ffff492c0f2f0ccc1e0c1548addcec99c73fff09
Canonical Aweigit commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## Purpose

A6 is the first Level-3 real-game regression phase after A5 Core2D DEVICE-PASS.
It validates the production A5 core with a real commercial JAR on the original RG35XX without introducing any new J2ME semantic patch.

Audio/Media remain HOLD. A6 must not diagnose or patch media behavior.

## Locked first corpus entry

Game file:
`Vua-Cuop-Bien-240x320.jar`

Required SHA256:
`220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578`

Known corpus metadata:
- MIDP-1.0
- CLDC-1.0
- 83 class files
- 61 non-class resources
- Font APIs: getDefaultFont, getFont, charWidth, stringWidth, getHeight, getBaselinePosition
- Text: drawString
- Graphics: drawRegion, setClip, drawImage
- RMS: RecordStore/open/add/set/get/delete
- Vendor namespace: nokia/
- Media API usage: none in the compatibility matrix

The game itself is NOT stored or distributed by this repository. A6 packaging must require a user-supplied local copy and fail closed unless the SHA256 matches exactly.

## Scope

A6 evaluates only the already-accepted non-audio production path:
- JAR load/startup
- 240x320 logical rendering to physical 640x480 SDL1/fbcon
- image/resource rendering
- text/font rendering
- physical RG35XX input mapping
- RMS behavior when exercised by the game
- normal exit vs hang/hard reset

## Evidence required

Capture:
- production/adapter build identity
- canonical Aweigit identity
- platform JAR SHA256
- input/video native SHA256
- protected JamVM and glibj SHA256 before/after
- real-game JAR filename and SHA256
- boot result
- render result
- input result
- persistence result when exercised
- normal exit vs hang/hard reset
- runtime log/result file

## Acceptance vocabulary

BUILD-PASS != DEVICE-PASS
DEVICE-PASS != STABLE

A6 cannot be promoted from CI alone. Only evidence from the original RG35XX can promote the real-game gate.

## Failure handling

If the real game fails:
1. identify the first meaningful failing boundary;
2. compare against pinned Aweigit behavior and A5 device-proven contracts;
3. do not replay DP patches;
4. do not patch game-layer semantics speculatively;
5. use a micro diagnostic only when evidence narrows the owner;
6. rerun the same locked game/JAR after any evidence-driven fix.

## Current status

A4_LEVEL1_DEVICE_PASS=YES
A5_R2_DEVICE_PASS=YES
A5_REGRESSION_CONFIRMATION=PASS
A5_PRODUCTION_MERGE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
A6_REAL_GAME_REGRESSION=PENDING
AUDIO=HOLD
MEDIA=HOLD
STABLE=NO
FULL_PLATFORM_STABLE=NO
