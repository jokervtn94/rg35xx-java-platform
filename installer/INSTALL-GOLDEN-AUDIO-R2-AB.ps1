param([Parameter(Mandatory=$false,Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$Jam='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$Glib='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$FoundationCore='fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062'
$ReconFont='20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9'
$Pkg=Split-Path -Parent $PSScriptRoot; $Pay=Join-Path $Pkg 'payload'
$Jar=Join-Path $Pay 'freej2me-lr.jar'; $Core=Join-Path $Pay 'freej2me_plus_libretro.so'; $HashFile=Join-Path $Pay 'PAYLOAD-SHA256.txt'
function Fail([string]$m){throw "GOLDEN-AUDIO-R2-AB FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){Fail "missing $p"};(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Sd([string]$p){if([string]::IsNullOrWhiteSpace($p)){$p=Read-Host 'Nhap o SD, vi du H'};$p=$p.Trim().Trim('"');if($p-match'^[A-Za-z]$'){$p="$p`:"};if($p-match'^[A-Za-z]:$'){$p="$p\"};if(!(Test-Path -LiteralPath $p -PathType Container)){Fail "SD root not found: $p"};$r=(Resolve-Path -LiteralPath $p).Path;if($r-notmatch'^[A-Za-z]:\\?$'){Fail "not drive root: $r"};$r.TrimEnd('\')+'\'}
function ReadPayloadHash([string]$name){$line=Get-Content -LiteralPath $HashFile | Where-Object {$_ -match "\s+$([regex]::Escape($name))$"} | Select-Object -First 1;if($null-eq$line){Fail "missing payload hash for $name"};($line -split '\s+')[0].ToLowerInvariant()}
$S=Sd $SdRoot; Write-Host "[1/8] SD=$S"
if((Sha (Join-Path $S 'CFW\java\bin\jamvm'))-ne$Jam){Fail 'JamVM mismatch'}
if((Sha (Join-Path $S 'CFW\java\share\classpath\glibj.zip'))-ne$Glib){Fail 'glibj mismatch'}
$oldCore=Join-Path $S 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
if((Sha $oldCore)-ne$FoundationCore){Fail "baseline core mismatch; expected Foundation $FoundationCore"}
Write-Host '[2/8] JamVM/glibj/Foundation core VERIFIED'
$jarExpected=ReadPayloadHash 'freej2me-lr.jar';$coreExpected=ReadPayloadHash 'freej2me_plus_libretro.so'
if((Sha $Jar)-ne$jarExpected){Fail 'runtime payload SHA mismatch'}
if((Sha $Core)-ne$coreExpected){Fail 'core payload SHA mismatch'}
Write-Host '[3/8] payload hashes VERIFIED'
Add-Type -AssemblyName System.IO.Compression;Add-Type -AssemblyName System.IO.Compression.FileSystem
$z=[IO.Compression.ZipFile]::OpenRead($Jar);try{$e=$z.GetEntry('org/recompile/mobile/rg35xx-font.bin');if($null-eq$e-or$e.Length-ne727008){Fail 'reconstructed font resource missing/size mismatch'};$ms=New-Object IO.MemoryStream;$st=$e.Open();try{$st.CopyTo($ms)}finally{$st.Dispose()};$h=[Security.Cryptography.SHA256]::Create();try{$fh=([BitConverter]::ToString($h.ComputeHash($ms.ToArray()))).Replace('-','').ToLowerInvariant()}finally{$h.Dispose();$ms.Dispose()};if($fh-ne$ReconFont){Fail 'reconstructed font SHA mismatch'}}finally{$z.Dispose()}
Write-Host '[4/8] reconstructed experimental font VERIFIED'
$targets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$bakRoot=Join-Path $S "RG35XX-JAVA-BACKUP\golden-audio-r2-ab-$stamp";$back=@();$created=@();$coreBak=Join-Path $bakRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
try{
 Write-Host "[5/8] backup=$bakRoot"
 New-Item -ItemType Directory -Force -Path (Split-Path -Parent $coreBak)|Out-Null;Copy-Item -LiteralPath $oldCore -Destination $coreBak -Force
 foreach($rel in $targets){$dst=Join-Path $S $rel;New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null;if(Test-Path -LiteralPath $dst -PathType Leaf){$bak=Join-Path $bakRoot $rel;New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak)|Out-Null;Copy-Item -LiteralPath $dst -Destination $bak -Force;$back+=,@($dst,$bak)}else{$created+=$dst}}
 Write-Host '[6/8] atomic runtime install'
 foreach($rel in $targets){$dst=Join-Path $S $rel;$stage="$dst.audio-r2-new";Copy-Item -LiteralPath $Jar -Destination $stage -Force;if((Sha $stage)-ne$jarExpected){Fail "runtime stage SHA mismatch $rel"};Move-Item -LiteralPath $stage -Destination $dst -Force;if((Sha $dst)-ne$jarExpected){Fail "runtime commit SHA mismatch $rel"}}
 Write-Host '[7/8] atomic native core install'
 $coreStage="$oldCore.audio-r2-new";Copy-Item -LiteralPath $Core -Destination $coreStage -Force;if((Sha $coreStage)-ne$coreExpected){Fail 'core stage SHA mismatch'};Move-Item -LiteralPath $coreStage -Destination $oldCore -Force;if((Sha $oldCore)-ne$coreExpected){Fail 'core commit SHA mismatch'}
 $result=Join-Path $S 'RG35XX-GOLDEN-AUDIO-R2-AB-INSTALL-RESULT.txt';@('RG35XX NOMASK + FONT BYPASS + GOLDEN AUDIO R2 A/B','STATUS=INSTALL-PASS_DEVICE-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","RUNTIME_SHA256=$jarExpected","CORE_SHA256=$coreExpected","PREVIOUS_CORE_SHA256=$FoundationCore","JAMVM_L_SHA256=$Jam","GLIBJ_SHA256=$Glib","FONT_RESOURCE_SHA256=$ReconFont",'FONT_RESOURCE_STATUS=RECONSTRUCTED-EXPERIMENTAL','GREEN_TINT_FIX=NOMASK_RETAINED','AUDIO=RECONSTRUCTED_ASYNC_WORKER_RING_R2','AUDIO_RING=16384','MIDI_PRIME=3072','WORKER_CHUNK=1470','TSF_SYNTH=14700','OUTPUT=44100_MONO_X3','DRAWRGB_AB=NOT_INCLUDED','TRANSPARENCY=NOT_INCLUDED','VIDEO_CHANGES=NONE_IN_AUDIO_R2','DEVICE_PASS=NO','STABLE=NO',"BACKUP=$bakRoot")|Set-Content -LiteralPath $result -Encoding ASCII
 Write-Host '[8/8] INSTALL PASS - DEVICE TEST REQUIRED';Write-Host "Result=$result"
}catch{
 Write-Warning "rollback: $($_.Exception.Message)"
 foreach($rel in $targets){$stage=(Join-Path $S $rel)+'.audio-r2-new';Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue}
 Remove-Item -LiteralPath ($oldCore+'.audio-r2-new') -Force -ErrorAction SilentlyContinue
 foreach($p in $created){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue}
 foreach($x in $back){if(Test-Path -LiteralPath $x[1]){Copy-Item -LiteralPath $x[1] -Destination $x[0] -Force}}
 if(Test-Path -LiteralPath $coreBak){Copy-Item -LiteralPath $coreBak -Destination $oldCore -Force}
 throw
}
