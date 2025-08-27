$ErrorActionPreference = 'Stop'

# Build
& tools\lazbuild.bat --build-mode=Debug examples\fafafa.core.color\palette_demo.lpi

# Run and tee output
$log = 'examples\fafafa.core.color\palette_demo.log'
if (Test-Path 'bin\palette_demo.exe') {
  & 'bin\palette_demo.exe' | Tee-Object -FilePath $log
  Write-Host "[RunDemo] Log written to $log"
}
else {
  throw 'bin\palette_demo.exe not found after build.'
}

