# CK device diagnosis — font metrics + MMAPI

Device evidence from the comprehensive test identifies three concrete runtime defects.

## Font / apparent screen overflow

The recovered Golden Unicode bitmap renderer uses a fixed 8-pixel Latin advance and 16-row raster while MIDP `Font` reports the test sample as `101x14`. This makes paint geometry wider/taller than layout geometry, which explains the visible overlap at the footer and clipped/stacked text. The 640x480 native Smart-Fit itself is not the primary defect: the core reports source 240x320 -> 360x480 centered at x=140.

CK correction: preserve the Golden Unicode glyph resource/range table, but scale each glyph into `Font.charWidth(c)` x `Font.getHeight()` and use `Font.stringWidth()` for anchor geometry. Rendering must still obey translation, current clip, canvas bounds, and opaque ARGB.

## Manager.playTone

Device stack trace shows `NullPointerException` at `javax.microedition.media.Manager.playTone`. In the pinned FreeJ2ME implementation this occurs when `toneChannel` is null on JamVM/headless JavaSound. CK routes `playTone` through a short generated MIDI Player so the existing native MIDI bridge owns playback.

## ToneControl

Pinned `PlatformPlayer.toneControl.setupSequence` incorrectly expects byte 0 to equal literal `1`. JSR-135 sequence framing is `ToneControl.VERSION (-2), version-number (1), ...`. CK accepts `-2,1` and begins parsing events at index 2.

## PCM WAV

WAV starts and native PCM is loaded, but device evidence shows an underrun/re-prime and no `END_OF_MEDIA` before the test leaves the page. This remains a native lifecycle/cadence item after CK verifies font, playTone and ToneControl. Do not hide this as PASS until device evidence receives `endOfMedia` for PCM.
