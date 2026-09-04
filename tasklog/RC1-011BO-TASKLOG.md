# RGJ-RC1-011BO — Windows one-click completion of pinned runtime assets

- Action: ADD PACKAGING TOOL
- Status: IMPLEMENTED
- Scope: provide a Windows-side helper that completes an existing RC1 SD-card overlay with the exact pinned DejaVu Sans and GeneralUser-GS assets without requiring the user to search for files manually.
- Source policy:
  - DejaVu Fonts 2.37 release archive only; extracted `DejaVuSans.ttf` must equal SHA-256 `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`.
  - GeneralUser-GS commit `684543d5e5efaef08d02be50dcda8d552478fa60`; `GeneralUser-GS.sf2` must equal SHA-256 `9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`.
- Failure policy: fail closed on download, extraction, or hash mismatch; never accept substitute font/SoundFont bytes.
- Output: place the two verified files into `Java/runtime/` of the supplied SD overlay and refresh `SHA256SUMS` when present.
- Usability: include a `.cmd` launcher so Windows users can double-click rather than type a shell/PowerShell command.
- No RG35XX runtime/media/input/graphics/RMS implementation code is modified.
- DEVICE-TEST-PASS is not implied.
