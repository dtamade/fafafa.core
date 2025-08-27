#requires -version 3.0
Param(
  [string]$LazbuildPath
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Join-Path $root 'fafafa.core.json/tests_json.lpi'
$exe  = Join-Path $root 'fafafa.core.json/bin/tests_json.exe'

if (-not (Test-Path $proj)) {
  Write-Error "[ERROR] Project file not found: $proj"
}

if (-not $LazbuildPath) {
  try {
    $LazbuildPath = (Get-Command lazbuild -ErrorAction Stop).Source
  } catch {
    $candidates = @(
      'C:\Program Files\Lazarus\lazbuild.exe',
      'C:\Lazarus\lazbuild.exe'
    )
    foreach ($c in $candidates) { if (Test-Path $c) { $LazbuildPath = $c; break } }
  }
}

if (-not $LazbuildPath) {
  Write-Error '[ERROR] lazbuild not found in PATH or default locations. Provide -LazbuildPath or install Lazarus.'
}

Write-Host "[INFO] Using lazbuild: $LazbuildPath"
& "$LazbuildPath" "$proj"

if (Test-Path $exe) {
  Write-Host "[INFO] Running: $exe"
  & "$exe"
} else {
  # Try platform-agnostic fallback
  $exe2 = (Join-Path $root 'fafafa.core.json/bin/tests_json')
  if (Test-Path $exe2) { & "$exe2" } else { Write-Warning "Build finished, but test binary not found: $exe / $exe2" }
}

