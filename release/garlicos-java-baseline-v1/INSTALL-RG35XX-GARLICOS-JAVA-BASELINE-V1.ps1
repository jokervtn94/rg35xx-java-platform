param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm   = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj   = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedRuntime = 'e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed'
$ExpectedCore    = '56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'

$PayloadRoot = Join-Path $PSScriptRoot 'payload'
$ManifestPath = Join-Path $PayloadRoot 'SHA256SUMS.txt'

function Fail([string]$Message) { throw "GARLICOS JAVA BASELINE V1 INSTALL FAIL: $Message" }

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

function Read-Manifest([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "Missing payload manifest: $Path" }
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $line = $line.Trim()
        if (-not $line) { continue }
        if ($line -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') { Fail "Invalid manifest line: $line" }
        $map[$matches[2].Replace('/','\')] = $matches[1].ToLowerInvariant()
    }
    return $map
}

$Sd = Resolve-SdRoot $SdRoot
Write-Host "[1/8] SD root: $Sd"

$jamvm = Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj = Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$jamvmSha = Get-Sha $jamvm
$glibjSha = Get-Sha $glibj
if ($jamvmSha -ne $ExpectedJamvm) { Fail "JamVM mismatch expected=$ExpectedJamvm actual=$jamvmSha" }
if ($glibjSha -ne $ExpectedGlibj) { Fail "glibj mismatch expected=$ExpectedGlibj actual=$glibjSha" }
Write-Host '[2/8] Device-proven JamVM + glibj: VERIFIED'

$manifest = Read-Manifest $ManifestPath
foreach ($rel in $manifest.Keys) {
    $p = Join-Path $PayloadRoot $rel
    $actual = Get-Sha $p
    if ($actual -ne $manifest[$rel]) { Fail "Payload SHA mismatch: $rel expected=$($manifest[$rel]) actual=$actual" }
}
Write-Host '[3/8] Package payload: VERIFIED'

$coreSrc = Join-Path $PayloadRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$runtimeSrc = Join-Path $PayloadRoot 'BIOS\freej2me-lr.jar'
if ((Get-Sha $coreSrc) -ne $ExpectedCore) { Fail 'Core is not the locked B4 device-evidence binary' }
if ((Get-Sha $runtimeSrc) -ne $ExpectedRuntime) { Fail 'Runtime is not the locked B4 device-evidence binary' }

$targets = @(
    @{ Source=$coreSrc; Sha=$ExpectedCore; Rel='CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so' },
    @{ Source=$coreSrc; Sha=$ExpectedCore; Rel='CFW\retroarch\.retroarch\cores\freej2me_libretro.so' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='BIOS\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='BIOS\freej2me_plus-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='CFW\java\share\freej2me\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='CFW\retroarch\.retroarch\system\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='CFW\retroarch\system\freej2me-lr.jar' }
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $Sd "RG35XX-JAVA-BACKUP\garlicos-java-baseline-v1-$stamp"
$backupSd = Join-Path $backupRoot 'sd'
$statePath = Join-Path $backupRoot 'STATE.txt'
New-Item -ItemType Directory -Force -Path $backupSd | Out-Null
$state = New-Object System.Collections.Generic.List[string]

function Backup-Path([string]$Rel) {
    $src = Join-Path $Sd $Rel
    if (Test-Path -LiteralPath $src) {
        $dst = Join-Path $backupSd $Rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
        $state.Add("EXISTED|$Rel")
    } else {
        $state.Add("ABSENT|$Rel")
    }
}

foreach ($t in $targets) { Backup-Path $t.Rel }

$wrongBaseRel = 'Roms\APPS\RG35XX-JAVA-BASELINE'
Backup-Path $wrongBaseRel

$Apps = Join-Path $Sd 'Roms\APPS'
$wrongWrappers = @()
if (Test-Path -LiteralPath $Apps -PathType Container) {
    Get-ChildItem -LiteralPath $Apps -Filter 'JAVA - *.sh' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $head = (Get-Content -LiteralPath $_.FullName -TotalCount 3 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
        if ($head -match 'RG35XX-JAVA-INSTALLABLE-BASELINE-V1') {
            $wrongWrappers += $_.FullName
            Backup-Path ('Roms\APPS\' + $_.Name)
            $pathFile = [System.IO.Path]::ChangeExtension($_.FullName,'.path')
            if (Test-Path -LiteralPath $pathFile -PathType Leaf) {
                Backup-Path ('Roms\APPS\' + [System.IO.Path]::GetFileName($pathFile))
                $wrongWrappers += $pathFile
            }
        }
    }
}
$state | Set-Content -LiteralPath $statePath -Encoding ASCII
Write-Host '[4/8] Existing core/runtime + mistaken APP integration: BACKED UP'

try {
    $wrongBase = Join-Path $Sd $wrongBaseRel
    if (Test-Path -LiteralPath $wrongBase) { Remove-Item -LiteralPath $wrongBase -Recurse -Force }
    foreach ($p in $wrongWrappers) {
        if (Test-Path -LiteralPath $p -PathType Leaf) { Remove-Item -LiteralPath $p -Force }
    }
    Write-Host '[5/8] Mistaken APP wrappers removed; Roms\JAVA preserved'

    foreach ($t in $targets) {
        $dst = Join-Path $Sd $t.Rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        $tmp = $dst + '.garlicos-java-new'
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        Copy-Item -LiteralPath $t.Source -Destination $tmp -Force
        if ((Get-Sha $tmp) -ne $t.Sha) { Fail "Staged SHA mismatch: $($t.Rel)" }
        Move-Item -LiteralPath $tmp -Destination $dst -Force
        if ((Get-Sha $dst) -ne $t.Sha) { Fail "Installed SHA mismatch: $($t.Rel)" }
    }
    Write-Host '[6/8] Canonical GarlicOS core/runtime aliases installed'

    foreach ($name in @('freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log','freej2me-java-control.log')) {
        $p = Join-Path $Sd $name
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            Copy-Item -LiteralPath $p -Destination (Join-Path $backupRoot $name) -Force
            Remove-Item -LiteralPath $p -Force
        }
    }

    $javaRoot = Join-Path $Sd 'Roms\JAVA'
    $jarCount = 0
    if (Test-Path -LiteralPath $javaRoot -PathType Container) {
        $jarCount = @(Get-ChildItem -LiteralPath $javaRoot -Filter '*.jar' -File -Recurse).Count
    }
    Write-Host "[7/8] Roms\JAVA JAR count: $jarCount"

    $report = Join-Path $Sd 'RG35XX-GARLICOS-JAVA-BASELINE-V1-INSTALL-RESULT.txt'
    @(
        'RG35XX GARLICOS JAVA BASELINE V1',
        'STATUS=INSTALL-PASS_DEVICE-GAME-TEST-PENDING',
        "TIME=$((Get-Date).ToString('s'))",
        "SD_ROOT=$Sd",
        "BACKUP=$backupRoot",
        "JAMVM_SHA256=$jamvmSha",
        "GLIBJ_SHA256=$glibjSha",
        "RUNTIME_SHA256=$ExpectedRuntime",
        "CORE_SHA256=$ExpectedCore",
        "ROMS_JAVA_JAR_COUNT=$jarCount",
        'LAUNCH_MODEL=GARLICOS_ROM_BROWSER_DIRECT_JAR',
        'APP_WRAPPERS=NO',
        'R1_5_INCLUDED=NO',
        'FULL_PLATFORM_STABLE=NO',
        'RESULT=PASS'
    ) | Set-Content -LiteralPath $report -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-GARLICOS-JAVA-BASELINE-V1-CURRENT-BACKUP.txt') -Value $backupRoot -Encoding ASCII
    Write-Host '[8/8] INSTALL PASS'
    Write-Host 'Launch games directly from GarlicOS JAVA / Roms\JAVA.'
}
catch {
    Write-Warning "Install failed; rolling back current transaction: $($_.Exception.Message)"
    foreach ($line in Get-Content -LiteralPath $statePath) {
        $parts = $line.Split('|',2)
        if ($parts.Count -ne 2) { continue }
        $kind=$parts[0]; $rel=$parts[1]
        $dst=Join-Path $Sd $rel
        $bak=Join-Path $backupSd $rel
        if ($kind -eq 'ABSENT') {
            if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
        } elseif ($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak)) {
            if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            Copy-Item -LiteralPath $bak -Destination $dst -Recurse -Force
        }
    }
    throw
}
) { Fail "Refusing non-drive-root path: $resolved" }
    return ($resolved.TrimEnd('\') + '\')
}

function Read-Manifest([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "Missing payload manifest: $Path" }
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $line = $line.Trim()
        if (-not $line) { continue }
        if ($line -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') { Fail "Invalid manifest line: $line" }
        $map[$matches[2].Replace('/','\')] = $matches[1].ToLowerInvariant()
    }
    return $map
}

$Sd = Resolve-SdRoot $SdRoot
Write-Host "[1/8] SD root: $Sd"

$jamvm = Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj = Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$jamvmSha = Get-Sha $jamvm
$glibjSha = Get-Sha $glibj
if ($jamvmSha -ne $ExpectedJamvm) { Fail "JamVM mismatch expected=$ExpectedJamvm actual=$jamvmSha" }
if ($glibjSha -ne $ExpectedGlibj) { Fail "glibj mismatch expected=$ExpectedGlibj actual=$glibjSha" }
Write-Host '[2/8] Device-proven JamVM + glibj: VERIFIED'

$manifest = Read-Manifest $ManifestPath
foreach ($rel in $manifest.Keys) {
    $p = Join-Path $PayloadRoot $rel
    $actual = Get-Sha $p
    if ($actual -ne $manifest[$rel]) { Fail "Payload SHA mismatch: $rel expected=$($manifest[$rel]) actual=$actual" }
}
Write-Host '[3/8] Package payload: VERIFIED'

$coreSrc = Join-Path $PayloadRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$runtimeSrc = Join-Path $PayloadRoot 'BIOS\freej2me-lr.jar'
if ((Get-Sha $coreSrc) -ne $ExpectedCore) { Fail 'Core is not the locked B4 device-evidence binary' }
if ((Get-Sha $runtimeSrc) -ne $ExpectedRuntime) { Fail 'Runtime is not the locked B4 device-evidence binary' }

$targets = @(
    @{ Source=$coreSrc; Sha=$ExpectedCore; Rel='CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so' },
    @{ Source=$coreSrc; Sha=$ExpectedCore; Rel='CFW\retroarch\.retroarch\cores\freej2me_libretro.so' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='BIOS\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='BIOS\freej2me_plus-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='CFW\java\share\freej2me\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='CFW\retroarch\.retroarch\system\freej2me-lr.jar' },
    @{ Source=$runtimeSrc; Sha=$ExpectedRuntime; Rel='CFW\retroarch\system\freej2me-lr.jar' }
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $Sd "RG35XX-JAVA-BACKUP\garlicos-java-baseline-v1-$stamp"
$backupSd = Join-Path $backupRoot 'sd'
$statePath = Join-Path $backupRoot 'STATE.txt'
New-Item -ItemType Directory -Force -Path $backupSd | Out-Null
$state = New-Object System.Collections.Generic.List[string]

function Backup-Path([string]$Rel) {
    $src = Join-Path $Sd $Rel
    if (Test-Path -LiteralPath $src) {
        $dst = Join-Path $backupSd $Rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
        $state.Add("EXISTED|$Rel")
    } else {
        $state.Add("ABSENT|$Rel")
    }
}

foreach ($t in $targets) { Backup-Path $t.Rel }

$wrongBaseRel = 'Roms\APPS\RG35XX-JAVA-BASELINE'
Backup-Path $wrongBaseRel

$Apps = Join-Path $Sd 'Roms\APPS'
$wrongWrappers = @()
if (Test-Path -LiteralPath $Apps -PathType Container) {
    Get-ChildItem -LiteralPath $Apps -Filter 'JAVA - *.sh' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $head = (Get-Content -LiteralPath $_.FullName -TotalCount 3 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
        if ($head -match 'RG35XX-JAVA-INSTALLABLE-BASELINE-V1') {
            $wrongWrappers += $_.FullName
            Backup-Path ('Roms\APPS\' + $_.Name)
            $pathFile = [System.IO.Path]::ChangeExtension($_.FullName,'.path')
            if (Test-Path -LiteralPath $pathFile -PathType Leaf) {
                Backup-Path ('Roms\APPS\' + [System.IO.Path]::GetFileName($pathFile))
                $wrongWrappers += $pathFile
            }
        }
    }
}
$state | Set-Content -LiteralPath $statePath -Encoding ASCII
Write-Host '[4/8] Existing core/runtime + mistaken APP integration: BACKED UP'

try {
    $wrongBase = Join-Path $Sd $wrongBaseRel
    if (Test-Path -LiteralPath $wrongBase) { Remove-Item -LiteralPath $wrongBase -Recurse -Force }
    foreach ($p in $wrongWrappers) {
        if (Test-Path -LiteralPath $p -PathType Leaf) { Remove-Item -LiteralPath $p -Force }
    }
    Write-Host '[5/8] Mistaken APP wrappers removed; Roms\JAVA preserved'

    foreach ($t in $targets) {
        $dst = Join-Path $Sd $t.Rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        $tmp = $dst + '.garlicos-java-new'
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        Copy-Item -LiteralPath $t.Source -Destination $tmp -Force
        if ((Get-Sha $tmp) -ne $t.Sha) { Fail "Staged SHA mismatch: $($t.Rel)" }
        Move-Item -LiteralPath $tmp -Destination $dst -Force
        if ((Get-Sha $dst) -ne $t.Sha) { Fail "Installed SHA mismatch: $($t.Rel)" }
    }
    Write-Host '[6/8] Canonical GarlicOS core/runtime aliases installed'

    foreach ($name in @('freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log','freej2me-java-control.log')) {
        $p = Join-Path $Sd $name
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            Copy-Item -LiteralPath $p -Destination (Join-Path $backupRoot $name) -Force
            Remove-Item -LiteralPath $p -Force
        }
    }

    $javaRoot = Join-Path $Sd 'Roms\JAVA'
    $jarCount = 0
    if (Test-Path -LiteralPath $javaRoot -PathType Container) {
        $jarCount = @(Get-ChildItem -LiteralPath $javaRoot -Filter '*.jar' -File -Recurse).Count
    }
    Write-Host "[7/8] Roms\JAVA JAR count: $jarCount"

    $report = Join-Path $Sd 'RG35XX-GARLICOS-JAVA-BASELINE-V1-INSTALL-RESULT.txt'
    @(
        'RG35XX GARLICOS JAVA BASELINE V1',
        'STATUS=INSTALL-PASS_DEVICE-GAME-TEST-PENDING',
        "TIME=$((Get-Date).ToString('s'))",
        "SD_ROOT=$Sd",
        "BACKUP=$backupRoot",
        "JAMVM_SHA256=$jamvmSha",
        "GLIBJ_SHA256=$glibjSha",
        "RUNTIME_SHA256=$ExpectedRuntime",
        "CORE_SHA256=$ExpectedCore",
        "ROMS_JAVA_JAR_COUNT=$jarCount",
        'LAUNCH_MODEL=GARLICOS_ROM_BROWSER_DIRECT_JAR',
        'APP_WRAPPERS=NO',
        'R1_5_INCLUDED=NO',
        'FULL_PLATFORM_STABLE=NO',
        'RESULT=PASS'
    ) | Set-Content -LiteralPath $report -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-GARLICOS-JAVA-BASELINE-V1-CURRENT-BACKUP.txt') -Value $backupRoot -Encoding ASCII
    Write-Host '[8/8] INSTALL PASS'
    Write-Host 'Launch games directly from GarlicOS JAVA / Roms\JAVA.'
}
catch {
    Write-Warning "Install failed; rolling back current transaction: $($_.Exception.Message)"
    foreach ($line in Get-Content -LiteralPath $statePath) {
        $parts = $line.Split('|',2)
        if ($parts.Count -ne 2) { continue }
        $kind=$parts[0]; $rel=$parts[1]
        $dst=Join-Path $Sd $rel
        $bak=Join-Path $backupSd $rel
        if ($kind -eq 'ABSENT') {
            if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
        } elseif ($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak)) {
            if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            Copy-Item -LiteralPath $bak -Destination $dst -Recurse -Force
        }
    }
    throw
}
