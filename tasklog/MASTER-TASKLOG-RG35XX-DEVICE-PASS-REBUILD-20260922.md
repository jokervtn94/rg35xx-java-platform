# MASTER TASKLOG — RG35XX DEVICE-PASS REBUILD BASELINE — 2026-09-22

Project: RG35XX Java Platform  
Purpose: single source of truth for a NEW CHAT / clean platform rebuild  
Target hardware: original Anbernic RG35XX / GarlicOS class environment  
Status of full platform: **STABLE=NO**

---

## 0. Why this master exists

Previous work accumulated several different build families (VC7/verified-clean/from-zero/R2/Miyoo standalone). A later build often reintroduced defects that had already been isolated because evidence from different branches was mixed together.

This master intentionally separates:

1. **explicit real-device DEVICE-PASS checkpoints** — allowed as locked behavior;
2. **device-proven/admitted historical behavior** — useful but not equivalent to a full DEVICE-PASS artifact;
3. **HOLD / EXPERIMENTAL / FAIL** — must not be silently treated as stable;
4. **architecture boundaries** — Miyoo standalone evidence must not be assumed valid inside Libretro without a new device test.

The new rebuild must start from this file and the cited primary checkpoint files, not from memory and not from the newest assembled R2 runtime.

---

## 1. Mandatory evidence vocabulary

Use only these labels:

- `UNVERIFIED`
- `BUILD-PASS`
- `DEVICE-EVIDENCE`
- `DEVICE-PASS`
- `STABLE`
- `FAIL`
- `EXPERIMENTAL`
- `DEVICE-TEST-PENDING`

Evidence ladder:

`UNVERIFIED -> BUILD-PASS -> DEVICE-EVIDENCE -> DEVICE-PASS -> STABLE`

Hard rules:

- CI/build success is never enough for `DEVICE-PASS`.
- Real RG35XX testing is mandatory for `DEVICE-PASS`.
- Hard reset required = checkpoint FAIL, never DEVICE-PASS.
- Do not call a reconstructed binary/resource `Golden`.
- Do not call the whole platform `STABLE` from a subsystem test.
- One primary variable per A/B checkpoint.
- Preserve every already DEVICE-PASS subsystem unless new real-device evidence proves a regression.

Primary rules source:
`project-rules/RG35XX_PROJECT_RULES.json`

---

## 2. Locked build identities / protected dependencies

### FreeJ2ME source pin
`13ec186903087156c145268f8706eecfaf9f1e50`

### ARM toolchain
`docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`

### JamVM L — protected DEVICE-PASS foundation
SHA256:
`eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

Locked behavior:
- production interpreter fix retained;
- do not reintroduce diagnostic A-K variants / low-pointer diagnostic exits;
- treat the exact binary identity as protected unless source provenance is independently recovered and revalidated.

### GNU Classpath baseline — immutable
`glibj.zip` SHA256:
`d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

Rules:
- do not byte-patch N3/N3.1 or later experimental GNU Classpath variants into the new foundation;
- changing glibj requires its own isolated device checkpoint.

---

## 3. ARCHITECTURE LOCK — do not mix evidence silently

There are two historically different platform families:

### A. Miyoo-derived STANDALONE path

Proven chain on original RG35XX:

`JamVM -> Java -> JNI -> SDL1/fbcon -> physical LCD`

Input chain:

`/dev/input/js0 -> JNI -> MobilePlatform -> Canvas/GameCanvas`

This family contains the strongest explicit `DEVICE-PASS` chain for display, input, Canvas and GameCanvas.

### B. Libretro / FreeJ2ME core path

Proven historical behaviors exist for RGB565 transport, Smart-Fit, dynamic logical view, NoMask green-tint fix, PNG iCCP, audio worker-ring architecture, etc. However, several assembled Libretro builds later reintroduced font/audio/transparency/freeze defects.

### Mandatory new-rebuild rule

**Do not copy a DEVICE-PASS claim across A <-> B.**

If the rebuild is based on the Miyoo standalone chain, preserve its standalone ownership model. If a Libretro frontend is added later, that is a new primary-variable checkpoint and the affected display/input/lifecycle paths must be revalidated on RG35XX.

