param(
  [string]$RootPath = "$PSScriptRoot"
)

$ErrorActionPreference = 'Stop'

# Find latest JSON/CSV files in temp dir created by tests
$reportFiles = Get-ChildItem -Path $env:TEMP -Filter reporter_*.json,reporter_*.csv -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if (-not $reportFiles -or $reportFiles.Count -eq 0) {
  Write-Host "No reporter_* files found in TEMP. Set FAFAFA_KEEP_REPORT_FILES=1 to keep test outputs." -ForegroundColor Yellow
  exit 0
}

# Basic validators
function Test-JsonReport($file) {
  $text = Get-Content -Raw -Path $file
  $json = $null
  try { $json = $text | ConvertFrom-Json } catch { throw "Invalid JSON in $file: $_" }

  # Expect either a single object or an array; handle both
  if ($json -is [System.Array]) { $json = $json[0] }
  if ($null -eq $json) { throw "Empty JSON in $file" }

  if (-not $json.schema_version) { throw "schema_version missing in $file" }
  if (-not $json.name) { throw "name missing in $file" }
  if ($null -eq $json.iterations) { throw "iterations missing in $file" }
  if ($null -eq $json.total_time_ns) { throw "total_time_ns missing in $file" }
  if ($null -eq $json.time_per_iteration_ns) { throw "time_per_iteration_ns missing in $file" }
  if ($null -eq $json.throughput_per_sec) { throw "throughput_per_sec missing in $file" }
  if (-not $json.statistics) { throw "statistics missing in $file" }
  foreach ($f in 'mean','stddev','min','max','median','p95','p99','coefficient_of_variation','sample_count') {
    if ($null -eq $json.statistics.$f) { throw "statistics.$f missing in $file" }
  }
}

function Test-CsvReport($file) {
  $lines = Get-Content -Path $file
  $lines = $lines | Where-Object { $_ -ne '' }
  if ($lines.Count -lt 2) { throw "CSV needs at least header and one data line: $file" }
  $header = $lines[0]
  $data = $lines[1]

  # Expect TAB separated as per tests (sep=tab)
  if ($header -notmatch "\t") { throw "CSV header not TAB-separated: $file" }
  if ($data -notmatch "\t") { throw "CSV data not TAB-separated: $file" }

  $hCols = $header -split "\t"
  $dCols = $data -split "\t"
  if ($hCols.Count -ne $dCols.Count) { throw "CSV header/data columns mismatch: $file" }

  if ($header -notmatch 'SchemaVersion') { throw "CSV header missing SchemaVersion: $file" }
}

$errors = @()
foreach ($f in $reportFiles) {
  try {
    if ($f.Extension -eq '.json') { Test-JsonReport $f.FullName }
    elseif ($f.Extension -eq '.csv') { Test-CsvReport $f.FullName }
  } catch {
    $errors += $_.ToString()
  }
}

if ($errors.Count -gt 0) {
  Write-Host "Export validation failed:" -ForegroundColor Red
  $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  exit 1
}

Write-Host "Export validation passed." -ForegroundColor Green
exit 0

