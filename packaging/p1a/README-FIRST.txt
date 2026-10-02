P1A GRAPHICS MODULE — ORIGINAL RG35XX PHYSICAL ACCEPTANCE
========================================================

Purpose
-------
One physical module test for the completed P1A Graphics / Raw2D / DirectGraphics candidate.
This package does not test individual methods separately and never promotes DEVICE_PASS automatically.

Exact identities
----------------
Candidate head: 74935af9de9d184dd33a72c80038dcc594f7d3f1
freej2me-rg35xx.jar SHA256: ca61589b71da1413f06ab7f898d490274506638d4d2db3be47a4137970a9263a
RG35XX-Platform-Exerciser-P1A.jar SHA256: 126d586ccaeede8bc8adddf5fa65ee9b5b037ca8468c6dce5aa513bb6bd3fefc
librg35xx_input.so SHA256: 69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
librg35xx_video.so SHA256: c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
libaudio.so SHA256: 4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644

Install
-------
1. Extract this physical package on Windows.
2. Run PowerShell:
   .\INSTALL-RG35XX-P1A-GRAPHICS.ps1 -SdRoot G:\
   Replace G:\ with the actual original-RG35XX SD-card root.
3. The installer refuses to write anything unless protected JamVM/glibj and all critical package hashes match.
4. It writes only these owned paths:
   Roms\APPS\RG35XX-P1A-GRAPHICS.sh
   Roms\APPS\RG35XX-P1A-GRAPHICS\
   Existing content at those exact paths is backed up first. A8 production paths are not replaced.

One device run
--------------
Launch exactly: RG35XX-P1A-GRAPHICS

The runner creates exactly one device evidence directory:
  /mnt/mmc/RG35XX-P1A-GRAPHICS-EVIDENCE

It verifies and logs exact hashes for JamVM, glibj, platform JAR, input native, video native, protected A7 audio bridge, and exerciser before and after the run. It also logs every exerciser case and requires the accepted A7 lazy audio bridge to load successfully.

Visual acceptance
-----------------
Before pressing a key, physically verify:
- title reads: P1A GRAPHICS PASS
- every listed case shows PASS/green
- no obvious corrupt frame, white screen, hang, or hard reset
Then press any key once.
Verify that execution returns normally to the GarlicOS menu.

Programmatic evidence must include:
- RG35XX_A7_AUDIO_BRIDGE=LOADED DEVICE_INIT=LAZY BACKEND=SDL1_MIXER
- P1A_DEVICE_PROGRAMMATIC_RESULT=PASS
- P1A_PROTECTED_HASHES=PASS
- P1A_NORMAL_EXIT=PASS
- P1A_EXERCISER_RESULT=PASS
- every P1A_EXERCISER_<case>=PASS marker

Important
---------
Human physical observation is the final authority. The runner writes DEVICE_PASS=NO_PENDING_MANUAL_REVIEW and STABLE=NO. Do not edit these to YES manually.

Collect evidence
----------------
Reconnect the SD card to Windows and run:
  .\COLLECT-RG35XX-P1A-GRAPHICS-EVIDENCE.ps1 -SdRoot G:\
Upload the generated RG35XX-P1A-GRAPHICS-EVIDENCE-*.zip for review together with your physical observation (screen showed P1A GRAPHICS PASS; normal return to GarlicOS yes/no).
