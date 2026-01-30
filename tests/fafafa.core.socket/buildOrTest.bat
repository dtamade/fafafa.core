@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Set paths relative to the script's location
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_socket.lpi"
set "TEST_EXECUTABLE=%SCRIPT_DIR%bin\tests_socket.exe"

if /i "%1"=="test" goto BUILD_AND_RUN
if /i "%1"=="test-perf" goto BUILD_AND_RUN_PERF
if /i "%1"=="adv" goto ADV
if /i "%1"=="advanced" goto ADV

if /i "%1"=="" goto USAGE
if "%1"=="/?" goto USAGE
if /i "%1"=="help" goto USAGE

:USAGE
    echo Usage: buildOrTest.bat [build^|test^|test-perf^|adv] [--suite=Name] [extra args]
    echo.
    echo Commands:
    echo   build       Build tests only
    echo   test        Build and run functional tests (plain log to bin\tests_socket.log)
    echo   test-perf   Build and run performance suites (plain log to bin\tests_socket_perf.log)
    echo   adv         Build and run advanced suites (log to bin\tests_socket_adv.log)
    echo.
    echo JUnit output (optional): set environment variable JUNIT=1 ^(optional JUNIT_OUT for path^)
    echo   Example (Windows):
    echo     set JUNIT=1 ^&^& tests\fafafa.core.socket\buildOrTest.bat test
    echo     set JUNIT=1 ^&^& set JUNIT_OUT=D:\reports\socket.junit.xml ^&^& tests\fafafa.core.socket\buildOrTest.bat adv --suite=TTestCase_Socket_Advanced
    echo.
    echo Examples:
    echo   tests\fafafa.core.socket\buildOrTest.bat test --suite=TTestCase_Socket
    echo   tests\fafafa.core.socket\buildOrTest.bat adv --suite=TTestCase_Socket_Advanced
    echo.
    goto END

REM Default: just build
:BUILD_ONLY
    echo Building fafafa.core.socket tests: %PROJECT%...
    call "%LAZBUILD%" "%PROJECT%"
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed with error code %ERRORLEVEL%.
        goto END
    )
    echo.
    echo Build successful.
    echo.
    echo To run tests, call this script with 'test' or 'test-perf'.
    goto END

:BUILD_AND_RUN
    echo Building fafafa.core.socket tests (functional): %PROJECT%...
    call "%LAZBUILD%" "%PROJECT%"
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed with error code %ERRORLEVEL%.
        goto END
    )
    echo.
    shift
    set "LOG=%SCRIPT_DIR%bin\tests_socket.log"
    if defined JUNIT (
        set "JUNIT_FILE=%SCRIPT_DIR%bin\tests_socket.junit.xml"
        if defined JUNIT_OUT set "JUNIT_FILE=%JUNIT_OUT%"
        echo [JUnit] Writing to "%JUNIT_FILE%"
        "%TEST_EXECUTABLE%" --all --progress --format=xml %* > "%JUNIT_FILE%" 2>&1
        set "EXIT=%ERRORLEVEL%"
        for /f "usebackq delims=" %%S in (`findstr /R /C:"<testsuite " "%JUNIT_FILE%"`) do set "SUMMARY=%%S"
        if defined SUMMARY (echo [JUnit] Summary: !SUMMARY!) else (echo [JUnit] Summary: see report "%JUNIT_FILE%")
        echo ExitCode=!EXIT!
        goto END
    )
    echo Running fafafa.core.socket tests...
    echo.
    "%TEST_EXECUTABLE%" --all --progress --format=plain %* > "%LOG%" 2>&1
    set "EXIT=%ERRORLEVEL%"
    for /f "usebackq delims=" %%S in (`findstr /R /C:"OK:" /C:"Failures" /C:"Errors" "%LOG%"`) do set "SUMMARY=%%S"
    if defined SUMMARY (echo Summary: !SUMMARY!) else (echo Summary: see log "%LOG%")
    echo ExitCode=!EXIT!
    if not "!EXIT!"=="0" (
        echo Tests failed. Showing last 50 lines:
        powershell -NoProfile -Command "Get-Content -Tail 50 -Path '%LOG%'"
    )
    goto END

