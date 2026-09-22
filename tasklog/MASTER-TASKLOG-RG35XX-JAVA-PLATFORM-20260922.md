# MASTER TASKLOG — RG35XX Java Platform — 2026-09-22

Repository: jokervtn94/rg35xx-java-platform
Active branch: rg35xx-clean-consolidated-r2
Project state: DEVICE-EVIDENCE / BUILD-PASS candidates / STABLE=NO

## Current physical-device base

Authoritative installed base: RG35XX Clean Consolidated R2A
Runtime SHA256 on all five aliases:
5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913

Protected foundation:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- B4 native core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c

Authoritative evidence: RG35XX-CLEAN-R2A-EVIDENCE-20260922-115120.zip

Do not restart from old VC7/RC1 experiments. Continue from exact R2A unless a later task explicitly changes the base.

## Mandatory rules

- Device evidence is authoritative.
- Status: UNVERIFIED -> BUILD-PASS -> DEVICE-EVIDENCE -> DEVICE-PASS -> STABLE.
- Hard reset required = FAIL.
- Minimal delta and fail closed.
- One primary variable per A/B checkpoint.
- Never bundle font, transparency, audio and Canvas in one device test.
- Preserve proven hashes/components.
- Bounded diagnostics only.
- Restore exact R2A before testing another independent candidate.
- Full platform stays STABLE=NO until representative real-game regression passes.

## Source/reference pins

- FreeJ2ME repository: TASEmulators/freej2me-plus
- FreeJ2ME pin: 13ec186903087156c145268f8706eecfaf9f1e50
- Miyoo reference: aweigit/freej2me-miyoomini
- Miyoo audited commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63

Miyoo is architecture guidance only: one subsystem = one owner, handheld audio native, Java MMAPI facade retained, audio independent from render cadence.

## Clean foundation to preserve

- Lazy Media Boot
- Golden Java RGB565 frame transport
- protected B4 native receiver/front-back/Smart-Fit
- Video Mask R2
- Hotpath R2
- PNG iCCP compatibility
- VC7R2 dynamic logical view
- canonical framebuffer object+data binding
- JamVM L
- immutable glibj

## R2A device result

Real games tested:
1. Dragon Mania S40v6
2. Tan Tay Du Ky 3 320x240
3. Real Football 2015 240x320
4. NinjaSchool2
5. KDTT Tam Quoc Chi 320x240
6. Asphalt 4 240x320
7. Zombie Infection 240x320

All seven reached CORE_INIT -> JAVA_READY -> LOAD_GAME -> IPC_RUN_SENT -> CORE_DEINIT.

Image evidence:
- R2A_IMAGE_NORMALIZE_COUNT=37
- PNG_ICCP_STRIP=2
- PNG_ICC_V4_ERRORS=0
- IMAGE_READ_FAILURES=0
- IMAGE_NULL_FAILURES=0

Framebuffer evidence:
- FRAME_BIND_LINES=112
- FRAME_BIND_MISMATCH_TRUE=0

Conclusion: generic image decode advanced successfully. Remaining white-background image defect is transparency semantics, not generic ImageIO load.

R2A classification:
- INSTALL-PASS=YES
- DECODE_PATH_ADVANCED=YES
- TRANSPARENCY_PASS=NO
- FONT/AWT_PASS=NO
- AUDIO_PASS=NO
- FREEZE_PASS=NO
- DEVICE-PASS=NO
- STABLE=NO

## P0 blocker: font/AWT

Tan Tay Du Ky 3:
- 336 ArrayIndexOutOfBoundsException occurrences
- stack reaches Zone.combineWithSubGlyph -> GlyphLoader -> TrueTypeScaler -> GNUGlyphVector -> AbstractGraphics2D.drawString -> PlatformGraphics.drawString

NinjaSchool2:
- 23 NullPointerException / AbstractGraphics2D.renderScanline failures

KDTT:
- game thread terminates with compound-glyph ArrayIndexOutOfBoundsException.

Therefore test font/AWT before any new Canvas/serviceRepaints experiment.

## R2C-FONT — NEXT DEVICE CHECKPOINT

Primary variable: FONT_TEXT_RASTER_ONLY

Design: bypass normal GNU AWT/OpenType text raster and write metric-scaled Unicode bitmap glyphs directly to canvasData while retaining MIDP/DoJa metrics, anchors, baseline, translation and clipping.

Font resource:
- bytes: 727008
- records: 22719
- exact Golden SHA: 7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c
- reconstructed SHA: 20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9
- status: RECONSTRUCTED-NOT-GOLDEN

