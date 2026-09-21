param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){ $SdRoot=Read-Host 'Nhap ky tu o SD RG35XX' }
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){ $SdRoot=$SdRoot+':' }
if($SdRoot -match '^[A-Za-z]:$'){ $SdRoot=$SdRoot+'\' }
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-DRAGON-GAMECANVAS-FLUSH-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($n in @(
  'RG35XX-B4-DRAGON-GAMECANVAS-FLUSH-R1-INSTALL-RESULT.txt',
  'RG35XX-B4-DRAGON-GAMECANVAS-FLUSH-R1-RMS-CURRENT.txt',
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
  'CHECKPOINT=B4-DRAGON-GAMECANVAS-FLUSH-R1-AB',
  'PRIMARY_VARIABLE=BOUNDED_GAMECANVAS_TO_FRONTBUFFER_CONTENT_OBSERVABILITY_ONLY',
  'TEST_GAME=dragon-mania-s40v6',
  'TEST_ONLY_DRAGON=YES'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
  $lines=@(Get-Content -LiteralPath $java)
  $summary += ('JAVA_LOG_LINES='+@($lines).Count)
  $summary += ('MOBILE_FLUSH_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MOBILE-FLUSH').Count)
  $summary += ('PG_FLUSH_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH').Count)
  $summary += ('PG_BEFORE='+@($lines | Select-String -SimpleMatch 'stage=PG_BEFORE').Count)
  $summary += ('PG_ALIAS_RETURN='+@($lines | Select-String -SimpleMatch 'stage=PG_ALIAS_RETURN').Count)
  $summary += ('PG_FULLCOPY_DONE='+@($lines | Select-String -SimpleMatch 'stage=PG_FULLCOPY_DONE').Count)
  $summary += ('PG_COPY_DONE='+@($lines | Select-String -SimpleMatch 'stage=PG_COPY_DONE').Count)
  $summary += ('FLUSH_ALIAS_TRUE='+@($lines | Select-String -SimpleMatch 'alias=true').Count)
  $summary += ('FRAME_BIND_MISMATCH_TRUE='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND' | Select-String -SimpleMatch 'mismatch=true').Count)
  $summary += ('PNG_ICCP_STRIP='+@($lines | Select-String -SimpleMatch 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk').Count)
  $summary += ('NETWORK_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-R13I-NET').Count)
  $summary += ('MEDIA_TRACE_LINES='+@($lines | Select-String -SimpleMatch 'RG35XX-B4-MEDIA-TRACE').Count)
  $summary += ('STRING_INDEX_OOB='+@($lines | Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
  $summary += ('NULL_POINTER_EXCEPTION='+@($lines | Select-String -SimpleMatch 'java.lang.NullPointerException').Count)

  @($lines | Select-String -SimpleMatch 'RG35XX-B4-GAMECANVAS-FLUSH') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'GAMECANVAS-FLUSH-LINES.txt') -Encoding ASCII
  @($lines | Select-String -SimpleMatch 'RG35XX-B4-MOBILE-FLUSH') |
    ForEach-Object { $_.Line } |
    Set-Content -LiteralPath (Join-Path $out 'MOBILE-FLUSH-LINES.txt') -Encoding ASCII
}

$summary += @(
  'EXPECTED_RESULT=classify source buffer content and source-to-frontbuffer copy semantics while Gameloft logo is visible',
  'GAMECANVAS_FLUSH_BEHAVIOR_CHANGE=NONE',
  'CANONICAL_FRAMEBUFFER_BINDING=PRESERVED',
  'PNG_ICCP_COMPATIBILITY=PRESERVED',
  'NETWORK_BEHAVIOR_CHANGE=NONE',
  'MEDIA_BEHAVIOR_CHANGE=NONE',
  'RMS_MUTATION_BY_CHECKPOINT=NONE',
  'CORE_CHANGE=NONE',
  'SCREENSHOT=NOT_A_PASS_CRITERION',
  'STABLE=NO'
)
$summary | Set-Content -LiteralPath (Join-Path $out 'GAMECANVAS-FLUSH-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
