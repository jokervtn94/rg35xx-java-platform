param([Parameter(Mandatory=$false,Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$Jam='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$Glib='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$R2Runtime='b71a61ec4a1be0237b0fbdc74834ae1dbe32575272241f53c9de791b2a56f6d2'
$R2Core3072='a8e59eca633dfcaa3fc0e8c027fcffaa35f53d1ff5d127b7062edfd962fe7c57'
$R21Core2048='3a843fe06c73958dc383e1689806c440e17b86605af9718d99bbf0763d570a7d'
$Pkg=Split-Path -Parent $PSScriptRoot; $Pay=Join-Path $Pkg 'payload'; $HashFile=Join-Path $Pay 'PAYLOAD-SHA256.txt'
function Fail([string]$m){throw "AUDIO-R2.2-FILE-MIDI-AB FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){Fail "missing $p"};(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Sd([string]$p){if([string]::IsNullOrWhiteSpace($p)){$p=Read-Host 'Nhap o SD, vi du H'};$p=$p.Trim().Trim('"');if($p-match'^[A-Za-z]$'){$p="$p`:"};if($p-match'^[A-Za-z]:$'){$p="$p\"};if(!(Test-Path -LiteralPath $p -PathType Container)){Fail "SD root not found: $p"};$r=(Resolve-Path -LiteralPath $p).Path;if($r-notmatch'^[A-Za-z]:\\?$'){Fail "not drive root: $r"};$r.TrimEnd('\')+'\'}
function ReadPayloadHash([string]$name){$line=Get-Content -LiteralPath $HashFile | Where-Object {$_ -match "\s+$([regex]::Escape($name))$"}|Select-Object -First 1;if($null-eq$line){Fail "missing payload hash for $name"};($line -split '\s+')[0].ToLowerInvariant()}
$S=Sd $SdRoot; Write-Host "[1/8] SD=$S"
if((Sha (Join-Path $S 'CFW\java\bin\jamvm'))-ne$Jam){Fail 'JamVM mismatch'}
if((Sha (Join-Path $S 'CFW\java\share\classpath\glibj.zip'))-ne$Glib){Fail 'glibj mismatch'}
$runtime=Join-Path $S 'BIOS\freej2me-lr.jar'; if((Sha $runtime)-ne$R2Runtime){Fail 'runtime is not exact R2 baseline'}
$core=Join-Path $S 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'; $oldCoreHash=Sha $core
if($oldCoreHash-eq$R2Core3072){$prime='3072';$corePayload=Join-Path $Pay 'freej2me_plus_libretro-prime3072.so'}elseif($oldCoreHash-eq$R21Core2048){$prime='2048';$corePayload=Join-Path $Pay 'freej2me_plus_libretro-prime2048.so'}else{Fail "unsupported baseline core $oldCoreHash; expected exact R2 or R2.1"}
Write-Host "[2/8] exact baseline VERIFIED prime=$prime"
$jarPayload=Join-Path $Pay 'freej2me-lr.jar'; $jarExpected=ReadPayloadHash 'freej2me-lr.jar'; $coreName=Split-Path -Leaf $corePayload; $coreExpected=ReadPayloadHash $coreName
if((Sha $jarPayload)-ne$jarExpected){Fail 'runtime payload SHA mismatch'};if((Sha $corePayload)-ne$coreExpected){Fail 'core payload SHA mismatch'}
Write-Host '[3/8] payload hashes VERIFIED'
$targets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$bakRoot=Join-Path $S "RG35XX-JAVA-BACKUP\audio-r2.2-file-midi-$stamp";$back=@();$created=@();$coreBak=Join-Path $bakRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
try{
 Write-Host "[4/8] backup=$bakRoot";New-Item -ItemType Directory -Force -Path (Split-Path -Parent $coreBak)|Out-Null;Copy-Item -LiteralPath $core -Destination $coreBak -Force
 foreach($rel in $targets){$dst=Join-Path $S $rel;New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null;if(Test-Path -LiteralPath $dst -PathType Leaf){$bak=Join-Path $bakRoot $rel;New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak)|Out-Null;Copy-Item -LiteralPath $dst -Destination $bak -Force;$back+=,@($dst,$bak)}else{$created+=$dst}}
 Write-Host '[5/8] atomic R2.2 runtime install';foreach($rel in $targets){$dst=Join-Path $S $rel;$stage="$dst.r22-new";Copy-Item -LiteralPath $jarPayload -Destination $stage -Force;if((Sha $stage)-ne$jarExpected){Fail "runtime stage mismatch $rel"};Move-Item -LiteralPath $stage -Destination $dst -Force;if((Sha $dst)-ne$jarExpected){Fail "runtime commit mismatch $rel"}}
 Write-Host "[6/8] atomic R2.2 core install preserving prime=$prime";$stage="$core.r22-new";Copy-Item -LiteralPath $corePayload -Destination $stage -Force;if((Sha $stage)-ne$coreExpected){Fail 'core stage mismatch'};Move-Item -LiteralPath $stage -Destination $core -Force;if((Sha $core)-ne$coreExpected){Fail 'core commit mismatch'}
 $cache=Join-Path $S 'CFW\java\cache\freej2me-media';New-Item -ItemType Directory -Force -Path $cache|Out-Null
 Write-Host '[7/8] cache directory ready'
 $result=Join-Path $S 'RG35XX-AUDIO-R2.2-FILE-MIDI-AB-INSTALL-RESULT.txt';@('RG35XX AUDIO R2.2 FILE-BACKED MIDI A/B','STATUS=INSTALL-PASS_DEVICE-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","PREVIOUS_CORE_SHA256=$oldCoreHash","BASELINE_PRIME=$prime","RUNTIME_SHA256=$jarExpected","CORE_SHA256=$coreExpected",'PRIMARY_DELTA=MIDI_BLOB_PIPE_TO_FILE_PATH_COMMAND','MIDI_CACHE=/mnt/mmc/CFW/java/cache/freej2me-media','TONE_INLINE=UNCHANGED','PCM_INLINE=UNCHANGED','AUDIO_RING=16384','WORKER_CHUNK=1470','TSF_SYNTH=14700','OUTPUT=44100_MONO_X3','VIDEO=UNCHANGED','NOMASK=UNCHANGED','FONT=UNCHANGED','DEVICE_PASS=NO','STABLE=NO',"BACKUP=$bakRoot")|Set-Content -LiteralPath $result -Encoding ASCII
 Write-Host '[8/8] INSTALL PASS - DEVICE TEST REQUIRED';Write-Host "Result=$result"
}catch{
 Write-Warning "rollback: $($_.Exception.Message)";foreach($rel in $targets){Remove-Item -LiteralPath ((Join-Path $S $rel)+'.r22-new') -Force -ErrorAction SilentlyContinue};Remove-Item -LiteralPath ($core+'.r22-new') -Force -ErrorAction SilentlyContinue;foreach($p in $created){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue};foreach($x in $back){if(Test-Path -LiteralPath $x[1]){Copy-Item -LiteralPath $x[1] -Destination $x[0] -Force}};if(Test-Path -LiteralPath $coreBak){Copy-Item -LiteralPath $coreBak -Destination $core -Force};throw
}
