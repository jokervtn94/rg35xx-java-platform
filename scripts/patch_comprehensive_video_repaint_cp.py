#!/usr/bin/env python3
"""Fail-closed CP patch for the RG35XX comprehensive device-test JAR.

Purpose:
- CO already resets tick/paint timing after the automatic suite.
- The old VIDEO_REPAINT gate still waited until tick 100 (~5 s), which lets
  manual navigation/media activity contaminate the repaint-only window.
- CP evaluates at tick 40 (~2 s) while preserving maxPaintGap < 250 ms.

This script does not modify runtime/core behavior. It patches only the test
class and refuses to run unless the exact expected bytecode/string patterns
are present once.
"""

from pathlib import Path
import shutil
import sys
import tempfile
import zipfile


def patch(input_jar: Path, output_jar: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="rg35xx-cp-") as td:
        tree = Path(td)
        with zipfile.ZipFile(input_jar, "r") as z:
            z.extractall(tree)

        cls = tree / "RG35XXComprehensiveTest$TestCanvas.class"
        data = bytearray(cls.read_bytes())

        # getfield #154 (tick), bipush 100, if_icmpne
        needle = bytes.fromhex("b4 00 9a 10 64 a0")
        hits = []
        p = 0
        while True:
            i = data.find(needle, p)
            if i < 0:
                break
            hits.append(i)
            p = i + 1
        if len(hits) != 1:
            raise SystemExit("unexpected VIDEO_REPAINT tick gate: %r" % (hits,))
        data[hits[0] + 4] = 0x28  # 40 decimal

        old = b"100 repaint ticks; max gap="
        new = b"40 steady repaint; max gap="
        if len(old) != len(new) or data.count(old) != 1:
            raise SystemExit("unexpected VIDEO_REPAINT message pattern")
        data = data.replace(old, new, 1)
        cls.write_bytes(data)

        if output_jar.exists():
            output_jar.unlink()
        with zipfile.ZipFile(output_jar, "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(tree.rglob("*")):
                if f.is_file():
                    z.write(f, f.relative_to(tree).as_posix())


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: patch_comprehensive_video_repaint_cp.py INPUT.jar OUTPUT.jar")
    patch(Path(sys.argv[1]), Path(sys.argv[2]))
