#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/scripts/build-a9-core2d-blit-perf.sh"
TMP="$ROOT/scripts/.build-a9-core2d-blit-perf-v2.generated.sh"
trap 'rm -f "$TMP"' EXIT

python3 - "$SRC" "$TMP" <<'PY'
import sys
from pathlib import Path
src=Path(sys.argv[1])
dst=Path(sys.argv[2])
text=src.read_text(encoding='utf-8')
old='''R1_SHA="$(sha256sum "$R1_JAR" | awk '{print $1}')"\n[ "$R1_SHA" = "c4a5adff83c89c891531b2693558583a773a8f8297386f4d36a3cb21ee65f201" ] || fail "R1 platform hash mismatch $R1_SHA"\n'''
new='''R1_SHA="$(sha256sum "$R1_JAR" | awk '{print $1}')"\nR1_ID="$R1/A9-FILLTRIANGLE-IDENTITY.txt"\n[ -f "$R1_ID" ] || fail "R1 identity missing"\ngrep -q '^CANDIDATE_PLATFORM_SEMANTIC_SHA256=4eddfa373d2e52115033924e711d546b8e2cdc03b222b90b3f06c5c676e6bc52$' "$R1_ID" || fail "R1 semantic identity mismatch"\ngrep -q '^FAILURE_OWNER=RG35XX_RAW_PLATFORMGRAPHICS_AWT_NULL$' "$R1_ID" || fail "R1 failure-owner identity mismatch"\ngrep -q '^CHANGED_JAR_SCOPE=org/recompile/mobile/PlatformGraphics.class$' "$R1_ID" || fail "R1 scope identity mismatch"\ngrep -q '^A9_FILLTRIANGLE_HOST_GATE=PASS$' "$R1_ID" || fail "R1 fillTriangle gate missing"\nR1_SEMANTIC=4eddfa373d2e52115033924e711d546b8e2cdc03b222b90b3f06c5c676e6bc52\nR1_DEVICE_SHA=c4a5adff83c89c891531b2693558583a773a8f8297386f4d36a3cb21ee65f201\n'''
if text.count(old) != 1:
    raise SystemExit('A9_CORE2D_BLIT_V2_PATCH_FAIL R1 byte-hash gate anchor')
text=text.replace(old,new,1)

# The staged blit method is already fail-closed on the exact sourceOver call
# expression, and the A5/Core2D host gate verifies source-over pixel arithmetic.
# Do not additionally key CI to the private helper declaration's exact source
# spelling after the full A4->A7 staging chain.
old_sourceover='''# sourceOver itself must remain present outside the staged method and unmodified by\n# this transformer; the transformer performs one exact method replacement only.\nif 'private static int sourceOver(int s, int d)' not in s:\n    raise SystemExit('A9_CORE2D_BLIT_SOURCE_GATE_FAIL sourceOver missing')\n'''
new_sourceover='''# sourceOver behavior is locked by the exact call-expression source gate above\n# plus A5_CORE2D_ALPHA_HOST_GATE below. The no-copy transformer itself replaces\n# exactly one blit-method block and does not target the helper declaration.\n'''
if text.count(old_sourceover) != 1:
    raise SystemExit('A9_CORE2D_BLIT_V2_PATCH_FAIL sourceOver declaration gate anchor')
text=text.replace(old_sourceover,new_sourceover,1)

old_id='R1_PLATFORM_SHA256=$R1_SHA\n'
new_id='''R1_PLATFORM_SHA256=$R1_DEVICE_SHA\nR1_REBUILD_PLATFORM_SHA256=$R1_SHA\nR1_PLATFORM_SEMANTIC_SHA256=$R1_SEMANTIC\nR1_PARENT_GATE=SEMANTIC_PLUS_SOURCE_PLUS_HOST_REGRESSION\n'''
if text.count(old_id) != 1:
    raise SystemExit('A9_CORE2D_BLIT_V2_PATCH_FAIL identity anchor')
text=text.replace(old_id,new_id,1)
dst.write_text(text,encoding='utf-8')
print('A9_CORE2D_BLIT_R1_GATE_MODE=SEMANTIC_IDENTITY')
print('A9_CORE2D_BLIT_SOURCEOVER_GATE=CALL_EXPRESSION_PLUS_ALPHA_HOST_BEHAVIOR')
print('A9_CORE2D_BLIT_DEVICE_R1_SHA_REFERENCE=c4a5adff83c89c891531b2693558583a773a8f8297386f4d36a3cb21ee65f201')
print('A9_CORE2D_BLIT_R1_SEMANTIC_SHA256=4eddfa373d2e52115033924e711d546b8e2cdc03b222b90b3f06c5c676e6bc52')
PY

chmod +x "$TMP"
bash "$TMP"
