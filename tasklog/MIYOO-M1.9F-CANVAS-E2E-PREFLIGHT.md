# M1.9F Canvas end-to-end preflight

CURRENT_SYMPTOM: M1.9E proves software framebuffer -> SDL1/fbcon -> physical LCD, but real Canvas callback -> framebuffer -> LCD is not DEVICE-PASS.
HISTORY_FOUND: YES. M1.6 display DEVICE-PASS; M1.8 input dispatch DEVICE-PASS; M1.9D raster device-proven; M1.9E presenter DEVICE-PASS.
PREVIOUS_FIX: preserve all proven boundaries and connect a minimal real MIDP Canvas using only setColor/fillRect to the M1.9E presenter.
PREVIOUS_EVIDENCE_LEVEL: M1.6/M1.8/M1.9E DEVICE-PASS; M1.9D DEVICE-EVIDENCE PASS.
REGRESSION_RISK: medium; lifecycle/display-current framebuffer access is the only new integration boundary.
MINIMAL_PROPOSED_CHANGE: real Canvas with blue background and green 80x80 square; D-pad moves square; A/FIRE changes square red while held; no drawString/font/audio/game-specific logic.
EXPECTED_DEVICE_TEST: 30 seconds. Observe square move with D-pad and change green->red on A. Require balanced press/release, direction>0, fire>0, present>0, normal exit, protected hashes unchanged.
DEVICE_PASS=NO
FULL_PLATFORM_STABLE=NO
