# A1P5 Device-Pass Evidence

Preserved from the original RG35XX A7 parent-regression A1P5 package supplied after device acceptance.

## Runtime identity

```text
A7_ADAPTER_COMMIT=5b7a8e88bd32a735a1342715e718eecf8cf10fad
A7_PLATFORM_SEMANTIC_SHA256=7cd3a4a29d4238e0d2464a213db48ba555bdf3c590aa77fe60c68b480bdc4adf
PLATFORM_JAR_SHA256=057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
INPUT_NATIVE_SHA256=69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
PRIME_PCM_SHA256=8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e
```

## Accepted production-boundary delta

```text
A1P5_RUNTIME_BINARY_DELTA=NONE_EXACT_A1P1_A1P5
A1P5_ONLY_PRODUCTION_BOUNDARY_DELTA=PREJAVA_APLAY_RW_INTERLEAVED_ZERO_PCM_350MS
PRIME_DEVICE=hw:0,0
PRIME_FORMAT=S32_LE_STEREO_44100
PRIME_CONTENT=ALL_ZERO_PCM
PRIME_DURATION_MS=350
GPIO_MUTATION=NO
MIXER_MUTATION=NO
SDL_AUDIODRIVER=alsa
```

The launcher invokes `aplay -q -D hw:0,0 -t raw -f S32_LE -c 2 -r 44100` on the all-zero prime file before starting JamVM.

## Protected runtime

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

## Parent corpus acceptance

The supplied A1P5 package was the exact package used for the accepted Vua Cướp Biển and God of War parent regression described in the project tasklog. Commercial JARs remain external test inputs and must not be committed or distributed by this repository.

## Important A8 finding

The preserved A1P5 regression launchers truncate the result file with `: >"$OUT"` after the audio prime. Therefore the prime BEGIN/PASS markers written immediately before that point are erased from the final result log. This is a logging-order defect only; it does not invalidate the already observed device behavior. A8 may correct the logging order while preserving the exact prime command and runtime identities.

## Supplied artifact hashes

```text
A1P5_PACKAGE_ZIP_SHA256=62a837d2ea7bb2e4fcc2484990ea004d8f50f036ce1e870f7f4f122f63a92f3c
GOW_A1P5_LAUNCHER_SHA256=5c91d26e93c792b8ed3d363cc202f4a282e2f521d39c320362398c0f37dc691b
VUA_A1P5_LAUNCHER_SHA256=6cbb6dcf208b24785eeab5ac10d3ff5f5c01929b62e73813555020e1505a0c8c
```
