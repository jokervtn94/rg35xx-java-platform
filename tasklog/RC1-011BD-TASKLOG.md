# RGJ-RC1-011BD — Correct AWK literal-call ownership gate

- Action: MODIFY
- Status: IMPLEMENTED
- Trigger: consolidated run `33881987528`, job `101052580270`.
- Failure: assembly reached all zero-fuzz patch application and then reported `assembled core audio drain start is not immediately after parent audio-pipe handoff`.
- Root cause: `scripts/rc1_assemble.sh` used doubled backslashes inside AWK regex literals (`\\(` / `\\)`), so the ownership matcher did not recognize the literal C calls even though the patch integration gate passed and 0015 places the drain start directly after the unique parent handoff call.
- Decision: correct only the AWK regex-literal escaping to `\(` / `\)`; preserve the strict `drain == parent + 1` ownership requirement and all runtime semantics.
- Acceptance: pinned patch integration PASS; consolidated assembly PASS; Java build PASS; ARMv5TE/uClibc compile/link PASS; no unresolved `rg35xx_*`; historical live-wiring warnings absent before BUILD-PASS may be claimed.
- BUILD-PASS: not claimed by this task.
- DEVICE-TEST-PASS: not claimed.
