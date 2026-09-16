# M1.14-r1 RG35XX Device Evidence

Checkpoint: Font Metrics Semantics v1
Primary variable: REPORTED_FONT_METRICS_ONLY
Commit under test: b3836548ba48e00a9881410d7f10f302e7e9e192

## Classification
- BUILD-PASS: YES
- DEVICE-PASS: YES for M1.14-r1 reported font metrics checkpoint
- FULL PLATFORM STABLE: NO
- Font resource: EXPERIMENTAL_NOT_GOLDEN

## Device evidence
- Font resource size: 727008
- Font SHA256: 20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9
- Resource gate: PASS_EXPERIMENTAL_20C2
- JamVM before/after: eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj before/after: d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- SDL driver: fbcon
- Surface: 640x480
- Native init: 0
- Present count: 21
- Normal exit: PASS
- Protected hashes: PASS
- Execution result: PASS
- Live capture: PASS, Java ARGB before presenter, frame 20, 640x480
- Live capture SHA256: f8798fd2ba01330cb166c91e9ae23dfb8029411f57bf5fba14f51c4cb506c775
- Screenshot SHA256: 9822cf8d3b2807afe3e99f7d77956bac90b0342698f12a1921d4be9224f93f3e

## Metrics observed on real RG35XX
All three MIDP size requests currently report the same metrics:
- height = 16
- baseline = 13
- stringWidth("ABC 123") = 56
- stringWidth("Tiếng Việt") = 80
- stringWidth("中文") = 24
- charWidth('I') = 8
- charWidth('ệ') = 8
- charWidth('中') = 12

The reported narrow/wide widths are internally consistent with the M1.13-r2 bitmap advance contract (8/12), and Unicode/Vietnamese/CJK remained visible in the device screenshot.

## Important unresolved observation
SMALL, MEDIUM and LARGE report identical API metrics even though the renderer has size-dependent bitmap scale behavior. This is not changed in r1. It is the next isolated compatibility question; do not alter raster/resource/SDL/GameCanvas/input/audio while investigating it.
