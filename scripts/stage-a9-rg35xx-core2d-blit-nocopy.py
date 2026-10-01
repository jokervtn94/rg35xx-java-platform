#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-a9-rg35xx-core2d-blit-nocopy.py <repo-root>")

root = Path(sys.argv[1]).resolve()
src = root / "adapter/java/org/recompile/rg35xx/RG35XXCore2D.java"
if not src.is_file():
    raise SystemExit("A9_CORE2D_BLIT_STAGE_FAIL source missing: %s" % src)

text = src.read_text(encoding="utf-8")
old = '''    /** Source-over ARGB blit with clipping and an optional MIDP transform. */
    public static void blit(int[] dst, int dstWidth, int dstHeight,
                            int[] src, int srcWidth, int srcHeight,
                            int srcX, int srcY, int width, int height, int transform,
                            int dstX, int dstY,
                            int clipX, int clipY, int clipWidth, int clipHeight) {
        RawImage r = transform == 0
                ? subRaw(src, srcWidth, srcHeight, srcX, srcY, width, height)
                : transform(src, srcWidth, srcHeight, srcX, srcY, width, height, transform);
        int left = Math.max(dstX, Math.max(clipX, 0));
        int top = Math.max(dstY, Math.max(clipY, 0));
        int right = Math.min(dstX + r.width, Math.min(clipX + clipWidth, dstWidth));
        int bottom = Math.min(dstY + r.height, Math.min(clipY + clipHeight, dstHeight));
        if (right <= left || bottom <= top) return;
        for (int y = top; y < bottom; y++) {
            int sy = y - dstY;
            int di = y * dstWidth + left;
            int si = sy * r.width + (left - dstX);
            for (int x = left; x < right; x++, di++, si++) {
                dst[di] = sourceOver(r.pixels[si], dst[di]);
            }
        }
    }
'''
new = '''    /** Source-over ARGB blit with clipping and an optional MIDP transform. */
    public static void blit(int[] dst, int dstWidth, int dstHeight,
                            int[] src, int srcWidth, int srcHeight,
                            int srcX, int srcY, int width, int height, int transform,
                            int dstX, int dstY,
                            int clipX, int clipY, int clipWidth, int clipHeight) {
        // A9 performance evidence: the game/render thread saturates one CPU core.
        // The accepted A5 transform==0 path allocated and copied width*height pixels
        // into a temporary RawImage for every ordinary sprite/image blit. Preserve
        // the exact source-over/clip semantics but read the requested source window
        // directly. Non-zero MIDP transforms stay on the accepted transform path.
        if (transform == 0) {
            if (srcX < 0 || srcY < 0 || width < 0 || height < 0 ||
                srcX + width > srcWidth || srcY + height > srcHeight) {
                throw new IllegalArgumentException("subimage bounds");
            }
            int left = Math.max(dstX, Math.max(clipX, 0));
            int top = Math.max(dstY, Math.max(clipY, 0));
            int right = Math.min(dstX + width, Math.min(clipX + clipWidth, dstWidth));
            int bottom = Math.min(dstY + height, Math.min(clipY + clipHeight, dstHeight));
            if (right <= left || bottom <= top) return;
            for (int y = top; y < bottom; y++) {
                int sy = srcY + (y - dstY);
                int di = y * dstWidth + left;
                int si = sy * srcWidth + srcX + (left - dstX);
                for (int x = left; x < right; x++, di++, si++) {
                    dst[di] = sourceOver(src[si], dst[di]);
                }
            }
            return;
        }

        RawImage r = transform(src, srcWidth, srcHeight, srcX, srcY, width, height, transform);
        int left = Math.max(dstX, Math.max(clipX, 0));
        int top = Math.max(dstY, Math.max(clipY, 0));
        int right = Math.min(dstX + r.width, Math.min(clipX + clipWidth, dstWidth));
        int bottom = Math.min(dstY + r.height, Math.min(clipY + clipHeight, dstHeight));
        if (right <= left || bottom <= top) return;
        for (int y = top; y < bottom; y++) {
            int sy = y - dstY;
            int di = y * dstWidth + left;
            int si = sy * r.width + (left - dstX);
            for (int x = left; x < right; x++, di++, si++) {
                dst[di] = sourceOver(r.pixels[si], dst[di]);
            }
        }
    }
'''

count = text.count(old)
if count != 1:
    raise SystemExit("A9_CORE2D_BLIT_STAGE_FAIL blit anchor count=%d" % count)
text = text.replace(old, new, 1)
src.write_text(text, encoding="utf-8")
print("A9_CORE2D_BLIT_STAGE=PASS")
print("A9_CORE2D_BLIT_TRANSFORM0_TEMP_COPY=REMOVED")
print("A9_CORE2D_BLIT_TRANSFORMED_PATH=UNCHANGED")
