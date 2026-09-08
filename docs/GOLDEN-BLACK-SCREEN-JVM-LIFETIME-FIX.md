# Golden black-screen JVM lifetime fix

Status: SOURCE-FIX / DEVICE-TEST-PENDING

## Device evidence

The one-shot diagnostic core on RG35XX reached:

- video init OK
- receiver thread entered
- frame request sent
- frame header read FAILED with EOF semantics
- receiver exited at generation=0

The Java stderr log contained only the ALSA sequencer warning and no Java exception or JamVM SIGSEGV.

## Root-cause hypothesis promoted to source fix

`Libretro.main()` only constructs `Libretro` and then returns. The pinned upstream `LibretroIO` thread is explicitly daemon. The reconstructed `RG35XXGoldenFrameTransport` worker was also configured daemon. On the headless JamVM runtime, once the main thread returns there may be no non-daemon Java thread left to anchor process lifetime. JamVM can therefore terminate cleanly, closing binary stdout while the native receiver is waiting for the first 0xFE frame header.

That behavior matches the device trace exactly: native sends the first frame request, receives EOF instead of a header, and generation remains zero. It also explains the absence of a Java exception.

## Fix

`RG35XXGoldenFrameTransport` is changed to make `RG35XX-FrameWorker` non-daemon. The worker becomes the intended JVM lifetime anchor and remains low priority. Shutdown remains explicit through the transport/process lifecycle.

No changes are made to:

- JamVM L
- GNU Classpath / glibj.zip
- KDTT game JAR
- audio/MIDI policy
- PNG compatibility

The core and runtime must be rebuilt and deployed as one synchronized pair before device acceptance.

## Acceptance

Do not call this stable until RG35XX confirms all of:

1. Java remains alive after startup.
2. Native receives a valid 16-byte frame header.
3. At least one RGB565 frame is published and presented.
4. KDTT displays visible graphics and remains responsive.
5. No regression to the old JamVM CHECKCAST crash.
