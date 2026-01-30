param(
  [object]$Iters = "200",
  [int]$Repeats = 3,
  [object]$Steps = "7",
  [object]$Spans = "60",
  [object]$Bases = "20",
  [string]$CsvPath,
  [string]$Tag,
  [int]$PerRunTimeoutSec = 0,
  [int]$ProgressIntervalSec = 15
)

class ProgressState { [int]$Total; [int]$Done; [datetime]$Last; }
function Start-ProgressHeartbeat([int]$total,[int]$interval){
  $script:__hb = New-Object ProgressState; $script:__hb.Total=$total; $script:__hb.Done=0; $script:__hb.Last=Get-Date
  if($interval -le 0){ return }
  $script:__timer = [System.Timers.Timer]::new($interval*1000)
  $script:__timer.AutoReset=$true
  $script:__timer.add_Elapsed({ if($script:__hb){ $pct=[math]::Round(100.0*$script:__hb.Done/[math]::Max(1,$script:__hb.Total),1); Write-Host ("[PROGRESS] {0}/{1} ({2}%)" -f $script:__hb.Done,$script:__hb.Total,$pct) } })
  $script:__timer.Start()
}
function Stop-ProgressHeartbeat(){ if($script:__timer){ $script:__timer.Stop(); $script:__timer.Dispose(); $script:__timer=$null }; $script:__hb=$null }
function Inc-Progress(){ if($script:__hb){ $script:__hb.Done++ } }

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function NormalizeList($list){
  if($null -eq $list){ return @() }
  function _TryToInt($s){
    $n = 0
    if([int]::TryParse($s, [ref]$n)){ return $n }
    return $null
  }
  $toNums = {
    param($seq)
    $nums = @()
    foreach($v in $seq){
      $tok = ($v.ToString()).Trim()
      $tok = $tok.Trim('"').Trim("'")
      if($tok -ne ''){
        $n = _TryToInt $tok
        if($null -ne $n){ $nums += $n }
      }
    }
    return $nums
  }
  if($list -is [array]){ return & $toNums $list }
  $s = $list.ToString().Trim()
  $s = ($s -replace '[\(\)]','')
  $tokens = $s -split '[,;\s]+' | Where-Object { $_ -ne '' }
  return & $toNums $tokens
}

function FlattenIfNested($arr){
  if($arr -is [array] -and $arr.Count -eq 1 -and $arr[0] -is [array]){ return @($arr[0]) }
  return $arr
}


