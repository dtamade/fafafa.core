@echo off
echo Testing minimal compilation...

if not exist bin mkdir bin

echo Compiling minimal.lpr...
D:\devtools\lazarus\trunk\lazbuild.exe minimal.lpr -o bin\minimal.exe

if exist bin\minimal.exe (
    echo Success! Running minimal test...
    bin\minimal.exe
) else (
    echo Failed to create minimal.exe
)

pause
