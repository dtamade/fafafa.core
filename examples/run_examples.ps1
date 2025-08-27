#requires -version 3.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$example = Join-Path $root 'fafafa.core.json/example_forin_and_ptr_best_practices.lpr'
$exe = Join-Path $root 'fafafa.core.json/example_forin_and_ptr_best_practices.exe'

try { $lazbuild = (Get-Command lazbuild -ErrorAction Stop).Source } catch {
  $candidates = @(
    'C:\Program Files\Lazarus\lazbuild.exe',
    'C:\Lazarus\lazbuild.exe'
  )
  foreach ($c in $candidates) { if (Test-Path $c) { $lazbuild = $c; break } }
}

if (-not $lazbuild) { throw 'lazbuild not found in PATH or default locations' }

Write-Host "[INFO] Building example with $lazbuild"
& "$lazbuild" "$example"

if (Test-Path $exe) {
  Write-Host '[INFO] Running example ...'
  & "$exe"
} else {
  Write-Warning "Example exe not found: $exe"
}

