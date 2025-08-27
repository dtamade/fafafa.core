param(
  [string[]]$CsvPaths,
  [string]$OutPath,
  [string]$HtmlOutPath,
  [double]$DeltaWarnPct = 5,
  [double]$DeltaErrPct = 10,
  [double]$DeltaMsWarnMs = 1.0,
  [double]$DeltaMsErrMs = 3.0,
  [bool]$BgHighlight = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


function Normalize-CsvPaths([object]$CsvPaths){
  $list = @()
  if($CsvPaths -is [array]){ $list = @($CsvPaths) } else { $list = @($CsvPaths) }
  if($list.Count -eq 1 -and ($list[0] -is [string]) -and ($list[0] -as [string]).Contains(',')){
    $parts = ($list[0] -as [string]) -split ','
    $list = @()
    foreach($p in $parts){
      $t = ($p -as [string]).Trim()
      if($t.StartsWith('"') -and $t.EndsWith('"')){ $t = $t.Trim('"') }
      if($t.StartsWith("'") -and $t.EndsWith("'")){ $t = $t.Trim("'") }
      if($t){ $list += $t }
    }
  } else {
    $list = @($list | ForEach-Object {
      if($_ -is [string]){
        $t = $_.Trim()
        if($t.StartsWith('"') -and $t.EndsWith('"')){ $t = $t.Trim('"') }
        if($t.StartsWith("'") -and $t.EndsWith("'")){ $t = $t.Trim("'") }
        $t
      } else { $_ }
    })
  }
  return ,$list
}

function Get-Quantile([double[]]$vals, [double]$p){
  if(-not $vals -or $vals.Count -eq 0){ return $null }
  $arr = @($vals | Sort-Object)
  $n = $arr.Count
  if($n -eq 1){ return $arr[0] }
  if($p -le 0){ return $arr[0] }
  if($p -ge 1){ return $arr[$n-1] }
  $rank = ($n - 1) * $p
  $lo = [math]::Floor($rank)
  $hi = [math]::Ceiling($rank)
  if($lo -eq $hi){ return $arr[$lo] }
  $w = $rank - $lo
  return $arr[$lo] * (1 - $w) + $arr[$hi] * $w
}

function Get-Stats([double[]]$vals){
  if(-not $vals -or $vals.Count -eq 0){ return @{ Mean=$null; Std=$null; Count=0; P50=$null; P90=$null; P99=$null } }
  $n = [double]$vals.Count
  $mean = ($vals | Measure-Object -Average).Average
  # Std (sample, n-1). If n==1 => 0
  if($n -le 1){ $std = 0.0 }
  else {
    $sumSq = 0.0
    foreach($v in $vals){ $sumSq += [math]::Pow($v - $mean, 2) }
    $std = [math]::Sqrt($sumSq / ($n - 1.0))
  }
  $p50 = Get-Quantile $vals 0.5
  $p90 = Get-Quantile $vals 0.9
  $p99 = Get-Quantile $vals 0.99
  return @{
    Mean=[math]::Round($mean,3);
    Std=[math]::Round($std,3);
    Count=[int]$n;
    P50= if($p50 -ne $null){ [math]::Round($p50,3) } else { $null };
    P90= if($p90 -ne $null){ [math]::Round($p90,3) } else { $null };
    P99= if($p99 -ne $null){ [math]::Round($p99,3) } else { $null }
  }
}

# Default to latest generated CSV if not provided
$CsvPaths = Normalize-CsvPaths $CsvPaths
if(-not $CsvPaths -or $CsvPaths.Count -eq 0){
  $latest = Get-ChildItem -ErrorAction SilentlyContinue -Path "$PSScriptRoot\bin" -Filter "select_bench_compare_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if(-not $latest){
    Write-Error "No CSV provided and no select_bench_compare_*.csv found under bin/."
    exit 2
  }
  $CsvPaths = @($latest.FullName)
}

# Merge rows
$rows = @()
foreach($p in $CsvPaths){
  if(-not (Test-Path $p)){ Write-Warning "CSV not found: $p"; continue }
  $rows += (Import-Csv -Path $p)
}
if(-not $rows -or $rows.Count -eq 0){ Write-Error "No data rows loaded."; exit 3 }

# Normalize types
foreach($r in $rows){
  $r.N = [int]$r.N
  $r.avg_ms = [double]$r.avg_ms
}

# Collect meta params (may vary across CSVs)
$metaSets = $rows | Select-Object -Property iter,step,span,base,tag -Unique

