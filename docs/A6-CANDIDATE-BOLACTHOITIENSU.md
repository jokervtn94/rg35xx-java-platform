# A6 candidate inventory — Bolacthoitiensu mod

Date: 2026-09-23
Stage: A6 REAL_GAME_REGRESSION candidate evaluation
Production baseline: `ffff492c0f2f0ccc1e0c1548addcec99c73fff09`

## Binary identity

File: `Bolacthoitiensu_mod_by_thaimeow_320x240_fix.jar`
SHA256: `5091f23baab29a420edb677c9fdc4f0e24c299f26b0656eaf8a601366d3d1f74`
Size: `482460` bytes

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
- Player.getControl("VolumeControl")
- VolumeControl.setLevel

The music bytes are sourced from packed in-memory data rather than a normal `.mid` file entry.

Media calls are wrapped in Java Exception handlers, but Media still remains outside the current A6 acceptance scope.

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

## A6 decision

`A6_CANDIDATE_BOLACTHOITIENSU=CONDITIONAL_FALLBACK`

This candidate is substantially cleaner than NinjaSchool1 because it avoids SMS, network transport, Bluetooth and device-ID activation dependencies. It provides useful real-game coverage for 320x240 landscape rendering, Canvas/input, image/drawRegion/text and RMS.

However it still actively invokes J2ME Media. Therefore:
- it is not a clean first-choice non-audio acceptance corpus;
- it may be used as a fallback A6 core regression title only if audio/media behavior is explicitly excluded from the verdict;
- a Media-related failure must not be counted as an A6 non-audio core failure;
- if another user-owned JAR with comparable Graphics/RMS coverage and no Media/activation dependency is available, that cleaner JAR should be preferred for first A6 acceptance.

Current project locks remain:
`AUDIO=HOLD`
`MEDIA=HOLD`
`A6_REAL_GAME_REGRESSION=PENDING`
