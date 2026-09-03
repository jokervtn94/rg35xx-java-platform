# RG35XX Java Platform RC1 — Source Reconciliation Audit

Status: STATIC-AUDIT-PASS for inventory reconciliation only. This document does not claim BUILD-PASS.

## Mandatory basis
Before this audit, `tasklog/TASKLOG.md`, `tasklog/RC1-TASKLOG.md`, and `docs/PLATFORM-SOURCE-REGISTRY.md` were reloaded. The current GitHub source tree was then checked against the registry rather than relying on memory or an older overlay.

## Confirmed registry/source mismatches

### 1. `RG35XXWavDecoder`
Registry state before audit: KEEP.
Expected path: `src/org/recompile/mobile/RG35XXWavDecoder.java`.
Current repository result: MISSING.
Impact: `RG35XXNativePlayer` explicitly requires WAV to be normalized to PCM16 before `setPcm16()`. The PlatformPlayer integration specification also depends on this helper. Therefore the Manager/PlatformPlayer RC gate cannot be locked until this source is restored or its responsibility is explicitly REPLACED by an audited existing owner.

No replacement class is created in this audit. Upstream WAV decoder classes (`WAVTools`, `WAVImaADPCMDecoder`, `WAVLawDecoder`) were inspected as possible source basis, but their current implementations include desktop/host sample-rate behavior and cannot be silently treated as the missing RG35XX normalization contract without a separate audited design.

### 2. `RG35XXFontEngine`
Registry state before audit: KEEP.
Expected path: `src/org/recompile/mobile/RG35XXFontEngine.java`.
Current repository result: MISSING.
Impact: the registry and RC1 manifest require unified font metrics/raster behavior. The previous Beta 2 design must not be reconstructed from memory because doing so could diverge from the approved metrics/resource contract.

No replacement font class/package is created in this audit. Recovery must come from an authoritative prior source/artifact or an explicit REPLACE task.

### 3. `rg35xx_audio_dispatch.h`
Registry state before audit: authoritative native module.
Expected path: `native/rg35xx_audio_dispatch.h`.
Current repository result: MISSING while `native/rg35xx_audio_dispatch.c` exists.
Impact: native build/link integration must verify whether the C module intentionally exposes no public header or whether the header was omitted. The registry must not claim the header exists until that is resolved.

## Search of prior files
A Library/conversation search for the historical Beta 2 ZIP and the exact missing Java filenames did not locate an authoritative `RG35XXFontEngine.java` or `RG35XXWavDecoder.java`. A prior combined patch was found, but exact-term inspection did not contain those class names. Therefore no old code is resurrected from an unrelated patch.

## Policy correction
The source registry now distinguishes `KEEP/PRESENT` from `MISSING — RESTORE REQUIRED`. A registry entry is not proof that the file currently exists. Future turns must check both registry intent and current tree presence.

## RC1 consequences
- `RGJ-RC1-010 Manager + PlatformPlayer media facade` remains open; it may be audited semantically but cannot be locked while `RG35XXWavDecoder` is missing.
- Font consolidation cannot be considered complete while `RG35XXFontEngine` is missing.
- Native media/link gate must resolve `rg35xx_audio_dispatch.h` ownership before BUILD-PASS.
- No BUILD-PASS or DEVICE-TEST-PASS is claimed.
