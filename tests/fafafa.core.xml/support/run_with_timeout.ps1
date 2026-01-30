param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [Parameter(Mandatory=$true)][string]$ArgString,
  [int]$TimeoutSec = 240,
  [string]$RedirectStderr = ''
)

# Ensure tests don't print registration noise that corrupts junit/xml output
$env:FAFAFA_TEST_SILENT_REG = '1'

try {
  if ($RedirectStderr -ne '') {
    $p = Start-Process -FilePath $Exe -ArgumentList $ArgString -NoNewWindow -PassThru -RedirectStandardError $RedirectStderr
  } else {
    $p = Start-Process -FilePath $Exe -ArgumentList $ArgString -NoNewWindow -PassThru
  }
  if (-not $p.WaitForExit($TimeoutSec * 1000)) {
    try { $p.Kill() } catch {}
    Write-Output "[TIMEOUT] Killed $Exe after $TimeoutSec sec"
    exit 124
  }
  exit $p.ExitCode
} catch {
  Write-Output "[ERROR] $_"
  exit 1
}

