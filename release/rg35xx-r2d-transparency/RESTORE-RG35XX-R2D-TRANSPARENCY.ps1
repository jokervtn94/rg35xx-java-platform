param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function Fail([string]$m){throw "R2D TRANSPARENCY RESTORE FAIL: $m"}
function Ensure-Parent([string]$p){$d=Split-Path -Parent $p;if([string]::IsNullOrWhiteSpace($d)){return};if(Test-Path -LiteralPath $d -PathType Container){return};New-Item -ItemType Directory -Force -Path $d|Out-Null}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'};$SdRoot=$SdRoot.Trim().Trim('"');if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'};if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'};if(!(Test-Path -LiteralPath $SdRoot -PathType Container)){Fail 'SD root not found'};$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$ptr=Join-Path $Sd 'RG35XX-R2D-TRANSPARENCY-CURRENT-BACKUP.txt';if(!(Test-Path -LiteralPath $ptr -PathType Leaf)){Fail 'backup pointer missing'};$backup=(Get-Content -LiteralPath $ptr -Raw).Trim()
$targets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
foreach($rel in $targets){$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel;if(!(Test-Path -LiteralPath $bak -PathType Leaf)){Fail "missing backup $rel"};Ensure-Parent $dst;Copy-Item -LiteralPath $bak -Destination $dst -Force}
Write-Host "RESTORE R2D TRANSPARENCY PASS from $backup"
