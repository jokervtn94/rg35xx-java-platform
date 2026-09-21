param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$ExpectedOldCore='56bb3b972337dd40b342c1881f6599c53eebf66a29f920a1aa2e2839eb29a07c'
$ExpectedR1Core='f6eb57bd38a021fd1ef1936293492ce21bb02dfc4d06a1a8f5cb7e47016310ca'
$ExpectedRuntime='4f1f126c2e02b4fbc3b8985d3afd0cbb239d35e0f97512a4eb85f25fcbacbc9c'

function Fail([string]$m){throw "RESTORE FAIL: $m"}
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
function Normalize-BackupCandidate([string]$candidate,[string]$sd){
 if([string]::IsNullOrWhiteSpace($candidate)){return $null}
 $candidate=$candidate.Trim().Trim('"')
 if(Test-Path -LiteralPath $candidate -PathType Container){return (Resolve-Path -LiteralPath $candidate).Path}

 # Installer report may contain a historical drive letter (for example H:) while
 # Windows mounted the same SD as another letter today. Rebase the path onto
 # the currently selected SD root.
 if($candidate -match '^[A-Za-z]:\\(.+)$'){
   $rebased=Join-Path $sd $Matches[1]
   if(Test-Path -LiteralPath $rebased -PathType Container){
     return (Resolve-Path -LiteralPath $rebased).Path
   }
 }
 return $null
}

$Sd=Resolve-Sd $SdRoot
$coreMain=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$coreAlias=Join-Path $Sd 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so'
$runtime=Join-Path $Sd 'BIOS\freej2me-lr.jar'

$actualCore=Sha $coreMain
$actualRuntime=Sha $runtime
if($actualRuntime -ne $ExpectedRuntime){
 Fail "Runtime is not B4-HOTPATH-R2. expected=$ExpectedRuntime actual=$actualRuntime"
}
if($actualCore -ne $ExpectedR1Core -and $actualCore -ne $ExpectedOldCore){
 Fail "Current core is neither Screenshot-R1 nor baseline. actual=$actualCore"
}
if($actualCore -eq $ExpectedOldCore){
 Write-Host 'RESTORE NOT NEEDED - baseline core is already installed'
 exit 0
}

$backup=$null
$source=$null

# 1) Preferred: explicit pointer written by installer.
$ptr=Join-Path $Sd 'RG35XX-B4-SCREENSHOT-R1-CURRENT-BACKUP.txt'
if(Test-Path -LiteralPath $ptr -PathType Leaf){
 $raw=(Get-Content -LiteralPath $ptr -Raw).Trim()
 $backup=Normalize-BackupCandidate $raw $Sd
 if($backup){$source='POINTER'}
}

# 2) Fallback: parse BACKUP= from the installer PASS report.
if(-not $backup){
 $report=Join-Path $Sd 'RG35XX-B4-SCREENSHOT-R1-INSTALL-RESULT.txt'
 if(Test-Path -LiteralPath $report -PathType Leaf){
   $line=Get-Content -LiteralPath $report | Where-Object {$_ -like 'BACKUP=*'} | Select-Object -First 1
   if($line){
     $raw=$line.Substring(7)
     $backup=Normalize-BackupCandidate $raw $Sd
     if($backup){$source='INSTALL_REPORT'}
   }
 }
}

# 3) Last fail-closed fallback: newest matching backup folder that contains STATE.txt.
if(-not $backup){
 $root=Join-Path $Sd 'RG35XX-JAVA-BACKUP'
 if(Test-Path -LiteralPath $root -PathType Container){
   $candidates=Get-ChildItem -LiteralPath $root -Directory -Filter 'b4-screenshot-r1-*' |
     Sort-Object Name -Descending
   foreach($dir in $candidates){
     if(Test-Path -LiteralPath (Join-Path $dir.FullName 'STATE.txt') -PathType Leaf){
       $backup=$dir.FullName
       $source='BACKUP_SCAN'
       break
     }
   }
 }
}

if(-not $backup){
 Fail 'No valid Screenshot-R1 backup found via pointer, install report, or backup scan'
}

$state=Join-Path $backup 'STATE.txt'
if(!(Test-Path -LiteralPath $state -PathType Leaf)){Fail "STATE missing: $state"}

$backupCore=Join-Path $backup 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$backupHash=Sha $backupCore
if($backupHash -ne $ExpectedOldCore){
 Fail "Backup core hash mismatch. expected=$ExpectedOldCore actual=$backupHash backup=$backup"
}

Write-Host "RESTORE SOURCE=$source"
Write-Host "RESTORE BACKUP=$backup"
Write-Host "BACKUP CORE SHA256=$backupHash"

foreach($line in Get-Content -LiteralPath $state){
 $p=$line.Split('|',2)
 if($p.Count -ne 2){continue}
 $kind=$p[0]
 $rel=$p[1]
 $dst=Join-Path $Sd $rel
 $bak=Join-Path $backup $rel

 if($kind -ne 'EXISTED'){Fail "Unexpected STATE entry: $line"}
 if(!(Test-Path -LiteralPath $bak -PathType Leaf)){Fail "Backup file missing: $bak"}

 if(Test-Path -LiteralPath $dst){Remove-Item -LiteralPath $dst -Force}
 New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null
 Copy-Item -LiteralPath $bak -Destination $dst -Force
}

$after=Sha $coreMain
if($after -ne $ExpectedOldCore){
 Fail "Post-restore main core mismatch expected=$ExpectedOldCore actual=$after"
}
if(Test-Path -LiteralPath $coreAlias -PathType Leaf){
 $aliasAfter=Sha $coreAlias
 if($aliasAfter -ne $ExpectedOldCore){
   Fail "Post-restore alias core mismatch expected=$ExpectedOldCore actual=$aliasAfter"
 }
}

@(
 'CHECKPOINT=B4-SCREENSHOT-R1-ROLLBACK-AB',
 'RESULT=PASS',
 "TIME=$((Get-Date).ToString('s'))",
 "RESTORE_SOURCE=$source",
 "BACKUP=$backup",
 "RESTORED_CORE_SHA256=$after",
 "RUNTIME_SHA256=$actualRuntime",
 'SCREENSHOT_R1_CORE_PRESENT=NO',
 'BASELINE_CORE_RESTORED=YES',
 'STABLE=NO'
)|Set-Content -LiteralPath (Join-Path $Sd 'RG35XX-B4-SCREENSHOT-R1-ROLLBACK-RESULT.txt') -Encoding ASCII

Write-Host 'RESTORE PASS'
Write-Host "Core restored: $after"
Write-Host "Runtime kept:  $actualRuntime"
