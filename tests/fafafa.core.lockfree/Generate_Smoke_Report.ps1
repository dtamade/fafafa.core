# Generate Smoke RingBuffer Report from CSV
param(
    [string]$CsvPath = "logs\smoke_ringbuffer_times.csv",
    [string]$ReportPath = "logs\report_smoke_ringbuffer.md",
    [int]$RecentN = 10
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvFile = Join-Path $scriptDir $CsvPath
$reportFile = Join-Path $scriptDir $ReportPath

if (!(Test-Path $csvFile)) {
    Write-Host "[warn] CSV not found: $csvFile"
    "# RingBuffer Smoke Report`n`nNo data available. Run smoke tests with SMOKE_TIMER=1 first." | Set-Content -LiteralPath $reportFile
    exit 0
}

$data = Import-Csv -LiteralPath $csvFile
if ($data.Count -eq 0) {
    "# RingBuffer Smoke Report`n`nCSV exists but no data rows." | Set-Content -LiteralPath $reportFile
    exit 0
}

$recent = $data | Select-Object -Last $RecentN
$totalRuns = $data.Count
$recentCount = $recent.Count

# Calculate stats
$avgOpsPerSec = ($recent | Measure-Object -Property ops_per_sec -Average).Average
$medianOpsPerSec = ($recent | Sort-Object { [int]$_.ops_per_sec } | Select-Object -Index ([math]::Floor($recentCount / 2))).ops_per_sec
$minOpsPerSec = ($recent | Measure-Object -Property ops_per_sec -Minimum).Minimum
$maxOpsPerSec = ($recent | Measure-Object -Property ops_per_sec -Maximum).Maximum

$avgMs = ($recent | Measure-Object -Property ms -Average).Average
$avgOps = ($recent | Measure-Object -Property ops -Average).Average

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Generate report
$report = @"
# RingBuffer Smoke Performance Report

**Generated:** $timestamp  
**Total Runs:** $totalRuns  
**Recent Runs Analyzed:** $recentCount (last $RecentN)

## Performance Summary (Recent $RecentN runs)

| Metric | Value |
|--------|-------|
| Average ops/sec | $([math]::Round($avgOpsPerSec, 0)) |
| Median ops/sec | $medianOpsPerSec |
| Min ops/sec | $minOpsPerSec |
| Max ops/sec | $maxOpsPerSec |
| Average operations | $([math]::Round($avgOps, 0)) |
| Average time (ms) | $([math]::Round($avgMs, 1)) |

## Recent Test Results

| Timestamp | Operations | Time (ms) | ops/sec |
|-----------|------------|-----------|---------|
"@

foreach ($row in $recent) {
    $report += "`n| $($row.timestamp) | $($row.ops) | $($row.ms) | $($row.ops_per_sec) |"
}

$report += @"


## Usage

To add more data points:
``````
set SMOKE_TIMER=1 && set SMOKE_OPS=200000 && BuildOrTest.bat minimal
Summarize_Smoke_Queues.bat
``````

CSV data: ``$csvFile``
"@

$report | Set-Content -LiteralPath $reportFile -Encoding UTF8
Write-Host "[report] Generated: $reportFile"
