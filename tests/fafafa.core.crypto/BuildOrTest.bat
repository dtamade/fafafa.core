@echo off

setlocal ENABLEDELAYEDEXPANSION
set "SCRIPT_DIR=%~dp0"

rem Normalize paths relative to this script directory so it works from any CWD
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo [ERROR] tools\lazbuild.bat not found: %LAZBUILD%
  echo Please configure tools\lazbuild.bat to wrap your lazbuild.
  exit /b 2
)
echo [BuildOrTest] Using lazbuild wrapper: %LAZBUILD%
call "%LAZBUILD%" --version
if %ERRORLEVEL% NEQ 0 echo [WARN] Unable to query lazbuild version (non-fatal).
set "PROJECT=%SCRIPT_DIR%tests_crypto.lpi"
set "TEST_EXECUTABLE=%SCRIPT_DIR%bin\tests_crypto.exe"
set "REPORTS=%SCRIPT_DIR%reports"
set "CLEAN_FLAG="
set "FINAL_RC=0"
set "RC_ON=0"
set "RC_OFF=0"

set "AEAD_FLAG="
set "HMAC_FLAG="
for %%A in (%*) do (
  if /I "%%~A"=="aead" set "AEAD_FLAG=1"
  if /I "%%~A"=="hmac" set "HMAC_FLAG=1"
  if /I "%%~A"=="clean" set "CLEAN_FLAG=1"
  if /I "%%~A"=="test-clmul" set "CLMUL_FLAG=1"
)

rem CI mode disabled per user request

set "LZ_OPTS=--build-mode=Release"
set "BUILD_MODE=Release"
if defined CLMUL_FLAG (
  set "LZ_OPTS=--build-mode=Release-CLMUL"
  set "BUILD_MODE=Release-CLMUL"
) else (
  if defined AEAD_FLAG (
    set "LZ_OPTS=--build-mode=AEAD"
    set "BUILD_MODE=AEAD"
  ) else (
    if defined HMAC_FLAG (
      set "LZ_OPTS=--build-mode=HMAC-DEBUG"
      set "BUILD_MODE=HMAC-DEBUG"
    )
  )
)
echo [BuildOrTest] BuildMode: %BUILD_MODE%

echo Building project (anon=ON): %PROJECT%...
if defined CLEAN_FLAG (
  echo [BuildOrTest] Cleaning output (lib/bin)
  if exist "%SCRIPT_DIR%lib" rmdir /S /Q "%SCRIPT_DIR%lib"
  if exist "%SCRIPT_DIR%bin" rmdir /S /Q "%SCRIPT_DIR%bin"
)
call "%LAZBUILD%" %LZ_OPTS% "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
)
if not exist "%TEST_EXECUTABLE%" (
    echo [ERROR] Build appears successful but missing executable: %TEST_EXECUTABLE%
    set "FINAL_RC=100"
    goto END
)
if /i "%1"=="test-clmul" set "SKIP_NOANON=1"
if /i "%2"=="NO_NOANON" set "SKIP_NOANON="


echo.
echo Build successful (anon=ON).
echo.

if /i "%1"=="test" goto RUN_TESTS_ON
if defined CLMUL_FLAG goto RUN_TESTS_ON

echo Skipping tests for anon=ON run (no 'test' arg).

goto AFTER_TESTS_ON

:RUN_TESTS_ON
echo Running tests (anon=ON)...
if not exist "%REPORTS%" mkdir "%REPORTS%"
set "FAFAFA_CORE_AEAD_DIAG=1"
"%TEST_EXECUTABLE%" --all --format=xml > "%REPORTS%\tests_crypto.junit.xml"
set "RC_ON=%ERRORLEVEL%"
rem Optional: also produce our JUnit with CaseId in system-out when enabled
if /i "%FAFAFA_ENABLE_AUX_JUNIT%"=="1" (
  set "FAFAFA_JUNIT_NO_SYSOUT=0"
  "%TEST_EXECUTABLE%" --all --format=junit --junit="%REPORTS%\tests_crypto.junit.caselog.xml" 1>NUL 2>NUL
  if NOT "%ERRORLEVEL%"=="0" echo [INFO] Current test runner does not support --format=junit; skipping auxiliary JUnit report.
)
rem Rotate AEAD diag log to distinguish anon=ON pass
if exist "%REPORTS%\aead_diag.log" (
  del /f /q "%REPORTS%\aead_diag.on.log" >NUL 2>&1
  rename "%REPORTS%\aead_diag.log" "aead_diag.on.log"
)
if /i "%FAFAFA_ENABLE_AUX_JUNIT%"=="1" (
  echo Test reports saved to: %REPORTS%\tests_crypto.junit.xml and ...\tests_crypto.junit.caselog.xml
) else (
  echo Test report saved to: %REPORTS%\tests_crypto.junit.xml
)

