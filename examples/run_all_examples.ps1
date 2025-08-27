#requires -version 3.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Join-Path $root 'examples.lpi'
$exe  = Join-Path $root 'bin/examples.exe'

try { $lazbuild = (Get-Command lazbuild -ErrorAction Stop).Source } catch {
  $candidates = @(
    'C:\Program Files\Lazarus\lazbuild.exe',
    'C:\Lazarus\lazbuild.exe'
  )
  foreach ($c in $candidates) { if (Test-Path $c) { $lazbuild = $c; break } }
}

if (-not $lazbuild) { throw 'lazbuild not found in PATH or default locations' }

Write-Host "[INFO] Building examples project with $lazbuild"
& "$lazbuild" "$proj"

if (Test-Path $exe) {
  Write-Host '[INFO] Running examples ...'
  & "$exe"
} else {
  Write-Warning "Examples exe not found: $exe"
}

