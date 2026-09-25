# RG35XX Aweigit Port — Accepted Baseline Ledger

Lock date: 2026-09-25

## Reference baseline

```text
REFERENCE_BRANCH=rg35xx-aweigit-r1-stable
ACCEPTED_SOURCE_BRANCH=rg35xx-aweigit-r1-a7-audio-media
ACCEPTED_SOURCE_CHECKPOINT=5b7a8e88bd32a735a1342715e718eecf8cf10fad
CANONICAL_AWEIGIT_PIN=ca11dfe8ea1cc273d92460f9a83bbf192023fa63
A7_ACCEPTED_RUNTIME_BASE=YES
FULL_PLATFORM_STABLE=NO
```

The stable reference branch is a preservation point for the currently accepted RG35XX implementation. Feature work should branch from it rather than modifying it casually.

## Accepted identities recorded by device acceptance

```text
A6_PARENT_SEMANTIC_SHA256=53f229dbf14621a2a27a7249cb1355b1a2367bebc51a761959d3bd54985565d6
A7_PLATFORM_JAR_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
A7_PLATFORM_SEMANTIC_SHA256=7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

Raw JAR hashes may differ after reproducible rebuilds because ZIP/JAR timestamps can change. Semantic identity is therefore important when determining whether the Java platform behavior changed.

## Device-proven milestone chain

### Foundation

- Aweigit canonical implementation pinned rather than independently redesigning J2ME semantics.
- RG35XX-specific behavior isolated in adapter/package/launcher boundaries where possible.
- original RG35XX SDL1/fbcon display path retained.
- protected JamVM/glibj runtime retained.

### Core graphics and input

Accepted device path includes Canvas/GameCanvas, physical controller input, core 2D rendering, image transparency, Sprite/TiledLayer-related integration, raw primitives required by the selected corpus, and normal exit.

### A6 selected real-game corpus

`Vua-Cuop-Bien-240x320.jar`

```text
SHA256=220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578
RESULT=DEVICE-PASS
```

`God-of-War-Betrayal_J2ME_EN_v148.jar`

```text
SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
RESULT=DEVICE-PASS
```

The God of War regression isolated and accepted the `PlatformGraphics.translate()` clip correction. The resulting path displayed Kratos, monsters and background correctly while preserving input, gameplay, RMS where exercised and normal exit.

### A7 Audio/Media

The RG35XX adapter gained a native SDL1_mixer backend compatible with the device's ARMv5TE soft-float environment. Canonical media behavior was retained rather than replacing the MMAPI state machine with a separate RG35XX design.

A Java 6 compatibility boundary was required for the protected JamVM/glibj environment. Subsequent device evidence showed that Java/SDL media execution could reach the correct ALSA PCM device while remaining silent on a cold route.

A direct PCM A/B test and a cold Java-only test isolated the missing owner to device audio-route priming. The accepted launcher-boundary workaround is:

```text
PRE-JAVA
  aplay
  RW_INTERLEAVED
  hw:0,0
  S32_LE
  44100 Hz
  stereo
  ~350 ms zero PCM
  close
THEN
  accepted Java + SDL1_mixer runtime
```

No audible marker tone, GPIO mutation, `amixer` mutation or `alsactl restore` is part of the accepted solution.

A7 direct testing then passed audible WAV, WAV pause/resume, audible MIDI, MIDI END_OF_MEDIA, protected hashes and normal exit. The A7 candidate subsequently passed Vua Cướp Biển and God of War parent regression.

## Protected accepted owners

Do not modify these without new parent-level regression evidence pointing back to them:

```text
AWEIGIT_CANONICAL_PIN
JAMVM_GLIBJ
A6_GRAPHICS
A6_INPUT
PERF_A1
PNG_ALPHA_DRAWREGION
CLIPTRANSLATE
A7_JAVA6_MEDIA_COMPAT
A7_SDL1_MIXER_BACKEND
A1P5_AUDIO_ROUTE_PRIME
```

## What DEVICE-PASS means here

The designation applies only to the tested integration scope and selected game corpus. It does not prove universal J2ME compatibility.

Currently deferred or outside the accepted scope include:

```text
3D / M3G / Mascot
NETWORK
SMS
PAYMENT
untested MMAPI codecs/formats
all untested commercial games
```

## Rules for the next stage

1. Branch future development from `rg35xx-aweigit-r1-stable`.
2. Preserve the accepted baseline as a rollback/reference point.
3. Do not replay DP-R1..DP-R11, VC or Golden patch chains.
4. Prefer one evidence-rich integration package over repeated micro-tests.
5. BUILD-PASS is never DEVICE-PASS.
6. A hang or hard reset is FAIL.
7. When a new regression appears, identify canonical behavior, RG35XX contract and failure owner before editing code.
8. Apply the smallest adapter delta and rerun the parent integration/regression test.
9. Commercial game JARs remain external test inputs and must never be bundled.
10. Do not declare the whole platform STABLE until broader repeated real-device regression justifies that status.

## Next planned stage

```text
A8 = PACKAGE / LAUNCHER CONSOLIDATION + GENERAL REAL-GAME SANITY
```

A8 should consolidate the accepted A1P5 audio prime into the production launcher, correct diagnostic/logging order where needed, preserve accepted runtime identities and use a consolidated original-RG35XX integration test before expanding the game corpus.
