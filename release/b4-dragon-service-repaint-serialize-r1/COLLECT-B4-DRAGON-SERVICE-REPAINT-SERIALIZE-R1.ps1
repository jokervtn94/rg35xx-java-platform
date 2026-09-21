param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-RMS-CURRENT.txt',
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
  'CHECKPOINT=B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-AB',
  'PRIMARY_VARIABLE=SERVICEREPAINTS_COMPLETION_WAKE_AND_ACTIVE_PAINT_SERIALIZATION',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $serial=@($lines | Select-String -SimpleMatch 'RG35XX-B4-SERVICE-SERIAL')
  $r13h=@($lines | Select-String -SimpleMatch 'RG35XX-R13H-LOOP')
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('SERVICE_SERIAL_LINES='+@($serial).Count)
  foreach($stage in @('WAIT_WAKE','SUPPRESS_AFTER_COMPLETION','SUPPRESS_WHILE_PAINT_ACTIVE','FORCE_FALLBACK')){
    $summary += ('SERVICE_SERIAL_'+$stage+'='+@($serial | Select-String -SimpleMatch ('stage='+$stage)).Count)
  }
  $summary += ('R13H_WAIT_WAKE='+@($r13h | Select-String -SimpleMatch 'stage=SERVICE_WAIT_WAKE').Count)
  $summary += ('R13H_WAIT_WAKE_AUX1='+@($r13h | Select-String -SimpleMatch 'stage=SERVICE_WAIT_WAKE' | Select-String -SimpleMatch 'aux=1').Count)
  $summary += ('R13H_THREAD1_REPAINT_BEGIN='+@($r13h | Select-String -SimpleMatch 'stage=REPAINT_REQUEST_BEGIN' | Select-String -SimpleMatch 'thread=Thread-1').Count)
  $summary += ('RESOURCE_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('RESOURCE_16_THREAD1='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE stage=STREAM_BEGIN' | Select-String -SimpleMatch 'resource=/16' | Select-String -SimpleMatch 'thread=Thread-1').Count)
  $summary += ('RESOURCE_16_EVENTTHREAD='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE stage=STREAM_BEGIN' | Select-String -SimpleMatch 'resource=/16' | Select-String -SimpleMatch 'thread=EventProcessing-Thread').Count)
  $summary += ('TIMEBASE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-TIMEBASE').Count)
  $summary += ('NEGATIVE_ELAPSED='+@($lines | Select-String -SimpleMatch 'negativeElapsed=true').Count)
  $summary += ('IMAGE_DECODE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE').Count)
  $summary += ('GAMECANVAS_FLUSH_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH').Count)
  $summary += ('FRAME_BIND_MISMATCH_TRUE='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND' | Select-String -SimpleMatch 'mismatch=true').Count)
  $summary += ('NETWORK_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13I-NET').Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)

  $serial | ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'SERVICE-REPAINT-SERIAL-LINES.txt') -Encoding ASCII
  $r13h | ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'SERVICE-REPAINT-R13H-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'RESOURCE-TRACE-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'GAMECANVAS-FLUSH-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-TIMEBASE') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'TIMEBASE-TRACE-LINES.txt') -Encoding ASCII
}

$summary += @(
  'EXPECTED_RESULT=no caller-thread paint takeover after paint-completion wake; no overlapping forced paint while another paint callback is active',
  'SERVICE_REPAINT_BEHAVIOR_CHANGE=FALLBACK_SERIALIZATION_ONLY',
  'NORMAL_EDT_REPAINT_PATH=UNCHANGED',
  'ONE_SECOND_RESCUE_FALLBACK=PRESERVED_WHEN_NO_COMPLETION_AND_NO_ACTIVE_PAINT',
  'TIMEBASE_BEHAVIOR_CHANGE=NONE',
  'RESOURCE_LOAD_BEHAVIOR_CHANGE=NONE',
  'IMAGE_DECODE_BEHAVIOR_CHANGE=NONE',
  'GAMECANVAS_FLUSH_BEHAVIOR_CHANGE=NONE',
  'CANONICAL_FRAMEBUFFER_BINDING=PRESERVED',
  'NETWORK_BEHAVIOR_CHANGE=NONE',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'RMS_MUTATION_BY_CHECKPOINT=NONE',
  'CORE_CHANGE=NONE',
  'SCREENSHOT=NOT_A_PASS_CRITERION',
  'STABLE=NO'
)
$summary | Set-Content -LiteralPath (Join-Path $out 'SERVICE-REPAINT-SERIAL-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
