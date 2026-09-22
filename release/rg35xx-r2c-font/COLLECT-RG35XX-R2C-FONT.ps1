param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot,[switch]$SelfTest)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function Count-Matches([object[]]$a,[string]$s){return @($a|Select-String -SimpleMatch $s).Count}
if($SelfTest){if((Count-Matches @('x') 'z')-ne 0){throw 'zero'};if((Count-Matches @('z') 'z')-ne 1){throw 'one'};Write-Output 'SELFTEST_COUNT=PASS';exit 0}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'}
$SdRoot=$SdRoot.Trim().Trim('"');if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'};if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'}
$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$out=Join-Path $PSScriptRoot ("RG35XX-R2C-FONT-EVIDENCE-"+$stamp);New-Item -ItemType Directory -Force -Path $out|Out-Null
foreach($n in @('RG35XX-R2C-FONT-INSTALL-RESULT.txt','freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log')){$p=Join-Path $Sd $n;if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}}
$sum=@('CHECKPOINT=R2C-FONT','PRIMARY_VARIABLE=FONT_TEXT_RASTER_ONLY','STABLE=NO')
$j=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $j -PathType Leaf){$l=@(Get-Content -LiteralPath $j);$sum+=("JAVA_LINES="+$l.Count);$sum+=("R2D_FONT_READY="+(Count-Matches $l 'RG35XX-R2D-FONT: ready'));$sum+=("ZONE_AIOOBE="+(Count-Matches $l 'Zone.combineWithSubGlyph'));$sum+=("RENDER_SCANLINE_NPE="+(Count-Matches $l 'AbstractGraphics2D.renderScanline'));$sum+=("GETSEQUENCER_ERRORS="+(Count-Matches $l 'NoSuchMethodError: getSequencer'));$sum+=("R2A_IMAGE_NORMALIZE="+(Count-Matches $l 'RG35XX-R2A-IMAGE-NORMALIZE'))}
$sum|Set-Content -LiteralPath (Join-Path $out 'SUMMARY.txt') -Encoding ASCII
Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT R2C FONT PASS: $out.zip"
