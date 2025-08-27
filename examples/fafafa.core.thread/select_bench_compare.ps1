param(
  [int]$Iter = 200,
  [int]$Repeats = 3,
  [string]$CsvPath,
  [int]$Step = 7,
  [int]$Span = 60,
  [int]$Base = 20,
  [switch]$Append,
  [string]$Tag
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Push-Location $PSScriptRoot
try {
  $LAZBUILD = Join-Path $PSScriptRoot "..\..\tools\lazbuild.bat"
  $BENCH_PROJ = "example_thread_select_bench.lpr"
  $BENCH_EXE = Join-Path $PSScriptRoot "bin\example_thread_select_bench.exe"
  $SRC_DIR = Join-Path $PSScriptRoot "..\..\src"
  $FPCEXE = "D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe"

  if(-not $CsvPath -or $CsvPath -eq ''){
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $CsvPath = Join-Path $PSScriptRoot "bin\select_bench_compare_$ts.csv"
  }
  $CsvDir = Split-Path -Parent $CsvPath
  if(-not (Test-Path $CsvDir)) { New-Item -ItemType Directory -Path $CsvDir | Out-Null }

  $willWriteTag = $false
  if(-not $Append -or -not (Test-Path $CsvPath)){
    "mode,N,avg_ms,iter,step,span,base,tag" | Set-Content -Path $CsvPath -Encoding UTF8
    $willWriteTag = $true
  } else {
    $header = Get-Content -Path $CsvPath -TotalCount 1
    if($header -match '(^|,)tag($|,)') { $willWriteTag = $true }
  }

  Write-Host "[1/4] Build bench (polling)..."
  & $LAZBUILD --build-mode=Release $BENCH_PROJ | Out-Null

  Write-Host "[2/4] Run bench (polling)..."
  for($i=1; $i -le $Repeats; $i++){
    $out = & $BENCH_EXE $Iter $Step $Span $Base
    foreach($line in $out){
      if($line -match 'N=([0-9]+).*avg=([0-9\.,]+)\s*ms'){
        $N = $matches[1]
        $avgTxt = $matches[2]
        $avg = ($avgTxt -replace ',', '.')
        Write-Host ("polling,N={0},avg_ms={1}" -f $N,$avg)
        $row = "polling,{0},{1},{2},{3},{4},{5}" -f $N,$avg,$Iter,$Step,$Span,$Base
        if($willWriteTag -and $Tag){ $row = "$row,$Tag" }
        Add-Content -Path $CsvPath -Value $row
      }
    }
  }

  Write-Host "[3/4] Build bench (non-polling)..."
  & $FPCEXE -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -dFAFAFA_THREAD_SELECT_NONPOLLING -Fi. -Fu. -Fu"$SRC_DIR" -FEbin $BENCH_PROJ | Out-Null

  Write-Host "[4/4] Run bench (non-polling)..."
  for($i=1; $i -le $Repeats; $i++){
    $out = & $BENCH_EXE $Iter $Step $Span $Base
    foreach($line in $out){
      if($line -match 'N=([0-9]+).*avg=([0-9\.,]+)\s*ms'){
        $N = $matches[1]
        $avgTxt = $matches[2]
        $avg = ($avgTxt -replace ',', '.')
        Write-Host ("nonpolling,N={0},avg_ms={1}" -f $N,$avg)
        $row = "nonpolling,{0},{1},{2},{3},{4},{5}" -f $N,$avg,$Iter,$Step,$Span,$Base
        if($willWriteTag -and $Tag){ $row = "$row,$Tag" }
        Add-Content -Path $CsvPath -Value $row
      }
    }
  }

  Write-Host ("CSV saved to: {0}" -f $CsvPath)
}
finally {
  Pop-Location
}

