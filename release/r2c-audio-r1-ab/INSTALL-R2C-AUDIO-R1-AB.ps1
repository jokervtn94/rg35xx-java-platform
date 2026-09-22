param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$ExpectedR2C='0f38d6181201b3c5128b421e8d0ee747b69911c928a728fd9b3207e39e067e34'
$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedSoundFont='c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854'
$NewRuntime='__R2C_AUDIO_R1_RUNTIME_SHA256__'
$NewCore='__R2C_AUDIO_R1_CORE_SHA256__'
function Fail([string]$m){throw "R2C-AUDIO-R1-AB INSTALL FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null};return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
function Ensure-Parent([string]$p){$d=Split-Path -Parent $p;if([string]::IsNullOrWhiteSpace($d)){return};if(!(Test-Path -LiteralPath $d -PathType Container)){New-Item -ItemType Directory -Force -Path $d|Out-Null}}
function Resolve-Sd([string]$raw){if([string]::IsNullOrWhiteSpace($raw)){$raw=Read-Host 'Nhap ky tu o SD RG35XX'};$raw=$raw.Trim().Trim('"');if($raw -match '^[A-Za-z]$'){$raw=$raw+':'};if($raw -match '^[A-Za-z]:$'){$raw=$raw+'\'};if(!(Test-Path -LiteralPath $raw -PathType Container)){Fail "SD root not found: $raw"};$r=(Resolve-Path -LiteralPath $raw).Path;$t=$r.TrimEnd('\');if($t.Length -ne 2 -or $t[1] -ne ':'){Fail "Refusing non-drive-root path: $r"};return $t+'\'}
$Sd=Resolve-Sd $SdRoot
$payloadJar=Join-Path $PSScriptRoot 'payload\freej2me-lr.jar'
$payloadCore=Join-Path $PSScriptRoot 'payload\freej2me_plus_libretro.so'
if((Sha $payloadJar)-ne $NewRuntime){Fail "runtime payload hash mismatch actual=$(Sha $payloadJar)"}
if((Sha $payloadCore)-ne $NewCore){Fail "core payload hash mismatch actual=$(Sha $payloadCore)"}
$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm';$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip';$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so';$sf=Join-Path $Sd 'BIOS\freej2me.sf2'
if((Sha $jamvm)-ne $ExpectedJamvm){Fail "JamVM mismatch actual=$(Sha $jamvm)"}
if((Sha $glibj)-ne $ExpectedGlibj){Fail "glibj mismatch actual=$(Sha $glibj)"}
if((Sha $core)-ne $ExpectedCore){Fail "B4 core baseline mismatch actual=$(Sha $core). Restore exact R2A then install exact R2C-FONT before this checkpoint."}
if((Sha $sf)-ne $ExpectedSoundFont){Fail "SoundFont mismatch actual=$(Sha $sf)"}
$runtimeTargets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
foreach($rel in $runtimeTargets){$h=Sha (Join-Path $Sd $rel);if($h-ne $ExpectedR2C){Fail "exact R2C-FONT required at $rel expected=$ExpectedR2C actual=$h"}}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\r2c-audio-r1-ab-$stamp";New-Item -ItemType Directory -Force -Path $backup|Out-Null
$all=@($runtimeTargets)+@('CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so');$state=@()
foreach($rel in $all){$src=Join-Path $Sd $rel;$dst=Join-Path $backup $rel;Ensure-Parent $dst;Copy-Item -LiteralPath $src -Destination $dst -Force;$state+=("EXISTED|$rel|$(Sha $src)")}
$state|Set-Content -LiteralPath (Join-Path $backup 'STATE.txt') -Encoding ASCII
foreach($n in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-control.log')){$p=Join-Path $Sd $n;if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination (Join-Path $backup $n) -Force}}
try{
 foreach($rel in $runtimeTargets){$dst=Join-Path $Sd $rel;$tmp=$dst+'.r2caudionew';if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force};Copy-Item -LiteralPath $payloadJar -Destination $tmp -Force;if((Sha $tmp)-ne $NewRuntime){Fail "staged runtime hash mismatch $rel"};Move-Item -LiteralPath $tmp -Destination $dst -Force;if((Sha $dst)-ne $NewRuntime){Fail "installed runtime hash mismatch $rel"}}
 $tmpc=$core+'.r2caudionew';if(Test-Path -LiteralPath $tmpc){Remove-Item -LiteralPath $tmpc -Force};Copy-Item -LiteralPath $payloadCore -Destination $tmpc -Force;if((Sha $tmpc)-ne $NewCore){Fail 'staged core hash mismatch'};Move-Item -LiteralPath $tmpc -Destination $core -Force;if((Sha $core)-ne $NewCore){Fail 'installed core hash mismatch'}
 foreach($n in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-control.log')){$p=Join-Path $Sd $n;if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}}
 @('R2C-AUDIO-R1-AB','RESULT=PASS','STATUS=BUILD-PASS_INSTALLED_DEVICE-TEST-PENDING',"TIME=$((Get-Date).ToString('s'))","BACKUP=$backup","BASE_R2C_RUNTIME_SHA256=$ExpectedR2C","NEW_RUNTIME_SHA256=$NewRuntime","OLD_B4_CORE_SHA256=$ExpectedCore","NEW_CORE_SHA256=$NewCore","SOUNDFONT_SHA256=$ExpectedSoundFont",'PRIMARY_VARIABLE=AUDIO_OWNERSHIP_ONLY','FONT_BASELINE=R2C_RECONSTRUCTED_NOT_GOLDEN','TRANSPARENCY_CHANGE=NONE','VIDEO_CHANGE=NONE','CANVAS_CHANGE=NONE','STABLE=NO')|Set-Content -LiteralPath (Join-Path $Sd 'R2C-AUDIO-R1-AB-INSTALL-RESULT.txt') -Encoding ASCII
 Set-Content -LiteralPath (Join-Path $Sd 'R2C-AUDIO-R1-AB-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - R2C-AUDIO-R1-AB';Write-Host "NEW_RUNTIME_SHA256=$NewRuntime";Write-Host "NEW_CORE_SHA256=$NewCore"
}catch{$original=$_.Exception;foreach($line in @(Get-Content -LiteralPath (Join-Path $backup 'STATE.txt'))){$p=$line.Split('|');if($p.Count-lt 2){continue};$rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel;if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue};if(Test-Path -LiteralPath $bak -PathType Leaf){Ensure-Parent $dst;Copy-Item -LiteralPath $bak -Destination $dst -Force}};throw $original}
