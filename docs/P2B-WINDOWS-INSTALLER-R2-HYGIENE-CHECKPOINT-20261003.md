# P2B Font/Text — Windows Installer R2 Hygiene Checkpoint

Date: 2026-10-03

## Scope

This checkpoint records a **packaging/helper-only** correction after the P2B Font/Text module had already passed original-RG35XX physical acceptance.

The physically accepted runtime remains:

```text
RUNTIME_CANDIDATE_COMMIT=2f18b78e9b0aa1660b7fd2f5904dd697fcef5830
SOURCE_PHYSICAL_BRANCH_HEAD=5a8e29dd368bf99b22e81d256691b2a7ec8f1adf
P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS
```

No runtime, native adapter, canonical source, font asset, launcher under `SD/`, exerciser, or protected artifact is changed by R2.

## Reason for R2

The original Windows PowerShell helper used a mandatory path parameter plus direct `Resolve-Path` and had no catch/pause path. User observation showed the helper window could terminate immediately after drive input without displaying a useful diagnostic.

The user successfully installed and physically tested the same R1 `SD/` payload using the corrected Windows helper package. Device evidence established 360/360 PASS, a green PASS screen, exit code 0, protected hashes PASS, and normal return to GarlicOS.

R2 therefore fixes only the Windows install/evidence-helper surface and preserves the accepted on-device payload byte-for-byte.

## Source lineage

```text
PHYSICAL_ACCEPTANCE_RECORD_COMMIT=4c8e10f3d96288deda6b9b6d000125cea59e3919
R2_REPACKER_COMMIT=4084d6cc9f4e38320f9c0492f3ecc7470cf594b8
R2_WORKFLOW_INITIAL_COMMIT=67c614ebcf6973496e3ce3ba13fd97aead382195
R2_WORKFLOW_PATH_FIX_COMMIT=db177eb139aa3468e4b436f034dd7ef19717ee09
```

The first R2 hygiene workflow run (`37133136622`, job `111232101121`) is retained as an archived diagnostic: it failed only because the GitHub artifact ZIP preserved the original workspace path and the workflow initially assumed the inner R1 ZIP was at artifact root. The accepted R1 package was not modified and no runtime semantic gate ran after that path lookup failure.

## Successful CI hygiene gate

```text
WORKFLOW=P2B Font Text Windows Installer R2 Hygiene
RUN_ID=37133242055
JOB_ID=111232412816
HEAD_SHA=db177eb139aa3468e4b436f034dd7ef19717ee09
RESULT=PASS
```

The successful run verifies:

```text
P2B_R2_ACCEPTED_LINEAGE=PASS
P2B_R2_REPOSITORY_SCOPE=PASS
P2B_R2_EXACT_ACCEPTED_R1_INPUT=PASS
P2B_R2_INPUT_R1_SHA_GATE=PASS
P2B_R2_KEY_PAYLOAD_HASH_GATE=PASS
P2B_R2_SD_RUNTIME_PAYLOAD_DELTA=NONE
P2B_R2_RUNTIME_SEMANTIC_DELTA=NONE
P2B_R2_REPACK_GATE=PASS
P2B_R2_INDEPENDENT_SD_TREE_IDENTITY=PASS
P2B_R2_WINDOWS_HELPER_GATE=PASS
```

The independent gate extracts both R1 and R2 and executes a recursive byte comparison of their complete `SD/` trees.

## Package identities

Exact physically accepted R1 package input:

```text
FILE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R1.zip
SHA256=1e78c30c166f2ce4988478d44c476b0bfdf8c6795e433cf8f21ed934796037da
SOURCE_WORKFLOW_RUN=37127662925
SOURCE_ARTIFACT_ID=11275935320
```

R2 Windows-helper hygiene package:

```text
FILE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R2.zip
SHA256=7df059c07a3867eef5e6a00348b19b18ee6901cffd4bf7b53caefbbebb34de38
SD_MANIFEST_SHA256=4ff2cd9b019c1b09147731ca690fa046d9fc361a8b715bda889a42c845d9d956
```

Uploaded GitHub Actions artifact:

```text
ARTIFACT_ID=11277463370
ARTIFACT_NAME=RG35XX-P2B-FONT-TEXT-PHYSICAL-R2-WINDOWS-HYGIENE-db177eb139aa3468e4b436f034dd7ef19717ee09
ARTIFACT_ARCHIVE_SHA256=234b72a12c64e3fe40b812b078552fdd340e22925b7617e7175da053795d885d
ARTIFACT_EXPIRED=NO
```

## R2 helper behavior

The Windows helper now:

- accepts drive forms such as `E`, `E:`, or `E:\`;
- rejects the Windows system drive;
- validates the exact P2B payload hashes before copying;
- copies the `SD/` contents to the selected SD-card root;
- validates important payload hashes after copying;
- prints explicit `INSTALL_RESULT=PASS` or `INSTALL_RESULT=FAIL`;
- waits for Enter before closing;
- supplies matching `.cmd` wrappers for install and evidence collection.

These files are outside the device `SD/` runtime payload.

## Physical re-test decision

```text
R2_ORIGINAL_RG35XX_RETEST_REQUIRED=NO
```

Reason: the complete device-visible `SD/` tree is independently proven byte-for-byte identical to the already physically accepted R1 tree. Repeating the same module physical run would not test a new device/runtime artifact and would consume unnecessary physical-device time.

The physical authority remains the user-returned R1 evidence and human observation recorded in `docs/P2B-FONT-TEXT-PHYSICAL-ACCEPTANCE-20261003.md`.

## Boundary after hygiene

```text
P2B_HOST_MODULE_GATE=PASS
P2B_PHYSICAL_PACKAGE_GATE=PASS
P2B_PHYSICAL_TEST=PASS
P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS
P2B_WINDOWS_INSTALLER_R2_HYGIENE=PASS
RUNTIME_SEMANTIC_DELTA=NONE
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
```

This checkpoint does not complete P2. Remaining P2 frontend/input/resolution/pointer/rotation policy work remains subject to its own platform-first module gates. It also does not satisfy P8 baseline promotion.