For the clean rebuild intended by this master, **Miyoo standalone is the preferred foundation because it has the clearest explicit DEVICE-PASS chain on the original RG35XX.**

---

## 4. EXPLICIT DEVICE-PASS WHITELIST — safe behavior to preserve

Only the scopes below are allowed to be described as DEVICE-PASS without a new test.

### 4.1 M1.6 — Java -> JNI -> SDL1/fbcon display

Status: `DEVICE-PASS`

Source evidence:
`tasklog/MIYOO-M1.6-JAVA-SDL1-DISPLAY-DEVICE-RESULT.md`

Build identity:
- branch: `rg35xx-miyoo-platform-v1`
- commit: `419e70035c7443daf352cdf58aee89b429248782`
- workflow run: `34933644505`
- job: `104266856028`
- artifact: `10382283430`
- artifact digest: `20e7abec28f7bdfea92462ac6dd7c7f7c69ad23791e06c13cca4dccd1894e084`
- native display library SHA: `f03a2fe5e31443fea009c878db209ac94e32cf8eab45f956e46681d74e2a5451`

Real-device acceptance:
- SDL driver = `fbcon`
- physical surface = `640x480`, pitch `2560`
- RED visible
- GREEN visible
- BLUE visible
- WHITE visible
- native init `0`
- automatic normal exit
- no hard reset
- JamVM/glibj unchanged

LOCK:
- original RG35XX display backend = **SDL1/fbcon** for this standalone architecture.

### 4.2 M1.7 — Java -> JNI -> raw `/dev/input/js0`

Status: `DEVICE-PASS`

Source evidence:
`tasklog/MIYOO-M1.7-JAVA-RAW-JS0-INPUT-DEVICE-RESULT.md`

Real-device acceptance:
- input device opened successfully;
- all 12 controls recognized;
- normal exit;
- no hard reset;
- protected hashes unchanged.

Locked physical mapping:
- UP = axis7 negative
- DOWN = axis7 positive
- LEFT = axis6 negative
- RIGHT = axis6 positive
- A/B/X/Y = buttons 0/1/2/3
- START = button8
- SELECT = button7
- L/R = buttons5/6

### 4.3 M1.8 — physical input -> MobilePlatform dispatch

Status: `DEVICE-PASS`

Source evidence:
`tasklog/MIYOO-M1.8-PHYSICAL-INPUT-DEVICE-PASS.md`

Build identity:
- branch: `miyoo-m1.8-midp-input-dispatch`
- commit: `f011ba68221dc9820d0d99a38e2377d154dabbc2`
- run: `34959980076`
- artifact: `10393017078`
- artifact digest: `4e8e97efc80e7a0730b75a14530bcc333db39fed96cf7f6998dd2a1dc665487b`

Real-device evidence:
- 30-second physical window
- press = 49
- release = 49
- repeat = 28
- balanced press/release
- production dispatch path used
- JamVM exit code 0

Locked scope:
`/dev/input/js0 -> JNI -> M1Input.rawGetState() -> M1InputDispatch.poll() -> MobilePlatform keyPressed/keyReleased/keyRepeated`

### 4.4 M1.9E — Java ARGB framebuffer -> SDL1/fbcon -> LCD presenter

Status: `DEVICE-PASS`

Source evidence:
`tasklog/MIYOO-M1.9E-SDL1-PRESENTER-DEVICE-PASS.md`

Real-device acceptance:
- Java buffer length 307200
- expected ARGB blue/green samples
- SDL `fbcon`
- surface `640x480`, pitch `2560`
- native init 0
- present return 0
- visible blue fullscreen + centered green rectangle
- normal exit
- JamVM/glibj unchanged

LOCK:
The presenter cadence/ownership is proven. Do not replace it merely because another presenter compiles.

### 4.5 M1.9F — Canvas input/render end-to-end

Status: `DEVICE-PASS`

Source evidence:
`docs/checkpoints/M1.9F-DEVICE-PASS.md`

Build identity:
- lock source commit: `fa6fa239c4c2db120b104b306a759425bcb62609`
- run: `35040971638`
- artifact: `10425098012`
- artifact digest: `603822945b08aef969c4eacbee7ef00b75a04f163aebb14a65e79808fa52322d`

