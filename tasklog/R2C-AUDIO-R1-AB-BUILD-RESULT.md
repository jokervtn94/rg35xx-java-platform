# R2C-AUDIO-R1-AB — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Source commit: `d18180dafb2f648c52fab7f29083024745a6c9f9`

## CI

Workflow: `R2C Audio R1 AB`
Run ID: `35704069363`
Job ID: `106668657574`
Conclusion: **SUCCESS**

Artifact:
- ID: `10683647968`
- name: `r2c-audio-r1-ab`
- artifact digest / downloaded ZIP SHA256:
  `a726d22df250dfdaa4ac9cabd27092a5b7221d33e0498eda0bf2868e4c1a3055`

Payload:
- runtime SHA256:
  `7a48de2aa229f9039f87dd1e85dce27bdc10aa14d891805ac5e99e89507a00b1`
- native core SHA256:
  `54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51`
- font resource SHA256:
  `20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`

## Important A/B identity result

The newly built native core SHA256 is exactly identical to the prior R2B audio core:

`54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51`

Therefore the native audio implementation itself is unchanged relative to the R2B device-evidence checkpoint.

The Java runtime differs because it intentionally contains both:
1. the already device-evidenced R2C direct metric bitmap font baseline; and
2. the R2B Java MMAPI/native routing needed by that exact native audio core.

## Gates passed

- fresh pinned FreeJ2ME source: PASS
- exact R2A source foundation assembly: PASS
- exact R2C font patch contract: PASS
- deterministic reconstructed font resource SHA: PASS
- font resource size 727008: PASS
- R2B historical media source pin: PASS
- Java native media facade route: PASS
- worker ring=16384: PASS
- prime=3072: PASS
- worker chunk=1470: PASS
- async libretro audio callback: PASS
- fixed 735-frame `retro_run()` pump absent: PASS
- R2C font bytecode marker: PASS
- normal GNU `gc.drawString` path bypass remains active: PASS
- Java class major 50: PASS
- R2A image normalization preserved: PASS
- Golden RGB565 video owner preserved: PASS
- ARM ELF32 / EABI5 / soft-float: PASS
- Windows installer/precheck/restore/collector parse: PASS
- collector self-test: PASS
- internal SHA256SUMS verification: PASS

## Scope

Primary variable relative to exact R2C-FONT baseline:
`AUDIO_OWNERSHIP_ONLY`

Preserved:
- R2C font owner and reconstructed font resource;
- R2A image normalization;
- current transparency behavior;
- Golden RGB565 video owner;
- dynamic logical view / Smart-Fit;
- JamVM L;
- glibj.

Not included:
- R2D transparency;
- screenshot fix;
- Canvas/serviceRepaints changes;
- RMS redesign;
- audio DSP/prime tuning.

## Device prerequisite

Install only on exact R2C-FONT:
`0f38d6181201b3c5128b421e8d0ee747b69911c928a728fd9b3207e39e067e34`

with:
- B4 core `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`
- JamVM L `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- SoundFont `c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854`

## Device acceptance

Test:
1. NinjaSchool2
2. KDTT
3. Real Football 2015

Required:
- text remains readable;
- `Zone.combineWithSubGlyph=0`;
- `AbstractGraphics2D.renderScanline=0`;
- audible audio;
- `NoSuchMethodError: getSequencer=0`;
- `LineUnavailableException=0`;
- no hard reset;
- record exact freeze point if a game still stalls.

White/opaque backgrounds are expected to remain unchanged because transparency is intentionally outside this checkpoint.

## Status

- BUILD-PASS=YES
- DEVICE-TEST-PENDING=YES
- DEVICE-PASS=NO
- STABLE=NO
