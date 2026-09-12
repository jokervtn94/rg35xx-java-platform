param(
  [Parameter(Mandatory=$true)][string]$SdRoot,
  [Parameter(Mandatory=$true)][string]$RuntimePayload
)

$ErrorActionPreference = "Stop"
$Golden = "4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf"
$CN     = "9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40"
$Runtime = "cb8926539749535a53cb4a627e814e198aaa0eba3cce8cac1bb213957e37189b"

function Sha256([string]$p) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}

$SdRoot = [IO.Path]::GetFullPath($SdRoot)
if (!(Test-Path -LiteralPath $SdRoot)) { throw "SD root not found: $SdRoot" }
if (!(Test-Path -LiteralPath $RuntimePayload)) { throw "Missing VC7R22 runtime payload" }
if ((Sha256 $RuntimePayload) -ne $Runtime) { throw "VC7R22 runtime SHA mismatch" }

$coreTargets = @(
  (Join-Path $SdRoot "CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so"),
  (Join-Path $SdRoot "CFW\retroarch\.retroarch\cores\freej2me_libretro.so")
)
$runtimeTargets = @(
  (Join-Path $SdRoot "BIOS\freej2me-lr.jar"),
  (Join-Path $SdRoot "BIOS\freej2me_plus-lr.jar"),
  (Join-Path $SdRoot "CFW\java\freej2me-lr.jar"),
  (Join-Path $SdRoot "CFW\java\freej2me_plus-lr.jar")
)

$scanRoots = @(
  $SdRoot,
  (Join-Path $SdRoot "Java"),
  (Join-Path $SdRoot "RG35XX_Java_Backup"),
  (Join-Path $SdRoot "RG35XX_Java_Recovery_Snapshot")
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique

$foundCN = $null
$foundGolden = $null
foreach ($root in $scanRoots) {
  Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.so" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      $h = Sha256 $_.FullName
      if ($h -eq $CN -and !$foundCN) { $foundCN = $_.FullName }
      elseif ($h -eq $Golden -and !$foundGolden) { $foundGolden = $_.FullName }
    } catch {}
  }
  if ($foundCN) { break }
}

if (!$foundCN -and !$foundGolden) {
  Write-Host "VC7R22 AUDIO RESTORE: FAIL-CLOSED"
  Write-Host "No exact device-proven Golden/CN core was found on this SD."
  exit 22
}

$stage = Join-Path $env:TEMP ("rg35xx-vc7r22-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
$cnStage = Join-Path $stage "freej2me_plus_libretro.so"

if ($foundCN) {
  Copy-Item -LiteralPath $foundCN -Destination $cnStage -Force
} else {
  [byte[]]$b = [IO.File]::ReadAllBytes($foundGolden)
  $patches = @(
    @{ off = 0x11710; old = 0xE3A02A03; new = 0xE3A02B03 },
    @{ off = 0x1180C; old = 0x13A02A03; new = 0x13A02B03 },
    @{ off = 0x11824; old = 0xE3550A03; new = 0xE3550B03 }
  )
  foreach ($p in $patches) {
    if ($p.off + 4 -gt $b.Length) { throw ("Core too small for patch offset 0x{0:X}" -f $p.off) }
    $got = [BitConverter]::ToUInt32($b, $p.off)
    if ($got -ne [uint32]$p.old) {
      throw ("Golden core patch mismatch at 0x{0:X}: expected {1:X8}, got {2:X8}" -f $p.off,$p.old,$got)
    }
  }
  foreach ($p in $patches) {
    [byte[]]$w = [BitConverter]::GetBytes([uint32]$p.new)
    [Array]::Copy($w, 0, $b, $p.off, 4)
  }
  [IO.File]::WriteAllBytes($cnStage, $b)
}

if ((Sha256 $cnStage) -ne $CN) { throw "Recovered/patched core does not match exact CN SHA" }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $SdRoot ("Java\vc7r22-backup-" + $stamp)
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($t in $coreTargets + $runtimeTargets) {
  if (Test-Path -LiteralPath $t) {
    $name = ($t.Substring($SdRoot.Length).TrimStart('\') -replace '[\\/:*?"<>|]','_')
    Copy-Item -LiteralPath $t -Destination (Join-Path $backup $name) -Force
  }
}
foreach ($t in $coreTargets) {
  $d = Split-Path -Parent $t
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  Copy-Item -LiteralPath $cnStage -Destination $t -Force
  if ((Sha256 $t) -ne $CN) { throw "Installed core SHA mismatch: $t" }
}
foreach ($t in $runtimeTargets) {
  $d = Split-Path -Parent $t
  if (Test-Path -LiteralPath $d) {
    Copy-Item -LiteralPath $RuntimePayload -Destination $t -Force
    if ((Sha256 $t) -ne $Runtime) { throw "Installed runtime SHA mismatch: $t" }
  }
}

$result = Join-Path $SdRoot "Java\VC7R22-INSTALL-RESULT.txt"
@(
  "VC7R22 GOLDEN AUDIO WORKER-RING RESTORE"
  "RESULT=PASS"
  "CORE=CN DEVICE-PROVEN"
  "CORE_SHA256=$CN"
  "RUNTIME_SHA256=$Runtime"
  "MIDI_PRIME=3072"
  "GOLDEN_WORKER_RING=REQUIRED"
  "RING=16384"
  "WORKER_CHUNK=1470"
  "LAZY_MEDIA=KEEP"
  "MEDIA_WARMUP=OFF"
  "RETRO_RUN_AUDIO_PUMP=NOT_USED_BY_CN_CORE"
  "BACKUP=$backup"
) | Set-Content -LiteralPath $result -Encoding ASCII

Write-Host "VC7R22 INSTALL PASS"
Write-Host "Core SHA:    $CN"
Write-Host "Runtime SHA: $Runtime"
Write-Host "Backup:      $backup"
