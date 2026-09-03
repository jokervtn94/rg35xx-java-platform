# RG35XX RC1 — WAV / PCM static and fixture audit

Status: STATIC-AUDIT-PASS for source/format contracts only. This is not BUILD-PASS or DEVICE-TEST-PASS.

## Sources checked
- Current `RG35XXWavDecoder.java`.
- Upstream FreeJ2ME WAV/IMA/law decoder behavior.
- IMA-WAV block packing specification: one 4-byte predictor/index header per channel; stereo body is packed in 4-byte channel groups, so each 8-byte L/R group yields eight stereo frames.
- Current `rg35xx_media_cache.h/.c`, `rg35xx_mixer.h/.c`.

## Decoder fixture contract
Synthetic fixture expectations used for static reconciliation:

1. PCM8 mono: unsigned bytes are centered at 128 and expanded to signed PCM16 LE. 0 -> -32768, 128 -> 0, 255 -> 32512.
2. PCM16 mono/stereo: payload remains little-endian and must contain complete channel frames. Odd/incomplete frames are rejected instead of silently truncating one channel/sample.
3. A-law / mu-law: each encoded byte expands to one signed PCM16 sample; stereo payload must contain complete two-channel frames.
4. IMA mono: predictor is the first output sample; nibbles are decoded low nibble first, then high nibble.
5. IMA stereo: predictor frame is L,R. Body is consumed as 4 bytes left + 4 bytes right; each group emits eight L,R frames. No per-group heap arrays are used.
6. Full stereo IMA blocks with payload not divisible by 8 are rejected. A short final block decodes only complete 8-byte channel groups and never emits an unmatched left/right tail.

## Important native sample-rate finding
The restored Java decoder intentionally preserves source sample rate. During this audit the current native PCM mixer was inspected and found to consume exactly one source frame for every 44.1 kHz output frame. `sample_rate` was used for media-time calculations, but not for PCM rate conversion.

Consequence before RC1-010D:
- 8 kHz WAV would play about 5.5x too fast/pitched up.
- 22.05 kHz WAV would play about 2x too fast/pitched up.
- Only 44.1 kHz PCM had correct duration/pitch.

## RC1-010D correction
`rg35xx_mixer.c` now keeps a per-voice Q15 source position and Q15 rate step:

`step = sourceRate * 32768 / 44100`

The render loop performs linear interpolation between adjacent PCM16 source frames and advances by that step. This preserves source duration/pitch while output remains fixed at `RG35XX_MIXER_RATE = 44100`.

Why Q15:
- fractional precision is sufficient for J2ME WAV rates;
- interpolation delta * fraction fits signed 32-bit arithmetic;
- only the long-lived source position uses uint64_t;
- no malloc/calloc/free is introduced in the render hot path.

One-second step-duration sanity calculations:
- 8000 Hz source -> ~44103 output frames
- 11025 Hz -> 44100
- 14700 Hz -> ~44099
- 22050 Hz -> 44100
- 32000 Hz -> ~44101
- 44100 Hz -> 44100
- 48000 Hz -> 44100

The small +/- frame rounding at some rates is from Q15 step quantization and is bounded; real device audio-quality/timing validation is still required.

## Remaining media gate blockers
- Apply exact PlatformPlayer WAV call site: `RG35XXWavDecoder.decode(...)` then `RG35XXNativePlayer.setPcm16(decoded.pcm16, decoded.sampleRate, decoded.channels)`.
- Reconcile tone conversion-to-MIDI before native registration.
- Verify native protocol/register payload alignment and TML/TSF link symbols.
- Compile consolidated Java and ARMv5TE native source before any BUILD-PASS claim.
