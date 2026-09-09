# VC6 device evidence — PNG path advanced, font/AWT is the next blocker

Date: 2026-09-09
Branch: `verified-clean-platform-v1`

## Scope

This checkpoint records device evidence after installing the Verified Clean VC6 Atomic Acceptance package. It does not admit any font, audio, CV/CW resolution, or GNU Classpath modification.

## Installed identities

Device install verification reported PASS with these payload identities:

- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- GNU Classpath `glibj.zip`: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- VC6 observed core aliases: `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`
- VC6 runtime aliases: `cdb864b4b6b1418ad49088092973656311f06cf051e8fdb064ed2aa2056b1203`

## Native/video evidence

`freej2me-vc3-early.log` shows the B4 early path completing for multiple real JARs:

`CORE_INIT -> RUNTIME_PATH -> JAVA_OPEN_BEGIN -> PIPE_CREATE -> FORK_RESULT -> JAVA_READY -> LOAD_GAME_ENTER -> IPC_LOAD_SENT -> IPC_RUN_SENT -> FIRST_FRAME_HEADER -> FIRST_FRAME_PUBLISH -> FIRST_PRESENT -> CORE_DEINIT`

Observed sessions include KDTT Tam Quoc, KDTT Dai nao thien cung, God of War Betrayal, NinjaSchool1 and Qix. Video generations continue into the hundreds before deinit, so the current failure is not a first-frame/native receiver failure.

Current VC6 sessions in this evidence are presenting a `240x320` source as `360x480`. Dynamic-resolution admission remains out of scope here; do not reintroduce CV/CW while resolving the current blocker.

## PNG compatibility conclusion

The previous blocking exception was:

`IllegalArgumentException: Wrong major version number:4`

from GNU Classpath PNG ICC decoding.

That exception is not present in the current captured Java error log. The game now progresses to text rendering and fails deeper in the AWT font stack. This is enough to classify VC6 as having advanced beyond the previously observed ICC-v4 blocker for these runs, but it is not sufficient to call the whole VC6 platform DEVICE-PASS because the expected `RG35XX-PNG-ICCP: stripped ancillary iCCP chunk` marker was not captured in the supplied log.

Status: `PNG_ICCP_SOURCE_COMPAT = DEVICE-PROVEN-THROUGH-PREVIOUS-BLOCKER`, not full platform acceptance.

## New P0 blocker: GNU AWT/OpenType text path

Two independent failures are captured in `freej2me-java-error.log` beneath `PlatformGraphics.drawString` / `drawChar`:

1. `NullPointerException` in `gnu.java.awt.java2d.AbstractGraphics2D.renderScanline`, reached through `drawGlyphVector -> drawString`.
2. `ArrayIndexOutOfBoundsException` in `gnu.java.awt.font.opentype.truetype.Zone.combineWithSubGlyph`, reached through `GlyphLoader.loadCompoundGlyph -> TrueTypeScaler.getOutline -> OpenTypeFont.getGlyphOutline -> GNUGlyphVector -> AbstractGraphics2D.drawString`.

The second failure occurs on a real game thread. This makes the AWT/OpenType glyph raster path the next correctness blocker.

## Architectural decision

Do not patch `glibj.zip`. B2 remains immutable.

Do not restore the later ASCII 5x7 renderer as the normal path. It is not the device-proven Golden font architecture and cannot satisfy Vietnamese/Latin Extended/CJK coverage.

The next stage is **VC7 — Golden Unicode Font Path** in FreeJ2ME `PlatformGraphics`, using the recovered Golden resource contract:

- resource: `/org/recompile/mobile/rg35xx-font.bin`
- exact length: `727008`
- SHA-256: `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`
- 22719 glyph records, 32 bytes each, 16 raster rows
- normal advance 8, wide/CJK advance 12
- scale 1 for active font height < 26, scale 2 otherwise
- direct framebuffer raster only with translation + clip + canvas-bound checks

VC7 must bypass GNU AWT glyph rasterization for the normal J2ME text path while preserving VC6 PNG compatibility and the B4 native/video foundation unchanged.

## Admission rules for VC7

VC7 may change only FreeJ2ME font/text handling and add the verified Golden bitmap resource. It must not change:

- JamVM L
- `glibj.zip`
- native core/video/Smart-Fit
- VC6 PNG iCCP compatibility
- media/audio
- CV/CW resolution behavior

The exact Golden font binary is not stored in this repository. VC7 assembly must therefore accept it only as an external verified input and fail closed on size/hash mismatch.
