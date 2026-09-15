# MIYOO M1.6 — JAVA -> SDL1/FBCON DISPLAY DEVICE RESULT

## Classification

BUILD-PASS = YES
DEVICE-EVIDENCE = YES
DEVICE-PASS = YES
DEVICE_PASS_SCOPE = M1.6_JAVA_TO_JNI_TO_SDL1_FBCON_DISPLAY_PATH_ONLY
FULL_PLATFORM_STABLE = NO

## Build identity

- Branch: rg35xx-miyoo-platform-v1
- Head SHA: 419e70035c7443daf352cdf58aee89b429248782
- Workflow run: 34933644505
- Job: 104266856028
- Artifact: 10382283430 / rg35xx-miyoo-m1.6-java-sdl1-display
- Artifact digest: sha256:20e7abec28f7bdfea92462ac6dd7c7f7c69ad23791e06c13cca4dccd1894e084
- libm1_6_display.so SHA256: f03a2fe5e31443fea009c878db209ac94e32cf8eab45f956e46681d74e2a5451
- m1.6-display-probe.jar SHA256: a5b5854ec47337330134aac66823d104700938d19a93ded430080d54d39adf3d

## Real-device log evidence

Device result reported:
- JAMVM_SHA256_BEFORE=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- GLIBJ_SHA256_BEFORE=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
- JAMVM_EXIT_CODE=0
- M1_6_JAVA_MARKER=PASS
- M1_6_SDL_DRIVER=fbcon
- M1_6_SURFACE=640x480 PITCH=2560
- M1_6_NATIVE_INIT_RC=0
- M1_6_FRAME_RED_RC=0
- M1_6_FRAME_GREEN_RC=0
- M1_6_FRAME_BLUE_RC=0
- M1_6_FRAME_WHITE_RC=0
- M1_6_DISPLAY_SEQUENCE_MARKER=PASS
- protected JamVM/glibj hashes unchanged after test
- PROTECTED_HASHES_UNCHANGED=YES
- M1_6_EXECUTION_RESULT=PASS

JamVM log independently contained the same Java/native/display markers and no reported linkage/exception failure.

## Physical LCD confirmation

User explicitly confirmed on the original RG35XX real device:

> Trên RG35XX đã hiện lần lượt Đỏ, Xanh Lá, Xanh Dương, Trắng và sau đó tự thoát bình thường

Therefore the required physical visual gate is satisfied:
- RED visible = PASS
- GREEN visible = PASS
- BLUE visible = PASS
- WHITE visible = PASS
- normal automatic exit = PASS
- hard hang/reset = NO

## Historical comparison

This result extends the previously DEVICE-PASS M1.2A native SDL1/fbcon display foundation. M1.6 proves the integrated path:

JamVM L -> Java5 probe -> JNI bridge -> SDL1 1.2 -> fbcon -> physical RG35XX LCD

SDL2 video remains rejected for this target. No audio, input, game-JAR execution, font, transparency, NoMask, VC7 or Libretro transport was admitted by this checkpoint.

## Locked conclusion

M1.6 Java-to-SDL1/fbcon display path is DEVICE-PASS and may be used as the display foundation for the next isolated checkpoint. This does NOT classify the full Java platform as stable.
