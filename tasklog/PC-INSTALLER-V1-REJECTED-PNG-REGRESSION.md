# PC Stable Clean Installer v1 — REJECTED

Date: 2026-09-08
Status: REJECTED / DO-NOT-USE-AS-STABLE

## Affected package

`RG35XX_Stable_Clean_PC_Installer_v1.zip`

Payload identity used by that package:

- JamVM L Production: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- M1 FreeJ2ME core: `f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`
- M1 runtime JAR: `cae779a1ac2dfd7cd65e8893b30fee8196c1c6107f693c335701fe34fea4d322`

## Device failure evidence

After installing the combined package, KDTT presents only a solid green framebuffer and does not reach normal text/game presentation.

Java log proves the game thread aborts while decoding a PNG ICC profile:

`java.lang.IllegalArgumentException: Wrong major version number:4`

Call path:

`PNGICCProfile -> ICC_Profile.getInstance -> ImageIO.read -> PlatformImage -> Image.createImage -> game thread`

The failure reproduced in two launches with different game-class call sites, so it is a runtime image-decoding compatibility regression, not a single corrupt text glyph or a JamVM CHECKCAST recurrence.

## Classification

- JamVM L: KEEP. Its direct-interpreter ALOAD_0/GETFIELD correctness fix remains independently device-proven.
- M1 core/runtime pair: REJECT for stable distribution until PNG compatibility is restored and device-tested.
- Font/audio M1 changes: do not promote together with a compatibility-regressed runtime.

## Recovery policy

The v1 installer created a per-device backup before overwriting payload files under:

`RG35XX_Java_Backup/YYYYMMDD-HHMMSS/`

Recovery must restore the pre-M1 FreeJ2ME core/runtime from that device backup, then install the separately validated JamVM L Production binary.

Do not silently rebuild or guess the former core/runtime. Export and hash the actual pre-M1 backup first so it can become an immutable portable baseline.

## Stable promotion gate

A replacement PC installer may be called STABLE only after real RG35XX evidence confirms:

1. KDTT PNG assets decode and UI/text appears.
2. KDTT passes the former JamVM crash point.
3. video/Smart-Fit remain correct.
4. MIDI/PCM audio remains usable.
5. no new Java exception or native crash occurs during representative play.

Until those gates pass, use RECOVERY / CANDIDATE labels rather than STABLE.