rem For 'test-clmul', default to skipping anon=OFF unless explicitly overridden by NO_NOANON
if defined SKIP_NOANON (
  echo.
  echo [BuildOrTest] Skipping anon=OFF second pass for 'test-clmul'. Use 'NO_NOANON' to override.
  goto CONSOLIDATE_RC
)

:AFTER_TESTS_ON

set "LZ_OPTS_NOANON=--build-mode=Release-NoAnon"
echo.
echo Building project (anon=OFF): %PROJECT%...
call "%LAZBUILD%" %LZ_OPTS_NOANON% "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build (anon=OFF) failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto CONSOLIDATE_RC
)
if not exist "%TEST_EXECUTABLE%" (
    echo [ERROR] Build (anon=OFF) appears successful but missing executable: %TEST_EXECUTABLE%
    set "FINAL_RC=101"
    goto CONSOLIDATE_RC
)

echo.
echo Build successful (anon=OFF).

if /i "%1" NEQ "test" (
  echo Skipping tests for anon=OFF run (no 'test' arg).
  goto CONSOLIDATE_RC
)

echo Running tests (anon=OFF)...
set "FAFAFA_CORE_AEAD_DIAG=1"
"%TEST_EXECUTABLE%" --all --format=xml > "%REPORTS%\tests_crypto_noanon.junit.xml"
set "RC_OFF=%ERRORLEVEL%"
rem Optional: also produce our JUnit with CaseId in system-out when enabled
if /i "%FAFAFA_ENABLE_AUX_JUNIT%"=="1" (
  set "FAFAFA_JUNIT_NO_SYSOUT=0"
  "%TEST_EXECUTABLE%" --all --format=junit --junit="%REPORTS%\tests_crypto_noanon.junit.caselog.xml" 1>NUL 2>NUL
  if NOT "%ERRORLEVEL%"=="0" echo [INFO] Current test runner does not support --format=junit; skipping auxiliary JUnit report.
)
rem Rotate AEAD diag log to distinguish anon=OFF pass
if exist "%REPORTS%\aead_diag.log" (
  del /f /q "%REPORTS%\aead_diag.off.log" >NUL 2>&1
  rename "%REPORTS%\aead_diag.log" "aead_diag.off.log"
)

if /i "%FAFAFA_ENABLE_AUX_JUNIT%"=="1" (
  echo Test reports (anon=OFF) saved to: %REPORTS%\tests_crypto_noanon.junit.xml and ...\tests_crypto_noanon.junit.caselog.xml
) else (
  echo Test report (anon=OFF) saved to: %REPORTS%\tests_crypto_noanon.junit.xml
)

:CONSOLIDATE_RC
rem Consolidate final return code (reset before checks)
set "FINAL_RC=0"

rem Tolerate false non-zero when JUnit shows all passed
if exist "%REPORTS%\tests_crypto.junit.xml" (
  set "F_OK_ON=0"
  set "E_OK_ON=0"
  findstr /i "failures=\"0\"" "%REPORTS%\tests_crypto.junit.xml" >NUL && set "F_OK_ON=1"
  findstr /i "errors=\"0\""   "%REPORTS%\tests_crypto.junit.xml" >NUL && set "E_OK_ON=1"
  if "%F_OK_ON%"=="1" if "%E_OK_ON%"=="1" set "RC_ON=0"
)
if exist "%REPORTS%\tests_crypto_noanon.junit.xml" (
  set "F_OK_OFF=0"
  set "E_OK_OFF=0"
  findstr /i "failures=\"0\"" "%REPORTS%\tests_crypto_noanon.junit.xml" >NUL && set "F_OK_OFF=1"
  findstr /i "errors=\"0\""   "%REPORTS%\tests_crypto_noanon.junit.xml" >NUL && set "E_OK_OFF=1"
  if "%F_OK_OFF%"=="1" if "%E_OK_OFF%"=="1" set "RC_OFF=0"
)

rem Final decide
if %RC_ON% NEQ 0 set "FINAL_RC=%RC_ON%"
if %RC_OFF% NEQ 0 set "FINAL_RC=%RC_OFF%"

:END
exit /b %FINAL_RC%
endlocal
