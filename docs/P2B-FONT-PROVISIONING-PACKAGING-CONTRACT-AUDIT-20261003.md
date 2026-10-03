# RG35XX P2B Font/Text — Font Provisioning / Packaging Contract Audit

**Status:** AUDIT_ONLY / PASS_FOR_EMBEDDED_SOFTWARE_SCOPE  
**Date:** 2026-10-03  
**Phase:** P2B_FONT_TEXT  
**Branch:** `audit/p2b-font-text-post-layout-r2`

> Engineering/license-evidence classification for this project scope only; this is not a legal opinion. No runtime implementation is included in this commit.

## 1. Exact font identity required by the pinned Miyoo contract

The exact font used by the Aweigit Miyoo 2.0 release and all P2B differentials is:

```text
SOURCE_RELEASE=https://github.com/aweigit/freej2me-miyoomini/releases/download/2.0/miyoomini-freej2me.zip
ENTRY=JAVA/font.ttf
SHA256=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
SIZE=8092724
NAME=MiSans_Normal
FAMILY=MiSans_Normal
PS_NAME=MiSans-Normal
```

Production P2B must use this exact identity unless all font-dependent differential evidence is reopened for another font.

## 2. Official Xiaomi license evidence

Official current sources checked on 2026-10-03:

```text
FAQ=https://hyperos.mi.com/font/en/faq/
DOWNLOAD_LICENSE=https://hyperos.mi.com/font/en/download/
LICENSE_PDF=https://hyperos.mi.com/font-download/MiSans字体知识产权许可协议.pdf
```

The official FAQ explicitly states that MiSans may be used as an **embedded font**, provided the software specifically notes that MiSans is used.

The official license grants royalty-free use subject to conditions including:

- software must specifically note that MiSans is used;
- the font/components must not be adapted or redeveloped;
- the font must not be distributed as a separate font product/copy;
- works such as applications created using MiSans may be distributed/sold;
- copyright notice and the license agreement must be retained with copies of MiSans.

Engineering classification:

```text
P2B_MISANS_EMBEDDED_USE_EVIDENCE=PASS
P2B_MISANS_ATTRIBUTION_REQUIRED=YES
P2B_MISANS_LICENSE_COPY_REQUIRED=YES
P2B_MISANS_MODIFICATION_ALLOWED=NO
P2B_MISANS_STANDALONE_FONT_DISTRIBUTION=REJECTED
```

## 3. Locked RG35XX packaging form

P2B may package the exact font only as an **internal embedded runtime asset of the FreeJ2ME-RG35XX application/platform package**.

Required layout concept:

```text
FreeJ2ME-RG35XX/
  freej2me-rg35xx.jar
  librg35xx_font.so                 [future P2B owner artifact]
  font.ttf                          [embedded runtime asset; exact hash only]
  licenses/
    MiSans-LICENSE.pdf
  NOTICE.txt                        [must state that the software uses MiSans]
```

Rules:

1. `font.ttf` is not published as a standalone downloadable artifact.
2. Build/release automation fetches it from the locked Aweigit 2.0 release lineage, extracts `JAVA/font.ttf`, and verifies SHA256/size before packaging.
3. The repository itself does not commit the font bytes.
4. The final app/platform package may contain the exact verified `font.ttf` as an embedded runtime component.
5. The official Xiaomi license agreement is included with the app/platform package.
6. `NOTICE.txt` explicitly states that MiSans is used and identifies Xiaomi as the font licensor/copyright owner as required by the license materials.
7. The font is copied byte-for-byte. No subsetting, conversion, patching, hinting change, glyph modification, or re-encoding is permitted.
8. Launcher/package gates reject a missing or mismatched font before Java runtime acceptance.

## 4. Why this preserves the Miyoo-first contract

Pinned Miyoo itself requires `./font.ttf`; the source tree does not contain the bytes. The Aweigit 2.0 release supplies the exact runtime file used by the P2B evidence.

The RG35XX package therefore preserves the same external-runtime-asset identity rather than substituting a different font or inventing fallback metrics.