# Group by N and mode
$Ns = ($rows | Select-Object -ExpandProperty N | Sort-Object -Unique)
$Modes = @('polling','nonpolling')

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$outPath = Join-Path $PSScriptRoot "bin\select_bench_report_$ts.md"
if($OutPath){ $outPath = $OutPath }

$md = @()
$md += "# Select Bench Report ($ts)"
$md += ""
$md += "Environment:"
$os = (Get-CimInstance Win32_OperatingSystem)
$cs = (Get-CimInstance Win32_ComputerSystem)
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1)
$md += ("- OS: {0} {1}" -f $os.Caption, $os.Version)
$md += ("- Machine: {0} ({1} cores, {2} GB RAM)" -f $cs.Model, $cs.NumberOfLogicalProcessors, [math]::Round($cs.TotalPhysicalMemory/1GB,1))
$md += ("- CPU: {0}" -f $cpu.Name)
$md += ""
$md += "Input CSV(s):"
foreach($p in $CsvPaths){ $md += "- $p" }
$md += ""
$md += "Meta param sets (iter,step,span,base[,tag]):"
foreach($m in $metaSets){
  $tagPart = ""
  if($m.PSObject.Properties.Name -contains 'tag'){
    if(-not [string]::IsNullOrEmpty($m.tag)) { $tagPart = ", tag=$($m.tag)" }
  }
  $md += ("- {0}, {1}, {2}, {3}{4}" -f $m.iter, $m.step, $m.span, $m.base, $tagPart)
}
$md += ""
$md += "## Global overview (by N)"
$md += "| N | polling avg | std | nonpolling avg | std | delta ms | delta % |"