Build:
- workflow: RG35XX Clean R2C Font
- run: 35689608909
- job: 106623585033
- source commit: ccd21053d9fcb14ef194859b2a11e008c4c08d1c
- result: SUCCESS
- artifact ID: 10678482005
- ZIP SHA: c8506a15d8991f863e16530b952431ad2c2d85416f25585d3078bbb3db403e24
- runtime SHA: 0f38d6181201b3c5128b421e8d0ee747b69911c928a728fd9b3207e39e067e34
- exact required base: R2A 5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913

Package: RG35XX-CLEAN-R2C-FONT.zip
Scripts:
- INSTALL-RG35XX-R2C-FONT.cmd
- RESTORE-RG35XX-R2C-FONT.cmd
- COLLECT-RG35XX-R2C-FONT.cmd

Test order:
1. Tan Tay Du Ky 3
2. NinjaSchool2
3. KDTT Tam Quoc Chi

Expected marker: RG35XX-R2D-FONT: ready bytes=727008
Expected: Zone.combineWithSubGlyph -> zero; AbstractGraphics2D.renderScanline text failures -> zero; no game-thread death at text raster; usable text; no hard reset.

Audio/transparency/screenshot are expected to remain unchanged in this font-only checkpoint.

After test collect RG35XX-R2C-FONT-EVIDENCE-*.zip, then restore exact R2A before another checkpoint.

## R2D-TRANSPARENCY — SECOND INDEPENDENT CHECKPOINT

Primary variable: IMAGE_TRANSPARENCY_ONLY

Design:
1. inspect raw PNG before old ImageIO;
2. capture PNG tRNS metadata;
3. reapply palette/RGB/grayscale transparency after decode;
4. preserve meaningful decoder alpha;
5. only if no alpha/tRNS, conservatively key border-connected pure-white legacy matte.

Global white-as-transparent is forbidden.

Build:
- workflow: RG35XX Clean R2D Transparency
- run: 35689243906
- job: 106622513267
- source commit: 3411e64c3787730a92484795f531c9eef283a799
- result: SUCCESS
- artifact ID: 10677812613
- ZIP SHA: f3276d9bd01443d5a9d6529dd9e1bf743618996945bed016246a8912b581a3fa
- runtime SHA: b377db1c725592fb96cddabe59ff8a376dab516184cd18c9f5f9b78f8501f891
- exact required base: R2A 5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913

Package: RG35XX-CLEAN-R2D-TRANSPARENCY.zip
Scripts:
- INSTALL-RG35XX-R2D-TRANSPARENCY.cmd
- RESTORE-RG35XX-R2D-TRANSPARENCY.cmd
- COLLECT-RG35XX-R2D-TRANSPARENCY.cmd

Expected marker: RG35XX-R2C-TRANSPARENCY

Do not install R2D on top of R2C-FONT. Restore exact R2A first.

## R2B-AUDIO — BUILD-PASS, DEVICE INSTALL BLOCKED

Current-device evidence:
- GETSEQUENCER_ERRORS=2
- CLIP_ERRORS=2
- Real Football 2015 hits LineUnavailableException and NoSuchMethodError getSequencer
- Zombie Infection hits getSequencer from PlatformPlayer midi prefetch

Conclusion: desktop JavaSound is not a valid final RG35XX backend.

R2B architecture:
- Java MMAPI facade retained
- RG35XX media routes before JavaSound
- dedicated inherited audio FD
- parent worker owns audio drain/mixer
- async libretro callback consumes ring
- retro_run does not own media drain/render

Worker constants: ring=16384, prime=3072, chunk=1470

Build:
- workflow: RG35XX Clean Consolidated R2B Audio Ownership Build
- run: 35687872223
- job: 106618475998
- source commit: ef1bb0534c6d3090185ae49cb175155f5d2d98e2
- result: SUCCESS
- artifact ID: 10676804838
- artifact SHA: 5e10f751bd87a4e57f49396d8aced162219eebc8fcf1a1dff8445dbbc7db55e4
- runtime SHA: 202714a2509b9c7e62accc925f24cea3d0d1b1d47d3699b015bf8605da3ae929
- experimental core SHA: 54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51

Before publishing R2B installer require exact R2A/JamVM/glibj/current protected core plus BIOS/freej2me.sf2 with expected historical SHA c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854.

Status: BUILD-PASS=YES; DEVICE-INSTALL=BLOCKED; DEVICE-PASS=NO; STABLE=NO.

## Screenshot issue

Two R2A KDTT screenshots are 640x480 RGB but contain only black and white; white is only near the top and the rest is black.
FRAME_BIND_MISMATCH_TRUE=0.

