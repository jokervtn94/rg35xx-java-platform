#!/usr/bin/env python3
"""Audit the pinned Miyoo source and RG35XX P3 runtime-service boundary.

This is intentionally an audit-only gate.  It does not rewrite the canonical
submodule or generate runtime classes.  The gate is designed to run after CI
checks out ``upstream/freej2me-miyoomini`` at the locked canonical commit.
"""

from __future__ import print_function

import hashlib
import re
import subprocess
import sys
from pathlib import Path


CANONICAL = "ca11dfe8ea1cc273d92460f9a83bbf192023fa63"
REQUIRED = {
    "lifecycle": [
        "src/org/recompile/mobile/MobilePlatform.java",
        "src/org/recompile/mobile/MIDletLoader.java",
        "src/javax/microedition/midlet/MIDlet.java",
    ],
    "rms-filesystem": [
        "src/javax/microedition/rms/RecordStore.java",
        "src/javax/microedition/rms/impl/AndroidRecordStoreManager.java",
        "src/org/microemu/cldc/file/FileSystemFileConnection.java",
    ],
    "media-audio": [
        "src/org/recompile/mobile/PlatformPlayer.java",
        "src/org/recompile/mobile/SdlMixerManager.java",
    ],
}


def fail(message):
    raise SystemExit("P3_AUDIT_FAIL=" + message)


def git_head(repo):
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), "rev-parse", "HEAD"],
            stderr=subprocess.STDOUT,
        ).decode("ascii").strip()
    except Exception as exc:
        fail("canonical-submodule-unavailable:%s" % exc)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while True:
            chunk = stream.read(1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def read(path):
    return path.read_text(encoding="utf-8")


def main():
    root = Path(__file__).resolve().parents[1]
    upstream = root / "upstream" / "freej2me-miyoomini"
    source = upstream / "src"
    if not source.is_dir():
        fail("canonical-source-missing:%s" % source)

    head = git_head(upstream)
    print("P3_CANONICAL_HEAD=%s" % head)
    if head != CANONICAL:
        fail("canonical-pin:%s" % head)
    print("P3_CANONICAL_PIN=PASS")

    missing = []
    for owner, paths in REQUIRED.items():
        for relative in paths:
            path = root / "upstream" / "freej2me-miyoomini" / relative
            if not path.is_file():
                missing.append(relative)
                continue
            print("P3_SOURCE=%s OWNER=%s SHA256=%s" % (relative, owner, sha256(path)))
    if missing:
        fail("required-source-missing:%s" % ",".join(missing))

    lifecycle = "\n".join(read(upstream / relative) for relative in REQUIRED["lifecycle"])
    loader = read(upstream / REQUIRED["lifecycle"][1])
    rms = read(upstream / REQUIRED["rms-filesystem"][1])
    file_connection = read(upstream / REQUIRED["rms-filesystem"][2])
    player = read(upstream / REQUIRED["media-audio"][0])
    mixer = read(upstream / REQUIRED["media-audio"][1])

    checks = [
        ("P3_LIFECYCLE_STARTAPP", "startApp", lifecycle),
        ("P3_LIFECYCLE_NOTIFY_DESTROYED", "notifyDestroyed", lifecycle),
        ("P3_LIFECYCLE_LOADER", "class MIDletLoader", loader),
        ("P3_RMS_PERSISTENCE", "RecordStore", rms),
        ("P3_FILE_CONNECTION", "FileSystemFileConnection", file_connection),
        ("P3_MMAPI_PLAYER", "implements Player", player),
        ("P3_SDL_MIXER_BRIDGE", "SdlMixerManager", mixer),
    ]
    for marker, needle, content in checks:
        if needle not in content:
            fail("contract-anchor:%s:%s" % (marker, needle))
        print("%s=PASS" % marker)

    java6_risk = []
    for relative in [
        REQUIRED["lifecycle"][1],
        REQUIRED["rms-filesystem"][1],
        REQUIRED["rms-filesystem"][2],
        REQUIRED["media-audio"][0],
    ]:
        content = read(upstream / relative)
        if re.search(r"java\.nio\.file|new\s+[^;]+<>\s*\(|try\s*\(", content):
            java6_risk.append(relative)
    print("P3_JAVA6_RISK_FILES=%s" % ",".join(java6_risk))
    print("P3_RUNTIME_SERVICE_AUDIT=PASS")
    print("P3_RUNTIME_SERVICE_DEVICE_TEST=NOT_TESTED")
    print("P3_RUNTIME_SERVICE_IMPLEMENTATION=NOT_AUTHORIZED_BY_AUDIT")


if __name__ == "__main__":
    main()
