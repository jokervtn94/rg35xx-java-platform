# MIYOO M1.4C JAVA5 CORE2D BASELINE COMPILE — RESULT

Date: 2026-09-14
Branch: rg35xx-miyoo-platform-v1
Pinned Miyoo source: ca11dfe8ea1cc273d92460f9a83bbf192023fa63
Workflow run: 34870723323
Job: 104065642841
Artifact ID: 10359046029
Artifact ZIP SHA256: 001adee7e0733b572723899f9b0d534372fe19bb88387b92ec0a3097078fb339
Summary SHA256: c7b7cb9abc2b367b1e72b732105722eeb989e780b3cdf58737d15984db6f4ced
Compile log SHA256: 9f2facd3241a28072f2f505fa0a7ca958e0c75fb0b07963deb88ba6923957cb8
Source-list SHA256: 3396f679f02e66f7df16e15d1f8b90ac6fef00dd09a5b88a90475de44d7ed50d

## Baseline
- source inventory count: 276 Java files
- compiler: Temurin JDK 8 javac
- requested language/bytecode: `-source 1.5 -target 1.5`
- unmodified pinned source compile exit code: 1
- BASELINE_COMPILE=FAIL_EXPECTED
- 20 first-stage Java-version syntax errors

## Confirmed M1.4B blockers
Compiler independently confirmed:
- diamond syntax in mandatory lcdui/RMS/util/MIDletLoader/MyMethodVisitor files;
- try-with-resources in AndroidRecordStoreManager;
- lambda in RecordEnumerationImpl.

## Newly discovered blockers outside the first M1.4B scope
1. `org/microemu/cldc/file/FileSystemFileConnection.java`
   - diamond syntax;
   - real lambda in file sorting;
   - real try-with-resources with RandomAccessFile.
   - must be classified before patch because JSR-75 file connection may be mandatory for game compatibility.

2. bundled `org/objectweb/asm` source
   - ClassReader.java and Constants.java use try-with-resources.
   - upstream `lib/` contains only jsr305; there is no bundled ASM JAR to substitute automatically.
   - requires history/source comparison before choosing backport or replacement.

3. `ru/woesss/j2me/micro3d/*`
   - Java7/8 constructs found because the initial exclusion list did not cover this path.
   - this is optional 3D for the M1 2D boot checkpoint and must not be silently backported into the initial scope.

## Classification
This run is not a platform/device failure. It is a compiler-oracle result that expands the known source-compatibility inventory.

- BUILD-PASS for final Java5 candidate: NO
- DEVICE-PASS: NO / not tested
- STABLE: NO
- current JamVM/glibj/device platform modified: NO

## Required next action
Before editing source, search project history for prior Java5-compatible implementations of:
- FileSystemFileConnection / JSR-75 file transport;
- ASM sources used by the device-proven runtime;
- 3D/micro3d treatment in prior RG35XX builds.
Then choose the smallest M1.4C delta. Optional `ru/woesss/j2me/micro3d` must be excluded from initial 2D source set unless history proves it is required for boot.
