param(
  [Parameter(Mandatory=$true)] [string]$CsvPath
)

if (!(Test-Path $CsvPath)) {
  Write-Error "CSV not found: $CsvPath"
  exit 1
}

$rows = Import-Csv -Path $CsvPath

# Cast numeric fields
$rows | ForEach-Object {
  $_.capacity = [int]$_.capacity
  $_.producers = [int]$_.producers
  $_.consumers = [int]$_.consumers
  $_.duration_ms = [int]$_.duration_ms
  $_.ops = [int64]$_.ops
  $_.ops_per_sec = [double]$_.ops_per_sec
  $_.run = [int]$_.run
}

# Group and compute averages (mean) and median
$groups = $rows | Group-Object algo, mode, capacity, producers, consumers

$summary = foreach ($g in $groups) {
  $opsps = $g.Group | Select-Object -ExpandProperty ops_per_sec
  $mean = [Math]::Round(($opsps | Measure-Object -Average).Average, 0)
  $sorted = $opsps | Sort-Object
  $n = $sorted.Count
  if ($n -gt 0) {
    if ($n % 2 -eq 1) { $median = $sorted[([int]($n/2))] } else { $median = ($sorted[($n/2)-1] + $sorted[($n/2)]) / 2 }
  } else { $median = 0 }
  [pscustomobject]@{
    algo = $g.Group[0].algo
    mode = $g.Group[0].mode
    capacity = $g.Group[0].capacity
    producers = $g.Group[0].producers
    consumers = $g.Group[0].consumers
    runs = $n
    opsps_mean = $mean
    opsps_median = [Math]::Round($median, 0)
  }
}

$summary | Sort-Object algo, mode, capacity, producers, consumers | Format-Table -AutoSize

