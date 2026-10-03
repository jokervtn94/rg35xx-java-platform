# RG35XX-AWEIGIT-R1 — A4 DEVICE-PASS

Date: 2026-09-23
Stage: A4 Level-1 SMOKE
Device: original RG35XX real-device run
Adapter commit tested: `d4fa63aaa0d063c700761bb5d43ae00fd00c8005`
Canonical Aweigit commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

## Evidence bundle

Uploaded evidence archive:

`RG35XX-AWEIGIT-R1-A4-EVIDENCE-20260923-150353.zip`

SHA256:

`c4fcf00acf1add328e0d17f8b289a696160cadb75daadcd23913a53ce416a6d0`

Primary smoke result SHA256:

`669ad49b15d85ca664843dc57e21ded26f81523a0a543493aa83d7f57a0e3657`

Evidence inventory SHA256:

`39cd09679aa18630cc8a075150134bac6659ade6ea03feb3322daf8571d2861c`

## Device acceptance markers

The real-device smoke result records all A4 acceptance markers as PASS:

- `A4_PAYLOAD_HASHES=PASS`
- `RG35XX_A4_RAW2D=ENABLED`
- `RG35XX_A3_SDL_DRIVER=fbcon`
- `RG35XX_A3_SURFACE=640x480 PITCH=2560`
- `A4_SMOKE_BOOT=PASS`
- `A4_INPUT_TRACE=ENABLED`
- `A4_CANVAS_MONITOR=NONBLOCKING`
- `A4_CANVAS_INPUT=PASS`
- `A4_CANVAS_EXECUTION=PASS`
- `A4_GAMECANVAS_KEYSTATES=PASS`
- `A4_GAMECANVAS_EXECUTION=PASS`
- `A4_SMOKE_DEVICE_ACCEPTANCE_MARKER=PASS`
- `A4_NORMAL_EXIT=PASS`
- `JAMVM_EXIT_CODE=0`
- `A4_PROTECTED_HASHES=PASS`
- `A4_SMOKE_PROGRAMMATIC_RESULT=PASS`

## Canvas evidence

Canvas phase reached balanced physical input and rendered successfully:

- paint count: `39`
- tracked press count: `2`
- tracked release count: `2`
- D-pad direction observed
- FIRE/A observed
- phase transitioned normally into GameCanvas

## GameCanvas evidence

GameCanvas phase executed on the same real-device run:

- sample count: `16`
- flush count: `16`
- `getKeyStates()` observed FIRE press and release
- D-pad movement state observed
- `flushGraphics()` completed repeatedly
- phase completed normally

## Protected runtime integrity

JamVM SHA256 before and after:

`eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

Protected `glibj.zip` SHA256 before and after:

`d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

Both remained unchanged through install and device execution.

## Package identity

- platform JAR SHA256: `ebd6bf93e043fd3ea5b3c6eb1ab0362cd633bfa4d27b529eb1bd013700438abe`
- input native SHA256: `69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d`
- video native SHA256: `9094819d7c81576b63bd0cde9531404a3fb82b8d5b845dbae152152f2e1a2a7a`
- smoke JAR SHA256: `c81a6731c4bbdfd3bc48c71a758941cfd9fef45e8d98cd28386e51e60d2b9d4f`

## Status

`A4_SMOKE_DEVICE_PASS=YES`

`BUILD-PASS=YES`

`DEVICE-PASS=YES` for the A4 Level-1 smoke scope only.

`STABLE=NO`

`FULL_PLATFORM_STABLE=NO`

Audio and media remain HOLD. Image decoding, text rendering, RMS, Sprite, TiledLayer and deferred 3D/M3G/Mascot/LWJGL are not promoted by this result.

This evidence promotes only the A4 Level-1 smoke parent test. The next phase must continue with core integration/regression rather than introducing a new micro-fix chain.