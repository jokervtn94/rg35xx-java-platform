#!/usr/bin/env python3
from __future__ import print_function
import argparse, hashlib, os, zipfile

EXPECTED_R1_SHA = '1e78c30c166f2ce4988478d44c476b0bfdf8c6795e433cf8f21ed934796037da'
EXPECTED = {
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/freej2me-rg35xx.jar':'6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4',
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/RG35XX-Platform-Exerciser-P2B-FontText.jar':'c0e3df5e1ab01c99932af19116183990b1b382383397e655ba49f06f070f479e',
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/librg35xx_font.so':'29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b',
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/font.ttf':'1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10',
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/librg35xx_input.so':'69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d',
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/librg35xx_video.so':'c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d',
    'Roms/APPS/RG35XX-P2B-FONT-TEXT/libaudio.so':'4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644',
}
ROOT_R2 = 'RG35XX-P2B-FONT-TEXT-PHYSICAL-R2'
RUNTIME_CANDIDATE='2f18b78e9b0aa1660b7fd2f5904dd697fcef5830'
SOURCE_HEAD='5a8e29dd368bf99b22e81d256691b2a7ec8f1adf'

INSTALL_PS1 = r'''param([string]$SdRoot = "")

$ErrorActionPreference = "Stop"
$exitCode = 1

function Wait-BeforeExit {
    try { [void](Read-Host "Press ENTER to close") } catch { }
}

function Normalize-SdDrive([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "SD drive is empty. Enter a drive letter such as E, E:, or E:\"
    }
    $v = $Value.Trim().Trim([char]34).Trim([char]39)
    if ($v -notmatch '^([A-Za-z])(?::)?(?:\\)?$') {
        throw "Invalid SD drive '$Value'. Enter only a drive letter such as E, E:, or E:\"
    }
    $letter = $Matches[1].ToUpperInvariant()
    $drive = $letter + ':'
    if ($env:SystemDrive -and ($drive -ieq $env:SystemDrive)) {
        throw "Refusing to install to Windows system drive $drive"
    }
    $root = $drive + '\'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw "Drive root does not exist or is not mounted: $root"
    }
    return $root
}

function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required file missing: $Path" }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw "SHA256 mismatch: $Path`nExpected: $Expected`nActual:   $actual"
    }
}

try {
    Write-Host "RG35XX P2B Font/Text physical installer R2" -ForegroundColor Cyan
    Write-Host "SD runtime payload is byte-for-byte identical to physically accepted R1." -ForegroundColor DarkGray
    Write-Host ""
    if ([string]::IsNullOrWhiteSpace($SdRoot)) {
        $SdRoot = Read-Host "Enter RG35XX SD drive letter (example: E, E:, or E:\)"
    }
    $dst = Normalize-SdDrive $SdRoot
    $src = Join-Path $PSScriptRoot "SD"
    if (-not (Test-Path -LiteralPath $src -PathType Container)) { throw "SD payload missing next to installer: $src" }
    $payload = Join-Path $src "Roms\APPS\RG35XX-P2B-FONT-TEXT"
    Assert-Hash (Join-Path $payload "freej2me-rg35xx.jar") "6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4"
    Assert-Hash (Join-Path $payload "RG35XX-Platform-Exerciser-P2B-FontText.jar") "c0e3df5e1ab01c99932af19116183990b1b382383397e655ba49f06f070f479e"
    Assert-Hash (Join-Path $payload "librg35xx_font.so") "29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b"
    Assert-Hash (Join-Path $payload "font.ttf") "1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10"
    Assert-Hash (Join-Path $payload "librg35xx_input.so") "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d"
    Assert-Hash (Join-Path $payload "librg35xx_video.so") "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"
    Assert-Hash (Join-Path $payload "libaudio.so") "4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644"
    Write-Host "Payload SHA256 precheck: PASS" -ForegroundColor Green
    Write-Host "Installing to: $dst"
    Get-ChildItem -LiteralPath $src -Force | Copy-Item -Destination $dst -Recurse -Force
    $installed = Join-Path $dst "Roms\APPS\RG35XX-P2B-FONT-TEXT"
    Assert-Hash (Join-Path $installed "freej2me-rg35xx.jar") "6be579996cfe8f0930034cae33920027fb2576817225ab45b7757009fa6c8ff4"
    Assert-Hash (Join-Path $installed "RG35XX-Platform-Exerciser-P2B-FontText.jar") "c0e3df5e1ab01c99932af19116183990b1b382383397e655ba49f06f070f479e"
    Assert-Hash (Join-Path $installed "librg35xx_font.so") "29d19de922e9b3b24b93dca2db73886a32fd9e51ef1c9215b820d12324b8c84b"
    Assert-Hash (Join-Path $installed "font.ttf") "1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10"
    Assert-Hash (Join-Path $installed "librg35xx_input.so") "69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d"
    Assert-Hash (Join-Path $installed "librg35xx_video.so") "c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d"
    Assert-Hash (Join-Path $installed "libaudio.so") "4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644"
    $launcher = Join-Path $dst "Roms\APPS\RG35XX-P2B-FONT-TEXT.sh"
    if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw "Launcher missing after copy: $launcher" }
    Write-Host ""
    Write-Host "INSTALL_RESULT=PASS" -ForegroundColor Green
    Write-Host "Installed and verified RG35XX P2B Font/Text package on $dst" -ForegroundColor Green
    Write-Host "Safely eject the SD card, boot the original RG35XX, then launch RG35XX-P2B-FONT-TEXT from GarlicOS Apps."
    $exitCode = 0
} catch {
    Write-Host ""
    Write-Host "INSTALL_RESULT=FAIL" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $exitCode = 1
} finally {
    Write-Host ""
    Wait-BeforeExit
}
exit $exitCode
'''

