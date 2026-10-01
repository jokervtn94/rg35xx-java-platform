[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$JarPath,

    [Parameter(Mandatory = $true)]
    [string]$GameName,

    [string]$Source = "UNSPECIFIED",

    [string]$CandidateId = "A8-COMP-UNASSIGNED",

    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"

$jar = Get-Item -LiteralPath $JarPath
if ($jar.PSIsContainer) {
    throw "JarPath must point to a .jar file: $JarPath"
}

if ($jar.Extension -notmatch '^\.jar$') {
    Write-Warning "Input does not use a .jar extension: $($jar.Name)"
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$hash = (Get-FileHash -LiteralPath $jar.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
$safeId = ($CandidateId -replace '[^A-Za-z0-9._-]', '_')
if ([string]::IsNullOrWhiteSpace($safeId)) {
    $safeId = "A8-COMP-UNASSIGNED"
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outFile = Join-Path $OutputDir ("{0}-{1}-CANDIDATE.txt" -f $safeId, $stamp)

$lines = @(
    "PROJECT=RG35XX-AWEIGIT-R1",
    "BASELINE=A8",
    "CANDIDATE_ID=$CandidateId",
    "GAME=$GameName",
    "JAR_FILENAME=$($jar.Name)",
    "JAR_SHA256=$hash",
    "JAR_SIZE_BYTES=$($jar.Length)",
    "SOURCE=$Source",
    "DEVICE=ORIGINAL_RG35XX",
    "PREPARED_AT=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
    "",
    "BOOT=NOT_TESTED",
    "GRAPHICS=NOT_TESTED",
    "INPUT=NOT_TESTED",
    "GAMEPLAY=NOT_TESTED",
    "AUDIO=NOT_TESTED",
    "MEDIA=NOT_TESTED",
    "RMS=NOT_TESTED",
    "LIFECYCLE=NOT_TESTED",
    "PERFORMANCE=NOT_TESTED",
    "HANG_CRASH=NOT_TESTED",
    "EXIT=NOT_TESTED",
    "",
    "RESULT=NEEDS_REPRO",
    "FAILURE_OWNER=UNASSIGNED",
    "LOG_EVIDENCE=",
    "NOTES="
)

$lines | Set-Content -LiteralPath $outFile -Encoding UTF8

Write-Host "A8 candidate prepared"
Write-Host "Game      : $GameName"
Write-Host "JAR       : $($jar.FullName)"
Write-Host "SHA256    : $hash"
Write-Host "Record    : $outFile"
Write-Host ""
Write-Host "The JAR itself was not copied or modified."
