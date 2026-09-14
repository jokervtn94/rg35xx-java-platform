param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$SdRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedFoundationCore = 'fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062'
$PackageRoot = Split-Path -Parent $PSScriptRoot
$PayloadRoot = Join-Path $PackageRoot 'payload'
$RuntimeSrc = Join-Path $PayloadRoot 'freej2me-lr.jar'
$RuntimeShaFile = Join-Path $PayloadRoot 'RUNTIME-SHA256.txt'

function Fail([string]$Message) { throw "NOMASK-AB INSTALL FAIL: $Message" }
function Get-Sha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "missing file: $Path" }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Resolve-SdRoot([string]$Raw) {
    if ([string]::IsNullOrWhiteSpace($Raw)) { $Raw = Read-Host 'Nhap o dia SD (vi du G, G: hoac G:\)' }
    $Raw = $Raw.Trim().Trim('"')
    if ($Raw -match '^[A-Za-z]$') { $Raw = "$Raw`:" }
    if ($Raw -match '^[A-Za-z]:$') { $Raw = "$Raw\" }
    if (-not (Test-Path -LiteralPath $Raw -PathType Container)) { Fail "SD root not found: $Raw" }
    $resolved = (Resolve-Path -LiteralPath $Raw).Path
    if ($resolved -notmatch '^[A-Za-z]:\\?$') { Fail "refusing non-drive-root path: $resolved" }
    return ($resolved.TrimEnd('\') + '\')
}

$Sd = Resolve-SdRoot $SdRoot
Write-Host "[1/6] SD root: $Sd"

$jamvmSha = Get-Sha256 (Join-Path $Sd 'CFW\java\bin\jamvm')
$glibjSha = Get-Sha256 (Join-Path $Sd 'CFW\java\share\classpath\glibj.zip')
$corePath = Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$coreSha = Get-Sha256 $corePath
if ($jamvmSha -ne $ExpectedJamvm) { Fail "JamVM mismatch expected=$ExpectedJamvm actual=$jamvmSha" }
if ($glibjSha -ne $ExpectedGlibj) { Fail "glibj mismatch expected=$ExpectedGlibj actual=$glibjSha" }
if ($coreSha -ne $ExpectedFoundationCore) { Fail "foundation core mismatch expected=$ExpectedFoundationCore actual=$coreSha" }
Write-Host '[2/6] Foundation dependencies/core: VERIFIED'

if (-not (Test-Path -LiteralPath $RuntimeShaFile -PathType Leaf)) { Fail 'RUNTIME-SHA256.txt missing' }
$expectedRuntime = (Get-Content -LiteralPath $RuntimeShaFile -Raw).Trim().ToLowerInvariant()
if ($expectedRuntime -notmatch '^[0-9a-f]{64}$') { Fail 'invalid runtime SHA file' }
$payloadSha = Get-Sha256 $RuntimeSrc
if ($payloadSha -ne $expectedRuntime) { Fail "runtime payload mismatch expected=$expectedRuntime actual=$payloadSha" }
Write-Host '[3/6] A/B runtime payload: VERIFIED'

$targets = @(
    'BIOS\freej2me-lr.jar',
    'BIOS\freej2me_plus-lr.jar',
    'CFW\java\share\freej2me\freej2me-lr.jar',
    'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
    'CFW\retroarch\system\freej2me-lr.jar'
)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $Sd "RG35XX-JAVA-BACKUP\from-zero-nomask-ab-$stamp"
$created = New-Object System.Collections.Generic.List[string]
$backed = New-Object System.Collections.Generic.List[object]

try {
    Write-Host "[4/6] Backup runtime files: $backupRoot"
    foreach ($rel in $targets) {
        $dst = Join-Path $Sd $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        if (Test-Path -LiteralPath $dst -PathType Leaf) {
            $bak = Join-Path $backupRoot $rel
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak) | Out-Null
            Copy-Item -LiteralPath $dst -Destination $bak -Force
            $backed.Add(@{Dst=$dst; Bak=$bak})
        } else { $created.Add($dst) }
    }

    Write-Host '[5/6] Atomic runtime stage + verify + commit'
    foreach ($rel in $targets) {
        $dst = Join-Path $Sd $rel
        $tmp = "$dst.nomask-ab-new"
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        Copy-Item -LiteralPath $RuntimeSrc -Destination $tmp -Force
        if ((Get-Sha256 $tmp) -ne $expectedRuntime) { Fail "staged runtime mismatch: $rel" }
        Move-Item -LiteralPath $tmp -Destination $dst -Force
        if ((Get-Sha256 $dst) -ne $expectedRuntime) { Fail "committed runtime mismatch: $rel" }
    }

    $result = Join-Path $Sd 'RG35XX-FROM-ZERO-NOMASK-AB-INSTALL-RESULT.txt'
    @(
        'RG35XX FROM-ZERO NOMASK A/B INSTALL RESULT',
        'STATUS=INSTALL-PASS_DEVICE-AB-TEST-PENDING',
        "TIME=$((Get-Date).ToString('s'))",
        "SD_ROOT=$Sd",
        "RUNTIME_SHA256=$expectedRuntime",
        "PRESERVED_CORE_SHA256=$coreSha",
        "JAMVM_L_SHA256=$jamvmSha",
        "GLIBJ_SHA256=$glibjSha",
        "BACKUP=$backupRoot",
        'CHANGE=PLATFORMGRAPHICS_LCD_MASK_SUPPRESSED_ONLY',
        'AUDIO=UNCHANGED',
        'FONT=UNCHANGED',
        'TRANSPARENCY=UNCHANGED'
    ) | Set-Content -LiteralPath $result -Encoding ASCII
    Write-Host '[6/6] INSTALL PASS - test Real Football first, then one normal title.'
    Write-Host "Result: $result"
}
catch {
    Write-Warning "Install failed; rolling back: $($_.Exception.Message)"
    foreach ($rel in $targets) {
        $dst = Join-Path $Sd $rel
        $tmp = "$dst.nomask-ab-new"
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
    foreach ($p in $created) { if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } }
    foreach ($b in $backed) {
        if (Test-Path -LiteralPath $b.Bak) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $b.Dst) | Out-Null
            Copy-Item -LiteralPath $b.Bak -Destination $b.Dst -Force
        }
    }
    throw
}
