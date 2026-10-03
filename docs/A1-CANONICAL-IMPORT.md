# A1 Canonical Import Record

Date: 2026-09-23
Project: RG35XX-AWEIGIT-R1
Production branch: `rg35xx-aweigit-port-r1`

## Canonical identity

- Repository: `aweigit/freej2me-miyoomini`
- Commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- Upstream Git tree: `36493c9bc81badeae98966e6a3bdb86812068858`
- Role: `CANONICAL_J2ME_IMPLEMENTATION`
- Import form: pinned git submodule at `upstream/freej2me-miyoomini`

The production working tree intentionally does not carry forward the historical DP/legacy Java source tree. Old DP artifacts remain evidence/specification only.

## Canonical source/build inventory

Observed at the pinned commit:

- Java build: Apache Ant `build.xml`
- Java source root: `src/`
- Top-level Java namespaces under `src/`: `android`, `com`, `javax`, `org`, `ru`
- Core FreeJ2ME entry/config: `src/org/recompile/freej2me/Anbu.java`, `SDLConfig.java`
- Core platform layer includes `src/org/recompile/mobile/MobilePlatform.java`, `Mobile.java`, `PlatformGraphics.java`
- Build output: `build/freej2me-sdl.jar`
- Main-Class: `org.recompile.freej2me.Anbu`
- Java classpath dependency directory: `lib/`
- Observed Java dependency: `lib/jsr305-3.0.2.jar`
- Native/source support: `cpp/` including native M3G/micro3d/SDL-mixer makefiles and JNI headers
- Bundled native library sets: `jlib/arm32`, `jlib/arm64`, `jlib/x64Linux`
- Observed ARM32 bundled LWJGL libraries: `liblwjgl.so`, `liblwjgl_opengles.so`

Aweigit handheld frontend assumptions are not automatically adopted by RG35XX. In particular, SDL2-oriented frontend/native choices are outside the canonical J2ME semantic lock and must be replaced/adapted at the RG35XX adapter boundary where required.

## Canonical-diff gate established before adapter work

`scripts/verify-canonical.sh` fails if:

1. the submodule is not initialized;
2. the checked-out upstream commit differs from the pin;
3. the configured upstream repository differs;
4. the upstream working tree is dirty;
5. the production gitlink differs from the pinned canonical commit.

This provides the initial canonical integrity gate before A2/A3 modifications.

## A1 status

- Production branch created: YES
- Clean production tree: YES
- Exact Aweigit pin recorded: YES
- Canonical source materialization mechanism: YES
- Initial canonical diff/integrity gate: YES
- DP Java patch replay: NO
- RG35XX adapter source imported: NO (deferred to A2 inventory)
- Runtime/JamVM/glibj changed: NO
- J2ME semantic source changed: NO
- BUILD-PASS: NO
- DEVICE-PASS: NO
- STABLE: NO

Next stage: A2 — inventory only the device-proven RG35XX adapter pieces worth carrying forward, recording `origin -> purpose -> source hash -> previous device evidence -> new hash` for each candidate.
