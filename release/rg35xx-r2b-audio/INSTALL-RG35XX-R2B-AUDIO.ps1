param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedBaseCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedBaseRuntime='5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913'
$ExpectedSoundFont='c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854'
$NewRuntime='202714a2509b9c7e62accc925f24cea3d0d1b1d47d3699b015bf8605da3ae929'
$NewCore='54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51'
function Fail([string]$m){throw "RG35XX R2B AUDIO INSTALL FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null};return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
function Resolve-Sd([string]$raw){if([string]::IsNullOrWhiteSpace($raw)){$raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)'};$raw=$raw.Trim().Trim('"');if($raw -match '^[A-Za-z]$'){$raw=$raw+':'};if($raw -match '^[A-Za-z]:$'){$raw=$raw+'\'};if(!(Test-Path -LiteralPath $raw -PathType Container)){Fail "SD root not found: $raw"};$resolved=(Resolve-Path -LiteralPath $raw).Path;$trim=$resolved.TrimEnd('\');if($trim.Length -ne 2 -or $trim[1] -ne ':'){Fail "Refusing non-drive-root path: $resolved"};return $trim+'\'}
function Ensure-Parent([string]$p){$parent=Split-Path -Parent $p;if([string]::IsNullOrWhiteSpace($parent)){return};if(!(Test-Path -LiteralPath $parent -PathType Container)){New-Item -ItemType Directory -Force -Path $parent|Out-Null}}
$Sd=Resolve-Sd $SdRoot
$PayloadRuntime=Join-Path $PSScriptRoot 'payload\freej2me-lr.jar'
$PayloadCore=Join-Path $PSScriptRoot 'payload\freej2me_plus_libretro.so'
if((Sha $PayloadRuntime) -ne $NewRuntime){Fail "payload runtime hash mismatch actual=$(Sha $PayloadRuntime)"}
if((Sha $PayloadCore) -ne $NewCore){Fail "payload core hash mismatch actual=$(Sha $PayloadCore)"}
$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm';$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip';$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so';$soundfont=Join-Path $Sd 'BIOS\freej2me.sf2'
if((Sha $jamvm) -ne $ExpectedJamvm){Fail "JamVM L precondition failed actual=$(Sha $jamvm)"}
if((Sha $glibj) -ne $ExpectedGlibj){Fail "glibj precondition failed actual=$(Sha $glibj)"}
if((Sha $core) -ne $ExpectedBaseCore){Fail "protected B4 core precondition failed. Restore exact R2A first. actual=$(Sha $core)"}
if((Sha $soundfont) -ne $ExpectedSoundFont){Fail "SoundFont precondition failed at BIOS\freej2me.sf2 expected=$ExpectedSoundFont actual=$(Sha $soundfont)"}
$runtimeTargets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
foreach($rel in $runtimeTargets){$h=Sha (Join-Path $Sd $rel);if($h -ne $ExpectedBaseRuntime){Fail "R2A runtime precondition failed at $rel expected=$ExpectedBaseRuntime actual=$h. If R2C-FONT is still installed, restore R2A before R2B."}}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\clean-r2b-audio-$stamp";New-Item -ItemType Directory -Force -Path $backup|Out-Null;$state=@();$allTargets=@($runtimeTargets)+@('CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so')
foreach($rel in $allTargets){$src=Join-Path $Sd $rel;if(Test-Path -LiteralPath $src -PathType Leaf){$dst=Join-Path $backup $rel;Ensure-Parent $dst;Copy-Item -LiteralPath $src -Destination $dst -Force;$state+=("EXISTED|$rel|$(Sha $src)")}else{$state+=("ABSENT|$rel|")}}
$state|Set-Content -LiteralPath (Join-Path $backup 'STATE.txt') -Encoding ASCII
foreach($name in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-control.log')){$p=Join-Path $Sd $name;if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination (Join-Path $backup $name) -Force}}
try{
 foreach($rel in $runtimeTargets){$dst=Join-Path $Sd $rel;Ensure-Parent $dst;$tmp=$dst+'.r2bnew';if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force};Copy-Item -LiteralPath $PayloadRuntime -Destination $tmp -Force;if((Sha $tmp) -ne $NewRuntime){Fail "staged runtime hash mismatch: $rel"};Move-Item -LiteralPath $tmp -Destination $dst -Force;if((Sha $dst) -ne $NewRuntime){Fail "installed runtime hash mismatch: $rel"}}
 $coreTmp=$core+'.r2bnew';if(Test-Path -LiteralPath $coreTmp){Remove-Item -LiteralPath $coreTmp -Force};Copy-Item -LiteralPath $PayloadCore -Destination $coreTmp -Force;if((Sha $coreTmp) -ne $NewCore){Fail 'staged core hash mismatch'};Move-Item -LiteralPath $coreTmp -Destination $core -Force;if((Sha $core) -ne $NewCore){Fail 'installed core hash mismatch'}
 foreach($name in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-control.log')){$p=Join-Path $Sd $name;if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}}
 @('RG35XX CLEAN R2B AUDIO','RESULT=PASS','STATUS=BUILD-PASS_INSTALLED_DEVICE-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","BACKUP=$backup","BASE_R2A_RUNTIME_SHA256=$ExpectedBaseRuntime","OLD_B4_CORE_SHA256=$ExpectedBaseCore","NEW_R2B_RUNTIME_SHA256=$NewRuntime","NEW_R2B_CORE_SHA256=$NewCore","SOUNDFONT_SHA256=$ExpectedSoundFont","JAMVM_SHA256=$ExpectedJamvm","GLIBJ_SHA256=$ExpectedGlibj",'PRIMARY_VARIABLE=AUDIO_OWNERSHIP_ONLY','AUDIO_OWNER=DEDICATED_FD_WORKER_RING_ASYNC_CALLBACK','RING_FRAMES=16384','PRIME_FRAMES=3072','WORKER_CHUNK=1470','RETRO_RUN_AUDIO_PUMP=ABSENT','SYNTH_STAGE=44100_STEREO_RECONSTRUCTION_NOT_GOLDEN','FONT_CHANGE=NONE','TRANSPARENCY_CHANGE=NONE','CANVAS_CHANGE=NONE','FULL_PLATFORM_STABLE=NO')|Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-CLEAN-R2B-AUDIO-INSTALL-RESULT.txt') -Encoding ASCII
 Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-CLEAN-R2B-AUDIO-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - RG35XX CLEAN R2B AUDIO';Write-Host "NEW_R2B_RUNTIME_SHA256=$NewRuntime";Write-Host "NEW_R2B_CORE_SHA256=$NewCore"
}catch{$original=$_.Exception;foreach($line in @(Get-Content -LiteralPath (Join-Path $backup 'STATE.txt'))){$p=$line.Split('|');if($p.Count -lt 2){continue};$kind=$p[0];$rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel;if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue};if($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)){Ensure-Parent $dst;Copy-Item -LiteralPath $bak -Destination $dst -Force}};throw $original}
