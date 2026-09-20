param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Fail([string]$Message) { throw "BASELINE V1 RESTORE FAIL: $Message" }
function Resolve-SdRoot([string]$Raw) {
  if ([string]::IsNullOrWhiteSpace($Raw)) { $Raw = Read-Host "Nhap o dia SD RG35XX (vi du G, G: hoac G:\)" }
  $Raw = $Raw.Trim().Trim('"')
  if ($Raw -match "^[A-Za-z]$") { $Raw = "$Raw`:" }
  if ($Raw -match "^[A-Za-z]:$") { $Raw = "$Raw\" }
  if (-not (Test-Path -LiteralPath $Raw -PathType Container)) { Fail "SD root not found: $Raw" }
  $resolved = (Resolve-Path -LiteralPath $Raw).Path
  if ($resolved -notmatch "^[A-Za-z]:\\?$") { Fail "Refusing non-drive-root path: $resolved" }
  return ($resolved.TrimEnd("\") + "\")
}

$Sd = Resolve-SdRoot $SdRoot
$pointer = Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-CURRENT-BACKUP.txt"
$backupRoot = $null
if (Test-Path -LiteralPath $pointer -PathType Leaf) {
  $backupRoot = (Get-Content -LiteralPath $pointer -Raw).Trim()
}
if ([string]::IsNullOrWhiteSpace($backupRoot) -or -not (Test-Path -LiteralPath $backupRoot -PathType Container)) {
  $parent = Join-Path $Sd "RG35XX-JAVA-BACKUP"
  if (Test-Path -LiteralPath $parent) {
    $latest = Get-ChildItem -LiteralPath $parent -Directory -Filter "installable-baseline-v1-*" | Sort-Object Name -Descending | Select-Object -First 1
    if ($null -ne $latest) { $backupRoot = $latest.FullName }
  }
}
if ([string]::IsNullOrWhiteSpace($backupRoot) -or -not (Test-Path -LiteralPath $backupRoot -PathType Container)) { Fail "No baseline-v1 backup found" }

$Apps = Join-Path $Sd "Roms\APPS"
$base = Join-Path $Apps "RG35XX-JAVA-BASELINE"
if (Test-Path -LiteralPath $base) { Remove-Item -LiteralPath $base -Recurse -Force }
if (Test-Path -LiteralPath $Apps) {
  Get-ChildItem -LiteralPath $Apps -Filter "JAVA - *.sh" -File -ErrorAction SilentlyContinue | ForEach-Object {
    $first = Get-Content -LiteralPath $_.FullName -TotalCount 3 -ErrorAction SilentlyContinue
    if (($first -join "`n") -match "RG35XX-JAVA-INSTALLABLE-BASELINE-V1") { Remove-Item -LiteralPath $_.FullName -Force }
  }
  Get-ChildItem -LiteralPath $Apps -Filter "JAVA - *.path" -File -ErrorAction SilentlyContinue | Remove-Item -Force
}

$restore = Join-Path $backupRoot "sd"
if (-not (Test-Path -LiteralPath $restore -PathType Container)) { Fail "Backup payload missing: $restore" }
Copy-Item -Path (Join-Path $restore "*") -Destination $Sd -Recurse -Force

$report = Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-RESTORE-RESULT.txt"
@(
  "RG35XX JAVA BASELINE V1 RESTORE",
  "TIME=$((Get-Date).ToString("s"))",
  "BACKUP=$backupRoot",
  "RESULT=PASS"
) | Set-Content -LiteralPath $report -Encoding ASCII
Write-Host "RESTORE PASS"
Write-Host "Backup restored: $backupRoot"
Write-Host "Report: $report"
