# RC1 Font Runtime Deployment Audit — RGJ-RC1-011N

Status: **STATIC-AUDIT-PASS** for runtime-path ownership and packaging contract. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Problem found after 011M

The initial concrete GNU Classpath overlay copied `DejaVuSans.ttf` into the disposable Classpath assembly tree and wrote that assembly path directly into `gnu/java/awt/font/fonts.properties`.

That is structurally valid for a host-side source tree but wrong as a target runtime contract: GNU Classpath `OpenTypeFontPeer` resolves the mapped value as a filesystem path at runtime. A disposable build-host path can therefore compile successfully and still fail later on RG35XX.

011N separates **build staging** from **target runtime destination**.

## Authoritative ownership

- `RG35XX_FONT_FILE` is the verified build input containing the materialized DejaVu Sans binary.
- `RG35XX_FONT_RUNTIME_PATH` is an explicit absolute filesystem path on the final target runtime.
- `runtime/classpath/apply_rg35xx_font_overlay.sh` stages the font in the disposable runtime assembly for packaging, but writes only `RG35XX_FONT_RUNTIME_PATH` into `fonts.properties`.
- `scripts/rc1_runtime_build_overlay.sh` emits `rg35xx_runtime_files.list` describing the exact source payload, target path and SHA-256 to be used by the later package/deploy stage.

No target path is guessed by the project. The deployment environment must provide it explicitly.

## FontPeer concurrency correction

The 011M logical-family/attribute peer cache is now accessed through a synchronized helper. This avoids concurrent unsynchronized mutation of the shared `HashMap` if AWT/font creation occurs from more than one Java thread.

This does not add a rendering lock to every glyph operation; synchronization is limited to peer lookup/creation.

## Fail-closed gates

Assembly now fails if:

- the target font path is not absolute;
- the target path refers to the disposable Classpath assembly tree;
- the pinned Classpath source shape is not recognized;
- the OpenType constructor path cannot be converted to fail-closed behavior;
- the staged font payload is absent;
- `fonts.properties` contains the disposable runtime assembly path;
- the deployment manifest does not contain the declared target path.

## Runtime manifest

Generated file: `RG35XX_ASSEMBLY_ROOT/rg35xx_runtime_files.list`.

Current record fields:

- `TYPE=font`
- `SOURCE=<staged DejaVuSans.ttf>`
- `TARGET=<RG35XX_FONT_RUNTIME_PATH>`
- `SHA256=<actual staged font SHA-256>`

The later packaging step must copy SOURCE to TARGET without changing bytes and should re-check SHA-256 after deployment.

## Evidence boundary

This closes the static path-leak/deployment ownership defect. It does **not** prove:

- GNU Classpath compilation;
- JamVM construction of `OpenTypeFontPeer`;
- `Font.hashCode`, glyph-vector or metrics behavior;
- Vietnamese glyph rendering on the target;
- filesystem availability of the chosen target path on a real RG35XX.

Those remain compiler/device gates.

## Result

011N: **STATIC-AUDIT-PASS**.

Next stage should create the first compiler execution driver and run it only when the external inputs/toolchain are physically available. BUILD-PASS remains forbidden until real Java/ClassPath/native compilation succeeds.