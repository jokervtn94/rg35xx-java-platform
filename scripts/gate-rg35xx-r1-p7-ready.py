#!/usr/bin/env python3
import hashlib
import sys
import zipfile

if len(sys.argv) != 2:
    raise SystemExit('usage: gate-rg35xx-r1-p7-ready.py <zip>')
path = sys.argv[1]
expected = {
    'freej2me-rg35xx.jar': 'b5e619eedf0b3efcca6770a46a03d125449ff9aadb59c11b18dc1b95bd6c5117',
    'librg35xx_input.so': '6eaf5e23a63fa346782f35dff340d625238a89db4e54cce56d34ba5db5a4064c',
    'librg35xx_video.so': 'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
    'librg35xx_font.so': '29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
    'libaudio.so': '4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
    'font.ttf': '1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
}
with zipfile.ZipFile(path) as z:
    names = z.namelist()
    roots = {n.split('/', 1)[0] for n in names if '/' in n}
    if roots != {'RG35XX-MIYOO-FULL-PORT-R1-P7-READY'}:
        raise SystemExit('P7_GATE_FAIL root=' + repr(sorted(roots)))
    root = 'RG35XX-MIYOO-FULL-PORT-R1-P7-READY/SD/Roms/APPS/'
    app = root + 'FreeJ2ME-RG35XX/'
    required = [
        root + 'FreeJ2ME-RG35XX.sh',
        root + 'RG35XX-FULL-PORT-R1-TEST.sh',
        root + 'RG35XX-R1-P7-TIER0.sh',
        root + 'RG35XX-R1-P7/P7-TIER0-IDENTITY.txt',
        'RG35XX-MIYOO-FULL-PORT-R1-P7-READY/SD/Roms/JAVA/README-TIER0-EXACT.txt',
        'RG35XX-MIYOO-FULL-PORT-R1-P7-READY/P7-README-FIRST.txt',
    ]
    for n in required:
        if n not in names:
            raise SystemExit('P7_GATE_FAIL missing=' + n)
    for base, sha in expected.items():
        data = z.read(app + base)
        got = hashlib.sha256(data).hexdigest()
        if got != sha:
            raise SystemExit('P7_GATE_FAIL hash %s %s' % (base, got))
    commercial = [n for n in names if n.endswith('/Vua-Cuop-Bien-240x320.jar') or n.endswith('/God-of-War-Betrayal_J2ME_EN_v148.jar')]
    if commercial:
        raise SystemExit('P7_GATE_FAIL commercial=' + repr(commercial))
    launcher = z.read(root + 'RG35XX-R1-P7-TIER0.sh')
    for marker in [
        b'FULL_PORT_R1_PROGRAMMATIC=PASS',
        b'220ac0e6a2ab61318aa3d2e20057e2231991a21d7ca15148ed3c57534b941578',
        b'e256ca47cde2b27735a4f4d3d826003ac5bbc723f91629bd5d093d948c1f9a98',
        b'"$VUA" 240 320',
        b'"$GOW" 240 320',
        b'GOW_AUDIO_AUDIBLE_DEVICE=REQUIRED_MANUAL',
        b'P7_PHYSICAL_REGRESSION=NOT_TESTED',
        b'DEVICE_PASS=NO',
    ]:
        if marker not in launcher:
            raise SystemExit('P7_GATE_FAIL launcher-marker=' + repr(marker))
    identity = z.read(root + 'RG35XX-R1-P7/P7-TIER0-IDENTITY.txt')
    for marker in [
        b'RUNTIME_SEMANTIC_DELTA=NONE',
        b'COMMERCIAL_GAME_CONTENT=NO',
        b'GAME_SPECIFIC_RUNTIME_CODE=NO',
        b'P7_PHYSICAL_REGRESSION=NOT_TESTED',
    ]:
        if marker not in identity:
            raise SystemExit('P7_GATE_FAIL identity-marker=' + repr(marker))
print('P7_READY_INDEPENDENT_GATE=PASS')
print('P7_READY_COMMERCIAL_GAME_CONTENT=NO')
print('P7_READY_RUNTIME_SEMANTIC_DELTA=NONE')
print('P7_READY_PHYSICAL_TEST=NOT_TESTED')
print('P7_READY_DEVICE_PASS=NO')