```text
PINNED_MIYOO_FONT_CONTRACT
  -> exact Aweigit release font identity
  -> embedded RG35XX app asset
  -> hash gate
  -> exact JDK8u504 semantic backend
```

No game-specific font selection is allowed.

## 5. Failure behavior

The production candidate must fail closed for the exact font contract:

```text
FONT_MISSING -> PACKAGE/LAUNCH_GATE=FAIL
FONT_HASH_MISMATCH -> PACKAGE/LAUNCH_GATE=FAIL
FONT_SIZE_MISMATCH -> PACKAGE/LAUNCH_GATE=FAIL
FONT_FALLBACK_SUBSTITUTION=FORBIDDEN
```

Do not silently fall back to the current synthetic 5x7 Raw2D font or to an arbitrary system font.

## 6. Build-time provenance

The future candidate build must record at minimum:

```text
P2B_FONT_RELEASE_URL
P2B_FONT_RELEASE_ZIP_SHA256
P2B_FONT_ENTRY
P2B_FONT_SHA256
P2B_FONT_SIZE
P2B_FONT_EMBEDDED=YES
P2B_FONT_MODIFIED=NO
P2B_MISANS_NOTICE_PRESENT=YES
P2B_MISANS_LICENSE_PRESENT=YES
```

Font bytes may appear only in the final embedded application/package artifact and ephemeral build workspace required to create it. Audit-only artifacts must continue to exclude the font bytes.

## 7. Scope classification

```text
P2B_FONT_ASSET_IDENTITY=PASS
P2B_FONT_FAMILY_PROVENANCE=PASS
P2B_EXACT_BINARY_PROVENANCE=PARTIAL
P2B_MISANS_EMBEDDED_USE_EVIDENCE=PASS
P2B_FONT_PACKAGING_LICENSE_SCOPE=PASS_FOR_EMBEDDED_SOFTWARE_WITH_ATTRIBUTION
P2B_FONT_PROVISIONING_PACKAGING_CONTRACT=PASS
```

`P2B_EXACT_BINARY_PROVENANCE=PARTIAL` remains as a historical provenance statement: the exact 8,092,724-byte Miyoo-release binary has not been proven byte-identical to Xiaomi's current download revision. That does not authorize substitution. It remains hash-locked as the exact pinned Miyoo runtime asset.

## 8. Candidate authorization after this audit

All P2B pre-change fields required by the locked Miyoo-first rule are now resolved for an owner-scoped implementation candidate:

```text
MIYOO_SOURCE=PASS
FREEJ2ME_REFERENCE=PASS
JDK_OPENJDK_REFERENCE_IF_REQUIRED=PASS
RG35XX_MEASURED_LIMITATION=PASS
EXACT_FAILURE_OR_MISSING_CONTRACT=PASS
FAILURE_OWNER=PASS
WHY_MIYOO_AS_IS_CANNOT_WORK=PASS
MINIMUM_REQUIRED_DELTA=PASS
FILES_ALLOWED_TO_CHANGE=PASS
FILES_FORBIDDEN_TO_CHANGE=PASS
PARENT_REGRESSION_GATES=PASS
HOST_DIFFERENTIAL_GATE=PASS
MODULE_INTEGRATION_GATE=PASS
PHYSICAL_GATE=PASS
FONT_PROVISIONING_CONTRACT=PASS
GAME_SPECIFIC_CODE=NO
SPECULATIVE_OPTIMIZATION=NO
A9_PARENT=NO
```

Therefore the next legal engineering unit is:

```text
P2B-FONT-TEXT-MODULE-CANDIDATE-R1
```

It must be parented from the exact accepted P2A runtime lineage, not from an experimental game branch and not from A9. Audit evidence may be carried forward without changing the accepted P2A runtime semantics.

## 9. Physical-test lock remains

Implementation authorization is **not** physical acceptance.

```text
P2B_RUNTIME_CANDIDATE=NOT_TESTED
P2B_DEVICE_PACKAGE=FORBIDDEN_UNTIL_HOST_MODULE_GATES_PASS
P2B_PHYSICAL_TEST=NOT_TESTED
RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO
STABLE=NO
NEW_TIER1_FIX=FORBIDDEN
```