COLLECT_PS1 = r'''param(
  [string]$SdRoot = "",
  [string]$Output = (Join-Path $PSScriptRoot "RG35XX-P2B-FONT-TEXT-EVIDENCE")
)
$ErrorActionPreference = "Stop"
$exitCode = 1
function Wait-BeforeExit { try { [void](Read-Host "Press ENTER to close") } catch { } }
function Normalize-SdDrive([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { throw "SD drive is empty. Enter a drive letter such as E, E:, or E:\" }
    $v = $Value.Trim().Trim([char]34).Trim([char]39)
    if ($v -notmatch '^([A-Za-z])(?::)?(?:\\)?$') { throw "Invalid SD drive '$Value'. Enter only a drive letter such as E, E:, or E:\" }
    $root = $Matches[1].ToUpperInvariant() + ':\'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Drive root does not exist or is not mounted: $root" }
    return $root
}
try {
    Write-Host "RG35XX P2B Font/Text evidence collector" -ForegroundColor Cyan
    if ([string]::IsNullOrWhiteSpace($SdRoot)) { $SdRoot = Read-Host "Enter RG35XX SD drive letter (example: E, E:, or E:\)" }
    $root = Normalize-SdDrive $SdRoot
    $src = Join-Path $root "RG35XX-P2B-FONT-TEXT-EVIDENCE"
    if (-not (Test-Path -LiteralPath $src -PathType Container)) { throw "Evidence directory missing: $src" }
    if (Test-Path -LiteralPath $Output) { Remove-Item -LiteralPath $Output -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $Output -Recurse -Force
    Write-Host "EVIDENCE_COLLECT_RESULT=PASS" -ForegroundColor Green
    Write-Host "Collected evidence to $Output" -ForegroundColor Green
    $exitCode = 0
} catch {
    Write-Host "EVIDENCE_COLLECT_RESULT=FAIL" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $exitCode = 1
} finally {
    Write-Host ""
    Wait-BeforeExit
}
exit $exitCode
'''

INSTALL_CMD='''@echo off\r\nsetlocal\r\ncd /d "%~dp0"\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL-RG35XX-P2B-FONT-TEXT.ps1"\r\nexit /b %ERRORLEVEL%\r\n'''
COLLECT_CMD='''@echo off\r\nsetlocal\r\ncd /d "%~dp0"\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT-RG35XX-P2B-FONT-TEXT-EVIDENCE.ps1"\r\nexit /b %ERRORLEVEL%\r\n'''
README=f'''RG35XX P2B FONT/TEXT PHYSICAL MODULE R2\n========================================\n\nR2 is an installer/evidence-helper hygiene revision only.\nThe complete SD/ runtime payload is byte-for-byte identical to the physically accepted R1 payload.\nRuntime candidate: {RUNTIME_CANDIDATE}\n\nAccepted physical evidence for R1:\n  360/360 cases PASS\n  green PASS screen observed\n  normal return to GarlicOS observed\n\nWindows install:\n  Double-click INSTALL-RG35XX-P2B-FONT-TEXT.cmd\n  Enter the SD drive as E, E:, or E:\\\n  The installer rejects the Windows system drive, validates exact payload hashes,\n  copies SD/ to the SD root, verifies hashes again, and waits before closing.\n\nManual install remains valid:\n  Copy the CONTENTS of SD/ to the root of the RG35XX SD card, preserving paths.\n\nEvidence collector:\n  Double-click COLLECT-RG35XX-P2B-FONT-TEXT-EVIDENCE.cmd\n\nAcceptance boundary:\n  P2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS\n  RG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO\n  STABLE=NO\n  GAME_SPECIFIC_CODE=NO\n  A9_PARENT=NO\n'''

def sha(b): return hashlib.sha256(b).hexdigest()
def file_sha(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''): h.update(chunk)
    return h.hexdigest()

