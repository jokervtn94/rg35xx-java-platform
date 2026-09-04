# RG35XX Java Platform — RC1 011Z Tasklog

This file extends the immutable RC1 engineering record.

## RGJ-RC1-011Z — Split disposable GNU Classpath baselines for assembly and runtime overlay
- Action: MODIFY (workflow orchestration only)
- Status: IMPLEMENTED
- Trigger: consolidated build run `33863280657` passed toolchain and all external-input gates, then `rc1_assemble.sh` successfully applied the Classpath font overlay and completed assembly. The subsequent `rc1_runtime_build_overlay.sh` failed with `unexpected getClasspathFontPeer baseline; refuse unreviewed rewrite` because it was given the already-modified Classpath tree and correctly refused a second application.
- Root cause: both stages were sharing one disposable GNU Classpath source directory even though each overlay script intentionally guards the pristine 0.99 baseline.
- Correction: materialize two independent Classpath 0.99 source trees from the same exact verified archive. `rc1_assemble.sh` receives the assembly tree; after it completes, `rc1_runtime_build_overlay.sh` receives the still-pristine runtime-input tree and writes its own disposable runtime assembly output.
- Preservation: no Classpath guard is relaxed, no font logic changes, no project class/native module is added or replaced, and both trees retain the same exact GNU Classpath 0.99 archive SHA-256.
- Acceptance: external-input gate must remain PASS, assembly must remain PASS, runtime overlay must pass on the pristine second tree, then the workflow may proceed to `rc1_compile.sh`.
- Boundary: no BUILD-PASS is claimed until the consolidated Java JAR and ARMv5TE/uClibC core compile/link successfully and postbuild evidence is reviewed.
