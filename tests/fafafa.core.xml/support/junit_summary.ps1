param(
  [Parameter(Mandatory=$true)]
  [string]$Path
)

if (-not (Test-Path $Path)) {
  Write-Output "[FAIL] junit missing: $Path"
  exit 1
}

try {
  $xml = Get-Content $Path -Raw
  [xml]$doc = $xml
} catch {
  Write-Output "[FAIL] cannot read junit: $Path"
  exit 1
}

$suites = $doc.testsuites.testsuite
if ($null -eq $suites) {
  Write-Output "suites=0 tests=0 failures=0 errors=0 skipped=0"
  exit 0
}

# Normalize to array
if ($suites -isnot [System.Array]) { $suites = @($suites) }

$tests   = ($suites | ForEach-Object { [int]$_.tests }   | Measure-Object -Sum).Sum
$fails   = ($suites | ForEach-Object { [int]$_.failures }| Measure-Object -Sum).Sum
$errors  = ($suites | ForEach-Object { [int]$_.errors }  | Measure-Object -Sum).Sum
$skipped = ($suites | ForEach-Object { [int]$_.skipped } | Measure-Object -Sum).Sum

Write-Output ("suites={0} tests={1} failures={2} errors={3} skipped={4}" -f $suites.Length,$tests,$fails,$errors,$skipped)
exit 0

