param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [Parameter(Mandatory=$true)][string]$Suite,
  [Parameter(Mandatory=$true)][int]$TimeoutSec,
  [Parameter(Mandatory=$true)][string]$OutDir
)

$ErrorActionPreference = 'Stop'

function Invoke-Proc {
  param([string]$File, [object]$ArgList, [string]$StdOutPath, [string]$StdErrPath, [int]$TimeoutSec)
  # Ensure ArgList is a non-empty array of strings
  if ($null -eq $ArgList) { $ArgList = @() }
  if ($ArgList -is [string]) { $ArgList = @($ArgList) }
  $ArgList = @($ArgList | ForEach-Object { if ($_ -ne $null) { $_.ToString() } })
  if ($ArgList.Count -eq 0) { throw "ArgumentList is empty" }
  $p = Start-Process -FilePath $File -ArgumentList $ArgList -PassThru -NoNewWindow -RedirectStandardOutput $StdOutPath -RedirectStandardError $StdErrPath
  if (-not $p.WaitForExit($TimeoutSec * 1000)) {
    try { $p.Kill() } catch {}
    return 124
  }
  return $p.ExitCode
}

# Ensure output directory exists
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$plainOut = Join-Path $OutDir ("suite_${Suite}.txt")
$plainErr = Join-Path $OutDir ("suite_${Suite}.err")
$sumPath  = Join-Path $OutDir ("suite_${Suite}.summary")
$jsonPath = Join-Path $OutDir ("suite_${Suite}.json")

$script:sumTests = 'n/a'
$script:sumFailures = 'n/a'
$script:sumErrors = 'n/a'

function Parse-Counts {
  param([string]$log)
  try {
    # Prefer embedded XML extraction if present
    $xmlMatch = [regex]::Match($log, '(?s)<\?xml.*?<TestResults>.*?</TestResults>')
    if ($xmlMatch.Success) {
      try {
        [xml]$doc = $xmlMatch.Value
        $node = $null
        if ($doc.TestResults.TestListing.TestSuite -and $doc.TestResults.TestListing.TestSuite.TestSuite) {
          $node = @($doc.TestResults.TestListing.TestSuite.TestSuite) | Where-Object { $_.Name -eq $Suite } | Select-Object -First 1
        }
        if (-not $node -and $doc.TestResults.TestListing.TestSuite) {
          # maybe top-level aggregate
          $node = $doc.TestResults.TestListing.TestSuite
        }
        if ($node -and $node.NumberOfRunTests) { $script:sumTests = [string]$node.NumberOfRunTests }
        if ($node -and $node.NumberOfFailures) { $script:sumFailures = [string]$node.NumberOfFailures }
        if ($node -and $node.NumberOfErrors) { $script:sumErrors = [string]$node.NumberOfErrors }
        return
      } catch {}
    }
    # Fallback: text patterns
    $m = [regex]::Match($log, 'tests\s*=\s*(\d+)[^\r\n]*failures\s*=\s*(\d+)[^\r\n]*errors\s*=\s*(\d+)', 'IgnoreCase')
    if ($m.Success) { $script:sumTests=$m.Groups[1].Value; $script:sumFailures=$m.Groups[2].Value; $script:sumErrors=$m.Groups[3].Value; return }
    $m = [regex]::Match($log, 'Failures\s*[:=]\s*(\d+)[^\r\n]*Errors\s*[:=]\s*(\d+)', 'IgnoreCase')
    if ($m.Success) { $script:sumFailures=$m.Groups[1].Value; $script:sumErrors=$m.Groups[2].Value }
    $m = [regex]::Match($log, 'Errors\s*[:=]\s*(\d+)[^\r\n]*Failures\s*[:=]\s*(\d+)', 'IgnoreCase')
    if ($m.Success) { $script:sumErrors=$m.Groups[1].Value; $script:sumFailures=$m.Groups[2].Value }
    $m = [regex]::Match($log, '(Total\s+tests|Ran)\s*[:=]?\s*(\d+)', 'IgnoreCase')
    if ($m.Success) { $script:sumTests=$m.Groups[2].Value }
    $m = [regex]::Match($log, '失败\s*[:=]\s*(\d+)', 'IgnoreCase')
    if ($m.Success) { $script:sumFailures=$m.Groups[1].Value }
    $m = [regex]::Match($log, '错误\s*[:=]\s*(\d+)', 'IgnoreCase')
    if ($m.Success) { $script:sumErrors=$m.Groups[1].Value }
  } catch {}
}

