# RG35XX Java Platform — From-Zero Device-Proven Manifest v1

Status: FOUNDATION REBUILD POLICY
Branch: `rg35xx-from-zero-rebuild-v1`
Pinned FreeJ2ME upstream: `13ec186903087156c145268f8706eecfaf9f1e50`

## Rule

A fix is admitted to the from-zero foundation only when there is real RG35XX device evidence. `BUILD-PASS` alone is not sufficient. Every build starts from a fresh checkout of the pinned upstream and applies an explicit allowlist. Existing VC7Rxx assembled trees are never used as build input.

## ADMIT — device-proven foundation

### 1. JamVM L Production

- Device-proven interpreter fix: disable the unsafe direct-interpreter fusion `ALOAD_0 + GETFIELD -> GETFIELD_THIS`.
- Production SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`.
- Diagnostics A-K, low-pointer guards and diagnostic exit codes are forbidden.
- Current limitation: exact JamVM L source commit is not present in this repository. Until source provenance is restored, JamVM L is admitted only as a pinned external device-proven component, not claimed source-reproducible.

### 2. GNU Classpath baseline

- `glibj.zip` remains immutable.
- N3/N3.1 and later byte-patches of GNU Classpath are forbidden.

### 3. Lazy Media Boot

- Do not call `prepareMediaEngine()` during MIDlet boot.
- No `RG35XX-MediaWarmup` thread.
- No `/dev/snd/seq` probe during startup.
- Device evidence showed this removed the boot-time Java/JamVM instability and allowed `runJar()` + frame production to continue.

### 4. Golden asynchronous video transport

- Java ARGB frontbuffer snapshot.
- Dedicated Java frame worker.
- ARGB -> RGB565 conversion.
- Framed IPC.
- Native receiver thread with exact/full-frame validation.
- Front/back buffer publication.
- `retro_run()` presents the newest complete frame and must not block waiting for Java.
- Native Smart-Fit owns physical 640x480 fitting.

### 5. Proven dynamic logical view

- Keep game logical LCD separate from physical RG35XX output.
- Explicit `WxH` token in JAR filename may define logical LCD.
- Device-proven examples include KDTT 320x240 and normal 240x320 games.
- Do not import CV/CW deferred-Java boot-resolution architecture.

### 6. PNG iCCP compatibility boundary

- Compatibility belongs in `PlatformImage`, not in `glibj.zip`.
- Unsupported PNG `iCCP` can be stripped by a structure-aware PNG parser before ImageIO decode.
- Do not byte-patch Classpath or mutate the game JAR.

### 7. Render pipeline fixes with real-device evidence

Admitted behavior, not diagnostic spam:

- decoded image -> software image blit
- GameCanvas -> canonical frontbuffer flush
- frontbuffer -> frame transport
- LCD mask must only apply when `Mobile.renderLCDMask` is true

The diagnostic probes used to prove these stages are not admitted to production.

### 8. Early native observability

Keep bounded, low-cost startup/deinit checkpoints so a black/blue screen never becomes a no-evidence failure. Per-frame tracing is forbidden in production.

## HOLD — useful but requires revalidation before admission

### Golden audio worker-ring restore

Historical RG35XX evidence proved the architecture below worked:

- async libretro audio callback
- dedicated worker
- ring = 16384 frames
- MIDI prime = 3072 frames
- chunk = 1470
- TSF synth = 14700 Hz -> output 44100 Hz mono x3
- PCM prime ~= 2940 and underrun re-prime
- native END_OF_MEDIA / BGM resume

The current VC7R22 reconstruction must still be revalidated from a clean foundation, so audio is staged after the foundation build, not silently admitted.

### Transparency / tRNS / legacy white-key

VC7R20/21 contained promising fixes but the cited checkpoints were not globally DEVICE-PASS. Reapply only in a separate compatibility stage with visual device acceptance.

### Font

Current 727008-byte resource SHA `20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9` is reconstructed, not the historical Golden resource SHA `7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c`.

Do not label reconstructed font as Golden or stable.

## REJECT — never import into foundation

- CV/CW boot-time/deferred Java resolution architecture.
- VC7R diagnostic-only frame/color/image/text probes.
- unbounded per-frame `System.err` logging.
- `vc7r3` audio pumping tied to `retro_run()` / ~735 frames per game frame.
- 44.1k stereo/block-1024 audio path that replaced the proven worker-ring.
- media eager prewarm or `RG35XX-MediaWarmup`.
- JavaSound `MidiSystem.getSequencer()` as the RG35XX MIDI path.
- GNU Classpath N3/N3.1 byte patches.
- transform-cache patch `0008` as a required foundation fix.
- reconstructed font presented as Golden.
- any checkpoint whose only evidence is CI/build success.

## Clean-build order

1. Fresh checkout FreeJ2ME pin.
2. Apply Lazy Media Boot.
3. Apply Golden async video transport + native receiver/Smart-Fit.
4. Apply proven dynamic logical view without CV/CW.
5. Apply source-level PNG iCCP compatibility.
6. Apply only the minimal proven render-state fixes (canonical framebuffer/GameCanvas flush/LCD-mask gate), with diagnostics removed.
7. Add bounded early native logging.
8. Compile Java major 50 and ARM EABI5 soft-float core.
9. Stage against immutable Classpath + JamVM L.
10. Device acceptance.
11. Only after foundation passes: audio, transparency and font are introduced as isolated stages.

## Stable definition

A release is not `STABLE` until it has all of:

- source/build scripts
- SHA manifests
- installer + rollback
- real-device evidence on RG35XX
- no unresolved regression in boot/video/input/RMS/media required by the acceptance matrix
