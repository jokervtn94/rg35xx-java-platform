#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit("usage: vc7r22r21_apply_prime2048_ab.py freej2me_libretro.c")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s

pairs = (
    ("#define RG35XX_AUDIO_PRIME_FRAMES 3072u", "#define RG35XX_AUDIO_PRIME_FRAMES 2048u"),
    ("worker START ring=16384 target=3072 chunk=1470", "worker START ring=16384 target=2048 chunk=1470"),
    ("PRIMED queued=%u target=3072", "PRIMED queued=%u target=2048"),
    ("underrun queued=0; re-prime target=3072", "underrun queued=0; re-prime target=2048"),
)

for old, new in pairs:
    n = s.count(old)
    if n != 1:
        raise SystemExit("R2.1 FAIL expected exactly one occurrence: %s count=%d" % (old, n))
    s = s.replace(old, new, 1)

for token in (
    "#define RG35XX_AUDIO_RING_FRAMES 16384u",
    "#define RG35XX_AUDIO_WORKER_CHUNK 1470u",
    "#define RG35XX_AUDIO_PRIME_FRAMES 2048u",
    "RETRO_ENVIRONMENT_SET_AUDIO_CALLBACK",
):
    if token not in s:
        raise SystemExit("R2.1 FAIL missing token: " + token)

if "#define RG35XX_AUDIO_PRIME_FRAMES 3072u" in s:
    raise SystemExit("R2.1 FAIL old prime residue")
if s == orig:
    raise SystemExit("R2.1 FAIL no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("R2.1 PRIME2048_AB=PASS")
print("R2.1 ONLY_PRIMARY_DELTA=MIDI_PRIME_3072_TO_2048")
