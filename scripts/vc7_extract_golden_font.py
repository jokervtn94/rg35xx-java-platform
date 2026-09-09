#!/usr/bin/env python3
"""Extract the device-proven Golden RG35XX bitmap font from a verified runtime JAR.

Fail-closed by design. The output is written only after path, size and SHA-256 all
match the recovered Golden font contract.
"""

import hashlib
import os
import sys
import tempfile
import zipfile

ENTRY = "org/recompile/mobile/rg35xx-font.bin"
EXPECTED_SIZE = 727008
EXPECTED_SHA256 = "7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c"


def fail(msg):
    sys.stderr.write("VC7 GOLDEN FONT FAIL: %s\n" % msg)
    return 1


def main(argv):
    if len(argv) != 3:
        sys.stderr.write("usage: vc7_extract_golden_font.py <golden-runtime.jar> <output-font.bin>\n")
        return 2

    jar_path, output_path = argv[1], argv[2]
    if not os.path.isfile(jar_path):
        return fail("runtime JAR missing: %s" % jar_path)

    try:
        with zipfile.ZipFile(jar_path, "r") as zf:
            names = zf.namelist()
            if names.count(ENTRY) != 1:
                return fail("expected exactly one %s entry, found %d" % (ENTRY, names.count(ENTRY)))
            data = zf.read(ENTRY)
    except (IOError, OSError, zipfile.BadZipfile) as exc:
        return fail("cannot read runtime JAR: %s" % exc)

    if len(data) != EXPECTED_SIZE:
        return fail("font size mismatch: got %d expected %d" % (len(data), EXPECTED_SIZE))

    digest = hashlib.sha256(data).hexdigest()
    if digest != EXPECTED_SHA256:
        return fail("font SHA-256 mismatch: got %s expected %s" % (digest, EXPECTED_SHA256))

    parent = os.path.dirname(os.path.abspath(output_path)) or "."
    if not os.path.isdir(parent):
        os.makedirs(parent)

    fd, tmp = tempfile.mkstemp(prefix=".rg35xx-font.", dir=parent)
    try:
        with os.fdopen(fd, "wb") as fh:
            fh.write(data)
            fh.flush()
            try:
                os.fsync(fh.fileno())
            except OSError:
                pass
        os.rename(tmp, output_path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise

    sys.stdout.write("VC7 GOLDEN FONT PASS\n")
    sys.stdout.write("ENTRY=%s\n" % ENTRY)
    sys.stdout.write("SIZE=%d\n" % len(data))
    sys.stdout.write("SHA256=%s\n" % digest)
    sys.stdout.write("OUTPUT=%s\n" % os.path.abspath(output_path))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
