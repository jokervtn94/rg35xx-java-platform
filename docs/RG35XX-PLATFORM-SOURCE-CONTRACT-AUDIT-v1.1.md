# RG35XX PLATFORM SOURCE CONTRACT AUDIT v1.1

**Project:** Port FreeJ2ME to original RG35XX  
**Status:** `AUDIT_LOCKED / DOCS_ONLY / NO_RUNTIME_CHANGE`  
**Authority:** `RG35XX-PORT-RULER-LOCKED-v1.md`  
**Canonical:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`  
**RG35XX reset/base:** `e7b0860310fd5204e1d1f2d01c992002b8660df2`

## 1. Workflow correction

The project is a platform port, not a commercial-game patch queue.

Locked order:

```text
PINNED AWEIGIT SOURCE / BEHAVIOR
        ↓
WHOLE-SOURCE + METHOD COVERAGE AUDIT
        ↓
MEASURED ORIGINAL-RG35XX HARDWARE CONTRACT
        ↓
COMPLETE RG35XX BOUNDARY BACKING
        ↓
ONE GENERIC INSTALLABLE PLATFORM
        ↓
ONE PLATFORM EXERCISER
        ↓
TIER-0 PHYSICAL REGRESSION
        ↓
TIER-1 COMPATIBILITY
```

`game -> missing method -> micro-fix -> next game -> micro-fix` is prohibited.

## 2. Exact Golden P0 authority recovered

Historical accepted checkpoint and artifact:

```text
SOURCE_CHECKPOINT=5b7a8e88bd32a735a1342715e718eecf8cf10fad
WORKFLOW_RUN_ID=36079435727
ARTIFACT_ID=10841810644
ARTIFACT_DIGEST_SHA256=2292df4c140d4f8a7479fbdc432bef194bdd9b83057ab1e6fb3f38df4c516c6f
```

Exact device-accepted runtime bytes:

```text
freej2me-rg35xx.jar=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
librg35xx_input.so=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
librg35xx_video.so=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
libaudio.so=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
A1P5_PRIME=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

The previous raw-JAR-different semantic-equivalent A8 control is not Golden authority.

## 3. Whole canonical source inventory

Repeatable CI audit:

```text
TOTAL_CANONICAL_JAVA_FILES=921
A3_DEFERRED_JAVA_FILES=658
CURRENT_STAGED_2D_MIDP_JAVA_FILES=263
AWT_OR_IMAGEIO_DEP_FILES_ALL_SOURCE=8
JAVA6_COMPAT_RISK_FILES_ALL_SOURCE=275
NATIVE_SURFACE_FILES_ALL_SOURCE=204
NETWORK_RUNTIME_DEP_FILES_ALL_SOURCE=16
CANONICAL_INCOMPLETE_OR_STUB_RISK_FILES_ALL_SOURCE=260
NULL_FALSE_RETURN_REVIEW_FILES_ALL_SOURCE=66
```

The 658 deferred files are dominated by `org.lwjgl`, M3G and Micro3D. Current RG35XX is therefore a 2D/MIDP subset with 3D explicitly deferred, not full pinned-Miyoo feature parity.

## 4. Current staged 263-file runtime risk inventory

Within the 263 staged Java files:

```text
AWT_OR_IMAGEIO_DEP_FILES=6
JAVA6_COMPAT_RISK_FILES=15
NATIVE_SURFACE_FILES=2
NETWORK_RUNTIME_DEP_FILES=12
CANONICAL_INCOMPLETE_OR_STUB_RISK_FILES=28
NULL_FALSE_RETURN_REVIEW_FILES=42
```

These are static flags, not failure verdicts. Compile PASS is not module DEVICE-PASS; TODO/null/false may be canonical limitations; AWT import alone is not necessarily a Raw2D failure.

## 5. Raw2D graphics source coverage

Pinned `PlatformGraphics` inventory:

```text
PLATFORMGRAPHICS_METHODS_SCANNED=52
METHODS_WITH_AWT_BACKING_DEPENDENCY=38
AWT_DEP_METHODS_WITHOUT_RG35XX_STAGE_MENTION=16
```

Raw2D intentionally nulls AWT backing, while the accepted chain overlays only part of the canonical surface.

Protected raw paths include raw construction/state, `fillRect`, `drawLine`, `drawRect`, image blit, `drawRegion`, `drawRGB`, accepted text, rectangle-only DirectGraphics fillPolygon and ClipTranslate.

Coverage gaps requiring platform completion include `clearRect`, `copyArea`, arc/round-rect fill/draw, `setAlphaRGB`, AWT BufferedImage helpers, DirectGraphics drawPixels/polygon/triangle paths, non-rectangle fillPolygon and DirectGraphics getPixels int/short paths.

