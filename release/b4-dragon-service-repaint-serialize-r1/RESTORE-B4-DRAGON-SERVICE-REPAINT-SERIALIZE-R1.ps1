param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"'); if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'}; if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$ptr=Join-Path $Sd 'RG35XX-B4-DRAGON-SERVICE-REPAINT-SERIALIZE-R1-CURRENT-BACKUP.txt'
if(!(Test-Path -LiteralPath $ptr -PathType Leaf)){throw 'RESTORE FAIL: backup pointer missing'}
$backup=(Get-Content -LiteralPath $ptr -Raw).Trim()
if(!(Test-Path -LiteralPath $backup -PathType Container)){
 if($backup -match '^[A-Za-z]:\\(.+)$'){
  $rebased=Join-Path $Sd $Matches[1]
  if(Test-Path -LiteralPath $rebased -PathType Container){$backup=$rebased}
 }
}
$state=Join-Path $backup 'STATE.txt'
if(!(Test-Path -LiteralPath $state -PathType Leaf)){throw "RESTORE FAIL: STATE missing: $state"}
foreach($line in Get-Content -LiteralPath $state){
 $p=$line.Split('|',2); if($p.Count -ne 2){continue}
 $kind=$p[0];$rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel
 if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}
 if($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)){
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
   Copy-Item -LiteralPath $bak -Destination $dst -Force
 }
}
Write-Host "RESTORE PASS from $backup"
