# RG35XX Clean Consolidated R2B Audio — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Source commit: `ef1bb0534c6d3090185ae49cb175155f5d2d98e2`

## Result

R2B native audio ownership reconstruction builds successfully on top of the R2A foundation.

Workflow:
- `RG35XX Clean Consolidated R2B Audio Ownership Build`
- run ID: `35687872223`
- job ID: `106618475998`
- conclusion: **SUCCESS**

Artifact:
- ID: `10676804838`
- name: `rg35xx-clean-consolidated-r2b-audio-build-only`
- artifact digest:
  `sha256:5e10f751bd87a4e57f49396d8aced162219eebc8fcf1a1dff8445dbbc7db55e4`

Built pair:
- runtime SHA256:
  `202714a2509b9c7e62accc925f24cea3d0d1b1d47d3699b015bf8605da3ae929`
- experimental native core SHA256:
  `54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51`

## Gates passed

- pinned Miyoo-compatible ARMv5TE/uClibc toolchain: PASS
- exact R2A foundation assembly: PASS
- pinned historical RG35XX media source materialization: PASS
- Java media facade route: PASS
- dedicated audio FD path: PASS
- worker-ring source gate: PASS
- Java class count: 1351
- Java major 50: PASS
- ARM ELF32 / EABI5 / soft-float: PASS
- Golden RGB565 video owner preserved: PASS
- R2A decoded-image normalization preserved: PASS
- async audio callback registration present: PASS
- ring=16384: PASS
- prime=3072: PASS
- worker chunk=1470: PASS
- fixed 735-frame `retro_run()` audio pump absent: PASS
- frame-coupled `AudioBatch(rg35xx_audio_run_buffer,...)` path absent: PASS

## Architecture interpretation

This matches the handheld architecture lesson taken from Miyoo:
- Java MMAPI remains facade;
- device playback is native;
- audio does not depend on desktop JavaSound on the RG35XX target path;
- audio progression is independent from render cadence.

It is still a reconstruction, not an exact Golden/CN binary.

Current TSF/mixer source remains:
- 44100 Hz stereo source reconstruction;
- not the recovered Golden 14700 Hz mono-x3 staging.

## Release policy

**DEVICE INSTALL BLOCKED.**

Do not install R2B yet.

The next real-device checkpoint remains R2A image normalization. R2B may only advance after:
1. R2A is installed from exact current R1;
2. black/missing image behavior is retested;
3. R2A evidence is collected;
4. no new hard reset/regression is observed.

Status:
- R2B BUILD-PASS=YES
- R2B DEVICE-PASS=NO
- STABLE=NO


---

## R2A real-device evidence justification — 2026-09-22

Evidence from the exact installed R2A runtime confirms the desktop JavaSound path is failing on target:

- `NoSuchMethodError: getSequencer`: 2 occurrences.
- `LineUnavailableException`: 2 occurrences.
- Real Football 2015 hits both Clip/LineUnavailable and getSequencer failure.
- Zombie Infection reaches `PlatformPlayer$midiPlayer.prefetch` then getSequencer failure.

This promotes the R2B native-audio architecture from historical-only rationale to a current-device-required subsystem change.

Before any R2B device installer is published, add fail-closed preconditions for:
- exact R2A base runtime;
- exact JamVM L and glibj;
- exact current protected B4 core as source/base identity;
- SoundFont path `BIOS\freej2me.sf2`;
- expected historical SoundFont SHA256 `c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854`.

R2B must remain a separate checkpoint from font and transparency testing.

Current status remains:
- BUILD-PASS=YES
- DEVICE-INSTALL=BLOCKED
- DEVICE-PASS=NO
- STABLE=NO
