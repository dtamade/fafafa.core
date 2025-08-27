@echo off
setlocal

rem Build and run cancel best practices examples
set EX_DIR=%~dp0
pushd "%EX_DIR%"

lazbuild cancel_best_practices.lpr || goto :eof
lazbuild cancel_best_practices_with_token_struct.lpr || goto :eof

.\bin\cancel_best_practices.exe
.\bin\cancel_best_practices_with_token_struct.exe

popd
endlocal

