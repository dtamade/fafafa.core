@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "BIN_DIR=%SCRIPT_DIR%bin"

if not exist "%BIN_DIR%" (
  echo bin/ not found. Build first: BuildExamples.bat
  goto END
)

for %%F in ("%BIN_DIR%\example_xml_reader.exe" "%BIN_DIR%\example_xml_writer.exe" "%BIN_DIR%\example_xml_config.exe" "%BIN_DIR%\bench_xml_reader.exe" "%BIN_DIR%\bench_xml_reader_file.exe" "%BIN_DIR%\example_writer_attr_pretty_combined.exe" "%BIN_DIR%\example_xml_reader_autodecode.exe") do (
  if exist "%%~F" (
    echo.
    echo ==== Running %%~nxF ====
    "%%~F"
  ) else (
    echo Skipped %%~nxF (not built)
  )
)

:END
endlocal

