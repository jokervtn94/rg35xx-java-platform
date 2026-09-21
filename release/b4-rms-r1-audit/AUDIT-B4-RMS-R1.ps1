param([Parameter(Mandatory=$false, Position=0)][string]$SdRoot)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function Fail([string]$m){ throw "B4-RMS-R1 AUDIT FAIL: $m" }

function Resolve-Sd([string]$raw){
    if([string]::IsNullOrWhiteSpace($raw)){ $raw=Read-Host 'Nhap ky tu o SD RG35XX (vi du H)' }
    $raw=$raw.Trim().Trim('"')
    if($raw -match '^[A-Za-z]$'){ $raw=$raw+':' }
    if($raw -match '^[A-Za-z]:$'){ $raw=$raw+'\' }
    if(!(Test-Path -LiteralPath $raw -PathType Container)){ Fail "SD root not found: $raw" }
    $resolved=(Resolve-Path -LiteralPath $raw).Path
    $trim=$resolved.TrimEnd('\')
    if($trim.Length -ne 2 -or $trim[1] -ne ':'){ Fail "Refusing non-drive-root path: $resolved" }
    return $trim+'\'
}

function Sha([string]$p){
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}

function LastNonWhitespaceByte([byte[]]$bytes){
    for($i=$bytes.Length-1; $i -ge 0; $i--){
        $b=$bytes[$i]
        if($b -ne 0x20 -and $b -ne 0x09 -and $b -ne 0x0A -and $b -ne 0x0D){ return [int]$b }
    }
    return -1
}

$Sd=Resolve-Sd $SdRoot
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $PSScriptRoot ("B4-RMS-R1-AUDIT-EVIDENCE-"+$stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null

# Read-only discovery. Do not create/delete/rename anything on the SD.
$rmsRoots=@()
$freej2meDirs=@(Get-ChildItem -LiteralPath $Sd -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ieq 'freej2me' })

foreach($d in $freej2meDirs){
    $candidate=Join-Path $d.FullName 'rms'
    if(Test-Path -LiteralPath $candidate -PathType Container){
        $rmsRoots += (Resolve-Path -LiteralPath $candidate).Path
    }
}

$rmsRoots=@($rmsRoots | Sort-Object -Unique)

$rows=@()
$suspicious=@()
$totalMeta=0
$totalPayload=0

foreach($root in $rmsRoots){
    $metaFiles=@(Get-ChildItem -LiteralPath $root -File -Filter '*.rms' -Recurse -ErrorAction SilentlyContinue)
    foreach($f in $metaFiles){
        $totalMeta++
        [byte[]]$bytes=[System.IO.File]::ReadAllBytes($f.FullName)
        $len=$bytes.Length
        $first= if($len -gt 0){ [int]$bytes[0] } else { -1 }
        $last=LastNonWhitespaceByte $bytes
        $outerBraces=($len -ge 2 -and $first -eq 0x7B -and $last -eq 0x7D)

        $base=[System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        $payloads=@(Get-ChildItem -LiteralPath $f.DirectoryName -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like ($base+'.*') -and $_.Name -ne $f.Name })
        $payloadCount=@($payloads).Count
        $totalPayload += $payloadCount

        $reason=@()
        if($len -eq 0){ $reason += 'ZERO_LENGTH' }
        elseif($len -lt 2){ $reason += 'TOO_SHORT_FOR_OUTER_BRACES' }
        if(!$outerBraces){ $reason += 'OUTER_BRACES_INVALID' }

        $isSuspicious=(@($reason).Count -gt 0)
        $rel=$f.FullName.Substring($Sd.Length)
        $suiteRel=$f.DirectoryName.Substring($Sd.Length)

        $row=[PSCustomObject]@{
            RMSRoot=$root.Substring($Sd.Length)
            SuiteDirectory=$suiteRel
            MetadataFile=$rel
            Length=$len
            SHA256=Sha $f.FullName
            FirstByteHex= if($first -ge 0){ ('0x{0:X2}' -f $first) } else { 'NONE' }
            LastNonWhitespaceByteHex= if($last -ge 0){ ('0x{0:X2}' -f $last) } else { 'NONE' }
            OuterBracesValid=$outerBraces
            PayloadFileCount=$payloadCount
            Suspicious=$isSuspicious
            Reason=($reason -join ';')
        }
        $rows += $row
        if($isSuspicious){ $suspicious += $row }
    }
}

$csv=Join-Path $out 'RMS-METADATA-AUDIT.csv'
$rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8

$summary=@(
    'CHECKPOINT=B4-RMS-R1-AUDIT',
    'MODE=READ_ONLY',
    "TIME=$((Get-Date).ToString('s'))",
    "SD=$Sd",
    "RMS_ROOT_COUNT=$(@($rmsRoots).Count)",
    "RMS_METADATA_COUNT=$totalMeta",
    "RMS_PAYLOAD_COUNT=$totalPayload",
    "SUSPICIOUS_METADATA_COUNT=$(@($suspicious).Count)",
    'RULE_ZERO_LENGTH=metadata file length 0',
    'RULE_TOO_SHORT=metadata file length less than 2',
    'RULE_BRACES=first byte must be { and last non-whitespace byte must be }',
    'SOURCE_FAILURE=RecordStore.loadRecordStore calls jsonString.substring(1,jsonString.length()-1) before length validation',
    'SD_MUTATION=NONE',
    'STABLE=NO'
)

if(@($rmsRoots).Count -eq 0){
    $summary += 'AUDIT_RESULT=NO_RMS_ROOT_FOUND'
} elseif($totalMeta -eq 0){
    $summary += 'AUDIT_RESULT=RMS_ROOT_FOUND_NO_METADATA'
} elseif(@($suspicious).Count -eq 0){
    $summary += 'AUDIT_RESULT=NO_STRUCTURALLY_SHORT_OR_UNBRACED_METADATA_FOUND'
} else {
    $summary += 'AUDIT_RESULT=SUSPICIOUS_METADATA_FOUND'
}

$summary | Set-Content -LiteralPath (Join-Path $out 'RMS-AUDIT-SUMMARY.txt') -Encoding ASCII

$rmsRoots | ForEach-Object { $_.Substring($Sd.Length) } |
    Set-Content -LiteralPath (Join-Path $out 'RMS-ROOTS.txt') -Encoding UTF8

if(@($suspicious).Count -gt 0){
    $suspicious |
      Select-Object SuiteDirectory,MetadataFile,Length,SHA256,FirstByteHex,LastNonWhitespaceByteHex,OuterBracesValid,PayloadFileCount,Reason |
      Export-Csv -LiteralPath (Join-Path $out 'RMS-SUSPICIOUS.csv') -NoTypeInformation -Encoding UTF8
} else {
    'NONE' | Set-Content -LiteralPath (Join-Path $out 'RMS-SUSPICIOUS.txt') -Encoding ASCII
}

# Preserve current platform hashes for correlation, still read-only.
$hashLines=@()
foreach($rel in @(
    'CFW\java\bin\jamvm',
    'CFW\java\share\classpath\glibj.zip',
    'CFW\retroarch\.retroarch\cores\freej2me_plus_libretro.so',
    'CFW\retroarch\.retroarch\cores\freej2me_libretro.so',
    'BIOS\freej2me-lr.jar'
)){
    $p=Join-Path $Sd $rel
    if(Test-Path -LiteralPath $p -PathType Leaf){
        $hashLines += ($rel+'='+(Sha $p))
    }
}
$hashLines | Set-Content -LiteralPath (Join-Path $out 'DEVICE-HASHES.txt') -Encoding ASCII

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out+'.zip') -Force
Write-Host "RMS AUDIT PASS: $out.zip"
Write-Host "RMS roots: $(@($rmsRoots).Count)"
Write-Host "Metadata files: $totalMeta"
Write-Host "Suspicious metadata: $(@($suspicious).Count)"
