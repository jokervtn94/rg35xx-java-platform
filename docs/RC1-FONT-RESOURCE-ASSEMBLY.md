# RC1 Font Resource / GNU Classpath Assembly

Status: STATIC-AUDIT-PASS for font-resource provenance and assembly policy. BUILD-READY, BUILD-PASS and DEVICE-TEST-PASS are not claimed.

## Scope

This closes the unresolved font-resource selection left by RGJ-RC1-011D/011G without restoring the superseded RG35XXFontEngine or choosing a host-installed font implicitly.

## Authoritative font source

RC1 selects DejaVu Sans from `dejavu-fonts/dejavu-fonts` tag `version_2_37`, resolving to commit:

`0eda8a319c08835009849583cd090bb5b141ce25`

The upstream LICENSE at that pin permits reproduction/distribution of the Font Software subject to preserving copyright/trademark/permission notices. DejaVu changes are documented as public domain; imported Bitstream Vera/Arev portions retain their stated license terms.

The source repository builds `DejaVuSans.ttf` as an output rather than storing the generated TTF at the repository root. Therefore RC1 MUST NOT invent a Git blob identity for a generated TTF. Acquisition must use an official DejaVu 2.37 binary release artifact or reproducibly build the TTF from the exact pinned source; the resulting file must then be hashed locally and recorded in the assembly provenance before BUILD-READY is claimed.

## Why DejaVu Sans

The pinned DejaVu language-coverage data is the authoritative coverage evidence for the selected family. It is suitable as the single default logical SansSerif/Dialog resource for the first RC because the project requires broad Latin coverage including Vietnamese rather than an ASCII-only fallback. Runtime glyph behavior still requires JamVM/GNU Classpath smoke validation.

## GNU Classpath ownership

FreeJ2ME `PlatformFont` and `PlatformGraphics` remain unchanged owners of MIDP font policy/drawing. GNU Classpath `HeadlessToolkit` plus one real `ClasspathFontPeer`/`OpenTypeFontPeer` delegate remains the backend owner under patch 0022.

Assembly requirements:

1. Exact GNU Classpath 0.99 source input must be identified and verified before patching.
2. Map logical `SansSerif` and `Dialog` to the pinned DejaVu Sans resource. `Monospaced` must either map deterministically to an explicitly pinned DejaVu Sans Mono resource or deliberately share the same pinned Sans resource for RC1; no host font discovery is allowed.
3. Font resource loading happens during font/toolkit initialization and is cached. Never open/parse the TTF per `drawString`.
4. `getFontPeer(String,int)` and `getClasspathFontPeer(String,Map)` must return a non-null usable peer/delegate.
5. Initialization failure is fatal/diagnostic; do not allow a Font with a null peer/delegate to continue into `hashCode`, glyph-vector or metrics paths.
6. Do not add ASCII sanitization or a second bitmap font renderer.

## Required local provenance record

Before BUILD-READY, assembly must record:

- DejaVu upstream tag and commit above;
- exact binary artifact origin or exact reproducible-build procedure;
- SHA-256 of the actual TTF installed into the target runtime;
- preserved upstream LICENSE;
- exact target installation path used by the patched headless peer.

## Smoke acceptance before BUILD-PASS

On the assembled JamVM/GNU Classpath runtime:

- construct SansSerif/Dialog/Monospaced Font objects;
- call `hashCode()` without exception;
- obtain stable FontMetrics repeatedly;
- create a glyph vector without null-peer/delegate failure;
- measure/render ASCII and Vietnamese precomposed text;
- verify repeated drawString calls do not reload the font resource.

## Result

Font family/provider ambiguity is closed: DejaVu 2.37 is the authoritative RC1 font source. Physical generated TTF identity remains an assembly-time materialization gate and must be recorded from the actual official/reproducible artifact; it is not fabricated in this repository.