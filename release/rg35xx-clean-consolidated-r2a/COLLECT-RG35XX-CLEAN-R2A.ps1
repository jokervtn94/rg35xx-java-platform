param(
 [Parameter(Mandatory=$false, Position=0)][string]$SdRoot,
 [switch]$SelfTest
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function Count-Matches([object[]]$InputLines,[string]$Needle){
 return @($InputLines | Select-String -SimpleMatch $Needle).Count
}
function Sha([string]$p){
 if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}
 return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
if($SelfTest){
 $zero=@('a','b');$one=@('x marker','b');$many=@('marker','marker x','z marker')
 if((Count-Matches $zero 'marker') -ne 0){throw 'zero failed'}
 if((Count-Matches $one 'marker') -ne 1){throw 'one failed'}
 if((Count-Matches $many 'marker') -ne 3){throw 'many failed'}
 Write-Output 'SELFTEST_ZERO_MATCH=PASS'
 Write-Output 'SELFTEST_SINGLE_MATCH=PASS'
 Write-Output 'SELFTEST_MULTI_MATCH=PASS'
 exit 0
}

if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
if(!(Test-Path -LiteralPath $SdRoot -PathType Container)){throw "SD root not found: $SdRoot"}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("RG35XX-CLEAN-R2A-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null

foreach($n in @(
 'RG35XX-CLEAN-CONSOLIDATED-R2A-INSTALL-RESULT.txt',
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
 'BIOS\freej2me-lr.jar',
 'BIOS\freej2me_plus-lr.jar',
 'CFW\java\share\freej2me\freej2me-lr.jar',
 'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
 'CFW\retroarch\system\freej2me-lr.jar'
)){
 $p=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $p -PathType Leaf){$hash+=("$rel="+(Sha $p))}
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

$summary=@(
 'CHECKPOINT=RG35XX-CLEAN-CONSOLIDATED-R2A',
 'R2A_SCOPE=DECODED_IMAGE_NORMALIZATION_ONLY',
 'FULL_PLATFORM_STABLE=NO'
)

$java=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $java -PathType Leaf){
 $lines=@(Get-Content -LiteralPath $java)
 $summary+=("JAVA_LOG_LINES="+$lines.Count)
 $summary+=("R2A_IMAGE_NORMALIZE_COUNT="+(Count-Matches $lines 'RG35XX-R2A-IMAGE-NORMALIZE'))
 $summary+=("PNG_ICCP_STRIP="+(Count-Matches $lines 'RG35XX-PNG-ICCP: stripped ancillary iCCP chunk'))
 $summary+=("PNG_ICC_V4_ERRORS="+(Count-Matches $lines 'Wrong major version number:4'))
 $summary+=("IMAGE_READ_FAILURES="+(Count-Matches $lines 'Failed to read image'))
 $summary+=("IMAGE_NULL_FAILURES="+(Count-Matches $lines "returned image is null"))
 $summary+=("DYNAMIC_VIEW_LINES="+(Count-Matches $lines 'RG35XX-VC7R2-VIEW:'))
 $summary+=("FRAME_BIND_LINES="+(Count-Matches $lines 'RG35XX-B4-FRAME-BIND'))
 $summary+=("FRAME_BIND_MISMATCH_TRUE="+(Count-Matches $lines 'mismatch=true'))
 $summary+=("GETSEQUENCER_ERRORS="+(Count-Matches $lines 'NoSuchMethodError: getSequencer'))
 $summary+=("CLIP_ERRORS="+(Count-Matches $lines 'LineUnavailableException'))
 $summary+=("RENDER_SCANLINE_NPE="+(Count-Matches $lines 'AbstractGraphics2D.renderScanline'))
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

$screenshotCount=0
$shotOut=Join-Path $out 'screenshots'
foreach($relDir in @(
 'CFW\retroarch\.retroarch\screenshots',
 'CFW\retroarch\screenshots',
 'Screenshots',
 'screenshots'
)){
 $d=Join-Path $Sd $relDir
 if(Test-Path -LiteralPath $d -PathType Container){
   $shots=@(Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue |
     Where-Object {$_.Extension -match '^\.(png|bmp|jpg|jpeg)$'} |
     Sort-Object LastWriteTime -Descending |
     Select-Object -First 10)
   if($shots.Count -gt 0){
     New-Item -ItemType Directory -Force -Path $shotOut|Out-Null
     foreach($shot in $shots){
       $name=($relDir -replace '[\\/:*?"<>|]','_')+'__'+$shot.Name
       Copy-Item -LiteralPath $shot.FullName -Destination (Join-Path $shotOut $name) -Force
       $screenshotCount++
     }
   }
 }
}
$summary+=("SCREENSHOTS_COPIED="+$screenshotCount)

$summary+=@(
 'PHYSICAL_LCD_CHECK=report visible/black/corrupt directly on device',
 'GAME_IMAGE_CHECK=report restored/still black/still missing',
 'SCREENSHOT_CHECK=report physical LCD vs captured screenshot difference',
 'AUDIO_CHECK=report audible/silent; R2A does not change audio',
 'FREEZE_CHECK=report exact screen/state and whether normal exit works',
 'EXIT_CHECK=report normal exit/hard reset'
)
$summary|Set-Content -LiteralPath (Join-Path $out 'R2A-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT R2A PASS: $out.zip"
