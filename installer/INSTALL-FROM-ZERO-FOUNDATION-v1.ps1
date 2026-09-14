param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$SdRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$PackageRoot = Split-Path -Parent $PSScriptRoot
$PayloadRoot = Join-Path $PackageRoot 'payload'
$ManifestPath = Join-Path $PayloadRoot 'SHA256SUMS.txt'

function Fail([string]$Message) {
    throw "FROM-ZERO INSTALL FAIL: $Message"
}

function Get-Sha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "missing file: $Path" }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Resolve-SdRoot([string]$Raw) {
    if ([string]::IsNullOrWhiteSpace($Raw)) {
        $Raw = Read-Host 'Nhap o dia SD (vi du G, G: hoac G:\)'
    }
    $Raw = $Raw.Trim().Trim('"')
    if ($Raw -match '^[A-Za-z]$') { $Raw = "$Raw`:" }
    if ($Raw -match '^[A-Za-z]:$') { $Raw = "$Raw\" }
    if (-not (Test-Path -LiteralPath $Raw -PathType Container)) { Fail "SD root not found: $Raw" }
    $resolved = (Resolve-Path -LiteralPath $Raw).Path
    if ($resolved -notmatch '^[A-Za-z]:\\?$') {
        Fail "refusing non-drive-root path: $resolved. Pass a drive letter such as G, G: or G:\"
    }
    return ($resolved.TrimEnd('\') + '\')
}

function Read-Manifest([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "payload manifest missing: $Path" }
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $line = $line.Trim()
        if (-not $line) { continue }
        if ($line -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') { Fail "invalid manifest line: $line" }
        $rel = $matches[2].Replace('/','\')
        $map[$rel] = $matches[1].ToLowerInvariant()
    }
    return $map
}

function Verify-Payload([hashtable]$Manifest) {
    foreach ($rel in $Manifest.Keys) {
        $p = Join-Path $PayloadRoot $rel
        $actual = Get-Sha256 $p
        if ($actual -ne $Manifest[$rel]) { Fail "payload SHA mismatch: $rel expected=$($Manifest[$rel]) actual=$actual" }
    }
}

$Sd = Resolve-SdRoot $SdRoot
Write-Host "[1/6] SD root: $Sd"

$jamvm = Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj = Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$jamvmSha = Get-Sha256 $jamvm
$glibjSha = Get-Sha256 $glibj
if ($jamvmSha -ne $ExpectedJamvm) { Fail "JamVM L is not the device-proven binary. expected=$ExpectedJamvm actual=$jamvmSha" }
if ($glibjSha -ne $ExpectedGlibj) { Fail "glibj.zip is not the pinned baseline. expected=$ExpectedGlibj actual=$glibjSha" }
Write-Host '[2/6] JamVM L + glibj: VERIFIED'

$manifest = Read-Manifest $ManifestPath
Verify-Payload $manifest
Write-Host '[3/6] Package payload hashes: VERIFIED'

$runtimeSrc = Join-Path $PayloadRoot 'BIOS\freej2me-lr.jar'
$coreSrc = Join-Path $PayloadRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$runtimeRel = 'BIOS\freej2me-lr.jar'
$coreRel = 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
if (-not $manifest.ContainsKey($runtimeRel)) { Fail "manifest missing $runtimeRel" }
if (-not $manifest.ContainsKey($coreRel)) { Fail "manifest missing $coreRel" }
$runtimeSha = $manifest[$runtimeRel]
$coreSha = $manifest[$coreRel]

$targets = @(
    @{ Source=$coreSrc; Sha=$coreSha; Rel='CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so' },
    @{ Source=$coreSrc; Sha=$coreSha; Rel='CFW\retroarch\.retroarch\cores\freej2me_libretro.so' },
    @{ Source=$runtimeSrc; Sha=$runtimeSha; Rel='BIOS\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$runtimeSha; Rel='BIOS\freej2me_plus-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$runtimeSha; Rel='CFW\java\share\freej2me\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$runtimeSha; Rel='CFW\retroarch\.retroarch\system\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$runtimeSha; Rel='CFW\retroarch\system\freej2me-lr.jar' }
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $Sd "RG35XX-JAVA-BACKUP\from-zero-foundation-v1-$stamp"
$created = New-Object System.Collections.Generic.List[string]
$backed = New-Object System.Collections.Generic.List[object]

try {
    Write-Host "[4/6] Backup: $backupRoot"
    foreach ($t in $targets) {
        $dst = Join-Path $Sd $t.Rel
        $dir = Split-Path -Parent $dst
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        if (Test-Path -LiteralPath $dst -PathType Leaf) {
            $bak = Join-Path $backupRoot $t.Rel
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak) | Out-Null
            Copy-Item -LiteralPath $dst -Destination $bak -Force
            $backed.Add(@{Dst=$dst; Bak=$bak})
        } else {
            $created.Add($dst)
        }
    }

    Write-Host '[5/6] Atomic stage + verify + commit'
    foreach ($t in $targets) {
        $dst = Join-Path $Sd $t.Rel
        $tmp = "$dst.from-zero-new"
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        Copy-Item -LiteralPath $t.Source -Destination $tmp -Force
        $actual = Get-Sha256 $tmp
        if ($actual -ne $t.Sha) { Fail "staged SHA mismatch: $($t.Rel) expected=$($t.Sha) actual=$actual" }
        Move-Item -LiteralPath $tmp -Destination $dst -Force
        $final = Get-Sha256 $dst
        if ($final -ne $t.Sha) { Fail "committed SHA mismatch: $($t.Rel) expected=$($t.Sha) actual=$final" }
    }

    $result = Join-Path $Sd 'RG35XX-FROM-ZERO-INSTALL-RESULT.txt'
    @(
        'RG35XX FROM-ZERO FOUNDATION V1 INSTALL RESULT',
        'STATUS=INSTALL-PASS_DEVICE-TEST-PENDING',
        "TIME=$((Get-Date).ToString('s'))",
        "SD_ROOT=$Sd",
        "JAMVM_L_SHA256=$jamvmSha",
        "GLIBJ_SHA256=$glibjSha",
        "RUNTIME_SHA256=$runtimeSha",
        "CORE_SHA256=$coreSha",
        "BACKUP=$backupRoot",
        'AUDIO_GOLDEN=DEFERRED',
        'FONT_GOLDEN=DEFERRED',
        'TRANSPARENCY_EXTENSIONS=DEFERRED'
    ) | Set-Content -LiteralPath $result -Encoding ASCII

    Write-Host '[6/6] INSTALL PASS'
    Write-Host "Result: $result"
    Write-Host 'Next: eject SD safely, boot RG35XX, test one 240x320 title and KDTT 320x240.'
}
catch {
    Write-Warning "Install failed; rolling back: $($_.Exception.Message)"
    foreach ($t in $targets) {
        $dst = Join-Path $Sd $t.Rel
        $tmp = "$dst.from-zero-new"
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
    foreach ($p in $created) {
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
    }
    foreach ($b in $backed) {
        if (Test-Path -LiteralPath $b.Bak) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $b.Dst) | Out-Null
            Copy-Item -LiteralPath $b.Bak -Destination $b.Dst -Force
        }
    }
    throw
}
