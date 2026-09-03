# Build and Deployment Reference

This document records the known RG35XX Original build target. Platform 1.0 is still under static development; these commands are retained for the later consolidated RC build.

## Java

FreeJ2ME Plus uses Ant. Its build does not provide an `ant clean` target. To force a clean Java rebuild:

```bash
cd ~/freej2me-plus && rm -rf build && ant
```

Do not document or use `ant clean` for this project.

## Native libretro core

```bash
cd ~/freej2me-plus/src/libretro && make clean && make CC="/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-gcc -marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft -pthread" CXX="/opt/miyoo/bin/arm-miyoo-linux-uclibcgnueabi-g++ -marm -march=armv5te -mtune=arm926ej-s -mfloat-abi=soft -pthread"
```

The MiyooCFW shared SDK is used because it produces binaries compatible with the GarlicOS-era uClibc userspace.

## Deployment layout

```text
/mnt/mmc/BIOS/freej2me-lr.jar
/mnt/mmc/CFW/java/bin/jamvm
/mnt/mmc/CFW/retroarch/.retroarch/cores/freej2me_plus_libretro.so
/mnt/mmc/Roms/JAVA/*.jar
```

GarlicOS core mapping uses:

```json
"JAVA": "freej2me_plus_libretro.so"
```

## Important runtime constraints

- Java launcher: `/mnt/mmc/CFW/java/bin/jamvm`
- do not rely on FAT32 symlinks
- GNU Classpath unversioned JNI `.so` names must be physical files on deployment media
- Java stdout is IPC and must remain untouched by shell/native logging redirects
- JAR and native core must be protocol-compatible
- fixed frontend geometry remains 640x480 RGB565

## Test policy

Do not build/test every micro-patch. Beta stages are completed with source/JAR/static audits first. The consolidated Release Candidate is then built and tested on the real RG35XX against the compatibility matrix.
