@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

set EXE1=%SCRIPT_DIR%test_api_aliases.exe
set EXE2=%SCRIPT_DIR%test_oa_tombstone_stress.exe
set EXE3=%SCRIPT_DIR%test_resource_safety_basic.exe

set RC=0
for %%E in ("%EXE1%" "%EXE2%" "%EXE3%") do (
  if exist %%~fE (
    echo [run] %%~nxE
    %%~fE
    if %ERRORLEVEL% NEQ 0 set RC=%ERRORLEVEL%
  ) else (
    echo [skip] %%~nxE not found
  )
)
exit /b %RC%

