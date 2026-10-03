param([Parameter(Mandatory=$false)][string]$SdRoot)
$ErrorActionPreference = 'Stop'
$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
function Get-Sha256([string]$Path){(Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)'}
if([string]::IsNullOrWhiteSpace($SdRoot)){throw 'SD root is empty.'}
$SdRoot=$SdRoot.Trim()
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot.ToUpperInvariant()+':\'}
elseif($SdRoot -match '^[A-Za-z]:[\\/]?$'){$SdRoot=$SdRoot.Substring(0,1).ToUpperInvariant()+':\'}
else{$SdRoot=[System.IO.Path]::GetFullPath($SdRoot)}
if(-not(Test-Path -LiteralPath $SdRoot -PathType Container)){throw "SD root not found: $SdRoot"}
$Jamvm=Join-Path $SdRoot 'CFW\java\bin\jamvm'; $Glibj=Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'
if(-not(Test-Path -LiteralPath $Jamvm -PathType Leaf)){throw "Protected JamVM missing: $Jamvm"}
if(-not(Test-Path -LiteralPath $Glibj -PathType Leaf)){throw "Protected glibj missing: $Glibj"}
$JH=Get-Sha256 $Jamvm; $GH=Get-Sha256 $Glibj
if($JH -ne $ExpectedJamvm){throw "JamVM hash mismatch. Nothing installed."}
if($GH -ne $ExpectedGlibj){throw "glibj hash mismatch. Nothing installed."}
$SourceRoot=Join-Path $PSScriptRoot 'SD'
$SourceLauncher=Join-Path $SourceRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A5-CORE.sh'
$SourcePayload=Join-Path $SourceRoot 'Roms\APPS\RG35XX-AWEIGIT-R1-A5-CORE'
if(-not(Test-Path -LiteralPath $SourceLauncher -PathType Leaf)){throw "Package launcher missing: $SourceLauncher"}
if(-not(Test-Path -LiteralPath $SourcePayload -PathType Container)){throw "Package payload missing: $SourcePayload"}
$DestApps=Join-Path $SdRoot 'Roms\APPS'; New-Item -ItemType Directory -Force -Path $DestApps|Out-Null
$DestLauncher=Join-Path $DestApps 'RG35XX-AWEIGIT-R1-A5-CORE.sh'; $DestPayload=Join-Path $DestApps 'RG35XX-AWEIGIT-R1-A5-CORE'
$Stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $Backup=Join-Path $SdRoot "RG35XX-AWEIGIT-R1-A5-BACKUP-$Stamp"
$NeedBackup=(Test-Path -LiteralPath $DestLauncher)-or(Test-Path -LiteralPath $DestPayload)
if($NeedBackup){New-Item -ItemType Directory -Force -Path $Backup|Out-Null;if(Test-Path $DestLauncher){Copy-Item -LiteralPath $DestLauncher -Destination $Backup};if(Test-Path $DestPayload){Copy-Item -LiteralPath $DestPayload -Destination $Backup -Recurse}}
if(Test-Path $DestPayload){Remove-Item -LiteralPath $DestPayload -Recurse -Force}
New-Item -ItemType Directory -Force -Path $DestPayload|Out-Null
Copy-Item -LiteralPath $SourceLauncher -Destination $DestLauncher -Force
Get-ChildItem -LiteralPath $SourcePayload -File|ForEach-Object{Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $DestPayload $_.Name) -Force}
$Names=@('freej2me-rg35xx.jar','librg35xx_input.so','librg35xx_video.so','rg35xx-a5-core.jar','BUILD-IDENTITY.txt','CANONICAL-DIFF-MANIFEST.txt','JAVA6-COMPAT-AUDIT.tsv','PAYLOAD-SHA256SUMS.txt')
foreach($Name in $Names){$S=Join-Path $SourcePayload $Name;$D=Join-Path $DestPayload $Name;if(-not(Test-Path $D -PathType Leaf)){throw "Installed file missing: $Name"};if((Get-Sha256 $S) -ne (Get-Sha256 $D)){throw "Install hash mismatch: $Name"}}
if((Get-Sha256 $SourceLauncher) -ne (Get-Sha256 $DestLauncher)){throw 'Launcher hash mismatch.'}
$Result=Join-Path $SdRoot 'RG35XX-AWEIGIT-R1-A5-INSTALL-RESULT.txt'
@('PROJECT=RG35XX-AWEIGIT-R1','STAGE=A5-CORE-INTEGRATION',"INSTALL_TIME=$((Get-Date).ToString('o'))","JAMVM_SHA256=$JH","GLIBJ_SHA256=$GH","LAUNCHER=$DestLauncher","PAYLOAD=$DestPayload","BACKUP_CREATED=$NeedBackup","BACKUP_PATH=$Backup",'INSTALL_RESULT=PASS','DEVICE_PASS=NO','STABLE=NO')|Set-Content -LiteralPath $Result -Encoding ASCII
Write-Host 'A5 install PASS.'; Write-Host "Launcher: $DestLauncher"; Write-Host "Result: $Result"