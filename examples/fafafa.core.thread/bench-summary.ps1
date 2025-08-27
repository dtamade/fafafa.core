Param(
  [string]$InputCsv = "bench.csv",
  [string]$OutputCsv = "bench_summary.csv"
)

if (-not (Test-Path $InputCsv)) {
  Write-Error "Input CSV not found: $InputCsv"
  exit 1
}

$rows = Import-Csv -Path $InputCsv
$summary = @()
foreach ($r in $rows) {
  $title = $r.title
  $core = [int]$r.core
  $max = [int]$r.max
  $queue = [int]$r.queue
  $total = [int]$r.total
  $time_ms = [int]$r.time_ms
  $hit = [int]$r.hit
  $miss = [int]$r.miss
  $ret = [int]$r.ret
  $drop = [int]($r.drop)

  if ($ret -gt 0) {
    $hit_rate = [math]::Round(($hit / $ret), 4)
    $miss_rate = [math]::Round(($miss / $ret), 4)
  } else {
    $hit_rate = ''
    $miss_rate = ''
  }
  if ($total -gt 0 -and $time_ms -gt 0) {
    $time_per_k = [math]::Round(($time_ms / ($total / 1000.0)), 3)
  } else {
    $time_per_k = ''
  }

  $summary += [pscustomobject]@{
    title = $title
    core = $core
    max = $max
    queue = $queue
    total = $total
    time_ms = $time_ms
    hit = $hit
    miss = $miss
    ret = $ret
    drop = $drop
    hit_rate = $hit_rate
    miss_rate = $miss_rate
    time_per_k = $time_per_k
  }
}

$summary | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $OutputCsv"
