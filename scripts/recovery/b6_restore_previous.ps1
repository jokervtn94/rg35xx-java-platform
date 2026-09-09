$ErrorActionPreference='Stop'
$drive=$args[0]
if([string]::IsNullOrWhiteSpace($drive)){ $drive=Read-Host 'Nhap ky tu o the nho RG35XX' }
$drive=$drive.Trim().TrimEnd(':','\')
$root="$drive`:\"
if(!(Test-Path -LiteralPath $root)){ throw "Khong tim thay o dia $root" }
$base=Join-Path $root 'RG35XX_VERIFIED_CLEAN_B6_Backup'
if(!(Test-Path -LiteralPath $base)){ throw 'Khong co backup B6' }
$latest=Get-ChildItem -LiteralPath $base -Directory | Sort-Object Name -Descending | Select-Object -First 1
if($null -eq $latest){ throw 'Khong tim thay snapshot backup' }
$files=Get-ChildItem -LiteralPath $latest.FullName -File -Recurse
foreach($f in $files){
  $rel=$f.FullName.Substring($latest.FullName.Length).TrimStart('\')
  if($rel -match '^freej2me-.*\.log$'){ continue }
  $dst=Join-Path $root $rel
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
  Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
  Write-Host "RESTORED $rel"
}
Write-Host "RESTORE: PASS from $($latest.FullName)" -ForegroundColor Green