function Write-Summary {
  param([string]$Status, [int]$Rc, [string]$Note)
  try {
    $lines = @(
      "suite=$Suite",
      "status=$Status",
      "rc=$Rc",
      "note=$Note",
      "tests=$script:sumTests",
      "failures=$script:sumFailures",
      "errors=$script:sumErrors"
    )
    Set-Content -LiteralPath $sumPath -Value $lines -Encoding UTF8
    $payload = [ordered]@{
      suite=$Suite; status=$Status; rc=$Rc; note=$Note;
      tests=$script:sumTests; failures=$script:sumFailures; errors=$script:sumErrors
    }
    ($payload | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $jsonPath -Encoding UTF8
  } catch {}
}

# 0) Precheck: ensure suite exists via --list (best-effort, isolated)
try {
  $listOut = Join-Path $OutDir ("list_${Suite}.txt")
  $p = Start-Process -FilePath $Exe -ArgumentList @("--list") -PassThru -NoNewWindow -RedirectStandardOutput $listOut -RedirectStandardError $listOut
  if (-not $p.WaitForExit(10000)) { try { $p.Kill() } catch {} }
  if (Test-Path -LiteralPath $listOut) {
    $list = Get-Content -LiteralPath $listOut -Raw -ErrorAction SilentlyContinue
    if (-not ($list -match [regex]::Escape($Suite))) {
      Write-Output "SUITE NOT FOUND in --list: $Suite"
      exit 6
    }
  }
} catch {
  # ignore precheck errors; main checks will catch problems
}

# 1) XML run to capture counts (best-effort)
$xmlOut = Join-Path $OutDir ("suite_${Suite}.xml")
$xmlErr = Join-Path $OutDir ("suite_${Suite}.xml.err")
if (Test-Path -LiteralPath $xmlOut) { try { Remove-Item -LiteralPath $xmlOut -Force -ErrorAction SilentlyContinue } catch {} }
if (Test-Path -LiteralPath $xmlErr) { try { Remove-Item -LiteralPath $xmlErr -Force -ErrorAction SilentlyContinue } catch {} }

$xmlAttempts = @()
$xmlAttempts += ,@("--format=xml")

foreach ($xmlArgs in $xmlAttempts) {
  $rcXml = [int](Invoke-Proc -File $Exe -ArgList $xmlArgs -StdOutPath $xmlOut -StdErrPath $xmlErr -TimeoutSec $TimeoutSec)
  if ($rcXml -eq 124) { break } # timeout will be handled in plain run
  if ($rcXml -ne 0) { continue }
  try {
    if (Test-Path -LiteralPath $xmlOut) {
      $raw = Get-Content -LiteralPath $xmlOut -Raw -ErrorAction Stop
      $m = [regex]::Match($raw, '(?s)<\?xml.*?<TestResults>.*?</TestResults>')
      if ($m.Success) { [xml]$doc = $m.Value } else { [xml]$doc = $raw }
      $node = $null
      if ($doc.TestResults.TestListing.TestSuite -and $doc.TestResults.TestListing.TestSuite.TestSuite) {
        $node = @($doc.TestResults.TestListing.TestSuite.TestSuite) | Where-Object { $_.Name -eq $Suite } | Select-Object -First 1
      }
      if (-not $node -and $doc.TestResults.TestListing.TestSuite) {
        $node = $doc.TestResults.TestListing.TestSuite
      }
      if ($node) {
        if ($node.NumberOfRunTests) { $script:sumTests = [string]$node.NumberOfRunTests }
        if ($node.NumberOfFailures) { $script:sumFailures = [string]$node.NumberOfFailures }
        if ($node.NumberOfErrors) { $script:sumErrors = [string]$node.NumberOfErrors }
      }
      break
    }
  } catch { }
}

# Fallback: try global results.xml if present
try {
  $globalXml = Join-Path $OutDir ("results.xml")
  if ((-not ($script:sumTests -match '^\d+$')) -and (Test-Path -LiteralPath $globalXml)) {
    $rawG = Get-Content -LiteralPath $globalXml -Raw -ErrorAction Stop
    $mG = [regex]::Match($rawG, '(?s)<\?xml.*?<TestResults>.*?</TestResults>')
    if ($mG.Success) { [xml]$docG = $mG.Value } else { [xml]$docG = $rawG }
    $nodeG = $null
    if ($docG.TestResults.TestListing.TestSuite -and $docG.TestResults.TestListing.TestSuite.TestSuite) {
      $nodeG = @($docG.TestResults.TestListing.TestSuite.TestSuite) | Where-Object { $_.Name -eq $Suite } | Select-Object -First 1
    }
    if ($nodeG) {
      if ($nodeG.NumberOfRunTests) { $script:sumTests = [string]$nodeG.NumberOfRunTests }
      if ($nodeG.NumberOfFailures) { $script:sumFailures = [string]$nodeG.NumberOfFailures }
      if ($nodeG.NumberOfErrors) { $script:sumErrors = [string]$nodeG.NumberOfErrors }
    }
  }
} catch {}

# 2) Plain run only（多种参数格式重试，作为判定标准）
$attempts = @()
$attempts += ,@("--only-suite=$Suite", "--progress", "--format=plain")
$attempts += ,@("--only-suite", $Suite, "--progress", "--format=plain")
$attempts += ,@("--suite=$Suite", "--progress", "--format=plain")
$attempts += ,@("--suite", $Suite, "--progress", "--format=plain")
$attempts += ,@("-s=$Suite", "--progress", "--format=plain")
$hadNoSelected = $false
foreach ($plainArgs in $attempts) {
  $rc = [int](Invoke-Proc -File $Exe -ArgList $plainArgs -StdOutPath $plainOut -StdErrPath $plainErr -TimeoutSec $TimeoutSec)
  if ($rc -eq 124) { Write-Output "TIMEOUT"; Write-Summary -Status "TIMEOUT" -Rc 124 -Note "timeout"; exit 124 }
  if ($rc -ne 0)   { Write-Output "FAIL rc=$rc"; Write-Summary -Status "FAIL" -Rc $rc -Note "process rc"; exit $rc }
  try {
    $log = Get-Content -LiteralPath $plainOut -Raw -ErrorAction Stop
    Parse-Counts -log $log
    if ($log -match "No tests selected") { $hadNoSelected = $true; continue }
    if ($log -match "(Failures|失败).*?[1-9]" -or $log -match "(Errors|错误).*?[1-9]") { Write-Output "FAIL: summary"; Write-Summary -Status "FAIL" -Rc 2 -Note "summary indicates failure"; exit 2 }
    Write-Summary -Status "PASS" -Rc 0 -Note "ok"; exit 0
  } catch {
    # 读取失败尝试下一种参数样式
    continue
  }
}
if ($hadNoSelected) { Write-Output "FAIL: no tests selected"; Write-Summary -Status "FAIL" -Rc 6 -Note "no tests selected"; exit 6 }
Write-Output "LOG read error after retries"; Write-Summary -Status "FAIL" -Rc 7 -Note "log read error after retries"; exit 7

