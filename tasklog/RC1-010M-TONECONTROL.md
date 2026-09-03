# RGJ-RC1-010M — JavaSound-free ToneControl / Manager.playTone

- Action: ADD / MODIFY / AUDIT / ADD INTEGRATION PATCH
- Status: STATIC-AUDIT-PASS
- Pre-change reload: TASKLOG + RC1-TASKLOG + PLATFORM-SOURCE-REGISTRY + current media helpers + exact upstream ToneControl/Manager/PlatformPlayer sources.
- Duplicate check: repository search found no existing RG35XX ToneControl A-BNF -> MIDI encoder; public ToneControl remains upstream-owned.
- Source added: `src/org/recompile/mobile/RG35XXToneSequenceEncoder.java`.
- Specification basis: MIDP 2.0 ToneControl VERSION/TEMPO/RESOLUTION/BLOCK/PLAY_BLOCK/SET_VOLUME/REPEAT/note/SILENCE grammar and parameter ranges.
- Timing: generated format-0 SMF uses PPQ=resolution and four ticks per ToneControl duration unit, exactly preserving the MIDP duration formula.
- Guardrails: previous-block-only PLAY_BLOCK validation, matched block ids, fixed expanded-event ceiling, no JavaSound/concurrent dependency.
- Manager.playTone: integration preserves upstream validation, 50ms short-tone compatibility floor, nonblocking behavior and single-current-tone replacement while eliminating the RG35XX toneThread/JavaSound dependency.
- PlatformPlayer: existing nested ToneControl remains the public Control owner; RG35XX branch converts before prefetch and calls `RG35XXNativePlayer.setMidi()`; device://tone branches before desktop midiPlayer construction.
- Capability promotion: `RG35XXMediaProfile` now advertises `audio/x-tone-seq`; live device://midi remains unclaimed.
- Integration patch: `patches/0019-platformplayer-tonecontrol-rg35xx.patch`.
- Audit: `docs/RC1-TONECONTROL-AUDIT.md`.
- BUILD-PASS: not claimed.
- DEVICE-TEST-PASS: not claimed.
