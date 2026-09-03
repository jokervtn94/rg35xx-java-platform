# RG35XX Java Platform — Authoritative Source Registry

Status: RC1 PRE-BUILD control document.

This registry is the mandatory duplicate/missing-source gate. Before ADD/REMOVE/REPLACE/MODIFY reload tasklogs, this registry and current target sources.

## Rules

1. Never create a second class for an existing responsibility without an explicit REPLACE task.
2. Never resurrect removed/superseded code from an older overlay without an explicit REVERT/REPLACE task.
3. Project-owned RG35XX Java code lives under `org.recompile.mobile` unless adapting an existing upstream API owner.
4. stdout remains binary video IPC; audio uses the dedicated RG35XX transport.
5. BUILD-PASS / DEVICE-TEST-PASS require real validation.

## Authoritative RG35XX Java classes

| Class | Responsibility | State |
|---|---|---|
| RG35XXPlatformProfile | target/profile policy | KEEP / PRESENT |
| RG35XXFrameScheduler | dirty-frame generation/wakeup | KEEP / PRESENT — 011B |
| RG35XXImageCache | immutable decoded-image cache | KEEP / PRESENT — 011B |
| RG35XXInputEngine | deterministic key transitions/repeat | KEEP / PRESENT — 011B |
| RG35XXWavDecoder | WAV normalization | KEEP / PRESENT |
| RG35XXMediaProfile | truthful RG35XX MMAPI capability policy | KEEP / PRESENT — 010N |
| RG35XXMediaRegistry | Java player registry/native-event queue | KEEP / PRESENT — 010L |
| RG35XXAudioProtocol | Java/native framed protocol | KEEP / PRESENT |
| RG35XXAudioTransport | dedicated Java→native audio writer | KEEP / PRESENT |
| RG35XXAudioBootstrap | inherited audio-FD bootstrap | KEEP / PRESENT |
| RG35XXNativePlayer | native MIDI/WAV/Tone adapter | KEEP / PRESENT |
| RG35XXToneSequenceEncoder | JavaSound-free ToneControl→SMF | KEEP / PRESENT — 010M |
| RG35XXFontEngine | historical bitmap renderer | SUPERSEDED — DO NOT RESTORE; GNU Classpath FontPeer is owner |
| RG35XXTransformCache | Sprite transform maps | KEEP / PRESENT — 011B |
| RG35XXRmsCoordinator | historical coalesced persistence | KEEP / PRESENT, DORMANT — 011C |
| RG35XXRmsAtomicFile | historical atomic helper | KEEP / PRESENT, UNHOOKED — 011C |
| RG35XXLifecycle | subsystem lifecycle ordering | KEEP / PRESENT — 011B/011C |

## Existing upstream owners — integrate, do not duplicate

`javax.microedition.media.Manager`, `javax.microedition.rms.RecordStore`, `org.recompile.freej2me.Libretro`, `org.recompile.mobile.MobilePlatform`, `PlatformGraphics`, `PlatformImage`, `PlatformPlayer`, `PlatformFont`, plus GNU Classpath `gnu.java.awt.peer.headless.HeadlessToolkit` and one real `ClasspathFontPeer` backend.

Vendor container decoders remain preserved but are not advertised on RG35XX while their conversion requires JavaSound; see 010N.

## Authoritative native modules

`rg35xx_audio_protocol.h`, `rg35xx_media_cache.[hc]`, `rg35xx_media_events.h`, `rg35xx_media_event_queue.[hc]`, `rg35xx_audio_dispatch.[hc]`, `rg35xx_audio_pipe.[hc]`, `rg35xx_mixer.[hc]`, `rg35xx_midi_backend.[hc]`, `rg35xx_tsf_worker.[hc]`, `rg35xx_tsf_impl.c`, `rg35xx_soundfont_source.[hc]`, `rg35xx_media_runtime.[hc]` are KEEP/PRESENT. `rg35xx_tsf_impl.c` is the sole TML/TSF implementation translation unit. Existing `freej2me_libretro.c` is the only core entrypoint.

