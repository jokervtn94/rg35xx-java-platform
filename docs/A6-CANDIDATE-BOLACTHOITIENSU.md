# A6 candidate inventory — Bolacthoitiensu mod

Date: 2026-09-24
Stage: A6 REAL_GAME_REGRESSION candidate evaluation
Production baseline: `ffff492c0f2f0ccc1e0c1548addcec99c73fff09`

## Binary identity

File: `Bolacthoitiensu_mod_by_thaimeow_320x240_fix.jar`
SHA256: `5091f23baab29a420edb677c9fdc4f0e24c299f26b0656eaf8a601366d3d1f74`
Size: `482460` bytes

The previously recorded 65-character SHA256 was incorrect because it contained one extra hexadecimal `7`. The 64-character value above was verified directly from the user-owned 482460-byte JAR and is the canonical identity for this corpus.

Manifest:
- MIDlet-Name: `Bolacthoitiensu_mod_by_thaimeow`
- MIDlet-1 entry class: `Class6`
- MIDlet-Version: `1.0.1`
- MicroEdition-Configuration: `CLDC-1.1`
- MicroEdition-Profile: `MIDP-2.1`
- ScreenWidth: `320`
- ScreenHeight: `240`
- Nokia original display size: `320 240,240 320`
- Nokia orientation: `landscape`

Archive inventory:
- 7 class files
- all class major versions = 47
- 33 non-class entries
- 1 PNG resource
- 25 extensionless resources

## Non-audio core coverage

Confirmed bytecode calls include:
- Canvas: getGameAction, repaint, setFullScreenMode, sizeChanged
- Display: getDisplay, setCurrent
- Font: getFont, getHeight, stringWidth
- Graphics: drawImage, drawLine, drawRect, drawRegion, drawString, fillRect, clip getters, setClip, setColor, setFont
- Image: createImage, getGraphics
- RMS: RecordStore open/add/get/getNumRecords/close/delete

No Sprite/TiledLayer dependency was found.

## Media inventory

The JAR has an active media implementation, not only dead strings. Class `a` constructs a Player through:
- `javax.microedition.media.Manager.createPlayer(InputStream, "audio/midi")`
- Player.realize
- Player.addPlayerListener
- Player.prefetch
- Player.start
- Player.stop
- Player.close
- Player.setMediaTime
- Player.getControl("VolumeControl")`
- VolumeControl.setLevel

The music bytes are sourced from packed in-memory data rather than a normal `.mid` file entry.

## Network / activation / vendor risk inventory

Not found in class references:
- `javax.microedition.io.Connector`
- HttpConnection / SocketConnection
- `javax.wireless.messaging`
- MessageConnection / TextMessage
- Bluetooth
- Nokia IMEI/device identity APIs

One `MIDlet.platformRequest` path exists and the JAR contains the literal:
`https://www.facebook.com/hoangmanhthai.2302`
This appears to be an external-link path, not an in-game network transport API.

## Original-RG35XX PERF-A1-base device evidence — 2026-09-24

Package stage:
`A6-CORPUS2-BOLACTHOITIENSU-A1BASE-LANDSCAPE`

Installer:
- corrected canonical game SHA256: PASS;
- JamVM/glibj protected hashes: PASS;
- runtime Java/input/video hashes: exact PERF-A1 base.

Runtime reached:
- MIDlet creation/start;
- 320x240 Canvas creation;
- expected PERF-A1 geometry fallback marker:
  `RG35XX_PERF_A1_ASYNC=GEOMETRY_CHANGE_FALLBACK_P3 SOURCE=320x240`;
- RMS `t0`, `t1`, `t2` open/close paths.

The first meaningful runtime failure was:

```text
Exception in thread "Thread-2" java.lang.NoClassDefFoundError: java/nio/file/Paths
   at org.recompile.mobile.PlatformPlayer$sdlPlayer.<init>(PlatformPlayer.java:276)
   at org.recompile.mobile.PlatformPlayer.<init>(PlatformPlayer.java:97)
   at javax.microedition.media.Manager.createPlayer(Manager.java:37)
   at a.<init>(Unknown Source)
   at f.F(Unknown Source)
   at f.v(Unknown Source)
   at f.run(Unknown Source)
```

Cause:
- the game enters active MMAPI MIDI during its startup/game thread;
- the current PlatformPlayer path references `java.nio.file.Paths`;
- the RG35XX Java-6-era JamVM/glibj runtime does not provide that Java 7 NIO class.

There was no evidence of a preceding render/input/RMS core exception. However the Media exception kills the game thread before the constrained A6 path can complete basic gameplay/input/normal-exit acceptance.

## A6 decision

`A6_CANDIDATE_BOLACTHOITIENSU=BLOCKED_BY_MEDIA_OUT_OF_SCOPE`

Classification:
- `CORE_REGRESSION=NOT_PROVEN`
- `DEVICE_PASS=NO`
- `MEDIA_BLOCKER=JAVA_NIO_FILE_PATHS_FROM_PLATFORMPLAYER`
- `AUDIO=HOLD`
- `MEDIA=HOLD`

This title must not be used as the next A6 acceptance corpus unless Media is deliberately brought into scope in a later phase. A Media compatibility patch must not be introduced merely to make this A6 non-audio regression title run.

Next corpus requirement:
- user-owned JAR;
- preferably 240x320 so PERF-A1 async can be cross-game validated;
- Canvas/Graphics/Image/Input/RMS coverage;
- no active MMAPI Media dependency in startup/gameplay path;
- no SMS/payment/network/device-ID activation dependency in the constrained test path.

`BUILD-PASS != DEVICE-PASS != STABLE`.
