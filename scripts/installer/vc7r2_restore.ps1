param([Parameter(Mandatory=$true)][string]$SdInput,[string]$BackupPath='')
$ErrorActionPreference='Stop'
function Normalize-SdRoot([string]$Raw){$s=$Raw.Trim().Trim('"').Trim("'");if($s-match'^[A-Za-z]$'){$s+=':'};if($s-match'^[A-Za-z]:\\?$'){return($s.Substring(0,2)+'\')};return((Resolve-Path -LiteralPath $s).Path.TrimEnd('\')+'\')}
$sd=Normalize-SdRoot $SdInput
if([string]::IsNullOrWhiteSpace($BackupPath)){$root=Join-Path $sd 'RG35XX_VC7R2_Backup';if(-not(Test-Path -LiteralPath $root)){throw "Backup root missing: $root"};$latest=Get-ChildItem -LiteralPath $root -Directory|Sort-Object Name -Descending|Select-Object -First 1;if($null-eq$latest){throw 'No VC7R2 backup found.'};$BackupPath=$latest.FullName}
$bk=(Resolve-Path -LiteralPath $BackupPath).Path;Write-Host "Restoring from: $bk"
foreach($f in Get-ChildItem -LiteralPath $bk -File -Recurse){$rel=$f.FullName.Substring($bk.Length).TrimStart('\');$dst=Join-Path $sd $rel;New-Item -ItemType Directory -Force -Path(Split-Path -Parent $dst)|Out-Null;Copy-Item -LiteralPath $f.FullName -Destination $dst -Force;Write-Host "RESTORED $rel"}
Write-Host 'RESTORE PASS' -ForegroundColor Green
