param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedEmptySha='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
$BadStores=@(
  'ffffffff9c61314e09vhjlzvf1zxn0',
  'ffffffff9c61314e14u2hvcf9vbmxvy2tozxc_'
)

function Fail([string]$m){ throw "B4-RMS-R2 QUARANTINE FAIL: $m" }
function Sha([string]$p){ return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }

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

# Protected platform state.
$expected=@{
 'CFW\java\bin\jamvm'='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
 'CFW\java\share\classpath\glibj.zip'='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
 'BIOS\freej2me-lr.jar'='4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c'
}
foreach($rel in $expected.Keys){
  $p=Join-Path $Sd $rel
  if(!(Test-Path -LiteralPath $p -PathType Leaf)){ Fail "Protected file missing: $rel" }
  $actual=Sha $p
  if($actual -ne $expected[$rel]){ Fail "Protected hash mismatch $rel actual=$actual" }
}

# Find exactly one Dragon Mania RMS directory under a freej2me\rms root.
$dragonDirs=@(
  Get-ChildItem -LiteralPath $Sd -Directory -Recurse -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Name -eq 'Dragon Mania' -and
    $_.Parent -and $_.Parent.Name -eq 'rms' -and
    $_.Parent.Parent -and $_.Parent.Parent.Name -eq 'freej2me'
  }
)
if(@($dragonDirs).Count -ne 1){ Fail "Expected exactly one Dragon Mania RMS directory, found $(@($dragonDirs).Count)" }
$Dragon=$dragonDirs[0].FullName

# Validate exact known-corrupt stores before touching anything.
$movePlan=@()
foreach($base in $BadStores){
  $meta=Join-Path $Dragon ($base+'.rms')
  if(!(Test-Path -LiteralPath $meta -PathType Leaf)){ Fail "Expected corrupt metadata missing: $meta" }
  $fi=Get-Item -LiteralPath $meta
  if($fi.Length -ne 0){ Fail "Metadata is no longer zero-length: $meta length=$($fi.Length)" }
  if((Sha $meta) -ne $ExpectedEmptySha){ Fail "Zero-length metadata hash mismatch: $meta" }

  $siblings=@(
    Get-ChildItem -LiteralPath $Dragon -File -ErrorAction Stop |
    Where-Object { $_.Name -like ($base+'.*') -and $_.Name -ne ($base+'.rms') }
  )
  if(@($siblings).Count -ne 1){ Fail "Expected exactly one payload sibling for $base, found $(@($siblings).Count)" }

  $movePlan += [PSCustomObject]@{ Kind='META'; Base=$base; Path=$meta; Name=([IO.Path]::GetFileName($meta)); SHA256=(Sha $meta); Length=$fi.Length }
  foreach($s in $siblings){
    $movePlan += [PSCustomObject]@{ Kind='PAYLOAD'; Base=$base; Path=$s.FullName; Name=$s.Name; SHA256=(Sha $s.FullName); Length=$s.Length }
  }
}
if(@($movePlan).Count -ne 4){ Fail "Expected 4 files in move plan, found $(@($movePlan).Count)" }

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$qRoot=Join-Path $Sd ("RG35XX-JAVA-BACKUP\b4-rms-r2-quarantine-"+$stamp)
$qFiles=Join-Path $qRoot 'files'
New-Item -ItemType Directory -Force -Path $qFiles | Out-Null

# Copy first, verify backup hashes, then remove from active RMS directory.
$manifest=@()
foreach($item in $movePlan){
  $dst=Join-Path $qFiles $item.Name
  Copy-Item -LiteralPath $item.Path -Destination $dst -Force
  $copySha=Sha $dst
  if($copySha -ne $item.SHA256){ Fail "Backup hash mismatch for $($item.Name)" }
  $manifest += [PSCustomObject]@{
    Kind=$item.Kind
    Base=$item.Base
    OriginalPath=$item.Path.Substring($Sd.Length)
    BackupRelativePath=('files\'+$item.Name)
    Length=$item.Length
    SHA256=$item.SHA256
  }
}

$manifestPath=Join-Path $qRoot 'MANIFEST.csv'
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

# Only after all backup copies verify, remove the four active files.
foreach($item in $movePlan){
  Remove-Item -LiteralPath $item.Path -Force
  if(Test-Path -LiteralPath $item.Path){ Fail "Failed to quarantine active file: $($item.Path)" }
}

# Verify the six remaining Dragon Mania metadata stores stay untouched and valid-looking.
$remainingMeta=@(Get-ChildItem -LiteralPath $Dragon -File -Filter '*.rms')
if(@($remainingMeta).Count -ne 6){ Fail "Expected 6 remaining Dragon Mania metadata files, found $(@($remainingMeta).Count)" }

$report=Join-Path $Sd 'RG35XX-B4-RMS-R2-QUARANTINE-RESULT.txt'
@(
 'CHECKPOINT=B4-RMS-R2-DATA-QUARANTINE-AB',
 'RESULT=PASS',
 "TIME=$((Get-Date).ToString('s'))",
 "DRAGON_RMS_DIR=$($Dragon.Substring($Sd.Length))",
 "QUARANTINE=$qRoot",
 'QUARANTINED_METADATA_COUNT=2',
 'QUARANTINED_PAYLOAD_COUNT=2',
 'REMAINING_DRAGON_METADATA_COUNT=6',
 'PLATFORM_CHANGE=NONE',
 'RUNTIME_CHANGE=NONE',
 'CORE_CHANGE=NONE',
 'SAVE_DATA_CHANGE=REVERSIBLE_QUARANTINE_ONLY',
 'STABLE=NO'
) | Set-Content -LiteralPath $report -Encoding ASCII

Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-RMS-R2-CURRENT-QUARANTINE.txt') -Value $qRoot -Encoding ASCII

Write-Host 'RMS QUARANTINE PASS'
Write-Host "Dragon RMS: $Dragon"
Write-Host "Backup:     $qRoot"
Write-Host 'Now boot RG35XX and test Dragon Mania before any other change.'
