# RG35XX Exact Golden P0 Provenance

**Status:** `REFERENCE_ONLY / NO_RUNTIME_CHANGE / P0_EXACT_GOLDEN_RECOVERED`

## Authority

The accepted baseline ledger records the device-accepted A7 runtime identities that A8 production consolidation is required to preserve:

```text
A7_ACCEPTED_SOURCE_CHECKPOINT=5b7a8e88bd32a735a1342715e718eecf8cf10fad
A7_PLATFORM_JAR_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
A7_PLATFORM_SEMANTIC_SHA256=7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
A1P5_PRIME_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

## Recovered historical artifact

GitHub Actions workflow run:

```text
RUN_ID=36079435727
WORKFLOW=A7 RG35XX Audio Media SDL1 A1P1
HEAD_SHA=5b7a8e88bd32a735a1342715e718eecf8cf10fad
ARTIFACT_ID=10841810644
ARTIFACT_NAME=RG35XX-AWEIGIT-R1-A7-AUDIO-SDL1-A1P1-5b7a8e88bd32a735a1342715e718eecf8cf10fad
ARTIFACT_ARCHIVE_DIGEST_SHA256=2292df4c140d4f8a7479fbdc432bef194bdd9b83057ab1e6fb3f38df4c516c6f
```

Direct hashing of the recovered artifact contents gives:

```text
freej2me-rg35xx.jar  057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
librg35xx_input.so   69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
librg35xx_video.so   c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
libaudio.so          4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
```

This is the exact byte identity recorded by device acceptance. It replaces the previous incorrect practice of using a raw-JAR-different, semantic-equivalent A8 rebuild as if it were the exact Golden artifact.

## A8 production relationship

The locked A8 launcher hash-gates the exact identities above and adds only the accepted A1P5 pre-Java route prime:

```text
aplay -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100 <zero PCM>
```

The protected prime is exactly 123480 zero bytes and hashes to:

```text
8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

A8 launcher expected platform hash is the exact device-accepted `057567...`, not a rebuilt-equivalent raw JAR hash.

## P0 lock

```text
P0_EXACT_GOLDEN_RECOVERED=YES
EXACT_GOLDEN_SOURCE=HISTORICAL_DEVICE_ACCEPTED_A7_ARTIFACT
SEMANTIC_EQUIVALENT_REBUILD_AS_GOLDEN=FORBIDDEN
RUNTIME_CHANGE=NO
NEW_DEVICE_PASS_INFERRED=NO
```

This reference must be used for rollback, byte identity, A/B controls, and parent comparison. Future P1 platform-completion candidates may be reconstructed semantically for CI, but must never overwrite or relabel a raw-hash-different rebuild as the exact physical Golden artifact.
