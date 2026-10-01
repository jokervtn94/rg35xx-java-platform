[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdRoot,

    [string]$OutputDir = "."
)

$ErrorActionPreference = 'Stop'

function Resolve-SdRoot {
    param([string]$Value)
    $v = $Value.Trim().Trim('"')
    if ($v -match '^[A-Za-z]$') { $v = "$v`:" }
    if ($v -match '^[A-Za-z]:$') { $v = "$v\" }
    return [System.IO.Path]::GetFullPath($v)
}

$root = Resolve-SdRoot $SdRoot
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "SD root not found: $root"
}

$evidenceDir = Join-Path $root 'A8-COMPAT-EVIDENCE'
if (-not (Test-Path -LiteralPath $evidenceDir -PathType Container)) {
    throw "No A8 compatibility evidence found: $evidenceDir"
}

if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDir)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("A8-COMPAT-EVIDENCE-$stamp")
$zipPath = Join-Path $resolvedOutput ("A8-COMPAT-EVIDENCE-$stamp.zip")

if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}
New-Item -ItemType Directory -Path $stage -Force | Out-Null

Copy-Item -LiteralPath $evidenceDir -Destination (Join-Path $stage 'A8-COMPAT-EVIDENCE') -Recurse -Force

$optionalFiles = @(
    'A8-COMPAT-HARNESS-INSTALL-RESULT.txt',
    'RG35XX-AWEIGIT-R1-RESULT.txt'
)
foreach ($name in $optionalFiles) {
    $source = Join-Path $root $name
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $stage $name) -Force
    }
}

$records = Get-ChildItem -LiteralPath $evidenceDir -Directory -ErrorAction SilentlyContinue
@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'BASELINE=A8',
    "SD_ROOT=$root",
    "EVIDENCE_RECORD_COUNT=$($records.Count)",
    "COLLECTED_AT=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
) | Set-Content -LiteralPath (Join-Path $stage 'COLLECT-MANIFEST.txt') -Encoding UTF8

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $stage -Recurse -Force

Write-Host 'A8 compatibility evidence collected.'
Write-Host "Records : $($records.Count)"
Write-Host "ZIP     : $zipPath"
