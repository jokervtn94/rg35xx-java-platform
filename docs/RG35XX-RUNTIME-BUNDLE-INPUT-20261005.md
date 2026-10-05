# RG35XX Runtime Bundle Input — 2026-10-05

## Status

```text
INPUT_BUNDLE_RECEIVED=YES
BUNDLE_ROLE=ALTERNATIVE_TEST_RUNTIME
PRODUCTION_RUNTIME_PROMOTED=NO
PROTECTED_A8_RUNTIME_REPLACED=NO
RUNTIME_LAYOUT_ON_DEVICE=NOT_INSTALLED_TO_FINAL_LOCATION
```

This record captures the additional `runtime.zip` supplied for the current RG35XX test workflow. It is evidence/input for integration planning. It is **not** promoted over the protected A8 runtime identity.

## Bundle identity

```text
RUNTIME_ZIP_SHA256=07ae3b97a4506d736d0553ce46987cdce378d50836349cf22e4b20db12011bad
JAMVM_SHA256=0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3
GLIBJ_SHA256=c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4
JAMVM_CLASSES_SHA256=ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86
LIBJVM_SHA256=a9f7376cfddc828cff5ae1fb1f78fca85f060d9104b36118a9913aea010e51ec
```

The bundle contains JamVM, GNU Classpath `glibj.zip`, JamVM helper classes, `libjvm.so`, and GNU Classpath native JNI libraries for java.io, java.lang, java.lang.management, java.lang.reflect, java.net, java.nio and java.util.

## Provenance

The binary layout and embedded paths match the repository's isolated runtime-candidate build track:

```text
RUNTIME_OWNER=JAMVM_2.0.0_PLUS_GNU_CLASSPATH_0.99
BUILD_TRACK=RG35XX-RUNTIME-CANDIDATE-REBUILD
BUILD_COMMIT=e2f6668f43965248b2f5d499c38c3b15cd692f15
WORKFLOW_RUN=37191027040
ARTIFACT_ID=11299340903
```

That track was explicitly created as a diagnostic alternative runtime and was not allowed to mutate the protected `/mnt/mmc/CFW/java` runtime.

## ABI / dependency findings

`bin/jamvm` and `lib/libjvm.so` are:

```text
ELF32
ARM
EABI5
SOFT_FLOAT_ABI
uClibc dynamic loader
```

The build uses the Miyoo uClibc cross toolchain with conservative original-RG35XX targeting (`-march=armv5te -mtune=arm926ej-s -mfloat-abi=soft`). This is materially different from the pinned Miyoo native frontend/3D build flags that assume Cortex-A7/ARMv7VE/VFPv4 hard-float.

Main JamVM dependencies:

```text
libz.so.1
libc.so.0
ld-uClibc.so.1
```

GNU Classpath native libraries also require `libgcc_s.so.1`; `libjavanio.so` requires `libiconv.so.2`.

## Java class-library capability visible in this bundle

`glibj.zip` contains, among others:

```text
java/awt/Graphics2D.class
javax/imageio/ImageIO.class
javax/net/ssl/SSLContext.class
java/net/Socket.class
java/nio/ByteBuffer.class
java/util/prefs/Preferences.class
javax/crypto/Cipher.class
```

This proves class presence in the supplied bundle. It does not by itself prove every backend works on original RG35XX; platform integration/physical evidence remains authoritative.

## Critical relocatability finding

This runtime is **not production-relocatable as built**.

JamVM/libjvm embed the configured prefix:

```text
/mnt/mmc/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime
```

including boot classpath, JamVM class path, extension/endorsed paths and native Classpath path. The `.la` files also record the same app-local `libdir`. `libjavanio.so` contains an RPATH derived from the Miyoo toolchain sysroot.

Therefore simply moving this bundle to `/mnt/mmc/CFW/java` or another final production directory is not accepted as a production installation method. A production candidate must be rebuilt with an explicitly approved final runtime root or otherwise demonstrate a deterministic relocatable launcher without changing protected behavior.

## Protected runtime relationship

This bundle does not match the locked A8 protected identities:

```text
PROTECTED_A8_JAMVM_SHA256=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
PROTECTED_A8_GLIBJ_SHA256=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
```

Therefore:

```text
ALTERNATIVE_RUNTIME_IDENTITY=CONFIRMED
A8_RUNTIME_IDENTITY=UNCHANGED
SILENT_REPLACEMENT=FORBIDDEN
```

## Integration decision

For the upcoming full-port integration:

```text
USE_AS_SOURCE_AND_TEST_RUNTIME_INPUT=YES
COPY_BLINDLY_TO_CFW_JAVA=NO
PROMOTE_AS_PRODUCTION_RUNTIME=NO
REBUILD_FOR_FINAL_LAYOUT_IF_SELECTED=REQUIRED
PHYSICAL_RUNTIME_ACCEPTANCE_IF_SELECTED=REQUIRED
```

The full-port integration should preserve the accepted A8 runtime authority by default. This supplied candidate may be used app-locally for controlled integration work and as a reproducible JamVM 2.0.0 + GNU Classpath 0.99 source/build reference. Selecting it as the final platform runtime is a separate runtime-owner decision and requires explicit evidence and acceptance; it must not be inferred from host build success alone.
