# A6 — REAL GAME REGRESSION (NON-AUDIO)

Date: 2026-09-23
Project: RG35XX-AWEIGIT-R1
Production baseline: ffff492c0f2f0ccc1e0c1548addcec99c73fff09
Canonical Aweigit commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## Purpose

A6 is the first Level-3 real-game regression phase after A5 Core2D DEVICE-PASS.
It validates the production A5 core with a real commercial JAR on the original RG35XX without introducing any new J2ME semantic patch.

Audio/Media remain HOLD. A6 must not diagnose or patch media behavior.

## Historical corpus candidate — unavailable

Game file:
`Vua-Cuop-Bien-240x320.jar`

Historical SHA256:
`220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578`

Known corpus metadata from the compatibility matrix:
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

Historical logs confirm that this JAR previously ran from:
`/mnt/mmc/Roms/JAVA/Vua-Cuop-Bien-240x320.jar`

The user has confirmed that the JAR was deleted from the SD card. No recoverable binary copy is currently available in Project/Library context. Therefore this entry is retained only as historical corpus identity and MUST NOT be used for A6 acceptance unless an exact user-owned copy is recovered and its SHA256 matches the historical value.

Status:
`A6_CORPUS_01=UNAVAILABLE`

## Evaluated replacement candidate — rejected for A6

Uploaded file:
`NinjaSchool1.jar`

SHA256:
`8eac77fd4cfef3903d210db32792ef3fb34fceaaf77a700ed9a4873aea5e9cb3`

Size:
`298021` bytes

Manifest/profile:
- MIDlet-Name: Ninja School
- MIDlet-Vendor: TeaMobi
- MIDlet-Version: 1.0.0
- MIDP-2.0
- CLDC-1.0
- Nokia-MIDlet-no-exit: true

Static inventory:
- 4 class files
- 393 non-class resources
- 362 PNG resources
- 5 MIDI (`.mid`) resources
- 2 TXT resources
- 24 extensionless resources
- class major versions: 45, 47
- Graphics/Image: drawImage, drawRegion, drawString, setClip, createImage
- Font: getFont, getHeight, stringWidth
- RMS: RecordStore open/add/set/get/close
- Media: `javax.microedition.media.Manager.createPlayer`, Player realize/prefetch/start/stop/deallocate/setLoopCount, VolumeControl.setLevel
- SMS: `javax.wireless.messaging.MessageConnection`, TextMessage, send
- IO wrapper: `javay.microedition.io.Connector`
- Bluetooth/device identity: `javax.bluetooth.LocalDevice`, `com.nokia.IMEI`

A6 decision:
`A6_CANDIDATE_NINJASCHOOL1=REJECTED_OUT_OF_SCOPE`

Reason: the game mixes the non-audio Core2D/RMS path with Media, SMS/activation, Bluetooth/device-ID dependencies. Using it now would create ambiguous failures outside the currently opened A6 scope. It remains a useful later-stage corpus candidate after Media and activation/vendor compatibility are intentionally opened.

## Evaluated replacement candidate — conditional fallback

Uploaded file:
`Bolacthoitiensu_mod_by_thaimeow_320x240_fix.jar`

SHA256:
`5091f23baab29a420edb677c9fdc4f0e24c299f26b0656eaf8a601366d3d1f74`

Size:
`482460` bytes

Manifest/profile:
- MIDlet-Name: Bolacthoitiensu_mod_by_thaimeow
- MIDlet-Version: 1.0.1
- CLDC-1.1
- MIDP-2.1
- logical screen 320x240
- landscape orientation

Static inventory:
- 7 class files, all class major version 47
- 33 non-class entries
- 1 PNG and 25 extensionless resources
- Canvas/Input: getGameAction, repaint, full-screen, sizeChanged
- Graphics/Image: drawImage, drawLine, drawRect, drawRegion, drawString, fillRect, setClip, setColor, createImage/getGraphics
- Font: getFont, getHeight, stringWidth
- RMS: RecordStore open/add/get/getNumRecords/close/delete
- no Connector/HTTP/Socket/SMS/Bluetooth/IMEI references found
- one `platformRequest` literal points to a Facebook URL
- Media is active: Manager.createPlayer(InputStream, `audio/midi`), Player realize/prefetch/start/stop/close/setMediaTime, VolumeControl.setLevel

A6 decision:
`A6_CANDIDATE_BOLACTHOITIENSU=CONDITIONAL_FALLBACK`

Reason: this title is substantially cleaner than NinjaSchool1 and provides useful real-game coverage for 320x240 landscape rendering, Canvas/input, drawRegion/text and RMS without SMS/network/device-activation dependencies. However it still actively invokes J2ME Media, so any media-related failure must be excluded from the A6 non-audio verdict. A clean comparable title with no Media dependency remains preferred for first A6 acceptance.

## Replacement corpus policy

A6 is not blocked on one title. A replacement real-game JAR may be locked only after its actual binary is available and statically inventoried.

Replacement requirements:
1. user-owned/local real JAR binary is available;
2. record exact filename, SHA256, size, MIDP/CLDC profile and resource count;
3. inventory Font/Text/Graphics/Game API/RMS/Vendor/Media usage;
4. while Audio/Media remain HOLD, prefer a title with no `javax.microedition.media` / Manager / Player usage;
5. avoid SMS/network/device-activation dependencies for the first A6 acceptance title when possible;
6. if Media APIs are present, do not interpret a media-related startup/runtime failure as an A6 non-audio core failure;
7. once selected, lock the exact JAR identity before device testing;
8. repository must not store or redistribute the commercial game JAR.

## Scope

A6 evaluates only the already-accepted non-audio production path:
- JAR load/startup
- logical rendering to physical 640x480 SDL1/fbcon
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
A6_CORPUS_01=UNAVAILABLE
A6_CANDIDATE_NINJASCHOOL1=REJECTED_OUT_OF_SCOPE
A6_CANDIDATE_BOLACTHOITIENSU=CONDITIONAL_FALLBACK
A6_REPLACEMENT_CORPUS=PENDING_CLEAN_CANDIDATE
A6_REAL_GAME_REGRESSION=PENDING
AUDIO=HOLD
MEDIA=HOLD
STABLE=NO
FULL_PLATFORM_STABLE=NO
