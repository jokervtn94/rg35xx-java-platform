# RG35XX R1 — God of War JAR audio structure / MMAPI lifecycle analysis

Date: 2026-10-05
Branch: `physical-test/rg35xx-r1-p6-p7-20261005`

## Status

```text
DIAGNOSTIC_ONLY=YES
RUNTIME_CHANGE=NO
GAME_JAR_REPACK=NO
P6_PHYSICAL_ACCEPTANCE=PASS
P7_PHYSICAL_REGRESSION=FAIL:GOW_AUDIBLE_AUDIO_CONTINUITY
DEVICE_PASS=NO
STABLE=NO
```

## Exact game input

```text
GAME=God-of-War-Betrayal_J2ME_EN_v148.jar
SHA256=e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98
MIDLET=GOWMIDlet
```

The commercial JAR was inspected in-place only. It was not modified, rebuilt, repacked, or committed.

## Game audio architecture

The JAR does not store its gameplay music as ordinary top-level `.mid` files. Audio data is embedded in Glu resource packs (`RP*`). `d.class` owns the media lifecycle and obtains bytes through the resource loader before constructing MMAPI players.

The relevant generic sequence in `d.class` is:

```text
resource bytes
-> optional MIDI transformation
-> Manager.createPlayer(ByteArrayInputStream, "audio/midi")
-> realize()
-> prefetch()

play request:
prefetch()
-> setMediaTime(0)
-> setLoopCount(...)
-> start()
```

Before another selected sound is started, the current started `Player` can be stopped through `Player.stop()`.

## Preloaded audio resources

`e.class` preloads the following three media slots:

```text
slot=0 resource=1063 loop=-1 priority=0
slot=1 resource=1064 loop=1  priority=0
slot=2 resource=1062 loop=1  priority=0
```

The game invokes these slots from game logic after preload; they are not dead/unreferenced data.

RP1 parsing maps resource IDs 1062/1063/1064 to indices 38/39/40. All three are valid MIDI resources with real note content.

```text
ID=1062
RAW_SIZE=161
RAW_SHA256=9fd75702de67aafbe9cb2fef20c8af93aa75887ba88c1e20a2b4fffd36b891d2
RAW_MIDI_DURATION_APPROX=0.225s
NOTE_ON_COUNT=10

ID=1063
RAW_SIZE=6274
RAW_SHA256=4852386b604ed3008cee0c8a6333a5e70fa23c5ebdc9f2705649d92f4d03e077
RAW_MIDI_DURATION_APPROX=28.0s
NOTE_ON_COUNT=867
TRACK_COUNT=11
GAME_LOOP_COUNT=-1
ROLE=LONG_LOOPING_MUSIC/BGM

ID=1064
RAW_SIZE=261
RAW_SHA256=00a8c729ce695ac6554a6d57134b8d6e63fa6662f41c45539c83f6dc98bdb9e1
RAW_MIDI_DURATION_APPROX=1.65s
NOTE_ON_COUNT=18
GAME_LOOP_COUNT=1
```

Therefore:

```text
GOW_AUDIO_EXISTS=YES
GOW_HAS_LONG_LOOPING_MIDI=YES
GOW_HAS_SHORT_MIDI_EVENTS=YES
```

## Game-side MIDI transformation

For the loop-count-1 assets, the private MIDI transformation in `d.class` changes the byte stream before `Manager.createPlayer(...)`.

Exact execution of that transformation shows:

```text
1064 RAW_SIZE=261 -> TRANSFORMED_SIZE=281
1062 RAW_SIZE=161 -> TRANSFORMED_SIZE=181
```

The transformed files retain their audible notes near the beginning, but gain an approximately 600-second MIDI timeline/silent tail. Thus a one-shot can be physically silent after roughly the first 0.1–1.2 seconds while the MIDI object remains logically active for a much longer time.

The looping resource 1063 (`loop=-1`) does not take this same loop-count-1 transformation path.

## Exact load mapping against R4 physical log

The protected `PlatformPlayer.sdlPlayer` writes media to an RMS-side `.mid` filename derived from the MD5 of the input buffer. The unusual `ffffffff...` text in the device log comes from signed-byte hex formatting; reducing it to the underlying 16 MD5 bytes maps the physical files exactly to the game resources.

```text
resource 1063 raw BGM
MD5=73b733dab3205c34663fff81849edd95
physical log path reduces to same MD5

resource 1064 transformed
MD5=8158c9a3e6b3a507bb16449170151b18
physical log path reduces to same MD5

resource 1062 transformed
MD5=fc268213e8386911bd2b9d3e59f2b93e
physical log path reduces to same MD5
```

