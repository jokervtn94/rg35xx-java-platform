# R2C-AUDIO-R1-AB — Integrate R2B Audio onto R2C-FONT Baseline

Date: 2026-09-22
Baseline: exact R2C-FONT runtime
Primary variable: AUDIO_OWNERSHIP_ONLY
Status: SOURCE-PENDING / BUILD-PENDING / DEVICE-TEST-PENDING / STABLE=NO

## Required preflight

CURRENT_SYMPTOM:
- R2B real-device test has audible audio and zero `NoSuchMethodError: getSequencer` / `LineUnavailableException`.
- Game freeze remains.
- White/opaque background defect remains.

HISTORY_FOUND:
- R2C-FONT device evidence removed the previous GNU Classpath text crash families:
  - `Zone.combineWithSubGlyph` -> zero
  - `AbstractGraphics2D.renderScanline` text failures -> zero
- R2B-AUDIO device evidence removed the desktop JavaSound failure boundary and produced audible audio.
- R2B on R2A re-exposed the known R2A font `renderScanline` failures, as expected from one-variable testing.

PREVIOUS_FIX:
- Font: R2C direct metric bitmap Unicode raster.
- Audio: R2B dedicated inherited media FD + native worker/ring + async libretro audio callback.

PREVIOUS_EVIDENCE_LEVEL:
- R2C font crash removal: DEVICE-EVIDENCE.
- R2B audio route/audibility: DEVICE-EVIDENCE.
- Neither subsystem is DEVICE-PASS or STABLE.

REGRESSION_RISK:
- Reintroducing desktop JavaSound on RG35XX.
- Reintroducing fixed 735-frame `retro_run()` audio ownership.
- Reintroducing GNU AWT/OpenType normal text raster.
- Accidentally changing transparency/video/Canvas in the same checkpoint.

MINIMAL_PROPOSED_CHANGE:
- Reproduce the exact R2C font source/resource contract on the R2A source foundation.
- Add only the already BUILD-PASS R2B audio ownership implementation.
- Preserve R2A image normalization, current transparency behavior, Golden RGB565 video owner, JamVM L and glibj.

EXPECTED_DEVICE_TEST:
- R2C font marker present and old text crash families remain zero.
- Audible audio.
- `getSequencer` and Clip errors remain zero.
- No hard reset.
- NinjaSchool2/KDTT/Real Football can progress farther than their previously isolated font/audio failure boundaries.
- Background transparency is expected to remain unchanged; this checkpoint does not include R2D.

## Baseline identities

R2C-FONT runtime:
`0f38d6181201b3c5128b421e8d0ee747b69911c928a728fd9b3207e39e067e34`

R2A source foundation runtime:
`5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`

R2C reconstructed font resource:
`20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9`
Status: RECONSTRUCTED-NOT-GOLDEN.

R2B build source:
`ef1bb0534c6d3090185ae49cb175155f5d2d98e2`

R2B reconstructed core:
`54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51`

SoundFont:
`c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854`

## Scope lock

Allowed:
- R2C font owner reproduced unchanged.
- R2B audio owner added.

Forbidden:
- R2D transparency patch.
- screenshot fix.
- Canvas/serviceRepaints semantic change.
- RMS redesign.
- video geometry/Smart-Fit changes.
- JamVM/glibj replacement.
- new audio DSP/prime tuning.

## Device install policy

The device installer MUST require:
- exact R2C-FONT on all five runtime aliases;
- exact B4 protected core;
- exact JamVM L;
- exact glibj;
- exact SoundFont.

It must backup all runtime aliases and core before write and support rollback.

## Result policy

This checkpoint may become DEVICE-EVIDENCE or DEVICE-PASS only after real RG35XX testing.
CI/build alone is BUILD-PASS only.
Hard reset = FAIL.
Full platform remains STABLE=NO.
