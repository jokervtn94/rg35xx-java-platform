# RGJ-RC1-011BP — Harden Windows asset retrieval + on-device test summary

- Action: MODIFY / ADD PACKAGING + DEVICE TEST UI
- Status: IMPLEMENTED
- Replaces only the fragile retrieval behavior of RC1-011BO; RC1-011BO remains immutable history.
- Windows retrieval policy: explicitly enable TLS 1.2; use multiple download mechanisms (`curl.exe`, .NET WebClient, BITS when available) instead of a single `Invoke-WebRequest` dependency.
- DejaVu source: exact 2.37 release asset, with official SourceForge 2.37 package as fallback. Extracted `DejaVuSans.ttf` must equal SHA-256 `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`.
- GeneralUser-GS source: exact pinned commit `684543d5e5efaef08d02be50dcda8d552478fa60`; prefer the commit archive and extract `GeneralUser-GS.sf2` so the completion flow is not dependent on raw-content delivery. Extracted file must equal SHA-256 `9575028c7a1f589f5770fccc8cff2734566af40cd26ed836944e9a5152688cfe`.
- Failure policy remains fail closed. A download/extraction/hash failure must not create a COMPLETE overlay.
- Device-test UI: extend `device-tests/RG35XXDeviceTest.java` from seven pages to eight, adding a SUMMARY page that consolidates automatic/observable state for video activity, graphics resource loading, font metrics, input activity/repeat, RMS persistence and media tests.
- SUMMARY values are diagnostic PASS/PENDING/FAIL only and never imply platform `DEVICE-TEST-PASS` without real-device review.
- No platform core/runtime media/input/graphics/RMS implementation semantics are changed.
