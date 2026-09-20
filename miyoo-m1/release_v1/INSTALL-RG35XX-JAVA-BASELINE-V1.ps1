param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ExpectedJamvm = "eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34"
$ExpectedGlibj = "d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea"
$ExpectedFont = "20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9"
$PayloadRoot = Join-Path $PSScriptRoot "payload"
$ManifestPath = Join-Path $PayloadRoot "SHA256SUMS.txt"

function Fail([string]$Message) { throw "BASELINE V1 INSTALL FAIL: $Message" }
function Get-Sha([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}
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
function Read-Manifest([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "Missing payload manifest" }
  $map = @{}
  foreach ($line in Get-Content -LiteralPath $Path) {
    $line = $line.Trim(); if (-not $line) { continue }
    if ($line -notmatch "^([0-9a-fA-F]{64})\s+\*?(.+)$") { Fail "Invalid manifest line: $line" }
    $map[$matches[2].Replace("/","\")] = $matches[1].ToLowerInvariant()
  }
  return $map
}
function Backup-Rel([string]$Rel) {
  $src = Join-Path $Sd $Rel
  if (Test-Path -LiteralPath $src) {
    $dst = Join-Path $BackupSd $Rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    Add-Content -LiteralPath $BackupList -Value $Rel
  }
}
function Extract-Font([string]$Jar,[string]$Dest) {
  try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Jar)
    try {
      $entry = $zip.GetEntry("org/recompile/mobile/rg35xx-font.bin")
      if ($null -eq $entry) { return $false }
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$Dest,$true)
      return $true
    } finally { $zip.Dispose() }
  } catch { return $false }
}

$Sd = Resolve-SdRoot $SdRoot
$Jamvm = Join-Path $Sd "CFW\java\bin\jamvm"
$Glibj = Join-Path $Sd "CFW\java\share\classpath\glibj.zip"
$JamvmSha = Get-Sha $Jamvm; $GlibjSha = Get-Sha $Glibj
if ($JamvmSha -ne $ExpectedJamvm) { Fail "JamVM mismatch expected=$ExpectedJamvm actual=$JamvmSha" }
if ($GlibjSha -ne $ExpectedGlibj) { Fail "glibj mismatch expected=$ExpectedGlibj actual=$GlibjSha" }
Write-Host "[1/8] JamVM + glibj DEVICE-PROVEN hashes: VERIFIED"

$Manifest = Read-Manifest $ManifestPath
foreach ($rel in $Manifest.Keys) {
  $p = Join-Path $PayloadRoot $rel
  $got = Get-Sha $p
  if ($got -ne $Manifest[$rel]) { Fail "Payload SHA mismatch: $rel expected=$($Manifest[$rel]) actual=$got" }
}
Write-Host "[2/8] Package payload hashes: VERIFIED"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $Sd "RG35XX-JAVA-BACKUP\installable-baseline-v1-$stamp"
$BackupSd = Join-Path $BackupRoot "sd"
$BackupList = Join-Path $BackupRoot "BACKED-UP-PATHS.txt"
New-Item -ItemType Directory -Force -Path $BackupSd | Out-Null
New-Item -ItemType File -Force -Path $BackupList | Out-Null

$OldExact = @(
  "BIOS\freej2me-lr.jar",
  "BIOS\freej2me_plus-lr.jar",
  "CFW\java\share\freej2me\freej2me-lr.jar",
  "CFW\retroarch\.retroarch\system\freej2me-lr.jar",
  "CFW\retroarch\system\freej2me-lr.jar",
  "CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so",
  "CFW\retroarch\.retroarch\cores\freej2me_libretro.so",
  "Roms\APPS\RG35XX-JAVA-BASELINE"
)
foreach ($rel in $OldExact) { Backup-Rel $rel }

