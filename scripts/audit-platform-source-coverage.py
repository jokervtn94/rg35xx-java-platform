#!/usr/bin/env python3
"""Static, documentation-only coverage checker for the RG35XX FreeJ2ME port.

This script does NOT modify or build runtime code. It exists to stop the project
from discovering missing Raw2D/API coverage one commercial game at a time.

Authority:
  - pinned Aweigit submodule commit ca11dfe8ea1cc273d92460f9a83bbf192023fa63
  - RG35XX reset/base reconstruction branch/docs

Outputs under build/platform-source-audit/:
  - PLATFORMGRAPHICS-METHOD-COVERAGE.tsv
  - PLATFORMIMAGE-AWT-DEPENDENCIES.tsv
  - A3-DEFERRED-TREES.tsv
  - CANONICAL-CAPABILITY-SURFACES.tsv
  - SUMMARY.txt

The checker intentionally distinguishes:
  * canonical method has an AWT dependency;
  * an RG35XX staging script mentions/overlays the method;
  * physical DEVICE-PASS (NOT inferred here).
A stage mention is evidence for manual review, never proof of semantic parity.
"""

from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
UP = ROOT / "upstream/freej2me-miyoomini"
OUT = ROOT / "build/platform-source-audit"
PIN = "ca11dfe8ea1cc273d92460f9a83bbf192023fa63"


def fail(msg: str) -> None:
    raise SystemExit("PLATFORM_SOURCE_AUDIT_FAIL=" + msg)


def git(*args: str, cwd: Path = ROOT) -> str:
    return subprocess.check_output(["git", "-C", str(cwd), *args], text=True).strip()


def read(path: Path) -> str:
    if not path.is_file():
        fail("missing:" + str(path.relative_to(ROOT) if path.is_relative_to(ROOT) else path))
    return path.read_text(encoding="utf-8", errors="replace")


