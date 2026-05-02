@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift

set "NORMALIZED_TEST_ARGS="
:collect_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--list-suites" (
  set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! --list"
) else (
  set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! %~1"
)
shift
goto :collect_args
:args_done

set "ROOT=%SIMD_SCRIPT_ROOT%"
if "%ROOT%"=="" set "ROOT=%~dp0"
if not "%ROOT%"=="" if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
if not exist "%ROOT%buildOrTest.bat" set "ROOT=%CD%\tests\fafafa.core.simd.cpuinfo.x86\"
if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
for %%I in ("%ROOT%..\..") do set "REPO_ROOT=%%~fI"
if not "%REPO_ROOT%"=="" if not "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT%\"
set "PROJ=%ROOT%fafafa.core.simd.cpuinfo.x86.test.lpi"
set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"
set "BIN_DIR=%OUTPUT_ROOT%\bin"
set "LIB_DIR=%OUTPUT_ROOT%\lib"
set "BIN=%BIN_DIR%\fafafa.core.simd.cpuinfo.x86.test.exe"
set "EXPECTED_BIN=%BIN%"
set "LOG_DIR=%OUTPUT_ROOT%\logs"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "MODE=%FAFAFA_BUILD_MODE%"
if "%MODE%"=="" set "MODE=Release"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "LAZBUILD_EXE=%LAZBUILD%"
if "%LAZBUILD_EXE%"=="" set "LAZBUILD_EXE=%ROOT%..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD_EXE%" set "LAZBUILD_EXE=%ProgramFiles%\Lazarus\lazbuild.exe"
if not exist "%LAZBUILD_EXE%" set "LAZBUILD_EXE=lazbuild"
if not exist "%LAZBUILD_EXE%" set "LAZBUILD_EXE=lazbuild"

if /I "%ACTION%"=="debug" set "MODE=Debug"
if /I "%ACTION%"=="release" set "MODE=Release"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="check" goto :check
if /I "%ACTION%"=="test" goto :test
if /I "%ACTION%"=="debug" goto :test
if /I "%ACTION%"=="release" goto :test

echo Usage: %~nx0 [clean^|build^|check^|test^|debug^|release] [test-args...]
exit /b 2

:build_log_has_fatal
findstr /c:"Fatal:" /c:"returned an error exitcode" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 exit /b 0
exit /b 1

:build_log_has_link
findstr /c:"(9015) Linking" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 exit /b 0
exit /b 1

:build_log_has_compiled
findstr /c:"(1008)" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 exit /b 0
exit /b 1

:try_set_resolved_build_bin
set "RESOLVED_BUILD_BIN_CANDIDATE=%~1"
if "%RESOLVED_BUILD_BIN_CANDIDATE%"=="" exit /b 1
if not exist "%RESOLVED_BUILD_BIN_CANDIDATE%" exit /b 1
for %%F in ("%RESOLVED_BUILD_BIN_CANDIDATE%") do set "RESOLVED_BUILD_BIN=%%~fF"
exit /b 0

:resolve_binary_from_build_log
set "RESOLVED_BUILD_BIN="
set "BUILD_LINK_LINE="
set "BUILD_LINK_PATH="
for /f "delims=" %%L in ('findstr /c:"(9015) Linking" "%BUILD_LOG%" 2^>nul') do set "BUILD_LINK_LINE=%%L"
if not defined BUILD_LINK_LINE exit /b 1
set "BUILD_LINK_PATH=!BUILD_LINK_LINE:* Linking =!"
if "!BUILD_LINK_PATH!"=="!BUILD_LINK_LINE!" exit /b 1
set "BUILD_LINK_PATH=!BUILD_LINK_PATH:"=!"
call :try_set_resolved_build_bin "!BUILD_LINK_PATH!"
if not errorlevel 1 exit /b 0
call :try_set_resolved_build_bin "%ROOT%!BUILD_LINK_PATH!"
if not errorlevel 1 exit /b 0
call :try_set_resolved_build_bin "%OUTPUT_ROOT%!BUILD_LINK_PATH!"
if not errorlevel 1 exit /b 0
call :try_set_resolved_build_bin "%REPO_ROOT%!BUILD_LINK_PATH!"
if not errorlevel 1 exit /b 0
call :try_set_resolved_build_bin "%CD%\!BUILD_LINK_PATH!"
if not errorlevel 1 exit /b 0
exit /b 1

:normalize_built_binary
set "BIN=%EXPECTED_BIN%"
if exist "%EXPECTED_BIN%" exit /b 0
call :resolve_binary_from_build_log
if errorlevel 1 exit /b 0
if not defined RESOLVED_BUILD_BIN exit /b 0
if /I "%RESOLVED_BUILD_BIN%"=="%EXPECTED_BIN%" exit /b 0
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
copy /y "%RESOLVED_BUILD_BIN%" "%EXPECTED_BIN%" >nul
if errorlevel 1 exit /b 1
echo [BUILD] Binary normalized: %RESOLVED_BUILD_BIN% -^> %EXPECTED_BIN%
set "BIN=%EXPECTED_BIN%"
exit /b 0

