# P2C Original RG35XX Input Capability Diagnostic Result — 2026-10-03

## Scope

This record closes the original-RG35XX hardware identity prerequisite for P2C. It is diagnostic evidence only and is not P2C module physical acceptance.

```text
CURRENT_PHASE=P2
CURRENT_MODULE=P2C_INPUT_FRONTEND
SCOPE=DIAGNOSTIC_ONLY_ORIGINAL_RG35XX_RAW_JS0
MODIFIES_PRODUCTION_RUNTIME=NO
RUNTIME_SEMANTIC_DELTA=NONE
P2C_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
A9_PARENT=NO
GAME_SPECIFIC_CODE=NO
```

## Diagnostic identity

```text
AUDIT_BRANCH=audit/p2c-input-frontend-contract-20261003
DIAGNOSTIC_SOURCE_HEAD=8cb9a194500a075e8188e2941353d6d63b5b488a
DIAGNOSTIC_READY_CHECKPOINT=13e5d1a2c3336d090f53884030a0f798b56538d9
WORKFLOW_RUN=37137415150
WORKFLOW_JOB=111244650846
ARTIFACT_ID=11279100414
ARTIFACT_NAME=RG35XX-P2C-INPUT-CAPABILITY-DIAGNOSTIC
ARTIFACT_ZIP_SHA256=6f282f2d9b9360cae3dac9e822437e1e3d5333e0fa1e01ac302f9d657bd0f314
PACKAGE_TAR_GZ_SHA256=81bc34e41a766f3d2125edc637206988717e81601d025c45dbb2be1ac6824511
PROBE_SHA256=b37a0e79f58795e90e75261c161697c9e150f6a59bba0f3ffa861d56404f3bf1
DEVICE_RESULT_SHA256=2bf0de5660431bc144e29ab531fa7614ce764e29517b397fe865d88f3134fdf5
```

## Original RG35XX measured mapping

The device report completed all fourteen requested controls and exited with code 0.

| Control | js0 type | index | press | release | baseline |
| --- | --- | ---: | ---: | ---: | ---: |
| UP | axis | 7 | -32767 | 0 | 0 |
| DOWN | axis | 7 | 32767 | 0 | 0 |
| LEFT | axis | 6 | -32767 | 0 | 0 |
| RIGHT | axis | 6 | 32767 | 0 | 0 |
| A | button | 0 | 1 | 0 | 0 |
| B | button | 1 | 1 | 0 | 0 |
| X | button | 2 | 1 | 0 | 0 |
| Y | button | 3 | 1 | 0 | 0 |
| START | button | 8 | 1 | 0 | 0 |
| SELECT | button | 7 | 1 | 0 | 0 |
| L1 | button | 5 | 1 | 0 | 0 |
| L2 | axis | 2 | 32767 | -32767 | -32767 |
| R1 | button | 6 | 1 | 0 | 0 |
| R2 | axis | 5 | 32767 | -32767 | -32767 |

```text
KEYMAP_COUNT=14
P2C_INPUT_CAPABILITY_RESULT=PASS
PROBE_EXIT_CODE=0
P2C_DIAGNOSTIC_RESULT=PASS_14_CONTROL_CALIBRATION
HARDWARE_EVIDENCE=PASS
```

## Protected runtime evidence

The device report recorded the same protected JamVM and glibj hashes before and after the diagnostic:

```text
JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
PROTECTED_RUNTIME_BEFORE_AFTER=IDENTICAL
```

The diagnostic therefore closes the missing hardware inventory without changing the accepted production runtime.

## Decision

```text
L2_R2_EXACT_ORIGINAL_RG35XX_IDENTITY=PASS
COMPLETE_14_CONTROL_HARDWARE_INVENTORY=PASS
RUNTIME_PATCH_PREREQUISITE_HARDWARE_EVIDENCE=PASS
P2C_PHYSICAL_TEST=NOT_TESTED
NEXT_LEGAL_ACTION=P2C_DEFINE_AND_BUILD_MINIMUM_OWNER_SCOPED_CANDIDATE
```
