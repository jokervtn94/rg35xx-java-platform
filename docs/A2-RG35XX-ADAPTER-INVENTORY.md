# A2 — RG35XX Adapter Inventory

Project: `RG35XX-AWEIGIT-R1`
Canonical J2ME: `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
Historical evidence snapshot reviewed: `faa49f9b941db5394265d9b13413e4576ef4694f`
Status: `A2_INVENTORY_COMPLETE`
Production source changed: `NO`
Canonical semantic source changed: `NO`

## 1. Scope and policy

This inventory implements Master Tasklog A2 only. Historical DP/M1 files are evidence/reference candidates, not a production source base. No old Java semantic patch is replayed here.

The adapter boundary is limited to:

- physical video output: SDL1/fbcon, 640x480 LCD;
- physical input: `/dev/input/js0`;
- thin Java/JNI glue into canonical Aweigit `MobilePlatform` ownership;
- protected JamVM/glibj bootstrap;
- filesystem/font glue only when required by later parent integration tests.

Audio/media remains HOLD until non-media SMOKE + CORE INTEGRATION pass.

## 2. Historical evidence source selection

The branch `rg35xx-device-pass-rebuild-v1` records the clean standalone evidence chain, but its own build script materialized proven helper files from the locked snapshot:

`faa49f9b941db5394265d9b13413e4576ef4694f`

Therefore A2 identities are taken from that exact snapshot, not merely from the current branch pathname.

Important: Git blob SHA values below are Git object identities, **not SHA256**. Source SHA256 and rebuilt binary SHA256 remain pending until the files are materialized/built in the controlled A3 workspace.

## 3. Input inventory

### 3.1 Native raw input — REUSE_CANDIDATE

Origin:
`miyoo-m1/m1_8/m1_8_input_jni.c`

Locked Git blob:
`008b5457b595686bc6104a85ca975dca2a6a7881`

Observed contract:

- sole raw owner opens `/dev/input/js0` nonblocking;
- axis7 negative/positive -> UP/DOWN;
- axis6 negative/positive -> LEFT/RIGHT;
- buttons 0/1/2/3 -> A/B/X/Y;
- buttons 5/6 -> L/R;
- button 7 -> SELECT;
- button 8 -> START;
- JNI returns a semantic bitmask and does not directly call MIDP Displayable code.

Decision: **eligible for narrow source reuse in A3**, after renaming/repackaging as RG35XX adapter code and after source/binary SHA256 is recorded.

### 3.2 Thin JNI loader — REUSE_PATTERN

Origin:
`miyoo-m1/m1_8/M1Input.java`

Locked Git blob:
`b707bdc6aa26b86624543749cacbf2da6831be02`

Decision: preserve only the thin-loader pattern. A3 may create an Aweigit-compatible adapter class; class/library naming is not a compatibility contract.

### 3.3 Old dispatch helper — DO_NOT_IMPORT_AS_IS

Origin:
`miyoo-m1/m1_8/M1InputDispatch.java`

Locked Git blob:
`cf21fa84920e8e83926016d49d6143725d718562`

Reason:

- it was written against the old FreeJ2ME-Plus baseline;
- it calls `Mobile.getMobileKey(...)` and static `MobilePlatform.keyPressed/keyReleased/keyRepeated(...)`;
- the pinned Aweigit source instead exposes the current platform through `Mobile.getPlatform()` and has instance event methods on `MobilePlatform`;
- importing it unchanged would create a baseline-specific Java fork rather than adapter glue.

Decision: A3 may recreate only the minimum mapping/edge/repeat glue against the exact canonical Aweigit API. MIDP event semantics remain owned by canonical `MobilePlatform`.

### 3.4 Polling helper — REFERENCE_ONLY

Origin:
`miyoo-m1/m1_9/M19InputPump.java`

Locked Git blob:
`8d4499e10d0d43e5163f456743d409d1bca8300c`

Decision: use only if the clean Aweigit/RG35XX launcher needs a bounded polling owner. Do not create a second raw input owner and do not inject events directly into Displayable objects.

## 4. Video inventory

### 4.1 Thin Java presenter API — REUSE_PATTERN

Origin:
`miyoo-m1/m1_9/M19SdlPresenter.java`

Locked Git blob:
`c3c99dd6070b1a7e1fcb4e248a95b930e81a36fb`

Decision: thin JNI API pattern may be recreated under the RG35XX adapter namespace.

### 4.2 SDL1/fbcon native presenter — PARTIAL_REUSE_CANDIDATE

Origin:
`miyoo-m1/m1_9/m1_9e_presenter_jni.c`

Locked Git blob:
`112a72defcad48351ef42b12357cf5bb373f74ff`

Device-contract-compatible parts:

- dynamically loads `libSDL-1.2.so.0` / `libSDL-1.2.so.0.11.4`;
- forces `SDL_VIDEODRIVER=fbcon`;
- initializes SDL video only;
- opens physical `640x480x32` surface;
- respects physical surface pitch when copying rows;
- uses `SDL_MapRGB` and `SDL_Flip`;
- explicit shutdown.

Part that must **not** be carried blindly:

- `presentARGB()` rejects any Java framebuffer that is not already 640x480. The old chain reached this condition through accumulated headless/resize adaptation. The new Aweigit port must preserve canonical logical LCD sizes and put fit/scaling only in the RG35XX adapter.

Decision: A3 may reuse the SDL1 loader/init/physical-surface/shutdown hardware code, while implementing device-owned logical-to-640x480 fit without modifying canonical image/graphics semantics.

### 4.3 `native/golden/rg35xx_golden_video.*` — REFERENCE_ONLY

These files implement a framed/pipe transport plus RGB565 canvas and callback presentation. They are not the canonical SDL1 physical presenter for the new port and must not reintroduce the old transport model. Their fit algorithm may be consulted only as historical behavior evidence if A3 needs a device-owned fit implementation.

## 5. Lifecycle/bootstrap inventory

### Old `M19CanvasLifecycleLauncher` — REJECT_IMPORT

Reason: it sets `rg35xx.headless.font`, `rg35xx.headless.image.probe`, and `rg35xx.headless.graphics.probe`, which are assumptions from the old patched/headless chain. Bringing it forward would violate the strategy reset.

A3 requirement instead:

- use the clean pinned Aweigit lifecycle/core;
- add only RG35XX bootstrap needed for protected JamVM/glibj, adapter native library path, JAR path, and device-owned input/video startup/shutdown;
- do not patch canonical graphics/image/font semantics simply to reproduce the old launcher.

## 6. Runtime and filesystem

Protected runtime identities remain external contracts:

- JamVM L SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj.zip SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- toolchain: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`