:resolve_test_binary
set "BIN=%EXPECTED_BIN%"
if exist "%BIN%" exit /b 0
call :normalize_built_binary
if exist "%EXPECTED_BIN%" (
  set "BIN=%EXPECTED_BIN%"
  exit /b 0
)
call :resolve_binary_from_build_log
if errorlevel 1 exit /b 1
if not defined RESOLVED_BUILD_BIN exit /b 1
if not exist "%RESOLVED_BUILD_BIN%" exit /b 1
set "BIN=%RESOLVED_BUILD_BIN%"
exit /b 0

:clean
echo [CLEAN] Removing bin, lib, logs
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
set "LAZARUS_MODE=%MODE%"
if /I "%LAZARUS_MODE%"=="Release" set "LAZARUS_MODE=Default"
echo [BUILD] Project: %PROJ% (mode=%MODE%, lazarus-mode=%LAZARUS_MODE%)
echo. > "%BUILD_LOG%"
call "%LAZBUILD_EXE%" --build-mode=%LAZARUS_MODE% --build-all "%PROJ%" > "%BUILD_LOG%" 2>&1
set "BUILD_RC=%ERRORLEVEL%"
set "BIN=%EXPECTED_BIN%"
set "RESOLVED_BUILD_BIN="
call :normalize_built_binary
set "BUILD_FATAL=0"
call :build_log_has_fatal
if not errorlevel 1 set "BUILD_FATAL=1"
set "BUILD_LINKED=0"
call :build_log_has_link
if not errorlevel 1 set "BUILD_LINKED=1"
set "BUILD_COMPILED=0"
call :build_log_has_compiled
if not errorlevel 1 set "BUILD_COMPILED=1"
if not "%BUILD_RC%"=="0" (
  if "%BUILD_FATAL%"=="0" (
    if exist "%BIN%" goto :build_warn_nonzero_usable_artifact
    if defined RESOLVED_BUILD_BIN if exist "%RESOLVED_BUILD_BIN%" (
      set "BIN=!RESOLVED_BUILD_BIN!"
      goto :build_warn_nonzero_usable_artifact
    )
  )
  goto :build_failed_from_log
)
if not exist "%BIN%" (
  if defined RESOLVED_BUILD_BIN if exist "%RESOLVED_BUILD_BIN%" (
    set "BIN=!RESOLVED_BUILD_BIN!"
    goto :build_warn_zero_usable_artifact
  )
  goto :build_failed_missing_binary
)
echo [BUILD] OK
exit /b 0

:build_warn_nonzero_usable_artifact
echo [BUILD] WARN ^(lazbuild rc=%BUILD_RC% but artifact/build log are usable^)
if /I not "%BIN%"=="%EXPECTED_BIN%" echo [BUILD] WARN ^(resolved linked binary path: %BIN%^)
echo [BUILD] OK
exit /b 0

:build_warn_zero_usable_artifact
echo [BUILD] WARN ^(linked artifact is usable but expected binary path probe missed: %EXPECTED_BIN%^)
if /I not "%BIN%"=="%EXPECTED_BIN%" echo [BUILD] WARN ^(resolved linked binary path: %BIN%^)
echo [BUILD] OK
exit /b 0

:build_failed_from_log
echo [BUILD] FAILED ^(see %BUILD_LOG%^)
type "%BUILD_LOG%"
exit /b 1

:build_failed_missing_binary
echo [BUILD] FAILED ^(expected binary missing: %EXPECTED_BIN%^)
if defined RESOLVED_BUILD_BIN echo [BUILD] Resolved linked binary candidate: %RESOLVED_BUILD_BIN%
type "%BUILD_LOG%"
exit /b 1

:check
call :build
if errorlevel 1 exit /b 1
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units or cpuinfo.x86 test sources in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK (no SIMD-unit and cpuinfo.x86-test warnings/hints)
exit /b 0

:test
call :build
if errorlevel 1 exit /b 1
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas.*Hint:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Warning:" /c:"fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr.*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units or cpuinfo.x86 test sources in build log
  type "%BUILD_LOG%"
  exit /b 1
)

if not exist "%BIN%" (
  call :resolve_test_binary
)
if not exist "%BIN%" (
  echo [TEST] Missing binary: %EXPECTED_BIN%
  if defined RESOLVED_BUILD_BIN echo [TEST] Resolved linked binary candidate: %RESOLVED_BUILD_BIN%
  exit /b 2
)
if /I not "%BIN%"=="%EXPECTED_BIN%" echo [TEST] Resolved binary fallback: %BIN%

echo [TEST] Running: %BIN%%NORMALIZED_TEST_ARGS%
echo. > "%TEST_LOG%"
"%BIN%" %NORMALIZED_TEST_ARGS% > "%TEST_LOG%" 2>&1
if errorlevel 1 (
  echo [TEST] FAILED ^(see %TEST_LOG%^)
  type "%TEST_LOG%"
  exit /b 1
)
findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [TEST] FAILED: unsupported test argument ^(see %TEST_LOG%^)
  type "%TEST_LOG%"
  exit /b 2
)
findstr /r /c:"Number of failures:[ ]*[1-9][0-9]*" /c:"Number of errors:[ ]*[1-9][0-9]*" /c:"Time:.* E:[1-9][0-9]*" /c:"Time:.* F:[1-9][0-9]*" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [TEST] FAILED: test runner reports failures/errors ^(see %TEST_LOG%^)
  type "%TEST_LOG%"
  exit /b 1
)
echo [TEST] OK

findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks
  type "%TEST_LOG%"
  exit /b 1
)
echo [LEAK] OK
exit /b 0
