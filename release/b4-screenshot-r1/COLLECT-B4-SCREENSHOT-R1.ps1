param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'

if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-SCREENSHOT-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null

foreach($n in @(
 'RG35XX-B4-SCREENSHOT-R1-INSTALL-RESULT.txt',
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
 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so',
 'BIOS\freej2me-lr.jar'
)){
 $p=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $p -PathType Leaf){
   $hash+=("$rel="+(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant())
 }
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

@(
 'CHECKPOINT=B4-SCREENSHOT-R1-AB',
 'PRIMARY_VARIABLE=NATIVE_PRESENTATION_CANVAS_LIFETIME_ONLY',
 'TEST_GAME=Real Football 2015 240x320',
 'EXPECTED_SMARTFIT=360x480 at x=140 y=0',
 'REQUIRED_SCREENSHOTS=at least 3 screenshots at different moments',
 'PASS_SCREENSHOT=complete viewport, not horizontal strips',
 'REQUIRED_PHYSICAL_LCD_CHECK=unchanged complete image and green tint remains fixed',
 'REQUIRED_INPUT_CHECK=usable',
 'REQUIRED_EXIT_CHECK=normal exit; no hard reset',
 'RUNTIME_CHANGE=NONE',
 'AUDIO_CHANGE=NONE',
 'FONT_CHANGE=NONE',
 'FULL_PLATFORM_STABLE=NO'
)|Set-Content -LiteralPath (Join-Path $out 'TEST-EXPECTATIONS.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
