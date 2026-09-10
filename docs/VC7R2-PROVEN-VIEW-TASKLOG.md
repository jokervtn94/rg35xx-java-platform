# VC7R2 Proven View — recovery/tasklog checkpoint

Date: 2026-09-10
Branch: `verified-clean-platform-v1`
Status: **BUILD-PASS / PARTIAL DEVICE EVIDENCE / NOT DEVICE-PASS**

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

## 6. First real-device evidence — 2026-09-10

Installer result from the user's RG35XX SD:

- `RESULT=PASS`.
- Installed runtime SHA matched `8aca7ef0bb2909ca8e500d439359110b7d2199263c4fcef58814b22339aa4bbc`.
- Accepted native core SHA remained `fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062`.
- JamVM L and immutable GNU Classpath were preserved.
- `BACKLIGHT_OPTION_FILES_UPDATED=0`; therefore the installer did not find an existing `freej2me_backlightcolor` line to change. Do not claim the previous green tint was fixed by this installer setting rewrite.
- Backup created at `g:\RG35XX_VC7R2_Backup\20260910-182901`.

### Dynamic logical LCD evidence

The new VC7R2 Java log explicitly shows for `KDTT-Tam_Quoc_Chi_320x240_vh_by_zeplaovn.jar`:

- `RG35XX-VC7R2-VIEW: filename logical size 320x240`;
- `filename resize 240x320 -> 320x240`;
- `after-load keep 320x240`;
- `settings update keep runtime size 320x240`;
- `before-run keep 320x240`;
- frame requests and FrameWorker wake at `320x240`;
- RGB565 payload remains `153600` bytes, which is exactly `320*240*2`.

The corresponding native early log confirms:

- `FIRST_FRAME_HEADER src=320x240 rot=0 payload=153600`;
- `FIRST_PRESENT ... src=320x240 dst=640x480 x=0 y=0 output=640x480`.

This is a **real-device confirmation that the VC7R2 filename-token logical-size restoration works for the 320x240 KDTT case** and that native Smart-Fit handles that logical frame correctly.

Other observed current-session behavior:

- `NinjaSchool1.jar` has no filename `WxH` token, so VC7R2 logs `no filename size; keep runtime size 240x320` and remains 240x320.
- `Asphalt_4_-_Elite_Racing_240x320...jar` is correctly recognized as 240x320.
- `240x320-zombie_infection-s60.jar` remains 240x320 as expected.
- Qix 352x416 and Barman 360x640 were not present in this evidence set, so those VC7R2 paths remain device-pending.

### RGB565 / frame transport evidence

Java repeatedly records snapshot copy, `RGB565 ENCODED bytes=153600`, IPC header/payload writes and `IPC FLUSH PASS error=false`. Native receives/publishes/presents sustained frames, including hundreds of generations per game. Therefore the asynchronous frame transport remains alive after VC7R2 logical-size restoration.

This proves transport liveness and correct payload sizing, but by itself does **not** prove visual color correctness. Color/tint still requires screenshots or explicit device observation.

### PNG compatibility evidence

`RG35XX-PNG-ICCP: stripped ancillary iCCP chunk` appears in the current Java log. The old `Wrong major version number:4` failure was not observed in this evidence set. Keep status conservative: compatibility path exercised successfully in this run.

### Font path evidence

`RG35XX-VC7-FONT: ready bytes=727008` appears, proving the reconstructed bitmap resource is loaded. This does not promote the font to Golden or prove acceptable visual glyph quality.

### New separate media compatibility failure

The current Java log contains:

`java.lang.NoSuchMethodError: getSequencer`

from `org.recompile.mobile.PlatformPlayer$midiPlayer.prefetch(...)`, reached from a game event thread. This is a **separate MIDI/media compatibility blocker**, not evidence that Lazy Media Boot regressed. Lazy boot still logs `eager prepare SKIPPED; lazy media enabled` and frame transport continues. Do not reintroduce eager media warmup. Investigate the runtime/JamVM GNU Classpath MIDI API compatibility separately after display/font acceptance, unless the failing game requires it for basic execution.

### Old AWT/OpenType font crash status

No new `AbstractGraphics2D.renderScanline` NPE or `Zone.combineWithSubGlyph` AIOOBE was identified in the current VC7R2 evidence. Keep this as **not observed in this test**, not a global proof until broader game coverage.

## 7. Remaining device acceptance plan

VC7R2 is not DEVICE-PASS yet. Remaining evidence required:

- Qix filename containing `352x416` -> expect source 352x416 and Smart-Fit 406x480, x=117;
- Barman filename containing `360x640` -> expect source 360x640 and Smart-Fit 270x480, x=185;
- screenshots/visual confirmation that the previous green tint is gone or still present;
- text-heavy/Vietnamese screenshots to judge reconstructed font quality;
- verify no old AWT/OpenType crash across representative text-heavy games;
- isolate the `getSequencer` MIDI compatibility error from display/font work.

After testing, preserve `RG35XX-VC7R2-INSTALL-RESULT.txt`, `freej2me-java-error.log`, `freej2me-core.log`, and `freej2me-vc3-early.log` when present.

## 8. Status vocabulary

- JamVM L: DEVICE-PASS.
- B2 GNU Classpath: IMMUTABLE.
- VC6 native/video foundation: accepted/device-proven through first-frame and sustained presentation evidence.
- VC7R2 source/runtime: BUILD-PASS.
- VC7R2 logical-size restoration, KDTT 320x240 case: **DEVICE-PROVEN**.
- VC7R2 Qix/Barman non-240x320 coverage: DEVICE-PENDING.
- RGB565 transport liveness/payload sizing after VC7R2: DEVICE-PROVEN; visual color correctness still pending.
- PNG iCCP source compatibility path: exercised on device; old ICC v4 blocker not observed in this run.
- VC7R2 reconstructed font resource load: DEVICE-PROVEN; visual font quality pending; still RECONSTRUCTED-NOT-GOLDEN.
- MIDI `getSequencer` compatibility: DEVICE-FAIL for at least one tested game path; separate from Lazy Media Boot.
- VC7R2 overall: **PARTIAL DEVICE EVIDENCE / NOT DEVICE-PASS**.

Never label VC7R2 stable or DEVICE-PASS before the remaining device acceptance above succeeds.
