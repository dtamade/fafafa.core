param(
  [Parameter(Mandatory=$true)] [string]$DefaultCsv,
  [Parameter(Mandatory=$true)] [string]$AggressiveCsv,
  [string]$Out = "bench_compare.csv",
  [string]$Model,
  [string]$WaitPolicy,
  [int]$Cap,
  [int]$Batch,
  [double]$NsPerOpRatioMin,
  [double]$OpsPerMsRatioMin,
  [ValidateSet('default','ns_ratio','ops_ratio')][string]$Sort = 'default'
)

function Convert-ToDoubleInvariant([string]$s) {
  if ([string]::IsNullOrEmpty($s)) { return [double]0 }
  $s2 = $s -replace ',', '.'
  return [double]$s2
}

Write-Host "Loading CSV..."
$def = Import-Csv -Path $DefaultCsv
$agg = Import-Csv -Path $AggressiveCsv

# Build index for Aggressive by (name|model|wait_policy|cap|batch)
$idx = @{}
foreach ($r in $agg) {
  $key = "{0}|{1}|{2}|{3}|{4}" -f $r.name,$r.model,$r.wait_policy,$r.cap,$r.batch
  $idx[$key] = $r
}

# Optional filters
if ($Model) { $def = $def | Where-Object { $_.model -eq $Model } }
if ($WaitPolicy) { $def = $def | Where-Object { $_.wait_policy -eq $WaitPolicy } }
if ($PSBoundParameters.ContainsKey('Cap')) { $def = $def | Where-Object { [int]$_.cap -eq $Cap } }
if ($PSBoundParameters.ContainsKey('Batch')) { $def = $def | Where-Object { [int]$_.batch -eq $Batch } }

$result = @()
foreach ($d in $def) {
  $key = "{0}|{1}|{2}|{3}|{4}" -f $d.name,$d.model,$d.wait_policy,$d.cap,$d.batch
  if (-not $idx.ContainsKey($key)) { continue }
  $a = $idx[$key]

  $d_ns = Convert-ToDoubleInvariant $d.ns_per_op_avg
  $a_ns = Convert-ToDoubleInvariant $a.ns_per_op_avg
  $d_ops = Convert-ToDoubleInvariant $d.ops_per_ms
  $a_ops = Convert-ToDoubleInvariant $a.ops_per_ms

  $ns_delta = $a_ns - $d_ns
  $ns_ratio = if ($d_ns -ne 0) { $a_ns / $d_ns } else { [double]::NaN }
  $ops_delta = $a_ops - $d_ops
  $ops_ratio = if ($d_ops -ne 0) { $a_ops / $d_ops } else { [double]::NaN }

  $outObj = [PSCustomObject]@{
    name          = $d.name
    model         = $d.model
    wait_policy   = $d.wait_policy
    cap           = $d.cap
    batch         = $d.batch
    N             = $d.N

    default_ns_per_op = $d_ns
    aggressive_ns_per_op = $a_ns
    ns_per_op_delta = $ns_delta
    ns_per_op_ratio = $ns_ratio

    default_ops_per_ms = $d_ops
    aggressive_ops_per_ms = $a_ops
    ops_per_ms_delta = $ops_delta
    ops_per_ms_ratio = $ops_ratio

    default_backoff = $d.backoff
    aggressive_backoff = $a.backoff

    host_default   = $d.host
    host_aggressive = $a.host
    run_id_default = $d.run_id
    run_id_aggressive = $a.run_id
    commit_default = $d.commit
    commit_aggressive = $a.commit

    p50_ms_default = $d.p50_ms
    p50_ms_aggressive = $a.p50_ms
    p90_ms_default = $d.p90_ms
    p90_ms_aggressive = $a.p90_ms
    p95_ms_default = $d.p95_ms
    p95_ms_aggressive = $a.p95_ms
    p99_ms_default = $d.p99_ms
    p99_ms_aggressive = $a.p99_ms

    file_default  = $DefaultCsv
    file_aggressive = $AggressiveCsv
  }
  $result += $outObj
}

# Optional threshold filters
if ($PSBoundParameters.ContainsKey('NsPerOpRatioMin')) { $result = $result | Where-Object { $_.ns_per_op_ratio -ge $NsPerOpRatioMin } }
if ($PSBoundParameters.ContainsKey('OpsPerMsRatioMin')) { $result = $result | Where-Object { $_.ops_per_ms_ratio -ge $OpsPerMsRatioMin } }

# Sorting
switch ($Sort) {
  'ns_ratio'  { $result = $result | Sort-Object -Property ns_per_op_ratio -Descending }
  'ops_ratio' { $result = $result | Sort-Object -Property ops_per_ms_ratio -Descending }
  default     { $result = $result | Sort-Object model, wait_policy, cap, batch, name }
}

$result | Export-Csv -Path $Out -NoTypeInformation -Encoding UTF8
Write-Host "Done. Wrote" (Resolve-Path $Out)

