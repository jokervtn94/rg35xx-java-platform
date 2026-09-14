param([Parameter(Mandatory=$false,Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$Jam='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$Glib='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$Core='fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062'
$FontSha='7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c'
$FontEntry='org/recompile/mobile/rg35xx-font.bin'; $FontSize=727008
$Pkg=Split-Path -Parent $PSScriptRoot; $Pay=Join-Path $Pkg 'payload'
$BaseJar=Join-Path $Pay 'freej2me-lr-code-only.jar'; $BaseShaFile=Join-Path $Pay 'RUNTIME-CODE-SHA256.txt'
function Fail([string]$m){throw "NOMASK-GOLDENFONT-AB FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){Fail "missing $p"};(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Sd([string]$p){if([string]::IsNullOrWhiteSpace($p)){$p=Read-Host 'Nhap o SD, vi du H'};$p=$p.Trim().Trim('"');if($p-match'^[A-Za-z]$'){$p="$p`:"};if($p-match'^[A-Za-z]:$'){$p="$p\"};if(!(Test-Path -LiteralPath $p -PathType Container)){Fail "SD root not found: $p"};$r=(Resolve-Path -LiteralPath $p).Path;if($r-notmatch'^[A-Za-z]:\\?$'){Fail "not drive root: $r"};$r.TrimEnd('\')+'\'}
Add-Type -AssemblyName System.IO.Compression; Add-Type -AssemblyName System.IO.Compression.FileSystem
function EntryBytes([string]$jar){
  $z=$null;try{$z=[IO.Compression.ZipFile]::OpenRead($jar);$e=$z.GetEntry($FontEntry);if($null-eq$e-or$e.Length-ne$FontSize){return $null};$ms=New-Object IO.MemoryStream;$s=$e.Open();try{$s.CopyTo($ms)}finally{$s.Dispose()};$b=$ms.ToArray();$ms.Dispose();$h=[Security.Cryptography.SHA256]::Create();try{$d=([BitConverter]::ToString($h.ComputeHash($b))).Replace('-','').ToLowerInvariant()}finally{$h.Dispose()};if($d-ne$FontSha){return $null};return $b}catch{return $null}finally{if($null-ne$z){$z.Dispose()}}}
function Merge([string]$base,[byte[]]$font,[string]$out){Copy-Item -LiteralPath $base -Destination $out -Force;$z=[IO.Compression.ZipFile]::Open($out,[IO.Compression.ZipArchiveMode]::Update);try{$old=$z.GetEntry($FontEntry);if($null-ne$old){$old.Delete()};$e=$z.CreateEntry($FontEntry,[IO.Compression.CompressionLevel]::Optimal);$s=$e.Open();try{$s.Write($font,0,$font.Length)}finally{$s.Dispose()}}finally{$z.Dispose()}}
$S=Sd $SdRoot; Write-Host "[1/7] SD=$S"
if((Sha (Join-Path $S 'CFW\java\bin\jamvm'))-ne$Jam){Fail 'JamVM mismatch'}
if((Sha (Join-Path $S 'CFW\java\share\classpath\glibj.zip'))-ne$Glib){Fail 'glibj mismatch'}
if((Sha (Join-Path $S 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'))-ne$Core){Fail 'Foundation core mismatch'}
Write-Host '[2/7] JamVM/glibj/core VERIFIED'
$baseExpected=(Get-Content -LiteralPath $BaseShaFile -Raw).Trim().ToLowerInvariant();if((Sha $BaseJar)-ne$baseExpected){Fail 'code-only runtime payload mismatch'}
Write-Host '[3/7] NoMask + Golden renderer code VERIFIED'
$roots=@('RG35XX-JAVA-BACKUP','Java','RG35XX_N1_Backup','RG35XX_N1_V2_Backup','BIOS','CFW\java','CFW\retroarch')
$font=$null;$source=$null
Write-Host '[4/7] Searching SD JAR backups for exact Golden font...'
foreach($rel in $roots){$r=Join-Path $S $rel;if(!(Test-Path -LiteralPath $r -PathType Container)){continue};foreach($f in Get-ChildItem -LiteralPath $r -Recurse -File -Filter '*.jar' -ErrorAction SilentlyContinue){$b=EntryBytes $f.FullName;if($null-ne$b){$font=$b;$source=$f.FullName;break}};if($null-ne$font){break}}
if($null-eq$font){Fail "exact Golden font not found on SD; required entry SHA256=$FontSha. No reconstructed font used."}
Write-Host "[5/7] Golden font VERIFIED from $source"
$tmp=Join-Path $env:TEMP ('rg35xx-nomask-goldenfont-'+[guid]::NewGuid().ToString('N')+'.jar');Merge $BaseJar $font $tmp;$finalSha=Sha $tmp
$targets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$bakRoot=Join-Path $S "RG35XX-JAVA-BACKUP\from-zero-nomask-goldenfont-ab-$stamp";$back=@();$created=@()
try{Write-Host "[6/7] Atomic install; backup=$bakRoot";foreach($rel in $targets){$dst=Join-Path $S $rel;New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null;if(Test-Path -LiteralPath $dst -PathType Leaf){$bak=Join-Path $bakRoot $rel;New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak)|Out-Null;Copy-Item -LiteralPath $dst -Destination $bak -Force;$back+=,@($dst,$bak)}else{$created+=$dst}};foreach($rel in $targets){$dst=Join-Path $S $rel;$stage="$dst.nomask-goldenfont-new";Copy-Item -LiteralPath $tmp -Destination $stage -Force;if((Sha $stage)-ne$finalSha){Fail "stage SHA mismatch $rel"};Move-Item -LiteralPath $stage -Destination $dst -Force;if((Sha $dst)-ne$finalSha){Fail "commit SHA mismatch $rel"}};$result=Join-Path $S 'RG35XX-FROM-ZERO-NOMASK-GOLDENFONT-AB-INSTALL-RESULT.txt';@('RG35XX FROM-ZERO NOMASK + GOLDENFONT A/B','STATUS=INSTALL-PASS_DEVICE-AB-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","FINAL_RUNTIME_SHA256=$finalSha","PRESERVED_CORE_SHA256=$Core","JAMVM_L_SHA256=$Jam","GLIBJ_SHA256=$Glib","GOLDEN_FONT_SHA256=$FontSha","GOLDEN_FONT_SOURCE_JAR=$source","BACKUP=$bakRoot",'GREEN_TINT_FIX=NOMASK_RETAINED','FONT=EXACT_GOLDEN_RESOURCE_PLUS_GOLDEN_RENDERER','DRAWRGB_AB=NOT_INCLUDED','AUDIO=UNCHANGED','TRANSPARENCY=UNCHANGED')|Set-Content -LiteralPath $result -Encoding ASCII;Write-Host '[7/7] INSTALL PASS. Test KDTT, Tan Tay Du Ky 3, then Real Football green tint.';Write-Host "Result=$result"}
catch{Write-Warning "rollback: $($_.Exception.Message)";foreach($rel in $targets){$stage=(Join-Path $S $rel)+'.nomask-goldenfont-new';Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue};foreach($p in $created){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue};foreach($x in $back){if(Test-Path -LiteralPath $x[1]){Copy-Item -LiteralPath $x[1] -Destination $x[0] -Force}};throw}
finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