$Apps = Join-Path $Sd "Roms\APPS"
if (Test-Path -LiteralPath $Apps) {
  $patterns = @("M1.*.sh","m1.*","libm1_*.so","VC7*.sh","RG35XX-VC*.sh","JAVA - *.sh","JAVA - *.path")
  foreach ($pattern in $patterns) {
    Get-ChildItem -LiteralPath $Apps -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
      $rel = "Roms\APPS\" + $_.Name; Backup-Rel $rel
    }
  }
}
Get-ChildItem -LiteralPath $Sd -Filter "freej2me*.log" -File -ErrorAction SilentlyContinue | ForEach-Object { Backup-Rel $_.Name }
Get-ChildItem -LiteralPath $Sd -Filter "RG35XX-MIYOO-*.txt" -File -ErrorAction SilentlyContinue | ForEach-Object { Backup-Rel $_.Name }
Write-Host "[3/8] Existing platform/evidence paths: BACKED UP to $BackupRoot"

# Extract only the device-proven experimental font resource before old runtime aliases are removed.
$FontTmpDir = Join-Path $env:TEMP ("rg35xx-font-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $FontTmpDir | Out-Null
$FontBin = Join-Path $FontTmpDir "rg35xx-font.bin"
$fontSource = $null
foreach ($rel in $OldExact) {
  if ($rel -notlike "*.jar") { continue }
  $candidate = Join-Path $Sd $rel
  if (Test-Path -LiteralPath $candidate -PathType Leaf) {
    Remove-Item -LiteralPath $FontBin -Force -ErrorAction SilentlyContinue
    if ((Extract-Font $candidate $FontBin) -and ((Get-Sha $FontBin) -eq $ExpectedFont)) { $fontSource = $candidate; break }
  }
}
if ($null -eq $fontSource) { Fail "Required EXPERIMENTAL_NOT_GOLDEN font resource 20c2... not found in existing verified runtime aliases" }
Write-Host "[4/8] Font resource extracted and verified from: $fontSource"

$CreatedWrappers = New-Object System.Collections.Generic.List[string]
try {
  foreach ($rel in $OldExact) {
    $p = Join-Path $Sd $rel
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force }
  }
  if (Test-Path -LiteralPath $Apps) {
    $patterns = @("M1.*.sh","m1.*","libm1_*.so","VC7*.sh","RG35XX-VC*.sh","JAVA - *.sh","JAVA - *.path")
    foreach ($pattern in $patterns) { Get-ChildItem -LiteralPath $Apps -Filter $pattern -File -ErrorAction SilentlyContinue | Remove-Item -Force }
  }
  Get-ChildItem -LiteralPath $Sd -Filter "freej2me*.log" -File -ErrorAction SilentlyContinue | Remove-Item -Force
  Get-ChildItem -LiteralPath $Sd -Filter "RG35XX-MIYOO-*.txt" -File -ErrorAction SilentlyContinue | Remove-Item -Force
  Write-Host "[5/8] Known old platform aliases/diagnostic files: REMOVED after backup"

  $BaseDst = Join-Path $Sd "Roms\APPS\RG35XX-JAVA-BASELINE"
  New-Item -ItemType Directory -Force -Path $BaseDst | Out-Null
  Copy-Item -LiteralPath (Join-Path $PayloadRoot "Roms\APPS\RG35XX-JAVA-BASELINE\*") -Destination $BaseDst -Recurse -Force

  $fontTree = Join-Path $FontTmpDir "jarroot\org\recompile\mobile"
  New-Item -ItemType Directory -Force -Path $fontTree | Out-Null
  Copy-Item -LiteralPath $FontBin -Destination (Join-Path $fontTree "rg35xx-font.bin") -Force
  $fontZip = Join-Path $FontTmpDir "font-resource.zip"
  Compress-Archive -Path (Join-Path $FontTmpDir "jarroot\*") -DestinationPath $fontZip -Force
  Copy-Item -LiteralPath $fontZip -Destination (Join-Path $BaseDst "font-resource.jar") -Force
  Set-Content -LiteralPath (Join-Path $BaseDst "FONT-RESOURCE.txt") -Encoding ASCII -Value @(
    "CLASSIFICATION=EXPERIMENTAL_NOT_GOLDEN",
    "RESOURCE_SHA256=$ExpectedFont",
    "SOURCE_BEFORE_CLEANUP=$fontSource"
  )
  Write-Host "[6/8] Baseline runtime installed; font isolated into minimal resource JAR"

  $JavaRoot = Join-Path $Sd "Roms\JAVA"
  $wrapperCount = 0
  if (Test-Path -LiteralPath $JavaRoot) {
    Get-ChildItem -LiteralPath $JavaRoot -Filter "*.jar" -File -Recurse | ForEach-Object {
      $rel = $_.FullName.Substring($JavaRoot.Length).TrimStart("\")
      $relUnix = $rel.Replace("\","/")
      $label = ($rel -replace "\.jar$","" -replace "[\\/]"," - " -replace "[^\p{L}\p{Nd} _\.\-\(\)\[\]]","_")
      $sh = Join-Path $Apps ("JAVA - " + $label + ".sh")
      $pathFile = [System.IO.Path]::ChangeExtension($sh, ".path")
      $gameUnix = "/mnt/mmc/Roms/JAVA/" + $relUnix
      $script = @(
        "#!/bin/sh",
        "# RG35XX-JAVA-INSTALLABLE-BASELINE-V1",
        "BASE=/mnt/mmc/Roms/APPS/RG35XX-JAVA-BASELINE",
        "PATHFILE=`"${0%.sh}.path`"",
        "GAME=`$(cat `"$PATHFILE`")",
        "exec `"$BASE/run-java.sh`" `"$GAME`""
      ) -join "`n"
      [System.IO.File]::WriteAllText($sh, $script + "`n", (New-Object System.Text.UTF8Encoding($false)))
      [System.IO.File]::WriteAllText($pathFile, $gameUnix + "`n", (New-Object System.Text.UTF8Encoding($false)))
      $CreatedWrappers.Add($sh); $CreatedWrappers.Add($pathFile); $wrapperCount++
    }
  }
  Write-Host "[7/8] Java game launchers generated: $wrapperCount"

  $result = Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-INSTALL-RESULT.txt"
  @(
    "RG35XX JAVA INSTALLABLE BASELINE V1",
    "STATUS=INSTALL-PASS_DEVICE-TEST-PENDING",
    "TIME=$((Get-Date).ToString("s"))",
    "SD_ROOT=$Sd",
    "BACKUP=$BackupRoot",
    "JAMVM_SHA256=$JamvmSha",
    "GLIBJ_SHA256=$GlibjSha",
    "FONT_RESOURCE_SHA256=$ExpectedFont",
    "FONT_CLASSIFICATION=EXPERIMENTAL_NOT_GOLDEN",
    "GAME_WRAPPERS=$wrapperCount",
    "M1_16_R15_INCLUDED=NO",
    "FULL_PLATFORM_STABLE=NO",
    "RESULT=PASS"
  ) | Set-Content -LiteralPath $result -Encoding ASCII
  Set-Content -LiteralPath (Join-Path $Sd "RG35XX-JAVA-BASELINE-V1-CURRENT-BACKUP.txt") -Value $BackupRoot -Encoding ASCII
  Write-Host "[8/8] INSTALL PASS - device/game acceptance is next"
  Write-Host "Result: $result"
} catch {
  Write-Warning "Install failed; restoring backup: $($_.Exception.Message)"
  $base = Join-Path $Sd "Roms\APPS\RG35XX-JAVA-BASELINE"; if (Test-Path -LiteralPath $base) { Remove-Item -LiteralPath $base -Recurse -Force -ErrorAction SilentlyContinue }
  foreach ($p in $CreatedWrappers) { if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } }
  $restore = Join-Path $BackupRoot "sd"
  if (Test-Path -LiteralPath $restore) { Copy-Item -Path (Join-Path $restore "*") -Destination $Sd -Recurse -Force }
  throw
} finally {
  Remove-Item -LiteralPath $FontTmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
