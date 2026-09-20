param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Fail([string]$Message) { throw "BASELINE V1 COLLECT FAIL: $Message" }
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
function Copy-If([string]$Source,[string]$DestDir) {
  if (Test-Path -LiteralPath $Source -PathType Leaf) { Copy-Item -LiteralPath $Source -Destination $DestDir -Force }
}

$Sd = Resolve-SdRoot $SdRoot
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $PSScriptRoot ("RG35XX-JAVA-BASELINE-V1-EVIDENCE-" + $stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

Copy-If (Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-INSTALL-RESULT.txt") $out
Copy-If (Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-RESTORE-RESULT.txt") $out
Copy-If (Join-Path $Sd "RG35XX-JAVA-BASELINE-LAST.log") $out
Copy-If (Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-CURRENT-BACKUP.txt") $out

Get-ChildItem -LiteralPath $Sd -Filter "RG35XX-JAVA-BASELINE-*.log" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 12 | Copy-Item -Destination $out -Force
Get-ChildItem -LiteralPath $Sd -Filter "freej2me*.log" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 12 | Copy-Item -Destination $out -Force

$base = Join-Path $Sd "Roms\APPS\RG35XX-JAVA-BASELINE"
$hashReport = Join-Path $out "DEVICE-HASHES.txt"
$lines = New-Object System.Collections.Generic.List[string]
$jamvm = Join-Path $Sd "CFW\java\bin\jamvm"
$glibj = Join-Path $Sd "CFW\java\share\classpath\glibj.zip"
if (Test-Path -LiteralPath $jamvm) { $lines.Add("JAMVM_SHA256=" + (Get-FileHash -Algorithm SHA256 -LiteralPath $jamvm).Hash.ToLowerInvariant()) }
if (Test-Path -LiteralPath $glibj) { $lines.Add("GLIBJ_SHA256=" + (Get-FileHash -Algorithm SHA256 -LiteralPath $glibj).Hash.ToLowerInvariant()) }
if (Test-Path -LiteralPath $base) {
  Get-ChildItem -LiteralPath $base -File | Sort-Object Name | ForEach-Object {
    $lines.Add($_.Name + "_SHA256=" + (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant())
  }
}
$lines | Set-Content -LiteralPath $hashReport -Encoding ASCII

$gameReport = Join-Path $out "JAVA-GAMES.txt"
$javaRoot = Join-Path $Sd "Roms\JAVA"
if (Test-Path -LiteralPath $javaRoot) {
  Get-ChildItem -LiteralPath $javaRoot -Filter "*.jar" -File -Recurse | ForEach-Object { $_.FullName.Substring($javaRoot.Length).TrimStart("\") } | Sort-Object | Set-Content -LiteralPath $gameReport -Encoding UTF8
} else { "NO_ROMS_JAVA_DIRECTORY" | Set-Content -LiteralPath $gameReport -Encoding ASCII }

$zip = "$out.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $out "*") -DestinationPath $zip -Force
Write-Host "COLLECT PASS"
Write-Host "Evidence ZIP: $zip"
