param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm   = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj   = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore    = '56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedRuntime = 'cb8926539749535a53cb4a627e814e198aaa0eba3cce8cac1bb213957e37189b'

$PayloadRoot = Join-Path $PSScriptRoot 'payload'
$RuntimeSrc = Join-Path $PayloadRoot 'freej2me-lr-vc7r22.jar'

function Fail([string]$Message) { throw "GARLICOS JAVA BASELINE V1.3 INSTALL FAIL: $Message" }

function Get-Sha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Resolve-SdRoot([string]$Raw) {
    if ([string]::IsNullOrWhiteSpace($Raw)) { $Raw = Read-Host 'Nhap o dia SD RG35XX (vi du G, G: hoac G:\)' }
    $Raw = $Raw.Trim().Trim('"')
    if ($Raw -match '^[A-Za-z]$') { $Raw = $Raw + ':' }
    if ($Raw -match '^[A-Za-z]:$') { $Raw = $Raw + '\' }
    if (-not (Test-Path -LiteralPath $Raw -PathType Container)) { Fail "SD root not found: $Raw" }
    $resolved = (Resolve-Path -LiteralPath $Raw).Path
    $trimmed = $resolved.TrimEnd('\')
    if ($trimmed.Length -ne 2 -or $trimmed[1] -ne ':') { Fail "Refusing non-drive-root path: $resolved" }
    return ($trimmed + '\')
}

$Sd = Resolve-SdRoot $SdRoot
Write-Host "[1/7] SD root: $Sd"

$jamvm = Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj = Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$core = Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'

$jamvmSha = Get-Sha $jamvm
$glibjSha = Get-Sha $glibj
$coreSha = Get-Sha $core

if ($jamvmSha -ne $ExpectedJamvm) { Fail "JamVM mismatch expected=$ExpectedJamvm actual=$jamvmSha" }
if ($glibjSha -ne $ExpectedGlibj) { Fail "glibj mismatch expected=$ExpectedGlibj actual=$glibjSha" }
if ($coreSha -ne $ExpectedCore) { Fail "Core mismatch expected=$ExpectedCore actual=$coreSha" }
Write-Host '[2/7] JamVM + glibj + current B4 core: VERIFIED / CORE WILL NOT BE MODIFIED'

if ((Get-Sha $RuntimeSrc) -ne $ExpectedRuntime) { Fail 'VC7R22 runtime payload SHA mismatch' }
Write-Host '[3/7] VC7R22 runtime payload: VERIFIED'

$targets = @(
    'BIOS\freej2me-lr.jar',
    'BIOS\freej2me_plus-lr.jar',
    'CFW\java\share\freej2me\freej2me-lr.jar',
    'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
    'CFW\retroarch\system\freej2me-lr.jar'
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $Sd "RG35XX-JAVA-BACKUP\garlicos-java-baseline-v1.3-$stamp"
$backupSd = Join-Path $backupRoot 'sd'
$statePath = Join-Path $backupRoot 'STATE.txt'
New-Item -ItemType Directory -Force -Path $backupSd | Out-Null
$state = New-Object System.Collections.Generic.List[string]

foreach ($rel in $targets) {
    $src = Join-Path $Sd $rel
    if (Test-Path -LiteralPath $src -PathType Leaf) {
        $bak = Join-Path $backupSd $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak) | Out-Null
        Copy-Item -LiteralPath $src -Destination $bak -Force
        $state.Add("EXISTED|$rel")
    } else {
        $state.Add("ABSENT|$rel")
    }
}
$state | Set-Content -LiteralPath $statePath -Encoding ASCII
Write-Host "[4/7] Runtime aliases backed up: $backupRoot"

try {
    foreach ($rel in $targets) {
        $dst = Join-Path $Sd $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        $tmp = $dst + '.vc7r22-new'
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        Copy-Item -LiteralPath $RuntimeSrc -Destination $tmp -Force
        if ((Get-Sha $tmp) -ne $ExpectedRuntime) { Fail "Staged runtime SHA mismatch: $rel" }
        Move-Item -LiteralPath $tmp -Destination $dst -Force
        if ((Get-Sha $dst) -ne $ExpectedRuntime) { Fail "Installed runtime SHA mismatch: $rel" }
    }
    Write-Host '[5/7] VC7R22 runtime installed to canonical aliases'

    foreach ($name in @('freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log','freej2me-java-control.log')) {
        $p = Join-Path $Sd $name
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            Copy-Item -LiteralPath $p -Destination (Join-Path $backupRoot $name) -Force
            Remove-Item -LiteralPath $p -Force
        }
    }
    Write-Host '[6/7] Previous evidence logs backed up and cleared'

    $javaRoot = Join-Path $Sd 'Roms\JAVA'
    $jarCount = 0
    if (Test-Path -LiteralPath $javaRoot -PathType Container) {
        $jarCount = @(Get-ChildItem -LiteralPath $javaRoot -Filter '*.jar' -File -Recurse).Count
    }

    $report = Join-Path $Sd 'RG35XX-GARLICOS-JAVA-BASELINE-V1.3-INSTALL-RESULT.txt'
    @(
        'RG35XX GARLICOS JAVA BASELINE V1.3 RUNTIME RESTORE',
        'STATUS=INSTALL-PASS_DEVICE-GAME-TEST-PENDING',
        "TIME=$((Get-Date).ToString('s'))",
        "SD_ROOT=$Sd",
        "BACKUP=$backupRoot",
        "JAMVM_SHA256=$jamvmSha",
        "GLIBJ_SHA256=$glibjSha",
        "CORE_SHA256=$coreSha",
        "RUNTIME_SHA256=$ExpectedRuntime",
        "ROMS_JAVA_JAR_COUNT=$jarCount",
        'PRIMARY_VARIABLE=JAVA_RUNTIME_B4_TO_VC7R22',
        'CORE_CHANGE=NONE',
        'VC7R15_LCD_MASK_GATE_FIX=RESTORED_IN_RUNTIME',
        'VC7R21_GRAPHICS_LINEAGE=PRESERVED_IN_RUNTIME',
        'VC7R22_HOTPATH_CLEANUP=RESTORED_IN_RUNTIME',
        'LAZY_MEDIA_BOOT=PRESERVED',
        'APP_WRAPPERS=NO',
        'R1_5_INCLUDED=NO',
        'FULL_PLATFORM_STABLE=NO',
        'RESULT=PASS'
    ) | Set-Content -LiteralPath $report -Encoding ASCII

    Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-GARLICOS-JAVA-BASELINE-V1.3-CURRENT-BACKUP.txt') -Value $backupRoot -Encoding ASCII
    Write-Host '[7/7] INSTALL PASS'
    Write-Host 'Test the same JAR directly from GarlicOS -> JAVA.'
}
catch {
    Write-Warning "Install failed; rolling back runtime aliases: $($_.Exception.Message)"
    foreach ($line in Get-Content -LiteralPath $statePath) {
        $parts = $line.Split('|',2)
        if ($parts.Count -ne 2) { continue }
        $kind=$parts[0]; $rel=$parts[1]
        $dst=Join-Path $Sd $rel
        $bak=Join-Path $backupSd $rel
        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue }
        if ($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            Copy-Item -LiteralPath $bak -Destination $dst -Force
        }
    }
    throw
}
