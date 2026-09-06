#!/usr/bin/env python3
"""RC1 Golden CN: exact binary patch for device-proven Golden audio worker.

The Golden core primes MIDI at 12288 output frames (~278.6 ms @ 44.1 kHz).
Device evidence shows Manager.playTone() generates a 177 ms MIDI one-shot that
reaches native END before the ring ever becomes primed, so no audible samples
reach the frontend even though the Java test reports PASS.

This patch lowers ONLY the Golden MIDI prime threshold to 3072 frames
(~69.7 ms). It does not alter sample rate, synth timing, note duration, ring
capacity, PCM prime policy, END_OF_MEDIA protocol, or video code.

Fail-closed contract: the input must contain the exact three ARM instructions
from the audited Golden core. Any mismatch aborts rather than patching an
unknown binary.
"""
from pathlib import Path
import argparse, struct, hashlib

PATCHES = {
    0x11710: (0xE3A02A03, 0xE3A02B03),  # mov r2,#12288 -> mov r2,#3072 (diagnostic target)
    0x1180C: (0x13A02A03, 0x13A02B03),  # movne r2,#12288 -> movne r2,#3072
    0x11824: (0xE3550A03, 0xE3550B03),  # cmp r5,#12288 -> cmp r5,#3072
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('input')
    ap.add_argument('output')
    args = ap.parse_args()
    data = bytearray(Path(args.input).read_bytes())
    for off, (old, new) in PATCHES.items():
        if off + 4 > len(data):
            raise SystemExit('CN FAIL: core too small for offset 0x%x' % off)
        got = struct.unpack_from('<I', data, off)[0]
        if got != old:
            raise SystemExit('CN FAIL: offset 0x%x expected %08x got %08x' % (off, old, got))
    for off, (_, new) in PATCHES.items():
        struct.pack_into('<I', data, off, new)
    Path(args.output).write_bytes(data)
    print('CN input sha256 :', sha256(Path(args.input).read_bytes()))
    print('CN output sha256:', sha256(data))
    print('CN prime frames  : 3072 (~69.7 ms @ 44100 Hz)')

if __name__ == '__main__':
    main()
