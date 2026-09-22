param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Fail([string]$m){throw "RG35XX CLEAN R2A RESTORE FAIL: $m"}
function Ensure-Parent([string]$p){
 $parent=Split-Path -Parent $p
 if([string]::IsNullOrWhiteSpace($parent)){return}
 if(Test-Path -LiteralPath $parent -PathType Container){return}
 New-Item -ItemType Directory -Force -Path $parent|Out-Null
}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
if(!(Test-Path -LiteralPath $SdRoot -PathType Container)){Fail "SD root not found: $SdRoot"}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$ptr=Join-Path $Sd 'RG35XX-CLEAN-CONSOLIDATED-R2A-CURRENT-BACKUP.txt'
if(!(Test-Path -LiteralPath $ptr -PathType Leaf)){Fail 'backup pointer missing'}
$backup=(Get-Content -LiteralPath $ptr -Raw).Trim()
$state=Join-Path $backup 'STATE.txt'
if(!(Test-Path -LiteralPath $state -PathType Leaf)){Fail "STATE missing: $state"}

foreach($line in @(Get-Content -LiteralPath $state)){
 $p=$line.Split('|'); if($p.Count -lt 2){continue}
 $kind=$p[0];$rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel
 if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}
 if($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)){
  Ensure-Parent $dst
  Copy-Item -LiteralPath $bak -Destination $dst -Force
 }
}
Write-Host "RESTORE R2A PASS from $backup"
