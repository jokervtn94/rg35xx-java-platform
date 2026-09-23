# RG35XX AWEIGIT PORT R1 — CONTROL LOCK

Created: 2026-09-23

This branch is a control/documentation branch only. It must not inherit the historical DP patch chain as production source.

## New canonical direction

- Canonical repository: `aweigit/freej2me-miyoomini`
- Canonical pinned commit: `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`
- Production baseline name: `RG35XX-AWEIGIT-R1`
- Production branch to create/use: `rg35xx-aweigit-port-r1`
- Development method: `INTEGRATION_FIRST`
- DP-R1..DP-R11 role: `EVIDENCE_ARCHIVE_ONLY`
- Do not continue the primary production sequence as DP-R12/R13/etc.

## Protected original-RG35XX contracts

- JamVM L SHA256: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj.zip SHA256: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- Toolchain: `docker.io/miyoocfw/toolchain-shared-uclibc@sha256:6f6761867b4e4dcc27c99bf25fb91b2910264165f27bdd40b1c17e6f98cf751e`
- Video: SDL1/fbcon on original RG35XX
- Input: `/dev/input/js0`
- Native input reference SHA256: `02d2e4f5dec767ea63ef4fae067a942fd7026a7c68a7e422e0fe9680462a568c`
- Native presenter reference SHA256: `b09bbac1214b96310ebc6accee4ee7f45f144888bff92a9b1af08fecbccd3a0c`

## Control documents generated for handoff

The handoff package created on 2026-09-23 contains:

1. `RG35XX_AWEIGIT_PORT_RULES_v1.0.json`
   - SHA256: `fbbb5d13d59d8f0fc85f40ef6a1e66206d37045c8bae256ce2c43a416366ad7b`
2. `MASTER-TASKLOG-RG35XX-AWEIGIT-PORT-R1-20260923.md`
   - SHA256: `5db57873cc32adb60a8ab4557125f830184bf575dd95e10f229f5413bb7530b5`
3. `NEW-CHAT-STARTER-RG35XX-AWEIGIT-PORT-R1.txt`
   - SHA256: `792eaeb0277737935ec16a853f86c22843bb13b4a1eede3f27bf9fcb283f41c4`
4. `RG35XX_AWEIGIT_PORT_R1_CONTROL_PACK_20260923.zip`
   - SHA256: `f1d72570a41711d4331f674573ae1727ed1a36e2e3d9eca6f1534c6d67b69421`

## Required new-chat start

Start with A0 Control Lock then A1 Canonical Import from the Master Tasklog.

Do not immediately patch the DP-R11 `PlatformGraphics.clipRect()` failure. DP-R11 is the strategy-reset evidence showing why the accumulated micro-patch chain must no longer be the production architecture.

## Test policy

Production progression is:

`SMOKE -> CORE INTEGRATION -> REAL GAME REGRESSION`

A micro diagnostic/A-B test is allowed only after one of those parent tests exposes a reproducible failure. After a micro fix, rerun the parent integration/regression test before any promotion.

Full platform remains `STABLE=NO`.
