param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedRuntime='5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913'
$ExpectedSoundFont='c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854'
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null};(Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"');if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'};if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
if(!(Test-Path -LiteralPath $SdRoot -PathType Container)){throw "SD root not found: $SdRoot"}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$checks=@(
 @('JamVM','CFW\java\bin\jamvm',$ExpectedJamvm),
 @('glibj','CFW\java\share\classpath\glibj.zip',$ExpectedGlibj),
 @('B4 core','CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',$ExpectedCore),
 @('SoundFont','BIOS\freej2me.sf2',$ExpectedSoundFont),
 @('runtime BIOS','BIOS\freej2me-lr.jar',$ExpectedRuntime),
 @('runtime BIOS plus','BIOS\freej2me_plus-lr.jar',$ExpectedRuntime),
 @('runtime Java','CFW\java\share\freej2me\freej2me-lr.jar',$ExpectedRuntime),
 @('runtime RA hidden','CFW\retroarch\.retroarch\system\freej2me-lr.jar',$ExpectedRuntime),
 @('runtime RA system','CFW\retroarch\system\freej2me-lr.jar',$ExpectedRuntime)
)
$ok=$true;$out=@('RG35XX R2B AUDIO PRECHECK',"TIME=$((Get-Date).ToString('s'))")
foreach($c in $checks){$actual=Sha (Join-Path $Sd $c[1]);$pass=($actual -eq $c[2]);if(!$pass){$ok=$false};$out+=("{0}={1} path={2} actual={3} expected={4}" -f $c[0],$(if($pass){'PASS'}else{'FAIL'}),$c[1],$actual,$c[2])}
$out+=('RESULT='+$(if($ok){'PASS'}else{'FAIL'}));$out+=('READY_FOR_R2B='+$(if($ok){'YES'}else{'NO'}))
$out|Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-R2B-AUDIO-PRECHECK.txt') -Encoding ASCII
$out|ForEach-Object{Write-Host $_}
if(!$ok){exit 2}
