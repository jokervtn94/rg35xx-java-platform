param([Parameter(Mandatory=$false,Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$Jam='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$Glib='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$R2Runtime='b71a61ec4a1be0237b0fbdc74834ae1dbe32575272241f53c9de791b2a56f6d2'
$R2Core='a8e59eca633dfcaa3fc0e8c027fcffaa35f53d1ff5d127b7062edfd962fe7c57'
$Pkg=Split-Path -Parent $PSScriptRoot; $Pay=Join-Path $Pkg 'payload'
$Core=Join-Path $Pay 'freej2me_plus_libretro.so'; $HashFile=Join-Path $Pay 'PAYLOAD-SHA256.txt'
function Fail([string]$m){throw "AUDIO-R2.1-PRIME2048-AB FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){Fail "missing $p"};(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Sd([string]$p){if([string]::IsNullOrWhiteSpace($p)){$p=Read-Host 'Nhap o SD, vi du H'};$p=$p.Trim().Trim('"');if($p-match'^[A-Za-z]$'){$p="$p`:"};if($p-match'^[A-Za-z]:$'){$p="$p\"};if(!(Test-Path -LiteralPath $p -PathType Container)){Fail "SD root not found: $p"};$r=(Resolve-Path -LiteralPath $p).Path;if($r-notmatch'^[A-Za-z]:\\?$'){Fail "not drive root: $r"};$r.TrimEnd('\')+'\'}
function ReadPayloadHash([string]$name){$line=Get-Content -LiteralPath $HashFile | Where-Object {$_ -match "\s+$([regex]::Escape($name))$"} | Select-Object -First 1;if($null-eq$line){Fail "missing payload hash for $name"};($line -split '\s+')[0].ToLowerInvariant()}
$S=Sd $SdRoot; Write-Host "[1/6] SD=$S"
if((Sha (Join-Path $S 'CFW\java\bin\jamvm'))-ne$Jam){Fail 'JamVM mismatch'}
if((Sha (Join-Path $S 'CFW\java\share\classpath\glibj.zip'))-ne$Glib){Fail 'glibj mismatch'}
$runtime=Join-Path $S 'BIOS\freej2me-lr.jar'; if((Sha $runtime)-ne$R2Runtime){Fail "R2 runtime mismatch; expected $R2Runtime"}
$oldCore=Join-Path $S 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'; if((Sha $oldCore)-ne$R2Core){Fail "R2 core mismatch; expected $R2Core"}
Write-Host '[2/6] exact R2 baseline VERIFIED'
$coreExpected=ReadPayloadHash 'freej2me_plus_libretro.so'; if((Sha $Core)-ne$coreExpected){Fail 'R2.1 core payload SHA mismatch'}
Write-Host '[3/6] core payload VERIFIED'
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$bakRoot=Join-Path $S "RG35XX-JAVA-BACKUP\audio-r2.1-prime2048-ab-$stamp";$coreBak=Join-Path $bakRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
try{
 Write-Host "[4/6] backup=$bakRoot";New-Item -ItemType Directory -Force -Path (Split-Path -Parent $coreBak)|Out-Null;Copy-Item -LiteralPath $oldCore -Destination $coreBak -Force
 Write-Host '[5/6] atomic core-only A/B install';$stage="$oldCore.audio-r21-new";Copy-Item -LiteralPath $Core -Destination $stage -Force;if((Sha $stage)-ne$coreExpected){Fail 'stage SHA mismatch'};Move-Item -LiteralPath $stage -Destination $oldCore -Force;if((Sha $oldCore)-ne$coreExpected){Fail 'commit SHA mismatch'}
 $result=Join-Path $S 'RG35XX-AUDIO-R2.1-PRIME2048-AB-INSTALL-RESULT.txt';@('RG35XX AUDIO R2.1 PRIME2048 A/B','STATUS=INSTALL-PASS_DEVICE-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","PRESERVED_RUNTIME_SHA256=$R2Runtime","PREVIOUS_CORE_SHA256=$R2Core","CORE_SHA256=$coreExpected","JAMVM_L_SHA256=$Jam","GLIBJ_SHA256=$Glib",'ONLY_PRIMARY_DELTA=MIDI_PRIME_3072_TO_2048','AUDIO_RING=16384','MIDI_PRIME=2048','WORKER_CHUNK=1470','TSF_SYNTH=14700','OUTPUT=44100_MONO_X3','JAVA_RUNTIME=UNCHANGED_R2','VIDEO=UNCHANGED_R2','FONT=UNCHANGED_R2','NOMASK=UNCHANGED_R2','TRANSPARENCY=UNCHANGED','PCM_PRIME_2940=NOT_CHANGED_NOT_CLAIMED','DEVICE_PASS=NO','STABLE=NO',"BACKUP=$bakRoot")|Set-Content -LiteralPath $result -Encoding ASCII
 Write-Host '[6/6] INSTALL PASS - DEVICE TEST REQUIRED';Write-Host "Result=$result"
}catch{
 Write-Warning "rollback: $($_.Exception.Message)";Remove-Item -LiteralPath ($oldCore+'.audio-r21-new') -Force -ErrorAction SilentlyContinue;if(Test-Path -LiteralPath $coreBak){Copy-Item -LiteralPath $coreBak -Destination $oldCore -Force};throw
}
