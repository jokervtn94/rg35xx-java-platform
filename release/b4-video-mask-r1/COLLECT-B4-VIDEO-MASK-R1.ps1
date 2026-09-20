param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"'); if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}; if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-VIDEO-MASK-R1-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null
foreach($n in @('RG35XX-B4-VIDEO-MASK-R1-INSTALL-RESULT.txt','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log','freej2me-java-control.log')){
 $p=Join-Path $Sd $n;if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}
}
$hash=@()
foreach($rel in @('CFW\java\bin\jamvm','CFW\java\share\classpath\glibj.zip','CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so','BIOS\freej2me-lr.jar')){
 $p=Join-Path $Sd $rel;if(Test-Path -LiteralPath $p -PathType Leaf){$hash+=("$rel="+(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant())}
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII
Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
