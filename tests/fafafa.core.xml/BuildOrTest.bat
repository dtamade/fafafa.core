@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=tests_xml.lpi"
set "PROJECT_PATH=%SCRIPT_DIR%%PROJECT%"
set "TEST_EXECUTABLE=%SCRIPT_DIR%bin\tests_xml.exe"

if not exist "%SCRIPT_DIR%bin" mkdir "%SCRIPT_DIR%bin" >nul 2>nul
if not exist "%SCRIPT_DIR%bin\junit" mkdir "%SCRIPT_DIR%bin\junit" >nul 2>nul

echo Building project: %PROJECT%...
if not exist "%LAZBUILD%" (
  echo [BuildOrTest] lazbuild wrapper not found: %LAZBUILD%
  goto END
)
call "%LAZBUILD%" "%PROJECT_PATH%"
set "BUILD_EXIT=%ERRORLEVEL%"
if not "%BUILD_EXIT%"=="0" (
  echo.
  echo Build failed with error code %BUILD_EXIT%.
  goto END
)

echo.
echo [OK] Build successful.
echo.

if /i "%1"=="test" (
  echo [Run] plain with progress
  set FAFAFA_TEST_SILENT_REG=1
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%support\run_with_timeout.ps1" -Exe "%TEST_EXECUTABLE%" -ArgString "--all --format=plain -p" -TimeoutSec 300 -RedirectStderr "%SCRIPT_DIR%bin\heaptrc.txt"
  set "TEST_EXIT=%ERRORLEVEL%"
  if not "!TEST_EXIT!"=="0" echo WARN: test runner exit code !TEST_EXIT!
) else if /i "%1"=="test-notiming" (
  echo [Run] plainnotiming
  set FAFAFA_TEST_SILENT_REG=1
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%support\run_with_timeout.ps1" -Exe "%TEST_EXECUTABLE%" -ArgString "--all --format=plainnotiming" -TimeoutSec 300 -RedirectStderr "%SCRIPT_DIR%bin\heaptrc.txt"
  set "TEST_EXIT=%ERRORLEVEL%"
  if not "!TEST_EXIT!"=="0" echo WARN: test runner exit code !TEST_EXIT!
) else if /i "%1"=="test-xml" (
  set "XML_OUT=%SCRIPT_DIR%bin\junit\tests_xml.results.xml"
  echo [Run] xml to !XML_OUT!
  set FAFAFA_TEST_SILENT_REG=1
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%support\run_with_timeout.ps1" -Exe "%TEST_EXECUTABLE%" -ArgString "--all --format=xml --file=!XML_OUT!" -TimeoutSec 300 -RedirectStderr "%SCRIPT_DIR%bin\heaptrc.txt"
  set "TEST_EXIT=%ERRORLEVEL%"
  if exist "!XML_OUT!" (
    echo [OK] xml written: !XML_OUT!
  ) else (
    echo [FAIL] xml not written: !XML_OUT!
  )
) else if /i "%1"=="test-junit" (
  set "XML_OUT=%SCRIPT_DIR%bin\junit\tests_xml.junit.xml"
  echo [Run] junit to !XML_OUT!
  set FAFAFA_TEST_SILENT_REG=1
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%support\run_with_timeout.ps1" -Exe "%TEST_EXECUTABLE%" -ArgString "--all --format=junit --file=!XML_OUT!" -TimeoutSec 180 -RedirectStderr "%SCRIPT_DIR%bin\heaptrc.txt"
  set "TEST_EXIT=%ERRORLEVEL%"
  if exist "!XML_OUT!" (
    echo [OK] junit written: !XML_OUT!
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%support\junit_summary.ps1" -Path "!XML_OUT!"
  ) else (
    echo [FAIL] junit not written: !XML_OUT!
  )
) else if /i "%1"=="test-plainlog" (
  set "LOG_OUT=%SCRIPT_DIR%bin\tests_xml.results.txt"
  echo [Run] plain with progress to !LOG_OUT!
  set FAFAFA_TEST_SILENT_REG=1
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%support\run_with_timeout.ps1" -Exe "%TEST_EXECUTABLE%" -ArgString "--all --format=plain -p" -TimeoutSec 300 -RedirectStderr "%SCRIPT_DIR%bin\heaptrc.txt" > "!LOG_OUT!"
  set "TEST_EXIT=%ERRORLEVEL%"
  if exist "!LOG_OUT!" (
    echo [OK] log written: !LOG_OUT!
  ) else (
    echo [FAIL] log not written: !LOG_OUT!
  )
) else (
  echo Usage:
  echo   BuildOrTest.bat test            ^(build + run, format=plain^)
  echo   BuildOrTest.bat test-notiming   ^(build + run, format=plainnotiming^)
  echo   BuildOrTest.bat test-xml        ^(build + run, format=xml to bin\junit\...^)
  echo   BuildOrTest.bat test-junit      ^(build + run, format=junit to bin\junit\...^)
  echo   BuildOrTest.bat test-plainlog   ^(build + run, plain with progress to bin\tests_xml.results.txt^)
)

:END
endlocal

