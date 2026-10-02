param([Parameter(Mandatory=$false)][string]$SdRoot)
$ErrorActionPreference='Stop'
function H([string]$p){(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX (vi du G)'}
if([string]::IsNullOrWhiteSpace($SdRoot)){throw 'SD root is empty.'}
$SdRoot=$SdRoot.Trim(); if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot.ToUpperInvariant()+':\'} elseif($SdRoot -match '^[A-Za-z]:[\\/]?$'){$SdRoot=$SdRoot.Substring(0,1).ToUpperInvariant()+':\'} else {$SdRoot=[IO.Path]::GetFullPath($SdRoot)}
if(-not(Test-Path -LiteralPath $SdRoot -PathType Container)){throw "SD root not found: $SdRoot"}
$Stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $Work=Join-Path $PSScriptRoot "RG35XX-P1A-GRAPHICS-EVIDENCE-$Stamp"; $Zip="$Work.zip"; New-Item -ItemType Directory -Force -Path $Work|Out-Null
$Evidence=Join-Path $SdRoot 'RG35XX-P1A-GRAPHICS-EVIDENCE'; if(-not(Test-Path -LiteralPath $Evidence -PathType Container)){throw "Device evidence directory missing: $Evidence"}
Copy-Item -Path (Join-Path $Evidence '*') -Destination $Work -Recurse -Force
$Install=Join-Path $SdRoot 'RG35XX-P1A-GRAPHICS-INSTALL-RESULT.txt'; if(Test-Path -LiteralPath $Install -PathType Leaf){Copy-Item -LiteralPath $Install -Destination $Work -Force}
$Payload=Join-Path $SdRoot 'Roms\APPS\RG35XX-P1A-GRAPHICS'; $Launcher=Join-Path $SdRoot 'Roms\APPS\RG35XX-P1A-GRAPHICS.sh'; $Jamvm=Join-Path $SdRoot 'CFW\java\bin\jamvm'; $Glibj=Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'
$Inv=New-Object Collections.Generic.List[string]; $Inv.Add('PROJECT=RG35XX-AWEIGIT-R1'); $Inv.Add('MODULE=P1A_GRAPHICS'); $Inv.Add("COLLECT_TIME=$((Get-Date).ToString('o'))"); $Inv.Add("SD_ROOT=$SdRoot")
foreach($Pair in @(@('JAMVM',$Jamvm),@('GLIBJ',$Glibj),@('LAUNCHER',$Launcher),@('PLATFORM_JAR',(Join-Path $Payload 'freej2me-rg35xx.jar')),@('EXERCISER',(Join-Path $Payload 'RG35XX-Platform-Exerciser-P1A.jar')),@('INPUT_NATIVE',(Join-Path $Payload 'librg35xx_input.so')),@('VIDEO_NATIVE',(Join-Path $Payload 'librg35xx_video.so')))){ $N=$Pair[0]; $P=$Pair[1]; if(Test-Path -LiteralPath $P -PathType Leaf){$Inv.Add("${N}_PATH=$P");$Inv.Add("${N}_SHA256=$(H $P)")}else{$Inv.Add("${N}_MISSING=$P")}}
$Inv.Add('DEVICE_PASS_REVIEW=PENDING');$Inv.Add('STABLE=NO');$Inv|Set-Content -LiteralPath (Join-Path $Work 'P1A-EVIDENCE-INVENTORY.txt') -Encoding ASCII
if(Test-Path -LiteralPath $Zip){Remove-Item -LiteralPath $Zip -Force}; Compress-Archive -Path (Join-Path $Work '*') -DestinationPath $Zip -Force; Remove-Item -LiteralPath $Work -Recurse -Force; Write-Host "Evidence package: $Zip"
