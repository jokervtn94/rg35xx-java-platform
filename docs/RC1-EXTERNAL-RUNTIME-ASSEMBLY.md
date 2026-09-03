# RC1 External Runtime / Asset Assembly

Status: STATIC-AUDIT-PASS for provenance/ownership policy. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Purpose

Close the ambiguous external-input portion of G14 without inventing project classes or silently copying moving third-party assets. This document defines exact providers and acquisition rules for the first reproducible RC1 assembly.

## SoundFont decision

Authoritative RC1 provider: `mrbumpy409/GeneralUser-GS` at commit `684543d5e5efaef08d02be50dcda8d552478fa60`.

Authoritative asset at that pin:

- path: `GeneralUser-GS.sf2`
- Git blob: `298b552d2e9d1307e03e5c5c99d2c046aaed9ec3`
- size: `32319396` bytes
- upstream version documented at that pin: GeneralUser GS 2.0.3
- license file: `documentation/LICENSE.txt`

The upstream license permits use of the complete SoundFont in software projects and modification of the bank/packaging, while explicitly documenting uncertainty in provenance of some contained samples. RC1 records that caveat rather than claiming stronger provenance than upstream provides.

Policy:

1. Never fetch moving `main` during a release build.
2. Acquisition may fetch the exact pinned commit before the offline build stage.
3. The assembled asset must be verified by Git blob identity before it is accepted.
4. Preserve the upstream license text beside distribution/build provenance.
5. `rg35xx_soundfont_source` remains the runtime byte-source owner; selecting GeneralUser GS does not create a second loader or filesystem owner.
6. The 32.3 MB SF2 must not be copied into this repository through the text Contents API. It is a reproducible external build input until a binary/LFS/release-asset policy is deliberately adopted.

## TinySoundFont / TinyMidiLoader

Keep the existing exact pin `schellingb/TinySoundFont@853a0a171759f1ddba0de1442133a75912bbeffa` and the corrected blob identities enforced by `native/verify_tinysoundfont_vendor.sh`.

No moving branch is accepted. Normal release/native build remains offline.

## GNU Classpath 0.99

GNU Classpath source remains an external target-runtime build input. RC1 does not fork or duplicate `java.awt.Font` or FreeJ2ME `PlatformFont`.

Assembly must provide the exact GNU Classpath 0.99 source used for the JamVM target and apply/account for `patches/0022-pinned-headless-font-peer-consolidation.patch` at the headless toolkit/font-peer layer.

A separate authoritative font resource is still unresolved. This task deliberately does not choose a font merely because one exists on the build host. Required properties remain: deterministic resource identity/license, Vietnamese coverage or deterministic missing-glyph behavior, and one cached non-null ClasspathFontPeer/FontDelegate path.

Therefore font-resource selection remains a BUILD-READY blocker.

## Native link ownership

The project native overlay already has one module owner for audio protocol/cache/event queue/dispatch/pipe/mixer/MIDI/TSF/SoundFont/runtime. The assembled `src/libretro/freej2me_libretro.c` remains the only core entrypoint.

Before BUILD-READY the final native build manifest must compile/link each registered `.c` exactly once, include the vendored TML/TSF headers, and carry required math/pthread/system libraries from the actual target toolchain. Do not create a parallel libretro core or duplicate TML/TSF implementation unit.

## Result

SoundFont provider ambiguity is closed at source-policy level. Physical SF2 materialization, GNU Classpath font resource, exact TML/TSF materialization and final native Makefile/source assembly remain external-input gates. No BUILD-READY claim is made.