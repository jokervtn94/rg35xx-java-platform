# P2B Font / Text Contract Audit v1

Status: AUDIT_ONLY
Branch parent: `77a36526e0f6d875c57c7e9a973e0c1a05573721`
Pinned Miyoo/Aweigit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
P2A physical module acceptance: PASS on original RG35XX (checkpoint recorded separately; this audit branch is not parented from the physical-test branch).

## Locked rule disposition

`RUNTIME_PATCH=FORBIDDEN` until every required port-decision field is resolved.

## Port decision record

```text
PORT_UNIT=P2B_FONT_TEXT
MIYOO_SOURCE=src/javax/microedition/lcdui/Font.java + src/org/recompile/mobile/PlatformGraphics.java + src/org/recompile/freej2me/Anbu.java
MIYOO_CURRENT_BEHAVIOR=Anbu loads ./font.ttf through java.awt.Font.createFont(TRUETYPE), falls back to new java.awt.Font("MiSans Normal",PLAIN,12); MIDP Font derives style/point-size and uses AWT FontMetrics; PlatformGraphics uses Graphics2D.drawString plus AWT FontMetrics anchor calculations
FREEJ2ME_REFERENCE=hex007/freej2me PlatformFont/Font/PlatformGraphics: AWT Graphics2D/FontMetrics backend, logical SansSerif/Monospaced faces, underline TextAttribute; semantic reference only, not replacement lineage
JDK_OPENJDK_REFERENCE_IF_REQUIRED=REQUIRED because pinned Miyoo delegates metrics/raster/deriveFont/drawString to java.awt
RG35XX_MEASURED_LIMITATION=production rg35xx.raw2d path intentionally bypasses AWT Toolkit/BufferedImage font initialization and keeps gc/fm/awtFont null; a headless backing is therefore required
EXACT_FAILURE_OR_MISSING_CONTRACT=current RG35XX raw backing uses synthetic fontHeight/fontAscent/fontDescent/charWidth plus a 5x7 uppercased ASCII bitmap renderer; unknown glyphs become boxes; lowercase/case, Unicode glyphs, italic and exact AWT metrics/raster are not canonically reproduced; text anchors use a separate bitmap-box model
FAILURE_OWNER=RG35XX_GRAPHICS_BOUNDARY
WHY_MIYOO_AS_IS_CANNOT_WORK=original RG35XX production path has no accepted desktop AWT/Graphics2D font backend and intentionally runs Raw2D with those objects null
MINIMUM_REQUIRED_DELTA=UNRESOLVED pending exact font asset identity/provenance and JDK8 backend differential evidence
FILES_ALLOWED_TO_CHANGE=UNRESOLVED; expected owner scope is Font raw backing + PlatformGraphics raw text path + RG35XXCore2D font backing and test/build scaffolding only
FILES_FORBIDDEN_TO_CHANGE=JamVM; glibj.zip; protected input/video/audio natives; canonical Aweigit gitlink; P2A image decode semantics; non-text graphics owners; media/RMS/input/frontend
PARENT_REGRESSION_GATES=P1A graphics host regressions + P2A 150-case image decode host gate; no Tier-0 physical game run during P2B host work
HOST_DIFFERENTIAL_GATE=REQUIRED against pinned Miyoo/JDK8 backend using the exact authorized font asset
MODULE_INTEGRATION_GATE=REQUIRED one P2B Font/Text module exerciser
PHYSICAL_GATE=REQUIRED one original-RG35XX module physical test only after host/module gates pass
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
```

## Source facts locked before diagnostics

1. Pinned Miyoo `Font.java` blob is `51bbe0b933055761bb4e128dfee6969d0b4e86d7`.
2. Release tag `2.0` uses the same `Font.java` blob, so the official Miyoo release package is relevant as a diagnostic source for the external font asset used by that implementation.
3. The pinned source tree contains no `.ttf` file. README declares `font.ttf` as required runtime content and explicitly says replacing it changes the in-game font.
4. The accepted RG35XX P2A physical payload contains no `font.ttf`.
5. Pinned Miyoo `Font.convertSize` maps MIDP SMALL/MEDIUM/LARGE to 12/14/16.
6. Pinned Miyoo ignores MIDP face when deriving its custom global font: all faces derive from `Anbu.getFont()`.
7. Pinned Miyoo text width/height/char width come from AWT `FontMetrics`; `getBaselinePosition()` returns the converted point size, not `FontMetrics.getAscent()`.
8. Pinned Miyoo `PlatformGraphics.drawString` computes horizontal anchors with `fm.stringWidth()` and vertical anchor baseline adjustments with `fm.getAscent()/getDescent()`, then calls `Graphics2D.drawString`.
9. Current RG35XX raw path is intentionally provisional for font/text: 5x7 glyphs, uppercasing, box fallback, synthetic metrics and manual bold/underline.

## Diagnostic plan

R1 — exact source/asset identity
- prove pinned source has no TTF;
- download official `miyoomini-freej2me.zip` release asset as diagnostic evidence;
- locate every `font.ttf`, record ZIP SHA256, font SHA256, path, size;
- identify font internal name/family/PostScript name/num glyphs through JDK8;
- do not treat release packaging as a production parent.

R2 — JDK8 backend behavior
- use exact `Font.createFont` / `deriveFont` / `FontMetrics` / `Graphics2D.drawString` calls;
- record sizes 12/14/16 and style values 0..7;
- record height/ascent/descent/leading, representative widths, canDisplay masks and deterministic ARGB raster hashes;
- classify UNDERLINED combinations according to measured JDK8 behavior rather than assumption.

R3 — candidate authorization decision
- only after R1/R2, decide whether the release font asset has sufficient identity/provenance for redistribution/embedding;
- if provenance is insufficient, do not copy it into RG35XX; choose a legal backing only if it can preserve the pinned Miyoo contract and document the unavoidable asset-policy difference;
- no runtime candidate branch until the minimum delta and allowed file scope are exact.

## Current status

```text
P2B_SOURCE_AUDIT=PASS
P2B_FONT_ASSET_IDENTITY=UNVERIFIED
P2B_FONT_ASSET_PROVENANCE=UNVERIFIED
P2B_JDK8_BACKEND_DIAGNOSTIC=NOT_TESTED
P2B_RUNTIME_PATCH=FORBIDDEN
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
```
