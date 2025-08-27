@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
set "CONFIG=%SCRIPT_DIR%test_config.inc"

echo [Stress_Disable_Run] Disabling FAFAFA_CORE_ENABLE_STRESS_TESTS in %CONFIG% ...
powershell -NoProfile -Command ^
  "$p='%CONFIG%';" ^
  "$c=Get-Content $p -Raw;" ^
  "$c=$c -replace '\{\$DEFINE\s+FAFAFA_CORE_ENABLE_STRESS_TESTS\}', '{ $DEFINE FAFAFA_CORE_ENABLE_STRESS_TESTS }';" ^
  "; Set-Content -Encoding UTF8 $p $c;"

call "%SCRIPT_DIR%BuildOnly.bat" || exit /b 1
call "%SCRIPT_DIR%RunOnly_nointeractive.bat"
exit /b %ERRORLEVEL%

