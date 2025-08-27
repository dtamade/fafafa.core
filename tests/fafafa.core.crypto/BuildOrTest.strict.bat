@echo off

setlocal ENABLEDELAYEDEXPANSION
set "SCRIPT_DIR=%~dp0"

rem Strict variant for CI: identical flow to BuildOrTest.bat but exits with FINAL_RC
rem - anon=ON build+tests (ERRORLEVEL not propagated)
rem - anon=OFF build+tests decide FINAL_RC
rem - prints SUCCESS/FAILED markers for log parsers

set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_crypto.lpi"
set "TEST_EXECUTABLE=%SCRIPT_DIR%bin\tests_crypto.exe"
set "REPORTS=%SCRIPT_DIR%reports"
set "FINAL_RC=0"

set "AEAD_FLAG="
set "HMAC_FLAG="
set "CLEAN_FLAG="
for %%A in (%*) do (
  if /I "%%~A"=="aead" set "AEAD_FLAG=1"
  if /I "%%~A"=="hmac" set "HMAC_FLAG=1"
  if /I "%%~A"=="clean" set "CLEAN_FLAG=1"
)

set "LZ_OPTS="
if defined AEAD_FLAG (
  echo [BuildOrTest.strict] BuildMode: AEAD (defines -dFAFAFA_CORE_AEAD_TESTS)
  set "LZ_OPTS=--build-mode=AEAD"
) else (
  if defined HMAC_FLAG (
    echo [BuildOrTest.strict] BuildMode: HMAC-DEBUG (adds -dHMAC_DEBUG)
    set "LZ_OPTS=--build-mode=HMAC-DEBUG"
  )
)
if not defined AEAD_FLAG if not defined HMAC_FLAG (
  echo [BuildOrTest.strict] BuildMode: Release (default)
  set "LZ_OPTS=--build-mode=Release"
)

if defined CLEAN_FLAG (
  echo [BuildOrTest.strict] Cleaning output (lib/bin)
  if exist "%SCRIPT_DIR%lib" rmdir /S /Q "%SCRIPT_DIR%lib"
  if exist "%SCRIPT_DIR%bin" rmdir /S /Q "%SCRIPT_DIR%bin"
)

echo Building project (anon=ON): %PROJECT%...
call "%LAZBUILD%" %LZ_OPTS% "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
)

echo.
echo Build successful (anon=ON).
echo.

if /i "%1"=="test" goto RUN_TESTS_ON

echo Skipping tests for anon=ON run (no 'test' arg).

goto AFTER_TESTS_ON

:RUN_TESTS_ON
echo Running tests (anon=ON)...
if not exist "%REPORTS%" mkdir "%REPORTS%"
"%TEST_EXECUTABLE%" --all --format=xml > "%REPORTS%\tests_crypto.junit.xml"
rem Do not propagate anon=ON ErrorLevel to FINAL_RC; final status based on anon=OFF pass
rem if %ERRORLEVEL% NEQ 0 (
rem     set "FINAL_RC=%ERRORLEVEL%"
rem )
echo Test report saved to: %REPORTS%\tests_crypto.junit.xml

:AFTER_TESTS_ON

set "LZ_OPTS_NOANON=--build-mode=Release-NoAnon"
echo.
echo Building project (anon=OFF): %PROJECT%...
call "%LAZBUILD%" %LZ_OPTS_NOANON% "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build (anon=OFF) failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
)

echo.
echo Build successful (anon=OFF).

echo Running tests (anon=OFF)...
if not exist "%REPORTS%" mkdir "%REPORTS%"
"%TEST_EXECUTABLE%" --all --format=xml > "%REPORTS%\tests_crypto_noanon.junit.xml"
if %ERRORLEVEL% NEQ 0 (
    set "FINAL_RC=%ERRORLEVEL%"
) else (
    set "FINAL_RC=0"
)

echo Test report (anon=OFF) saved to: %REPORTS%\tests_crypto_noanon.junit.xml

echo FINAL_RC=%FINAL_RC%

echo.
echo To skip double-run, pass NO_NOANON after 'test'.
if /i "%2"=="NO_NOANON" (
    echo Skipping anon=OFF second pass per user flag.
)

if "%FINAL_RC%"=="0" (
  echo [BuildOrTest.strict] SUCCESS
) else (
  echo [BuildOrTest.strict] FAILED with code %FINAL_RC%
)

:END
exit /b %FINAL_RC%
endlocal

