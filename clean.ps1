# Clean script for fafafa.core project
# Removes all .o and .ppu files from the project directory

Write-Host "Cleaning fafafa.core project..." -ForegroundColor Green
Write-Host ""

# Find and remove .o and .ppu files
Write-Host "Searching for .o and .ppu files..." -ForegroundColor Yellow
$files = Get-ChildItem -Recurse -Include "*.o", "*.ppu"

if ($files.Count -eq 0) {
    Write-Host "No .o or .ppu files found." -ForegroundColor Green
} else {
    Write-Host "Found $($files.Count) files to clean" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Removing files..." -ForegroundColor Yellow
    foreach ($file in $files) {
        Write-Host "Deleting: $($file.FullName)" -ForegroundColor Gray
        Remove-Item $file.FullName -Force
    }
}

Write-Host ""
Write-Host "Cleanup completed!" -ForegroundColor Green

# Verify cleanup
$remaining = Get-ChildItem -Recurse -Include "*.o", "*.ppu"
if ($remaining.Count -eq 0) {
    Write-Host "All compilation artifacts have been successfully removed." -ForegroundColor Green
} else {
    Write-Host "Warning: $($remaining.Count) files still remain:" -ForegroundColor Red
    foreach ($file in $remaining) {
        Write-Host "  $($file.FullName)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
