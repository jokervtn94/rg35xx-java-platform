# RG35XX Java Platform — RC1 011AP Tasklog

## RGJ-RC1-011AP — Rebase remaining 0019 ToneControl/playTone hunks to zero-fuzz anchors
- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0019-platformplayer-tonecontrol-rg35xx.patch` only.
- Trigger: consolidated strict assembly run `33873643729` passes 0015 and 0018, then fails only 0019 PlatformPlayer hunk #3 and Manager hunk #3 under `--fuzz=0`; ordinary integration run `33873643838` shows both exact semantic hunks require only fuzz 1.
- Decision: preserve all 0019 behavior and split the two stale broad-context hunks into minimal exact one-line anchors / insertions and one-line replacements.
- Preserve: RG35XX device://tone routing; JavaSound-free ToneControl encoding; native transient playTone with 50ms minimum; EOM release; desktop JavaSound path; device://midi safe stub.
- Forbidden: lowering the strict assembly gate, deleting ToneControl/playTone functionality, introducing a second player/encoder owner, or changing 0018 ownership.
- Validation: patch integration plus consolidated `--fuzz=0` assembly; BUILD-PASS remains unclaimed until compile/link and live-wiring evidence pass.
