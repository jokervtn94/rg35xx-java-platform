package org.recompile.mobile;

/**
 * RG35XX Java Platform 1.0 - bounded MIDP Sprite transform map cache.
 *
 * The eight MIDP Sprite transforms are geometry-only.  This class caches the
 * destination-to-source coordinate maps for repeated sprite dimensions so the
 * ARM926 render path does not recompute transform arithmetic for every pixel.
 *
 * Java 6 compatible; no java.util.concurrent dependency.
 */
public final class RG35XXTransformCache {
    private static final int MAX_ENTRIES = 24;
    private static final Entry[] entries = new Entry[MAX_ENTRIES];
    private static long stamp;

    private RG35XXTransformCache() {}

    public static synchronized Map get(int width, int height, int transform) {
        if (width <= 0 || height <= 0 || transform < 0 || transform > 7) {
            throw new IllegalArgumentException("invalid transform geometry");
        }

        int free = -1;
        int oldest = 0;
        long oldestStamp = Long.MAX_VALUE;
        for (int i = 0; i < entries.length; i++) {
            Entry e = entries[i];
            if (e == null) {
                if (free < 0) free = i;
                continue;
            }
            if (e.width == width && e.height == height && e.transform == transform) {
                e.stamp = ++stamp;
                return e.map;
            }
            if (e.stamp < oldestStamp) {
                oldestStamp = e.stamp;
                oldest = i;
            }
        }

        Map map = build(width, height, transform);
        int slot = free >= 0 ? free : oldest;
        entries[slot] = new Entry(width, height, transform, map, ++stamp);
        return map;
    }

    public static synchronized void reset() {
        for (int i = 0; i < entries.length; i++) entries[i] = null;
        stamp = 0;
    }

    private static Map build(int w, int h, int t) {
        final boolean swap = (t == 4 || t == 5 || t == 6 || t == 7);
        final int dw = swap ? h : w;
        final int dh = swap ? w : h;
        final int count = dw * dh;
        final int[] sourceIndex = new int[count];

        int p = 0;
        for (int y = 0; y < dh; y++) {
            for (int x = 0; x < dw; x++) {
                int sx;
                int sy;
                switch (t) {
                    case 0: // TRANS_NONE
                        sx = x; sy = y; break;
                    case 1: // TRANS_MIRROR_ROT180
                        sx = x; sy = h - 1 - y; break;
                    case 2: // TRANS_MIRROR
                        sx = w - 1 - x; sy = y; break;
                    case 3: // TRANS_ROT180
                        sx = w - 1 - x; sy = h - 1 - y; break;
                    case 4: // TRANS_MIRROR_ROT270
                        sx = y; sy = x; break;
                    case 5: // TRANS_ROT90
                        sx = y; sy = h - 1 - x; break;
                    case 6: // TRANS_ROT270
                        sx = w - 1 - y; sy = x; break;
                    case 7: // TRANS_MIRROR_ROT90
                        sx = w - 1 - y; sy = h - 1 - x; break;
                    default:
                        throw new IllegalArgumentException("transform");
                }
                sourceIndex[p++] = sy * w + sx;
            }
        }
        return new Map(dw, dh, sourceIndex);
    }

    public static final class Map {
        public final int width;
        public final int height;
        public final int[] sourceIndex;

        private Map(int width, int height, int[] sourceIndex) {
            this.width = width;
            this.height = height;
            this.sourceIndex = sourceIndex;
        }
    }

    private static final class Entry {
        final int width;
        final int height;
        final int transform;
        final Map map;
        long stamp;

        Entry(int width, int height, int transform, Map map, long stamp) {
            this.width = width;
            this.height = height;
            this.transform = transform;
            this.map = map;
            this.stamp = stamp;
        }
    }
}
