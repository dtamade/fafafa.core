param(
  [int[]]$Threads = @(1,2,4,8),
  [int[]]$QueueCaps = @(64,256,1024,-1),
  [int[]]$TaskMs = @(0,1,2,5),
  [int]$Tasks = 50000,
  [int]$Loops = 3,
  [string]$Csv = "bench.csv"
)

$ErrorActionPreference = "Stop"

lazbuild benchmarks/fafafa.core.thread/queue_bench.lpr

foreach ($t in $Threads) {
  foreach ($q in $QueueCaps) {
    foreach ($m in $TaskMs) {
      $env:BENCH_THREADS = $t
      $env:BENCH_QUEUE_CAP = $q
      $env:BENCH_TASKS = $Tasks
      $env:BENCH_LOOPS = $Loops
      $env:BENCH_TASK_MS = $m
      $env:BENCH_CSV = $Csv
      Write-Host "Running t=$t q=$q ms=$m ..."
      benchmarks\fafafa.core.thread\queue_bench.exe | Out-Host
    }
  }
}

