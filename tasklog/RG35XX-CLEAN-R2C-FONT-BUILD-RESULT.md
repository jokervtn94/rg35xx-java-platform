# RG35XX Clean R2C Font — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Source commit: `ccd21053d9fcb14ef194859b2a11e008c4c08d1c`

## CI

Workflow: `RG35XX Clean R2C Font`
Run ID: `35689608909`
Job ID: `106623585033`
Result: **SUCCESS**

Gates:
- exact R2A source foundation: PASS
- font-only source scope: PASS
- deterministic reconstructed Unicode resource: PASS
- resource SHA gate: PASS
- Java class major 50: PASS
- compiled direct-font method bytecode: PASS
- runtime font-ready marker bytecode: PASS
- Windows installer/restore/collector parse: PASS
- collector StrictMode self-test: PASS
- package manifest: PASS

Artifact:
- ID: `10678482005`
- name: `rg35xx-clean-r2c-font`
- artifact/download ZIP SHA256:
  `c8506a15d8991f863e16530b952431ad2c2d85416f25585d3078bbb3db403e24`

Payload runtime SHA256:
`0f38d6181201b3c5128b421e8d0ee747b69911c928a728fd9b3207e39e067e34`

Required exact installed base:
`R2A = 5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`

Font resource:
- SHA256:
  `20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`
- bytes: 727008
- records: 22719
- fallback records: 57
- status: `RECONSTRUCTED-NOT-GOLDEN`
- exact Golden SHA is not claimed.

## Independent post-download verification

- GitHub artifact digest equals downloaded ZIP SHA: PASS
- all internal `SHA256SUMS.txt` entries: PASS
- payload hash exact: PASS
- unresolved installer placeholders: zero

## Scope

Primary variable:
- font/text raster only

R2C-FONT removes the final normal `gc.drawString(...)` path from PlatformGraphics and rasterizes Unicode bitmap glyphs directly to `canvasData` using active MIDP/DoJa metrics.

Unchanged:
- R2A image normalization
- R2A transparency behavior
- audio
- Canvas/serviceRepaints
- native core/video
- JamVM/glibj

## Device acceptance

Priority games:
1. Tan Tay Du Ky 3
2. NinjaSchool2
3. KDTT Tam Quoc Chi

Expected:
- `RG35XX-R2D-FONT: ready bytes=727008`
- `Zone.combineWithSubGlyph` -> zero
- `AbstractGraphics2D.renderScanline` text failure -> zero
- game thread no longer terminates during text raster
- text remains usable/aligned in real gameplay
- no hard reset

## Status

- BUILD-PASS=YES
- DEVICE-PASS=PENDING
- STABLE=NO
