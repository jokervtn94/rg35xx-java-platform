# A6 — REAL GAME REGRESSION (NON-AUDIO)

Date: 2026-09-23
Project: RG35XX-AWEIGIT-R1
Production baseline: ffff492c0f2f0ccc1e0c1548addcec99c73fff09
Canonical Aweigit commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63

## Purpose

A6 is the first Level-3 real-game regression phase after A5 Core2D DEVICE-PASS. It validates the production A5 core with a real commercial JAR on the original RG35XX without introducing speculative J2ME semantic patches.

Audio/Media remain HOLD. A6 must not diagnose or patch media behavior.

## Candidate status

### Vua Cuop Bien — unavailable
`Vua-Cuop-Bien-240x320.jar`
Historical SHA256: `220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578`
Status: `A6_CORPUS_01=UNAVAILABLE`

### NinjaSchool1 — rejected
`NinjaSchool1.jar`
SHA256: `8eac77fd4cfef3903d210db32792ef3fb34fceaaf77a700ed9a4873aea5e9cb3`
Status: `A6_CANDIDATE_NINJASCHOOL1=REJECTED_OUT_OF_SCOPE`
Reason: active Media plus SMS/activation, Bluetooth/device identity dependencies.

### Bo Lac Thoi Tien Su — conditional fallback
`Bolacthoitiensu_mod_by_thaimeow_320x240_fix.jar`
SHA256: `5091f23baab29a420edb677c9fdc4f0e24c299f26b0656eaf8a601366d3d1f74`
Status: `A6_CANDIDATE_BOLACTHOITIENSU=CONDITIONAL_FALLBACK`
Reason: useful landscape Graphics/Input/Font/RMS coverage and no SMS/HTTP activation stack detected, but active MMAPI MIDI remains. Audio-related failures must be excluded from the A6 verdict.

### KDTT Tam Quoc Chi — rejected
`KDTT-Tam_Quoc_Chi_320x240_vh_by_zeplaovn.jar`
SHA256: `5586089f41bdfe87b139bbe7e3ef5cb362cd691775559d0f6605ce8d2b9c6d07`
Size: `1092360` bytes
MIDlet: `口袋神兽三国志`
Vendor: `BlackPearl`
MIDP-2.0 / CLDC-1.0
89 classes / 125 non-class resources
Resources include 6 MIDI files.

Useful core coverage:
- GameCanvas
- drawImage/drawRegion/drawString/setClip/clipRect/fillRect/drawLine/drawRect
- Font getFont/getHeight/stringWidth/charWidth
- RMS open/add/set/get/getNumRecords/delete/close

Closed-boundary dependencies confirmed by bytecode:
- active MMAPI Manager/Player/VolumeControl MIDI playback
- active `javax.microedition.io.Connector` / `HttpConnection`
- WapPay HTTP request code and payment endpoints
- manifest `MIDlet-Install-Notify` points to a payment server
- SMS MessageConnection/TextMessage object construction and payload/address assignment

The modded SMS path contains `hardtodie cracked` and no inspected `MessageConnection.send` invocation, indicating the actual SMS send was patched/bypassed. This does not make the title clean for A6 because HTTP payment/activation and Media remain active.

Status: `A6_CANDIDATE_KDTT=REJECTED_OUT_OF_SCOPE`

## Replacement corpus policy

A replacement real-game JAR may be locked only after its binary is available and inventoried:
1. record exact filename/SHA256/size/MIDP/CLDC/resources;
2. inventory Font/Text/Graphics/Game API/RMS/Vendor/Media usage;
3. prefer no MMAPI Media for the first A6 acceptance title;
4. avoid HTTP/socket/SMS/Bluetooth/device-ID/activation/payment dependencies;
5. once selected, lock exact JAR identity before device testing;
6. do not store or redistribute commercial game JARs in the repository.

## Scope

A6 evaluates only the accepted non-audio production path: JAR load/startup, logical rendering to physical 640x480 SDL1/fbcon, image/resource rendering, text/font rendering, physical RG35XX input mapping, RMS behavior when exercised, and normal exit vs hang/hard reset.

## Evidence required

Capture production/adapter and canonical identities, platform/native hashes, protected JamVM/glibj hashes before/after, locked game JAR filename/SHA256, boot/render/input/persistence observations, normal exit vs hang/hard reset, and runtime logs.

BUILD-PASS != DEVICE-PASS != STABLE. Only original RG35XX evidence can promote the real-game gate.

## Failure handling

If a real game fails: identify the first meaningful boundary, compare against pinned Aweigit and A5 device-proven contracts, do not replay DP patches, do not patch game-layer semantics speculatively, use a micro diagnostic only when evidence narrows the owner, and rerun the same locked JAR after an evidence-driven fix.

## Current status

A4_LEVEL1_DEVICE_PASS=YES
A5_R2_DEVICE_PASS=YES
A5_REGRESSION_CONFIRMATION=PASS
A5_PRODUCTION_MERGE=ffff492c0f2f0ccc1e0c1548addcec99c73fff09
A6_CORPUS_01=UNAVAILABLE
A6_CANDIDATE_NINJASCHOOL1=REJECTED_OUT_OF_SCOPE
A6_CANDIDATE_BOLACTHOITIENSU=CONDITIONAL_FALLBACK
A6_CANDIDATE_KDTT=REJECTED_OUT_OF_SCOPE
A6_REPLACEMENT_CORPUS=PENDING_CLEAN_CANDIDATE
A6_REAL_GAME_REGRESSION=PENDING
AUDIO=HOLD
MEDIA=HOLD
STABLE=NO
FULL_PLATFORM_STABLE=NO
