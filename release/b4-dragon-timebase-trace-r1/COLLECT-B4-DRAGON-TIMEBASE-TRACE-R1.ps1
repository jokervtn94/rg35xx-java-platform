param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-TIMEBASE-TRACE-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-TIMEBASE-TRACE-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-TIMEBASE-TRACE-R1-RMS-CURRENT.txt',
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
  'CHECKPOINT=B4-DRAGON-TIMEBASE-TRACE-R1-AB',
  'PRIMARY_VARIABLE=BOUNDED_GAME_VIRTUAL_TIME_AND_SLEEP_OBSERVABILITY_ONLY',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $tb=@($lines | Select-String -SimpleMatch 'RG35XX-B4-TIMEBASE')
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('TIMEBASE_LINES='+@($tb).Count)
  foreach($stage in @('MILLIS','NANOS','SLEEP_BEGIN','SLEEP_END','DRAWSLEEP_BEGIN','DRAWSLEEP_END','YIELD_BEGIN','YIELD_END')){
    $summary += ('TIMEBASE_'+$stage+'='+@($tb | Select-String -SimpleMatch ('stage='+$stage)).Count)
  }
  $summary += ('NEGATIVE_ELAPSED='+@($tb | Select-String -SimpleMatch 'negativeElapsed=true').Count)
  $summary += ('RESOURCE_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('IMAGE_DECODE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE').Count)
  $summary += ('GAMECANVAS_FLUSH_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH').Count)
  $summary += ('FRAME_BIND_MISMATCH_TRUE='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND' | Select-String -SimpleMatch 'mismatch=true').Count)
  $summary += ('NETWORK_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13I-NET').Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)

  $tb | ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'TIMEBASE-TRACE-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'RESOURCE-TRACE-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'GAMECANVAS-FLUSH-LINES.txt') -Encoding ASCII
}

$summary += @(
  'EXPECTED_RESULT=verify game-visible virtual time monotonicity and requested-vs-actual sleep behavior while Gameloft logo remains visible',
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
$summary | Set-Content -LiteralPath (Join-Path $out 'TIMEBASE-TRACE-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
