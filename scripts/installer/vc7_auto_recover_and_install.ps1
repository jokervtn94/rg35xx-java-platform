param(
    [Parameter(Mandatory=$true)][string]$SdRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$TemplateSha = '7aacea52397a084e9bef249541e6f60a263b3773ebe35148e0b66481e23d8b1f'
$GoldenJarSha = 'de510e978ee0b601ac25c496197197676f86725662c434316825e00a86b497b8'
$FontSha = '7d835faaed37ae93d2bb783604453ad8d13d994f1c97074182ec040c6a29b99c'
$FontSize = 727008
$FontEntry = 'org/recompile/mobile/rg35xx-font.bin'
$JamvmSha = 'eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34'
$GlibjSha = 'd7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea'
$CoreSha = 'fc574021ad34b0466cd7ffe4f2eb58438eb2104c47cc503405d9f8722c02d062'

function Fail([string]$Message) { throw "VC7 INSTALL FAIL: $Message" }
function Sha256([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function RequireFile([string]$Path,[string]$Label) {
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ Fail "$Label missing: $Path" }
}
function AssertSha([string]$Path,[string]$Expected,[string]$Label) {
    $actual = Sha256 $Path
    if($actual -ne $Expected){ Fail "$Label SHA mismatch expected=$Expected actual=$actual path=$Path" }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$SdRoot = (Resolve-Path -LiteralPath $SdRoot).Path.TrimEnd('\')
$TemplateRuntime = Join-Path $PSScriptRoot 'payload\freej2me-lr-vc7-template.jar'
RequireFile $TemplateRuntime 'VC7 template runtime'
AssertSha $TemplateRuntime $TemplateSha 'VC7 template runtime'

$jamvm = Join-Path $SdRoot 'CFW\java\bin\jamvm'
$glibj = Join-Path $SdRoot 'CFW\java\share\classpath\glibj.zip'
$core1 = Join-Path $SdRoot 'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so'
$core2 = Join-Path $SdRoot 'CFW\retroarch\.retroarch\cores\freej2me_libretro.so'
RequireFile $jamvm 'JamVM L'
RequireFile $glibj 'GNU Classpath'
RequireFile $core1 'VC6 core plus'
RequireFile $core2 'VC6 core alias'
AssertSha $jamvm $JamvmSha 'JamVM L'
AssertSha $glibj $GlibjSha 'GNU Classpath'
AssertSha $core1 $CoreSha 'VC6 core plus'
AssertSha $core2 $CoreSha 'VC6 core alias'

$targets = @(
    'BIOS\freej2me-lr.jar',
    'BIOS\freej2me_plus-lr.jar',
    'CFW\java\share\freej2me\freej2me-lr.jar',
    'CFW\retroarch\.retroarch\system\freej2me-lr.jar',
    'CFW\retroarch\system\freej2me-lr.jar'
)
foreach($rel in $targets){ RequireFile (Join-Path $SdRoot $rel) "runtime target $rel" }

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('rg35xx-vc7-auto-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null

try {
    $fontPath = Join-Path $tmpRoot 'rg35xx-font.bin'
    $foundJar = $null
    $foundJarSha = $null

    Write-Host ''
    Write-Host 'VC7: searching automatically for the exact Golden font resource...'
    Write-Host "  Installer folder: $PSScriptRoot"
    Write-Host "  SD card:          $SdRoot"
    Write-Host ''

    $seen = @{}
    $roots = @($PSScriptRoot, $SdRoot)
    foreach($root in $roots){
        if($foundJar){ break }
        $jars = Get-ChildItem -LiteralPath $root -Filter '*.jar' -File -Recurse -ErrorAction SilentlyContinue
        foreach($jar in $jars){
            if($foundJar){ break }
            $full = $jar.FullName
            if($seen.ContainsKey($full)){ continue }
            $seen[$full] = $true
            if($full -eq (Resolve-Path -LiteralPath $TemplateRuntime).Path){ continue }

            $z = $null
            try {
                $z = [System.IO.Compression.ZipFile]::OpenRead($full)
                $entries = @($z.Entries | Where-Object { $_.FullName -eq $FontEntry })
                if($entries.Count -ne 1){ continue }
                if($entries[0].Length -ne $FontSize){ continue }
                if(Test-Path -LiteralPath $fontPath){ Remove-Item -LiteralPath $fontPath -Force }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], $fontPath, $true)
                if((Sha256 $fontPath) -eq $FontSha){
                    $foundJar = $full
                    $foundJarSha = Sha256 $full
                    break
                }
            } catch {
            } finally {
                if($z){ $z.Dispose() }
            }
        }
    }

    if(-not $foundJar){
        $result = Join-Path $SdRoot 'RG35XX-VC7-AUTO-RECOVERY-RESULT.txt'
        @(
            'RG35XX VC7 Auto Recovery Installer',
            ('Time=' + (Get-Date).ToString('o')),
            'RESULT=NO-GOLDEN-FONT-FOUND',
            ('RequiredFontSHA256=' + $FontSha),
            ('RequiredFontSize=' + $FontSize),
            'SD_MODIFIED=NO',
            'NOTE=No JAR in installer folder or SD/backups contained the exact Golden font resource.'
        ) | Set-Content -LiteralPath $result -Encoding UTF8
        Fail "exact Golden font was not found automatically. SD was NOT modified. Result: $result"
    }

    Write-Host "VC7: exact Golden font recovered from: $foundJar"
    Write-Host "Source JAR SHA256=$foundJarSha"
    if($foundJarSha -eq $GoldenJarSha){
        Write-Host 'Source identity: exact original Golden runtime.'
    } else {
        Write-Host 'Source identity: later/backup runtime carrying the exact Golden font resource.'
    }

    if((Get-Item -LiteralPath $fontPath).Length -ne $FontSize){ Fail 'recovered font size mismatch' }
    AssertSha $fontPath $FontSha 'Recovered Golden font'

    $templateZip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $TemplateRuntime).Path)
    try {
        if(-not ($templateZip.Entries | Where-Object { $_.FullName -eq 'org/recompile/mobile/PlatformGraphics.class' })){
            Fail 'VC7 template has no PlatformGraphics.class'
        }
        if($templateZip.Entries | Where-Object { $_.FullName -eq $FontEntry }){
            Fail 'VC7 template unexpectedly already contains Golden font resource'
        }
    } finally { $templateZip.Dispose() }

    $OutputRuntime = Join-Path $tmpRoot 'freej2me-lr-vc7.jar'
    Copy-Item -LiteralPath $TemplateRuntime -Destination $OutputRuntime -Force

    $outZip = [System.IO.Compression.ZipFile]::Open($OutputRuntime,[System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $entry = $outZip.CreateEntry($FontEntry,[System.IO.Compression.CompressionLevel]::Optimal)
        $dst = $entry.Open()
        $src = [System.IO.File]::OpenRead($fontPath)
        try { $src.CopyTo($dst) } finally { $src.Dispose(); $dst.Dispose() }
    } finally { $outZip.Dispose() }

    $verifyFont = Join-Path $tmpRoot 'verify-font.bin'
    $finalZip = [System.IO.Compression.ZipFile]::OpenRead($OutputRuntime)
    try {
        $entries = @($finalZip.Entries | Where-Object { $_.FullName -eq $FontEntry })
        if($entries.Count -ne 1){ Fail "materialized runtime contains $($entries.Count) font entries" }
        if($entries[0].Length -ne $FontSize){ Fail 'materialized font size mismatch' }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0],$verifyFont,$true)
    } finally { $finalZip.Dispose() }
    AssertSha $verifyFont $FontSha 'Materialized embedded font'
    $runtimeSha = Sha256 $OutputRuntime

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $SdRoot ("RG35XX_VC7_Backup\" + $stamp)
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    foreach($rel in $targets){
        $src = Join-Path $SdRoot $rel
        $dst = Join-Path $backup $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }

    foreach($rel in $targets){
        $dst = Join-Path $SdRoot $rel
        Copy-Item -LiteralPath $OutputRuntime -Destination $dst -Force
        if((Sha256 $dst) -ne $runtimeSha){ Fail "post-copy runtime mismatch: $rel" }
    }

    $result = Join-Path $SdRoot 'RG35XX-VERIFIED-CLEAN-VC7-INSTALL-RESULT.txt'
    @(
        'RG35XX Verified Clean VC7 Golden Unicode Font Runtime',
        ('Time=' + (Get-Date).ToString('o')),
        ('RecoveredFontSource=' + $foundJar),
        ('RecoveredFontSourceJarSHA256=' + $foundJarSha),
        ('GoldenFontSHA256=' + $FontSha),
        ('GoldenFontSize=' + $FontSize),
        ('VC7RuntimeSHA256=' + $runtimeSha),
        ('VC6CoreSHA256=' + $CoreSha),
        ('JamVMLSHA256=' + $JamvmSha),
        ('GlibjSHA256=' + $GlibjSha),
        ('Backup=' + $backup),
        'CORE_CHANGED=NO',
        'GLIBJ_CHANGED=NO',
        'JAMVM_CHANGED=NO',
        'VC7_FONT_RESOURCE=EXACT_GOLDEN',
        'RESULT=PASS'
    ) | Set-Content -LiteralPath $result -Encoding UTF8

    Write-Host ''
    Write-Host 'VC7 INSTALL: PASS'
    Write-Host "VC7 runtime SHA256=$runtimeSha"
    Write-Host "Backup=$backup"
    Write-Host "Result=$result"
} finally {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}