def brace_methods(source: str):
    """Best-effort Java method extractor with brace balancing.

    It is deliberately conservative: constructors and methods with a body are
    returned; declarations ending with ';' are ignored. Multiline signatures are
    normalized. This is an audit aid, not a Java compiler/parser.
    """
    # Strip comments enough to avoid most false signatures while preserving line numbers poorly but harmlessly.
    cleaned = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    cleaned = re.sub(r"//.*", "", cleaned)
    sig = re.compile(
        r"(?P<prefix>(?:public|protected|private|static|final|synchronized|native|abstract|\s)+)"
        r"(?:(?P<ret>[\w.$<>\[\]]+)\s+)?"
        r"(?P<name>[A-Za-z_$][\w$]*)\s*\((?P<args>[^;{}]*)\)\s*"
        r"(?:throws\s+[^{]+)?\{",
        re.M,
    )
    results = []
    for m in sig.finditer(cleaned):
        name = m.group("name")
        if name in {"if", "for", "while", "switch", "catch", "synchronized"}:
            continue
        start = m.end() - 1
        depth = 0
        end = None
        for i in range(start, len(cleaned)):
            ch = cleaned[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        if end is None:
            continue
        body = cleaned[start:end]
        args = " ".join(m.group("args").split())
        results.append((name, args, body))
    return results


def stage_sources():
    paths = []
    for pat in (
        "scripts/stage-a4-*.py",
        "scripts/stage-a5-*.py",
        "scripts/stage-a6-*.py",
        "scripts/stage-a7-*.py",
        "scripts/stage-a8-*.py",
    ):
        paths.extend(ROOT.glob(pat))
    return sorted(set(p for p in paths if p.is_file()))


def stage_mentions(method: str, paths):
    found = []
    token = method + "("
    for p in paths:
        s = p.read_text(encoding="utf-8", errors="replace")
        if token in s or (" " + method + "(") in s or ("\"" + method) in s:
            found.append(p.relative_to(ROOT).as_posix())
    return found


def write_tsv(path: Path, header, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        f.write("\t".join(header) + "\n")
        for row in rows:
            f.write("\t".join(str(x).replace("\t", " ").replace("\n", " ") for x in row) + "\n")


if not UP.is_dir():
    fail("canonical submodule missing")
if git("rev-parse", "HEAD", cwd=UP) != PIN:
    fail("canonical pin mismatch:" + git("rev-parse", "HEAD", cwd=UP))

OUT.mkdir(parents=True, exist_ok=True)
stages = stage_sources()

# --- PlatformGraphics method matrix ---
pg_path = UP / "src/org/recompile/mobile/PlatformGraphics.java"
pg = read(pg_path)
pg_rows = []
awt_method_count = 0
uncovered_candidates = 0
for name, args, body in brace_methods(pg):
    # Canonical AWT backing dependencies relevant to RG35XX Raw2D null gc/canvas.
    uses_gc = bool(re.search(r"\bgc\s*\.", body))
    uses_canvas = bool(re.search(r"\bcanvas\b", body))
    uses_buffered = "BufferedImage" in body
    uses_graphics2d = "Graphics2D" in body
    awt_dep = uses_gc or uses_canvas or uses_buffered or uses_graphics2d
    mentions = stage_mentions(name, stages)
    if awt_dep:
        awt_method_count += 1
    # A stage mention is deliberately only a review hint; overloads require manual confirmation.
    stage_hint = ";".join(mentions) if mentions else "NONE_FOUND"
    classification = "CANONICAL_NO_DIRECT_AWT_BACKING"
    if awt_dep and not mentions:
        classification = "RAW2D_REVIEW_REQUIRED_NO_STAGE_MENTION"
        uncovered_candidates += 1
    elif awt_dep and mentions:
        classification = "RAW2D_STAGE_MENTION_REVIEW_OVERLOAD_AND_SEMANTICS"
    pg_rows.append((name, args, int(uses_gc), int(uses_canvas), int(uses_buffered), int(uses_graphics2d), stage_hint, classification))

write_tsv(
    OUT / "PLATFORMGRAPHICS-METHOD-COVERAGE.tsv",
    ["METHOD", "ARGS", "USES_GC", "USES_CANVAS", "USES_BUFFEREDIMAGE", "USES_GRAPHICS2D", "RG35XX_STAGE_MENTIONS", "STATIC_CLASSIFICATION"],
    pg_rows,
)

# --- PlatformImage AWT dependency inventory ---
pi_path = UP / "src/org/recompile/mobile/PlatformImage.java"
pi = read(pi_path)
pi_rows = []
for name, args, body in brace_methods(pi):
    deps = []
    for tok in ("BufferedImage", "ImageIO", "Graphics2D", "AffineTransform", "canvas"):
        if tok in body:
            deps.append(tok)
    mentions = stage_mentions(name, stages)
    pi_rows.append((name, args, ",".join(deps) if deps else "NONE", ";".join(mentions) if mentions else "NONE_FOUND"))
write_tsv(OUT / "PLATFORMIMAGE-AWT-DEPENDENCIES.tsv", ["METHOD", "ARGS", "CANONICAL_AWT_DEPS", "RG35XX_STAGE_MENTIONS"], pi_rows)

# --- A3 explicit deferred source trees ---
a3 = read(ROOT / "scripts/stage-a3-java6.py")
deferred = [
    "org/lwjgl",
    "ru/woesss/j2me/micro3d",
    "com/mascotcapsule/micro3d",
    "javax/microedition/m3g",
]
deferred_rows = []
for rel in deferred:
    deferred_rows.append((rel, "YES" if rel in a3 else "NO", "DEFERRED_CAPABILITY" if rel in a3 else "REVIEW"))
write_tsv(OUT / "A3-DEFERRED-TREES.tsv", ["SOURCE_TREE", "EXPLICITLY_REMOVED_BY_A3", "CLASSIFICATION"], deferred_rows)

# --- Broad source capability surface inventory ---
cap_specs = [
    ("MIDP_IO", "src/javax/microedition/io", "API_SURFACE"),
    ("BLUETOOTH", "src/javax/bluetooth", "API_SURFACE_PARTIAL_PROVIDER_UNVERIFIED"),
    ("OBEX", "src/javax/obex", "API_SURFACE_PROVIDER_UNVERIFIED"),
    ("PIM", "src/javax/microedition/pim", "CANONICAL_UNAVAILABLE_REVIEW"),
    ("PKI", "src/javax/microedition/pki", "API_SURFACE"),
    ("SENSOR", "src/javax/microedition/sensor", "API_SURFACE_PROVIDER_UNVERIFIED"),
    ("M3G", "src/javax/microedition/m3g", "DEFERRED_BY_A3"),
    ("NOKIA", "src/com/nokia", "VENDOR_API_MIXED"),
    ("SAMSUNG", "src/com/samsung", "VENDOR_API_MIXED"),
    ("SIEMENS", "src/com/siemens", "VENDOR_API_MIXED"),
    ("MICRO3D", "src/com/mascotcapsule/micro3d", "DEFERRED_BY_A3"),
]
cap_rows = []
for cap, rel, cls in cap_specs:
    p = UP / rel
    files = sorted(p.rglob("*.java")) if p.is_dir() else []
    cap_rows.append((cap, rel, "YES" if p.exists() else "NO", len(files), cls))
write_tsv(OUT / "CANONICAL-CAPABILITY-SURFACES.tsv", ["CAPABILITY", "PATH", "PRESENT", "JAVA_FILE_COUNT", "CLASSIFICATION"], cap_rows)

# --- Java 6 risk patterns in source tree (audit, not automatic failure) ---
risk_rows = []
patterns = {
    "LAMBDA": re.compile(r"->"),
    "DIAMOND": re.compile(r"new\s+[A-Za-z_$][\w.$]*\s*<>\s*\("),
    "TRY_WITH_RESOURCES": re.compile(r"try\s*\([^)]*(?:InputStream|OutputStream|Reader|Writer|ZipFile|JarFile|RandomAccessFile|Scanner|Connection)"),
    "JAVA_NIO_FILE": re.compile(r"java\.nio\.file|FileSystems\.|Files\."),
}
for p in sorted((UP / "src").rglob("*.java")):
    txt = p.read_text(encoding="utf-8", errors="replace")
    for kind, rx in patterns.items():
        if rx.search(txt):
            risk_rows.append((kind, p.relative_to(UP).as_posix()))
write_tsv(OUT / "JAVA6-SOURCE-RISKS.tsv", ["RISK", "CANONICAL_PATH"], risk_rows)

# --- Summary ---
summary = [
    "PROJECT=RG35XX-AWEIGIT-R1",
    "STAGE=PLATFORM-SOURCE-COVERAGE-AUDIT",
    "DOCS_ONLY=YES",
    "RUNTIME_CHANGE=NO",
    "CANONICAL_COMMIT=" + PIN,
    "PLATFORMGRAPHICS_METHODS_SCANNED=" + str(len(pg_rows)),
    "PLATFORMGRAPHICS_METHODS_WITH_AWT_DEP=" + str(awt_method_count),
    "PLATFORMGRAPHICS_AWT_METHODS_WITHOUT_STAGE_MENTION=" + str(uncovered_candidates),
    "PLATFORMIMAGE_METHODS_SCANNED=" + str(len(pi_rows)),
    "RG35XX_STAGE_FILES_SCANNED=" + str(len(stages)),
    "JAVA6_RISK_FILES=" + str(len(set(path for _, path in risk_rows))),
    "A3_DEFERRED_TREE_GATE=" + ("PASS" if all(flag == "YES" for _, flag, _ in deferred_rows) else "REVIEW"),
    "PHYSICAL_DEVICE_PASS_INFERRED=NO",
    "STATIC_AUDIT_COMPLETE=PASS",
]
(OUT / "SUMMARY.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
print("\n".join(summary))
