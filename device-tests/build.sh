#!/bin/sh
set -eu

RUNTIME_JAR=${FREEJ2ME_RUNTIME_JAR:-}
OUT=${OUT:-./device-tests/out}
[ -n "$RUNTIME_JAR" ] || { echo "FREEJ2ME_RUNTIME_JAR is required" >&2; exit 1; }
[ -f "$RUNTIME_JAR" ] || { echo "runtime jar missing: $RUNTIME_JAR" >&2; exit 1; }
command -v javac >/dev/null 2>&1 || { echo "javac required" >&2; exit 1; }
command -v javap >/dev/null 2>&1 || { echo "javap required" >&2; exit 1; }
command -v jar >/dev/null 2>&1 || { echo "jar required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/device/classes" "$OUT/device/res" "$OUT/switch/classes"

python3 - "$OUT/device/res" <<'PY'
from pathlib import Path
import wave, math, struct, zlib, sys
res=Path(sys.argv[1]); res.mkdir(parents=True, exist_ok=True)
sr=8000
with wave.open(str(res/'test.wav'),'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    frames=bytearray()
    for i in range(int(sr*0.6)):
        frames += struct.pack('<h', int(10000*math.sin(2*math.pi*440*i/sr)))
    w.writeframes(frames)
track=bytearray()
def vlq(n):
    b=[n&0x7f]; n>>=7
    while n: b.append((n&0x7f)|0x80); n>>=7
    return bytes(reversed(b))
track += b'\x00\xff\x51\x03\x07\xa1\x20'
for note in (60,64,67,72):
    track += b'\x00\x90'+bytes([note,90]); track += vlq(96)+b'\x80'+bytes([note,0])
track += b'\x00\xff\x2f\x00'
(res/'test.mid').write_bytes(b'MThd'+struct.pack('>IHHH',6,0,1,96)+b'MTrk'+struct.pack('>I',len(track))+track)
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
W=24; H=24; raw=bytearray()
for y in range(H):
    raw.append(0)
    for x in range(W): raw.append(((x//6)+(y//6))&1)
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',W,H,8,3,0,0,0))+chunk(b'PLTE',bytes([255,0,0,0,255,0]))+chunk(b'tRNS',bytes([0,255]))+chunk(b'IDAT',zlib.compress(bytes(raw),9))+chunk(b'IEND',b'')
(res/'trns.png').write_bytes(png)
W=32; H=24; raw=bytearray()
for y in range(H):
    raw.append(0)
    for x in range(W):
        on=(x<20 and 6<=y<18) or (x>=16 and abs(y-12)<=(x-16)//2)
        raw += bytes([255,209,102,255]) if on else bytes([0,0,0,0])
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',W,H,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(raw),9))+chunk(b'IEND',b'')
(res/'sprite.png').write_bytes(png)
PY

javac --release 8 -g:none -cp "$RUNTIME_JAR" -d "$OUT/device/classes" device-tests/RG35XXDeviceTest.java
javac --release 8 -g:none -cp "$RUNTIME_JAR" -d "$OUT/switch/classes" device-tests/RG35XXSwitchProbe.java

python3 - "$OUT/device/classes" "$OUT/switch/classes" <<'PY'
from pathlib import Path
import sys
for root in sys.argv[1:]:
    for p in Path(root).rglob('*.class'):
        b=bytearray(p.read_bytes())
        if b[:4] != b'\xca\xfe\xba\xbe': raise SystemExit('bad class '+str(p))
        if int.from_bytes(b[6:8],'big') != 52: raise SystemExit('unexpected initial major '+str(p))
        b[6:8]=(50).to_bytes(2,'big')
        p.write_bytes(b)
PY

for c in "$OUT"/device/classes/*.class "$OUT"/switch/classes/*.class; do
    javap -verbose "$c" | grep -q 'major version: 50'
    if javap -verbose "$c" | grep -Eq 'InvokeDynamic|MethodHandle|MethodType'; then
        echo "unsupported constant-pool entry: $c" >&2; exit 1
    fi
done

cp "$OUT/device/res"/* "$OUT/device/classes/"
cat > "$OUT/device/MANIFEST.MF" <<'EOF'
Manifest-Version: 1.0
MIDlet-1: RG35XX RC1 Device Test,,RG35XXDeviceTest
MIDlet-Name: RG35XX RC1 Device Test
MIDlet-Vendor: RG35XX Java Platform
MIDlet-Version: 1.0.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
EOF
cat > "$OUT/switch/MANIFEST.MF" <<'EOF'
Manifest-Version: 1.0
MIDlet-1: RG35XX RC1 Switch Probe,,RG35XXSwitchProbe
MIDlet-Name: RG35XX RC1 Switch Probe
MIDlet-Vendor: RG35XX Java Platform
MIDlet-Version: 1.0.0
MicroEdition-Configuration: CLDC-1.1
MicroEdition-Profile: MIDP-2.0
EOF
jar cfm "$OUT/RG35XX_RC1_Device_Test.jar" "$OUT/device/MANIFEST.MF" -C "$OUT/device/classes" .
jar cfm "$OUT/RG35XX_RC1_Switch_Probe.jar" "$OUT/switch/MANIFEST.MF" -C "$OUT/switch/classes" .
sha256sum "$OUT/RG35XX_RC1_Device_Test.jar" "$OUT/RG35XX_RC1_Switch_Probe.jar" > "$OUT/SHA256SUMS"
echo "RC1 direct-device MIDlet build PASS"
cat "$OUT/SHA256SUMS"
