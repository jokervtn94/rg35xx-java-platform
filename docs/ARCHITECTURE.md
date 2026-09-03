# Architecture

## Runtime stack

```text
J2ME Game
   |
   +-- LCDUI / GameCanvas / Sprite / RMS / MMAPI
   |
FreeJ2ME compatibility layer
   |
RG35XX platform services
   +-- RG35XXPlatformProfile
   +-- RG35XXFrameScheduler
   +-- RG35XXImageCache
   +-- RG35XXInputEngine
   +-- RG35XXWavDecoder
   +-- RG35XXMediaProfile
   +-- RG35XXRuntimeStats
   |
Java/native IPC
   +-- video: RGB565
   +-- commands/input
   +-- media commands
   |
libretro native core
   +-- video receiver pthread / double buffer
   +-- SMART-FIT 640x480 presentation
   +-- async MIDI/PCM worker
   +-- audio ring + libretro audio callback
   |
RetroArch / GarlicOS 1.x / RG35XX Original
```

## Runtime target

The target is the original RG35XX, not the later H700-based RG35XX family. The runtime/toolchain assumptions are ARM32 EABI5, uClibc and soft-float. The native FreeJ2ME core is built for the GarlicOS-era userspace rather than modern glibc.

JamVM is launched by absolute path because FAT32 deployment cannot preserve the Java symlink layout reliably. GNU Classpath native JNI libraries that normally depend on unversioned symlinks must exist as physical files on the SD deployment.

## Video

The frontend geometry remains 640x480 RGB565. Game LCD geometry is not pushed dynamically into RetroArch. SMART-FIT scales the source while preserving aspect ratio, never cropping or stretching. Java/native frame payload is RGB565 to reduce pipe bandwidth.

The architecture deliberately separates frontend presentation rate from fresh Java frame production. Native presentation can re-present the last complete canvas while Java only serializes a new LCD generation when the game actually flushes a changed frame.

## Graphics compatibility retained

GNU Classpath 0.99 image decoding has known differences from phone JVM implementations. Indexed PNG palette transparency is repaired from PNG tRNS data before the image reaches the game renderer. This behavior is considered a compatibility requirement and must not be removed without replacing the decoder path.

## Audio

Audio must not be coupled to retro_run(). A native worker owns MIDI synthesis/PCM processing and feeds an audio ring consumed by the libretro asynchronous audio callback. The proven native END_OF_MEDIA notification path is retained.

Manager.prepareMediaEngine() is intentionally skipped on the libretro target because the old JavaSound/MIDI initialization path is incompatible with this GNU Classpath/JamVM environment.

Beta 1 introduces a WAV normalization layer supporting PCM 8/16-bit, Microsoft IMA ADPCM, G.711 A-law and G.711 mu-law, producing signed PCM16 little-endian for the native bridge.

## Input

Native input transports logical FreeJ2ME key indices. Vendor/mobile profile translation remains a Java ME compatibility concern. Numeric keypad keys use direct standard J2ME numeric codes where required. Beta 1 replaces release-triggered global repeat scanning with a deterministic press/release/repeat engine.

## Logging and IPC

Java stdout is binary protocol transport and must never be redirected at the OS/native layer. Java keeps the original stdout as ipcOut. Ordinary diagnostic output must not contaminate it. Hot-path SD logging is disabled/minimized because SD writes materially affect frame timing.

## Ownership rule

RG35XX-specific policies belong in dedicated RG35XX classes. `Libretro.java` should converge toward IPC/transport responsibilities; `PlatformPlayer.java` should converge toward MMAPI facade/state responsibilities. New platform subsystems should not be embedded into these large integration classes without a documented reason.
