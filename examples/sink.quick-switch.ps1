# PowerShell: Quick switch sinks for runner/benchmark
# Usage:
#   examples\sink.quick-switch.ps1 -target runner -sink console|json|junit [-outfile out\report.json]
#   examples\sink.quick-switch.ps1 -target bench  -sink console|json      [-outfile out\bench.json]
#   examples\sink.quick-switch.ps1 -target thread  # runs thread examples (BuildOrRun.bat run)

param(
  [ValidateSet('runner','bench','thread')][string]$target = 'runner',
  [ValidateSet('console','json','junit')][string]$sink = 'console',
  [string]$outfile = ''
)

if ($target -eq 'runner') {
  if ($sink -eq 'console') {
    $env:FAFAFA_TEST_USE_SINK_CONSOLE = '1'
    & tests\fafafa.core.test\bin\tests.exe --summary-only
  } elseif ($sink -eq 'json') {
    $env:FAFAFA_TEST_USE_SINK_JSON = '1'
    if (-not $outfile) { $outfile = 'out\report.json' }
    & tests\fafafa.core.test\bin\tests.exe --json=$outfile --no-console
  } elseif ($sink -eq 'junit') {
    $env:FAFAFA_TEST_USE_SINK_JUNIT = '1'
    if (-not $outfile) { $outfile = 'out\report.xml' }
    & tests\fafafa.core.test\bin\tests.exe --junit=$outfile --no-console
  }
}
elseif ($target -eq 'bench') {
  if ($sink -eq 'console') {
    $env:FAFAFA_BENCH_USE_SINK_CONSOLE = '1'
    & tests\fafafa.core.benchmark\bin\tests_benchmark.exe --report=console
  } elseif ($sink -eq 'json') {
    $env:FAFAFA_BENCH_USE_SINK_JSON = '1'
    if (-not $outfile) { $outfile = 'out\bench.json' }
    & tests\fafafa.core.benchmark\bin\tests_benchmark.exe --report=json --outfile=$outfile
  } else {
    Write-Error 'bench target supports console/json only'
    exit 1
  }
elseif ($target -eq 'thread') {
  Push-Location examples\fafafa.core.thread
  & .\BuildOrRun.bat run
  Pop-Location
}

}

