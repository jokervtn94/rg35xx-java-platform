# DP-R9 TiledLayer render + Sprite/TiledLayer collision diagnostic

CURRENT_SYMPTOM:
- DP-R8-B Sprite-vs-Sprite transformed pixel collision is real-device PASS for all 8 transforms.
- TiledLayer rendering and Sprite-vs-TiledLayer collision are not yet admitted.
- Pinned TiledLayer.java and current devel TiledLayer.java are byte-identical at the source blob level, so there is no evidence-based TiledLayer patch to apply before testing.
- Sprite.collidesWith(TiledLayer, boolean) in the pinned runtime still uses the raw collisionRectX/Y/Width/Height geometry; DP-R8 changed only Sprite-vs-Sprite collision geometry.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R3-B: drawRegion / Sprite rendering = DEVICE-PASS scoped.
- DP-R4-B: headless PlatformImage.getRGB = DEVICE-PASS scoped.
- DP-R5-B: untransformed Sprite pixel collision = DEVICE-PASS scoped.
- DP-R8-B: Sprite-vs-Sprite transformed pixel collision 8/8 = DEVICE-PASS scoped.

PREVIOUS_EVIDENCE_LEVEL:
- TiledLayer API state management: UNVERIFIED in clean DP rebuild.
- TiledLayer.paint(): UNVERIFIED in clean DP rebuild.
- Sprite-vs-TiledLayer bounding collision: UNVERIFIED.
- Sprite-vs-TiledLayer pixel collision under transforms: UNVERIFIED.

REGRESSION_RISK:
- High if TiledLayer, Sprite/TiledLayer collision, LayerManager, edge-touch semantics, collidesWith(Image), audio, input, SDL1, JamVM, glibj, or font are changed together.

MINIMAL_PROPOSED_CHANGE:
- Runtime change: NONE.
- Rebuild exact DP-R8-B runtime.
- Add one diagnostic MIDlet only.
- Test TiledLayer static cells, transparent cell 0, animated tile mapping, and offscreen rendering pixel results.
- Test Sprite-vs-TiledLayer bounding/pixel collision for all 8 Sprite transforms.
- Do NOT patch TiledLayer or Sprite in DP-R9.
- Do NOT test LayerManager yet.

VISIBLE STATUS:
- The diagnostic also shows a simple Canvas status so the real device is not intentionally black for the entire test.
- Blue background + yellow box = running.
- Blue background + green box = diagnostic PASS.
- Blue background + red box = diagnostic FAIL.
- The visual indicator is informational only; log gates remain authoritative.

EXPECTED DEVICE TEST:
- TiledLayer constructor/getters/cells/animated tile gates PASS.
- TiledLayer offscreen paint gate PASS.
- All 8 Sprite-vs-TiledLayer transform gates are recorded.
- If all 8 pass, DP-R9 can be admitted without a runtime patch.
- If a subset fails, use the failure pattern to define the next one-variable A/B patch.
- JamVM/glibj hashes unchanged.
- Normal exit; no hard reset.

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
