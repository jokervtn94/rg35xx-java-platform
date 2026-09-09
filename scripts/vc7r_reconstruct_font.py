#!/usr/bin/env python3
"""Build a RECONSTRUCTED VC7 bitmap resource from user/system fonts.

This does NOT reproduce or claim the lost Golden binary. It only emits the
same 22719-record / 32-byte-record container contract so VC7 can be exercised
without GNU AWT/OpenType text rasterization.

Requires: Pillow, fontTools.
Example:
  python3 scripts/vc7r_reconstruct_font.py \
    --font /path/to/latin.ttf \
    --font /path/to/cjk.ttc#0 \
    --out rg35xx-font-reconstructed.bin \
    --manifest rg35xx-font-reconstructed.json
"""

import argparse
import hashlib
import json
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTCollection, TTFont

RANGES = [
    (0x0020, 0x007E),
    (0x00A0, 0x024F),
    (0x0370, 0x03FF),
    (0x0400, 0x052F),
    (0x1E00, 0x1EFF),
    (0x3000, 0x303F),
    (0x3040, 0x309F),
    (0x30A0, 0x30FF),
    (0x4E00, 0x9FFF),
    (0xFF00, 0xFFEF),
]
EXPECTED_GLYPHS = 22719
RECORD_BYTES = 32
EXPECTED_BYTES = EXPECTED_GLYPHS * RECORD_BYTES
GOLDEN_SHA256 = "7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c"


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_font_spec(spec):
    if "#" in spec:
        path, idx = spec.rsplit("#", 1)
        return path, int(idx)
    return spec, 0


def cmap_for(path, index):
    if path.lower().endswith(".ttc"):
        coll = TTCollection(path)
        if index < 0 or index >= len(coll.fonts):
            raise SystemExit("font index out of range: %s#%d" % (path, index))
        font = coll.fonts[index]
    else:
        if index != 0:
            raise SystemExit("non-TTC font cannot use nonzero index: %s" % path)
        font = TTFont(path)
    out = set()
    for table in font["cmap"].tables:
        out.update(table.cmap.keys())
    return out


def is_wide(cp):
    return (0x3000 <= cp <= 0x30FF) or (0x4E00 <= cp <= 0x9FFF) or (0xFF00 <= cp <= 0xFFEF)


def render_record(font, ch, width):
    # Oversample, crop, then fit into the fixed Golden-compatible source cell.
    canvas = Image.new("L", (64, 64), 0)
    d = ImageDraw.Draw(canvas)
    try:
        bbox = d.textbbox((0, 0), ch, font=font)
    except Exception:
        bbox = None
    if not bbox:
        return bytes(RECORD_BYTES)
    x0, y0, x1, y1 = bbox
    if x1 <= x0 or y1 <= y0:
        return bytes(RECORD_BYTES)
    d.text((-x0 + 2, -y0 + 2), ch, fill=255, font=font)
    crop = canvas.crop(canvas.getbbox() or (0, 0, 1, 1))

    # Leave a small bearing where possible. CJK retains more horizontal pixels.
    max_w = width if width <= 2 else width - 1
    max_h = 15
    scale = min(float(max_w) / max(1, crop.width), float(max_h) / max(1, crop.height))
    new_w = max(1, min(max_w, int(round(crop.width * scale))))
    new_h = max(1, min(max_h, int(round(crop.height * scale))))
    crop = crop.resize((new_w, new_h), Image.Resampling.LANCZOS)

    cell = Image.new("L", (16, 16), 0)
    ox = max(0, (width - new_w) // 2)
    oy = max(0, (16 - new_h) // 2)
    cell.paste(crop, (ox, oy))

    out = bytearray()
    pix = cell.load()
    for y in range(16):
        bits = 0
        for x in range(16):
            if x < width and pix[x, y] >= 96:
                bits |= 1 << (15 - x)
        out.append((bits >> 8) & 0xFF)
        out.append(bits & 0xFF)
    return bytes(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--font", action="append", required=True,
                    help="font file; TTC subfont may be selected with #index")
    ap.add_argument("--out", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--pixel-size", type=int, default=24)
    args = ap.parse_args()

    specs = []
    for raw in args.font:
        path, index = parse_font_spec(raw)
        if not os.path.isfile(path):
            raise SystemExit("font not found: %s" % path)
        cmap = cmap_for(path, index)
        pil = ImageFont.truetype(path, args.pixel_size, index=index)
        specs.append({"raw": raw, "path": path, "index": index, "cmap": cmap, "pil": pil})

    codepoints = [cp for a, b in RANGES for cp in range(a, b + 1)]
    if len(codepoints) != EXPECTED_GLYPHS:
        raise SystemExit("internal range count mismatch")

    question_cp = 0x003F
    question_spec = next((s for s in specs if question_cp in s["cmap"]), None)
    if question_spec is None:
        raise SystemExit("no supplied font contains '?' fallback")

    out = bytearray()
    fallback_count = 0
    source_hits = [0] * len(specs)
    for cp in codepoints:
        width = 12 if is_wide(cp) else 8
        selected_index = None
        for i, s in enumerate(specs):
            if cp in s["cmap"]:
                selected_index = i
                break
        if selected_index is None:
            selected = question_spec
            ch = "?"
            fallback_count += 1
        else:
            selected = specs[selected_index]
            ch = chr(cp)
            source_hits[selected_index] += 1
        out.extend(render_record(selected["pil"], ch, width))

    if len(out) != EXPECTED_BYTES:
        raise SystemExit("output size mismatch: %d" % len(out))

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(out)
    out_sha = sha256_file(out_path)

    manifest = {
        "status": "RECONSTRUCTED-NOT-GOLDEN",
        "format": {
            "glyph_records": EXPECTED_GLYPHS,
            "record_bytes": RECORD_BYTES,
            "total_bytes": EXPECTED_BYTES,
            "rows": 16,
            "bits_per_row": 16,
            "row_endian": "big",
            "normal_source_width": 8,
            "wide_source_width": 12,
            "ranges": [[a, b] for a, b in RANGES],
        },
        "output": {"path": str(out_path), "sha256": out_sha, "bytes": len(out)},
        "golden_reference_sha256": GOLDEN_SHA256,
        "matches_exact_golden": out_sha == GOLDEN_SHA256,
        "fallback_records": fallback_count,
        "sources": [
            {
                "spec": s["raw"],
                "file_sha256": sha256_file(s["path"]),
                "selected_glyphs": source_hits[i],
            }
            for i, s in enumerate(specs)
        ],
    }
    Path(args.manifest).write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("VC7R_FONT_STATUS=RECONSTRUCTED-NOT-GOLDEN")
    print("VC7R_FONT_BYTES=%d" % len(out))
    print("VC7R_FONT_SHA256=%s" % out_sha)
    print("VC7R_FONT_FALLBACK_RECORDS=%d" % fallback_count)
    print("VC7R_EXACT_GOLDEN_MATCH=%s" % ("YES" if out_sha == GOLDEN_SHA256 else "NO"))


if __name__ == "__main__":
    main()
