param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
# v3: force all Get-Content/Select-String results to arrays before reading .Count.

if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-SCREENSHOT-R1-ROLLBACK-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null

foreach($n in @(
 'RG35XX-B4-SCREENSHOT-R1-ROLLBACK-VERIFY.txt',
 'RG35XX-B4-SCREENSHOT-R1-INSTALL-RESULT.txt',
 'freej2me-vc3-early.log',
 'freej2me-core.log',
 'freej2me-java-error.log',
 'freej2me-java-control.log'
)){
 $p=Join-Path $Sd $n
 if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}
}

function Sha([string]$p){
 if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}
 return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}

$hash=@()
foreach($rel in @(
 'CFW\java\bin\jamvm',
 'CFW\java\share\classpath\glibj.zip',
 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',
 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so',
 'BIOS\freej2me-lr.jar'
)){
 $p=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $p -PathType Leaf){$hash+=("$rel="+(Sha $p))}
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

$java=Join-Path $Sd 'freej2me-java-error.log'
$summary=@(
 'CHECKPOINT=B4-SCREENSHOT-R1-ROLLBACK-AB',
 'NO_CODE_CHANGE=YES',
 'COMPARE_AGAINST_SCREENSHOT_R1=YES'
)
if(Test-Path -LiteralPath $java -PathType Leaf){
 $lines=@(Get-Content -LiteralPath $java)
 $summary+=("JAVA_LOG_LINES="+@($lines).Count)
 $summary+=("STRING_INDEX_OOB="+@($lines|Select-String -SimpleMatch 'StringIndexOutOfBoundsException').Count)
 $summary+=("RMS_LOAD_RECORD_STORE="+@($lines|Select-String -SimpleMatch 'RecordStore.loadRecordStore').Count)
 $summary+=("RMS_OPEN_RECORD_STORE="+@($lines|Select-String -SimpleMatch 'RecordStore.openRecordStore').Count)
 $summary+=("RG35XX_VIDEO_JAVA_ERROR="+@($lines|Select-String -SimpleMatch 'RG35XX-VIDEO JAVA').Count)
 $summary+=("GETSEQUENCER_ERRORS="+@($lines|Select-String -SimpleMatch 'NoSuchMethodError: getSequencer').Count)
 $summary+=("CLIP_ERRORS="+@($lines|Select-String -SimpleMatch 'LineUnavailableException: no Clip available').Count)
}
$summary+=@(
 'TEST_GAME_1=dragon-mania-s40v6',
 'TEST_GAME_2=NinjaSchool1',
 'QUESTION_1=Does dragon-mania animate after Run?',
 'QUESTION_2=Does NinjaSchool1 animate after Run?',
 'QUESTION_3=Does either game require hard reset?',
 'STABLE=NO'
)
$summary|Set-Content -LiteralPath (Join-Path $out 'ROLLBACK-SUMMARY.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
