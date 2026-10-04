# P3 — Runtime service module audit

**Date:** 2026-10-04  
**Status:** `AUDIT_PASS / PACKAGE_BUILT / DEVICE_TEST=PASS / AUDIO_HEARD_ON_DEVICE`
**Predecessor:** P2C input/frontend physical acceptance  
**Canonical:** `aweigit/freej2me-miyoomini@ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

## Purpose

P2C is physically accepted on the original RG35XX. P3 now audits the remaining
runtime-service boundary as one platform module. The audit does not redesign
FreeJ2ME and does not change the accepted input, video, JamVM or glibj owners.

The Miyoo/Aweigit implementation remains the semantic base. FreeJ2ME source is
used to explain the intended service behavior; RG35XX code is allowed only at
the Java-6, filesystem, native-audio and launcher boundaries that the measured
device contract requires.

## Locked module scope

| Service area | Canonical owner | RG35XX boundary to audit | Current status |
|---|---|---|---|
| Lifecycle / normal return | `MobilePlatform`, `MIDletLoader`, MIDlet lifecycle | Java-6 loader staging, launcher shutdown and normal return | `UNVERIFIED_MODULE` |
| RMS / filesystem | `RecordStore`, `AndroidRecordStoreManager`, `FileSystemFileConnection` | RMS root/path and Java-6 source compatibility | `UNVERIFIED_MODULE` |
| Media / audio | `PlatformPlayer`, `SdlMixerManager` | Java-6 media cache path, SDL1 mixer bridge and audio loader | `UNVERIFIED_MODULE` |
| Runtime compatibility | canonical staged Java classes | Java 6 classfile and forbidden JDK API audit | `UNVERIFIED_MODULE` |

Historical A5 RMS and A7 audio evidence is retained, but it is not silently
converted into a new P3 module DEVICE-PASS. A physical module package must
exercise all declared P3 rows and must report normal return and protected hashes.

## Audit gates

The new `scripts/audit-p3-runtime-services.py` gate is read-only. It requires:

1. the canonical submodule to be present;
2. its `HEAD` to equal the locked Aweigit commit;
3. the lifecycle, RMS/filesystem and media source owners to exist;
4. canonical contract anchors to be present;
5. Java-6 risk locations to be enumerated without applying a rewrite.

The gate emits `P3_RUNTIME_SERVICE_AUDIT=PASS` only for this source audit. It
also emits `P3_RUNTIME_SERVICE_DEVICE_TEST=NOT_TESTED` until an original-RG35XX
module run is reviewed.

The source gate passed in GitHub Actions Run #2. The complete P3 exerciser and
physical package passed in Run #3 without rebuilding the P2C parent chain:

```text
P3_WORKFLOW_RUN=37206803198
P3_COMMIT=ee2f73e739fbed303d91741c512b5b1a66b3e72c
P3_ARTIFACT=RG35XX-P3-RUNTIME-SERVICE-EXERCISER-ee2f73e739fbed303d91741c512b5b1a66b3e72c
P3_ARTIFACT_SHA256=2d8329978c3b6a9aeebb88a6e04f30d549ff77f4888497915ed48b5cc94f189a
P3_PACKAGE_BUILD=PASS
P3_RUNTIME_SOURCE=CANDIDATE_PROBE
P3_RUNTIME_DEVICE_ROOT=/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
P3_RUNTIME_JAMVM_SHA256=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
P3_RUNTIME_GLIBJ_SHA256=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
P3_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
```

## Latest original-RG35XX result

The candidate runtime was installed from `Roms/APPS` and the launcher hash gate
passed on the device. Lifecycle, RMS CRUD, reopen/delete, and FileConnection
all passed. The first media operation stopped at the native audio boundary:

```text
P3_RUNTIME_HASH_GATE_BEFORE=PASS
P3_TEST_BOOT=PASS
P3_RMS_CRUD_ENUMERATE=PASS
P3_RMS_REOPEN_DELETE=PASS
P3_FILE_CREATE_WRITE_READ_DELETE=PASS
P3_RUNTIME_SERVICE_RESULT=FAIL_EXCEPTION
java.lang.UnsatisfiedLinkError: sdlMixerInit
```

The P3 parent platform jar had not loaded `libaudio.so` before the canonical
`SdlMixerManager` call. The accepted package therefore adds an
RG35XXLauncher-only audio-loader overlay. It leaves the canonical MMAPI,
`PlatformPlayer`, and `SdlMixerManager` classes unchanged and keeps the rebuilt
candidate runtime unchanged.

The follow-up package was run on the original RG35XX. All programmatic gates
passed and the user confirmed audible WAV and MIDI output:

```text
P3_RUNTIME_HASH_GATE_BEFORE=PASS
RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER
P3_TEST_BOOT=PASS
P3_RMS_CRUD_ENUMERATE=PASS
P3_RMS_REOPEN_DELETE=PASS
P3_FILE_CREATE_WRITE_READ_DELETE=PASS
P3_MMAPI_WAV_START=PASS
P3_MMAPI_WAV_PAUSE_RESUME=PASS
P3_MMAPI_MIDI_START=PASS
P3_MMAPI_MIDI_END_OF_MEDIA=PASS
P3_RUNTIME_SERVICE_RESULT=PASS
P3_DEVICE_PROGRAMMATIC_RESULT=PASS
RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES
P3_AUDIO_AUDIBLE_DEVICE=CONFIRMED_BY_USER
P3_PHYSICAL_ACCEPTANCE=PASS
```

## Required next implementation unit

After the audit gate passes in GitHub Actions, create one P3 exerciser and one
package. The exerciser must cover, at minimum:

- lifecycle start, pause/resume path where available, `notifyDestroyed()` and
  normal GarlicOS return;
- RMS create/open/add/update/enumerate/reopen/delete;
- FileConnection root/list/create/write/read/delete behavior within the
  configured device data root;
- MMAPI WAV/MIDI construction and state/control sequence, with audible output
  reviewed separately from API return values;
- Java-6 classfile and protected JamVM/glibj/input/video/audio identity gates.

No individual method-by-method SD packages are authorized. A P3 failure must be
classified as `CANONICAL_FREEJ2ME`, `RG35XX_FILESYSTEM/RMS_BOUNDARY`,
`RG35XX_AUDIO_BOUNDARY`, `LIFECYCLE_OWNER_UNRESOLVED` or
`RG35XX_JAVA6_COMPAT` before any runtime delta is proposed.

## Acceptance rule

P3 is not accepted from CI alone. The original RG35XX must run the complete
module package and provide logs plus physical observation. The P2C accepted
input/frontend owner and these protected identities must remain unchanged:

```text
RUNTIME_SOURCE=CANDIDATE_PROBE
RUNTIME_DEVICE_ROOT=/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
JAMVM_SHA256=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
GLIBJ_SHA256=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
INPUT_NATIVE_SHA256=6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c
VIDEO_NATIVE_SHA256=c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
AUDIO_NATIVE_SHA256=4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
P2C_PHYSICAL_ACCEPTANCE=PASS
P3_PHYSICAL_ACCEPTANCE=PASS
```

This checkpoint accepts the P3 runtime-service module on the tested original
RG35XX. It does not promote a different runtime, change the protected P2C
owners, or claim broad game-library stability.
