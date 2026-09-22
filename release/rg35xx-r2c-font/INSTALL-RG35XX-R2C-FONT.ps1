param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedR2ABase='5c1ac5ab9927fff29012366ac26cd756967858259116c654b529ebb501363913'
$NewRuntime='__R2C_FONT_RUNTIME_SHA256__'

function Fail([string]$m){throw "RG35XX R2C FONT INSTALL FAIL: $m"}
function Sha([string]$p){if(!(Test-Path -LiteralPath $p -PathType Leaf)){return $null};return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()}
function Ensure-Parent([string]$p){$d=Split-Path -Parent $p;if([string]::IsNullOrWhiteSpace($d)){return};if(Test-Path -LiteralPath $d -PathType Container){return};New-Item -ItemType Directory -Force -Path $d|Out-Null}
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

$Sd=Resolve-Sd $SdRoot
$Payload=Join-Path $PSScriptRoot 'payload\freej2me-lr.jar'
if((Sha $Payload) -ne $NewRuntime){Fail "payload hash mismatch actual=$(Sha $Payload)"}

$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
if((Sha $jamvm) -ne $ExpectedJamvm){Fail "JamVM mismatch actual=$(Sha $jamvm)"}
if((Sha $glibj) -ne $ExpectedGlibj){Fail "glibj mismatch actual=$(Sha $glibj)"}
if((Sha $core) -ne $ExpectedCore){Fail "core mismatch actual=$(Sha $core)"}

$targets=@(
 'BIOS\freej2me-lr.jar',
 'BIOS\freej2me_plus-lr.jar',
 'CFW\java\share\freej2me\freej2me-lr.jar',
 'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
 'CFW\retroarch\system\freej2me-lr.jar'
)
foreach($rel in $targets){
 $h=Sha (Join-Path $Sd $rel)
 if($h -ne $ExpectedR2ABase){Fail "R2A base mismatch at $rel actual=$h"}
}

$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $Sd "RG35XX-JAVA-BACKUP\r2c-font-$stamp"
New-Item -ItemType Directory -Force -Path $backup|Out-Null
foreach($rel in $targets){
 $src=Join-Path $Sd $rel;$dst=Join-Path $backup $rel
 Ensure-Parent $dst
 Copy-Item -LiteralPath $src -Destination $dst -Force
}
try {
 foreach($rel in $targets){
  $dst=Join-Path $Sd $rel;$tmp=$dst+'.r2cfont'
  if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force}
  Copy-Item -LiteralPath $Payload -Destination $tmp -Force
  if((Sha $tmp) -ne $NewRuntime){Fail "staged hash mismatch $rel"}
  Move-Item -LiteralPath $tmp -Destination $dst -Force
  if((Sha $dst) -ne $NewRuntime){Fail "installed hash mismatch $rel"}
 }
 foreach($n in @('freej2me-java-error.log','freej2me-vc3-early.log','freej2me-core.log','freej2me-java-control.log')){
  $p=Join-Path $Sd $n
  if(Test-Path -LiteralPath $p -PathType Leaf){Copy-Item -LiteralPath $p -Destination $backup -Force;Remove-Item -LiteralPath $p -Force}
 }
 @(
  'RG35XX CLEAN R2C FONT',
  'RESULT=PASS',
  "TIME=$((Get-Date).ToString('s'))",
  "BACKUP=$backup",
  "BASE_R2A_SHA256=$ExpectedR2ABase",
  "NEW_RUNTIME_SHA256=$NewRuntime",
  "CORE_SHA256=$ExpectedCore",
  'PRIMARY_VARIABLE=FONT_TEXT_RASTER_ONLY',
  'TRANSPARENCY_CHANGE=NONE',
  'AUDIO_CHANGE=NONE',
  'CANVAS_CHANGE=NONE',
  'STABLE=NO'
 )|Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-R2C-FONT-INSTALL-RESULT.txt') -Encoding ASCII
 Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-R2C-FONT-CURRENT-BACKUP.txt') -Value $backup -Encoding ASCII
 Write-Host 'INSTALL PASS - R2C FONT'
}
catch {
 $original=$_.Exception
 foreach($rel in $targets){
  $dst=Join-Path $Sd $rel;$bak=Join-Path $backup $rel
  if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue}
  if(Test-Path -LiteralPath $bak -PathType Leaf){Ensure-Parent $dst;Copy-Item -LiteralPath $bak -Destination $dst -Force}
 }
 throw $original
}
