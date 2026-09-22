param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("RG35XX-CLEAN-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null

foreach($n in @(
 'RG35XX-CLEAN-CONSOLIDATED-R1-INSTALL-RESULT.txt',
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

$summary=@(
 'CHECKPOINT=RG35XX-CLEAN-CONSOLIDATED-R1',
 'BUILD_BASE=verified-clean-platform-v1',
 'FULL_PLATFORM_STABLE=NO'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
 $lines=Get-Content -LiteralPath $java
 $summary+=("JAVA_LOG_LINES="+$lines.Count)
 $summary+=("RG35XX_JAVA_DIAG_LINES="+(($lines|Select-String -SimpleMatch 'RG35XX-JAVA-DIAG:').Count))
 $summary+=("RG35XX_VIDEO_JAVA_ERROR_LINES="+(($lines|Select-String -SimpleMatch 'RG35XX-VIDEO JAVA').Count))
 $summary+=("PNG_ICCP_STRIP="+(($lines|Select-String -SimpleMatch 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk').Count))
 $summary+=("PNG_ICC_V4_ERRORS="+(($lines|Select-String -SimpleMatch 'Wrong major version number:4').Count))
 $summary+=("DYNAMIC_VIEW_LINES="+(($lines|Select-String -SimpleMatch 'RG35XX-VC7R2-VIEW:').Count))
 $summary+=("FRAME_BIND_LINES="+(($lines|Select-String -SimpleMatch 'RG35XX-B4-FRAME-BIND').Count))
 $summary+=("FRAME_BIND_MISMATCH_TRUE="+(($lines|Select-String -SimpleMatch 'mismatch=true').Count))
 $summary+=("GETSEQUENCER_ERRORS="+(($lines|Select-String -SimpleMatch 'NoSuchMethodError: getSequencer').Count))
 $summary+=("CLIP_ERRORS="+(($lines|Select-String -SimpleMatch 'LineUnavailableException').Count))
 $summary+=("RENDER_SCANLINE_NPE="+(($lines|Select-String -SimpleMatch 'AbstractGraphics2D.renderScanline').Count))
 $summary+=("RMS_STRING_INDEX_ERRORS="+(($lines|Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count))
 $summary+=("RMS_LOAD_STACK_HITS="+(($lines|Select-String -SimpleMatch 'RecordStore.loadRecordStore').Count))
 $summary+=("NULL_POINTER_EXCEPTIONS="+(($lines|Select-String -SimpleMatch 'NullPointerException').Count))
}

$early=Join-Path $Sd 'freej2me-vc3-early.log'
if(Test-Path -LiteralPath $early -PathType Leaf){
 $elines=Get-Content -LiteralPath $early
 $summary+=("CORE_INIT="+(($elines|Select-String -SimpleMatch 'B4 CORE_INIT').Count))
 $summary+=("JAVA_READY="+(($elines|Select-String -SimpleMatch 'B4 JAVA_READY').Count))
 $summary+=("LOAD_GAME="+(($elines|Select-String -SimpleMatch 'B4 LOAD_GAME_ENTER').Count))
 $summary+=("IPC_RUN_SENT="+(($elines|Select-String -SimpleMatch 'B4 IPC_RUN_SENT').Count))
 $summary+=("CORE_DEINIT="+(($elines|Select-String -SimpleMatch 'B4 CORE_DEINIT').Count))
}

$summary+=@(
 'PHYSICAL_LCD_CHECK=report color/render directly from device',
 'INPUT_CHECK=report usable/not usable',
 'EXIT_CHECK=report normal exit/hard reset',
 'AUDIO_STATUS=known pending unless real-game evidence proves otherwise',
 'FONT_STATUS=upstream clean path; experimental bitmap font not admitted',
 'RMS_STATUS=no new persistence rewrite in R1'
)
$summary|Set-Content -LiteralPath (Join-Path $out 'R1-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
