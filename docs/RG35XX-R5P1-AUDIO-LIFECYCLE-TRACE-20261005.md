# RG35XX R5.1 audio lifecycle trace

**Branch:** `physical-test/rg35xx-r5-audio-owner-r5p1-audio-trace`  
**Purpose:** diagnose the remaining God of War gameplay-audio failure after the R5 owner-aware candidate passed the generic WAV/MIDI and Full Port checks.

## Scope

R5.1 changes only the native SDL1/SDL_mixer diagnostic build:

- logs `load`, `play`, `pause`, `resume`, `isPlaying`, `stop`, `free`, and `quit`;
- records manager identity, MIDI handle, current global SDL_mixer music handle, open state, playing state, and return code;
- wraps the R5 owner-aware `play` call so the actual transition is visible;
- enables tracing only from the Full Port and P7 diagnostic launchers with `RG35XX_AUDIO_TRACE=1`.

Java PlatformPlayer/MMAPI, JamVM, video, input, WAV/MIDI routing, and game data are unchanged. No God of War-specific code or commercial game bytes are added.

## Required physical run

Install the generated `RG35XX-MIYOO-FULL-PORT-R1-P7-READY-R5-AUDIO-TRACE.zip` exactly as a test package. Run the existing Tier-0 test with the same external game JARs:

1. Vua Cướp Biển: confirm the existing functional pass remains unchanged.
2. God of War: confirm menu audio, enter gameplay, wait for the point where gameplay audio is normally expected, then exit normally.

Collect:

```text
/mnt/mmc/RG35XX-R1-P7-EVIDENCE/GOW-R1.log
/mnt/mmc/RG35XX-R1-P7-EVIDENCE/P7-TIER0-RUN.log
```

## Interpretation

- `midi.load.pass` followed by no `r5.owner.play.begin`: Java/platform did not request playback for the gameplay track.
- `r5.owner.play.end result=-1` or `midi.play.fail`: native SDL_mixer playback failed; use the adjacent SDL error.
- `r5.owner.play.end result=0` with `playing=0`: playback was accepted but the SDL_mixer music slot stopped immediately.
- `playing=1` while the device is silent: the route/ALSA boundary remains implicated; compare the underrun lines and the exact transition timing.
- `r5.owner.*.ignored` for the gameplay manager: owner binding/current-handle sequencing remains incorrect.

This package is diagnostic only:

```text
P7=RETEST_REQUIRED
DEVICE_PASS=NO
STABLE=NO
```
