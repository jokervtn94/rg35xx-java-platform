# RG35XX Clean R2D Transparency — Build Result

Date: 2026-09-22
Branch: `rg35xx-clean-consolidated-r2`
Source commit: `3411e64c3787730a92484795f531c9eef283a799`

## CI

Workflow: `RG35XX Clean R2D Transparency`
Run ID: `35689243906`
Job ID: `106622513267`
Result: **SUCCESS**

Gates:
- exact R2A source foundation: PASS
- transparency-only source scope: PASS
- R2A PNG iCCP decode boundaries preserved: PASS
- R2D font owner absent: PASS
- Java class major 50: PASS
- transparency bytecode marker: PASS
- Windows installer/restore/collector parse: PASS
- collector StrictMode self-test: PASS
- package manifest: PASS

Artifact:
- ID: `10677812613`
- name: `rg35xx-clean-r2d-transparency`
- artifact/download ZIP SHA256:
  `f3276d9bd01443d5a9d6529dd9e1bf743618996945bed016246a8912b581a3fa`

Payload runtime SHA256:
`b377db1c725592fb96cddabe59ff8a376dab516184cd18c9f5f9b78f8501f891`

Required exact installed base:
`R2A = 5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913`

## Independent post-download verification

- GitHub digest vs downloaded ZIP: exact match
- every `SHA256SUMS.txt` entry: PASS
- payload SHA: exact match
- unresolved installer placeholders: zero

## Scope

Primary variable:
- image transparency semantics only

Enabled:
- raw PNG tRNS capture
- post-decode tRNS alpha recovery
- meaningful decoder alpha preservation
- conservative border-connected pure-white legacy sprite matte

Forbidden:
- global white-as-transparent

Unchanged:
- font/AWT
- audio
- Canvas/serviceRepaints
- native core/video
- JamVM/glibj
- R2A direct getRGB image normalization

## Status

- BUILD-PASS=YES
- DEVICE-PASS=PENDING
- STABLE=NO

Device test must begin from exact R2A, not from R2C-FONT or any audio candidate.
