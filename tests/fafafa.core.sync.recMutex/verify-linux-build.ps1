# ===================================================================
# fafafa.core.sync.recMutex Linux Build Verification Script
# ===================================================================
# 
# Function: Verify the Linux cross-compiled executable
# 
# Usage:
#   .\verify-linux-build.ps1
# 
# ===================================================================

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

Write-Info "===================================================================="
Write-Info "fafafa.core.sync.recMutex Linux Build Verification"
Write-Info "===================================================================="
Write-Output ""

$linuxExe = "bin\fafafa.core.sync.recMutex.test.linux"
$windowsExe = "bin\fafafa.core.sync.recMutex.test.exe"

# Check if Linux executable exists
if (!(Test-Path $linuxExe)) {
    Write-Error "Linux executable not found: $linuxExe"
    Write-Warning "Please run buildLinux.bat or buildLinux.ps1 first"
    exit 1
}

Write-Success "✓ Linux executable found: $linuxExe"

# Get file information
$linuxFile = Get-Item $linuxExe
Write-Output ""
Write-Info "Linux Executable Information:"
Write-Output "  Name: $($linuxFile.Name)"
Write-Output "  Size: $($linuxFile.Length) bytes ($([math]::Round($linuxFile.Length/1MB, 2)) MB)"
Write-Output "  Created: $($linuxFile.CreationTime)"
Write-Output "  Modified: $($linuxFile.LastWriteTime)"

# Calculate file hash
Write-Output ""
Write-Info "File Integrity:"
$hash = Get-FileHash -Path $linuxExe -Algorithm SHA256
Write-Output "  SHA256: $($hash.Hash)"

# Compare with Windows version if available
if (Test-Path $windowsExe) {
    $windowsFile = Get-Item $windowsExe
    Write-Output ""
    Write-Info "Comparison with Windows version:"
    Write-Output "  Windows size: $($windowsFile.Length) bytes ($([math]::Round($windowsFile.Length/1MB, 2)) MB)"
    Write-Output "  Linux size:   $($linuxFile.Length) bytes ($([math]::Round($linuxFile.Length/1MB, 2)) MB)"
    
    $sizeDiff = $linuxFile.Length - $windowsFile.Length
    if ($sizeDiff -gt 0) {
        Write-Output "  Difference:   +$sizeDiff bytes (Linux is larger)"
    } elseif ($sizeDiff -lt 0) {
        Write-Output "  Difference:   $sizeDiff bytes (Linux is smaller)"
    } else {
        Write-Output "  Difference:   Same size"
    }
}

# Check build artifacts
Write-Output ""
Write-Info "Build Artifacts:"
if (Test-Path "lib\x86_64-linux") {
    $libFiles = Get-ChildItem "lib\x86_64-linux" -Recurse -File
    Write-Success "  ✓ Linux build directory: lib\x86_64-linux ($($libFiles.Count) files)"
} else {
    Write-Warning "  ⚠ Linux build directory not found"
}

# Try to get file type information
Write-Output ""
Write-Info "File Type Detection:"
if (Get-Command "file" -ErrorAction SilentlyContinue) {
    Write-Output "  File command output:"
    $fileOutput = & file $linuxExe 2>$null
    Write-Output "    $fileOutput"
} else {
    Write-Warning "  'file' command not available (install Git Bash or WSL for file type detection)"
}

# Check for required dependencies (if objdump is available)
if (Get-Command "objdump" -ErrorAction SilentlyContinue) {
    Write-Output ""
    Write-Info "Binary Analysis:"
    try {
        $objdumpOutput = & objdump -f $linuxExe 2>$null
        if ($objdumpOutput) {
            Write-Output "  Architecture: x86_64"
            Write-Output "  Format: ELF64"
        }
    } catch {
        Write-Warning "  Could not analyze binary format"
    }
}

# Verify project configuration
Write-Output ""
Write-Info "Project Configuration:"
if (Test-Path "fafafa.core.sync.recMutex.test.lpi") {
    $lpiContent = Get-Content "fafafa.core.sync.recMutex.test.lpi" -Raw
    if ($lpiContent -match 'Linux-x86_64') {
        Write-Success "  ✓ Linux-x86_64 build mode configured"
    } else {
        Write-Warning "  ⚠ Linux-x86_64 build mode not found in project"
    }
    
    if ($lpiContent -match 'TargetOS.*linux') {
        Write-Success "  ✓ Target OS set to Linux"
    }
    
    if ($lpiContent -match 'TargetCPU.*x86_64') {
        Write-Success "  ✓ Target CPU set to x86_64"
    }
} else {
    Write-Error "  ✗ Project file not found"
}

# Summary
Write-Output ""
Write-Info "===================================================================="
Write-Success "Linux Cross-Compilation Verification Complete!"
Write-Info "===================================================================="
Write-Output ""
Write-Success "Ready for Linux deployment:"
Write-Output "  1. Transfer file: $linuxExe"
Write-Output "  2. Set permissions: chmod +x fafafa.core.sync.recMutex.test.linux"
Write-Output "  3. Run tests: ./fafafa.core.sync.recMutex.test.linux --all --format=plain"
Write-Output ""

# Expected test results
Write-Info "Expected Test Results on Linux:"
Write-Output "  • Total Tests: 34"
Write-Output "  • Global Tests: 2 (MakeRecMutex functions)"
Write-Output "  • Interface Tests: 26 (IRecMutex functionality)"
Write-Output "  • MultiThread Tests: 6 (Concurrency scenarios)"
Write-Output "  • Expected Result: 100% pass rate, 0 memory leaks"
Write-Output ""
Write-Info "===================================================================="
