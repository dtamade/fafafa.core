@echo off
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "OUTPUT_DIR=%SCRIPT_DIR%bin"
set "EXE=%OUTPUT_DIR%\tests_sync.exe"

:: Ensure runner exists; build if missing
if not exist "%EXE%" (
  echo Test runner not found, building...
  call "%SCRIPT_DIR%BuildOrTest.bat"
)
if not exist "%EXE%" (
  echo Error: test runner still not found: %EXE%
  exit /b 1
)

:: Per-suite timeout in seconds (configurable)
set "SUITE_TIMEOUT=60"

set "SUITES=TTestCase_TMutex TTestCase_TSpinLock TTestCase_TReadWriteLock TTestCase_TAutoLock TTestCase_TSemaphore TTestCase_TEvent TTestCase_TConditionVariable TTestCase_TBarrier"
set "OVERALL_RC=0"

rem ANSI colors (if supported)
for /f "delims=" %%A in ('echo prompt $E^| cmd') do set "ESC=%%A"
set "COL_RESET=%ESC%[0m"
set "COL_DIM=%ESC%[2m"
set "COL_PASS=%ESC%[32m"
set "COL_FAIL=%ESC%[31m"
set "COL_TIME=%ESC%[33m"
set "COL_HEAD=%ESC%[36m"

rem Optional disable colors: set NO_COLOR=1 to turn off ANSI
if defined NO_COLOR (
  set "COL_RESET="
  set "COL_DIM="
  set "COL_PASS="
  set "COL_FAIL="
  set "COL_TIME="
  set "COL_HEAD="
) else (
  if "%ESC%"=="" (
    rem Terminal may not support ANSI; fall back to no color
    set "COL_RESET="
    set "COL_DIM="
    set "COL_PASS="
    set "COL_FAIL="
    set "COL_TIME="
    set "COL_HEAD="
  )
)

set "FMT_WIDTH=34"

echo Preparing global XML results (one-time)...
powershell -NoProfile -Command "Start-Process -FilePath '%EXE%' -ArgumentList @('--format=xml') -PassThru -NoNewWindow -RedirectStandardOutput '%OUTPUT_DIR%\results.xml' -RedirectStandardError '%OUTPUT_DIR%\results.xml.err' | ForEach-Object { $_.WaitForExit() }"

for %%S in (%SUITES%) do (
  set "SUITE=%%S"
  echo.
  echo ===== Running %%S (timeout %SUITE_TIMEOUT%s) =====
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%RunSuite.ps1" -Exe "%EXE%" -Suite "%%S" -TimeoutSec %SUITE_TIMEOUT% -OutDir "%OUTPUT_DIR%"
  set "RC=!ERRORLEVEL!"
  set "STATUS=PASS"
  if !RC! EQU 124 set "STATUS=TIMEOUT"
  if !RC! NEQ 0 if !RC! NEQ 124 set "STATUS=FAIL"
  set "PAD=                                "
  set "LINE=[PASS]                          !SUITE!"
  if /I "!STATUS!"=="PASS" (
    call set "LINE=[PASS]%%PAD:~0,%FMT_WIDTH%%%!SUITE!"
    call echo !COL_PASS!!LINE!!COL_RESET!
  ) else if /I "!STATUS!"=="TIMEOUT" (
    call set "LINE=[TIMEOUT]%%PAD:~0,%FMT_WIDTH%%%!SUITE! (rc=!RC!)"
    call echo !COL_TIME!!LINE!!COL_RESET!
    set "OVERALL_RC=1"
  ) else (
    call set "LINE=[FAIL]%%PAD:~0,%FMT_WIDTH%%%!SUITE! (rc=!RC!)"
    call echo !COL_FAIL!!LINE!!COL_RESET!
    set "OVERALL_RC=1"
    rem Show last lines of the suite log for quick context (safe echo)
    set "LOG_TXT=%OUTPUT_DIR%\suite_%%S.txt"
    if exist "!LOG_TXT!" powershell -NoProfile -Command "Write-Output '--- tail: suite_%%S.txt ---'; Get-Content -LiteralPath '!LOG_TXT!' -Tail 30 | Out-String | Write-Output"
    set "LOG_XMLERR=%OUTPUT_DIR%\suite_%%S.xml.err"
    if exist "!LOG_XMLERR!" powershell -NoProfile -Command "Write-Output '--- tail: suite_%%S.xml.err ---'; Get-Content -LiteralPath '!LOG_XMLERR!' -Tail 30 | Out-String | Write-Output"
  )
)

