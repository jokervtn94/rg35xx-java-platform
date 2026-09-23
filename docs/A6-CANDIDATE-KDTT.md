# A6 Candidate — KDTT Tam Quoc Chi 320x240

File: `KDTT-Tam_Quoc_Chi_320x240_vh_by_zeplaovn.jar`
SHA256: `5586089f41bdfe87b139bbe7e3ef5cb362cd691775559d0f6605ce8d2b9c6d07`
Size: `1092360` bytes
MIDlet-Name: `口袋神兽三国志`
MIDlet-Vendor: `BlackPearl`
MIDlet-Version: `1.3.48`
MIDP: `2.0`
CLDC: `1.0`
Classes: `89`
Non-class resources: `125`
Class major versions: `45` (82 classes), `48` (7 classes)

Resource inventory:
- `.m`: 53
- `.png`: 35
- `.pak`: 19
- `.dat`: 10
- `.mid`: 6
- `.ini`: 2

## Core coverage

Graphics/Image/Font coverage includes:
- drawImage
- drawRegion
- drawString
- setClip
- clipRect
- fillRect
- drawLine
- drawRect
- setColor
- createImage
- getGraphics
- getFont
- getHeight
- stringWidth
- charWidth

Game API:
- `javax.microedition.lcdui.game.GameCanvas`

RMS coverage includes:
- openRecordStore
- addRecord
- setRecord
- getRecord
- getNumRecords
- deleteRecordStore
- closeRecordStore

## Out-of-scope dependencies confirmed by bytecode

### Media
The game has active MMAPI calls:
- `Manager.createPlayer(InputStream, "audio/midi")`
- `Player.prefetch`
- `Player.start`
- `Player.stop`
- `Player.deallocate`
- `Player.close`
- `Player.setLoopCount`
- `getControl("VolumeControl")`
- `VolumeControl.setLevel`

The JAR also contains 6 MIDI resources.

### HTTP / payment
Manifest contains:
`MIDlet-Install-Notify: http://59.42.254.3:8081/pay/install.do?...`

Bytecode contains active HTTP transport using:
- `javax.microedition.io.Connector.open`
- `javax.microedition.io.HttpConnection`
- setRequestMethod / setRequestProperty
- openOutputStream / openInputStream
- getResponseCode

Payment endpoints include:
- `http://59.42.254.3:8081/pay/largecharge.do`
- `http://59.42.254.3:8081/pay/largecheck.do`

### SMS / cracked-mod nuance
Bytecode still constructs SMS-related objects and calls:
- `javax.wireless.messaging.MessageConnection`
- `javax.wireless.messaging.TextMessage`
- `TextMessage.setAddress`
- `TextMessage.setPayloadText`

However the inspected modded bytecode does not contain a `MessageConnection.send` invocation in the SMS method. Instead it contains the diagnostic string `hardtodie cracked`, indicating that the send action was patched/bypassed in this modified build.

This does NOT make the title clean for A6 because SMS object construction and the HTTP/WapPay payment stack remain present and may execute depending on runtime path.

## A6 decision

`A6_CANDIDATE_KDTT=REJECTED_OUT_OF_SCOPE`

Reason: this title combines the desired Graphics/GameCanvas/RMS path with active MMAPI media and active HTTP payment/activation logic. It is therefore unsuitable as the first A6 non-audio core gate because failures would be ambiguous across boundaries that remain HOLD.

It may be retained as a later compatibility corpus for Media + network/payment/SMS-mod behavior after those boundaries are intentionally opened.

AUDIO=HOLD
MEDIA=HOLD
A6_REAL_GAME_REGRESSION=PENDING
