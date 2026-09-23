# RG35XX-AWEIGIT-R1

Production baseline for the original Anbernic RG35XX.

Canonical J2ME implementation:
- repo: `aweigit/freej2me-miyoomini`
- pinned commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- role: `CANONICAL_J2ME_IMPLEMENTATION`

Architecture:
`AWEIGIT_CANONICAL_J2ME_CORE -> RG35XX_ADAPTER -> RG35XX_PACKAGE_AND_LAUNCHER`

This branch intentionally starts from a clean working tree. Historical DP source/patch artifacts are not production inputs. They remain evidence/specification only.

Initialize canonical source with:

```sh
git submodule update --init --recursive
./scripts/verify-canonical.sh
```

No J2ME semantic modification is permitted without an evidence-driven exception record in the Master Tasklog. Audio remains out of scope until SMOKE and CORE INTEGRATION pass on real RG35XX hardware.
