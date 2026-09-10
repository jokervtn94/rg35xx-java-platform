param([Parameter(Mandatory=$true)][string]$SdInput)
$ErrorActionPreference='Stop'
$s=$SdInput.Trim().Trim('"').Trim("'");if($s-match'^[A-Za-z]$'){$s+=':'};if($s-match'^[A-Za-z]:\\?$'){$sd=$s.Substring(0,2)+'\'}else{$sd=((Resolve-Path -LiteralPath $s).Path.TrimEnd('\')+'\')}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$out=Join-Path $PSScriptRoot ('VC7R2-RESULT-'+$stamp);New-Item -ItemType Directory -Force -Path $out|Out-Null
foreach($n in @('RG35XX-VC7R2-INSTALL-RESULT.txt','freej2me-java-error.log','freej2me-core.log','freej2me-vc3-early.log')){$p=Join-Path $sd $n;if(Test-Path -LiteralPath $p){Copy-Item -LiteralPath $p -Destination $out -Force;Write-Host "COPIED $n"}}
Write-Host "RESULT FOLDER: $out"
