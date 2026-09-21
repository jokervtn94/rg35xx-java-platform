param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-DISPLAY-TRACE-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-DISPLAY-TRACE-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-DISPLAY-TRACE-R1-RMS-CURRENT.txt',
  'freej2me-java-error.log',
  'freej2me-vc3-early.log',
  'freej2me-core.log'
)){
  $p=Join-Path $Sd $n
  if(Test-Path -LiteralPath $p -PathType Leaf){ Copy-Item -LiteralPath $p -Destination $out -Force }
}

function Sha([string]$p){
  if(!(Test-Path -LiteralPath $p -PathType Leaf)){ return $null }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}

$hash=@()
foreach($rel in @(
  'CFW\java\bin\jamvm',
  'CFW\java\share\classpath\glibj.zip',
  'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',
  'BIOS\freej2me-lr.jar'
)){
  $p=Join-Path $Sd $rel
  if(Test-Path -LiteralPath $p -PathType Leaf){ $hash += ($rel+'='+(Sha $p)) }
}
$hash | Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

$summary=@(
  'CHECKPOINT=B4-DRAGON-DISPLAY-TRACE-R1-AB',
  'PRIMARY_VARIABLE=BOUNDED_DISPLAY_CANVAS_GAME_LOOP_OBSERVABILITY_ONLY',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('DISPLAY_EVENT_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13E-EVENT').Count)
  $summary += ('CANVAS_LOOP_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13H-LOOP').Count)

  foreach($m in @(
    'SETCURRENT_REQUEST','SETCURRENT_RUN_BEGIN','SETCURRENT_RUN_DONE',
    'SC_SHOW_BEGIN','SC_SHOW_DONE','SC_ASSIGN_BEGIN','SC_ASSIGN_DONE',
    'SC_REPAINT_BEGIN','SC_REPAINT_DONE','SC_FLUSH_BEGIN','SC_FLUSH_DONE',
    'DISPLAY_PAINT_BEGIN','DISPLAY_PAINT_DONE',
    'REPAINT_REQUEST_BEGIN','PAINT_CALLBACK_BEGIN','PAINT_CALLBACK_DONE',
    'REPAINT_FLUSH_BEGIN','REPAINT_FLUSH_DONE','REPAINT_REQUEST_DONE',
    'SERVICE_ENTER','SERVICE_EARLY_RETURN','SERVICE_EVENTTHREAD_REPAINT_BEGIN',
    'SERVICE_EVENTTHREAD_REPAINT_DONE','SERVICE_LOCK_BEGIN','SERVICE_LOCK_ACQUIRED',
    'SERVICE_WAIT_BEGIN','SERVICE_WAIT_WAKE',
    'LR_RX_DOWN','LR_RX_UP','MP_POST_DOWN','MP_POST_UP',
    'MP_DELIVER_DOWN_BEGIN','MP_DELIVER_DOWN_DONE','MP_DELIVER_UP_BEGIN','MP_DELIVER_UP_DONE'
  )){
    $summary += ($m+'='+@($lines | Select-String -SimpleMatch $m).Count)
  }

  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('GETSEQUENCER_ERRORS='+@($lines | Select-String -SimpleMatch 'NoSuchMethodError: getSequencer').Count)
}

$summary += @(
  'EXPECTED_OBSERVATION=Gameloft logo freeze if symptom persists',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'RMS_MUTATION_BY_TRACE=NONE',
  'SCREENSHOT=NOT_A_PASS_CRITERION',
  'STABLE=NO'
)
$summary | Set-Content -LiteralPath (Join-Path $out 'DISPLAY-TRACE-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
