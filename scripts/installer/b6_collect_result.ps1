$ErrorActionPreference='Stop'
$drive=$args[0]
if([string]::IsNullOrWhiteSpace($drive)){ $drive=Read-Host 'Nhap ky tu o the nho RG35XX' }
$drive=$drive.Trim().TrimEnd(':','\')
$root="$drive`:\"
if(!(Test-Path -LiteralPath $root)){ throw "Khong tim thay o dia $root" }
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path (Get-Location) "RESULT-B6-$stamp"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$files=@(
'RG35XX-VERIFIED-CLEAN-B6-INSTALL-RESULT.txt',
'freej2me-vc3-early.log',
'freej2me-core.log',
'freej2me-java-error.log',
'freej2me-java-control.log'
)
foreach($n in $files){
  $p=Join-Path $root $n
  if(Test-Path -LiteralPath $p){ Copy-Item -LiteralPath $p -Destination (Join-Path $out $n) -Force }
}
@(
  "COLLECT_TIME=$(Get-Date -Format o)",
  "SD_ROOT=$root"
) | Out-File -LiteralPath (Join-Path $out 'COLLECT-INFO.txt') -Encoding utf8
Write-Host "COLLECT: PASS -> $out" -ForegroundColor Green
