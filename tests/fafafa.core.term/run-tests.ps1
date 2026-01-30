#requires -Version 5.1
param([switch]$Rebuild)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure UTF-8 output (no BOM)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$scriptDir = Split-Path -Parent $PSCommandPath
Set-Location $scriptDir

$exePath = Join-Path $scriptDir 'bin/fafafa.core.term.test.exe'
$resultsDir = Join-Path $scriptDir 'bin/test-results'

if (-not (Test-Path -LiteralPath $resultsDir)) {
  New-Item -ItemType Directory -Path $resultsDir | Out-Null
}

$buildBat = Join-Path $scriptDir 'BuildOrTest.bat'

function Invoke-Build {
  if (-not (Test-Path -LiteralPath $buildBat)) {
    Write-Error "Build script not found: $buildBat"
    exit 1
  }
  & $buildBat | Tee-Object -FilePath (Join-Path $resultsDir ("build-" + (Get-Date).ToString('yyyyMMdd-HHmmss') + '.txt'))
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}

# Build if binary missing or sources/tests newer or -Rebuild
$needBuild = $Rebuild.IsPresent -or (-not (Test-Path -LiteralPath $exePath))
if (-not $needBuild) {
  $exeTime = (Get-Item -LiteralPath $exePath).LastWriteTime
  $latestSrc = Get-ChildItem -Recurse -File -Include *.pas,*.lpr,*.lpi |
               Where-Object { $_.FullName -notmatch "\\bin\\|\\lib\\" } |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1
  if ($latestSrc -and ($latestSrc.LastWriteTime -gt $exeTime)) { $needBuild = $true }
}

if ($needBuild) {
  Write-Host '[run-tests] Rebuilding (clean + build-all)...'
  & $buildBat rebuild | Tee-Object -FilePath (Join-Path $resultsDir ("rebuild-" + (Get-Date).ToString('yyyyMMdd-HHmmss') + '.txt'))
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Rebuild failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logPath = Join-Path $resultsDir ("run-" + $stamp + '.txt')

$quiet = $env:FAFAFA_TEST_QUIET -eq '1'
$args = @('--all','--summary')
if ($quiet) { $args += '--quiet' }

Write-Host ("[run-tests] Running: " + $exePath + ' ' + ($args -join ' '))

# Capture output and preserve exit code, then tee to file
$output = & $exePath @args 2>&1
$exitCode = $LASTEXITCODE

# Write to console and file (PS 5.1 Tee-Object has no -Encoding)
$output | Tee-Object -FilePath $logPath | Out-Host

# Emit a short summary footer
Write-Host "[run-tests] ExitCode: $exitCode"
Write-Host "[run-tests] Log: $logPath"

exit $exitCode