Device evidence:
- present count 376
- press 15 / release 15
- repeat 270
- release-no-stuck PASS
- D-pad moves green square
- A/FIRE changes square red
- release returns green
- normal exit
- no hard reset
- JamVM/glibj unchanged

Locked scope:
`js0 -> MIDP Canvas callbacks -> Canvas raster -> FreeJ2ME LCD buffer -> SDL1/fbcon -> physical LCD`

### 4.6 M1.10 — GameCanvas end-to-end

Status: `DEVICE-PASS`

Source evidence:
`docs/checkpoints/M1.10-DEVICE-PASS.md`

Build identity:
- branch: `miyoo-m1.10-gamecanvas-e2e`
- lock source commit: `7898e08934643fe53a15af2c857fa6322200791c`
- run: `35055051764`
- job: `104663364591`
- artifact: `10429949191`
- artifact digest: `4d3a263974719971510b5e6016d7f3af6cf725a2eb170511e59302ba6c8e1043`

Device acceptance:
- blue background visible
- green square visible
- D-pad movement works
- FIRE press -> red
- FIRE release -> green
- normal exit around 30 s
- no hard reset
- source/back/front buffer samples correct

Locked functional chain:
`js0 -> MobilePlatform keyState -> GameCanvas.getKeyStates() -> off-screen PlatformImage -> flushGraphics() -> lcdFrontbuffer -> SDL1/fbcon -> LCD`

Important warning:
A stale diagnostic marker in the old harness printed a failure string even though real r4b frontbuffer + human visual acceptance passed. **Future automation must not reuse that stale marker as the acceptance criterion.**

### 4.7 M1.14 — font semantics matrix

Status: `DEVICE-PASS scoped`

Source evidence:
`docs/checkpoints/M1.14-FONT-SEMANTICS-DEVICE-PASS.md`

Covered on real RG35XX:
- independent size semantics
- BOLD
- ITALIC
- UNDERLINE
- combined style interactions
- MONOSPACE face
- PROPORTIONAL glyph bounds
- regression matrix = 3 faces x 4 styles x 3 sizes = 36 configurations
- Vietnamese text present
- CJK text present
- no severe overlap/clipping/framebuffer corruption in visual review
- screenshot/capture pass
- normal exit

Font resource used:
`20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`

Classification of resource:
`EXPERIMENTAL_NOT_GOLDEN`

Historical Golden font required SHA:
`7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`

LOCK:
- semantics may be reused as DEVICE-PASS behavior;
- **never call resource 20c2... Golden or globally Stable.**

### 4.8 M1.15-r1 — RMS lifecycle

Status: `DEVICE-PASS scoped`

Source evidence:
`docs/checkpoints/M1.15-R1-RMS-LIFECYCLE-DEVICE-PASS.md`

Real-device lifecycle proven:
- create/open
- addRecord
- getRecord
- setRecord
- close
- reopen in same execution
- data verification after reopen
- deleteRecordStore
- verify not found
- JamVM exit 0
- protected hashes unchanged

LOCK:
Do not rewrite RMS merely because later game-specific persistence is suspicious. First prove the game-specific failure independently.

### 4.9 M1.15-r1.1 — RMS cross-process/reboot persistence

Status: `DEVICE-PASS scoped`

Source evidence:
`docs/checkpoints/M1.15-R1.1-RMS-PERSISTENCE-DEVICE-PASS.md`

Real-device A/B:
- Phase A creates deterministic marker and exits
- new process/device reboot
- Phase B opens existing store with create=false
- exact marker recovered
- store deleted
- absence verified
- protected hashes unchanged

LOCK:
Current tested RecordStore persistence behavior is valid. Do not replace it without concrete game/device evidence.

### 4.10 M1.16-r1.2 — blank mutable PlatformImage dimension semantics

Status: `DEVICE-PASS scoped`

Source evidence:
`docs/checkpoints/M1.16-R1.2-PLATFORMIMAGE-BLANK-DIMENSIONS-DEVICE-PASS.md`

