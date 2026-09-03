#!/bin/sh
set -eu

# RGJ-RC1-011L: fail-closed preflight for the concrete GNU Classpath/font input.
: "${RG35XX_CLASSPATH_ROOT:?set RG35XX_CLASSPATH_ROOT to extracted GNU Classpath 0.99 source}"
: "${RG35XX_FONT_FILE:?set RG35XX_FONT_FILE to materialized DejaVuSans.ttf}"

fail() { echo "RC1 CLASSPATH PREFLIGHT: FAIL: $*" >&2; exit 1; }
note() { echo "RC1 CLASSPATH PREFLIGHT: $*"; }

HT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/peer/headless/HeadlessToolkit.java"
OT="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/OpenTypeFontPeer.java"
FD="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/FontDelegate.java"
FF="$RG35XX_CLASSPATH_ROOT/gnu/java/awt/font/FontFactory.java"

[ -f "$HT" ] || fail "missing HeadlessToolkit.java"
[ -f "$OT" ] || fail "missing OpenTypeFontPeer.java"
[ -f "$FD" ] || fail "missing FontDelegate.java"
[ -f "$FF" ] || fail "missing FontFactory.java"
[ -s "$RG35XX_FONT_FILE" ] || fail "font file missing/empty"

# Official GNU Classpath 0.99 release identity is checked at acquisition time by tarball SHA-256.
# The source tree itself must expose the existing OpenType/FontDelegate path; do not invent a second renderer.
grep -q 'getFontPeer' "$HT" || fail "HeadlessToolkit has no getFontPeer entry"
grep -q 'ClasspathFontPeer' "$HT" || fail "HeadlessToolkit has no ClasspathFontPeer entry"
grep -q 'class OpenTypeFontPeer' "$OT" || fail "unexpected OpenTypeFontPeer source"
grep -q 'FontDelegate' "$OT" || fail "OpenTypeFontPeer is not backed by FontDelegate"

# Record the concrete TTF identity used by the build. The authoritative value is the materialized file,
# not a guessed hash embedded in project policy.
if command -v sha256sum >/dev/null 2>&1; then
  FONT_SHA=$(sha256sum "$RG35XX_FONT_FILE" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  FONT_SHA=$(shasum -a 256 "$RG35XX_FONT_FILE" | awk '{print $1}')
else
  fail "no SHA-256 utility available"
fi
[ ${#FONT_SHA} -eq 64 ] || fail "invalid font SHA-256"

note "Classpath source structure PASS"
note "DejaVuSans.ttf SHA256=$FONT_SHA"
note "This gate does not claim FontPeer runtime success; JamVM smoke probes remain mandatory."