:BUILD_AND_RUN_PERF
    echo Building fafafa.core.socket tests: %PROJECT%...
    call "%LAZBUILD%" "%PROJECT%"
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed with error code %ERRORLEVEL%.
        goto END
    )
    echo.
    echo Running fafafa.core.socket tests (with performance suites)...
    echo.
    set ENABLE_PERF=1
    REM Set safer defaults if not provided via environment
    if not defined PERF_TCP_SHORT_CONN_C set PERF_TCP_SHORT_CONN_C=20
    if not defined PERF_TCP_LONG_CLIENTS set PERF_TCP_LONG_CLIENTS=3
    if not defined PERF_TCP_LONG_ITER set PERF_TCP_LONG_ITER=50
    if not defined PERF_PAYLOAD_SIZE set PERF_PAYLOAD_SIZE=256
    if not defined PERF_ACCEPT_TIMEOUT_MS set PERF_ACCEPT_TIMEOUT_MS=1000
    if not defined PERF_UDP_PACKETS set PERF_UDP_PACKETS=200
    if not defined PERF_UDP_RECV_TIMEOUT_MS set PERF_UDP_RECV_TIMEOUT_MS=10

    shift
    set "PERF_LOG=%SCRIPT_DIR%bin\tests_socket_perf.log"
    if defined JUNIT (
        set "JUNIT_FILE=%SCRIPT_DIR%bin\tests_socket_perf.junit.xml"
        if defined JUNIT_OUT set "JUNIT_FILE=%JUNIT_OUT%"
        echo [PERF][JUnit] Writing to "%JUNIT_FILE%"
        "%TEST_EXECUTABLE%" --suite=TTestCase_Perf --progress --format=xml %* > "%JUNIT_FILE%" 2>&1
        set "PERF_EXIT=%ERRORLEVEL%"
        for /f "usebackq delims=" %%S in (`findstr /R /C:"<testsuite " "%JUNIT_FILE%"`) do set "PERF_SUMMARY=%%S"
        if defined PERF_SUMMARY (echo [PERF][JUnit] Summary: !PERF_SUMMARY!) else (echo [PERF][JUnit] Summary: see report "%JUNIT_FILE%")
        echo [PERF] ExitCode=!PERF_EXIT!
        goto END
    )
    "%TEST_EXECUTABLE%" --suite=TTestCase_Perf --progress --format=plain %* > "%PERF_LOG%" 2>&1
    set "PERF_EXIT=%ERRORLEVEL%"
    for /f "usebackq delims=" %%S in (`findstr /R /C:"OK:" /C:"Failures" /C:"Errors" "%PERF_LOG%"`) do set "PERF_SUMMARY=%%S"
    if defined PERF_SUMMARY (echo [PERF] Summary: !PERF_SUMMARY!) else (echo [PERF] Summary: see log "%PERF_LOG%")
    echo [PERF] ExitCode=!PERF_EXIT!
    if not "!PERF_EXIT!"=="0" (
        echo [PERF] Tests failed. Showing last 50 lines:
        powershell -NoProfile -Command "Get-Content -Tail 50 -Path '%PERF_LOG%'"
    )
    goto END

:END
endlocal
goto :EOF

:BUILD_AND_RUN_ADV
    echo Building fafafa.core.socket tests (ADVANCED): %PROJECT%...
    setlocal
    set EXTRA_OPTS=--build-mode=Default --ws= --skip-dependencies
    set DEFINE_SWITCH=-dFAFAFA_SOCKET_ADVANCED
    call "%LAZBUILD%" %DEFINE_SWITCH% %PROJECT%
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build (ADVANCED) failed with error code %ERRORLEVEL%.
        endlocal
        goto END
    )
    endlocal
    echo.
    echo Running fafafa.core.socket tests (ADVANCED)...
    echo.
    "%TEST_EXECUTABLE%" --all --progress --format=plain
    goto END


:ADV
    set "ADV_LPI=%SCRIPT_DIR%tests_socket_advanced.lpi"
    set "ADV_EXE=%SCRIPT_DIR%bin\tests_socket_adv.exe"
    echo [ADV] Using LAZBUILD: "%LAZBUILD%"
    echo [ADV] Building: "%ADV_LPI%"
    call "%LAZBUILD%" "%ADV_LPI%"
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [ADV] Build failed with error code %ERRORLEVEL%.
        goto END
    )
    if not exist "%ADV_EXE%" (
        echo [ADV] Error: built executable not found at "%ADV_EXE%".
        goto END
    )
    echo.
    shift
    set "ADV_LOG=%SCRIPT_DIR%bin\tests_socket_adv.log"
    if defined JUNIT (
        set "JUNIT_FILE=%SCRIPT_DIR%bin\tests_socket_adv.junit.xml"
        if defined JUNIT_OUT set "JUNIT_FILE=%JUNIT_OUT%"
        echo [ADV][JUnit] Writing to "%JUNIT_FILE%"
        "%ADV_EXE%" --all --progress --format=xml %* > "%JUNIT_FILE%" 2>&1
        set "ADV_EXIT=%ERRORLEVEL%"
        for /f "usebackq delims=" %%S in (`findstr /R /C:"<testsuite " "%JUNIT_FILE%"`) do set "ADV_SUMMARY=%%S"
        if defined ADV_SUMMARY (echo [ADV][JUnit] Summary: !ADV_SUMMARY!) else (echo [ADV][JUnit] Summary: see report "%JUNIT_FILE%")
        echo [ADV] ExitCode=!ADV_EXIT!
        goto END
    )
    echo [ADV] Running: "%ADV_EXE%" --all --progress --format=plain %*
    "%ADV_EXE%" --all --progress --format=plain %* > "%ADV_LOG%" 2>&1
    set "ADV_EXIT=%ERRORLEVEL%"
    for /f "usebackq delims=" %%S in (`findstr /R /C:"OK:" /C:"Failures" /C:"Errors" "%ADV_LOG%"`) do set "ADV_SUMMARY=%%S"
    if defined ADV_SUMMARY (echo [ADV] Summary: !ADV_SUMMARY!) else (echo [ADV] Summary: see log "%ADV_LOG%")
    echo [ADV] ExitCode=!ADV_EXIT!
    if not "!ADV_EXIT!"=="0" (
        echo [ADV] Tests failed. Showing last 50 lines:
        powershell -NoProfile -Command "Get-Content -Tail 50 -Path '%ADV_LOG%'"
    )
    goto END

endlocal
