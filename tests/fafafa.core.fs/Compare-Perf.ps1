param(
  [string]$BaselinePath = "tests/fafafa.core.fs/performance-data/baseline.txt",
  [string]$LatestPath   = "tests/fafafa.core.fs/performance-data/latest.txt"
)

function Parse-RangeLine {
  param([string]$Line, [string]$Unit)
  # expects like: "Sequential write: 364-366 MB/s"
  if ($Line -match "([0-9]+)\s*-\s*([0-9]+)\s+$Unit") {
    return [PSCustomObject]@{ Min = [int]$Matches[1]; Max = [int]$Matches[2] }
  }
  return $null
}

function Parse-ValueLine {
  param([string]$Line, [string]$Unit)
  # expects like: "Sequential write: 64 MB in 175 ms, 365 MB/s"
  if ($Line -match "([0-9]+)\s+$Unit") {
    return [int]$Matches[1]
  }
  return $null
}

if (!(Test-Path $BaselinePath)) { Write-Error "Baseline not found: $BaselinePath"; exit 2 }
if (!(Test-Path $LatestPath))   { Write-Error "Latest not found: $LatestPath"; exit 2 }

$baseline = Get-Content -Raw -Path $BaselinePath -Encoding UTF8
$latest   = Get-Content -Raw -Path $LatestPath   -Encoding UTF8

# Extract ranges from baseline
$bwRange = Parse-RangeLine -Line ($baseline -split "\r?\n" | Where-Object { $_ -match '^Sequential write:' } | Select-Object -First 1) -Unit "MB/s"
$brRange = Parse-RangeLine -Line ($baseline -split "\r?\n" | Where-Object { $_ -match '^Sequential read:'  } | Select-Object -First 1) -Unit "MB/s"
$rrRange = Parse-RangeLine -Line ($baseline -split "\r?\n" | Where-Object { $_ -match '^Random read:'     } | Select-Object -First 1) -Unit "ops/s"

if (-not $bwRange -or -not $brRange -or -not $rrRange) { Write-Error "Failed to parse baseline ranges"; exit 3 }

# Extract values from latest
$writeVal = Parse-ValueLine -Line ($latest -split "\r?\n" | Where-Object { $_ -match '^Sequential write:' } | Select-Object -First 1) -Unit "MB/s"
$readVal  = Parse-ValueLine -Line ($latest -split "\r?\n" | Where-Object { $_ -match '^Sequential read:'  } | Select-Object -First 1) -Unit "MB/s"
$randVal  = Parse-ValueLine -Line ($latest -split "\r?\n" | Where-Object { $_ -match '^Random read:'     } | Select-Object -First 1) -Unit "ops/s"

if ($null -eq $writeVal -or $null -eq $readVal -or $null -eq $randVal) { Write-Error "Failed to parse latest values"; exit 4 }

function Compare-ValRange {
  param([int]$Val, [int]$Min, [int]$Max)
  if ($Val -gt $Max) { return 'HIGH' }
  if ($Val -lt $Min) { return 'LOW' }
  return 'SAME'
}

$w = Compare-ValRange -Val $writeVal -Min $bwRange.Min -Max $bwRange.Max
$r = Compare-ValRange -Val $readVal  -Min $brRange.Min -Max $brRange.Max
$z = Compare-ValRange -Val $randVal  -Min $rrRange.Min -Max $rrRange.Max

"Result: write=$w (latest=$writeVal, baseline=$($bwRange.Min)-$($bwRange.Max) MB/s); read=$r (latest=$readVal, baseline=$($brRange.Min)-$($brRange.Max) MB/s); random=$z (latest=$randVal, baseline=$($rrRange.Min)-$($rrRange.Max) ops/s)"

