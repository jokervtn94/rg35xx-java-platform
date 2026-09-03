# Class Registry

| Class/File | Ownership | Introduced | Status | Responsibility | Must not absorb |
|---|---|---|---|---|---|
| RG35XXPlatformProfile | Platform | Alpha 1 | ACTIVE | RG35XX target constants/policy | game logic |
| RG35XXFrameScheduler | Platform | Alpha 1 | ACTIVE | LCD generation/dirty frame wake | RGB565 conversion |
| RG35XXImageCache | Platform | Beta 1 | ACTIVE | immutable decoded-image LRU | mutable image state |
| RG35XXInputEngine | Platform | Beta 1 | ACTIVE | press/release/repeat semantics | native button polling |
| RG35XXWavDecoder | Platform | Beta 1 | ACTIVE | WAV codecs -> PCM16 | audio mixing |
| RG35XXMediaProfile | Platform | Beta 1 | ACTIVE | codec capability truth | codec implementation |
| RG35XXRuntimeStats | Platform | Beta 1 | ACTIVE | aggregate diagnostics | hot-path logging |
| RG35XXFontEngine | Platform | Beta 2 | PLANNED | unified text metrics+raster | game-specific layout hacks |
| PlatformImage | FreeJ2ME integration | legacy | ACTIVE | J2ME image/decode bridge | global cache ownership |
| MobilePlatform | FreeJ2ME integration | legacy | ACTIVE | LCD/input platform state | native IPC |
| PlatformGraphics | FreeJ2ME integration | legacy | TO-REFACTOR | J2ME graphics semantics | independent font metrics |
| PlatformPlayer | FreeJ2ME integration | legacy | TO-REFACTOR | MMAPI facade/state | long-term native mixer logic |
| Libretro.java | IPC integration | legacy | REDUCE | Java/native transport | platform business logic |
| freej2me_libretro.c | Native core | legacy | ACTIVE | libretro/video/audio/native IPC | J2ME API semantics |

## Ownership rule

From Platform 1.0 onward, new RG35XX policy belongs in a dedicated platform class whenever practical. The size and responsibility of Libretro.java and PlatformPlayer.java should trend downward, not upward.
