# MIYOO M1.4A.8 MYMETHODVISITOR JAVA5 — BUILD RESULT

Date: 2026-09-15
Branch: rg35xx-miyoo-platform-v1
Head SHA: 3cf368075569bd0e4bda753a34529924735616eb
Source pin: aweigit/freej2me-miyoomini @ ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Workflow: Miyoo M1.4A Java5 Boot Slice
Run ID: 34930670366
Job ID: 104258010260

## Tasklog-first history check
The blocker was previously preserved after M1.4A.7 as the single active ASM instrumentation dependency. No prior Miyoo-branch MyMethodVisitor fix had DEVICE-PASS evidence. Earlier A.8 runs were INVALID harness runs and were not classified as source failures. The accepted change remained the preflight variable: BACKPORT_ACTIVE_MYMETHODVISITOR_SYNTAX_TO_JAVA5_PRESERVING_ASM_SEMANTICS.

## Exact build evidence
- compiler: javac 1.8.0_502
- source/target: Java 5 bounded audit contract
- JAVAC_RC=0
- MIDLETLOADER_NIO_GATE=PASS
- SDLMIXER_BOOT_GATE=PASS
- MIDLET_RMS_IMPORT_GATE=PASS
- M3G_2D_IMPORT_GATE=PASS
- MYMETHODVISITOR_JAVA5_GATE=PASS
- CLASS_COUNT=245
- CLASS_MAJOR_49_ONLY=YES
- M1_4A_8_RESULT=PASS

Artifact:
- ID: 10381174531
- name: rg35xx-miyoo-m1.4a-java5-boot-slice-audit
- ZIP SHA256: 637e95e7da6dc5b268308709ab3e9fc4cb388eae8e97680d3b53bad7cafaf739
- size: 321646 bytes

## Classification
BUILD-PASS = YES, limited to the bounded Java5 2D/no-audio source slice.
DEVICE-PASS = NO; this Java slice has not yet been launched on the real original RG35XX.
STABLE = NO.

This result does not promote audio, 3D/LWJGL, RMS implementation, font, transparency, VC7 diagnostics, or any previous Libretro transport into the Miyoo baseline.
