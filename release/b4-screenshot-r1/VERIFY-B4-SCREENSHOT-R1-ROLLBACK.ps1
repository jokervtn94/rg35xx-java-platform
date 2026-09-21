param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedJamvm='eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibj='d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedRuntime='4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c'
$ExpectedCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$RejectedR1Core='f6eb57bd38a021fd1ef1936293492ce21bb02dfc4d06a1a8f5cb7e47016310ca'

function Fail([string]$m){throw "B4-SCREENSHOT-R1 ROLLBACK VERIFY FAIL: $m"}
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
$jamvm=Join-Path $Sd 'CFW\java\bin\jamvm'
$glibj=Join-Path $Sd 'CFW\java\share\classpath\glibj.zip'
$runtime=Join-Path $Sd 'BIOS\freej2me-lr.jar'
$core=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$alias=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so'

$actualJamvm=Sha $jamvm
$actualGlibj=Sha $glibj
$actualRuntime=Sha $runtime
$actualCore=Sha $core
$actualAlias=Sha $alias

if($actualJamvm -ne $ExpectedJamvm){Fail "JamVM mismatch actual=$actualJamvm"}
if($actualGlibj -ne $ExpectedGlibj){Fail "glibj mismatch actual=$actualGlibj"}
if($actualRuntime -ne $ExpectedRuntime){Fail "runtime mismatch actual=$actualRuntime"}
if($actualCore -eq $RejectedR1Core){Fail 'Screenshot R1 core is still installed; run RESTORE-B4-SCREENSHOT-R1.cmd first'}
if($actualCore -ne $ExpectedCore){Fail "baseline core mismatch actual=$actualCore"}
if($actualAlias -and $actualAlias -ne $ExpectedCore){Fail "core alias mismatch actual=$actualAlias"}

$report=Join-Path $Sd 'RG35XX-B4-SCREENSHOT-R1-ROLLBACK-VERIFY.txt'
@(
 'CHECKPOINT=B4-SCREENSHOT-R1-ROLLBACK-AB',
 'RESULT=PASS',
 "TIME=$((Get-Date).ToString('s'))",
 "JAMVM_SHA256=$actualJamvm",
 "GLIBJ_SHA256=$actualGlibj",
 "RUNTIME_SHA256=$actualRuntime",
 "CORE_SHA256=$actualCore",
 "CORE_ALIAS_SHA256=$actualAlias",
 'SCREENSHOT_R1_CORE_PRESENT=NO',
 'BASELINE_CORE_RESTORED=YES',
 'NEXT_TEST_1=dragon-mania-s40v6',
 'NEXT_TEST_2=NinjaSchool1',
 'NO_CODE_CHANGE=YES',
 'STABLE=NO'
)|Set-Content -LiteralPath $report -Encoding ASCII

Write-Host 'ROLLBACK VERIFY PASS'
Write-Host "Core restored: $actualCore"
Write-Host "Runtime kept:  $actualRuntime"
