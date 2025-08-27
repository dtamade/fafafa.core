@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=fafafa.core.simd.test.lpi"
set "TEST_EXECUTABLE=bin\fafafa.core.simd.test.exe"
set "CLEAN_DIRS=lib bin"

set "CMD=%1"
if /i "%CMD%"=="clean" goto :CLEAN
if /i "%CMD%"=="rebuild" ( set "DO_CLEAN=1" )

:BUILD
if defined DO_CLEAN goto :CLEAN_ONLY

rem Ensure output dirs
if not exist bin mkdir bin
if not exist lib mkdir lib

rem Build via lazbuild wrapper (prefers LAZBUILD_EXE or PATH lazbuild)
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error code %ERRORLEVEL%.
  set "FINAL_RC=%ERRORLEVEL%"
  goto END
)

if /i "%CMD%"=="test" goto :RUN

echo Build successful. To run tests: buildOrTest.bat test
set "FINAL_RC=0"
goto END

:RUN
if exist "%TEST_EXECUTABLE%" (
  set "FAFAFA_SIMD_FORCE=SSE2"
  "%TEST_EXECUTABLE%" --all --format=plain
  set "FINAL_RC=!ERRORLEVEL!"
) else (
  echo Binary not found: %TEST_EXECUTABLE%
  set "FINAL_RC=2"
)
goto END

:CLEAN
for %%D in (%CLEAN_DIRS%) do (
  if exist "%%D" rmdir /s /q "%%D"
)
if /i "%CMD%"=="clean" (
  set "FINAL_RC=0"
  goto END
)

:CLEAN_ONLY
mkdir bin 2>nul
mkdir lib 2>nul
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
set "FINAL_RC=%ERRORLEVEL%"
goto END

:END
popd
exit /b %FINAL_RC%

