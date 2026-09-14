param([Parameter(Mandatory=$false,Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$Jam='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$Glib='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$R22Runtime='2cf28cd1832ba964c5db5e67c57e07ec5716bbc0aca88d8365c6188812f5d65b'
$R22Core3072='1a06a00df7bcc4c1a80edf6808602202dbd1f493cf36c5569906d17a5fc907b6'
$R22Core2048='6a8d46040b1cea9325f7ce9a4a5eebaae27bbbc5c31a9de17e099a3be9f41d63'
$Pkg=Split-Path -Parent $PSScriptRoot; $Pay=Join-Path $Pkg 'payload'; $HashFile=Join-Path $Pay 'PAYLOAD-SHA256.txt'
function Fail([string]$m){throw "AUDIO-R2.3-HANG-LOCALIZATION FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){Fail "missing $p"};(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Sd([string]$p){if([string]::IsNullOrWhiteSpace($p)){$p=Read-Host 'Nhap o SD, vi du H'};$p=$p.Trim().Trim('"');if($p-match'^[A-Za-z]$'){$p="$p`:"};if($p-match'^[A-Za-z]:$'){$p="$p\"};if(!(Test-Path -LiteralPath $p -PathType Container)){Fail "SD root not found: $p"};$r=(Resolve-Path -LiteralPath $p).Path;if($r-notmatch'^[A-Za-z]:\\?$'){Fail "not drive root: $r"};$r.TrimEnd('\')+'\'}
function ReadPayloadHash([string]$name){$line=Get-Content -LiteralPath $HashFile | Where-Object {$_ -match "\s+$([regex]::Escape($name))$"}|Select-Object -First 1;if($null-eq$line){Fail "missing payload hash for $name"};($line -split '\s+')[0].ToLowerInvariant()}
$S=Sd $SdRoot; Write-Host "[1/7] SD=$S"
if((Sha (Join-Path $S 'CFW\java\bin\jamvm'))-ne$Jam){Fail 'JamVM mismatch'}
if((Sha (Join-Path $S 'CFW\java\share\classpath\glibj.zip'))-ne$Glib){Fail 'glibj mismatch'}
$runtime=Join-Path $S 'BIOS\freej2me-lr.jar'; if((Sha $runtime)-ne$R22Runtime){Fail 'runtime is not exact R2.2 baseline'}
$core=Join-Path $S 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'; $oldCoreHash=Sha $core
if($oldCoreHash-eq$R22Core3072){$prime='3072';$corePayload=Join-Path $Pay 'freej2me_plus_libretro-r23-prime3072.so'}elseif($oldCoreHash-eq$R22Core2048){$prime='2048';$corePayload=Join-Path $Pay 'freej2me_plus_libretro-r23-prime2048.so'}else{Fail "unsupported core $oldCoreHash; expected exact R2.2 3072 or 2048"}
Write-Host "[2/7] exact R2.2 baseline VERIFIED prime=$prime"
$coreName=Split-Path -Leaf $corePayload; $coreExpected=ReadPayloadHash $coreName
if((Sha $corePayload)-ne$coreExpected){Fail 'diagnostic core payload SHA mismatch'}
Write-Host '[3/7] payload hash VERIFIED'
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$bakRoot=Join-Path $S "RG35XX-JAVA-BACKUP\audio-r2.3-hang-localization-$stamp";$coreBak=Join-Path $bakRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so';New-Item -ItemType Directory -Force -Path (Split-Path -Parent $coreBak)|Out-Null;Copy-Item -LiteralPath $core -Destination $coreBak -Force
$early=Join-Path $S 'freej2me-vc3-early.log';if(Test-Path -LiteralPath $early -PathType Leaf){New-Item -ItemType Directory -Force -Path $bakRoot|Out-Null;Copy-Item -LiteralPath $early -Destination (Join-Path $bakRoot 'freej2me-vc3-early.before-r23.log') -Force}
try{
 Write-Host "[4/7] backup=$bakRoot"
 $stage="$core.r23-new";Copy-Item -LiteralPath $corePayload -Destination $stage -Force;if((Sha $stage)-ne$coreExpected){Fail 'core stage mismatch'};Move-Item -LiteralPath $stage -Destination $core -Force;if((Sha $core)-ne$coreExpected){Fail 'core commit mismatch'}
 Write-Host "[5/7] diagnostic core installed prime=$prime"
 '' | Set-Content -LiteralPath $early -Encoding ASCII
 Write-Host '[6/7] early diagnostic log reset'
 $result=Join-Path $S 'RG35XX-AUDIO-R2.3-HANG-LOCALIZATION-INSTALL-RESULT.txt';@('RG35XX AUDIO R2.3 HANG LOCALIZATION A/B','STATUS=INSTALL-PASS_DEVICE-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","PREVIOUS_CORE_SHA256=$oldCoreHash","BASELINE_PRIME=$prime","RUNTIME_SHA256=$R22Runtime","CORE_SHA256=$coreExpected",'PRIMARY_DELTA=BOUNDED_NATIVE_DIAGNOSTICS_ONLY','LOG=/mnt/mmc/freej2me-vc3-early.log','CHECKPOINTS=1,8,32,128,512,2048,8192','R2.2_FILE_MIDI=UNCHANGED','AUDIO_RING=16384','WORKER_CHUNK=1470','TSF_SYNTH=14700','OUTPUT=44100_MONO_X3','VIDEO_BEHAVIOR=UNCHANGED','DEVICE_PASS=NO','STABLE=NO',"BACKUP=$bakRoot")|Set-Content -LiteralPath $result -Encoding ASCII
 Write-Host '[7/7] INSTALL PASS - RUN KDTT AND COLLECT LOG';Write-Host "Result=$result"
}catch{Remove-Item -LiteralPath ($core+'.r23-new') -Force -ErrorAction SilentlyContinue;if(Test-Path -LiteralPath $coreBak){Copy-Item -LiteralPath $coreBak -Destination $core -Force};throw}
