# VC7R2 Proven View — recovery/tasklog checkpoint

Date: 2026-09-10
Branch: `verified-clean-platform-v1`
Status: **BUILD-PASS / DEVICE-TEST-PENDING**

This checkpoint exists so the RG35XX platform can be reconstructed after a bad experiment or lost local installer. It deliberately separates tasklog-proven foundations from reconstructed components and from items still awaiting device acceptance.

## 1. Accepted foundations that must not regress

- JamVM production fix L is DEVICE-PASS. Required SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`.
- GNU Classpath is immutable. Required admitted `glibj.zip` SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`. Do not patch `glibj.zip`.
- Accepted VC6 native core SHA256: `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`.
- Preserve Golden-style Java RGB565 asynchronous frame transport, native receiver thread, full-frame validation, double-buffer publication, and native Smart-Fit.
- Preserve Lazy Media Boot. Do not restore eager media warmup.
- Preserve source-level PNG iCCP compatibility; do not solve PNG by modifying GNU Classpath.
- Do not restore CV/CW boot-time resolution experiments.

## 2. Tasklog-proven logical LCD behavior restored in VC7R2

Historical device evidence established that game logical resolution and physical RG35XX output are separate. Representative proven mappings were:

| Game | Logical frame | Physical Smart-Fit result |
|---|---:|---:|
| Zombie | 240x320 | 360x480 |
| KDTT | 320x240 | 640x480 |
| Qix | 352x416 | 406x480, x=117 |
| Barman | 360x640 | 270x480, x=185 |

The historical CQ/CR path logged filename-derived logical sizes. VC7R2 reconstructs that behavior in `scripts/vc7r2_apply_proven_dynamic_view.py` without claiming binary identity to historical CQ runtime SHA `45853d13376fd17d176a8296c247adcf2e14065cd44f171b1aaacf2387ec14a8`.

VC7R2:

1. captures a valid `WxH` token from the loaded JAR filename;
2. applies it before load;
3. reasserts it after successful load;
4. reasserts it immediately before `runJar()`;
5. prevents later core settings updates from collapsing the established logical LCD back to stale 240x320;
6. leaves physical 640x480 fitting entirely to the accepted native Smart-Fit path.

Expected Java markers include `RG35XX-VC7R2-VIEW: filename logical size`, `after-load`, `before-run`, and `settings update keep runtime size`.

Important: game filenames used for this checkpoint must retain their `WxH` token, e.g. `... 320x240.jar`.

## 3. VC7R2 build identity

GitHub Actions workflow: `.github/workflows/verified-clean-vc7r2-proven-view-build.yml`.

Successful build run: `34454884856` at source commit `338f27bc843753c329e1525d582ab781e2e853e7`.

Artifact: `rg35xx-vc7r2-proven-view-runtime`, artifact id `10143065923`, artifact digest `sha256:8f149bfa90224b736f4b60d71c0019206ff264339b46fba33774136ef6fc4a6c`.

Runtime `freej2me-lr-vc7r2.jar` SHA256:

`8aca7ef0bb2909ca8e500d439359110b7d2199263c4fcef58814b22339aa4bbc`

The build gate verifies Java class major 50, PNG iCCP compatibility, bitmap text routing, absence of eager media warmup, absence of CV marker, and preservation of RGB565 frame request/encode path.

## 4. Font status — do not overclaim

VC7R2 currently carries the reconstructed Unicode resource SHA256:

`20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`

Size: 727008 bytes.

This is **RECONSTRUCTED-NOT-GOLDEN**. Exact Golden resource remains:

`7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`

Do not call the reconstructed resource Golden and do not change the Golden baseline status.

## 5. Installer/recovery contract

Installer source is archived under `scripts/installer/`.

The Windows installer must fail closed before runtime/config writes unless all of these pass:

- VC7R2 payload SHA;
- embedded reconstructed font size/SHA;
- JamVM L SHA;
- immutable GNU Classpath SHA;
- accepted native core SHA;
- all five expected runtime aliases exist.

Before modification it backs up all five runtime aliases and any discovered `retroarch-core-options.cfg` files under `RG35XX_VC7R2_Backup/<timestamp>`.

It replaces runtime JAR aliases only. It does not replace JamVM, GNU Classpath, or native core.

To remove a previously selected Green/etc display tint, the installer changes an **existing** `freej2me_backlightcolor` option to `Disabled`. It intentionally does not alter `freej2me_resolution`; RGB565 source/native transport is unchanged.

Rollback helper restores the newest VC7R2 backup. Evidence collector copies install result and known Java/core/early logs for analysis.

## 6. Device acceptance plan

Do not mark VC7R2 DEVICE-PASS until a real RG35XX run supplies evidence.

Test at least:

- KDTT filename containing `320x240`;
- Qix filename containing `352x416`;
- Barman filename containing `360x640`;
- Zombie filename containing `240x320`;
- a text-heavy/Vietnamese game for font visibility.

Acceptance checks:

- logical source dimensions match the filename/game rather than all becoming 240x320;
- native Smart-Fit produces correct aspect/centering on 640x480;
- no unwanted Green backlight tint;
- no `AbstractGraphics2D.renderScanline` NPE;
- no `Zone.combineWithSubGlyph` AIOOBE;
- PNG ICC v4 blocker remains absent;
- frame transport remains healthy;
- no media boot regression;
- Unicode text is visible and usable.

After testing, run the evidence collector and preserve `RG35XX-VC7R2-INSTALL-RESULT.txt`, `freej2me-java-error.log`, `freej2me-core.log`, and `freej2me-vc3-early.log` when present.

## 7. Status vocabulary

- JamVM L: DEVICE-PASS.
- B2 GNU Classpath: IMMUTABLE.
- VC6 native/video foundation: accepted/device-proven through first-frame and sustained presentation evidence.
- VC7R2 source/runtime: BUILD-PASS.
- VC7R2 dynamic-view implementation: reconstructed from tasklog-proven behavior; device acceptance pending.
- VC7R2 font: RECONSTRUCTED-NOT-GOLDEN.
- VC7R2 overall: DEVICE-TEST-PENDING.

Never label VC7R2 stable or DEVICE-PASS before the device acceptance above succeeds.
