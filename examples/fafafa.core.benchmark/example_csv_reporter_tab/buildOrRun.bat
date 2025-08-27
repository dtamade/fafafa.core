@echo off
setlocal enabledelayedexpansion

set HERE=%~dp0
cd /d "%HERE%..\..\..\"

call tools\lazbuild.bat examples\fafafa.core.benchmark\example_csv_reporter_tab\example_csv_reporter_tab.lpr || goto :eof
examples\fafafa.core.benchmark\example_csv_reporter_tab\bin\example_csv_reporter_tab.exe

