# MIYOO M1.3A RAW JS0 INPUT BUILD RESULT

- commit SHA: `a91f03ba43ec820c30c2765d1d507ca00a04608d`
- workflow/run ID: `34843946294`
- job ID: `103975217803`
- artifact ID: `10347350526`
- artifact digest: `sha256:1cf29927c09835857f16bad57f246852720c37fec9e1f923acc08d30279ba867`
- raw probe SHA256: `fda395cb48ca6c994a351c649e6efc3b2e1f667b3e152c066caeb11101511cff`
- wrapper SHA256: `e4b08931ad4568c8217f8a7afc84cb28dfb9cd6edf33c89f14099eb7266edc79`
- ELF: ARM ELF32, EABI5, soft-float, interpreter `/lib/ld-uClibc.so.0`
- runtime SHA256: unchanged/not rebuilt; locked installed fallback expected `2cf28cd1832ba964c5db5e67c57e07ec5716bbc0aca88d8365c6188812f5d65b`
- core SHA256: unchanged/not rebuilt; locked installed fallback expected `8939ea7f1ad368f315da8e4ce863270d89e9c51385257d6d58e0a9147e00d29a`
- BUILD-PASS: YES
- DEVICE-PASS: NO
- STABLE: NO
- exact scope of change: standalone read-only direct Linux joystick `/dev/input/js0` probe and GarlicOS wrapper only. No SDL, video, audio, JVM, font, runtime or core behavior changed.

Device pass requires real RG35XX evidence of raw axis/button events during the bounded 20 second window plus unchanged locked fallback hashes before/after.