Exact-A8 MIDP six-argument `fillTriangle` is the already physically proven example of this class of gap. COMP-02 is retained as platform-gap evidence, not architecture driver.

## 6. Image and text coverage

Canonical image decode uses ImageIO; RG35XX Core2D raw decode is PNG-focused. PNG/alpha/transform/drawRegion/Adam7 accepted scope remains protected; non-PNG decode parity is partial.

Canonical font rendering uses AWT font/FontMetrics. RG35XX bitmap glyph rendering has limited glyph/face/style/proportional fidelity. Font/text therefore remains `PARTIAL` and must be handled as platform completion, not game-specific fixes.

## 7. Canvas/GameCanvas/lifecycle

Protected scoped behavior includes canonical Canvas/GameCanvas ownership, input terminating at MobilePlatform, repeated flushGraphics, physical controller input, Java6 MIDletLoader compatibility and accepted lifecycle behavior.

Platform-module validation is still needed for resizeLCD, pointer/touch production, generic logical dimensions and broader lifecycle/resource cases.

## 8. Input/frontend parity

Current physical RG35XX contract is:

```text
UP DOWN LEFT RIGHT
A B X Y
L1 R1 START SELECT
```

Miyoo additionally provides L2/R2, keymap.cfg, runtime key/hotkey modes, touch/mouse emulation and rotation. These are frontend/capability gaps. L2/R2 hardware numbers must not be guessed.

## 9. I/O/provider matrix

Canonical providers are present for FileConnection, HTTP, HTTPS, TCP socket and UDP/datagram. WMA/SMS is simulated. These are not yet original-RG35XX module DEVICE-PASS.

Canonical incomplete/unavailable areas include partial Bluetooth without LocalDevice/BTSPP provider, OBEX without Bluetooth transport, deliberately unavailable PIM, Sensor API without SensorManager provider, absent JSR-179 Location root, Nokia Sound stubs and unsupported/no-op Samsung AudioClip behavior. They must not automatically be classified as RG35XX bugs.

## 10. Media/audio

Protected design is canonical PlatformPlayer semantics + Java6 cache-path compatibility + RG35XX SDL1_mixer + A1P5 route prime. Historical accepted evidence records audible WAV/MIDI and GoW regression after A1P5. Exact Golden bytes are authoritative; API PASS alone is not audible proof.

## 11. RMS

Core RMS semantics remain canonical. Canonical TODO/partial behavior must not be changed as an RG35XX fix without a proven platform divergence.

## 12. 3D

```text
M3G=DEFERRED_CAPABILITY
MICRO3D=DEFERRED_CAPABILITY
LWJGL_OPENGL=DEFERRED_CAPABILITY
```

Before enabling 3D: probe physical EGL/GLES, verify ABI, map native/AWT dependencies and create a separate 3D workstream.

## 13. Audit conclusion

Recurring basic-class failures are consistent with incomplete RG35XX platform backing, especially Raw2D/DirectGraphics/image/font/frontend coverage.

The audit is sufficient to authorize P1 **design**, not uncontrolled runtime changes.

## 14. P1 owner

```text
WORK_UNIT=P1-CORE-2D-SOURCE-COVERAGE
PARENT_AUTHORITY=EXACT_GOLDEN_057567
CANONICAL_AUTHORITY=AWEIGIT_ca11dfe8
GAME_SPECIFIC_CODE=FORBIDDEN

SCOPE:
  PlatformGraphics raw MIDP primitive coverage
  Nokia DirectGraphics raw coverage
  supporting RG35XXCore2D primitives
  method-level host gates
  one platform-exerciser graphics matrix

OUT_OF_SCOPE:
  audio
  input mapping
  video presenter
  RMS semantics
  lifecycle redesign
  networking
  3D
  game-specific conditions
```

Before implementation, every P1 method must lock canonical behavior, exact Raw2D gap, raw equivalent, clipping/translation/alpha semantics, regression gate and physical exerciser observation.

## 15. Current lock

```text
P0_EXACT_GOLDEN_RECOVERED=YES
PLATFORM_SOURCE_AUDIT_V1_1=LOCKED
GAME_DRIVEN_RUNTIME_PATCHING=STOPPED
AUDIO01=ARCHIVED_DIAGNOSTIC
COMP02_FILLTRIANGLE=PLATFORM_GAP_EVIDENCE
RUNTIME_CHANGE_AUTHORIZED=NO
NEXT_ACTION=P1_CORE_2D_DESIGN_AND_TEST_MATRIX
```
