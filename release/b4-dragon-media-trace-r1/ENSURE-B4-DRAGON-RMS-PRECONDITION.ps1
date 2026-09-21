param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedEmptySha='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
$BadStores=@(
  'ffffffff9c61314e09vhjlzvf1zxn0',
  'ffffffff9c61314e14u2hvcf9vbmxvy2tozxc_'
)

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedRuntime='4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c'

function Fail([string]$m){ throw "B4-DRAGON-MEDIA-TRACE-R1 ENSURE FAIL: $m" }
function Sha([string]$p){
  if(!(Test-Path -LiteralPath $p -PathType Leaf)){ return $null }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function Resolve-Sd([string]$raw){
  if([string]::IsNullOrWhiteSpace($raw)){ $raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)' }
  $raw=$raw.Trim().Trim('"')
  if($raw -match '^[A-Za-z]$'){ $raw=$raw+':' }
  if($raw -match '^[A-Za-z]:$'){ $raw=$raw+'\' }
  if(!(Test-Path -LiteralPath $raw -PathType Container)){ Fail "SD root not found: $raw" }
  $resolved=(Resolve-Path -LiteralPath $raw).Path
  $trim=$resolved.TrimEnd('\')
  if($trim.Length -ne 2 -or $trim[1] -ne ':'){ Fail "Refusing non-drive-root path: $resolved" }
  return $trim+'\'
}

$Sd=Resolve-Sd $SdRoot

# Protected current platform state: ENSURE is only for the known baseline state.
$protected=@{
  'CFW\java\bin\jamvm'=$ExpectedJamvm
  'CFW\java\share\classpath\glibj.zip'=$ExpectedGlibj
  'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'=$ExpectedCore
  'BIOS\freej2me-lr.jar'=$ExpectedRuntime
}
foreach($rel in $protected.Keys){
  $p=Join-Path $Sd $rel
  if(!(Test-Path -LiteralPath $p -PathType Leaf)){ Fail "Protected file missing: $rel" }
  $actual=Sha $p
  if($actual -ne $protected[$rel]){ Fail "Protected hash mismatch $rel actual=$actual" }
}

# Locate active Dragon Mania RMS only. Explicitly exclude project backup areas.
$dragonDirs=@(
  Get-ChildItem -LiteralPath $Sd -Directory -Recurse -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Name -eq 'Dragon Mania' -and
    $_.Parent -and $_.Parent.Name -eq 'rms' -and
    $_.Parent.Parent -and $_.Parent.Parent.Name -eq 'freej2me' -and
    $_.FullName -notlike '*\RG35XX-JAVA-BACKUP\*'
  }
)
if(@($dragonDirs).Count -ne 1){
  Fail "Expected exactly one active Dragon Mania RMS directory, found $(@($dragonDirs).Count)"
}
$Dragon=$dragonDirs[0].FullName

$beforeMeta=@(Get-ChildItem -LiteralPath $Dragon -File -Filter '*.rms' -ErrorAction Stop)
$activePlan=@()

foreach($base in $BadStores){
  $meta=Join-Path $Dragon ($base+'.rms')
  $matching=@(
    Get-ChildItem -LiteralPath $Dragon -File -ErrorAction Stop |
    Where-Object { $_.Name -like ($base+'.*') }
  )

  if(Test-Path -LiteralPath $meta -PathType Leaf){
    $fi=Get-Item -LiteralPath $meta
    if($fi.Length -ne 0){
      Fail "Known bad store basename now contains NON-ZERO metadata; refusing quarantine: $($fi.Name) length=$($fi.Length)"
    }
    $metaSha=Sha $meta
    if($metaSha -ne $ExpectedEmptySha){
      Fail "Zero-length metadata hash mismatch: $($fi.Name) sha=$metaSha"
    }
  }

  if(@($matching).Count -gt 2){
    Fail "Unexpected extra files for known store $base count=$(@($matching).Count)"
  }

  foreach($file in $matching){
    $kind=if($file.Name -eq ($base+'.rms')){'META'}else{'PAYLOAD'}
    $activePlan += [PSCustomObject]@{
      Kind=$kind
      Base=$base
      Path=$file.FullName
      Name=$file.Name
      Length=$file.Length
      SHA256=Sha $file.FullName
    }
  }
}

# If nothing is active, verify the intended quarantined state and exit without mutation.
if(@($activePlan).Count -eq 0){
  if(@($beforeMeta).Count -ne 6){
    Fail "Known bad stores are absent, but Dragon Mania metadata count is $(@($beforeMeta).Count), expected 6"
  }

  @(
    'CHECKPOINT=B4-DRAGON-MEDIA-TRACE-R1-PRECONDITION',
    'RESULT=PASS',
    "TIME=$((Get-Date).ToString('s'))",
    "DRAGON_RMS_DIR=$($Dragon.Substring($Sd.Length))",
    'ACTION=NO_MUTATION_ALREADY_QUARANTINED',
    'ACTIVE_BAD_STORE_FILES_BEFORE=0',
    'ACTIVE_BAD_STORE_FILES_AFTER=0',
    'REMAINING_DRAGON_METADATA_COUNT=6',
    'STABLE=NO'
  ) | Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-DRAGON-MEDIA-TRACE-R1-RMS-PRECONDITION.txt') -Encoding ASCII

  Write-Host 'ENSURE PASS - quarantine state already active'
  Write-Host "Dragon metadata count: $(@($beforeMeta).Count)"
  exit 0
}

# Only proven zero-length metadata may be auto-requarantined.
foreach($base in $BadStores){
  $metaRow=@($activePlan | Where-Object {$_.Base -eq $base -and $_.Kind -eq 'META'})
  if(@($metaRow).Count -gt 1){ Fail "Multiple metadata files for $base" }
  if(@($metaRow).Count -eq 1){
    if([int64]$metaRow[0].Length -ne 0 -or $metaRow[0].SHA256 -ne $ExpectedEmptySha){
      Fail "Refusing requarantine: metadata for $base is not the proven zero-length state"
    }
  }
}

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$qRoot=Join-Path $Sd ("RG35XX-JAVA-BACKUP\b4-rms-r2-requarantine-"+$stamp)
$qFiles=Join-Path $qRoot 'files'
New-Item -ItemType Directory -Force -Path $qFiles | Out-Null

$manifest=@()
foreach($item in $activePlan){
  $dst=Join-Path $qFiles $item.Name
  Copy-Item -LiteralPath $item.Path -Destination $dst -Force
  if((Sha $dst) -ne $item.SHA256){ Fail "Backup hash mismatch for $($item.Name)" }
  $manifest += [PSCustomObject]@{
    Kind=$item.Kind
    Base=$item.Base
    OriginalPath=$item.Path.Substring($Sd.Length)
    BackupRelativePath=('files\'+$item.Name)
    Length=$item.Length
    SHA256=$item.SHA256
  }
}
$manifest | Export-Csv -LiteralPath (Join-Path $qRoot 'MANIFEST.csv') -NoTypeInformation -Encoding UTF8

# Remove only after all active known-store files have been backed up and verified.
foreach($item in $activePlan){
  Remove-Item -LiteralPath $item.Path -Force
  if(Test-Path -LiteralPath $item.Path){ Fail "Failed to remove active known-store file: $($item.Path)" }
}

# Final exact-state verification.
foreach($base in $BadStores){
  $left=@(
    Get-ChildItem -LiteralPath $Dragon -File -ErrorAction Stop |
    Where-Object { $_.Name -like ($base+'.*') }
  )
  if(@($left).Count -ne 0){ Fail "Known-store files still active after requarantine: $base count=$(@($left).Count)" }
}
$afterMeta=@(Get-ChildItem -LiteralPath $Dragon -File -Filter '*.rms' -ErrorAction Stop)
if(@($afterMeta).Count -ne 6){
  Fail "Post-requarantine Dragon Mania metadata count=$(@($afterMeta).Count), expected 6"
}

Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-RMS-R2-CURRENT-QUARANTINE.txt') -Value $qRoot -Encoding ASCII
@(
  'CHECKPOINT=B4-DRAGON-MEDIA-TRACE-R1-PRECONDITION',
  'RESULT=PASS',
  "TIME=$((Get-Date).ToString('s'))",
  "DRAGON_RMS_DIR=$($Dragon.Substring($Sd.Length))",
  "QUARANTINE=$qRoot",
  'ACTION=REAPPLIED_PROVEN_ZERO_LENGTH_QUARANTINE',
  "ACTIVE_BAD_STORE_FILES_BEFORE=$(@($activePlan).Count)",
  'ACTIVE_BAD_STORE_FILES_AFTER=0',
  'REMAINING_DRAGON_METADATA_COUNT=6',
  'PLATFORM_CHANGE=NONE',
  'STABLE=NO'
) | Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-DRAGON-MEDIA-TRACE-R1-RMS-PRECONDITION.txt') -Encoding ASCII

Write-Host 'ENSURE PASS - proven zero-length stores re-quarantined'
Write-Host "Files moved: $(@($activePlan).Count)"
Write-Host "Backup: $qRoot"
