param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedR1Runtime='6053eb80f890c33a4ef2466e1c18c516178d3b4a0d1ad5130c91a532951d9921'
$NewRuntime='__R2A_RUNTIME_SHA256__'

function Fail([string]$m){throw "RG35XX CLEAN R2A INSTALL FAIL: $m"}
function Sha([string]$p){
 if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}
 return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function Resolve-Sd([string]$raw){
 if([string]::IsNullOrWhiteSpace($raw)){$raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)'}
 $raw=$raw.Trim().Trim('"')
 if($raw -match '^[A-Za-z]$'){$raw=$raw+':'}
 if($raw -match '^[A-Za-z]:$'){$raw=$raw+'\'}
 if(!(Test-Path -LiteralPath $raw -PathType Container)){Fail "SD root not found: $raw"}
 $resolved=(Resolve-Path -LiteralPath $raw).Path
 $trim=$resolved.TrimEnd('\')
 if($trim.Length -ne 2 -or $trim[1] -ne ':'){Fail "Refusing non-drive-root path: $resolved"}
 return $trim+'\'
}
function Ensure-Parent([string]$p){
 $parent=Split-Path -Parent $p
 if([string]::IsNullOrWhiteSpace($parent)){return}
 if(Test-Path -LiteralPath $parent -PathType Container){return}
 New-Item -ItemType Directory -Force -Path $parent|Out-Null
}

$Sd=Resolve-Sd $SdRoot
$Payload=Join-Path $PSScriptRoot 'payload\freej2me-lr.jar'
if((Sha $Payload) -ne $NewRuntime){Fail "Payload runtime hash mismatch actual=$(Sha $Payload)"}

$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'

if((Sha $jamvm) -ne $ExpectedJamvm){Fail "JamVM L precondition failed actual=$(Sha $jamvm)"}
if((Sha $glibj) -ne $ExpectedGlibj){Fail "glibj precondition failed actual=$(Sha $glibj)"}
if((Sha $core) -ne $ExpectedCore){Fail "protected B4 core precondition failed actual=$(Sha $core)"}

$targets=@(
 'BIOS\freej2me-lr.jar',
 'BIOS\freej2me_plus-lr.jar',
 'CFW\java\share\freej2me\freej2me-lr.jar',
 'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
 'CFW\retroarch\system\freej2me-lr.jar'
)

# R2A is deliberately an overlay on the exact installed R1 runtime.
foreach($rel in $targets){
 $p=Join-Path $Sd $rel
 $h=Sha $p
 if($h -ne $ExpectedR1Runtime){
   Fail "R1 runtime precondition failed at $rel expected=$ExpectedR1Runtime actual=$h"
 }
}

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\clean-consolidated-r2a-$stamp"
New-Item -ItemType Directory -Force -Path $backup|Out-Null
$state=@()

foreach($rel in $targets){
 $src=Join-Path $Sd $rel
 $dst=Join-Path $backup $rel
 Ensure-Parent $dst
 Copy-Item -LiteralPath $src -Destination $dst -Force
 $state+=("EXISTED|$rel|$(Sha $src)")
}
$state|Set-Content -LiteralPath (Join-Path $backup 'STATE.txt') -Encoding ASCII

foreach($name in @(
 'freej2me-java-error.log',
 'freej2me-vc3-early.log',
 'freej2me-core.log',
 'freej2me-java-control.log'
)){
 $p=Join-Path $Sd $name
 if(Test-Path -LiteralPath $p -PathType Leaf){
   Copy-Item -LiteralPath $p -Destination (Join-Path $backup $name) -Force
 }
}

try {
 foreach($rel in $targets){
   $dst=Join-Path $Sd $rel
   Ensure-Parent $dst
   $tmp=$dst+'.r2anew'
   if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force}
   Copy-Item -LiteralPath $Payload -Destination $tmp -Force
   if((Sha $tmp) -ne $NewRuntime){Fail "staged hash mismatch: $rel"}
   Move-Item -LiteralPath $tmp -Destination $dst -Force
   if((Sha $dst) -ne $NewRuntime){Fail "installed hash mismatch: $rel"}
 }

 foreach($name in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-control.log')){
   $p=Join-Path $Sd $name
   if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}
 }

 $report=Join-Path $Sd 'RG35XX-CLEAN-CONSOLIDATED-R2A-INSTALL-RESULT.txt'
 @(
  'RG35XX CLEAN CONSOLIDATED R2A',
  'RESULT=PASS',
  'STATUS=BUILD-PASS_INSTALLED_DEVICE-TEST-PENDING',
  "TIME=$((Get-Date).ToString('s'))",
  "BACKUP=$backup",
  "OLD_R1_RUNTIME_SHA256=$ExpectedR1Runtime",
  "NEW_R2A_RUNTIME_SHA256=$NewRuntime",
  "CORE_SHA256=$ExpectedCore",
  "JAMVM_SHA256=$ExpectedJamvm",
  "GLIBJ_SHA256=$ExpectedGlibj",
  'R2A_IMAGE_NORMALIZE=ENABLED',
  'PNG_ICCP=R1_PRESERVED',
  'DYNAMIC_LOGICAL_VIEW=R1_PRESERVED',
  'VIDEO_MASK_R2=R1_PRESERVED',
  'HOTPATH_R2=R1_PRESERVED',
  'CANONICAL_FRAMEBUFFER=R1_PRESERVED',
  'AUDIO_CHANGE=NONE',
  'CANVAS_CHANGE=NONE',
  'NATIVE_CORE_CHANGE=NONE',
  'FULL_PLATFORM_STABLE=NO'
 )|Set-Content -LiteralPath $report -Encoding ASCII

 Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-CLEAN-CONSOLIDATED-R2A-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - RG35XX CLEAN CONSOLIDATED R2A'
 Write-Host "OLD_R1_RUNTIME_SHA256=$ExpectedR1Runtime"
 Write-Host "NEW_R2A_RUNTIME_SHA256=$NewRuntime"
}
catch {
 $original=$_.Exception
 foreach($line in @(Get-Content -LiteralPath (Join-Path $backup 'STATE.txt'))){
   $p=$line.Split('|'); if($p.Count -lt 2){continue}
   $kind=$p[0];$rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel
   if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue}
   if($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)){
     Ensure-Parent $dst
     Copy-Item -LiteralPath $bak -Destination $dst -Force
   }
 }
 throw $original
}
