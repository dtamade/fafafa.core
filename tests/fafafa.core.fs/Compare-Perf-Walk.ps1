param(
  [string]$Latest = "tests/fafafa.core.fs/performance-data/latest.txt",
  [string]$Baseline = "tests/fafafa.core.fs/performance-data/baseline.txt"
)

function Get-LatestMetrics([string]$text) {
  $m = [regex]::Match($text, 'Walk entries:\s*(\d+)\s*,\s*time:\s*(\d+)\s*ms', 'IgnoreCase')
  if ($m.Success) {
    return @{ Entries = [int]$m.Groups[1].Value; TimeMs = [int]$m.Groups[2].Value }
  }
  return $null
}

function Get-BaselineRange([string]$text) {
  $m = [regex]::Match($text, 'Entries:\s*~?(\d+)-(\d+)\s*,\s*Time:\s*~?(\d+)-(\d+)\s*ms', 'IgnoreCase')
  if ($m.Success) {
    return @{ EntriesMin = [int]$m.Groups[1].Value; EntriesMax = [int]$m.Groups[2].Value; TimeMin = [int]$m.Groups[3].Value; TimeMax = [int]$m.Groups[4].Value }
  }
  return $null
}

$latestText = Get-Content -Raw -ErrorAction SilentlyContinue $Latest
$baseText   = Get-Content -Raw -ErrorAction SilentlyContinue $Baseline

if (-not $latestText) { Write-Error "Latest file not found: $Latest"; exit 1 }
if (-not $baseText)   { Write-Error "Baseline file not found: $Baseline"; exit 1 }

$latest = Get-LatestMetrics $latestText
$base   = Get-BaselineRange $baseText

if (-not $latest -or -not $base) {
  Write-Host "Compare-Perf-Walk: Could not parse inputs."
  Write-Host "Latest  sample snippet (expected): Walk entries: 211, time: 427 ms"
  Write-Host "Baseline snippet (expected): Entries: ~200-250, Time: ~350-500 ms"
  exit 0
}

$inEntries = ($latest.Entries -ge $base.EntriesMin) -and ($latest.Entries -le $base.EntriesMax)
$inTime    = ($latest.TimeMs    -ge $base.TimeMin)    -and ($latest.TimeMs    -le $base.TimeMax)

if ($inEntries -and $inTime) {
  Write-Host "OK: Walk snapshot within baseline. Entries=$($latest.Entries) Time=$($latest.TimeMs)ms"
  exit 0
}

Write-Host "WARN: Walk snapshot out of baseline. Entries=$($latest.Entries) Time=$($latest.TimeMs)ms; Baseline Entries=$($base.EntriesMin)-$($base.EntriesMax) Time=$($base.TimeMin)-$($base.TimeMax)ms"
exit 0

