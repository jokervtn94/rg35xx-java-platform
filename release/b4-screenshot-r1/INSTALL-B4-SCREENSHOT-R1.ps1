param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedRuntime='4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c'
$ExpectedOldCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$NewCore='__NEW_CORE_SHA256__'

function Fail([string]$m){throw "B4-SCREENSHOT-R1 INSTALL FAIL: $m"}
function Sha([string]$p){
 if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}
 return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function Resolve-Sd([string]$raw){
 if([string]::IsNullOrWhiteSpace($raw)){$raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du G)'}
 $raw=$raw.Trim().Trim('"')
 if($raw -match '^[A-Za-z]$'){$raw=$raw+':'}
 if($raw -match '^[A-Za-z]:$'){$raw=$raw+'\'}
 if(!(Test-Path -LiteralPath $raw -PathType Container)){Fail "SD root not found: $raw"}
 $resolved=(Resolve-Path -LiteralPath $raw).Path
 $trim=$resolved.TrimEnd('\')
 if($trim.Length -ne 2 -or $trim[1] -ne ':'){Fail "Refusing non-drive-root path: $resolved"}
 return $trim+'\'
}

$Sd=Resolve-Sd $SdRoot
$Payload=Join-Path $PSScriptRoot 'payload\freej2me_plus_libretro.so'
if((Sha $Payload) -ne $NewCore){
 Fail "Payload core hash mismatch expected=$NewCore actual=$(Sha $Payload)"
}

$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$runtime=Join-Path $Sd 'BIOS\freej2me-lr.jar'
$coreMain=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$coreAlias=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so'

if((Sha $jamvm) -ne $ExpectedJamvm){Fail 'JamVM L precondition failed'}
if((Sha $glibj) -ne $ExpectedGlibj){Fail 'glibj precondition failed'}
if((Sha $runtime) -ne $ExpectedRuntime){Fail "B4-HOTPATH-R2 runtime precondition failed actual=$(Sha $runtime)"}
if((Sha $coreMain) -ne $ExpectedOldCore){Fail "B4 core precondition failed actual=$(Sha $coreMain)"}
if((Test-Path -LiteralPath $coreAlias -PathType Leaf) -and ((Sha $coreAlias) -ne $ExpectedOldCore)){
 Fail "core alias has unexpected hash actual=$(Sha $coreAlias)"
}

$coreTargets=@('CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so')
if(Test-Path -LiteralPath $coreAlias -PathType Leaf){
 $coreTargets+= 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so'
}

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\b4-screenshot-r1-$stamp"
New-Item -ItemType Directory -Force -Path $backup|Out-Null
$state=@()

foreach($rel in $coreTargets){
 $src=Join-Path $Sd $rel
 $dst=Join-Path $backup $rel
 New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
 Copy-Item -LiteralPath $src -Destination $dst -Force
 $state+="EXISTED|$rel"
}
$state|Set-Content -LiteralPath (Join-Path $backup 'STATE.txt') -Encoding ASCII

try {
 foreach($rel in $coreTargets){
   $dst=Join-Path $Sd $rel
   $tmp=$dst+'.b4shotr1new'
   if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force}
   Copy-Item -LiteralPath $Payload -Destination $tmp -Force
   if((Sha $tmp) -ne $NewCore){Fail "staged core hash mismatch: $rel"}
   Move-Item -LiteralPath $tmp -Destination $dst -Force
   if((Sha $dst) -ne $NewCore){Fail "installed core hash mismatch: $rel"}
 }

 foreach($name in @('freej2me-vc3-early.log','freej2me-core.log','freej2me-java-error.log')){
   $p=Join-Path $Sd $name
   if(Test-Path -LiteralPath $p -PathType Leaf){
     Copy-Item -LiteralPath $p -Destination (Join-Path $backup $name) -Force
     Remove-Item -LiteralPath $p -Force
   }
 }

 $report=Join-Path $Sd 'RG35XX-B4-SCREENSHOT-R1-INSTALL-RESULT.txt'
 @(
  'RG35XX B4 SCREENSHOT R1 AB',
  'RESULT=PASS',
  'STATUS=BUILD-PASS_INSTALLED_DEVICE-TEST-PENDING',
  "TIME=$((Get-Date).ToString('s'))",
  "BACKUP=$backup",
  "RUNTIME_SHA256=$ExpectedRuntime",
  "OLD_CORE_SHA256=$ExpectedOldCore",
  "NEW_CORE_SHA256=$NewCore",
  "JAMVM_SHA256=$ExpectedJamvm",
  "GLIBJ_SHA256=$ExpectedGlibj",
  'PRIMARY_VARIABLE=NATIVE_PRESENTATION_CANVAS_LIFETIME_ONLY',
  'PRESENTATION=DOUBLE_BUFFERED',
  'VIDEO_MASK_R2=PRESERVED_IN_RUNTIME',
  'HOTPATH_R2=PRESERVED_IN_RUNTIME',
  'FRAME_PROTOCOL=UNCHANGED',
  'SMART_FIT=UNCHANGED',
  'AUDIO_CHANGE=NONE',
  'FONT_CHANGE=NONE',
  'FULL_PLATFORM_STABLE=NO'
 )|Set-Content -LiteralPath $report -Encoding ASCII

 Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-SCREENSHOT-R1-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - B4 SCREENSHOT R1'
}
catch {
 foreach($line in Get-Content -LiteralPath (Join-Path $backup 'STATE.txt')){
   $p=$line.Split('|',2); if($p.Count -ne 2){continue}
   $rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel
   if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue}
   if(Test-Path -LiteralPath $bak -PathType Leaf){
     New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
     Copy-Item -LiteralPath $bak -Destination $dst -Force
   }
 }
 throw
}
