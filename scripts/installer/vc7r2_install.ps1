param(
    [Parameter(Mandatory=$true)][string]$SdInput
)
$ErrorActionPreference = 'Stop'
$ExpectedRuntimeSha = '8aca7ef0bb2909ca8e500d439359110b7d2199263c4fcef58814b22339aa4bbc'
$ExpectedFontSha = '20c2e59d063282d4b6a0d612dea3cba2c0b5bd7fafe85a05729951bd38902db9'
$ExpectedFontBytes = 727008
$ExpectedJamvmSha = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$ExpectedGlibjSha = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$ExpectedCoreSha = 'fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062'
$WritesStarted = $false
$Backup = $null
$BacklightUpdated = 0
function Sha256([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function Normalize-SdRoot([string]$Raw) {
    $s = $Raw.Trim().Trim('"').Trim("'")
    if($s -match '^[A-Za-z]$'){ $s = $s + ':' }
    if($s -match '^[A-Za-z]:\\?$'){ return ($s.Substring(0,2) + '\') }
    if(Test-Path -LiteralPath $s){ return ((Resolve-Path -LiteralPath $s).Path.TrimEnd('\') + '\') }
    throw "Invalid SD path: $Raw"
}
function Require-Hash([string]$Path, [string]$Expected, [string]$Label) {
    if(-not (Test-Path -LiteralPath $Path)){ throw "$Label missing: $Path" }
    $actual = Sha256 $Path
    if($actual -ne $Expected){ throw "$Label SHA mismatch. expected=$Expected actual=$actual path=$Path" }
    Write-Host "PASS $Label $actual"
}
$SdRoot = Normalize-SdRoot $SdInput
$Payload = Join-Path $PSScriptRoot 'payload\freej2me-lr-vc7r2.jar'
$Result = Join-Path $SdRoot 'RG35XX-VC7R2-INSTALL-RESULT.txt'
try {
    Write-Host 'RG35XX VC7R2 - Tasklog Proven View Installer'
    Write-Host "SD root: $SdRoot"
    Require-Hash $Payload $ExpectedRuntimeSha 'VC7R2 runtime payload'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Payload)
    try {
        $entry = $zip.GetEntry('org/recompile/mobile/rg35xx-font.bin')
        if($null -eq $entry){ throw 'VC7R2 font resource missing from payload JAR' }
        if($entry.Length -ne $ExpectedFontBytes){ throw "VC7R2 font size mismatch: $($entry.Length)" }
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('vc7r2-font-' + [Guid]::NewGuid().ToString('N') + '.bin')
        try { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$tmp,$true); Require-Hash $tmp $ExpectedFontSha 'VC7R2 reconstructed font' }
        finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    } finally { $zip.Dispose() }
    Require-Hash (Join-Path $SdRoot 'CFW\java\bin\jamvm') $ExpectedJamvmSha 'JamVM L'
    $glFound=$null
    foreach($g in @((Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'),(Join-Path $SdRoot 'CFW\java\share\jamvm\classes.zip'))){ if((Test-Path -LiteralPath $g) -and ((Sha256 $g) -eq $ExpectedGlibjSha)){ $glFound=$g; break } }
    if($null -eq $glFound){ throw 'Immutable GNU Classpath glibj.zip with admitted SHA was not found.' }
    Write-Host "PASS GNU Classpath immutable $ExpectedGlibjSha path=$glFound"
    $corePass=$false
    foreach($c in @((Join-Path $SdRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'),(Join-Path $SdRoot 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so'))){ if((Test-Path -LiteralPath $c) -and ((Sha256 $c) -eq $ExpectedCoreSha)){ Write-Host "PASS accepted RGB565/Smart-Fit native core $ExpectedCoreSha path=$c"; $corePass=$true } }
    if(-not $corePass){ throw 'Accepted VC6 RGB565/Smart-Fit native core was not found with required SHA.' }
    $targets=@('BIOS\freej2me-lr.jar','BIOS\freej2me_plus-lr.jar','CFW\java\share\freej2me\freej2me-lr.jar','CFW\retroarch\.retroarch\system\freej2me-lr.jar','CFW\retroarch\system\freej2me-lr.jar')
    foreach($rel in $targets){ if(-not(Test-Path -LiteralPath (Join-Path $SdRoot $rel))){ throw "Runtime target missing: $rel" } }
    $optionFiles=@(); $raRoot=Join-Path $SdRoot 'CFW\retroarch'
    if(Test-Path -LiteralPath $raRoot){ $optionFiles=@(Get-ChildItem -LiteralPath $raRoot -Filter 'retroarch-core-options.cfg' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -Unique) }
    $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $Backup=Join-Path $SdRoot ('RG35XX_VC7R2_Backup\'+$stamp); New-Item -ItemType Directory -Force -Path $Backup|Out-Null
    foreach($rel in $targets){ $src=Join-Path $SdRoot $rel; $dst=Join-Path $Backup $rel; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null; Copy-Item -LiteralPath $src -Destination $dst -Force; if((Sha256 $src) -ne (Sha256 $dst)){ throw "Backup verification failed: $rel" } }
    foreach($cfg in $optionFiles){ $relative=$cfg.Substring($SdRoot.Length); $dst=Join-Path $Backup $relative; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst)|Out-Null; Copy-Item -LiteralPath $cfg -Destination $dst -Force; if((Sha256 $cfg) -ne (Sha256 $dst)){ throw "Core-options backup verification failed: $relative" } }
    $WritesStarted=$true
    foreach($rel in $targets){ $dst=Join-Path $SdRoot $rel; Copy-Item -LiteralPath $Payload -Destination $dst -Force; Require-Hash $dst $ExpectedRuntimeSha ('installed runtime '+$rel) }
    foreach($cfg in $optionFiles){ $txt=[IO.File]::ReadAllText($cfg); $pattern='(?m)^\s*freej2me_backlightcolor\s*=\s*.*$'; if([Text.RegularExpressions.Regex]::IsMatch($txt,$pattern)){ $newTxt=[Text.RegularExpressions.Regex]::Replace($txt,$pattern,'freej2me_backlightcolor = "Disabled"'); if($newTxt -ne $txt){ [IO.File]::WriteAllText($cfg,$newTxt,(New-Object Text.UTF8Encoding($false))); $BacklightUpdated++; Write-Host "PASS backlight Disabled: $cfg" } } }
    @('RG35XX VC7R2 TASKLOG-PROVEN VIEW INSTALL','RESULT=PASS','STATUS=BUILD-PASS-DEVICE-TEST-PENDING',"RUNTIME_SHA256=$ExpectedRuntimeSha",'DYNAMIC_LOGICAL_VIEW=CQ_CR_BEHAVIOR_RECONSTRUCTED','CV_CW_BOOT_RESOLUTION=NOT_USED','RGB565_TRANSPORT=PRESERVED','NATIVE_SMART_FIT=PRESERVED',"NATIVE_CORE_SHA256=$ExpectedCoreSha", "FONT_SHA256=$ExpectedFontSha",'FONT_STATUS=RECONSTRUCTED-NOT-GOLDEN',"BACKLIGHT_OPTION_FILES_UPDATED=$BacklightUpdated",'RESOLUTION_CORE_OPTION=UNCHANGED',"BACKUP=$Backup",'JAMVM_L=PRESERVED','GLIBJ_IMMUTABLE=PRESERVED','DEVICE_TEST=PENDING') | Set-Content -LiteralPath $Result -Encoding UTF8
    Write-Host 'VC7R2 INSTALL PASS' -ForegroundColor Green; Write-Host "Result: $Result"; Write-Host "Backup: $Backup"
} catch {
    $msg=$_.Exception.Message; $lines=@('RG35XX VC7R2 TASKLOG-PROVEN VIEW INSTALL','RESULT=FAIL',('ERROR='+$msg),('WRITES_STARTED='+$(if($WritesStarted){'YES'}else{'NO'})),('BACKUP='+$(if($null-ne$Backup){$Backup}else{'NOT_CREATED'})),'DEVICE_TEST=PENDING'); if($WritesStarted){$lines+='WARNING=PARTIAL_INSTALL_POSSIBLE_USE_BACKUP_TO_RESTORE'}else{$lines+='SD_MODIFIED_BY_RUNTIME_INSTALL=NO'}; try{$lines|Set-Content -LiteralPath $Result -Encoding UTF8}catch{}; Write-Host ('VC7R2 INSTALL FAIL: '+$msg) -ForegroundColor Red; exit 1
}
