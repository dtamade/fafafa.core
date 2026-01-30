@echo off
setlocal ENABLEDELAYEDEXPANSION
REM Cleanup demo outputs for fafafa.core.crypto examples
REM - Removes generated test_* files and logs

REM Jump to this script's directory
cd /d "%~dp0"

set COUNT=0
for %%F in (
  fileenc.log
  test_original.txt
  test_encrypted.dat
  test_decrypted.txt
  test_decrypted_wrong.txt
  bin\run.log
) do (
  if exist "%%~F" (
    del /f /q "%%~F" >nul 2>nul
    echo Deleted: %%~F
    set /a COUNT+=1 >nul
  )
)

if %COUNT% EQU 0 (
  echo Nothing to clean.
) else (
  echo Cleaned %COUNT% file^(s^).
)

echo Done.
endlocal

