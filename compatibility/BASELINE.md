# Real-game Compatibility Baseline

## Purpose

Platform changes must be grounded in actual Java ME software behavior rather than only in synthetic assumptions. The project uses user-supplied game JARs as a private/local compatibility corpus.

Game binaries, copyrighted assets and extracted proprietary resources are not committed to this repository.

## What is recorded

For each reference JAR we may record only engineering metadata needed for compatibility work:

- MIDlet manifest/profile/configuration
- package/class inventory
- Java ME API references
- vendor API references
- Font/Graphics call inventory
- Canvas/GameCanvas/input behavior
- Sprite/TiledLayer APIs
- MMAPI Manager/Player/control APIs
- RMS APIs
- network APIs where relevant
- resource types and codec/container types
- screen geometry metadata
- cryptographic hash for identifying the exact local test binary
- observed runtime result once device testing begins

## Compatibility workflow

```text
reference JAR
  -> manifest/class/package/resource audit
  -> API usage matrix
  -> map API to platform implementation
  -> Task ID for any platform change
  -> static semantic audit
  -> consolidated RC build
  -> RG35XX device test
  -> regression mapped back to Task ID/symbol/rollback
```

## Known reference findings already established

### Vua Cướp Biển 240x320

Static inspection established that this particular JAR is MIDP 1.0 / CLDC 1.0 and does not contain an actual MMAPI/Nokia Sound audio implementation or common embedded audio assets. A resource named `music` observed in its classes is used as an image resource rather than proof of playable music. Therefore absence of audio in this binary must not be 'fixed' by inventing emulator audio behavior.

The game also contains explicit System.gc() calls, including transition/render-adjacent paths, and uses an approximately 50 ms game-loop target. Platform tuning must therefore distinguish game-originated stalls from runtime stalls.

### Image compatibility

A real game exposed indexed PNG tRNS transparency loss under GNU Classpath. The platform repairs palette alpha and treats that fix as a compatibility requirement.

### MIDI compatibility

Real-device testing has proven the native MIDI END_OF_MEDIA command path. Future Media Engine work must preserve this protocol unless an explicitly documented replacement is superior.

## Beta 2 matrix

The next audit expands this baseline into a per-JAR table for:

- Font.getDefaultFont / Font.getFont
- charWidth / charsWidth / stringWidth / substringWidth
- getHeight / getBaselinePosition
- Graphics.drawString / drawSubstring / drawChars
- anchor combinations
- Unicode/CJK/Vietnamese text evidence
- drawRGB / getRGB / drawRegion
- Sprite transforms
- Manager/Player/content types
- RecordStore patterns

The resulting matrix is the evidence base for RG35XXFontEngine and later Media/Graphics/RMS stages.
