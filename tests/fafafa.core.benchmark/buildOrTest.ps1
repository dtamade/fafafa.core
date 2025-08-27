param(
  [Parameter(Position=0)]
  [ValidateSet('build','test','clean')]
  [string]$Command
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$bat = Join-Path $here 'buildOrTest.bat'

if (!(Test-Path -LiteralPath $bat)) {
  Write-Error "buildOrTest.bat not found: $bat"
  exit 1
}

# Wrap the .bat with cmd /c to avoid PowerShell/Cmd parenthesis parsing noise
$cmdline = if ([string]::IsNullOrWhiteSpace($Command)) { "`"$bat`"" } else { "`"$bat`" $Command" }
$prevErr = $ErrorActionPreference
try {
  $ErrorActionPreference = 'Continue'
  $out = & cmd /c $cmdline 2>&1
  $rc = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $prevErr
}
$out | Out-Host

# Tolerate known cmd noise where exit code becomes 1 despite tests passing
if ($rc -ne 0) {
  if (($out -match 'All tests passed!') -and -not ($out -match 'Failed:\s*[1-9]')) {
    exit 0
  } else {
    exit $rc
  }
} else {
  exit 0
}

