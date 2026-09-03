# RGJ-RC1-011L — Classpath Font / Compiler Preflight

Status: STATIC-AUDIT-PASS

Completed:
- pinned official GNU Classpath 0.99 tarball identity in the audit (`f929297f8ae9b613a1a167e231566861893260651d913ad9b6c11933895fecc8`);
- added fail-closed Classpath/font source preflight;
- retained existing OpenTypeFontPeer/FontDelegate ownership;
- retained `RG35XXFontEngine` as superseded;
- required SHA-256 from the actual materialized DejaVuSans.ttf instead of inventing a digest;
- kept 0022 explicitly CONTRACT/UNAPPLIED until exact HeadlessToolkit reconciliation;
- kept ARMv5TE/uClibc and JamVM runtime tests outside static-pass claims.

Not claimed: BUILD-READY, BUILD-PASS, DEVICE-TEST-PASS.

Next whole stage: concrete HeadlessToolkit FontPeer implementation + reproducible Classpath overlay, followed by first real Java/native compile when all materialized inputs and toolchain are available.
