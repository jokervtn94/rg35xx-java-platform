# RGJ-RC1-011G — External Runtime / Asset Assembly

Status: STATIC-AUDIT-PASS for SoundFont provenance and external-input policy. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

Action: MODIFY / ADD / AUDIT.

Mandatory reload completed before mutation: `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, current prebuild gate, font audit/0022 contract and current external dependency state.

## SoundFont provider closed

RC1 selects `mrbumpy409/GeneralUser-GS@684543d5e5efaef08d02be50dcda8d552478fa60` as the authoritative SoundFont provider.

Pinned asset:

- `GeneralUser-GS.sf2`
- Git blob `298b552d2e9d1307e03e5c5c99d2c046aaed9ec3`
- size `32319396` bytes
- upstream version 2.0.3
- preserve `documentation/LICENSE.txt`

The upstream complete-work license permits software-project use, but upstream also explicitly records uncertainty about provenance of some contained samples. RC1 preserves that caveat and makes no stronger provenance claim.

The binary is not copied into this repository via the UTF-8 text Contents API. It remains an exact pinned external acquisition input until a deliberate binary/LFS/release-asset policy is adopted.

## Prebuild gate hardened

`scripts/rc1_prebuild_gate.sh --build-ready` now requires:

- explicit `RG35XX_FONT_FILE` in addition to the GNU Classpath source root;
- explicit `RG35XX_SOUNDFONT_FILE`;
- exact SoundFont byte size;
- exact SoundFont Git blob identity.

Therefore an arbitrary local `.sf2` can no longer satisfy BUILD-READY.

## Font decision

No font asset was guessed. 011D/0022 requires a deterministic licensed target TTF/OTF with a real cached ClasspathFontPeer/FontDelegate and Vietnamese/missing-glyph acceptance. That resource remains unresolved and is still a hard BUILD-READY blocker.

## Remaining external gates

1. exact TML/TSF headers physically materialized and verifier-passing;
2. pinned GeneralUser GS bytes physically materialized;
3. exact GNU Classpath 0.99 source assembled with 0022;
4. authoritative target TTF/OTF selected and pinned;
5. final native Makefile/source list links every registered module exactly once against the actual ARMv5TE/uClibc toolchain.

Audit: `docs/RC1-EXTERNAL-RUNTIME-ASSEMBLY.md`.

Gate result: STATIC-AUDIT-PASS for 011G policy/provenance. No BUILD-READY claim.