Real-device proven:
- `Image.createImage(w,h)` blank mutable image creation
- mutable state
- width access
- height access
- `getGraphics()` acquisition
- runtime gate PASS
- normal JamVM exit
- protected hashes unchanged

Exact scope:
headless blank mutable `PlatformImage` dimension fallback only.

NOT proven by this checkpoint:
- Image -> Sprite constructor
- Sprite rendering
- TiledLayer
- commercial game-layer compatibility

---

## 5. Device-proven / admitted behavior that is NOT a substitute for the DEVICE-PASS whitelist

Primary source:
`docs/FROM-ZERO-DEVICE-PROVEN-MANIFEST-v1.md`

Admitted behavior:
- JamVM L production interpreter binary
- immutable glibj baseline
- Lazy Media Boot
- asynchronous/non-blocking video ownership model
- separate logical LCD vs physical 640x480 output
- dynamic logical size support
- Smart-Fit behavior
- PNG iCCP compatibility in `PlatformImage`, not glibj mutation
- software image blit behavior
- GameCanvas -> canonical frontbuffer flush behavior
- LCD mask must only apply when `Mobile.renderLCDMask == true`
- bounded early native observability

Important historical fact:
The complete From-Zero Foundation v1 artifact **FAILED device acceptance** because green tint, GNU font crashes and JavaSound audio failures still existed. Therefore use the proven contracts, not that whole artifact, as a baseline.

---

## 6. Explicit REJECT / FAIL / HOLD list

### 6.1 SDL2 video on original RG35XX
Status: `FAIL`

Real device:
`SDL_INIT_VIDEO=FAIL error=No available video device`

Use SDL1/fbcon for the proven standalone display path.

### 6.2 Full platform STABLE claim
Status: `FAIL / NOT ACHIEVED`

No historical build in the audited set proves the entire Java platform STABLE across commercial games, media, graphics, game layers and persistence.

### 6.3 Audio
Current classification:
- historical worker-ring contract = `DEVICE-EVIDENCE / device-proven specific behaviors`
- current reconstructed R2B = `DEVICE-EVIDENCE` for audible audio / removal of JavaSound errors
- no clean source-reproducible exact Golden/CN audio build has been promoted to global DEVICE-PASS/STABLE in the current audited baseline

Exact historical accepted native identities:
- Golden core: `4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`
- CN short-prime core: `9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`

Historical contract:
- async callback
- dedicated worker
- ring 16384
- worker chunk 1470
- TSF 14700 Hz
- output 44100 Hz
- mono-x3
- PCM prime ~2940
- PCM underrun re-prime
- native END_OF_MEDIA / BGM resume
- no `retro_run()` audio pumping

Forbidden regressions:
- `MidiSystem.getSequencer()`
- `AudioSystem.getClip()`
- MediaWarmup/eager media boot
- `/dev/snd/seq` boot probe
- 735-frame `retro_run()` audio pumping
- audio lifecycle tied to frame cadence

### 6.4 Transparency / white background
Status: `NOT DEVICE-PASS`

Do not globally key white as transparent.
Do not call R2D transparency stable before independent real-device visual acceptance.

### 6.5 Font resource identity
`20c2...` = `EXPERIMENTAL_NOT_GOLDEN`.

### 6.6 Image -> Sprite / game layer
Status beyond blank image dimensions: `UNRESOLVED / NOT DEVICE-PASS`

Next clean rebuild must resume at Image -> Sprite isolation after reproducing earlier DEVICE-PASS foundations.

### 6.7 Native/RetroArch screenshot path
Status: unresolved as a general platform feature.

Java-side capture worked in diagnostics, but Libretro/RetroArch screenshot capture had separate presentation-lifetime defects.

---

## 7. Forbidden imports for the new clean platform

Do not import:
- CV/CW boot-time/deferred resolution architecture
- old VC7 hot-path diagnostic spam
- unbounded per-frame logging
- 735-frame `retro_run()` audio pumping
- JavaSound MIDI/Clip backend on RG35XX
- MediaWarmup/eager media preparation
- `/dev/snd/seq` boot probing
- GNU Classpath N3/N3.1 byte patches
- transform-cache patch 0008 as mandatory foundation
- unknown old binaries without exact SHA/provenance
- reconstructed font presented as Golden
- any BUILD-PASS-only artifact promoted as device-proven
- any current R2C/R2B/R2D assembled tree as the source tree of the new clean rebuild

