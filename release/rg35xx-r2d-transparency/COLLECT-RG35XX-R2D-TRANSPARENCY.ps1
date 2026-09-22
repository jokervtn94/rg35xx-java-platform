param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot,[switch]$SelfTest)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function Count-Matches([object[]]$a,[string]$s){return @($a|Select-String -SimpleMatch $s).Count}
if($SelfTest){if((Count-Matches @('x') 'z')-ne 0){throw 'zero'};if((Count-Matches @('z') 'z')-ne 1){throw 'one'};Write-Output 'SELFTEST_COUNT=PASS';exit 0}
if([string]::IsNullOrWhiteSpace($SdRoot)){$SdRoot=Read-Host 'Nhap ky tu o SD RG35XX'};$SdRoot=$SdRoot.Trim().Trim('"');if($SdRoot -match '^[A-Za-z]$'){$SdRoot=$SdRoot+':'};if($SdRoot -match '^[A-Za-z]:$'){$SdRoot=$SdRoot+'\'};$Sd=(Resolve-Path -LiteralPath $SdRoot).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$out=Join-Path $PSScriptRoot ("RG35XX-R2D-TRANSPARENCY-EVIDENCE-"+$stamp);New-Item -ItemType Directory -Force -Path $out|Out-Null
foreach($n in @('RG35XX-R2D-TRANSPARENCY-INSTALL-RESULT.txt','freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log')){$p=Join-Path $Sd $n;if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $out -Force}}
$sum=@('CHECKPOINT=R2D-TRANSPARENCY','PRIMARY_VARIABLE=IMAGE_TRANSPARENCY_ONLY','STABLE=NO')
$j=Join-Path $Sd 'freej2me-java-error.log'
if(Test-Path -LiteralPath $j -PathType Leaf){$l=@(Get-Content -LiteralPath $j);$sum+=("JAVA_LINES="+$l.Count);$sum+=("R2C_TRANSPARENCY_LINES="+(Count-Matches $l 'RG35XX-R2C-TRANSPARENCY'));$sum+=("PNG_ICCP_STRIP="+(Count-Matches $l 'RG35XX-PNG-ICCP'));$sum+=("IMAGE_READ_FAILURES="+(Count-Matches $l 'Failed to read image'));$sum+=("ZONE_AIOOBE="+(Count-Matches $l 'Zone.combineWithSubGlyph'));$sum+=("GETSEQUENCER_ERRORS="+(Count-Matches $l 'NoSuchMethodError: getSequencer'))}
$shotOut=Join-Path $out 'screenshots';$sc=0
foreach($relDir in @('CFW\retroarch\.retroarch\screenshots','CFW\retroarch\screenshots','Screenshots','screenshots')){$d=Join-Path $Sd $relDir;if(Test-Path -LiteralPath $d -PathType Container){$shots=@(Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue|Where-Object {$_.Extension -match '^\.(png|bmp|jpg|jpeg)$'}|Sort-Object LastWriteTime -Descending|Select-Object -First 10);if($shots.Count -gt 0){New-Item -ItemType Directory -Force -Path $shotOut|Out-Null;foreach($sh in $shots){$name=($relDir -replace '[\\/:*?"<>|]','_')+'__'+$sh.Name;Copy-Item -LiteralPath $sh.FullName -Destination (Join-Path $shotOut $name) -Force;$sc++}}}}
$sum+=("SCREENSHOTS_COPIED="+$sc);$sum|Set-Content -LiteralPath (Join-Path $out 'SUMMARY.txt') -Encoding ASCII
Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "COLLECT R2D TRANSPARENCY PASS: $out.zip"
