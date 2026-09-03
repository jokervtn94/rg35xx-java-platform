# RG35XX Java Platform — JAR Compatibility Matrix

Generated from the private/local reference JAR corpus. No game code or assets are reproduced here.

## Reference corpus

The current Beta 2 corpus contains six user-supplied Java ME titles: Zombie Infection, Asphalt 4 Elite Racing, Diamond Rush, God of War Betrayal, Prince of Persia The Two Thrones, and Vua Cướp Biển. Exact local binaries are tracked by SHA-256 in the private audit output; the JAR binaries themselves are excluded by repository policy.

## Audit dimensions

Each class constant pool and JAR resource inventory is scanned for the platform-relevant surface below:

- `javax.microedition.lcdui.Font`: getDefaultFont, getFont, charWidth, charsWidth, stringWidth, substringWidth, getHeight, getBaselinePosition
- Graphics text: drawString, drawSubstring, drawChars
- Graphics/image: drawRGB, getRGB, drawRegion, setClip, clipRect, drawImage, createRGBImage
- Game API: GameCanvas, Sprite, TiledLayer
- Media: Manager, Player, createPlayer, supported content types, VolumeControl, ToneControl
- RMS: RecordStore open/add/set/get/delete patterns
- vendor packages: Nokia, Samsung, Motorola, Siemens references
- resource extensions/container evidence

## Platform conclusions from the six-JAR baseline

1. **Font measurement and text rasterization must be one subsystem.** Beta 2 will not patch only `PlatformGraphics.drawString()`. `Font` measurement APIs and Graphics text APIs must consume the same RG35XX metric source.
2. **Graphics fast paths require semantic fallbacks.** The corpus combines image, RGB, clipping and game-layer APIs differently; one game-specific rendering shortcut cannot become the global behavior.
3. **Media capability truth must be conservative.** Manager/Player capability reporting must correspond to codecs the RG35XX backend really decodes and plays, rather than desktop JavaSound capabilities.
4. **RMS semantics come before SD optimization.** RecordStore behavior observed in games is the contract; asynchronous persistence is only acceptable if ordering and durability semantics remain compatible.
5. **Vendor packages stay in the compatibility layer.** A vendor API reference is evidence for an adapter, not justification for hard-coding game-specific input/render behavior.

## Beta 2 Font regression surface

The Unified Font Engine must provide a single source for:

```text
Font.getDefaultFont()
Font.getFont(...)
Font.charWidth(...)
Font.charsWidth(...)
Font.stringWidth(...)
Font.substringWidth(...)
Font.getHeight()
Font.getBaselinePosition()

Graphics.drawString(...)
Graphics.drawSubstring(...)
Graphics.drawChars(...)
```

Text anchors, clipping, baseline, style/size selection, Unicode lookup and rendered advance must be tested as a matched system.

## Corpus policy

Game JARs remain private/local compatibility inputs. Repository commits may contain hashes, API inventories, counts and engineering conclusions, but not proprietary game bytecode or extracted game assets.
