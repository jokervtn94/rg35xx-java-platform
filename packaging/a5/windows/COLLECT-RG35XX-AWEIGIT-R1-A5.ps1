param([Parameter(Mandatory=$false)][string]$SdRoot)
$ErrorActionPreference='Stop'
function Get-Sha256([string]$Path){(Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)'}
if([string]::IsNullOrWhiteSpace($SdRoot)){throw 'SD root is empty.'}
$SdRoot=$SdRoot.Trim(); if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot.ToUpperInvariant()+':\'} elseif($SdRoot -match '^[A-Za-z]:[\\/]?$'){$SdRoot=$SdRoot.Substring(0,1).ToUpperInvariant()+':\'} else{$SdRoot=[System.IO.Path]::GetFullPath($SdRoot)}
if(-not(Test-Path -LiteralPath $SdRoot -PathType Container)){throw "SD root not found: $SdRoot"}
$Stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $Work=Join-Path $PSScriptRoot "RG35XX-AWEIGIT-R1-A5-EVIDENCE-$Stamp"; $Zip="$Work.zip"; New-Item -ItemType Directory -Force -Path $Work|Out-Null
$Payload=Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A5-CORE'
$Files=@((Join-Path $SdRoot 'RG35XX-AWEIGIT-R1-A5-INSTALL-RESULT.txt'),(Join-Path $SdRoot 'RG35XX-AWEIGIT-R1-A5-CORE-RESULT.txt'),(Join-Path $Payload 'BUILD-IDENTITY.txt'),(Join-Path $Payload 'CANONICAL-DIFF-MANIFEST.txt'),(Join-Path $Payload 'JAVA6-COMPAT-AUDIT.tsv'),(Join-Path $Payload 'PAYLOAD-SHA256SUMS.txt'))
foreach($F in $Files){if(Test-Path -LiteralPath $F -PathType Leaf){Copy-Item -LiteralPath $F -Destination (Join-Path $Work ([IO.Path]::GetFileName($F)))}}
$Jamvm=Join-Path $SdRoot 'CFW\java\bin\jamvm'; $Glibj=Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'; $Launcher=Join-Path $SdRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A5-CORE.sh'
$Inv=@('PROJECT=RG35XX-AWEIGIT-R1','STAGE=A5-CORE-INTEGRATION',"COLLECT_TIME=$((Get-Date).ToString('o'))")
foreach($P in @(@('JAMVM',$Jamvm),@('GLIBJ',$Glibj),@('LAUNCHER',$Launcher),@('PLATFORM_JAR',(Join-Path $Payload 'freej2me-rg35xx.jar')),@('INPUT_NATIVE',(Join-Path $Payload 'librg35xx_input.so')),@('VIDEO_NATIVE',(Join-Path $Payload 'librg35xx_video.so')),@('CORE_JAR',(Join-Path $Payload 'rg35xx-a5-core.jar')))){if(Test-Path $P[1] -PathType Leaf){$Inv+="$($P[0])_PATH=$($P[1])";$Inv+="$($P[0])_SHA256=$(Get-Sha256 $P[1])"}else{$Inv+="$($P[0])_MISSING=$($P[1])"}}
$Inv+='DEVICE_PASS_REVIEW=PENDING';$Inv+='STABLE=NO';$Inv|Set-Content -LiteralPath (Join-Path $Work 'A5-EVIDENCE-INVENTORY.txt') -Encoding ASCII
if(Test-Path $Zip){Remove-Item $Zip -Force};Compress-Archive -Path (Join-Path $Work '*') -DestinationPath $Zip -Force;Remove-Item $Work -Recurse -Force;Write-Host "Evidence package: $Zip"