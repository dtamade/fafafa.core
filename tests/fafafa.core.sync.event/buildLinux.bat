@echo off

echo Cross-compiling to Linux x86_64...
lazbuild --cpu=x86_64 --os=linux --build-mode=Debug fafafa.core.sync.event.test.lpi

if %errorlevel% equ 0 (
    echo Build successful!
    if exist bin\fafafa.core.sync.event.test (
        echo Linux executable: bin\fafafa.core.sync.event.test
    )
) else (
    echo Build failed!
)
