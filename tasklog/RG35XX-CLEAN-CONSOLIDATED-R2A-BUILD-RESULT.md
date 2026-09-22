# RG35XX Clean Consolidated R2A — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Source commit: `42f7a7b85a1f34ada9db156039ce8d3d98d58e25`

## Purpose

R2A is the first narrow checkpoint after the current installed R1.
It changes decoded-image normalization only.

Reference architecture audited:
- `aweigit/freej2me-miyoomini`
- commit `ca11dfe8ea1cc273d92460f9a83bbf192023fa63`

Miyoo is used for ownership/architecture guidance, not copied wholesale.

## R2A delta

For the three PlatformImage decoded-image boundaries:

Before:
`ImageIO -> if non-INT image -> new ARGB -> Graphics2D.drawImage`

R2A:
`ImageIO + R1 PNG iCCP sanitizer -> if non-INT image -> BufferedImage.getRGB -> direct DataBufferInt copy`

This removes GNU Classpath headless Graphics2D from decoded-image normalization.

Bounded diagnostics:
- `RG35XX-R2A-IMAGE-NORMALIZE`
- first 24 conversions only.

## Scope locks

Unchanged:
- R1 video mask R2
- R1 hotpath cleanup
- R1 PNG iCCP
- R1 VC7R2 dynamic logical view
- R1 canonical framebuffer binding
- R1 Golden Java frame transport
- protected B4 native core
- JamVM L
- glibj
- Canvas/serviceRepaints semantics
- current audio path

R2A does not claim to fix audio, screenshot capture, or freeze.

## CI

Workflow:
- `RG35XX Clean Consolidated R2A Image Normalize`

Final package run:
- run ID: `35687681984`
- job ID: `106617922366`
- result: **SUCCESS**

Gates:
- exact FreeJ2ME pin: PASS
- R1 assembly inheritance: PASS
- R2A scope/ownership gate: PASS
- Java class major 50: PASS
- Windows PowerShell installer/restore/collector parse: PASS
- collector StrictMode 0/1/N self-test: PASS
- package SHA manifest: PASS

Artifact:
- ID: `10676954350`
- name: `rg35xx-clean-consolidated-r2a-runtime`
- GitHub artifact digest / downloaded ZIP SHA256:
  `10bebb7095d04ec6d3b0e16381f87ec9d7a1ecb79c796344a500d02b2087200e`

Final packaged runtime SHA256:
`5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`

Required installed R1 runtime SHA256:
`6053eb80f890c33a4ef2466e1c18c516178d3b4a0d1ad5130c91a532951d9921`

Protected foundation:
- JamVM L:
  `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj:
  `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`
- B4 core:
  `56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c`

## Device test

Installer is fail-closed:
- requires all five runtime aliases to equal exact current R1 runtime;
- requires exact JamVM/glibj/protected core;
- backs up R1 aliases;
- replaces JAR aliases only;
- native core is not packaged or modified.

Test the same game that showed black/missing decoded assets on R1.
Then run `COLLECT-RG35XX-CLEAN-R2A.cmd`.

Collector also copies up to 10 recent screenshots from known RetroArch screenshot directories when present.

## Status

- BUILD-PASS=YES
- DEVICE-PASS=PENDING
- STABLE=NO
