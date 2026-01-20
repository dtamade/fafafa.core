@echo off
echo Updating test file references...

:: Use PowerShell for batch replacement
powershell.exe -Command "(Get-Content 'fafafa.core.sync.sem.testcase.pas') -replace 'TTestCase_ISemaphore', 'TTestCase_ISem' | Set-Content 'fafafa.core.sync.sem.testcase.pas'"
powershell.exe -Command "(Get-Content 'fafafa.core.sync.sem.testcase.pas') -replace 'fafafa\.core\.sync\.semaphore\.MakeSemaphore', 'fafafa.core.sync.sem.MakeSem' | Set-Content 'fafafa.core.sync.sem.testcase.pas'"
powershell.exe -Command "(Get-Content 'fafafa.core.sync.sem.testcase.pas') -replace ': ISemaphore;', ': ISem;' | Set-Content 'fafafa.core.sync.sem.testcase.pas'"
powershell.exe -Command "(Get-Content 'fafafa.core.sync.sem.testcase.pas') -replace 'S: ISemaphore', 'S: ISem' | Set-Content 'fafafa.core.sync.sem.testcase.pas'"
powershell.exe -Command "(Get-Content 'fafafa.core.sync.sem.testcase.pas') -replace 'L := FSem; // ISemaphore', 'L := FSem; // ISem' | Set-Content 'fafafa.core.sync.sem.testcase.pas'"

echo Done updating references!
