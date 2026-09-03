# RGJ-RC1-010L — Direct MIDI/WAV Java media facade

- Action: MODIFY / AUDIT / ADD INTEGRATION PATCH
- Status: STATIC-AUDIT-PASS
- Pre-change reload: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY + current helpers + exact upstream Manager/PlatformPlayer/JavaxPlatformPlayer.
- Exact upstream finding: Manager returns JavaxPlatformPlayer and advertises desktop media broadly; PlatformPlayer constructor can immediately create JavaSound/JLayer backends, so RG35XX target routing must occur before backend construction.
- Target selector: `RG35XXPlatformProfile.isActive()` reads `-Dfreej2me.rg35xx=true`; desktop/AWT remains false and keeps upstream behavior. Selector is independent of audio-FD availability.
- Capability correction: RG35XX direct advertised types are MIDI/WAV aliases only. Tone was removed from direct advertised support until the JavaSound-free conversion stage is complete; AMR/MPEG remain false.
- Event correction: `RG35XXMediaRegistry` and `RG35XXNativePlayer` now preserve STARTED state for LOOPED and transition to PREFETCHED only on END_OF_MEDIA.
- Tone preparation: `RG35XXNativePlayer.setMidi(byte[])` allows a later ToneControl/vendor converter to replace media before prefetch; TYPE_TONE may register proven converted MIDI bytes, but this is not yet advertised as direct support.
- Integration patch: `patches/0018-manager-platformplayer-rg35xx-direct-media.patch`.
- Audit: `docs/RC1-DIRECT-MEDIA-FACADE-AUDIT.md`.
- Rollback: remove the RG35XX selector branch and helper semantic changes together only if exact assembled source proves incompatible; do not restore unconditional Manager capability replacement.
- BUILD-PASS: not claimed.
- DEVICE-TEST-PASS: not claimed.
