[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdRoot,

    [string]$OutputDir
)

$ErrorActionPreference = 'Stop'

function Resolve-SdRoot {
    param([string]$Value)
    $v = $Value.Trim().Trim('"')
    if ($v -match '^[A-Za-z]$') { $v = "$v`:" }
    if ($v -match '^[A-Za-z]:$') { $v = "$v\" }
    return [System.IO.Path]::GetFullPath($v)
}

function Resolve-OutputDir {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $candidate = $PSScriptRoot
    } else {
        $candidate = $Value.Trim().Trim('"')
    }

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $candidate = (Get-Location).Path
    }

    $resolved = [System.IO.Path]::GetFullPath($candidate)
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        New-Item -ItemType Directory -Path $resolved -Force | Out-Null
    }
    return $resolved
}

$root = Resolve-SdRoot $SdRoot
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "SD root not found: $root"
}

$resolvedOutput = Resolve-OutputDir $OutputDir

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("A8-COMPAT-EVIDENCE-$stamp")
$zipPath = Join-Path $resolvedOutput ("A8-COMPAT-EVIDENCE-$stamp.zip")

if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}
New-Item -ItemType Directory -Path $stage -Force | Out-Null

$evidenceDir = Join-Path $root 'A8-COMPAT-EVIDENCE'
$candidateDir = Join-Path $root 'A8-COMPAT-CANDIDATES'
$records = @()
$copiedAnything = $false

if (Test-Path -LiteralPath $evidenceDir -PathType Container) {
    Copy-Item -LiteralPath $evidenceDir -Destination (Join-Path $stage 'A8-COMPAT-EVIDENCE') -Recurse -Force
    $records = Get-ChildItem -LiteralPath $evidenceDir -Directory -ErrorAction SilentlyContinue
    $copiedAnything = $true
}

if (Test-Path -LiteralPath $candidateDir -PathType Container) {
    Copy-Item -LiteralPath $candidateDir -Destination (Join-Path $stage 'A8-COMPAT-CANDIDATES') -Recurse -Force
    $copiedAnything = $true
}

$optionalFiles = @(
    'A8-COMPAT-HARNESS-INSTALL-RESULT.txt',
    'A8-COMPAT-SD-DIAGNOSTIC.txt',
    'A8-CANONICAL-RESTORE-RESULT.txt',
    'RG35XX-AWEIGIT-R1-RESULT.txt'
)
foreach ($name in $optionalFiles) {
    $source = Join-Path $root $name
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $stage $name) -Force
        $copiedAnything = $true
    }
}

if (-not $copiedAnything) {
    Remove-Item -LiteralPath $stage -Recurse -Force
    throw "No A8 compatibility evidence or diagnostic files found on SD: $root"
}

@(
    'PROJECT=RG35XX-AWEIGIT-R1',
    'BASELINE=A8',
    'COLLECTOR=R4_OUTPUTDIR_SAFE',
    "SD_ROOT=$root",
    "OUTPUT_DIR=$resolvedOutput",
    "EVIDENCE_RECORD_COUNT=$($records.Count)",
    "COLLECTED_AT=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
) | Set-Content -LiteralPath (Join-Path $stage 'COLLECT-MANIFEST.txt') -Encoding UTF8

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $stage -Recurse -Force

Write-Host 'A8 compatibility evidence/diagnostic collected.'
Write-Host "Records : $($records.Count)"
Write-Host "ZIP     : $zipPath"