A2 does not copy or modify runtime binaries. A3 must fail closed if protected hashes differ.

Filesystem policy:

- no broad SD cleanup;
- no wildcard deletion;
- install/rollback paths must be exact and scoped to the Java application package;
- old hard-coded Miyoo/Aweigit paths are not adopted as RG35XX paths without device evidence.

## 7. Font and audio classification

Font:

- semantics evidence remains DEVICE-PASS scoped;
- reconstructed resource SHA256 `20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9` remains `EXPERIMENTAL_NOT_GOLDEN`;
- no font source/resource is imported in A2.

Audio/media:

- `HOLD_UNTIL_CORE_INTEGRATION_PASS`;
- no old `native/rg35xx_audio_*`, media cache/event/runtime code, JavaSound workaround, MediaWarmup, or audio pump enters A2/A3.

## 8. Canonical compatibility finding

Pinned Aweigit `MobilePlatform` already owns:

- logical LCD `PlatformImage`/`PlatformGraphics`;
- `resizeLCD()`;
- `getLCD()`;
- `keyPressed`, `keyReleased`, `keyRepeated`;
- GameCanvas key-state update.

Pinned Aweigit `Anbu` already routes frontend key events through `Mobile.getPlatform().keyPressed/keyReleased/keyRepeated`.

Therefore the RG35XX input adapter should terminate at that canonical platform boundary. It must not introduce a second MIDP semantics implementation.

## 9. A2 gate result

`A2_ADAPTER_INVENTORY=PASS`

Approved for A3 design/import candidate:

1. raw js0 native acquisition/mapping;
2. thin JNI input loader pattern;
3. thin JNI video presenter pattern;
4. SDL1/fbcon physical display initialization/presentation/shutdown subset;
5. protected JamVM/glibj identities and toolchain gate.

Explicitly not approved for direct import:

1. old `M1InputDispatch.java` implementation;
2. old headless lifecycle launcher;
3. old Java/image/graphics/font patch chain;
4. old pipe/Libretro-style transport as production foundation;
5. audio/media sources;
6. any DP JAR.

## 10. Next parent stage

Next stage: **A3 — Java/runtime compatibility**.

Before A3 source changes, issue a fresh required prechange report. A3 must create the smallest Aweigit-compatible adapter delta, generate a canonical-diff manifest, compile to the protected JamVM-compatible bytecode level, record hashes, and then proceed to A4 SMOKE. A3 BUILD-PASS must not be reported as DEVICE-PASS.
