@echo off
setlocal

if not exist "%~dp0bin" mkdir "%~dp0bin" >nul 2>&1

rem Prefer direct FPC compile to avoid wrapper recursion
set FPC_EXE=fpc
pushd "%~dp0"
"%FPC_EXE%" -MObjFPC -Scaghi -gl -Fu"..\..\src" -Fi"..\..\src" -dFAFAFA_PROCESS_GROUPS -FE"bin" example_pipeline_failfast.pas 1>"bin\build_failfast.log" 2>&1
set EC=%ERRORLEVEL%
popd

if not %EC%==0 (
  echo Build failed, see examples\fafafa.core.process\bin\build_failfast.log
  exit /b %EC%
)

echo Build success: examples\fafafa.core.process\bin\example_pipeline_failfast.exe
exit /b 0

