param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'

if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-HOTPATH-R2-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null

foreach($n in @(
 'RG35XX-B4-HOTPATH-R2-INSTALL-RESULT.txt',
 'freej2me-vc3-early.log',
 'freej2me-core.log',
 'freej2me-java-error.log',
 'freej2me-java-control.log'
)){
 $p=Join-Path $Sd $n
 if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}
}

$hash=@()
foreach($rel in @(
 'CFW\java\bin\jamvm',
 'CFW\java\share\classpath\glibj.zip',
 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',
 'BIOS\freej2me-lr.jar'
)){
 $p=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $p -PathType Leaf){
   $hash+=("$rel="+(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant())
 }
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

$java=Join-Path $Sd 'freej2me-java-error.log'
$summary=@(
 'CHECKPOINT=B4-HOTPATH-R2-AB',
 'PRIMARY_VARIABLE=UNBOUNDED_FRAME_TRANSPORT_DIAGNOSTICS_ONLY'
)
if(Test-Path -LiteralPath $java -PathType Leaf){
 $lines=Get-Content -LiteralPath $java
 $summary+=("JAVA_LOG_LINES="+$lines.Count)
 $summary+=("RG35XX_JAVA_DIAG_LINES="+(($lines|Select-String -SimpleMatch 'RG35XX-JAVA-DIAG:').Count))
 $summary+=("RG35XX_VIDEO_JAVA_ERROR_LINES="+(($lines|Select-String -SimpleMatch 'RG35XX-VIDEO JAVA').Count))
 $summary+=("GETSEQUENCER_ERRORS="+(($lines|Select-String -SimpleMatch 'NoSuchMethodError: getSequencer').Count))
 $summary+=("CLIP_ERRORS="+(($lines|Select-String -SimpleMatch 'LineUnavailableException: no Clip available').Count))
 $summary+=("PNG_ICC_V4_ERRORS="+(($lines|Select-String -SimpleMatch 'Wrong major version number:4').Count))
}
$summary+=@(
 'REQUIRED_VISUAL_REGRESSION_CHECK=green tint must remain fixed by direct physical LCD observation',
 'REQUIRED_INPUT_CHECK=usable',
 'REQUIRED_EXIT_CHECK=normal exit; no hard reset',
 'AUDIO_CHANGE=NONE',
 'FONT_CHANGE=NONE',
 'CORE_CHANGE=NONE',
 'FULL_PLATFORM_STABLE=NO'
)
$summary|Set-Content -LiteralPath (Join-Path $out 'HOTPATH-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