R2 artifacts are evidence/reference only.

---

## 8. Canonical clean rebuild order for the NEW CHAT

Suggested branch:
`rg35xx-device-pass-rebuild-v1`

### Phase A — protected runtime
1. Fresh checkout FreeJ2ME exact pin.
2. Require exact JamVM L hash.
3. Require exact glibj hash.
4. Use Java level compatible with the proven JamVM/ClassPath environment.

### Phase B — standalone hardware foundation
5. Reproduce M1.6 SDL1/fbcon display.
6. Device RGB sequence + normal exit.
7. Reproduce M1.7 raw js0 mapping.
8. Reproduce M1.8 MobilePlatform dispatch.
9. Reproduce M1.9E ARGB framebuffer presenter.

### Phase C — MIDP rendering/input
10. Reproduce M1.9F Canvas E2E.
11. Reproduce M1.10 GameCanvas E2E.
12. Keep no-stuck and GameCanvas flush DEVICE-PASS.

### Phase D — font
13. Reproduce M1.14 semantics.
14. Run the 36-configuration matrix on device.
15. Never relabel the reconstructed resource Golden.

### Phase E — RMS
16. Reproduce M1.15-r1 lifecycle.
17. Reproduce M1.15-r1.1 cross-process/reboot persistence.

### Phase F — image/game-layer
18. Reproduce M1.16-r1.2 blank PlatformImage dimensions.
19. Resume **Image -> Sprite isolation**.
20. After Sprite passes, test Sprite transforms/collision/TiledLayer/LayerManager independently.

### Phase G — audio
21. Add audio only after the non-media foundation is clean.
22. Compare standalone SDL audio feasibility against historical RG35XX worker-ring evidence.
23. Never use JavaSound fallback on RG35XX.
24. Require real-game audio acceptance before admission.

### Phase H — compatibility extensions
25. Transparency/tRNS as isolated checkpoint.
26. Additional logical resolutions.
27. Commercial JAR regression corpus.
28. Screenshot/frontend capture after presentation ownership is stable.

---

## 9. Required real-device regression matrix

After every admitted change, re-check affected locked boundaries:

Display:
- SDL1/fbcon
- 640x480 physical surface
- visible colors
- normal exit

Input:
- D-pad
- A/B/X/Y
- START/SELECT
- L/R
- balanced press/release
- no stuck keys

Canvas:
- visible background/primitive
- D-pad visible response
- FIRE press/release visible response

GameCanvas:
- getKeyStates
- off-screen image
- flushGraphics -> frontbuffer
- visible updates continue

Font:
- SYSTEM/MONOSPACE/PROPORTIONAL
- SMALL/MEDIUM/LARGE
- PLAIN/BOLD/ITALIC/UNDERLINE
- Vietnamese + CJK
- no severe overlap/clipping/corruption

RMS:
- create/add/get/set/close/reopen/delete
- separate process/reboot reopen

PlatformImage:
- blank mutable create
- width/height
- getGraphics

Every result must record:
- exact binary hashes
- JamVM/glibj before/after
- exit code
- hard-reset yes/no
- evidence archive name

---

## 10. Commercial game matrix — secondary regression layer

Representative titles:
- KDTT / Tam Quoc Chi 320x240
- NinjaSchool / NinjaSchool2
- Real Football 2015
- Dragon Mania S40v6
- Asphalt 4
- Zombie Infection
- Tan Tay Du Ky 3

For each game record:
- reaches menu/gameplay?
- input?
- audio?
- background/image?
- frames continue?
- normal exit?
- hard reset?
- exact stack/marker?

A single game working does not replace subsystem gates.

---

## 11. New-chat mandatory preflight

Before ANY implementation:

`CURRENT_SYMPTOM:`  
`HISTORY_FOUND:`  
`PREVIOUS_FIX:`  
`PREVIOUS_EVIDENCE_LEVEL:`  
`REGRESSION_RISK:`  
`MINIMAL_PROPOSED_CHANGE:`  
`EXPECTED_DEVICE_TEST:`