The R4 exact-A7-platform A/B log records three successful MIDI loads and successful play calls for these same resource-derived files.

Therefore:

```text
WRONG_GAME_RESOURCE_LOAD=NO
EMPTY_GAME_AUDIO=NO
MMAPI_CONTENT_TYPE=audio/midi
MIDI_EXTRACTION_TO_PLATFORM=CORRECT
NATIVE_MIX_LOAD=PASS
```

`LOAD=PASS` / `PLAY=PASS` remain API/programmatic evidence only; they do not satisfy the protected physical audible gate.

## Platform lifecycle structure

The exact protected A7 platform and pinned Miyoo `PlatformPlayer` use the same important Java lifecycle shape for MIDI:

```text
sdlPlayer.start():
  sdlMixerResumeMusic()            // global music resume
  if (!isOpen || !sdlMixerIsPlaying())
      sdlMixerPlayMusic(thisHandle, loops)

sdlPlayer.stop():
  sdlMixerPauseMusic()             // global music pause
```

`sdlPlayer` does not override `setMediaTime`; the inherited `audioplayer.setMediaTime(long)` merely returns the requested value. Therefore the game's explicit `Player.setMediaTime(0)` does not actually rewind the backend MIDI object.

The RG35XX SDL1 adapter also has one global SDL_mixer music channel:

```text
sdlMixerPlayMusic(handle, loops):
  Mix_HaltMusic()
  currentMusic = handle
  Mix_PlayMusic(handle, loops)

sdlMixerPauseMusic(): Mix_PauseMusic()
sdlMixerResumeMusic(): Mix_ResumeMusic()
sdlMixerIsPlaying(): Mix_PlayingMusic()
```

All MIDI `PlatformPlayer` instances therefore share the same backend playing/paused state, while the game models them as independent MMAPI `Player` objects.

## Concrete collision exposed by this JAR

The game expects a sequence equivalent to:

```text
stop current Player
select another Player
setMediaTime(0)
setLoopCount(...)
start selected Player
```

The protected platform implements that on top of one global SDL_mixer music object state:

```text
stop Player A -> pause global music
start Player B -> resume global music first
               -> consult global Mix_PlayingMusic()
               -> may skip Mix_PlayMusic(B) when B.isOpen and global music reports playing
```

Because the one-shot transformed MIDI can remain logically active for roughly 600 seconds after its audible notes have ended, a globally "playing" state can coexist with physical silence.

This is consistent with the physical log pattern where several `midi loop: 1` Java requests are present but not every request is accompanied by a new `RG35XX_A7_AUDIO_MIDI_PLAY=PASS` native-play marker.

## Canonical comparison and owner classification

Pinned Miyoo uses essentially the same Java `PlatformPlayer` lifecycle and a single SDL_mixer music path, but its device backend is SDL2/SDL2_mixer. Original RG35XX adaptation uses SDL1.2/SDL_mixer 1.2.

Consequently the discovered issue must not be patched by game/resource ID. The legal owner candidate is the generic media lifecycle / SDL mixer boundary:

```text
FAILURE_OWNER_CANDIDATE=MMAPI_MIDI_PLAYER_LIFECYCLE__SDL_MIXER_MUSIC_STATE_BOUNDARY
GAME_SPECIFIC_FIX=FORBIDDEN
WRONG_RESOURCE_OWNER=ELIMINATED
MISSING_AUDIO_DATA_OWNER=ELIMINATED
AUDIO_PRIME_OWNER=ELIMINATED_BY_CURRENT_EVIDENCE
RUNTIME_PROCESS_BOUNDARY=NOT_YET_ELIMINATED
```

The exact-A7-platform-on-R4-runtime physical A/B still failed audible gameplay, so this document does **not** claim final sole-owner proof. The R4 candidate runtime/process environment remains a live variable.

## Next legal work unit

Before a production semantic change, build one generic multi-Player MMAPI lifecycle diagnostic that records requested player handle versus current SDL_mixer handle/state across:

```text
A start
A stop
B start
B stop
A restart
```

The diagnostic must use generic MIDI fixtures and must not contain God-of-War-specific code or resource IDs. It should distinguish:

1. requested handle owns current music and may be resumed;
2. requested handle differs from current music and must actually be selected/played;
3. paused vs playing backend state;
4. whether Java `start()` resulted in a native `Mix_PlayMusic` call.

Only after that evidence should the smallest generic RG35XX boundary delta be selected.
