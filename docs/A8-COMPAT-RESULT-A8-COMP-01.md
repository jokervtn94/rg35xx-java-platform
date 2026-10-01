# A8-COMP-01 Compatibility Result

## Candidate identity

- Candidate: `A8-COMP-01`
- Game: Asphalt Nitro
- JAR filename: `Asphalt Nitro [320x240] (BlackBerry 8520) (andrew-lviv.net).jar`
- JAR SHA256: `b1ced935017042c4b69491ab2d34209200a178d52bd247d77cf4e598134571ff`
- Device: Original RG35XX
- Baseline: A8 canonical production runtime

## Runtime identity

The A8 runtime identity gate passed before game startup:

- JamVM: PASS
- glibj: PASS
- platform JAR: `057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c`
- input native: PASS
- video native: PASS
- audio native: PASS
- A1P5 prime: PASS
- protected hashes after execution: PASS

## Reproduced failure

The MIDlet was created and `startApp()` was invoked. Startup then failed during class loading because the JAR requires the BlackBerry/RIM vendor API class:

`net.rim.device.api.system.SystemListener2`

Observed runtime chain:

- `SystemListener2.class Not Found`
- `Error Adapting Class net.rim.device.api.system.SystemListener2`
- `NoClassDefFoundError: net/rim/device/api/system/SystemListener2`
- failure originates from `GloftASGM.startApp`

The canonical `aweigit/freej2me-miyoomini` source contains no implementation for `SystemListener2` or the `net.rim.device.api` namespace.

## Classification

```text
BOOT=FAIL
GRAPHICS=NOT_REACHED
INPUT=NOT_REACHED
GAMEPLAY=NOT_REACHED
AUDIO=NOT_REACHED
MEDIA=NOT_REACHED
RMS=NOT_REACHED
LIFECYCLE=NOT_REACHED
PERFORMANCE=NOT_REACHED
HANG_CRASH=NO_RUNTIME_HANG_OBSERVED
EXIT=PROCESS_RETURNED

RESULT=FAIL
FAILURE_OWNER=GAME/JAR_PROFILE_VENDOR_API_BLACKBERRY_RIM
A8_RUNTIME_REGRESSION=NO
A9_RUNTIME_CHANGE=NOT_JUSTIFIED
```

## Interpretation

This failure is not evidence of an RG35XX graphics, input, audio, media, or protected-runtime regression. The tested JAR is a BlackBerry 8520-specific build and depends on a RIM vendor API that is outside the currently supported canonical FreeJ2ME API surface.

The correct next compatibility candidate is a standard MIDP/CLDC build (for example a generic/Nokia/Sony Ericsson Java ME build) so the next test reaches actual graphics/input/audio/gameplay paths.

## Evidence source

Collected device evidence bundle:

`A8-COMPAT-EVIDENCE-20261001-100240.zip`

The RG35XX RTC timestamp embedded in the per-run evidence directory is stale (`20231105-164650`); registration and collection on the host occurred on 2026-10-01. This does not affect JAR identity or runtime hashes.
