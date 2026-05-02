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
if not exist "%ROOT%buildOrTest.bat" set "ROOT=%~dp0"
if not "%ROOT%"=="" if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
if not exist "%ROOT%buildOrTest.bat" set "ROOT=%CD%\tests\fafafa.core.simd.cpuinfo\"
if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"

set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"
set "PROG=%ROOT%fafafa.core.simd.cpuinfo.test.lpr"
set "BIN_DIR=%OUTPUT_ROOT%\bin"
set "LIB_ROOT=%OUTPUT_ROOT%\lib"
set "BIN=%BIN_DIR%\fafafa.core.simd.cpuinfo.test.exe"
set "LOG_DIR=%OUTPUT_ROOT%\logs"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "MODE=%FAFAFA_BUILD_MODE%"
if "%MODE%"=="" set "MODE=Release"

set "TARGET_CPU=nativecpu"
set "TARGET_OS=nativeos"
set "UNIT_DIR=%LIB_ROOT%\%TARGET_CPU%-%TARGET_OS%"
set "TARGET_LOG_DIR=%LOG_DIR%\%TARGET_CPU%-%TARGET_OS%"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_ROOT%" mkdir "%LIB_ROOT%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%UNIT_DIR%" mkdir "%UNIT_DIR%"
if not exist "%TARGET_LOG_DIR%" mkdir "%TARGET_LOG_DIR%"

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

:test_args_include_list_suites
if "%NORMALIZED_TEST_ARGS%"=="" exit /b 1
if not "%NORMALIZED_TEST_ARGS:--list=%"=="%NORMALIZED_TEST_ARGS%" exit /b 0
exit /b 1

:test_log_has_suite_list
findstr /c:"Available suites:" "%TEST_LOG%" >nul 2>nul
if errorlevel 1 exit /b 1
findstr /c:"TTestCase_" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 exit /b 0
exit /b 1

:test_log_has_failure_markers
findstr /r /c:"Number of failures:[ ]*[1-9][0-9]*" /c:"Number of errors:[ ]*[1-9][0-9]*" /c:"Time:.* E:[1-9][0-9]*" /c:"Time:.* F:[1-9][0-9]*" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 exit /b 0
findstr /c:"Some tests failed!" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 exit /b 0
exit /b 1

:resolve_fpc_exe_from_root
set "FPC_SEARCH_ROOT=%~1"
if "%FPC_SEARCH_ROOT%"=="" exit /b 1
if not exist "%FPC_SEARCH_ROOT%\fpc" exit /b 1
for /d %%V in ("%FPC_SEARCH_ROOT%\fpc\*") do (
  if exist "%%~fV\bin\%TARGET_CPU%-%TARGET_OS%\fpc.exe" (
    set "FPC_EXE=%%~fV\bin\%TARGET_CPU%-%TARGET_OS%\fpc.exe"
    exit /b 0
  )
  if exist "%%~fV\bin\x86_64-win64\fpc.exe" (
    set "FPC_EXE=%%~fV\bin\x86_64-win64\fpc.exe"
    exit /b 0
  )
  if exist "%%~fV\bin\i386-win32\fpc.exe" (
    set "FPC_EXE=%%~fV\bin\i386-win32\fpc.exe"
    exit /b 0
  )
)
exit /b 1

:resolve_fpc_exe
set "FPC_RESOLVE_ERROR="
set "FPC_EXE=%FPC_BIN%"
if "%FPC_EXE%"=="" set "FPC_EXE=%FPC%"
if not "%FPC_EXE%"=="" (
  if exist "%FPC_EXE%" exit /b 0
  for /f "delims=" %%P in ('where "%FPC_EXE%" 2^>nul') do (
    set "FPC_EXE=%%~fP"
    exit /b 0
  )
  if not "%FPC_BIN%%FPC%"=="" (
    set "FPC_RESOLVE_ERROR=requested FPC compiler not found: %FPC_EXE%"
    exit /b 1
  )
)
for /f "delims=" %%P in ('where fpc.exe 2^>nul') do (
  set "FPC_EXE=%%~fP"
  exit /b 0
)
for /f "delims=" %%P in ('where fpc 2^>nul') do (
  set "FPC_EXE=%%~fP"
  exit /b 0
)
if defined ProgramFiles (
  call :resolve_fpc_exe_from_root "%ProgramFiles%\Lazarus"
  if not errorlevel 1 exit /b 0
)
if defined ProgramW6432 (
  call :resolve_fpc_exe_from_root "%ProgramW6432%\Lazarus"
  if not errorlevel 1 exit /b 0
)
call :resolve_fpc_exe_from_root "C:\Program Files\Lazarus"
if not errorlevel 1 exit /b 0
call :resolve_fpc_exe_from_root "C:\Program Files (x86)\Lazarus"
if not errorlevel 1 exit /b 0
call :resolve_fpc_exe_from_root "C:\lazarus"
if not errorlevel 1 exit /b 0
call :resolve_fpc_exe_from_root "C:\Lazarus"
if not errorlevel 1 exit /b 0
set "FPC_RESOLVE_ERROR=fpc compiler not found; tried FPC_BIN/FPC, PATH, and common Lazarus roots"
exit /b 1

