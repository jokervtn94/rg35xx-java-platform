param(
 [Parameter(Mandatory=$false,Position=0)][string]$SdRoot,
 [switch]$Force
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Fail([string]$m){throw "RG35XX SD PRECLEAN RESTORE FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null};return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"')
if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}
if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
if(!(Test-Path -LiteralPath $SdRoot -PathType Container)){Fail "SD root not found: $SdRoot"}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path.TrimEnd('\')+'\'

$ptr=Join-Path $Sd 'RG35XX-SD-PRECLEAN-R1-CURRENT-QUARANTINE.txt'
if(!(Test-Path -LiteralPath $ptr -PathType Leaf)){Fail 'current quarantine pointer missing'}
$qRoot=(Get-Content -LiteralPath $ptr -Raw).Trim()
$manifest=Join-Path $qRoot 'MANIFEST.csv'
if(!(Test-Path -LiteralPath $manifest -PathType Leaf)){Fail "manifest missing: $manifest"}
$rows=@(Import-Csv -LiteralPath $manifest)

if(!$Force){
 foreach($r in $rows){
  $dst=Join-Path $Sd $r.RelativePath
  if(Test-Path -LiteralPath $dst -PathType Leaf){Fail "restore target already exists: $($r.RelativePath). Use -Force only if intentional."}
 }
}

$restored=0
foreach($r in $rows){
 $src=Join-Path $qRoot $r.RelativePath
 $dst=Join-Path $Sd $r.RelativePath
 if(!(Test-Path -LiteralPath $src -PathType Leaf)){continue}
 if(Test-Path -LiteralPath $dst -PathType Leaf){
  if(!$Force){Fail "target exists: $($r.RelativePath)"}
  Remove-Item -LiteralPath $dst -Force
 }
 New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
 Move-Item -LiteralPath $src -Destination $dst
 if((Sha $dst) -ne $r.SHA256){Fail "restored hash mismatch: $($r.RelativePath)"}
 $restored++
}
Set-Content -LiteralPath (Join-Path $qRoot 'RESTORE-RESULT.txt') -Value @(
 'RESULT=PASS',
 "TIME=$((Get-Date).ToString('s'))",
 "RESTORED_COUNT=$restored"
) -Encoding ASCII
Write-Host "RESTORE PASS - restored $restored files from $qRoot"
