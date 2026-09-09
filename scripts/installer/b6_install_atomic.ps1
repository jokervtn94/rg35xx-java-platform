$ErrorActionPreference = 'Stop'

function Get-Sha256Safe([string]$Path) {
    if (!(Test-Path -LiteralPath $Path)) { return $null }
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Resolve-SdRoot([string]$Drive) {
    if ([string]::IsNullOrWhiteSpace($Drive)) { $Drive = Read-Host 'Nhap ky tu o the nho RG35XX (vi du H)' }
    $Drive = $Drive.Trim().TrimEnd(':','\')
    if ($Drive.Length -ne 1) { throw "Ky tu o dia khong hop le: $Drive" }
    $root = "$Drive`:\"
    if (!(Test-Path -LiteralPath $root)) { throw "Khong tim thay o dia $root" }
    return $root
}

$root = Resolve-SdRoot $args[0]
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$payload = Join-Path $here 'payload'

$expectedJamvm  = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$expectedGlibj  = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$expectedRuntime= 'e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed'
$expectedCore   = '56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'

$targets = @(
    @{Rel='CFW\java\bin\jamvm'; Sha=$expectedJamvm},
    @{Rel='CFW\java\share\classpath\glibj.zip'; Sha=$expectedGlibj},
    @{Rel='CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'; Sha=$expectedCore},
    @{Rel='CFW\retroarch\.retroarch\cores\freej2me_libretro.so'; Sha=$expectedCore},
    @{Rel='BIOS\freej2me-lr.jar'; Sha=$expectedRuntime},
    @{Rel='BIOS\freej2me_plus-lr.jar'; Sha=$expectedRuntime},
    @{Rel='CFW\java\share\freej2me\freej2me-lr.jar'; Sha=$expectedRuntime},
    @{Rel='CFW\retroarch\.retroarch\system\freej2me-lr.jar'; Sha=$expectedRuntime},
    @{Rel='CFW\retroarch\system\freej2me-lr.jar'; Sha=$expectedRuntime}
)

foreach ($t in $targets) {
    $src = Join-Path $payload $t.Rel
    if (!(Test-Path -LiteralPath $src)) { throw "Thieu payload: $($t.Rel)" }
    $got = Get-Sha256Safe $src
    if ($got -ne $t.Sha) { throw "Payload SHA mismatch: $($t.Rel) expected=$($t.Sha) actual=$got" }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $root "RG35XX_VERIFIED_CLEAN_B6_Backup\$stamp"
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
$result = @()

foreach ($t in $targets) {
    $src = Join-Path $payload $t.Rel
    $dst = Join-Path $root $t.Rel
    $before = Get-Sha256Safe $dst

    if (Test-Path -LiteralPath $dst) {
        $bak = Join-Path $backupRoot $t.Rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak) | Out-Null
        Copy-Item -LiteralPath $dst -Destination $bak -Force
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $after = Get-Sha256Safe $dst
    if ($after -ne $t.Sha) { throw "AFTER SHA mismatch: $($t.Rel) expected=$($t.Sha) actual=$after" }
    $result += "TARGET=$($t.Rel) BEFORE=$before AFTER=$after"
}

$logs = @('freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log','freej2me-java-control.log')
foreach ($name in $logs) {
    $p = Join-Path $root $name
    if (Test-Path -LiteralPath $p) {
        Copy-Item -LiteralPath $p -Destination (Join-Path $backupRoot $name) -Force
        Remove-Item -LiteralPath $p -Force
    }
}

$report = Join-Path $root 'RG35XX-VERIFIED-CLEAN-B6-INSTALL-RESULT.txt'
@(
    'RG35XX VERIFIED CLEAN B6 ATOMIC INSTALL',
    "TIME=$(Get-Date -Format o)",
    "ROOT=$root",
    "BACKUP=$backupRoot",
    'STATUS=INSTALL-PASS-DEVICE-ACCEPTANCE-PENDING',
    'JAMVM_L_SHA256=' + $expectedJamvm,
    'GLIBJ_SHA256=' + $expectedGlibj,
    'B4_RUNTIME_SHA256=' + $expectedRuntime,
    'B4_CORE_SHA256=' + $expectedCore,
    $result,
    'RESULT=PASS'
) | Out-File -LiteralPath $report -Encoding utf8

Write-Host 'INSTALL: PASS' -ForegroundColor Green
Write-Host "Backup: $backupRoot"
Write-Host "Report: $report"
