#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${VC7_SOURCE:?set VC7_SOURCE to a completed VC6 assembly tree}"
: "${VC7_GOLDEN_FONT_BIN:?set VC7_GOLDEN_FONT_BIN to verified rg35xx-font.bin}"

fail() { echo "VC7 FONT PREFLIGHT FAIL: $*" >&2; exit 1; }
note() { echo "VC7 FONT PREFLIGHT: $*"; }

PG="$VC7_SOURCE/src/org/recompile/mobile/PlatformGraphics.java"
PI="$VC7_SOURCE/src/org/recompile/mobile/PlatformImage.java"
[ -f "$PG" ] || fail "PlatformGraphics.java missing"
[ -f "$PI" ] || fail "PlatformImage.java missing"
[ -f "$VC7_GOLDEN_FONT_BIN" ] || fail "Golden font input missing"

FONT_SIZE=$(wc -c < "$VC7_GOLDEN_FONT_BIN" | tr -d ' ')
FONT_SHA=$(sha256sum "$VC7_GOLDEN_FONT_BIN" | awk '{print $1}')
[ "$FONT_SIZE" = 727008 ] || fail "Golden font size mismatch: $FONT_SIZE"
[ "$FONT_SHA" = 7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c ] || fail "Golden font SHA mismatch: $FONT_SHA"

# VC6 must already be present. VC7 is layered on it rather than rebuilding a
# different foundation.
grep -Fq 'rg35xxPngIccpCompat' "$PI" || fail "VC6 PNG compatibility missing"
grep -Fq 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk' "$PI" || fail "VC6 PNG marker missing"

# Pin the upstream text boundary that device evidence identified. The normal
# path must still be GNU AWT before the VC7 overlay is applied, otherwise this
# script refuses to guess a patch location.
grep -Fq 'private void drawStringSingleLine(String str, int x, int y, int anchor)' "$PG" || fail "drawStringSingleLine anchor missing"
grep -Fq 'gc.drawString(str, x, y);' "$PG" || fail "expected AWT text boundary missing"
grep -Fq 'x = AnchorX(x, font.stringWidth(str), anchor);' "$PG" || fail "MIDP anchor baseline changed"
grep -Fq 'x = AnchorX(x, dojaFont.stringWidth(str), anchor);' "$PG" || fail "DoJa anchor baseline changed"

# Rejected alternatives must not already be the active normal path.
! grep -Fq 'RG35XXBitmapText.draw' "$PG" || fail "later bitmap fallback already wired into PlatformGraphics"
! grep -R -Fq 'RG35XX-CV:' "$VC7_SOURCE/src" || fail "CV/CW experiment present"
! grep -R -Fq 'RG35XX-MediaWarmup' "$VC7_SOURCE/src" || fail "media warmup regression present"

note "PASS"
note "VC6 source boundary verified"
note "Golden font size=$FONT_SIZE sha256=$FONT_SHA"
note "PlatformGraphics AWT text boundary is ready for a fail-closed VC7 overlay"
