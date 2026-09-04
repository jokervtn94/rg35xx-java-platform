# RGJ-RC1-011N — Font Runtime Deployment Boundary

- Action: MODIFY / AUDIT
- Status: STATIC-AUDIT-PASS
- Files:
  - `runtime/classpath/apply_rg35xx_font_overlay.sh`
  - `scripts/rc1_runtime_build_overlay.sh`
  - `docs/RC1-FONT-RUNTIME-DEPLOYMENT-AUDIT.md`

## Finding

The first 011M realization wrote the disposable Classpath assembly path into `fonts.properties`. Because GNU Classpath `OpenTypeFontPeer` resolves the mapping as a runtime filesystem path, this could compile successfully but fail on the RG35XX device.

## Correction

- Require explicit absolute `RG35XX_FONT_RUNTIME_PATH`.
- Never infer or hard-code a target-device path.
- Stage the verified DejaVu Sans payload separately for packaging.
- Write only the target runtime path into `fonts.properties`.
- Emit `rg35xx_runtime_files.list` with staged source, target path and actual SHA-256.
- Reject any disposable assembly path leaked into `fonts.properties`.
- Synchronize the shared logical-font peer cache to avoid concurrent HashMap mutation during peer creation.

## Gate

STATIC-AUDIT-PASS for path ownership/deployment contract only.

No BUILD-READY, BUILD-PASS or DEVICE-TEST-PASS claim. GNU Classpath/JamVM compilation, glyph smoke probes, actual deployment path availability and ARMv5TE/uClibc native compile/link remain required.