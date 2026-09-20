param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap o dia SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"');if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'};if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("RG35XX-GARLICOS-JAVA-V1.3-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out|Out-Null
foreach($n in @('RG35XX-GARLICOS-JAVA-BASELINE-V1.3-INSTALL-RESULT.txt','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log','freej2me-java-control.log')){
 $p=Join-Path $Sd $n;if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}
}
$hash=@()
foreach($rel in @('CFW\java\bin\jamvm','CFW\java\share\classpath\glibj.zip','CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so','BIOS\freej2me-lr.jar')){
 $p=Join-Path $Sd $rel;if(Test-Path -LiteralPath $p){$hash+=("$rel="+(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant())}
}
$hash|Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII
$java=Join-Path $Sd 'Roms\JAVA';if(Test-Path -LiteralPath $java){Get-ChildItem -LiteralPath $java -Filter '*.jar' -File -Recurse|ForEach-Object{$_.FullName.Substring($java.Length).TrimStart('\')}|Sort-Object|Set-Content -LiteralPath (Join-Path $out 'JAVA-GAMES.txt') -Encoding UTF8}
Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT PASS: $out.zip"
