@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Always execute from script directory
cd /d "%~dp0"

if "%1"=="smoke" goto :SMOKE

REM 默认执行全量测试
set MODE=%1
if /I "%MODE%"=="" set MODE=test
REM jump to the main section (single-pass)
goto :MAIN

:MAIN
REM jump to unified main section
goto :RUN_MAIN

:SMOKE
rem 仅执行核心用例集以加速反馈（约 1-3s）
set LAZBUILD_EXE=
rem 使用 FPCUnit 测试类名（与 --suite 对应）
set SUITES=TTestCase_TTaskScheduler_Basic TTestCase_TTaskScheduler_Order TTestCase_TTaskScheduler_Metrics TTestCase_TThreadPool_KeepAlive

echo Building project: tests_thread.lpi (smoke)
cd /d %~dp0

if not defined LAZBUILD_EXE (
  set LAZBUILD_EXE=D:\devtools\lazarus\trunk\lazarus\lazbuild.exe
)
"%LAZBUILD_EXE%" "tests_thread.lpi" -B
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

echo Running smoke tests...
set EXE="%~dp0..\..\bin\tests_thread.exe"
set FAIL=0
for %%S in (%SUITES%) do (
  echo( & echo === Running suite: %%S ===
  %EXE% --suite=%%S --format=plain -u
  if errorlevel 1 set FAIL=1
)
if %FAIL% NEQ 0 (
  echo One or more smoke suites failed.
  exit /b 1
)
echo All smoke suites passed.

:RUN_MAIN

@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"

REM Always work from the test directory for consistent relative paths
pushd "%SCRIPT_DIR%" >nul

set "PROJECT=tests_thread.lpi"
set "FINAL_RC=0"

REM Compute absolute paths for executables
set "TESTS_BIN_EXE=%SCRIPT_DIR%bin\tests_thread.exe"

REM Resolve repository root absolute path
pushd "%SCRIPT_DIR%..\.." >nul
set "ROOT_DIR=%CD%\"
popd >nul
set "ROOT_BIN_EXE=%ROOT_DIR%bin\tests_thread.exe"

REM Clean artifacts before build (iron rule)
if exist "%SCRIPT_DIR%bin\tests_thread.exe" del /f /q "%SCRIPT_DIR%bin\tests_thread.exe" >nul 2>&1
if exist "%SCRIPT_DIR%lib" rmdir /s /q "%SCRIPT_DIR%lib" >nul 2>&1
if exist "%ROOT_DIR%bin\tests_thread.exe" del /f /q "%ROOT_DIR%bin\tests_thread.exe" >nul 2>&1


echo Building project: %PROJECT%...
set "BUILD_LOG=%SCRIPT_DIR%build.log"
if exist "%BUILD_LOG%" del /f /q "%BUILD_LOG%" >nul 2>&1
call "%LAZBUILD%" "%PROJECT%" > "%BUILD_LOG%" 2>&1
set "BUILD_RC=%ERRORLEVEL%"
rem Echo the build log for visibility
type "%BUILD_LOG%"

if %BUILD_RC% NEQ 0 goto BUILD_ERROR

rem Additional guard: detect fatal compile errors in log even if RC==0
findstr /I /C:"Fatal: (1018) Compilation aborted" /C:"Error: (lazbuild) Failed compiling of project" /C:"returned an error exitcode" "%BUILD_LOG%" >nul
if %ERRORLEVEL% EQU 0 goto BUILD_FAILED_LOG

echo(
echo Build successful.
echo(

if /i "%MODE%"=="test" (
    echo Running tests...
    set "EXE="
    if exist "%ROOT_BIN_EXE%" set "EXE=%ROOT_BIN_EXE%"
    if not defined EXE if exist "%TESTS_BIN_EXE%" set "EXE=%TESTS_BIN_EXE%"
    if not defined EXE (
        echo ERROR: Test executable not found:
        echo   %TESTS_BIN_EXE%
        echo   %ROOT_BIN_EXE%
        goto END
    )
    echo Using executable: !EXE!
    rem === logging + timeout ===
    if not defined FAF_TEST_TIMEOUT_SEC set FAF_TEST_TIMEOUT_SEC=180
    for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "DATETIME=%%i"
    if not defined DATETIME set "DATETIME=unknown"
    set "LOG_DIR=%SCRIPT_DIR%logs"
    if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
    set "TEST_LOG=!LOG_DIR!\run_!DATETIME!.log"
    echo Writing test output to: !TEST_LOG!
    set "TEST_ERR=!LOG_DIR!\run_!DATETIME!.err.log"
    powershell -NoProfile -Command "& { $p=Start-Process -FilePath '!EXE!' -ArgumentList '--all','--format=plain','--progress','-u' -NoNewWindow -PassThru -RedirectStandardOutput '!TEST_LOG!' -RedirectStandardError '!TEST_ERR!'; $ok=$p.WaitForExit([int]$env:FAF_TEST_TIMEOUT_SEC*1000); if(-not $ok){ try{$p.Kill()}catch{}; exit 101 } else { exit $p.ExitCode } }"
    set "FINAL_RC=%ERRORLEVEL%"
    rem === slow test report (top 10) ===
    set "PS_LOG=!TEST_LOG!"
    if exist "!TEST_LOG!" powershell -NoProfile -Command "& { $lines=Get-Content $env:PS_LOG; $re='^\s*(\d+\.\d{3})\s+(\S+)'; $items=@(); foreach($l in $lines){ if($l -match $re){ $items+=[pscustomobject]@{Time=[double]$matches[1]; Name=$matches[2] } } }; $items | Sort-Object Time -Descending | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Output }"
) else if /i "%MODE%"=="test-quick" (
    echo Running quick sanity subset...
    set "EXE="
    if exist "%ROOT_BIN_EXE%" set "EXE=%ROOT_BIN_EXE%"
    if not defined EXE if exist "%TESTS_BIN_EXE%" set "EXE=%TESTS_BIN_EXE%"
    if not defined EXE (
        echo ERROR: Test executable not found:
        echo   %TESTS_BIN_EXE%
        echo   %ROOT_BIN_EXE%
        goto END
    )
    echo Using executable: !EXE!
    rem Run a minimal subset sequentially (runner only respects one --suite)
    set "SUITES=TTestCase_Global TTestCase_TThreadPoolPolicy TTestCase_TThreadPoolPolicy_More TTestCase_TThreadPool_KeepAlive TTestCase_TChannel_Fairness"
    set FAIL=0
    for %%S in (!SUITES!) do (
        echo( & echo === Running suite: %%S ===
        "!EXE!" --suite=%%S --format=plain -u
        if ERRORLEVEL 1 set FAIL=1
    )
    if !FAIL! NEQ 0 (
        echo One or more quick suites failed.
        set "FINAL_RC=1"
        goto END
    )
    echo All quick suites passed.
) else if /i "%MODE%"=="test-full" (
    echo Running full tests with heap trace...
    set "EXE="
    if exist "%ROOT_BIN_EXE%" set "EXE=%ROOT_BIN_EXE%"
    if not defined EXE if exist "%TESTS_BIN_EXE%" set "EXE=%TESTS_BIN_EXE%"
    if not defined EXE (
        echo ERROR: Test executable not found:
        echo   %TESTS_BIN_EXE%
        echo   %ROOT_BIN_EXE%
        set "FINAL_RC=1"
        goto END
    )
    rem Prepare logs directory and timestamped heap log file
    set "LOG_DIR=%SCRIPT_DIR%logs"
    if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
    for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "DATETIME=%%i"
    if not defined DATETIME set "DATETIME=unknown"
    set "HEAP_LOG=!LOG_DIR!\heaptrc_full_!DATETIME!.log"
    set "HEAPTRC=!HEAP_LOG!"
    if not defined FAF_TEST_TIMEOUT_SEC set FAF_TEST_TIMEOUT_SEC=180
    set "TEST_LOG=!LOG_DIR!\run_full_!DATETIME!.log"
    echo Using executable: !EXE!
    echo Heap trace will be written to: !HEAP_LOG!
    echo Writing test output to: !TEST_LOG!
    set "TEST_ERR=!LOG_DIR!\run_full_!DATETIME!.err.log"
    powershell -NoProfile -Command "& { $p=Start-Process -FilePath '!EXE!' -ArgumentList '--all','--format=plain','--progress','-u' -NoNewWindow -PassThru -RedirectStandardOutput '!TEST_LOG!' -RedirectStandardError '!TEST_ERR!'; $ok=$p.WaitForExit([int]$env:FAF_TEST_TIMEOUT_SEC*1000); if(-not $ok){ try{$p.Kill()}catch{}; exit 101 } else { exit $p.ExitCode } }"
    set "FINAL_RC=!ERRORLEVEL!"
    rem === slow test report (top 10) ===
    set "PS_LOG=!TEST_LOG!"
    if exist "!TEST_LOG!" powershell -NoProfile -Command "& { $lines=Get-Content $env:PS_LOG; $re='^\s*(\d+\.\d{3})\s+(\S+)'; $items=@(); foreach($l in $lines){ if($l -match $re){ $items+=[pscustomobject]@{Time=[double]$matches[1]; Name=$matches[2] } } }; $items | Sort-Object Time -Descending | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Output }"
) else (
    echo To run tests, call this script with 'test', 'test-quick' or 'test-full' parameter.
)

goto END

:BUILD_ERROR
@echo Build failed with error code %BUILD_RC%.
set "FINAL_RC=%BUILD_RC%"
goto END

:BUILD_FAILED_LOG
@echo Build failed (detected via log patterns). Not running stale executable.
set "FINAL_RC=1"
goto END

:END

REM Ensure final return code reflects build/test outcome
exit /b %FINAL_RC%

popd >nul
endlocal
