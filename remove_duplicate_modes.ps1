# Remove duplicate {$mode objfpc} directives since settings.inc already sets it
$files = Get-ChildItem "src\fafafa.core.simd*.pas" 

foreach ($file in $files) {
    Write-Host "Processing $($file.Name)..."
    
    $lines = Get-Content $file.FullName
    $newLines = @()
    $skip = $false
    
    foreach ($line in $lines) {
        if ($line -match '^\s*\{\$mode\s+objfpc\}') {
            Write-Host "  Removing duplicate mode directive: $line"
            $skip = $true
            continue
        }
        if ($skip -and $line -match '^\s*$') {
            # Skip empty line after removed mode directive
            $skip = $false
            continue
        }
        $skip = $false
        $newLines += $line
    }
    
    Set-Content -Path $file.FullName -Value $newLines
    Write-Host "  Fixed $($file.Name)"
}

Write-Host "Done removing duplicate mode directives"