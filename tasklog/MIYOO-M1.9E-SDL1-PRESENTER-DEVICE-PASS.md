# M1.9E SDL1/fbcon framebuffer presenter — DEVICE-PASS

## CURRENT_SYMPTOM
M1.9D software raster was device-proven but not yet connected to the physical LCD.

## HISTORY_FOUND
M1.6 Golden SDL1/fbcon display is DEVICE-PASS. M1.9D setColor/fillRect software framebuffer is device-proven.

## PREVIOUS_FIX
M1.9E connects the M1.9D Java ARGB int[307200] framebuffer to a JNI presenter derived from the exact M1.6 SDL1/fbcon backend without modifying the Golden M1.6 source.

## PREVIOUS_EVIDENCE_LEVEL
M1.6 DEVICE-PASS; M1.9D DEVICE-EVIDENCE/PASS checkpoint.

## DEVICE EVIDENCE — 2026-09-15
Real Anbernic RG35XX result:
- M1_9E_BUFFER_LENGTH=307200
- M1_9E_RASTER_BLUE=ff0000ff
- M1_9E_RASTER_GREEN=ff00ff00
- M1_9E_RASTER_PRECHECK=PASS
- M1_9E_SDL_DRIVER=fbcon
- M1_9E_SURFACE=640x480 PITCH=2560
- M1_9E_NATIVE_INIT_RC=0
- M1_9E_PRESENT_RC=0
- M1_9E_SDL_PRESENTER_MARKER=PASS
- M1_9E_NORMAL_EXIT=PASS
- M1_9E_DEVICE_ACCEPTANCE_MARKER=PASS
- JAMVM_EXIT_CODE=0
- M1_9_PROTECTED_HASHES=PASS
- M1_9E_EXECUTION_RESULT=PASS

Physical visual confirmation: blue fullscreen with centered green rectangle was observed on the RG35XX LCD.

Protected runtime hashes remained unchanged:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

## CLASSIFICATION
M1.9E framebuffer -> SDL1/fbcon -> physical RG35XX LCD = DEVICE-PASS.
This does NOT promote full M1.9 Canvas/GameCanvas integration and does NOT promote the full platform to STABLE.

## REGRESSION_RISK
Low if M1.6 Golden presenter behavior, M1.8 input mapping/dispatch, and M1.9A-D proven headless paths remain unchanged.

## NEXT MINIMAL VARIABLE
Connect a real MIDP Canvas lifecycle/render surface to the M1.9E presenter while preserving M1.8 production input. Prove D-pad and A/FIRE callbacks change visible Canvas-rendered pixels on the physical LCD, with balanced release, bounded repeat, normal exit, and protected hashes unchanged.