def sd_manifest(entries):
    rows=[]
    for rel,b in sorted(entries.items()): rows.append(rel+'\0'+sha(b)+'\n')
    return hashlib.sha256(''.join(rows).encode('utf-8')).hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('input_r1')
    ap.add_argument('output_r2')
    a=ap.parse_args()
    actual=file_sha(a.input_r1)
    if actual != EXPECTED_R1_SHA:
        raise SystemExit('P2B_R2_INPUT_R1_SHA_GATE=FAIL expected=%s actual=%s'%(EXPECTED_R1_SHA,actual))
    with zipfile.ZipFile(a.input_r1,'r') as zin:
        files={n:zin.read(n) for n in zin.namelist() if not n.endswith('/')}
    roots=sorted(set(n.split('/',1)[0] for n in files))
    if len(roots)!=1: raise SystemExit('P2B_R2_INPUT_ROOT_GATE=FAIL roots=%r'%roots)
    root=roots[0]
    sd={n.split('/SD/',1)[1]:b for n,b in files.items() if n.startswith(root+'/SD/')}
    if not sd: raise SystemExit('P2B_R2_SD_PAYLOAD_GATE=FAIL missing')
    for rel,expected in EXPECTED.items():
        if rel not in sd: raise SystemExit('P2B_R2_KEY_FILE_GATE=FAIL missing='+rel)
        if sha(sd[rel])!=expected: raise SystemExit('P2B_R2_KEY_FILE_GATE=FAIL hash='+rel)
    manifest_before=sd_manifest(sd)
    out={}
    for n,b in files.items():
        rel=n.split('/',1)[1]
        out[ROOT_R2+'/'+rel]=b
    def put(name, text, encoding='utf-8'):
        out[ROOT_R2+'/'+name]=text.encode(encoding)
    put('INSTALL-RG35XX-P2B-FONT-TEXT.ps1',INSTALL_PS1)
    put('COLLECT-RG35XX-P2B-FONT-TEXT-EVIDENCE.ps1',COLLECT_PS1)
    put('INSTALL-RG35XX-P2B-FONT-TEXT.cmd',INSTALL_CMD)
    put('COLLECT-RG35XX-P2B-FONT-TEXT-EVIDENCE.cmd',COLLECT_CMD)
    put('README-FIRST.txt',README)
    identity=f'''PROJECT=RG35XX-AWEIGIT-R1\nMODULE=P2B_FONT_TEXT\nPACKAGE=RG35XX-P2B-FONT-TEXT-PHYSICAL-R2\nSOURCE_R1_PACKAGE_SHA256={EXPECTED_R1_SHA}\nSOURCE_PHYSICAL_BRANCH_HEAD={SOURCE_HEAD}\nRUNTIME_CANDIDATE_COMMIT={RUNTIME_CANDIDATE}\nCHANGE_SCOPE=WINDOWS_INSTALLER_AND_EVIDENCE_HELPERS_ONLY\nSD_MANIFEST_SHA256={manifest_before}\nSD_RUNTIME_PAYLOAD_DELTA=NONE\nRUNTIME_SEMANTIC_DELTA=NONE\nP2B_FONT_TEXT_MODULE_PHYSICAL_ACCEPTANCE=PASS\nRG35XX_PLATFORM_BASELINE_DEVICE_PASS=NO\nSTABLE=NO\nGAME_SPECIFIC_CODE=NO\nA9_PARENT=NO\n'''
    put('WINDOWS-INSTALLER-R2-IDENTITY.txt',identity)
    sd_after={n.split('/SD/',1)[1]:b for n,b in out.items() if n.startswith(ROOT_R2+'/SD/')}
    manifest_after=sd_manifest(sd_after)
    if sd != sd_after or manifest_before != manifest_after:
        raise SystemExit('P2B_R2_SD_PAYLOAD_DELTA=FAIL')
    os.makedirs(os.path.dirname(os.path.abspath(a.output_r2)), exist_ok=True)
    fixed_date=(2026,10,3,0,0,0)
    with zipfile.ZipFile(a.output_r2,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as zout:
        for n in sorted(out):
            zi=zipfile.ZipInfo(n, fixed_date)
            zi.compress_type=zipfile.ZIP_DEFLATED
            zi.external_attr=(0o644 & 0xFFFF)<<16
            zout.writestr(zi,out[n])
    print('P2B_R2_INPUT_R1_SHA_GATE=PASS')
    print('P2B_R2_KEY_PAYLOAD_HASH_GATE=PASS')
    print('P2B_R2_SD_MANIFEST_SHA256='+manifest_after)
    print('P2B_R2_SD_RUNTIME_PAYLOAD_DELTA=NONE')
    print('P2B_R2_RUNTIME_SEMANTIC_DELTA=NONE')
    print('P2B_R2_PACKAGE_SHA256='+file_sha(a.output_r2))
    print('P2B_R2_PACKAGE_BUILD=PASS')

if __name__=='__main__': main()
