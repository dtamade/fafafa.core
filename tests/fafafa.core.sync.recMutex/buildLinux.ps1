# ===================================================================
# fafafa.core.sync.recMutex Linux Cross-Compilation PowerShell Script
# ===================================================================
# 
# Function: Cross-compile unit tests from Windows to Linux x86_64
# 
# Usage:
#   .\buildLinux.ps1          - Build Debug version
#   .\buildLinux.ps1 release  - Build Release version  
#   .\buildLinux.ps1 clean    - Clean build artifacts
# 
# Output:
#   bin/fafafa.core.sync.recMutex.test.linux - Linux executable
#   lib/x86_64-linux/ - Linux build intermediate files
# 
# ===================================================================

param(
    [string]$Mode = "debug"
)

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) { Write-ColorOutput Cyan $message }
function Write-Success($message) { Write-ColorOutput Green $message }
function Write-Warning($message) { Write-ColorOutput Yellow $message }
function Write-Error($message) { Write-ColorOutput Red $message }

# Check parameters
$BUILD_MODE = "Linux-x86_64"
$TARGET_SUFFIX = ".linux"

switch ($Mode.ToLower()) {
    "release" {
        $BUILD_MODE = "Release"
        $TARGET_SUFFIX = ".linux.release"
    }
    "clean" {
        Write-Info "===================================================================="
        Write-Info "Cleaning Linux Cross-Compilation Artifacts"
        Write-Info "===================================================================="
        Write-Output ""
        
        # Clean Linux-related build artifacts
        if (Test-Path "bin\fafafa.core.sync.recMutex.test.linux") {
            Remove-Item "bin\fafafa.core.sync.recMutex.test.linux"
            Write-Success "Deleted: bin\fafafa.core.sync.recMutex.test.linux"
        }
        
        if (Test-Path "bin\fafafa.core.sync.recMutex.test.linux.release") {
            Remove-Item "bin\fafafa.core.sync.recMutex.test.linux.release"
            Write-Success "Deleted: bin\fafafa.core.sync.recMutex.test.linux.release"
        }
        
        if (Test-Path "lib\x86_64-linux") {
            Remove-Item "lib\x86_64-linux" -Recurse -Force
            Write-Success "Deleted: lib\x86_64-linux\"
        }
        
        Write-Output ""
        Write-Success "Cleanup completed!"
        Write-Info "===================================================================="
        return
    }
}

Write-Info "===================================================================="
Write-Info "fafafa.core.sync.recMutex Linux Cross-Compilation"
Write-Info "===================================================================="
Write-Output ""
Write-Output "Build Mode: $BUILD_MODE"
Write-Output "Target Platform: Linux x86_64"
Write-Output "Output File: bin/fafafa.core.sync.recMutex.test$TARGET_SUFFIX"
Write-Output ""

# Check if lazbuild is available
if (!(Get-Command "lazbuild" -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: lazbuild command not found"
    Write-Error "Please ensure Lazarus is properly installed and added to PATH"
    exit 1
}

# Create output directories
if (!(Test-Path "bin")) { New-Item -ItemType Directory -Path "bin" | Out-Null }
if (!(Test-Path "lib")) { New-Item -ItemType Directory -Path "lib" | Out-Null }
if (!(Test-Path "lib\x86_64-linux")) { New-Item -ItemType Directory -Path "lib\x86_64-linux" | Out-Null }

Write-Info "Starting cross-compilation..."
Write-Output ""

# Execute cross-compilation
$result = & lazbuild --build-mode=$BUILD_MODE fafafa.core.sync.recMutex.test.lpi
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Output ""
    Write-Error "===================================================================="
    Write-Error "COMPILATION FAILED!"
    Write-Error "===================================================================="
    exit $exitCode
} else {
    Write-Output ""
    Write-Success "===================================================================="
    Write-Success "COMPILATION SUCCESSFUL!"
    Write-Success "===================================================================="
    Write-Output ""
    
    # Display generated file information
    $linuxExe = "bin\fafafa.core.sync.recMutex.test.linux"
    if (Test-Path $linuxExe) {
        Write-Info "Generated Linux executable:"
        $fileInfo = Get-Item $linuxExe
        Write-Output "  Name: $($fileInfo.Name)"
        Write-Output "  Size: $($fileInfo.Length) bytes"
        Write-Output "  Created: $($fileInfo.CreationTime)"
        Write-Output ""
        
        Write-Success "Linux executable generated: bin/fafafa.core.sync.recMutex.test.linux"
        Write-Output ""
        Write-Warning "Instructions for running on Linux:"
        Write-Output "  1. Transfer the file to a Linux system"
        Write-Output "  2. Make it executable: chmod +x fafafa.core.sync.recMutex.test.linux"
        Write-Output "  3. Run tests: ./fafafa.core.sync.recMutex.test.linux --all --format=plain"
        Write-Output ""
        
        # Try to get file type information if available
        if (Get-Command "file" -ErrorAction SilentlyContinue) {
            Write-Info "File type information:"
            & file $linuxExe
            Write-Output ""
        }
    }
}

Write-Info "===================================================================="
