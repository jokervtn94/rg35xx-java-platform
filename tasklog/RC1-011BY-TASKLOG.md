# RGJ-RC1-011BY — Restore RG35XX lazy media startup baseline

## Evidence
- Real-device log after the HeadlessToolkit restoration reaches JamVM but stops at ALSA sequencer initialization: `open /dev/snd/seq failed: No such file or directory`.
- Historical working-device traces show `MobilePlatform.runJar()` explicitly skipped `Manager.prepareMediaEngine()` on RG35XX before `loader.start()` and later routed MIDI/WAV through the native libretro bridge.
- Pinned upstream still calls `javax.microedition.media.Manager.prepareMediaEngine();` unconditionally inside `MobilePlatform.runJar()`.

## Scope
1. Preserve desktop/upstream eager media preparation outside the RG35XX target.
2. On explicit RG35XX launches (`RG35XXPlatformProfile.isActive()`), skip eager `prepareMediaEngine()` and call `loader.start()` directly.
3. Keep the existing direct RG35XX MIDI/WAV `PlatformPlayer` / native bridge unchanged.
4. Add an assembly gate proving the unconditional startup call is no longer on the RG35XX branch.
5. Require Patch Integration and Consolidated ARM Build PASS before packaging.

## Non-goals
- No changes to MIDI synthesis, WAV decoding, mixer policy, RMS, input, graphics, or lifecycle behavior.
- No DEVICE-TEST-PASS claim without hardware evidence.
