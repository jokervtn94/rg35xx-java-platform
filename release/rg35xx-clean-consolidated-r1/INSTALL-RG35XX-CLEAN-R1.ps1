param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$NewRuntime='__NEW_RUNTIME_SHA256__'

function Fail([string]$m){throw "RG35XX CLEAN R1 INSTALL FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null}; return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
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
$Payload=Join-Path $PSScriptRoot 'payload\freej2me-lr.jar'
$payloadSha=Sha $Payload
if($payloadSha -ne $NewRuntime){Fail "Payload runtime hash mismatch expected=$NewRuntime actual=$payloadSha"}

$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$current=Join-Path $Sd 'BIOS\freej2me-lr.jar'

if((Sha $jamvm) -ne $ExpectedJamvm){Fail "JamVM L precondition failed actual=$(Sha $jamvm)"}
if((Sha $glibj) -ne $ExpectedGlibj){Fail "glibj precondition failed actual=$(Sha $glibj)"}
if((Sha $core) -ne $ExpectedCore){Fail "protected B4 core precondition failed actual=$(Sha $core)"}

$oldRuntime=Sha $current
if($null -eq $oldRuntime){Fail 'Canonical BIOS runtime missing'}

$targets=@(
 'BIOS\freej2me-lr.jar',
 'BIOS\freej2me_plus-lr.jar',
 'CFW\java\share\freej2me\freej2me-lr.jar',
 'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
 'CFW\retroarch\system\freej2me-lr.jar'
)

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\clean-consolidated-r1-$stamp"
New-Item -ItemType Directory -Force -Path $backup|Out-Null
$state=@()

foreach($rel in $targets){
 $src=Join-Path $Sd $rel
 if(Test-Path -LiteralPath $src -PathType Leaf){
   $dst=Join-Path $backup $rel
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
   Copy-Item -LiteralPath $src -Destination $dst -Force
   $state+="EXISTED|$rel|$(Sha $src)"
 } else {
   $state+="ABSENT|$rel|"
 }
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
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
   $tmp=$dst+'.cleanr1new'
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

 $report=Join-Path $Sd 'RG35XX-CLEAN-CONSOLIDATED-R1-INSTALL-RESULT.txt'
 @(
  'RG35XX CLEAN CONSOLIDATED R1',
  'RESULT=PASS',
  'STATUS=BUILD-PASS_INSTALLED_DEVICE-TEST-PENDING',
  "TIME=$((Get-Date).ToString('s'))",
  "BACKUP=$backup",
  "OLD_RUNTIME_SHA256=$oldRuntime",
  "NEW_RUNTIME_SHA256=$NewRuntime",
  "CORE_SHA256=$ExpectedCore",
  "JAMVM_SHA256=$ExpectedJamvm",
  "GLIBJ_SHA256=$ExpectedGlibj",
  'VIDEO_MASK_R2=ENABLED_DEVICE_PASS_SCOPED',
  'HOTPATH_R2=ENABLED_DEVICE_PASS_SCOPED',
  'PNG_ICCP=ENABLED_DEVICE_EXERCISED',
  'DYNAMIC_LOGICAL_VIEW=ENABLED_DEVICE_PROVEN_SCOPED',
  'CANONICAL_FRAMEBUFFER_BINDING=ENABLED',
  'LEGACY_HELPER_GRAPH=NOT_ADMITTED',
  'AUDIO_RECONSTRUCTION=NOT_ADMITTED',
  'FONT_EXPERIMENT=NOT_ADMITTED',
  'NATIVE_CORE_CHANGE=NONE',
  'FULL_PLATFORM_STABLE=NO'
 )|Set-Content -LiteralPath $report -Encoding ASCII

 Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-CLEAN-CONSOLIDATED-R1-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - RG35XX CLEAN CONSOLIDATED R1'
 Write-Host "OLD_RUNTIME_SHA256=$oldRuntime"
 Write-Host "NEW_RUNTIME_SHA256=$NewRuntime"
}
catch {
 foreach($line in Get-Content -LiteralPath (Join-Path $backup 'STATE.txt')){
   $p=$line.Split('|'); if($p.Count -lt 2){continue}
   $kind=$p[0];$rel=$p[1];$dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel
   if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue}
   if($kind -eq 'EXISTED' -and (Test-Path -LiteralPath $bak -PathType Leaf)){
     New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
     Copy-Item -LiteralPath $bak -Destination $dst -Force
   }
 }
 throw
}
