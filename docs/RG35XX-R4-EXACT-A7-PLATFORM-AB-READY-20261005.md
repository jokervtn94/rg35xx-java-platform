# RG35XX R4 Exact A7 Platform / R4 Runtime A/B — Ready

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Purpose

Classify the remaining God of War audible-audio regression without changing production code.

The diagnostic holds the R4 candidate runtime constant and substitutes the exact device-accepted A7/A8 protected platform boundary recovered from historical CI.

## Golden source

```text
RUN_ID=36079435727
ARTIFACT_ID=10841810644
HEAD_SHA=5b7a8e88bd32a735a1342715e718eecf8cf10fad
```

Recovered and independently re-hashed bytes:

```text
freej2me-rg35xx.jar=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
librg35xx_input.so=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
librg35xx_video.so=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
libaudio.so=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
A1P5 prime=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

## Held constant

```text
R4 JamVM=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
R4 glibj=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
God of War=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
```

The existing R4 font resource/native font remain auxiliary dependencies and are not changed by this A/B.

## Safety / scope

- diagnostic only;
- no commercial game content bundled;
- no `/mnt/mmc/CFW/java` mutation;
- no production R4 file replacement;
- no runtime rebuild;
- no game-specific production patch;
- physical audible observation remains authoritative.

## Interpretation

If God of War audible gameplay returns, classify the failure into the post-A7 platform/input lineage currently carried by R4 and then perform owner-scoped differential narrowing.

If God of War remains silent after gameplay transition, the exact protected platform/input/video/audio/prime boundary is eliminated as the primary cause under the R4 candidate runtime. The remaining primary owner class becomes the R4 candidate runtime/process-environment boundary; no audio-code rewrite is justified.

## Status

```text
P6_PHYSICAL_ACCEPTANCE=PASS
P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY
PROTECTED_057_PLATFORM_AB=READY_NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
```