011I locks the exact project native translation-unit set and link/lifecycle ownership in `docs/RC1-NATIVE-BUILD-MANIFEST.md`. 011J adds the deterministic disposable FreeJ2ME assembly driver. 011K adds the generated Make overlay contract while preserving the pinned upstream Makefile/Makefile.common as build owners. Each registered project `.c` is linked exactly once; headers are declarations only; no second libretro entrypoint or TML/TSF implementation owner is permitted.

## Authoritative external build inputs

- FreeJ2ME-Plus: `TASEmulators/freej2me-plus@13ec186903087156c145268f8706eecfaf9f1e50`.
- TinySoundFont/TinyMidiLoader: `schellingb/TinySoundFont@853a0a171759f1ddba0de1442133a75912bbeffa`; exact header blobs enforced by verifier.
- SoundFont: `mrbumpy409/GeneralUser-GS@684543d5e5efaef08d02be50dcda8d552478fa60`, `GeneralUser-GS.sf2`, blob `298b552d2e9d1307e03e5c5c99d2c046aaed9ec3`, size `32319396`; preserve upstream license/provenance caveat. See `docs/RC1-EXTERNAL-RUNTIME-ASSEMBLY.md`.
- GNU Classpath: exact 0.99 target source tree required; headless FontPeer contract is patch 0022. 011K keeps this as an explicit unresolved concrete-source reconciliation gate rather than fabricating an implementation.
- Font source: DejaVu Fonts 2.37, tag `version_2_37`, commit `0eda8a319c08835009849583cd090bb5b141ce25`. Use DejaVu Sans as authoritative RC1 logical SansSerif/Dialog source. The actual binary TTF SHA-256 must be recorded before BUILD-READY.

## Closed static gates

010K media process boundary; 010L direct MIDI/WAV facade; 010M ToneControl; 010N vendor-container capability boundary; 010O native media consolidation; 011B graphics/input/lifecycle; 011C pinned RMS baseline; 011D headless font ownership; 011E TML/TSF provenance; 011F consolidated prebuild gate; 011G external runtime/SoundFont provenance; 011H font-resource provider/provenance; 011I native build manifest/core-link ownership; 011J reproducible FreeJ2ME assembly; 011K runtime/Make assembly structure.

## Authoritative integration patches

0003 Manager media profile; 0004 audio pipe; 0005 audio bootstrap; 0006 native PlatformPlayer; 0007 drawRGB; 0008 transform cache; 0009 historical RMS policy (superseded by 0021); 0010 lifecycle; 0011 image cache; 0012 dirty-frame (blocking consumer superseded by 0020); 0013 input; 0014 media events; 0015 native media runtime; 0016 audio FD inheritance; 0017 process-boundary completion; 0018 direct MIDI/WAV; 0019 ToneControl; 0020 pinned graphics/input/lifecycle; 0021 pinned RMS baseline; 0022 GNU Classpath headless FontPeer.

0022 remains an integration contract until reconciled to concrete GNU Classpath 0.99 peer/delegate source. Other integration contracts are applied only by the deterministic 011J assembly against the exact pinned source; divergence is a failure, never permission to duplicate helpers.

## Mandatory pre-change procedure

Reload `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, this registry and current target files; classify KEEP/MODIFY/ADD/REPLACE/REMOVE; prove non-overlap; then audit imports/package/call sites after mutation.

## RC1 missing/duplicate gate

Consolidation requires every KEEP source exactly once, no superseded RG35XXFontEngine resurrection, exact TML/TSF headers, pinned SoundFont bytes, pinned/materialized DejaVu font with recorded SHA-256, concrete GNU Classpath headless peer assembly, consolidated native call-sites and the single native link manifest before BUILD-PASS.
