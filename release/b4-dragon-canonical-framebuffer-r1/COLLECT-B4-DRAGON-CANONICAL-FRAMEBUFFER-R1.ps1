param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-RMS-CURRENT.txt',
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
  'CHECKPOINT=B4-DRAGON-CANONICAL-FRAMEBUFFER-R1-AB',
  'PRIMARY_VARIABLE=CURRENT_FRONTBUFFER_OBJECT_AND_DATA_BOUND_TOGETHER_AT_TRANSPORT_REQUEST',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)
$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('FRAME_BIND_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND').Count)
  $summary += ('FRAME_BIND_REQUEST='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND stage=REQUEST').Count)
  $summary += ('FRAME_BIND_CONTROL='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND stage=CONTROL').Count)
  $summary += ('FRAME_BIND_MISMATCH_TRUE='+@($lines | Select-String -SimpleMatch 'mismatch=true').Count)
  $summary += ('FRAME_BIND_CHANGED_TRUE='+@($lines | Select-String -SimpleMatch 'changed=true').Count)
  $summary += ('PNG_ICCP_STRIP='+@($lines | Select-String -SimpleMatch 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk').Count)
  $summary += ('NETWORK_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13I-NET').Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('DISPLAY_EVENT_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13E-EVENT').Count)
  $summary += ('CANVAS_LOOP_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13H-LOOP').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)
}
$summary += @(
  'EXPECTED_RESULT=observe whether Dragon progresses beyond Gameloft logo',
  'CANONICAL_FRAMEBUFFER_BINDING=ENABLED',
  'PNG_ICCP_COMPATIBILITY=PRESERVED',
  'NETWORK_BEHAVIOR_CHANGE=NONE',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'DISPLAY_CANVAS_BEHAVIOR_CHANGE=NONE',
  'RMS_MUTATION_BY_CHECKPOINT=NONE',
  'CORE_CHANGE=NONE',
  'SCREENSHOT=NOT_A_PASS_CRITERION',
  'STABLE=NO'
)
$summary | Set-Content -LiteralPath (Join-Path $out 'CANONICAL-FRAMEBUFFER-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