Also list every DEVICE-PASS scope that may be touched.

---

## 12. New-chat starting instruction

> Continue RG35XX Java Platform from `MASTER-TASKLOG-RG35XX-DEVICE-PASS-REBUILD-20260922.md`. Ignore the newest assembled R2 runtime as a source baseline. Start a clean rebuild from pinned FreeJ2ME `13ec186903087156c145268f8706eecfaf9f1e50` and preserve only the explicit DEVICE-PASS / locked scopes in the Master. Use Miyoo standalone SDL1/fbcon as the preferred device-proven hardware foundation. Do not mix standalone and Libretro evidence without a new isolated RG35XX device test. First reproduce the locked foundation through M1.16-r1.2, then resume at the first unresolved boundary: Image -> Sprite/game-layer. Audio, transparency and Libretro frontend integration are later isolated checkpoints. Follow `RG35XX_PROJECT_RULES.json` before every change. Full platform remains `STABLE=NO` until the complete real-device regression matrix passes.

---

## 13. Primary evidence files future chats must read first

1. `project-rules/RG35XX_PROJECT_RULES.json`
2. `docs/FROM-ZERO-DEVICE-PROVEN-MANIFEST-v1.md`
3. `tasklog/MIYOO-M1.6-JAVA-SDL1-DISPLAY-DEVICE-RESULT.md`
4. `tasklog/MIYOO-M1.7-JAVA-RAW-JS0-INPUT-DEVICE-RESULT.md`
5. `tasklog/MIYOO-M1.8-PHYSICAL-INPUT-DEVICE-PASS.md`
6. `tasklog/MIYOO-M1.9E-SDL1-PRESENTER-DEVICE-PASS.md`
7. `docs/checkpoints/M1.9F-DEVICE-PASS.md`
8. `docs/checkpoints/M1.10-DEVICE-PASS.md`
9. `docs/checkpoints/M1.14-FONT-SEMANTICS-DEVICE-PASS.md`
10. `docs/checkpoints/M1.15-R1-RMS-LIFECYCLE-DEVICE-PASS.md`
11. `docs/checkpoints/M1.15-R1.1-RMS-PERSISTENCE-DEVICE-PASS.md`
12. `docs/checkpoints/M1.16-R1.2-PLATFORMIMAGE-BLANK-DIMENSIONS-DEVICE-PASS.md`
13. `tasklog/REFERENCE-AUDIO-ARCHITECTURE-AUDIT-20260914.md`
14. `tasklog/VC7R22-GOLDEN-AUDIO-RESTORE-HOTPATH-CLEANUP.md`
15. `tasklog/VC7R23-AUDIO-WORKER-RING-RECONSTRUCTION.md`

If a future assistant has not read these files, it must not claim it knows the proven baseline.

---

## 14. Final frozen status

Explicit locked DEVICE-PASS scopes:
- JamVM L protected production binary
- M1.6 SDL1/fbcon display
- M1.7 Java/JNI raw js0 + 12-control mapping
- M1.8 physical input -> MobilePlatform dispatch
- M1.9E ARGB framebuffer -> SDL1/fbcon presenter
- M1.9F Canvas E2E
- M1.10 GameCanvas E2E
- M1.14 font semantics/regression matrix — scoped; resource EXPERIMENTAL_NOT_GOLDEN
- M1.15-r1 RMS lifecycle — scoped
- M1.15-r1.1 RMS cross-process/reboot persistence — scoped
- M1.16-r1.2 blank mutable PlatformImage dimensions/getGraphics — scoped
- NoMask green-tint symptom fix — DEVICE-PASS scoped per project rules

Not DEVICE-PASS / not stable:
- full commercial-game compatibility
- full Image/Sprite/TiledLayer/LayerManager path
- current reconstructed audio implementation as a complete subsystem
- transparency/white-background handling
- native/RetroArch screenshot capture
- arbitrary Libretro integration of the standalone DEVICE-PASS chain
- full platform

**FULL_PLATFORM_STABLE=NO**
