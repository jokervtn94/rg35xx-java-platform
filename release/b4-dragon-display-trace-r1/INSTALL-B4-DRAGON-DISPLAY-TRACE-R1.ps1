param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedOldRuntime='0c2f8658e7786cd3f97285c94c609623464cb8f04311b359bfd0a95a7109f11e'
$NewRuntime='__NEW_RUNTIME_SHA256__'

function Fail([string]$m){throw "B4-DRAGON-DISPLAY-TRACE-R1 INSTALL FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}; return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
function Resolve-Sd([string]$raw){
 if([string]::IsNullOrWhiteSpace($raw)){$raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)'}
 $raw=$raw.Trim().Trim('"')
 if($raw -match '^[A-Za-z]$'){$raw=$raw+':'}
 if($raw -match '^[A-Za-z]:$'){$raw=$raw+'\'}
 if(!(Test-Path -LiteralPath $raw -PathType Container)){Fail "SD root not found: $raw"}
 $resolved=(Resolve-Path -LiteralPath $raw).Path
 $trim=$resolved.TrimEnd('\')
 if($trim.Length -ne 2 -or $trim[1] -ne ':'){Fail "Refusing non-drive-root path: $resolved"}
 return $trim+'\'
}

$Sd=Resolve-Sd $SdRoot
$Payload=Join-Path $PSScriptRoot 'payload\freej2me-lr.jar'
if((Sha $Payload) -ne $NewRuntime){Fail "Payload runtime hash mismatch expected=$NewRuntime actual=$(Sha $Payload)"}

$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$current=Join-Path $Sd 'BIOS\freej2me-lr.jar'

if((Sha $jamvm) -ne $ExpectedJamvm){Fail 'JamVM L precondition failed'}
if((Sha $glibj) -ne $ExpectedGlibj){Fail 'glibj precondition failed'}
if((Sha $core) -ne $ExpectedCore){Fail 'Protected B4 core precondition failed'}
if((Sha $current) -ne $ExpectedOldRuntime){Fail "B4-DRAGON-MEDIA-TRACE-R1 runtime precondition failed actual=$(Sha $current)"}

# Validate current Dragon Mania RMS state without assuming that a basename
# which was corrupt earlier must remain absent forever. The game may legitimately
# recreate the same store. Corruption is defined by the file state/content, not
# by the basename alone.
$PreviouslyCorruptStores=@(
 'ffffffff9c61314e09vhjlzvf1zxn0',
 'ffffffff9c61314e14u2hvcf9vbmxvy2tozxc_'
)

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

$rmsState=@()
foreach($base in $PreviouslyCorruptStores){
  $meta=Join-Path $Dragon ($base+'.rms')

  if(!(Test-Path -LiteralPath $meta -PathType Leaf)){
    $rmsState += "$base=ABSENT"
    continue
  }

  $fi=Get-Item -LiteralPath $meta
  if($fi.Length -eq 0){
    Fail "Dragon Mania RMS store is currently ZERO-LENGTH again: $($fi.Name). Run ENSURE-B4-DRAGON-RMS-PRECONDITION.cmd to back up and quarantine only this proven corrupt state."
  }

  # A recreated non-zero store is not considered corrupt merely because it has
  # the same basename. Validate the current metadata against the format emitted
  # by pinned RecordStore.saveRecordStore().
  $raw=[System.IO.File]::ReadAllText($meta)
  $trim=$raw.Trim()
  if($trim.Length -lt 2 -or !$trim.StartsWith('{') -or !$trim.EndsWith('}')){
    Fail "Recreated RMS metadata has invalid outer JSON braces: $($fi.Name) length=$($fi.Length)"
  }

  try {
    $obj=$trim | ConvertFrom-Json
  } catch {
    Fail "Recreated RMS metadata is not valid JSON: $($fi.Name) error=$($_.Exception.Message)"
  }

  $propNames=@($obj.PSObject.Properties | ForEach-Object {$_.Name})
  foreach($req in @('rmsVersion','recordName','baseName','ownerName','compatibleLastId','ids')){
    if($propNames -notcontains $req){
      Fail "Recreated RMS metadata missing required key '$req': $($fi.Name)"
    }
  }

  if([string]$obj.baseName -ne $base){
    Fail "Recreated RMS baseName mismatch: file=$base metadata=$([string]$obj.baseName)"
  }

  $ids=@($obj.ids)
  foreach($id in $ids){
    if($null -eq $id){ continue }
    $idText=[string]$id
    if($idText -notmatch '^[0-9]+$'){
      Fail "Recreated RMS ids contains non-integer value '$idText': $($fi.Name)"
    }

    $payload=Join-Path $Dragon ($base+'.'+$idText)
    if(!(Test-Path -LiteralPath $payload -PathType Leaf)){
      Fail "Recreated RMS metadata references missing payload: $([IO.Path]::GetFileName($payload))"
    }

    $tagName='tag:'+$idText
    if($propNames -notcontains $tagName){
      Fail "Recreated RMS metadata missing $tagName for payload ${idText}: $($fi.Name)"
    }
  }

  $rmsState += "$base=RECREATED_NONZERO_STRUCTURALLY_VALID(length=$($fi.Length),sha=$(Sha $meta),ids=$(@($ids).Count))"
}

# Do not require exactly six stores anymore: the game is allowed to recreate
# one or both stores. The two prior zero-byte instances were corrupt; the
# basenames themselves are not forbidden.
$currentMeta=@(Get-ChildItem -LiteralPath $Dragon -File -Filter '*.rms' -ErrorAction Stop)
$rmsPrecondition='CURRENT_STATE_STRUCTURALLY_VALID'
$rmsState += "TOTAL_DRAGON_METADATA=$(@($currentMeta).Count)"

$rmsReport=Join-Path $Sd 'RG35XX-B4-DRAGON-DISPLAY-TRACE-R1-RMS-CURRENT.txt'
@(
  'CHECKPOINT=B4-DRAGON-DISPLAY-TRACE-R1-AB',
  'RMS_PRECONDITION=PASS',
  "TIME=$((Get-Date).ToString('s'))",
  "DRAGON_RMS_DIR=$($Dragon.Substring($Sd.Length))",
  "TOTAL_DRAGON_METADATA=$(@($currentMeta).Count)",
  $rmsState,
  'RMS_MUTATION_BY_INSTALLER=NONE',
  'STABLE=NO'
) | Set-Content -LiteralPath $rmsReport -Encoding ASCII

$targets=@(
 'BIOS\freej2me-lr.jar',
 'BIOS\freej2me_plus-lr.jar',
 'CFW\java\share\freej2me\freej2me-lr.jar',
 'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
 'CFW\retroarch\system\freej2me-lr.jar'
)

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\b4-dragon-display-trace-r1-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$state=@()

foreach($rel in $targets){
 $src=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $src -PathType Leaf){
   $dst=Join-Path $backup $rel
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
   Copy-Item -LiteralPath $src -Destination $dst -Force
   $state+="EXISTED|$rel"
 } else {
   $state+="ABSENT|$rel"
 }
}
$state | Set-Content -LiteralPath (Join-Path $backup 'STATE.txt') -Encoding ASCII

try {
 foreach($rel in $targets){
   $dst=Join-Path $Sd $rel
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
   $tmp=$dst+'.b4mediatracenew'
   if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force}
   Copy-Item -LiteralPath $Payload -Destination $tmp -Force
   if((Sha $tmp) -ne $NewRuntime){Fail "staged runtime hash mismatch: $rel"}
   Move-Item -LiteralPath $tmp -Destination $dst -Force
   if((Sha $dst) -ne $NewRuntime){Fail "installed runtime hash mismatch: $rel"}
 }

 foreach($name in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log')){
   $p=Join-Path $Sd $name
   if(Test-Path -LiteralPath $p -PathType Leaf){
     Copy-Item -LiteralPath $p -Destination (Join-Path $backup $name) -Force
     Remove-Item -LiteralPath $p -Force
   }
 }

 @(
  'CHECKPOINT=B4-DRAGON-DISPLAY-TRACE-R1-AB',
  'RESULT=PASS',
  'STATUS=BUILD-PASS_INSTALLED_DEVICE-TRACE-PENDING',
  "TIME=$((Get-Date).ToString('s'))",
  "BACKUP=$backup",
  "OLD_RUNTIME_SHA256=$ExpectedOldRuntime",
  "NEW_RUNTIME_SHA256=$NewRuntime",
  "CORE_SHA256=$ExpectedCore",
  "JAMVM_SHA256=$ExpectedJamvm",
  "GLIBJ_SHA256=$ExpectedGlibj",
  'PRIMARY_VARIABLE=BOUNDED_DISPLAY_CANVAS_GAME_LOOP_OBSERVABILITY_ONLY',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'DISPLAY_CANVAS_BEHAVIOR_CHANGE=NONE',
  'RMS_QUARANTINE_REQUIRED=YES',
  "RMS_PRECONDITION=$rmsPrecondition",
  "RMS_CURRENT_REPORT=$rmsReport",
  'CORE_CHANGE=NONE',
  'STABLE=NO'
 ) | Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-DRAGON-DISPLAY-TRACE-R1-INSTALL-RESULT.txt') -Encoding ASCII

 Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-DRAGON-DISPLAY-TRACE-R1-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - B4 DRAGON MEDIA TRACE R1'
}
catch {
 foreach($line in Get-Content -LiteralPath (Join-Path $backup 'STATE.txt')){
   $p=$line.Split('|',2); if($p.Count -ne 2){continue}
   $kind=$p[0]; $rel=$p[1]
   $dst=Join-Path $Sd $rel
   $bak=Join-Path $backup $rel
   if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue}
   if($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)){
     New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
     Copy-Item -LiteralPath $bak -Destination $dst -Force
   }
 }
 throw
}
