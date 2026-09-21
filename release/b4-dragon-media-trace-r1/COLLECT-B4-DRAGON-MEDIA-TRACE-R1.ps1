param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"'); if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}; if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-MEDIA-TRACE-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null

foreach($n in @(
 'RG35XX-B4-DRAGON-MEDIA-TRACE-R1-INSTALL-RESULT.txt',
 'RG35XX-B4-RMS-R2-QUARANTINE-RESULT.txt',
 'freej2me-java-error.log',
 'freej2me-vc3-early.log',
 'freej2me-core.log'
)){
 $p=Join-Path $Sd $n
 if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}
}

function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}; return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
$hash=@()
foreach($rel in @('CFW\java\bin\jamvm','CFW\java\share\classpath\glibj.zip','CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so','BIOS\freej2me-lr.jar')){
 $p=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $p -PathType Leaf){$hash+=("$rel="+(Sha $p))}
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

$java=Join-Path $Sd 'freej2me-java-error.log'
$summary=@('CHECKPOINT=B4-DRAGON-MEDIA-TRACE-R1-AB')
if(Test-Path -LiteralPath $java -PathType Leaf){
 $lines=@(Get-Content -LiteralPath $java)
 $summary+=("JAVA_LOG_LINES="+@($lines).Count)
 $summary+=("MEDIA_TRACE_LINES="+@($lines|Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
 foreach($m in @(
  'MANAGER_CREATE_STREAM_BEGIN','MANAGER_CREATE_LOCATOR_BEGIN',
  'PLAYER_START_BEGIN','PLAYER_START_BLOCKED_STATE',
  'MIDI_GETSEQUENCER_BEGIN','MIDI_GETSEQUENCER_DONE',
  'MIDI_PREPARE_SUBSYSTEM_BEGIN','MIDI_PREPARE_SUBSYSTEM_DONE',
  'MIDI_PREFETCH_FAIL','WAV_GETCLIP_BEGIN','WAV_GETCLIP_DONE',
  'WAV_PREFETCH_FAIL','PLAYER_EVENT'
 )){
  $summary+=($m+'='+@($lines|Select-String -SimpleMatch $m).Count)
 }
 $summary+=("STRING_INDEX_OOB="+@($lines|Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
 $summary+=("GETSEQUENCER_ERRORS="+@($lines|Select-String -SimpleMatch 'NoSuchMethodError: getSequencer').Count)
 $summary+=("CLIP_ERRORS="+@($lines|Select-String -SimpleMatch 'LineUnavailableException: no Clip available').Count)
}
$summary+=@(
 'TEST_GAME=dragon-mania-s40v6',
 'EXPECTED_OBSERVATION=stop at Gameloft logo if symptom persists',
 'RMS_QUARANTINE=KEEP',
 'SCREENSHOT=NOT_A_PASS_CRITERION',
 'STABLE=NO'
)
$summary|Set-Content -LiteralPath (Join-Path $out 'MEDIA-TRACE-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
