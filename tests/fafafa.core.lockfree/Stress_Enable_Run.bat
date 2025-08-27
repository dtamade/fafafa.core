@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
set "CONFIG=%SCRIPT_DIR%test_config.inc"

echo [Stress_Enable_Run] Enabling FAFAFA_CORE_ENABLE_STRESS_TESTS in %CONFIG% ...
powershell -NoProfile -Command ^
  "$p='%CONFIG%';" ^
  "$c=Get-Content $p -Raw;" ^
  "$c=$c -replace '^[\s\r\n]*\{\s*\$DEFINE\s+FAFAFA_CORE_ENABLE_STRESS_TESTS\s*\}[\s\r\n]*', '{$DEFINE FAFAFA_CORE_ENABLE_STRESS_TESTS}' + """\r\n""";" ^
  "if ($c -notmatch '\{\$DEFINE\s+FAFAFA_CORE_ENABLE_STRESS_TESTS\}') { $c += """{$DEFINE FAFAFA_CORE_ENABLE_STRESS_TESTS}\r\n""" }" ^
  "; Set-Content -Encoding UTF8 $p $c;"

call "%SCRIPT_DIR%BuildOnly.bat" || exit /b 1
call "%SCRIPT_DIR%RunOnly_nointeractive.bat"
exit /b %ERRORLEVEL%

