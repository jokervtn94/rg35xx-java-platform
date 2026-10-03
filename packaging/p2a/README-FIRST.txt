P2A IMAGE-DECODE MODULE — ORIGINAL RG35XX PHYSICAL ACCEPTANCE
============================================================

Purpose
-------
One physical module test for the P2A PNG image-decode candidate.
It is a generated/non-commercial platform exerciser, not a game test, and it never promotes DEVICE_PASS automatically.

Declared scope
--------------
PNG only. The exerciser covers all legal PNG color-type/bit-depth combinations used by the P2A contract, filters 0..4, non-interlace and Adam7, through all three canonical MIDP Image decode frontends: byte[], InputStream and resource name.
150 fixtures x 3 frontends = 450 device decodes. Expected pixel hashes are generated from pinned JDK8 ImageIO during CI. This package does not claim JPEG or other image formats.

Exact identities
----------------
Candidate head: __P2A_CANDIDATE_HEAD__
freej2me-rg35xx.jar SHA256: __P2A_PLATFORM_SHA256__
RG35XX-Platform-Exerciser-P2A-Image.jar SHA256: __P2A_EXERCISER_SHA256__
librg35xx_input.so SHA256: 69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
librg35xx_video.so SHA256: c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
libaudio.so SHA256: 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644

Install
-------
1. Extract this physical package on Windows.
2. Run PowerShell:
   .\INSTALL-RG35XX-P2A-IMAGE-DECODE.ps1 -SdRoot G:\
   Replace G:\ with the actual original-RG35XX SD-card root.
3. The installer refuses to write unless protected JamVM/glibj and all critical package hashes match.
4. It writes only these owned paths:
   Roms\APPS\RG35XX-P2A-IMAGE-DECODE.sh
   Roms\APPS\RG35XX-P2A-IMAGE-DECODE\
   Existing content at those exact paths is backed up first. A8 production paths are not replaced.

One device run
--------------
Launch exactly: RG35XX-P2A-IMAGE-DECODE
The runner creates one evidence directory:
  /mnt/mmc/RG35XX-P2A-IMAGE-DECODE-EVIDENCE
It verifies protected hashes before and after the run and logs every one of the 450 frontend decodes.

Visual acceptance
-----------------
Before pressing a key, physically verify:
- title reads: P2A IMAGE DECODE
- result reads PASS
- screen reports 150 fixtures and 450 decodes with zero failures
- no corrupt frame, white screen, hang, or hard reset
Then press any key once and verify normal return to the GarlicOS menu.

Programmatic evidence must include:
- RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER
- P2A_DEVICE_PROGRAMMATIC_RESULT=PASS
- P2A_PROTECTED_HASHES=PASS
- P2A_NORMAL_EXIT=PASS
- P2A_EXERCISER_FIXTURE_COUNT=150
- P2A_EXERCISER_DECODE_COUNT=450
- P2A_EXERCISER_FAILURE_COUNT=0
- P2A_EXERCISER_RESULT=PASS

Important
---------
Human physical observation is final authority. The runner writes DEVICE_PASS=NO_PENDING_MANUAL_REVIEW and STABLE=NO. Do not edit these to YES manually.

Collect evidence
----------------
Reconnect the SD card to Windows and run:
  .\COLLECT-RG35XX-P2A-IMAGE-DECODE-EVIDENCE.ps1 -SdRoot G:\
Upload the generated RG35XX-P2A-IMAGE-DECODE-EVIDENCE-*.zip together with your observation: screen PASS yes/no and normal return to GarlicOS yes/no.
