# DP-R11 LayerManager diagnostic

CURRENT_SYMPTOM:
- DP-R10-B is real-device PASS for TiledLayer rendering and Sprite↔TiledLayer transformed collision.
- LayerManager has not yet been admitted on the clean DP chain.

HISTORY_FOUND=YES

PREVIOUS_FIX:
- DP-R8-B Sprite↔Sprite transformed collision rectangle: DEVICE-PASS scoped.
- DP-R10-B Sprite↔TiledLayer transformed collision rectangle: DEVICE-PASS scoped.
- DP-R9/DP-R10 TiledLayer render/animated tile path: DEVICE-PASS scoped.

SOURCE_REVIEW:
- Pinned FreeJ2ME-Plus LayerManager.java and current devel LayerManager.java are byte-identical.
- No upstream LayerManager delta justifies a pre-emptive runtime patch.

PREVIOUS_EVIDENCE_LEVEL:
- LayerManager: UNVERIFIED in the current clean rebuild.

REGRESSION_RISK:
- High if LayerManager, Sprite, TiledLayer, renderer, audio, input, SDL1, JamVM or glibj are modified together.

MINIMAL_PROPOSED_CHANGE:
- NO runtime change.
- Rebuild exact DP-R10-B runtime.
- Add one diagnostic MIDlet only.
- Test:
  * append / insert / remove / getLayerAt / getSize
  * z-order (index 0 must paint in front)
  * visibility
  * view-window clipping and destination translation
  * Graphics clip and translation restoration after LayerManager.paint()
  * invalid negative view-window dimensions throw IllegalArgumentException
- No Sprite/TiledLayer/PlatformImage/PlatformGraphics implementation change.
- No audio/media work.

VISIBLE DEVICE STATUS:
- blue background + yellow box = running
- blue background + green box = all gates PASS
- blue background + red box = one or more gates FAIL
- log remains authoritative

EXPECTED_DEVICE_TEST:
- all API/order/visibility/view-window/state-restore gates PASS
- normal exit code 0
- JamVM/glibj hashes unchanged
- normal return to GarlicOS; no hard reset

STATUS:
BUILD-PASS=NO
DEVICE-PASS=NO
DEVICE-TEST-PENDING=YES
STABLE=NO