Keep screenshot diagnosis separate. Future owner test must distinguish Java MIDP frontbuffer vs native Golden RGB565 presentation vs RetroArch screenshot capture.

## Canvas/serviceRepaints

Deferred. Only revisit if R2C-FONT removes text crashes and freeze remains with new evidence.

## RMS

Prior Dragon audit proved zero-byte RMS metadata caused StringIndexOutOfBoundsException, but quarantine did not solve the Gameloft freeze. RMS corruption is real but not the sole cause. No broad RMS rewrite now.

## Proven scoped fixes to protect

- Video Mask R2: physical green tint fix device-proven.
- Hotpath R2: Java log 25,918 -> 484; RG35XX diagnostics 25,840 -> 12; keep bounded diagnostics.
- VC7R2 dynamic logical view: 320x240 scoped evidence; physical Smart-Fit unchanged.
- PNG iCCP: old ICC-v4 blocker absent; preserve sanitizer.
- Canonical framebuffer binding: current R2A mismatch count zero; preserve hardening.

## PowerShell lessons

Earlier bugs:
- drive-root parent path handling could produce illegal New-Item path;
- StrictMode scalar results could break Count assumptions.

Future scripts must array-wrap match results before Count and explicitly handle drive roots. R2C/R2D collectors already self-test StrictMode-safe counting.

## Exact next order

A. Confirm device is exact R2A 5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913.
B. Install/test R2C-FONT with Tan Tay Du Ky 3, NinjaSchool2 and KDTT.
C. Collect RG35XX-R2C-FONT-EVIDENCE-*.zip and analyze before new code.
D. Restore exact R2A.
E. Install/test R2D-TRANSPARENCY independently and collect evidence.
F. Only then complete fail-closed R2B audio installer/SoundFont gate.
G. Screenshot and Canvas remain later independent checkpoints.

## Status matrix

- Clean SD/install foundation: PASS
- JamVM/glibj/B4 core: PROTECTED
- video green tint: DEVICE-PASS scoped
- hotpath logs: DEVICE-PASS scoped
- dynamic 320x240 view: DEVICE-PROVEN scoped
- PNG ICC-v4: advanced/preserved
- generic image load: advanced/no read failures
- transparency: FAIL; R2D BUILD-PASS/device pending
- font/AWT: FAIL/P0; R2C BUILD-PASS/device pending
- freeze: FAIL; first remove font/AWT crashes
- audio: FAIL; R2B BUILD-PASS/install blocked
- screenshot: unresolved owner
- Canvas: deferred
- RMS redesign: deferred
- full platform: STABLE=NO

## Files to read first in a new chat

1. tasklog/MASTER-TASKLOG-RG35XX-JAVA-PLATFORM-20260922.md
2. tasklog/RG35XX-CLEAN-R2A-DEVICE-EVIDENCE-20260922.md
3. tasklog/RG35XX-CLEAN-R2C-FONT.md
4. tasklog/RG35XX-CLEAN-R2C-FONT-BUILD-RESULT.md
5. tasklog/RG35XX-CLEAN-R2D-TRANSPARENCY.md
6. tasklog/RG35XX-CLEAN-R2D-TRANSPARENCY-BUILD-RESULT.md
7. tasklog/RG35XX-CLEAN-CONSOLIDATED-R2B-AUDIO.md
8. tasklog/RG35XX-CLEAN-CONSOLIDATED-R2B-AUDIO-BUILD-RESULT.md

## New-chat handoff prompt

Tiếp tục project RG35XX Java Platform theo MASTER-TASKLOG-RG35XX-JAVA-PLATFORM-20260922.md. Máy thật hiện đang ở exact R2A runtime 5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913. Ưu tiên hiện tại là test R2C-FONT trước, không gộp transparency/audio/Canvas. Hãy đọc tasklog và evidence hiện có trước khi thay đổi code. Giữ nguyên one-primary-variable, fail-closed, device evidence authoritative và STABLE=NO cho tới khi test máy thật pass.

## Final handoff state

- physical device base = R2A
- R2A = DEVICE-EVIDENCE, not DEVICE-PASS
- R2C-FONT = BUILD-PASS, next device test
- R2D-TRANSPARENCY = BUILD-PASS, test only after restoring exact R2A
- R2B-AUDIO = BUILD-PASS reconstruction, DEVICE-INSTALL BLOCKED
- screenshot owner unresolved
- Canvas deferred
- RMS redesign deferred
- full platform STABLE=NO

Next real action: install and test R2C-FONT on exact R2A, collect evidence, and analyze before proceeding.