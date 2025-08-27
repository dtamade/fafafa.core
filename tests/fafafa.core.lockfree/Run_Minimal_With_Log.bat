@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG_FILE=%LOG_DIR%\latest_minimal.log"

>"%LOG_FILE%" (
  echo [run] test_api_aliases.exe
)
if exist "%SCRIPT_DIR%test_api_aliases.exe" (
  "%SCRIPT_DIR%test_api_aliases.exe" >> "%LOG_FILE%" 2>&1
  echo.>>"%LOG_FILE%"
) else (
  >>"%LOG_FILE%" echo [skip] test_api_aliases.exe not found
)

>>"%LOG_FILE%" echo [run] test_oa_tombstone_stress.exe
if exist "%SCRIPT_DIR%test_oa_tombstone_stress.exe" (
  "%SCRIPT_DIR%test_oa_tombstone_stress.exe" >> "%LOG_FILE%" 2>&1
  echo.>>"%LOG_FILE%"
) else (
  >>"%LOG_FILE%" echo [skip] test_oa_tombstone_stress.exe not found
)

>>"%LOG_FILE%" echo [run] test_resource_safety_basic.exe
if exist "%SCRIPT_DIR%test_resource_safety_basic.exe" (
  "%SCRIPT_DIR%test_resource_safety_basic.exe" >> "%LOG_FILE%" 2>&1
  echo.>>"%LOG_FILE%"
) else (
  >>"%LOG_FILE%" echo [skip] test_resource_safety_basic.exe not found
)

type "%LOG_FILE%"
exit /b 0

