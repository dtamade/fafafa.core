param(
  [string]$BaselinePath = "tests/fafafa.core.fs/performance-data/perf_resolve_baseline.txt",
  [string]$LatestPath   = "tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt",
  [int]$MaxRegressionPct = 25
)

function Get-ResolveCsvRow {
  param([string]$Text)
  $line = ($Text -split "\r?\n") | Where-Object { $_ -match '^CSV,ResolvePathEx,' } | Select-Object -First 1
  if (-not $line) { return $null }
  $parts = $line.Split(',')
  if ($parts.Length -lt 6) { return $null }
  return [PSCustomObject]@{
    Path   = $parts[2]
    Iters  = [int]$parts[3]
    DtFalse = [double]$parts[4]
    DtTrue  = [double]$parts[5]
  }
}

function Percent-Change { param([double]$baseline, [double]$latest)
  if ($baseline -le 0) { return $null }
  return (($latest - $baseline) / $baseline) * 100.0
}

if (!(Test-Path $LatestPath))   { Write-Error "Latest not found: $LatestPath"; exit 2 }
if (!(Test-Path $BaselinePath)) { Write-Error "Baseline not found: $BaselinePath"; exit 2 }

$baselineText = Get-Content -Raw -Path $BaselinePath -Encoding UTF8
$latestText   = Get-Content -Raw -Path $LatestPath   -Encoding UTF8

$B = Get-ResolveCsvRow -Text $baselineText
$L = Get-ResolveCsvRow -Text $latestText

if (-not $B -or -not $L) { Write-Error "Failed to parse CSV rows (CSV,ResolvePathEx,...)"; exit 3 }

$chgFalse = Percent-Change -baseline $B.DtFalse -latest $L.DtFalse
$chgTrue  = Percent-Change -baseline $B.DtTrue  -latest $L.DtTrue

$flag = 'OK'
if ($chgFalse -ne $null -and $chgFalse -gt $MaxRegressionPct) { $flag = 'REGRESSION' }
if ($chgTrue  -ne $null -and $chgTrue  -gt $MaxRegressionPct)  { $flag = 'REGRESSION' }

"Result: $flag; TouchDisk=False: latest=${($L.DtFalse)} ms (baseline=${($B.DtFalse)} ms, change={0:N1}%), TouchDisk=True: latest=${($L.DtTrue)} ms (baseline=${($B.DtTrue)} ms, change={1:N1}%)" -f ($chgFalse), ($chgTrue)

if ($flag -eq 'OK') { exit 0 } else { exit 1 }