$md += "|---:|------------:|----:|---------------:|----:|---------:|--------:|"
foreach($n in $Ns){
  $pValsAll = ($rows | Where-Object { $_.N -eq $n -and $_.mode -eq 'polling' } | Select-Object -ExpandProperty avg_ms)
  $npValsAll = ($rows | Where-Object { $_.N -eq $n -and $_.mode -eq 'nonpolling' } | Select-Object -ExpandProperty avg_ms)
  $pStatsAll = Get-Stats @([double[]]$pValsAll)
  $npStatsAll = Get-Stats @([double[]]$npValsAll)
  $deltaMsAll = $null; $deltaPctAll = $null
  if($pStatsAll.Mean -ne $null -and $npStatsAll.Mean -ne $null){
    $deltaMsAll = [math]::Round(($npStatsAll.Mean - $pStatsAll.Mean), 3)
    if($pStatsAll.Mean -ne 0){ $deltaPctAll = [math]::Round(100.0 * $deltaMsAll / $pStatsAll.Mean, 2) } else { $deltaPctAll = 'inf' }
}

  $md += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f `
    $n, $pStatsAll.Mean, $pStatsAll.Std, $npStatsAll.Mean, $npStatsAll.Std, $deltaMsAll, $deltaPctAll)
}
$md += ""

# Overview by tag × N (only if tag exists)
$tagsTN = ($rows | Where-Object { $_.PSObject.Properties.Name -contains 'tag' -and -not [string]::IsNullOrEmpty($_.tag) } | Select-Object -ExpandProperty tag | Sort-Object -Unique)
$tagsTN = @($tagsTN)
if($tagsTN -and $tagsTN.Length -gt 0){
  $md += "## Overview by tag x N"
  foreach($n in $Ns){
    $md += ("### N={0}" -f $n)
    $md += "| tag | polling avg | std | nonpolling avg | std | delta ms | delta % |"
    $md += "|:----|------------:|----:|---------------:|----:|---------:|--------:|"
    foreach($t in $tagsTN){
      $pValsTN = ($rows | Where-Object { $_.N -eq $n -and $_.mode -eq 'polling' -and $_.PSObject.Properties.Name -contains 'tag' -and $_.tag -eq $t } | Select-Object -ExpandProperty avg_ms)
      $npValsTN = ($rows | Where-Object { $_.N -eq $n -and $_.mode -eq 'nonpolling' -and $_.PSObject.Properties.Name -contains 'tag' -and $_.tag -eq $t } | Select-Object -ExpandProperty avg_ms)
      $pStatsTN = Get-Stats @([double[]]$pValsTN)
      $npStatsTN = Get-Stats @([double[]]$npValsTN)
      $deltaMsTN = $null; $deltaPctTN = $null
      if($pStatsTN.Mean -ne $null -and $npStatsTN.Mean -ne $null){
        $deltaMsTN = [math]::Round(($npStatsTN.Mean - $pStatsTN.Mean), 3)
        if($pStatsTN.Mean -ne 0){ $deltaPctTN = [math]::Round(100.0 * $deltaMsTN / $pStatsTN.Mean, 2) } else { $deltaPctTN = 'inf' }
      }
      $md += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f `
        $t, $pStatsTN.Mean, $pStatsTN.Std, $npStatsTN.Mean, $npStatsTN.Std, $deltaMsTN, $deltaPctTN)
    }
    $md += ""
  }
}
$md += ""
# Overview by tag (if any tag column present)
$hasTag = $false
foreach($r in $rows){ if($r.PSObject.Properties.Name -contains 'tag' -and -not [string]::IsNullOrEmpty($r.tag)){ $hasTag = $true; break } }
if($hasTag){
  $md += "## Overview by tag (all N)"
  $md += "| tag | polling avg | std | nonpolling avg | std | delta ms | delta % |"
  $md += "|:----|------------:|----:|---------------:|----:|---------:|--------:|"
  $tags = ($rows | Where-Object { $_.PSObject.Properties.Name -contains 'tag' -and -not [string]::IsNullOrEmpty($_.tag) } | Select-Object -ExpandProperty tag | Sort-Object -Unique)
  foreach($t in $tags){
    $pValsT = ($rows | Where-Object { $_.mode -eq 'polling' -and $_.PSObject.Properties.Name -contains 'tag' -and $_.tag -eq $t } | Select-Object -ExpandProperty avg_ms)
    $npValsT = ($rows | Where-Object { $_.mode -eq 'nonpolling' -and $_.PSObject.Properties.Name -contains 'tag' -and $_.tag -eq $t } | Select-Object -ExpandProperty avg_ms)
    $pStatsT = Get-Stats @([double[]]$pValsT)
    $npStatsT = Get-Stats @([double[]]$npValsT)
    $deltaMsT = $null; $deltaPctT = $null
    if($pStatsT.Mean -ne $null -and $npStatsT.Mean -ne $null){
      $deltaMsT = [math]::Round(($npStatsT.Mean - $pStatsT.Mean), 3)
      if($pStatsT.Mean -ne 0){ $deltaPctT = [math]::Round(100.0 * $deltaMsT / $pStatsT.Mean, 2) } else { $deltaPctT = 'inf' }
    }
    $md += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f `
      $t, $pStatsT.Mean, $pStatsT.Std, $npStatsT.Mean, $npStatsT.Std, $deltaMsT, $deltaPctT)
  }
  $md += ""
}
# Optional CSV exports for summaries
$csvDir = Split-Path -Parent $outPath
$csvTagAll = Join-Path $csvDir "overview_by_tag.csv"
$csvTagByN = Join-Path $csvDir "overview_by_tag_x_N.csv"

# Collect data for CSVs
$rowsTagAll = @()
$rowsTagByN = @()
if($hasTag){
  foreach($t in $tags){
    $rowsTagAll += [pscustomobject]@{
      tag=$t; polling_avg=$pStatsT.Mean; polling_std=$pStatsT.Std; nonpolling_avg=$npStatsT.Mean; nonpolling_std=$npStatsT.Std; delta_ms=$deltaMsT; delta_pct=$deltaPctT
    }
  }
}
if($tagsTN -and $tagsTN.Length -gt 0){
  foreach($n in $Ns){
    foreach($t in $tagsTN){
      $pValsTN = ($rows | Where-Object { $_.N -eq $n -and $_.mode -eq 'polling' -and $_.PSObject.Properties.Name -contains 'tag' -and $_.tag -eq $t } | Select-Object -ExpandProperty avg_ms)
      $npValsTN = ($rows | Where-Object { $_.N -eq $n -and $_.mode -eq 'nonpolling' -and $_.PSObject.Properties.Name -contains 'tag' -and $_.tag -eq $t } | Select-Object -ExpandProperty avg_ms)
      $pStatsTN = Get-Stats @([double[]]$pValsTN)
      $npStatsTN = Get-Stats @([double[]]$npValsTN)
      $deltaMsTN = $null; $deltaPctTN = $null
      if($pStatsTN.Mean -ne $null -and $npStatsTN.Mean -ne $null){
        $deltaMsTN = [math]::Round(($npStatsTN.Mean - $pStatsTN.Mean), 3)
        if($pStatsTN.Mean -ne 0){ $deltaPctTN = [math]::Round(100.0 * $deltaMsTN / $pStatsTN.Mean, 2) } else { $deltaPctTN = 'inf' }
      }
      $rowsTagByN += [pscustomobject]@{ N=$n; tag=$t; polling_avg=$pStatsTN.Mean; polling_std=$pStatsTN.Std; nonpolling_avg=$npStatsTN.Mean; nonpolling_std=$npStatsTN.Std; delta_ms=$deltaMsTN; delta_pct=$deltaPctTN }
    }
  }
}

if($rowsTagAll.Count -gt 0){ $rowsTagAll | Export-Csv -Path $csvTagAll -NoTypeInformation -Encoding UTF8 }
if($rowsTagByN.Count -gt 0){ $rowsTagByN | Export-Csv -Path $csvTagByN -NoTypeInformation -Encoding UTF8 }

$md += "## Results by parameter group"
foreach($m in $metaSets){
  $md += ""
  $title = "iter={0} step={1} span={2} base={3}" -f $m.iter, $m.step, $m.span, $m.base
  if($m.tag){ $title = "$title | tag=$($m.tag)" }
  $md += ("### $title")
  $rowsG = $rows | Where-Object { $_.iter -eq $m.iter -and $_.step -eq $m.step -and $_.span -eq $m.span -and $_.base -eq $m.base }
  $NsG = ($rowsG | Select-Object -ExpandProperty N | Sort-Object -Unique)
  $md += "| N | polling avg | p50 | p90 | p99 | std | nonpolling avg | p50 | p90 | p99 | std | delta ms | delta % |"
  $md += "|---:|------------:|----:|----:|----:|----:|---------------:|----:|----:|----:|----:|---------:|--------:|"
  foreach($n in $NsG){
    $pVals = ($rowsG | Where-Object { $_.N -eq $n -and $_.mode -eq 'polling' } | Select-Object -ExpandProperty avg_ms)
    $npVals = ($rowsG | Where-Object { $_.N -eq $n -and $_.mode -eq 'nonpolling' } | Select-Object -ExpandProperty avg_ms)
    $pStats = Get-Stats @([double[]]$pVals)
    $npStats = Get-Stats @([double[]]$npVals)
    $deltaMs = $null; $deltaPct = $null
    if($pStats.Mean -ne $null -and $npStats.Mean -ne $null){
      $deltaMs = [math]::Round(($npStats.Mean - $pStats.Mean), 3)
      if($pStats.Mean -ne 0){ $deltaPct = [math]::Round(100.0 * $deltaMs / $pStats.Mean, 2) } else { $deltaPct = 'inf' }
    }
    $md += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} | {10} | {11} | {12} |" -f `
      $n, $pStats.Mean, $pStats.P50, $pStats.P90, $pStats.P99, $pStats.Std,
      $npStats.Mean, $npStats.P50, $npStats.P90, $npStats.P99, $npStats.Std,
      $deltaMs, $deltaPct)
  }
}