echo.
call echo !COL_HEAD!===== Summary =====!COL_RESET!
set "PAD=                                "
for %%S in (%SUITES%) do (
  set "LOG=%OUTPUT_DIR%\suite_%%S.txt"
  set "SUM=%OUTPUT_DIR%\suite_%%S.summary"
  set "LAST="
  set "RIGHT=  (stats=n/a)"
  if exist "!LOG!" (
    for /f "usebackq delims=" %%L in ("!LOG!") do set "LAST=%%L"
  ) else (
    set "LAST=<no log>"
  )
  set "STAT_COLOR=%COL_DIM%"
  if exist "!SUM!" (
    set "STATUS_SUM="
    set "RC_SUM="
    set "TESTS_SUM="
    set "FAILS_SUM="
    set "ERRS_SUM="
    for /f "usebackq tokens=1,2 delims==" %%A in ("!SUM!") do (
      if /I "%%~A"=="status"  set "STATUS_SUM=%%~B"
      if /I "%%~A"=="rc"      set "RC_SUM=%%~B"
      if /I "%%~A"=="tests"   set "TESTS_SUM=%%~B"
      if /I "%%~A"=="failures" set "FAILS_SUM=%%~B"
      if /I "%%~A"=="errors"   set "ERRS_SUM=%%~B"
    )
    rem If tests are n/a, fall back to results.xml to fetch accurate numbers
    if /I "!TESTS_SUM!"=="n/a" (
      for /f "usebackq tokens=*" %%Z in (`powershell -NoProfile -Command "$doc=[xml](Get-Content -LiteralPath '%OUTPUT_DIR%\results.xml' -Raw); $n=$doc.TestResults.TestListing.TestSuite.TestSuite | Where-Object { $_.Name -eq '%%S' } | Select-Object -First 1; if($n){ Write-Output ($n.NumberOfRunTests+' '+$n.NumberOfFailures+' '+$n.NumberOfErrors) }"`) do (
        for /f "tokens=1,2,3" %%t in ("%%Z") do (
          set "TESTS_SUM=%%t"
          set "FAILS_SUM=%%u"
          set "ERRS_SUM=%%v"
        )
      )
    )
    set "RIGHT=  (status=!STATUS_SUM!, rc=!RC_SUM!, tests=!TESTS_SUM!, failures=!FAILS_SUM!, errors=!ERRS_SUM!)"
    if /I "!STATUS_SUM!"=="PASS" set "STAT_COLOR=%COL_PASS%"
    if /I "!STATUS_SUM!"=="TIMEOUT" set "STAT_COLOR=%COL_TIME%"
    if /I "!STATUS_SUM!"=="FAIL" set "STAT_COLOR=%COL_FAIL%"
  )
  call set "LEFT=%%S%%PAD:~0,%FMT_WIDTH%%%!LAST!"
  call echo !COL_DIM!!LEFT!!COL_RESET!!STAT_COLOR!!RIGHT!!COL_RESET!
)

rem Generate consolidated tail summary file
set "TAIL_LINES=30"
powershell -NoProfile -Command "$files=Get-ChildItem '%OUTPUT_DIR%' -Filter 'suite_*.txt' | Sort-Object Name; $out=@(); foreach($f in $files){ $out+='===== tail: '+$f.Name+' ====='; if(Test-Path $f.FullName){ $out += (Get-Content -LiteralPath $f.FullName -Tail %TAIL_LINES%); } else{ $out+='missing'; } $out+='' }; Set-Content -LiteralPath '%OUTPUT_DIR%\suites_tail_summary.txt' -Value $out -Encoding UTF8"

rem Generate consolidated JSON summary with totals
powershell -NoProfile -Command "$files=Get-ChildItem '%OUTPUT_DIR%' -Filter 'suite_*.json' | Sort-Object Name; $list=@(); foreach($f in $files){ try{ $j=Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json } catch{}; if($j){ $list += $j } }; function ToIntOrZero([object]$v){ try{ if($null -eq $v){return 0}; $n=[int]$v; return $n }catch{ return 0 } }; $totalTests=0; $totalFails=0; $totalErrs=0; $timeouts=0; $allGreen=$true; foreach($s in $list){ $totalTests += ToIntOrZero $s.tests; $totalFails += ToIntOrZero $s.failures; $totalErrs += ToIntOrZero $s.errors; if($s.status -eq 'TIMEOUT'){ $timeouts++ }; if($s.status -ne 'PASS'){ $allGreen=$false } }; $summary=[ordered]@{ suites=$list; totals=[ordered]@{ total_tests=$totalTests; total_failures=$totalFails; total_errors=$totalErrs; timeouts=$timeouts }; all_green=$allGreen }; ($summary | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath '%OUTPUT_DIR%\suites_summary.json' -Encoding UTF8"

rem Generate Markdown report
powershell -NoProfile -Command "$sum=Get-Content -LiteralPath '%OUTPUT_DIR%\suites_summary.json' -Raw | ConvertFrom-Json; $lines=@('# fafafa.core.sync Test Summary','','## Totals', ('- tests: '+$sum.totals.total_tests), ('- failures: '+$sum.totals.total_failures), ('- errors: '+$sum.totals.total_errors), ('- timeouts: '+$sum.totals.timeouts), ('- all_green: '+$sum.all_green), '', '## Suites', '| Suite | Status | RC | Tests | Failures | Errors | Note |', '|---|---|---:|---:|---:|---:|---|'); foreach($s in $sum.suites){ $lines += ('| '+$s.suite+' | '+$s.status+' | '+$s.rc+' | '+$s.tests+' | '+$s.failures+' | '+$s.errors+' | '+$s.note+' |') }; Set-Content -LiteralPath '%OUTPUT_DIR%\suites_summary.md' -Value $lines -Encoding UTF8"

exit /b %OVERALL_RC%

