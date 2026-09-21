param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-RESOURCE-LOAD-TRACE-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-RESOURCE-LOAD-TRACE-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-RESOURCE-LOAD-TRACE-R1-RMS-CURRENT.txt',
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
  'CHECKPOINT=B4-DRAGON-RESOURCE-LOAD-TRACE-R1-AB',
  'PRIMARY_VARIABLE=BOUNDED_RESOURCE_AND_IMAGE_DECODE_OBSERVABILITY_ONLY',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('RESOURCE_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('RESOURCE_STREAM_BEGIN='+@($lines | Select-String -SimpleMatch 'stage=STREAM_BEGIN' | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('RESOURCE_STREAM_END='+@($lines | Select-String -SimpleMatch 'stage=STREAM_END' | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('RESOURCE_STREAM_FALLBACK='+@($lines | Select-String -SimpleMatch 'stage=STREAM_FALLBACK').Count)
  $summary += ('RESOURCE_BYTES_BEGIN='+@($lines | Select-String -SimpleMatch 'stage=BYTES_BEGIN' | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('RESOURCE_BYTES_END='+@($lines | Select-String -SimpleMatch 'stage=BYTES_END' | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE').Count)
  $summary += ('RESOURCE_BYTES_FAIL='+@($lines | Select-String -SimpleMatch 'stage=BYTES_FAIL').Count)
  $summary += ('IMAGE_DECODE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE').Count)
  $summary += ('IMAGE_NAME_BEGIN='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE stage=NAME_BEGIN').Count)
  $summary += ('IMAGE_NAME_END='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE stage=NAME_END').Count)
  $summary += ('IMAGE_STREAM_BEGIN='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE stage=STREAM_BEGIN').Count)
  $summary += ('IMAGE_STREAM_END='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE stage=STREAM_END').Count)
  $summary += ('IMAGE_BYTES_BEGIN='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE stage=BYTES_BEGIN').Count)
  $summary += ('IMAGE_BYTES_END='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE stage=BYTES_END').Count)
  $summary += ('GAMECANVAS_FLUSH_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH').Count)
  $summary += ('FRAME_BIND_MISMATCH_TRUE='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND' | Select-String -SimpleMatch 'mismatch=true').Count)
  $summary += ('PNG_ICCP_STRIP='+@($lines | Select-String -SimpleMatch 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk').Count)
  $summary += ('NETWORK_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13I-NET').Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)

  @($lines | Select-String -SimpleMatch 'RG35XX-B4-RESOURCE-TRACE') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'RESOURCE-TRACE-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-IMAGE-DECODE') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'IMAGE-DECODE-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'GAMECANVAS-FLUSH-LINES.txt') -Encoding ASCII
}

$summary += @(
  'EXPECTED_RESULT=identify unmatched or long-running resource/image preload boundary while Gameloft logo remains visible',
  'RESOURCE_LOAD_BEHAVIOR_CHANGE=NONE',
  'IMAGE_DECODE_BEHAVIOR_CHANGE=NONE',
  'GAMECANVAS_FLUSH_DIAGNOSTICS=PRESERVED',
  'CANONICAL_FRAMEBUFFER_BINDING=PRESERVED',
  'PNG_ICCP_COMPATIBILITY=PRESERVED',
  'NETWORK_BEHAVIOR_CHANGE=NONE',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'RMS_MUTATION_BY_CHECKPOINT=NONE',
  'CORE_CHANGE=NONE',
  'SCREENSHOT=NOT_A_PASS_CRITERION',
  'STABLE=NO'
)
$summary | Set-Content -LiteralPath (Join-Path $out 'RESOURCE-LOAD-TRACE-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