# Write markdown file
$md | Set-Content -Path $outPath -Encoding UTF8
Write-Host "Report saved to: $outPath"

# Optional HTML export
if($HtmlOutPath){
  $html = @()
  $html += "<html><head><meta charset='utf-8'><style>"
  $html += "body{font-family:Segoe UI,Arial,sans-serif;padding:16px}"
  $html += "table{border-collapse:collapse;margin:12px 0;max-width:100%;overflow:auto;display:block}"
  $html += "th,td{border:1px solid #ddd;padding:6px 10px;text-align:right}"
  $html += "th:first-child,td:first-child{text-align:left}"
  $html += "thead th{position:sticky;top:0;background:#fafafa}"
  $html += "tr:nth-child(even){background:#fbfbfb}"
  $html += "h1,h2,h3{margin:18px 0 8px}"
  $html += "code{background:#f6f8fa;padding:2px 4px;border-radius:4px}"
  $html += "a{color:#0366d6;text-decoration:none} a:hover{text-decoration:underline}"
  $html += ".delta-warn{color:#d97706;font-weight:600} .delta-err{color:#b91c1c;font-weight:700} .delta-ok{color:#065f46} .bg .delta-warn{background:#fff3cd} .bg .delta-err{background:#fde2e2} .bg .delta-ok{background:#e8f7f1}"
  $html += "</style></head><body>"
  $inTable=$false; $headerDone=$false
  # Build TOC from headings (h2/h3)
  $toc = @()
  foreach($l in $md){
    if($l -match '^## (.+)'){ $text=$matches[1]; $id=($text.ToLower() -replace '[^a-z0-9 ]','' -replace ' +','-'); $toc += @{Level=2;Text=$text;Id=$id}; continue }
    if($l -match '^### (.+)'){ $text=$matches[1]; $id=($text.ToLower() -replace '[^a-z0-9 ]','' -replace ' +','-'); $toc += @{Level=3;Text=$text;Id=$id}; continue }
  }
  if($toc -and $toc.Count -gt 0){
    $html += "<div><strong>Contents</strong><ul>"
    foreach($h in $toc){
      $indent = if($h.Level -gt 2){ ($h.Level - 2) * 18 } else { 0 }
      $html += ("<li style='margin-left:{0}px'><a href='#{1}'>{2}</a></li>" -f $indent, $h.Id, $h.Text)
    }
    $html += "</ul></div><hr/>"
  }
  foreach($line in $md){
    if($line -match '^# (.+)'){ $t=$matches[1]; $id=($t.ToLower() -replace '[^a-z0-9 ]','' -replace ' +','-'); $html += ("<h1 id='{0}'>{1}</h1>" -f $id,$t); continue }
    if($line -match '^## (.+)'){ $t=$matches[1]; $id=($t.ToLower() -replace '[^a-z0-9 ]','' -replace ' +','-'); $html += ("<h2 id='{0}'>{1}</h2>" -f $id,$t); continue }
    if($line -match '^### (.+)'){ $t=$matches[1]; $id=($t.ToLower() -replace '[^a-z0-9 ]','' -replace ' +','-'); $html += ("<h3 id='{0}'>{1}</h3>" -f $id,$t); continue }
    if($line -match '^\|'){ # simple markdown table row
      # skip Markdown alignment row like |---:| or |:----|
      if($line -match '^\|\s*:?[-]+:?\s*(\|\s*:?[-]+:?\s*)+\|\s*$'){ continue }
      if(-not $inTable){ $inTable=$true; $html += "<table>" }
      $cells = ($line.Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
      if(-not $headerDone){
        $html += "<thead>"
        $html += ("<tr>{0}</tr>" -f (($cells | ForEach-Object { "<th>$_</th>" }) -join ''))
        $html += "</thead><tbody>"
        $headerDone = $true
      } else {
        # decorate delta columns if present (delta ms at index -2, delta % at last)
        $cellsOut = @()
        for($ci=0;$ci -lt $cells.Count;$ci++){
          $val = $cells[$ci]
          $cls = ""
          if($cells.Count -ge 2 -and ($ci -eq $cells.Count-1 -or $ci -eq $cells.Count-2)){
            if($ci -eq $cells.Count-1){ # delta %
              $num = $null; [double]::TryParse(($val -replace '%','' -replace ',','.'), [ref]$num) | Out-Null
              if($null -ne $num){ $abs=[math]::Abs($num); if($abs -ge $DeltaErrPct){ $cls='delta-err' } elseif($abs -ge $DeltaWarnPct){ $cls='delta-warn' } else { $cls='delta-ok' } }
            } elseif($ci -eq $cells.Count-2) { # delta ms
              $num2 = $null; [double]::TryParse(($val -replace ',','.'), [ref]$num2) | Out-Null
              if($null -ne $num2){ $abs2=[math]::Abs($num2); if($abs2 -ge $DeltaMsErrMs){ $cls='delta-err' } elseif($abs2 -ge $DeltaMsWarnMs){ $cls='delta-warn' } else { $cls='delta-ok' } }
            }
          }
          $tdClass = $cls
          if($BgHighlight -and -not [string]::IsNullOrEmpty($cls)){ $tdClass = "bg $cls" }
          if([string]::IsNullOrEmpty($tdClass)){ $cellsOut += ("<td>{0}</td>" -f $val) } else { $cellsOut += ("<td class='{0}'>{1}</td>" -f $tdClass,$val) }
        }
        $html += ("<tr>{0}</tr>" -f ($cellsOut -join ''))
      }
      continue
    } else {
      if($inTable){ $html += "</table>"; $inTable=$false; $headerDone=$false }
      if($line -eq ""){ $html += "<br/>" } else { $html += ("<div>{0}</div>" -f $line) }
    }
  }
  if($inTable){ $html += "</table>" }
  $html += "</body></html>"
  $html | Set-Content -Path $HtmlOutPath -Encoding UTF8
  Write-Host "HTML report saved to: $HtmlOutPath"
}

