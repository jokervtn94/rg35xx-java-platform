# RC1 GNU Classpath font overlay

This directory owns only the deterministic assembly logic for the target GNU Classpath 0.99 tree. It does not fork `java.awt.Font` and does not resurrect `RG35XXFontEngine`.

`apply_rg35xx_font_overlay.sh` operates on a disposable Classpath 0.99 source tree after `scripts/rc1_classpath_preflight.sh` has validated the external inputs. It installs the materialized DejaVuSans.ttf under a deterministic target-owned path and rewrites the two font-peer entry points in `HeadlessToolkit.java` only after proving that the expected null-returning 0.99 baseline is present.

The overlay intentionally reuses GNU Classpath `OpenTypeFontPeer`; logical SansSerif/Dialog/Monospaced names all map to the single pinned DejaVu Sans RC1 resource. Peer instances are cached by logical name/style/attribute map. If the source shape or font resource differs, assembly stops instead of guessing.

Runtime success still requires the JamVM Font.hashCode/createGlyphVector/FontMetrics smoke probes and target game corpus.