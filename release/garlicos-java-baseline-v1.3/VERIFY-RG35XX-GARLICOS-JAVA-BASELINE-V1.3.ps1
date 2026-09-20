param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
function Fail([string]$m){throw "VERIFY FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null};return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap o dia SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$J='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$G='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$C='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$R='cb8926539749535a53cb4a627e814e198aaa0eba3cce8cac1bb213957e37189b'
$checks=@(
@('CFW\java\bin\jamvm',$J),@('CFW\java\share\classpath\glibj.zip',$G),
@('CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',$C),
@('BIOS\freej2me-lr.jar',$R),@('BIOS\freej2me_plus-lr.jar',$R),
@('CFW\java\share\freej2me\freej2me-lr.jar',$R),
@('CFW\retroarch\.retroarch\system\freej2me-lr.jar',$R),
@('CFW\retroarch\system\freej2me-lr.jar',$R)
)
foreach($x in $checks){$p=Join-Path $Sd $x[0];$got=Sha $p;if($got -ne $x[1]){Fail "$($x[0]) expected=$($x[1]) actual=$got"}}
$java=Join-Path $Sd 'Roms\JAVA';if(!(Test-Path -LiteralPath $java -PathType Container)){Fail 'Roms\JAVA missing'}
$count=@(Get-ChildItem -LiteralPath $java -Filter '*.jar' -File -Recurse).Count
Write-Host "VERIFY PASS - VC7R22 runtime active; B4 core unchanged; Roms\JAVA JAR count=$count"
