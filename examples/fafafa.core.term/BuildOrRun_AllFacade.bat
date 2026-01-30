@echo off
setlocal EnableDelayedExpansion
set ROOT=%~dp0
pushd "%ROOT%" >nul

set LAZBUILD=%ROOT%..\..\tools\lazbuild.bat
set BIN=%ROOT%bin
if not exist "%BIN%" mkdir "%BIN%"

rem Build project (contains most examples)
call "%LAZBUILD%" "%ROOT%example_term.lpi" || goto :fail

rem Best-effort run of facade demos
for %%E in (example_facade_beta.exe example_facade_frame_loop.exe) do (
  if exist "%BIN%\%%E" (
    echo ===== Running %%E =====
    "%BIN%\%%E" || echo (skip) %%E exited non-zero
  ) else (
    echo (skip) %%E not built
  )
)

echo Done.
popd >nul
endlocal
exit /b 0
:fail
echo Build failed.
popd >nul
endlocal
exit /b 1

