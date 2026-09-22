param(
 [Parameter(Mandatory=$false, Position=0)][string]$SdRoot,
 [switch]$SelfTest
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function Count-Matches([object[]]$InputLines,[string]$Needle){
 return @($InputLines | Select-String -SimpleMatch $Needle).Count
}

if($SelfTest){
 $zero=@('alpha','beta')
 $one=@('alpha marker','beta')
 $many=@('marker one','beta marker','marker three')
 if((Count-Matches $zero 'marker') -ne 0){throw 'SELFTEST zero-match failed'}
 if((Count-Matches $one 'marker') -ne 1){throw 'SELFTEST singleton-match failed'}
 if((Count-Matches $many 'marker') -ne 3){throw 'SELFTEST multi-match failed'}
 $singleLine=@('only-line')
 if($singleLine.Count -ne 1){throw 'SELFTEST singleton-content failed'}
 Write-Output 'SELFTEST_ZERO_MATCH=PASS'
 Write-Output 'SELFTEST_SINGLE_MATCH=PASS'
 Write-Output 'SELFTEST_MULTI_MATCH=PASS'
 Write-Output 'SELFTEST_SINGLE_CONTENT_LINE=PASS'
 exit 0
}

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
 'CHECKPOINT=RG35XX-CLEAN-CONSOLIDATED-R1-COLLECTOR-R1.1',
 'BUILD_BASE=verified-clean-platform-v1',
 'FULL_PLATFORM_STABLE=NO'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
 $lines=@(Get-Content -LiteralPath $java)
 $summary+=("JAVA_LOG_LINES="+$lines.Count)
 $summary+=("RG35XX_JAVA_DIAG_LINES="+(Count-Matches $lines 'RG35XX-JAVA-DIAG:'))
 $summary+=("RG35XX_VIDEO_JAVA_ERROR_LINES="+(Count-Matches $lines 'RG35XX-VIDEO JAVA'))
 $summary+=("PNG_ICCP_STRIP="+(Count-Matches $lines 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk'))
 $summary+=("PNG_ICC_V4_ERRORS="+(Count-Matches $lines 'Wrong major version number:4'))
 $summary+=("DYNAMIC_VIEW_LINES="+(Count-Matches $lines 'RG35XX-VC7R2-VIEW:'))
 $summary+=("FRAME_BIND_LINES="+(Count-Matches $lines 'RG35XX-B4-FRAME-BIND'))
 $summary+=("FRAME_BIND_MISMATCH_TRUE="+(Count-Matches $lines 'mismatch=true'))
 $summary+=("GETSEQUENCER_ERRORS="+(Count-Matches $lines 'NoSuchMethodError: getSequencer'))
 $summary+=("CLIP_ERRORS="+(Count-Matches $lines 'LineUnavailableException'))
 $summary+=("RENDER_SCANLINE_NPE="+(Count-Matches $lines 'AbstractGraphics2D.renderScanline'))
 $summary+=("RMS_STRING_INDEX_ERRORS="+(Count-Matches $lines 'StringIndexOutOfBoundsException'))
 $summary+=("RMS_LOAD_STACK_HITS="+(Count-Matches $lines 'RecordStore.loadRecordStore'))
 $summary+=("NULL_POINTER_EXCEPTIONS="+(Count-Matches $lines 'NullPointerException'))
}

$early=Join-Path $Sd 'freej2me-vc3-early.log'
if(Test-Path -LiteralPath $early -PathType Leaf){
 $elines=@(Get-Content -LiteralPath $early)
 $summary+=("CORE_INIT="+(Count-Matches $elines 'B4 CORE_INIT'))
 $summary+=("JAVA_READY="+(Count-Matches $elines 'B4 JAVA_READY'))
 $summary+=("LOAD_GAME="+(Count-Matches $elines 'B4 LOAD_GAME_ENTER'))
 $summary+=("IPC_RUN_SENT="+(Count-Matches $elines 'B4 IPC_RUN_SENT'))
 $summary+=("CORE_DEINIT="+(Count-Matches $elines 'B4 CORE_DEINIT'))
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
Write-Host "COLLECT R1.1 PASS: $out.zip"
