# RGJ-RC1-011H — Font Resource / GNU Classpath Assembly

Action: AUDIT / MODIFY
Status: STATIC-AUDIT-PASS

## Governance reload
Before mutation this stage reloaded `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, `docs/PLATFORM-SOURCE-REGISTRY.md`, patch 0022 and the 011D/011G audit inputs. No new RG35XX Java class was introduced.

## Decision
The authoritative RC1 font source is DejaVu Fonts 2.37 from `dejavu-fonts/dejavu-fonts`, tag `version_2_37`, commit `0eda8a319c08835009849583cd090bb5b141ce25`.

DejaVu Sans is the authoritative first-RC logical SansSerif/Dialog resource. Existing FreeJ2ME PlatformFont/PlatformGraphics and GNU Classpath HeadlessToolkit/ClasspathFontPeer ownership is unchanged. Historical RG35XXFontEngine remains superseded.

## Provenance constraint
The pinned source repository generates `DejaVuSans.ttf`; it does not provide that generated TTF as a root source blob at the pin. Therefore this stage deliberately does not fabricate a TTF Git blob identity. BUILD-READY requires the actual DejaVu 2.37 TTF to be obtained from an official binary release or reproducibly built from the exact source pin, then locally SHA-256 recorded and verified by the prebuild gate.

Upstream LICENSE must accompany the distributed resource.

## Build-gate change
`scripts/rc1_prebuild_gate.sh --build-ready` now requires `RG35XX_FONT_FILE` and `RG35XX_FONT_SHA256` and verifies the materialized file against the recorded SHA-256. The source pin is separately fixed in project policy.

## Remaining gates
- materialize exact TML/TSF headers;
- materialize pinned GeneralUser GS SF2;
- materialize/record DejaVu 2.37 TTF;
- assemble exact GNU Classpath 0.99 and implement/test patch 0022;
- consolidate native Makefile/source/link manifest;
- compile Java/native and then device-test.

No BUILD-READY, BUILD-PASS or DEVICE-TEST-PASS claim is made.