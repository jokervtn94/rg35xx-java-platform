# B4-VIDEO-MASK-R2-AB — RG35XX software LCD-mask hard bypass

Status: BUILD-PASS / DEVICE-TEST-PENDING / STABLE=NO
Primary variable: RG35XX_SOFTWARE_LCD_MASK_BYPASS_ONLY

## Preflight

### CURRENT_SYMPTOM

B4-VIDEO-MASK-R1-AB installed correctly, but Real Football 2015 still displays a strong global green tint.

R1 device evidence:
- JamVM L: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj.zip: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- B4 core: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- R1 runtime: b8d56694887e578a4d3a2e84effab6fe768806486e230b11b582f33a89a60753
- installer: PASS
- hard native hang: not observed in captured sessions
- R1 result for green tint: FAIL / DEVICE-EVIDENCE, not DEVICE-PASS

The two Real Football screenshots remain mathematically constrained by the historical green mask RGB value 0x77EF5A: no captured RGB pixel contains bits outside that mask.

### HISTORY_FOUND

Pinned FreeJ2ME contains a simulated LCD/backlight color-mask system:
- Mobile.maskIndex defaults to 1
- Mobile.lcdMaskColors[1] = 0xFF77EF5A
- Mobile.renderLCDMask defaults false
- Display.flashBacklight() can set Mobile.renderLCDMask=true
- Display.vodafoneFlashBacklight() can set Mobile.renderLCDMask=true
- com.nokia.mid.ui.DeviceControl.setLights(..., level != 0) can set Mobile.renderLCDMask=true

Historical VC7R15 proved that gating the mask when renderLCDMask=false removes the green tint in its tested scene. R1 restored that exact gate to clean B4, but current Real Football evidence shows that state-gating alone is insufficient for this game/checkpoint.

### PREVIOUS_FIX

R1 changed PlatformGraphics.flushGraphics() from unconditional mask use to:
- fast path when renderLCDMask is false;
- apply lcdMaskColors[] in slow path only when renderLCDMask is true.

### PREVIOUS_EVIDENCE_LEVEL

Historical no-mask symptom fix: DEVICE-PASS for its tested green-tint symptom.
B4 R1 on current device/game: BUILD-PASS + DEVICE-EVIDENCE + FAIL.

### REGRESSION_RISK

Keep the delta to PlatformGraphics.flushGraphics() only.

Do not change:
- JamVM L
- GNU Classpath
- B4 native core
- Lazy Media
- RGB565 transport
- native receiver/presenter
- audio
- font
- resolution
- game JAR
- hot-path diagnostics

FunLights overlay remains enabled when requested.

### MINIMAL_PROPOSED_CHANGE

Layer R2 on top of the exact R1 source behavior:
- preserve Mobile.renderLCDMask state and all MIDP/Nokia light APIs;
- stop using lcdMaskColors[] to transform RG35XX game pixels;
- fastBlit depends only on whether FunLights needs the slow path;
- slow path copies the source pixel unchanged before optional FunLights blending.

This is a RG35XX runtime policy checkpoint. It does not attempt to redefine generic FreeJ2ME semantics upstream.

### EXPECTED_DEVICE_TEST

Use Real Football 2015 first.

Acceptance:
1. Installer only accepts exact R1 runtime + protected B4 core/JamVM/glibj.
2. Real Football splash/game image no longer has the global green mask.
3. Input still works.
4. Game can exit normally; no hard reset required.
5. JamVM/glibj/core hashes remain unchanged.
6. R2 runtime hash matches the build artifact.
7. Hot-path cleanup remains excluded.

BUILD-PASS does not imply DEVICE-PASS.
STABLE remains NO.


## Build result — 2026-09-21

- Source commit: 224faae000543133b3576f098add84a313aa3a43
- Workflow run: 35556841888
- Job: 106201988774
- Artifact: 10620302602
- Artifact digest / ZIP SHA256: 6fa45472599962a905b66e1f919e003bcfa22f7f5d20ee52993fa53bef3352bd
- Runtime SHA256: 90c4d9455e82ca8df5dce667c0a836356dfc69f8b756b6cafe1ea9ac0b9bc1ee
- Preserved B4 core SHA256: 56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c
- Java class count: 1334
- Java major: 50 gate PASS
- R1 source reproduction gate: PASS
- R2 software-mask bypass gate: PASS
- Package SHA manifest: PASS
- BUILD-PASS: YES
- DEVICE-PASS: NO / DEVICE-TEST-PENDING
- STABLE: NO

Exact scope:
- PlatformGraphics.flushGraphics() no longer uses lcdMaskColors[] to alter RG35XX framebuffer pixels.
- Mobile.renderLCDMask state/API behavior is preserved.
- FunLights overlay behavior is preserved.
- Native core, audio, font, resolution, JamVM L and GNU Classpath are unchanged.
- Hot-path cleanup is not included.
