#!/usr/bin/env python3
import hashlib
import re
import sys
import zipfile

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-miyoo-full-port-r1.py <zip>')
path = sys.argv[1]
expected = {
    'SD/Roms/APPS/FreeJ2ME-RG35XX/freej2me-rg35xx.jar': 'b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/librg35xx_input.so': '6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/librg35xx_video.so': 'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/librg35xx_font.so': '29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/libaudio.so': '4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/font.ttf': '1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
    'SD/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/bin/jamvm': '0d10011c35b791ac5670ef9f01e3dc888c4b6621c8df4b06a5460ac9072739e3',
    'SD/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/share/classpath/glibj.zip': 'c85b3af3728c89c090bf5feccdf402fc86474e99a2d61fd02142aa3c89964fd4',
    'SD/Roms/APPS/RG35XX-RUNTIME-CANDIDATE-PROBE/runtime/share/jamvm/classes.zip': 'ce27c0a0bbdacf7c3f0c4f3a2edbc40b5f7892c17b785b1f89f32fd53ef3af86',
}
required_suffixes = [
    'SD/Roms/APPS/FreeJ2ME-RG35XX.sh',
    'SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/FULL-PORT-R1-IDENTITY.txt',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Platform-Exerciser-P1A.jar',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Platform-Exerciser-P2A-Image.jar',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Platform-Exerciser-P2B-FontText.jar',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Platform-Exerciser-P2C-InputFrontend.jar',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Platform-Exerciser-P3-RuntimeService.jar',
    'SD/Roms/APPS/FreeJ2ME-RG35XX/test/RG35XX-Platform-Exerciser-P6-Integration.jar',
]
with zipfile.ZipFile(path) as z:
    names = z.namelist()
    prefix_candidates = sorted(set(n[:-len('SD/Roms/APPS/FreeJ2ME-RG35XX.sh')] for n in names if n.endswith('SD/Roms/APPS/FreeJ2ME-RG35XX.sh')))
    if len(prefix_candidates) != 1:
        raise SystemExit('R1_GATE_FAIL prefix ambiguity '+repr(prefix_candidates))
    prefix = prefix_candidates[0]
    name_set = set(names)
    for suffix in required_suffixes:
        if prefix + suffix not in name_set:
            raise SystemExit('R1_GATE_FAIL missing '+suffix)
    for suffix, sha in expected.items():
        name = prefix + suffix
        if name not in name_set:
            raise SystemExit('R1_GATE_FAIL missing protected '+suffix)
        got = hashlib.sha256(z.read(name)).hexdigest()
        if got != sha:
            raise SystemExit('R1_GATE_FAIL hash %s got=%s expected=%s' % (suffix, got, sha))
    if any('/CFW/java/' in n or n.endswith('/CFW/java') for n in names):
        raise SystemExit('R1_GATE_FAIL protected CFW/java mutation payload')
    forbidden_native = re.compile(r'(^|/)(libm3g\.so|libmicro3d\.so|[^/]*lwjgl[^/]*\.so)$', re.I)
    bad = [n for n in names if forbidden_native.search(n)]
    if bad:
        raise SystemExit('R1_GATE_FAIL deferred 3D native included '+repr(bad))
    identity = z.read(prefix+'SD/Roms/APPS/FreeJ2ME-RG35XX/FULL-PORT-R1-IDENTITY.txt').decode('utf-8')
    for marker in (
        'CANONICAL_AWEIGIT=ca11dfe8ea1cc273d92460f9a83bbf192023fa63',
        'PRODUCTION_PARENT=8cd4f6b2b08d9fbc009719e4d6148f1726972b7b',
        'M3G_REENABLED=NO', 'MICRO3D_REENABLED=NO', 'LWJGL_OPENGL_REENABLED=NO',
        'P6_ORIGINAL_RG35XX_PHYSICAL=NOT_TESTED', 'DEVICE_PASS=NO', 'STABLE=NO'):
        if marker not in identity:
            raise SystemExit('R1_GATE_FAIL identity marker '+marker)
    for script in ('SD/Roms/APPS/FreeJ2ME-RG35XX.sh','SD/Roms/APPS/RG35XX-FULL-PORT-R1-TEST.sh'):
        text=z.read(prefix+script).decode('utf-8')
        for forbidden in ('Vua Cướp Biển','God of War','BOLACTHOITIENSU'):
            if forbidden.lower() in text.lower():
                raise SystemExit('R1_GATE_FAIL game-specific launcher content')
    jars=[n for n in names if n.startswith(prefix+'SD/Roms/APPS/FreeJ2ME-RG35XX/') and n.endswith('.jar')]
    for jar_name in jars:
        import io
        with zipfile.ZipFile(io.BytesIO(z.read(jar_name))) as j:
            for n in j.namelist():
                if not n.endswith('.class'): continue
                b=j.read(n)
                if len(b)<8 or b[:4] != b'\xca\xfe\xba\xbe':
                    raise SystemExit('R1_GATE_FAIL bad class '+jar_name+' '+n)
                major=int.from_bytes(b[6:8], 'big')
                if major > 50:
                    raise SystemExit('R1_GATE_FAIL Java6 '+jar_name+' '+n+' major='+str(major))
print('FULL_PORT_R1_INDEPENDENT_HASH_GATE=PASS')
print('FULL_PORT_R1_NO_CFW_JAVA_MUTATION=PASS')
print('FULL_PORT_R1_DEFERRED_3D_GATE=PASS')
print('FULL_PORT_R1_JAVA6_GATE=PASS')
print('FULL_PORT_R1_GAME_SPECIFIC_CODE=NO')
print('FULL_PORT_R1_DEVICE_PASS=NO')
print('FULL_PORT_R1_STABLE=NO')