Push-Location $PSScriptRoot
try {
  if(-not $CsvPath -or $CsvPath -eq ''){
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $CsvPath = Join-Path $PSScriptRoot "bin/select_bench_compare_matrix_$ts.csv"
  }
  # Ensure arrays for count ops
  $Iters = @($Iters)
  $Steps = @($Steps)
  $Spans = @($Spans)
  $Bases = @($Bases)

  $CsvDir = Split-Path -Parent $CsvPath
  if([string]::IsNullOrWhiteSpace($CsvDir)){
    $CsvDir = Join-Path $PSScriptRoot "bin"
    if(-not (Test-Path $CsvDir)) { New-Item -ItemType Directory -Path $CsvDir | Out-Null }
    $CsvPath = Join-Path $CsvDir (Split-Path -Leaf $CsvPath)
  } else {
    if(-not (Test-Path $CsvDir)) { New-Item -ItemType Directory -Path $CsvDir | Out-Null }
  }

  $Iters = FlattenIfNested (NormalizeList $Iters)
  $Steps = FlattenIfNested (NormalizeList $Steps)
  $Spans = FlattenIfNested (NormalizeList $Spans)
  $Bases = FlattenIfNested (NormalizeList $Bases)

  # Prepare tools and paths (same as single-run script)
  $LAZBUILD = Join-Path $PSScriptRoot "..\..\tools\lazbuild.bat"
  $BENCH_PROJ = "example_thread_select_bench.lpr"
  $BENCH_EXE = Join-Path $PSScriptRoot "bin\example_thread_select_bench.exe"
  $SRC_DIR = Join-Path $PSScriptRoot "..\..\src"
  $FPCEXE = "D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe"

  # CSV header and tag column handling
  $willWriteTag = $false
  if(-not (Test-Path $CsvPath)){
    "mode,N,avg_ms,iter,step,span,base,tag" | Set-Content -Path $CsvPath -Encoding UTF8
    $willWriteTag = $true
  } else {
    $header = Get-Content -Path $CsvPath -TotalCount 1
    if($header -match '(^|,)tag($|,)'){ $willWriteTag = $true }
  }

  # 1) Build bench (polling) ONCE
  Write-Host "[1/4] Build bench (polling)..."
  & $LAZBUILD --build-mode=Release $BENCH_PROJ | Out-Null

  # Compute total combos for progress (robust to scalars)
  $itN = @($Iters).Count; $stN = @($Steps).Count; $spN = @($Spans).Count; $baN = @($Bases).Count
  $totalCombos = ($itN * $stN * $spN * $baN * 2 * [math]::Max(1,$Repeats))
  Start-ProgressHeartbeat -total $totalCombos -interval $ProgressIntervalSec

  # 2) Run bench (polling) for each combination
  Write-Host "[2/4] Run bench (polling, matrix)..."
  foreach($iter in $Iters){
    foreach($step in $Steps){
      foreach($span in $Spans){
        foreach($base in $Bases){
          $tagEff = $Tag; if(-not $tagEff -or $tagEff -eq ''){ $tagEff = "iter=$iter;step=$step;span=$span;base=$base" }
          Write-Host "== Run(polling): iter=$iter step=$step span=$span base=$base repeats=$Repeats tag=$tagEff =="
          for($i=1; $i -le $Repeats; $i++){
            $outJob = Start-Job -ScriptBlock { param($exe,$iter,$step,$span,$base) & $exe $iter $step $span $base } -ArgumentList $BENCH_EXE,$iter,$step,$span,$base
            $timeoutMs = $PerRunTimeoutSec * 1000
            if($PerRunTimeoutSec -gt 0){
              $ok = Wait-Job -Job $outJob -Timeout $PerRunTimeoutSec
              if(-not $ok){
                Write-Warning ("Run timed out: iter={0} step={1} span={2} base={3}" -f $iter,$step,$span,$base)
                Stop-Job $outJob -ErrorAction SilentlyContinue | Out-Null
                Remove-Job $outJob -Force -ErrorAction SilentlyContinue | Out-Null
                Inc-Progress
                continue
              }
            } else { Wait-Job -Job $outJob | Out-Null }
            $out = Receive-Job -Job $outJob; Remove-Job $outJob -Force -ErrorAction SilentlyContinue | Out-Null
            foreach($line in $out){
              if($line -match 'N=([0-9]+).*avg=([0-9\.,]+)\s*ms'){
                $N = $matches[1]
                $avgTxt = $matches[2]
                $avg = ($avgTxt -replace ',', '.')
                Write-Host ("polling,N={0},avg_ms={1}" -f $N,$avg)
                $row = "polling,{0},{1},{2},{3},{4},{5}" -f $N,$avg,$iter,$step,$span,$base
                if($willWriteTag -and $Tag){ $row = "$row,$tagEff" }
                Add-Content -Path $CsvPath -Value $row
              }
            }
            Inc-Progress
          }
        }
      }
    }
  }

  Stop-ProgressHeartbeat

  # 3) Build bench (non-polling) ONCE
  Write-Host "[3/4] Build bench (non-polling)..."
  & $FPCEXE -MObjFPC -Scghi -O2 -Xs -XX -CX -Sd -Si -Sg -vewnhibq -dFAFAFA_THREAD_SELECT_NONPOLLING -Fi. -Fu. -Fu"$SRC_DIR" -FEbin $BENCH_PROJ | Out-Null

  # 4) Run bench (non-polling) for each combination
  Write-Host "[4/4] Run bench (non-polling, matrix)..."
  foreach($iter in $Iters){
    foreach($step in $Steps){
      foreach($span in $Spans){
        foreach($base in $Bases){
          $tagEff = $Tag; if(-not $tagEff -or $tagEff -eq ''){ $tagEff = "iter=$iter;step=$step;span=$span;base=$base" }
          Write-Host "== Run(non-polling): iter=$iter step=$step span=$span base=$base repeats=$Repeats tag=$tagEff =="
          for($i=1; $i -le $Repeats; $i++){
            $outJob = Start-Job -ScriptBlock { param($exe,$iter,$step,$span,$base) & $exe $iter $step $span $base } -ArgumentList $BENCH_EXE,$iter,$step,$span,$base
            if($PerRunTimeoutSec -gt 0){
              $ok = Wait-Job -Job $outJob -Timeout $PerRunTimeoutSec
              if(-not $ok){
                Write-Warning ("Run timed out: iter={0} step={1} span={2} base={3}" -f $iter,$step,$span,$base)
                Stop-Job $outJob -ErrorAction SilentlyContinue | Out-Null
                Remove-Job $outJob -Force -ErrorAction SilentlyContinue | Out-Null
                Inc-Progress
                continue
              }
            } else { Wait-Job -Job $outJob | Out-Null }
            $out = Receive-Job -Job $outJob; Remove-Job $outJob -Force -ErrorAction SilentlyContinue | Out-Null
            foreach($line in $out){
              if($line -match 'N=([0-9]+).*avg=([0-9\.,]+)\s*ms'){
                $N = $matches[1]
                $avgTxt = $matches[2]
                $avg = ($avgTxt -replace ',', '.')
                Write-Host ("nonpolling,N={0},avg_ms={1}" -f $N,$avg)
                $row = "nonpolling,{0},{1},{2},{3},{4},{5}" -f $N,$avg,$iter,$step,$span,$base
                if($willWriteTag -and $Tag){ $row = "$row,$tagEff" }
                Add-Content -Path $CsvPath -Value $row
              }
            }
            Inc-Progress
          }
        }
      }
    }
  }

  Stop-ProgressHeartbeat

  Write-Host ("Matrix CSV saved to: {0}" -f $CsvPath)
}
finally {
  Pop-Location
}

