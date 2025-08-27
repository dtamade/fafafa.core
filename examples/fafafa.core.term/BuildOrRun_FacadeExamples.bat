@echo off
setlocal
set LAZBUILD=lazbuild
set OUTDIR=%~dp0bin
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem Build facade beta examples
"%LAZBUILD%" --build-all "%~dp0example_term.lpi" || goto :fail

rem Run the two new examples (best effort)
echo ===== example_facade_beta =====
"%~dp0bin\example_facade_beta.exe" || echo (skip) run failed or not built

echo ===== example_facade_frame_loop =====
"%~dp0bin\example_facade_frame_loop.exe" || echo (skip) run failed or not built

echo Done.
endlocal
exit /b 0
:fail
echo Build failed.
endlocal
exit /b 1

