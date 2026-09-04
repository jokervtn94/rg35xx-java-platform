# RC1-011AQ — Final 0019 zero-context insertion rebase

- Action: MODIFY
- Status: IMPLEMENTED
- Target: `patches/0019-platformplayer-tonecontrol-rg35xx.patch`
- Evidence basis: strict consolidated run `33874267653` and integration run `33874267782` at commit `407499a987f61b02006640e21eaf70a0ec1806bc`.
- Finding: 0019 one-line replacements already pass strict `--fuzz=0`; only the ToneControl native branch insertion and `Manager.playTone` RG35XX branch insertion still require fuzz 1.
- Exact integration anchors: the ToneControl state-check context matches pre-0019 old line 2264 (post-hunk output line 2297); the Manager volume-clamp context matches pre-0019 old line 173 (post-import/field output line 179).
- Decision: preserve all 0019 semantics and convert only these two remaining insertion hunks to zero-context pure insertions immediately after those exact old lines.
- Preserve: desktop JavaSound path; RG35XX device://tone routing through `RG35XXNativePlayer`; complete-blob device://midi stub; ToneControl MIDI passthrough/A-BNF encoding; 50ms minimum playTone duration; native EOM release; no Timer/sleep/JavaSound on target.
- Gate: patch integration + consolidated strict assembly must pass before compile evidence can be considered. BUILD-PASS is not claimed by this task.
