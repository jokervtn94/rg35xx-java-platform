# DP-R1 Standalone Foundation — BUILD-PASS

Date: 2026-09-22
Branch: `rg35xx-device-pass-rebuild-v1`
Full platform: `STABLE=NO`

## Required build report

- Build head commit: `87f97171c90118b79d7496e5a2c034f320a0d4c6`
- Workflow: `RG35XX Device-Pass Rebuild v1 Foundation`
- Run ID: `35708878946`
- Job ID: `106684349741`
- Artifact ID: `10685078307`
- Artifact name: `rg35xx-device-pass-rebuild-v1-foundation`
- Artifact digest / downloaded ZIP SHA256: `5e9f371925b1f46c9bc5ddefbd8978a517a964c408f77f37ed999997d0536740`

Runtime identities:
- FreeJ2ME pin: `13ec186903087156c145268f8706eecfaf9f1e50`
- FreeJ2ME tree: `ad47ab16e9025f0eb3d2067bc3b1897dc71987df`
- Locked source snapshot: `faa49f9b941db5394265d9b13413e4576ef4694f`
- Platform JAR SHA256: `975376726a3b8a198d01c71260f3e6d129fe07c31c15fc75c8bc41e9906e91c2`
- Input JNI SHA256: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- SDL1 presenter JNI SHA256: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`
- M1.7 source SHA256: `34e0e19297a3c7e32520e0684ce7031f361fc8bcbf585093149dc8db7f39d603`
- Protected JamVM L required SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- Protected glibj required SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- Libretro core SHA256: N/A — this checkpoint is standalone SDL1/fbcon and contains no Libretro core.

## Gates passed

- pinned Miyoo/uClibc toolchain digest
- locked-source materialization from exact historical snapshot
- pinned FreeJ2ME commit + tree
- cumulative allowlisted standalone patches only
- Java compatibility gate: no class major > 50
- ARM ELF32 / EABI5 / soft-float gate
- SDL1/fbcon marker present; SDL2 absent
- raw `/dev/input/js0` marker present
- package SHA256 verification
- all GitHub Actions steps succeeded

## Exact scope of change

No new runtime behavior was designed in DP-R1. This checkpoint consolidates the already proven standalone patch/helper chain into one reproducible build artifact. It does not import Libretro/R2/VC7 code, audio reconstruction, transparency heuristics, SDL2, JavaSound media or GNU Classpath mutations.

Because consolidation itself creates a new combined artifact, historical subsystem DEVICE-PASS evidence is not silently promoted to this binary.

## Classification

- `BUILD-PASS=YES`
- `DEVICE-PASS=NO`
- `DEVICE-TEST-PENDING=YES`
- `STABLE=NO`

## Required RG35XX acceptance

Run, in order:
1. Canvas E2E
2. GameCanvas E2E
3. 36-configuration font matrix + visual review
4. RMS lifecycle
5. RMS persistence Phase A
6. new process/reboot, RMS persistence Phase B
7. blank PlatformImage dimensions/getGraphics
8. collect evidence

Any hard reset, protected hash change, or regression in a locked boundary makes DP-R1 FAIL. Font resource `20c2...` remains `EXPERIMENTAL_NOT_GOLDEN`.
