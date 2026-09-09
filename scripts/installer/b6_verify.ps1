$ErrorActionPreference='Stop'
function Get-Sha256Safe([string]$Path){ if(!(Test-Path -LiteralPath $Path)){ return $null }; return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
$drive=$args[0]
if([string]::IsNullOrWhiteSpace($drive)){ $drive=Read-Host 'Nhap ky tu o the nho RG35XX' }
$drive=$drive.Trim().TrimEnd(':','\')
$root="$drive`:\"
if(!(Test-Path -LiteralPath $root)){ throw "Khong tim thay o dia $root" }
$targets=@(
@('CFW\java\bin\jamvm','eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'),
@('CFW\java\share\classpath\glibj.zip','d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'),
@('CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so','56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'),
@('CFW\retroarch\.retroarch\cores\freej2me_libretro.so','56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'),
@('BIOS\freej2me-lr.jar','e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed'),
@('BIOS\freej2me_plus-lr.jar','e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed'),
@('CFW\java\share\freej2me\freej2me-lr.jar','e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed'),
@('CFW\retroarch\.retroarch\system\freej2me-lr.jar','e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed'),
@('CFW\retroarch\system\freej2me-lr.jar','e8706495bfaed6a9020b395cc65347c76ca3a3d1bd5a1880aed593379fa9f4ed')
)
$bad=0
foreach($t in $targets){
  $got=Get-Sha256Safe (Join-Path $root $t[0])
  if($got -eq $t[1]){ Write-Host "PASS $($t[0])" -ForegroundColor Green }
  else { Write-Host "FAIL $($t[0]) expected=$($t[1]) actual=$got" -ForegroundColor Red; $bad++ }
}
if($bad -ne 0){ throw "VERIFY FAIL: $bad target(s)" }
Write-Host 'VERIFY: PASS' -ForegroundColor Green
