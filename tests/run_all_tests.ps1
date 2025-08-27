param(
  [string[]]$Allow = @('fafafa.core.collections.arr','fafafa.core.collections.base','fafafa.core.collections.vec','fafafa.core.collections.vecdeque'),
  [switch]$StopOnFail,
  [switch]$VerboseLogs
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testsRoot = $scriptRoot
$logDir = Join-Path $testsRoot '_run_all_logs_ps'
$summaryFile = Join-Path $testsRoot 'run_all_tests_summary_ps.txt'

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$modules = @()
$total = 0
$passed = 0
$failed = 0
$failedList = @()

function Write-Head([string]$s) {
  Write-Host ('=' * 40)
  Write-Host $s
  Write-Host ('=' * 40)
}

function Invoke-One([string]$scriptPath) {
  $moduleName = Split-Path (Split-Path $scriptPath -Parent) -Leaf
  if ($Allow.Count -gt 0 -and ($Allow -notcontains $moduleName)) {
    return
  }
  $logFile = Join-Path $logDir ("$moduleName.log")
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  "========================================`nModule: $moduleName`nScript: $scriptPath`nStarted: $ts`n========================================" | Out-File -FilePath $logFile -Encoding UTF8
  $global:LASTEXITCODE = 0

  $total = $script:total + 1; $script:total = $total

  Push-Location (Split-Path $scriptPath -Parent)
  try {
    # Call batch script via cmd, redirect stdout/stderr inside cmd to avoid NativeCommandError
    $oldPref = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $escapedScript = '"' + ($scriptPath -replace '"','""') + '"'
    $escapedLog = '"' + ($logFile -replace '"','""') + '"'
    $cmdLine = "call $escapedScript 1>> $escapedLog 2>>&1"
    & cmd.exe /c $cmdLine
    $rc = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $oldPref
    Pop-Location
  }

  if ($rc -eq 0) {
    $script:passed++
    Write-Host "[PASS] $moduleName (rc=$rc)" -ForegroundColor Green
  } else {
    $script:failed++
    Write-Host "[FAIL] $moduleName (rc=$rc)" -ForegroundColor Red
    $script:failedList += $moduleName
    if ($VerboseLogs) { Write-Head "Tail of $moduleName.log"; Get-Content $logFile -Tail 60 }
    if ($StopOnFail) { throw "StopOnFail enabled. Stopping at $moduleName (rc=$rc)." }
  }
}

Write-Head "Running all module test scripts under: $testsRoot"
"Logs: $logDir" | Tee-Object -Variable _ | Out-Null; Write-Host "Logs: $logDir"

# Sweep BuildOrTest.bat first, then BuildAndTest.bat
Get-ChildItem -Path $testsRoot -Recurse -Filter 'BuildOrTest.bat' | ForEach-Object { Invoke-One $_.FullName }
Get-ChildItem -Path $testsRoot -Recurse -Filter 'BuildAndTest.bat' | ForEach-Object { Invoke-One $_.FullName }

# Write summary
$summary = @()
$summary += '========================================'
$summary += "Run-all summary ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
$summary += "Logs dir: $logDir"
$summary += '========================================'
$summary += "Total:  $total"
$summary += "Passed: $passed"
$summary += "Failed: $failed"
if ($failedList.Count -gt 0) { $summary += 'Failed modules: ' + ($failedList -join ',') }
$summary | Out-File -FilePath $summaryFile -Encoding UTF8

$summary | ForEach-Object { Write-Host $_ }

if ($failed -gt 0) { exit 1 } else { exit 0 }

