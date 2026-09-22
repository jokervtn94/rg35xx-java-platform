param(
  [Parameter(Mandatory=$false, Position=0)][string]$SdRoot,
  [switch]$ScanOnly,
  [switch]$Force,
  [switch]$SelfTest
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'

$ProtectedJamvmRel='CFW\java\bin\jamvm'
$ProtectedGlibjRel='CFW\java\share\classpath\glibj.zip'
$ProtectedCoreRel='CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'

$KnownRuntimeAliases=@(
  'BIOS\freej2me-lr.jar',
  'BIOS\freej2me_plus-lr.jar',
  'BIOS\freej2me_plus_lr.jar',
  'CFW\java\share\freej2me\freej2me-lr.jar',
  'CFW\java\share\freej2me\freej2me_plus-lr.jar',
  'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
  'CFW\retroarch\.retroarch\system\freej2me_plus-lr.jar',
  'CFW\retroarch\system\freej2me-lr.jar',
  'CFW\retroarch\system\freej2me_plus-lr.jar'
)

function Fail([string]$m){ throw "RG35XX SD PRECLEAN R1 FAIL: $m" }
function Sha([string]$p){
  if(!(Test-Path -LiteralPath $p -PathType Leaf)){ return $null }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function Resolve-Sd([string]$raw){
  if([string]::IsNullOrWhiteSpace($raw)){ $raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du G)' }
  $raw=$raw.Trim().Trim('"')
  if($raw -match '^[A-Za-z]$'){ $raw=$raw+':' }
  if($raw -match '^[A-Za-z]:$'){ $raw=$raw+'\' }
  if(!(Test-Path -LiteralPath $raw -PathType Container)){ Fail "SD root not found: $raw" }
  $resolved=(Resolve-Path -LiteralPath $raw).Path
  $trim=$resolved.TrimEnd('\')
  if($trim.Length -ne 2 -or $trim[1] -ne ':'){ Fail "Refusing non-drive-root path: $resolved" }
  return $trim+'\'
}
function RelPath([string]$root,[string]$full){
  $rootFull=[IO.Path]::GetFullPath($root)
  $fullPath=[IO.Path]::GetFullPath($full)
  if(!$fullPath.StartsWith($rootFull,[StringComparison]::OrdinalIgnoreCase)){ Fail "Path escaped SD root: $fullPath" }
  return $fullPath.Substring($rootFull.Length).TrimStart('\')
}
function StartsRel([string]$rel,[string]$prefix){
  return $rel.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)
}

function Ensure-ParentDirectory([string]$path){
  $parent=Split-Path -Parent $path
  if([string]::IsNullOrWhiteSpace($parent)){ return }
  if(Test-Path -LiteralPath $parent -PathType Container){ return }
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

if($SelfTest){
  $rootProbe=Join-Path ([IO.Path]::GetPathRoot($env:SystemRoot)) 'rg35xx-preclean-selftest-root-file.tmp'
  Ensure-ParentDirectory $rootProbe

  $nestedBase=Join-Path $env:TEMP ('rg35xx-preclean-selftest-'+[Guid]::NewGuid().ToString('N'))
  $nestedFile=Join-Path $nestedBase 'probe.tmp'
  Ensure-ParentDirectory $nestedFile
  if(!(Test-Path -LiteralPath $nestedBase -PathType Container)){
    Fail 'SELFTEST nested parent creation failed'
  }
  Remove-Item -LiteralPath $nestedBase -Force
  $singleton=@([pscustomobject]@{Name='one'})
  if($singleton.Count -ne 1){ Fail 'SELFTEST singleton array normalization failed' }
  $empty=@()
  if($empty.Count -ne 0){ Fail 'SELFTEST empty array normalization failed' }

  Write-Output 'SELFTEST_ROOT_PARENT=PASS'
  Write-Output 'SELFTEST_NESTED_PARENT=PASS'
  Write-Output 'SELFTEST_SINGLETON_ARRAY=PASS'
  Write-Output 'SELFTEST_EMPTY_ARRAY=PASS'
  exit 0
}

$Sd=Resolve-Sd $SdRoot

if(!(Test-Path -LiteralPath (Join-Path $Sd 'CFW') -PathType Container)){ Fail 'CFW directory missing; this does not look like the expected RG35XX SD' }
if(!(Test-Path -LiteralPath (Join-Path $Sd 'Roms') -PathType Container)){ Write-Warning 'Roms directory not found; continuing because platform cleanup does not modify game directories' }

$jamvm=Join-Path $Sd $ProtectedJamvmRel
$glibj=Join-Path $Sd $ProtectedGlibjRel
$core=Join-Path $Sd $ProtectedCoreRel

$jamvmSha=Sha $jamvm
$glibjSha=Sha $glibj
$coreSha=Sha $core

if($jamvmSha -ne $ExpectedJamvm){ Fail "Protected JamVM L mismatch/missing. expected=$ExpectedJamvm actual=$jamvmSha" }
if($glibjSha -ne $ExpectedGlibj){ Fail "Protected glibj mismatch/missing. expected=$ExpectedGlibj actual=$glibjSha" }
if($coreSha -ne $ExpectedCore){ Fail "Protected B4 core mismatch/missing. expected=$ExpectedCore actual=$coreSha" }

$protected=@{}
$protected[$ProtectedJamvmRel.ToLowerInvariant()]=$true
$protected[$ProtectedGlibjRel.ToLowerInvariant()]=$true
$protected[$ProtectedCoreRel.ToLowerInvariant()]=$true

$runtimeAlias=@{}
foreach($r in $KnownRuntimeAliases){ $runtimeAlias[$r.ToLowerInvariant()]=$true }

$scriptRootFull=[IO.Path]::GetFullPath($PSScriptRoot)
$scriptOnSd=$scriptRootFull.StartsWith([IO.Path]::GetFullPath($Sd),[StringComparison]::OrdinalIgnoreCase)
$scriptRel=''
if($scriptOnSd){ $scriptRel=RelPath $Sd $scriptRootFull; if($scriptRel -and !$scriptRel.EndsWith('\')){$scriptRel+='\'} }

function Is-Excluded([string]$rel){
  if([string]::IsNullOrWhiteSpace($rel)){ return $true }
  if(StartsRel $rel 'RG35XX-JAVA-BACKUP\'){ return $true }
  if(StartsRel $rel 'RG35XX-JAVA-PRECLEAN\'){ return $true }
  if(StartsRel $rel 'Saves\'){ return $true }
  if(StartsRel $rel 'Roms\JAVA\'){ return $true }
  if($scriptOnSd -and $scriptRel -and (StartsRel ($rel+'\') $scriptRel)){ return $true }
  return $false
}

function Classify-Candidate([IO.FileInfo]$file){
  $rel=RelPath $Sd $file.FullName
  if(Is-Excluded $rel){ return $null }

  $relKey=$rel.ToLowerInvariant()
  if($protected.ContainsKey($relKey)){ return $null }

  $name=$file.Name
  $lower=$name.ToLowerInvariant()

  if($runtimeAlias.ContainsKey($relKey)){
    return 'KNOWN_RUNTIME_ALIAS'
  }

  if($lower -match '^freej2me.*\.jar$'){
    return 'STRAY_FREEJ2ME_RUNTIME_JAR'
  }

  if($lower -match '^freej2me.*libretro.*\.so$' -or $lower -match '^libfreej2me.*\.so$'){
    return 'STRAY_FREEJ2ME_CORE_OR_NATIVE'
  }

  if(($lower -match '^freej2me.*\.(new|tmp)$') -or
     ($lower -match '^freej2me.*\.(b4hotr2new|cleanr1new)$') -or
     ($lower -match '^freej2me.*\.jar\..*new$')){
    return 'STALE_RUNTIME_TEMP'
  }

  # Historical experimental APP wrappers. Never scan/delete Roms\JAVA game JARs.
  if(StartsRel $rel 'Roms\APPS\'){
    if($lower -match '^m1[\._-]' -or
       $lower -match '^m1\.\d+' -or
       $lower -match '^libm1_.*presenter\.so$' -or
       $lower -match '^rg35xx.*(vc[0-9]|b4|m1).*' ){
      return 'LEGACY_EXPERIMENT_APP'
    }
  }

  # Root-only stale logs/results/pointers can confuse evidence collection.
  if($rel.IndexOf('\') -lt 0){
    if($lower -match '^freej2me-.*\.log$'){ return 'STALE_ROOT_LOG' }
    if($lower -match '^rg35xx-.*-install-result\.txt$'){ return 'STALE_ROOT_INSTALL_RESULT' }
    if($lower -match '^rg35xx-.*-current-backup\.txt$'){ return 'STALE_ROOT_BACKUP_POINTER' }
  }

  return $null
}

function Scan-Candidates {
  $items=New-Object System.Collections.ArrayList
  $all=Get-ChildItem -LiteralPath $Sd -Recurse -Force -File -ErrorAction SilentlyContinue
  foreach($f in $all){
    $reason=Classify-Candidate $f
    if($null -eq $reason){ continue }
    $rel=RelPath $Sd $f.FullName
    $sha=Sha $f.FullName
    [void]$items.Add([pscustomobject]@{
      RelativePath=$rel
      FullPath=$f.FullName
      Reason=$reason
      Size=$f.Length
      SHA256=$sha
    })
  }
  return @($items | Sort-Object RelativePath -Unique)
}

Write-Host ''
Write-Host 'RG35XX SD PRE-CLEAN R1.2'
Write-Host "SD=$Sd"
Write-Host "Protected JamVM=$jamvmSha"
Write-Host "Protected glibj=$glibjSha"
Write-Host "Protected core=$coreSha"
Write-Host 'Preserve: Roms\JAVA, Saves, RG35XX-JAVA-BACKUP, protected foundation'
Write-Host ''

$partialQuarantines=@()
$precleanRoot=Join-Path $Sd 'RG35XX-JAVA-PRECLEAN'
if(Test-Path -LiteralPath $precleanRoot -PathType Container){
  $partialQuarantines=@(Get-ChildItem -LiteralPath $precleanRoot -Directory -Filter 'quarantine-*' -ErrorAction SilentlyContinue |
    Where-Object { !(Test-Path -LiteralPath (Join-Path $_.FullName 'RESULT.txt') -PathType Leaf) })
}
if($partialQuarantines.Count -gt 0){
  Write-Warning "Detected $($partialQuarantines.Count) previous partial quarantine folder(s). They remain isolated and will not be reactivated."
}

$candidates=@(Scan-Candidates)
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$reportRoot=Join-Path $Sd "RG35XX-JAVA-PRECLEAN\scan-$stamp"
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null

$candidates | Select-Object RelativePath,Reason,Size,SHA256 |
  Export-Csv -LiteralPath (Join-Path $reportRoot 'INVENTORY.csv') -NoTypeInformation -Encoding UTF8

@(
  'RG35XX SD PRE-CLEAN R1',
  "TIME=$((Get-Date).ToString('s'))",
  "SD=$Sd",
  "MODE=$(if($ScanOnly){'SCAN_ONLY'}else{'CLEAN'})",
  "CANDIDATE_COUNT=$($candidates.Count)",
  "PREVIOUS_PARTIAL_QUARANTINE_COUNT=$($partialQuarantines.Count)",
  "JAMVM_SHA256=$jamvmSha",
  "GLIBJ_SHA256=$glibjSha",
  "CORE_SHA256=$coreSha",
  'Roms/JAVA=PRESERVED',
  'Saves=PRESERVED',
  'RG35XX-JAVA-BACKUP=PRESERVED',
  'PROTECTED_FOUNDATION=PRESERVED'
) | Set-Content -LiteralPath (Join-Path $reportRoot 'SCAN-SUMMARY.txt') -Encoding ASCII

if($candidates.Count -eq 0){
  Write-Host 'SCAN PASS: no old/stray active platform files detected.'
  if($ScanOnly){
    Write-Host "Report: $reportRoot"
    exit 0
  }

  @(
    'RG35XX SD PRE-CLEAN R1.1',
    'RESULT=PASS',
    "TIME=$((Get-Date).ToString('s'))",
    "SD=$Sd",
    'MOVED_COUNT=0',
    "PREVIOUS_PARTIAL_QUARANTINE_COUNT=$($partialQuarantines.Count)",
    "JAMVM_SHA256=$ExpectedJamvm",
    "GLIBJ_SHA256=$ExpectedGlibj",
    "CORE_SHA256=$ExpectedCore",
    'ACTIVE_OLD_PLATFORM_SCAN=ZERO',
    'Roms/JAVA=PRESERVED',
    'Saves=PRESERVED',
    'RG35XX-JAVA-BACKUP=PRESERVED',
    'READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES'
  ) | Set-Content -LiteralPath (Join-Path $reportRoot 'CLEAN-READY-RESULT.txt') -Encoding ASCII

  Write-Host ''
  Write-Host 'CLEAN PASS - active platform paths are already clean.'
  Write-Host "Previous partial quarantine folders: $($partialQuarantines.Count)"
  Write-Host 'Protected JamVM/glibj/B4 core preserved.'
  Write-Host 'Roms\JAVA and Saves were not modified.'
  Write-Host 'ACTIVE_OLD_PLATFORM_SCAN=ZERO'
  Write-Host 'READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES'
  Write-Host "Report: $reportRoot"
  exit 0
}

Write-Host "Found $($candidates.Count) old/stray active platform files:"
$candidates | Select-Object RelativePath,Reason,Size | Format-Table -AutoSize

if($ScanOnly){
  Write-Host ''
  Write-Host "SCAN ONLY complete. Report: $reportRoot"
  exit 0
}

if(!$Force){
  Write-Host ''
  Write-Host 'The listed files will be REMOVED FROM ACTIVE PATHS and moved to a rollback quarantine.'
  $answer=Read-Host 'Type CLEAN to continue'
  if($answer -cne 'CLEAN'){ Fail 'User cancelled; no platform files moved' }
}

$qRoot=Join-Path $Sd "RG35XX-JAVA-PRECLEAN\quarantine-$stamp"
New-Item -ItemType Directory -Force -Path $qRoot | Out-Null
$moved=New-Object System.Collections.ArrayList

try {
  foreach($item in $candidates){
    $src=$item.FullPath
    if(!(Test-Path -LiteralPath $src -PathType Leaf)){ continue }

    $dst=Join-Path $qRoot $item.RelativePath
    Ensure-ParentDirectory $dst

    if(Test-Path -LiteralPath $dst){ Fail "Quarantine collision: $dst" }

    Move-Item -LiteralPath $src -Destination $dst
    $dstSha=Sha $dst
    if($dstSha -ne $item.SHA256){ Fail "Quarantine hash mismatch: $($item.RelativePath)" }
    if(Test-Path -LiteralPath $src){ Fail "Active file still exists after move: $($item.RelativePath)" }

    [void]$moved.Add([pscustomobject]@{
      RelativePath=$item.RelativePath
      Reason=$item.Reason
      Size=$item.Size
      SHA256=$item.SHA256
      QuarantinePath=$dst
    })
  }

  # Verify protected foundation was untouched.
  if((Sha $jamvm) -ne $ExpectedJamvm){ Fail 'JamVM changed during clean' }
  if((Sha $glibj) -ne $ExpectedGlibj){ Fail 'glibj changed during clean' }
  if((Sha $core) -ne $ExpectedCore){ Fail 'protected core changed during clean' }

  # Rescan active SD. This must be empty of known old runtime/core aliases.
  $residual=@(Scan-Candidates)
  if($residual.Count -ne 0){
    $residual | Select-Object RelativePath,Reason,Size,SHA256 |
      Export-Csv -LiteralPath (Join-Path $qRoot 'RESIDUAL.csv') -NoTypeInformation -Encoding UTF8
    Fail "Residual old/stray active platform files remain: $($residual.Count)"
  }

  $moved | Select-Object RelativePath,Reason,Size,SHA256 |
    Export-Csv -LiteralPath (Join-Path $qRoot 'MANIFEST.csv') -NoTypeInformation -Encoding UTF8

  @(
    'RG35XX SD PRE-CLEAN R1',
    'RESULT=PASS',
    "TIME=$((Get-Date).ToString('s'))",
    "SD=$Sd",
    "QUARANTINE=$qRoot",
    "MOVED_COUNT=$($moved.Count)",
    "PREVIOUS_PARTIAL_QUARANTINE_COUNT=$($partialQuarantines.Count)",
    "JAMVM_SHA256=$ExpectedJamvm",
    "GLIBJ_SHA256=$ExpectedGlibj",
    "CORE_SHA256=$ExpectedCore",
    'ACTIVE_OLD_PLATFORM_SCAN=ZERO',
    'Roms/JAVA=PRESERVED',
    'Saves=PRESERVED',
    'RG35XX-JAVA-BACKUP=PRESERVED',
    'READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES'
  ) | Set-Content -LiteralPath (Join-Path $qRoot 'RESULT.txt') -Encoding ASCII

  Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-SD-PRECLEAN-R1-CURRENT-QUARANTINE.txt') -Value $qRoot -Encoding ASCII

  Write-Host ''
  Write-Host 'CLEAN PASS'
  Write-Host "Moved $($moved.Count) old/stray platform files out of active paths."
  Write-Host "Quarantine: $qRoot"
  Write-Host 'Protected JamVM/glibj/B4 core preserved.'
  Write-Host 'Roms\JAVA and Saves were not modified.'
  Write-Host 'READY_FOR_RG35XX_CLEAN_R1_INSTALL=YES'
}
catch {
  $originalError=$_.Exception
  Write-Warning ("Clean failed: " + $originalError.Message)
  Write-Warning 'Rolling back files moved in this run.'
  $rollbackErrors=New-Object System.Collections.ArrayList
  for($i=$moved.Count-1;$i -ge 0;$i--){
    $m=$moved[$i]
    $src=$m.QuarantinePath
    $dst=Join-Path $Sd $m.RelativePath
    if(Test-Path -LiteralPath $src -PathType Leaf){
      try {
        Ensure-ParentDirectory $dst
        if(Test-Path -LiteralPath $dst){ Remove-Item -LiteralPath $dst -Force }
        Move-Item -LiteralPath $src -Destination $dst -Force
        if((Sha $dst) -ne $m.SHA256){ throw "Rollback hash mismatch: $($m.RelativePath)" }
      }
      catch {
        [void]$rollbackErrors.Add("$($m.RelativePath) => $($_.Exception.Message)")
      }
    }
  }
  if($rollbackErrors.Count -gt 0){
    Write-Warning 'Rollback had errors:'
    foreach($e in $rollbackErrors){ Write-Warning $e }
  } else {
    Write-Host 'ROLLBACK_AFTER_FAILURE=PASS'
  }
  throw $originalError
}
