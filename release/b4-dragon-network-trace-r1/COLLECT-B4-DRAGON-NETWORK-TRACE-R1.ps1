param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-NETWORK-TRACE-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-NETWORK-TRACE-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-NETWORK-TRACE-R1-RMS-CURRENT.txt',
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
  'CHECKPOINT=B4-DRAGON-NETWORK-TRACE-R1-AB',
  'PRIMARY_VARIABLE=BOUNDED_NETWORK_DEPENDENCY_OBSERVABILITY_ONLY',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('NETWORK_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13I-NET').Count)
  foreach($m in @(
    'CONNECTOR_OPEN_BEGIN',
    'CONNECTOR_NETWORK_BRANCH',
    'CONNECTOR_OPEN_DONE',
    'HTTP_CTOR',
    'HTTP_CONNECT',
    'HTTP_RESPONSE_CODE_STUB',
    'HTTP_INPUT_STREAM_NULL',
    'HTTP_OUTPUT_STREAM_NULL'
  )){
    $summary += ($m+'='+@($lines | Select-String -SimpleMatch $m).Count)
  }

  $summary += ('DISPLAY_EVENT_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13E-EVENT').Count)
  $summary += ('CANVAS_LOOP_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13H-LOOP').Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)
}

$summary += @(
  'EXPECTED_OBSERVATION=Gameloft logo freeze if symptom persists',
  'NETWORK_BEHAVIOR_CHANGE=NONE',
  'RMS_MUTATION_BY_TRACE=NONE',
  'DISPLAY_CANVAS_BEHAVIOR_CHANGE=NONE',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'SCREENSHOT=NOT_A_PASS_CRITERION',
  'STABLE=NO'
)
$summary | Set-Content -LiteralPath (Join-Path $out 'NETWORK-TRACE-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
