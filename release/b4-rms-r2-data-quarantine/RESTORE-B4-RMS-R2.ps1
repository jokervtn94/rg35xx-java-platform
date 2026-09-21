param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function Fail([string]$m){ throw "B4-RMS-R2 RESTORE FAIL: $m" }
function Sha([string]$p){ return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }

function Resolve-Sd([string]$raw){
  if([string]::IsNullOrWhiteSpace($raw)){ $raw=Read-Host 'Nhap ky tu o SD RG35XX' }
  $raw=$raw.Trim().Trim('"')
  if($raw -match '^[A-Za-z]$'){ $raw=$raw+':' }
  if($raw -match '^[A-Za-z]:$'){ $raw=$raw+'\' }
  if(!(Test-Path -LiteralPath $raw -PathType Container)){ Fail "SD root not found: $raw" }
  return ((Resolve-Path -LiteralPath $raw).Path.TrimEnd('\')+'\')
}

$Sd=Resolve-Sd $SdRoot
$ptr=Join-Path $Sd 'RG35XX-B4-RMS-R2-CURRENT-QUARANTINE.txt'
if(!(Test-Path -LiteralPath $ptr -PathType Leaf)){ Fail 'quarantine pointer missing' }
$qRoot=(Get-Content -LiteralPath $ptr -Raw).Trim()
if(!(Test-Path -LiteralPath $qRoot -PathType Container)){
  if($qRoot -match '^[A-Za-z]:\\(.+)$'){
    $rebased=Join-Path $Sd $Matches[1]
    if(Test-Path -LiteralPath $rebased -PathType Container){ $qRoot=$rebased }
  }
}
if(!(Test-Path -LiteralPath $qRoot -PathType Container)){ Fail "quarantine folder missing: $qRoot" }

$manifestPath=Join-Path $qRoot 'MANIFEST.csv'
if(!(Test-Path -LiteralPath $manifestPath -PathType Leaf)){ Fail 'MANIFEST.csv missing' }
$rows=@(Import-Csv -LiteralPath $manifestPath)
if(@($rows).Count -ne 4){ Fail "Expected 4 manifest rows, found $(@($rows).Count)" }

foreach($r in $rows){
  $src=Join-Path $qRoot $r.BackupRelativePath
  $dst=Join-Path $Sd $r.OriginalPath
  if(!(Test-Path -LiteralPath $src -PathType Leaf)){ Fail "Backup file missing: $src" }
  if((Sha $src) -ne $r.SHA256){ Fail "Backup hash mismatch: $src" }
  if(Test-Path -LiteralPath $dst){ Fail "Refusing overwrite during restore: $dst" }
}

foreach($r in $rows){
  $src=Join-Path $qRoot $r.BackupRelativePath
  $dst=Join-Path $Sd $r.OriginalPath
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
  if((Sha $dst) -ne $r.SHA256){ Fail "Restored hash mismatch: $dst" }
}

@(
 'CHECKPOINT=B4-RMS-R2-DATA-QUARANTINE-AB',
 'RESTORE_RESULT=PASS',
 "TIME=$((Get-Date).ToString('s'))",
 "QUARANTINE=$qRoot",
 'RESTORED_FILES=4',
 'STABLE=NO'
) | Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-RMS-R2-RESTORE-RESULT.txt') -Encoding ASCII

Write-Host 'RMS RESTORE PASS'