:populate_target_triplet
for /f "delims=" %%I in ('"%FPC_EXE%" -iTP 2^>nul') do if not defined TARGET_CPU_QUERY set "TARGET_CPU_QUERY=%%I"
if defined TARGET_CPU_QUERY set "TARGET_CPU=%TARGET_CPU_QUERY%"
for /f "delims=" %%I in ('"%FPC_EXE%" -iTO 2^>nul') do if not defined TARGET_OS_QUERY set "TARGET_OS_QUERY=%%I"
if defined TARGET_OS_QUERY set "TARGET_OS=%TARGET_OS_QUERY%"
set "UNIT_DIR=%LIB_ROOT%\%TARGET_CPU%-%TARGET_OS%"
set "TARGET_LOG_DIR=%LOG_DIR%\%TARGET_CPU%-%TARGET_OS%"
if not exist "%UNIT_DIR%" mkdir "%UNIT_DIR%"
if not exist "%TARGET_LOG_DIR%" mkdir "%TARGET_LOG_DIR%"
set "TARGET_CPU_QUERY="
set "TARGET_OS_QUERY="
exit /b 0

:clean
echo [CLEAN] Removing %BIN_DIR%, %LIB_ROOT%, %LOG_DIR%
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_ROOT%" rmdir /s /q "%LIB_ROOT%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0

:build
if /I "%MODE%"=="Debug" (
  set "FPC_MODE_FLAGS=-O1 -g -gl -dDEBUG"
) else (
  set "MODE=Release"
  set "FPC_MODE_FLAGS=-O2 -gl"
)
echo [BUILD] Program: %PROG% (mode=%MODE%, output_root=%OUTPUT_ROOT%)
echo. > "%BUILD_LOG%"
call :resolve_fpc_exe
if errorlevel 1 (
  echo [BUILD] FAILED ^(%FPC_RESOLVE_ERROR%^)> "%BUILD_LOG%"
  type "%BUILD_LOG%"
  exit /b 2
)
call :populate_target_triplet
"%FPC_EXE%" -B -Mobjfpc -Sc -Si %FPC_MODE_FLAGS% ^
  -Fu"%ROOT%" -Fu"%ROOT%..\..\src" -Fi"%ROOT%..\..\src" ^
  -FE"%BIN_DIR%" -FU"%UNIT_DIR%" ^
  -o"%BIN%" "%PROG%" > "%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED ^(see %BUILD_LOG%^)
  type "%BUILD_LOG%"
  exit /b 1
)
echo [BUILD] OK
exit /b 0

:check_build_log
findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" "%BUILD_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [CHECK] Found warnings/hints from SIMD units in build log
  type "%BUILD_LOG%"
  exit /b 1
)
echo [CHECK] OK ^(no SIMD-unit warnings/hints^)
exit /b 0

:check
call :build
if errorlevel 1 exit /b 1
call :check_build_log
exit /b %ERRORLEVEL%

:test
call :build
if errorlevel 1 exit /b 1
call :check_build_log
if errorlevel 1 exit /b 1

if not exist "%BIN%" (
  echo [TEST] Missing binary: %BIN%
  exit /b 2
)

echo [TEST] Running: %BIN%%NORMALIZED_TEST_ARGS%
echo. > "%TEST_LOG%"
"%BIN%" %NORMALIZED_TEST_ARGS% > "%TEST_LOG%" 2>&1
set "TEST_RC=%ERRORLEVEL%"
copy /y "%TEST_LOG%" "%TARGET_LOG_DIR%\test.txt" >nul 2>nul
set "TEST_LIST_SUITES_MODE=0"
call :test_args_include_list_suites
if not errorlevel 1 set "TEST_LIST_SUITES_MODE=1"
set "TEST_LISTING_VALID=0"
call :test_log_has_suite_list
if not errorlevel 1 set "TEST_LISTING_VALID=1"
if not "%TEST_RC%"=="0" (
  if "%TEST_LIST_SUITES_MODE%"=="1" if "%TEST_LISTING_VALID%"=="1" (
    echo [TEST] WARN ^(suite list output present despite rc=%TEST_RC%^)
    set "TEST_RC=0"
  )
)
if "%TEST_LIST_SUITES_MODE%"=="1" if "%TEST_LISTING_VALID%"=="1" (
  type "%TEST_LOG%"
  echo [TEST] OK
  goto :after_test_success
)
if not "%TEST_RC%"=="0" (
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
call :test_log_has_failure_markers
if not errorlevel 1 (
  echo [TEST] FAILED: test runner reports failures/errors ^(see %TEST_LOG%^)
  type "%TEST_LOG%"
  exit /b 1
)
echo [TEST] OK

:after_test_success
findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul
if not errorlevel 1 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks
  type "%TEST_LOG%"
  exit /b 1
)
echo [LEAK] OK
exit /b 0
