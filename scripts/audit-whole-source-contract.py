#!/usr/bin/env python3
"""Whole-source, documentation-only audit for the pinned Aweigit -> RG35XX port.

This is intentionally a risk/inventory generator, not an implementation tool.
It scans every canonical Java source file so platform work does not depend on a
commercial game eventually touching an unported class/method.

No DEVICE-PASS or semantic correctness is inferred from this static scan.
"""

from pathlib import Path
from collections import Counter
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
UP = ROOT / "upstream/freej2me-miyoomini"
OUT = ROOT / "build/platform-whole-source-audit"
PIN = "ca11dfe8ea1cc273d92460f9a83bbf192023fa63"

DEFERRED_PREFIXES = (
    "src/org/lwjgl/",
    "src/ru/woesss/j2me/micro3d/",
    "src/com/mascotcapsule/micro3d/",
    "src/javax/microedition/m3g/",
)


def fail(msg):
    raise SystemExit("WHOLE_SOURCE_AUDIT_FAIL=" + msg)


def git(*args, cwd=ROOT):
    return subprocess.check_output(["git", "-C", str(cwd), *args], text=True).strip()


def yn(v):
    return "YES" if v else "NO"


def tsv(path, header, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        f.write("\t".join(header) + "\n")
        for row in rows:
            f.write("\t".join(str(x).replace("\t", " ").replace("\n", " ") for x in row) + "\n")


if not UP.is_dir():
    fail("canonical submodule missing")
head = git("rev-parse", "HEAD", cwd=UP)
if head != PIN:
    fail("canonical pin mismatch:" + head)

OUT.mkdir(parents=True, exist_ok=True)
stages = sorted(ROOT.glob("scripts/stage-a*.py"))
stage_text = {p: p.read_text(encoding="utf-8", errors="replace") for p in stages if p.is_file()}

rows = []
class_counts = Counter()
package_counts = Counter()
java_files = sorted((UP / "src").rglob("*.java"))

for p in java_files:
    rel = p.relative_to(UP).as_posix()
    txt = p.read_text(encoding="utf-8", errors="replace")
    pkg_m = re.search(r"(?m)^\s*package\s+([\w.]+)\s*;", txt)
    pkg = pkg_m.group(1) if pkg_m else "<default>"
    top = ".".join(pkg.split(".")[:3]) if pkg != "<default>" else pkg
    package_counts[top] += 1

    deferred = any(rel.startswith(prefix) for prefix in DEFERRED_PREFIXES)
    awt = bool(re.search(r"\bjava\.awt\b|\bBufferedImage\b|\bGraphics2D\b|\bAffineTransform\b", txt))
    imageio = "javax.imageio" in txt or "ImageIO." in txt
    nio = bool(re.search(r"\bjava\.nio\b|\bFileSystems\.|\bFiles\.", txt))
    lambda_ = "->" in txt
    diamond = bool(re.search(r"new\s+[A-Za-z_$][\w.$]*\s*<>\s*\(", txt))
    twr = bool(re.search(r"try\s*\([^)]*(?:InputStream|OutputStream|Reader|Writer|ZipFile|JarFile|RandomAccessFile|Scanner|Connection)", txt))
    native = bool(re.search(r"\bnative\s+[\w<>, ?\[\].]+\s+[A-Za-z_$][\w$]*\s*\(", txt))
    javanet = "java.net." in txt or "javax.net." in txt
    TODO = bool(re.search(r"\bTODO\b|not implemented|Not implemented|Implementation is not available|unsupported|Unsupported", txt))
    unsupported_throw = "UnsupportedOperationException" in txt
    security_unavailable = bool(re.search(r"SecurityException\s*\([^)]*(?:not available|unavailable|not supported)", txt, re.I))
    return_null = bool(re.search(r"\breturn\s+null\s*;", txt))
    return_false = bool(re.search(r"\breturn\s+false\s*;", txt))

    basename = p.name
    class_stem = p.stem
    mentions = []
    for sp, st in stage_text.items():
        if basename in st or class_stem in st or rel.replace("src/", "") in st:
            mentions.append(sp.relative_to(ROOT).as_posix())

    flags = []
    if deferred:
        flags.append("DEFERRED_BY_A3")
    if awt or imageio:
        flags.append("AWT_OR_IMAGEIO_DEP")
    if nio or lambda_ or diamond or twr:
        flags.append("JAVA6_COMPAT_RISK")
    if native:
        flags.append("NATIVE_SURFACE")
    if javanet:
        flags.append("NETWORK_RUNTIME_DEP")
    if TODO or unsupported_throw or security_unavailable:
        flags.append("CANONICAL_INCOMPLETE_OR_STUB_RISK")
    if return_null or return_false:
        flags.append("NULL_FALSE_RETURN_REVIEW")
    if not flags:
        flags.append("NO_STATIC_RISK_FLAG")

    for fl in set(flags):
        class_counts[fl] += 1

    rows.append((
        rel, pkg, yn(deferred), yn(awt), yn(imageio), yn(nio), yn(lambda_), yn(diamond), yn(twr),
        yn(native), yn(javanet), yn(TODO), yn(unsupported_throw), yn(security_unavailable),
        yn(return_null), yn(return_false), ";".join(mentions) if mentions else "NONE_FOUND", ",".join(flags)
    ))


tsv(
    OUT / "WHOLE-JAVA-SOURCE-INVENTORY.tsv",
    [
        "PATH", "PACKAGE", "A3_DEFERRED", "AWT", "IMAGEIO", "NIO", "LAMBDA", "DIAMOND", "TRY_WITH_RESOURCES",
        "NATIVE_METHOD", "JAVA_NET", "TODO_OR_UNSUPPORTED_TEXT", "THROWS_UNSUPPORTED", "SECURITY_UNAVAILABLE",
        "RETURN_NULL", "RETURN_FALSE", "RG35XX_STAGE_MENTIONS", "STATIC_FLAGS"
    ],
    rows,
)

pkg_rows = [(k, v) for k, v in sorted(package_counts.items())]
tsv(OUT / "PACKAGE-COUNTS.tsv", ["PACKAGE_PREFIX", "JAVA_FILE_COUNT"], pkg_rows)
flag_rows = [(k, v) for k, v in sorted(class_counts.items())]
tsv(OUT / "FLAG-COUNTS.tsv", ["STATIC_FLAG", "JAVA_FILE_COUNT"], flag_rows)

# Explicit provider/surface checks: presence only. Semantic classifications remain in docs matrix.
provider_checks = [
    ("FILE_PROVIDER", "src/org/microemu/cldc/file/Connection.java"),
    ("HTTP_PROVIDER", "src/org/microemu/cldc/http/Connection.java"),
    ("HTTPS_PROVIDER", "src/org/microemu/cldc/https/Connection.java"),
    ("SOCKET_PROVIDER", "src/org/microemu/cldc/socket/Connection.java"),
    ("DATAGRAM_PROVIDER", "src/org/microemu/cldc/datagram/Connection.java"),
    ("SMS_PROVIDER", "src/org/microemu/cldc/sms/Connection.java"),
    ("BLUETOOTH_LOCALDEVICE", "src/javax/bluetooth/LocalDevice.java"),
    ("BTSPP_PROVIDER", "src/org/microemu/cldc/btspp/Connection.java"),
    ("PIM_ENTRYPOINT", "src/javax/microedition/pim/PIM.java"),
    ("SENSOR_MANAGER", "src/javax/microedition/sensor/SensorManager.java"),
    ("LOCATION_API_ROOT", "src/javax/microedition/location/Location.java"),
    ("WMA_MESSAGE_CONNECTION", "src/javax/wireless/messaging/MessageConnection.java"),
]
provider_rows = []
for name, rel in provider_checks:
    provider_rows.append((name, rel, yn((UP / rel).is_file())))
tsv(OUT / "PROVIDER-PRESENCE.tsv", ["CHECK", "CANONICAL_PATH", "PRESENT"], provider_rows)

summary = [
    "PROJECT=RG35XX-AWEIGIT-R1",
    "STAGE=WHOLE-CANONICAL-SOURCE-CONTRACT-AUDIT",
    "DOCS_ONLY=YES",
    "RUNTIME_CHANGE=NO",
    "CANONICAL_COMMIT=" + PIN,
    "TOTAL_CANONICAL_JAVA_FILES=" + str(len(java_files)),
    "A3_DEFERRED_JAVA_FILES=" + str(class_counts["DEFERRED_BY_A3"]),
    "AWT_OR_IMAGEIO_DEP_FILES=" + str(class_counts["AWT_OR_IMAGEIO_DEP"]),
    "JAVA6_COMPAT_RISK_FILES=" + str(class_counts["JAVA6_COMPAT_RISK"]),
    "NATIVE_SURFACE_FILES=" + str(class_counts["NATIVE_SURFACE"]),
    "NETWORK_RUNTIME_DEP_FILES=" + str(class_counts["NETWORK_RUNTIME_DEP"]),
    "CANONICAL_INCOMPLETE_OR_STUB_RISK_FILES=" + str(class_counts["CANONICAL_INCOMPLETE_OR_STUB_RISK"]),
    "PHYSICAL_DEVICE_PASS_INFERRED=NO",
    "WHOLE_SOURCE_STATIC_AUDIT=PASS",
]
(OUT / "SUMMARY.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
print("\n".join(summary))
