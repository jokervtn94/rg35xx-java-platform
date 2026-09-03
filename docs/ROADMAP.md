# Platform 1.0 Roadmap

## Completed foundation

### Legacy/proven runtime foundation
- JamVM 2.0.0 + GNU Classpath 0.99 on uClibc
- headless AWT path
- PNG tRNS palette-alpha repair
- fixed 640x480 RGB565 frontend
- SMART-FIT aspect preservation
- RGB565 Java/native frame protocol
- dedicated native video receiver thread
- asynchronous audio worker/ring callback
- TinySoundFont/TinyMidiLoader MIDI backend
- native MIDI END_OF_MEDIA command
- direct numeric keypad compatibility

### Alpha 1
- RG35XXPlatformProfile
- RG35XXFrameScheduler
- dirty LCD generation hooks
- frame worker avoids serializing unchanged LCD generations

### Beta 1
- RG35XXImageCache: bounded immutable ARGB LRU
- RG35XXInputEngine: deterministic repeat semantics
- RG35XXWavDecoder: PCM/IMA ADPCM/A-law/mu-law -> PCM16
- RG35XXMediaProfile
- RG35XXRuntimeStats

## Beta 2 — Compatibility baseline + Unified Font Engine

Before changing font semantics, analyze the reference game JAR corpus for actual Font/Graphics API usage. Build a compatibility matrix covering Font.getFont/getDefaultFont, charWidth/charsWidth/stringWidth/substringWidth, getHeight/getBaselinePosition and Graphics drawString/drawSubstring/drawChars anchors.

Then implement one RG35XX font engine used by both measurement and rasterization so layout metrics cannot disagree with rendered glyph widths. Preserve Unicode/Vietnamese/CJK requirements while avoiding GNU Classpath OpenType hot paths on JamVM.

## Beta 3 — Media Engine 2.0

- make Manager capability reporting match codecs actually playable
- formal Player lifecycle/state registry
- distinguish BGM MIDI, MIDI SFX, PCM SFX and tone
- multiple native voices where justified by audited games
- retain native END_OF_MEDIA truth
- eliminate unnecessary SD staging where safe

## Beta 4 — Graphics Engine

Audit and optimize high-frequency J2ME operations used by the reference corpus:
- drawRGB/getRGB/createRGBImage
- drawRegion
- Sprite transforms
- clipping
- alpha blend
- direct int[] fast paths
- safe semantic fallback paths

Correct J2ME semantics take precedence over a game-specific hack.

## Beta 5 — Storage/RMS

Design an RG35XX-friendly RecordStore backend with compatibility first:
- RAM mirror/cache
- bounded/ordered asynchronous persistence if safe
- temporary file + atomic replacement strategy
- corruption recovery
- existing save compatibility/migration plan

## Release Candidate

No RC until:
- Tasklog complete
- class ownership audit complete
- removal register complete
- JAR API/package/resource matrix complete
- Java/native protocol audit complete
- static source audit complete
- build instructions reproducible
- test matrix prepared

Only at RC do we start the consolidated real-device test pass instead of asking for device builds after every small change.
