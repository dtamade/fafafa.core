# Fix Pascal compiler mode for remaining SIMD modules
$files = @(
    "src\fafafa.core.simd.cpuinfo.diagnostic.pas",
    "src\fafafa.core.simd.cpuinfo.base.pas",
    "src\fafafa.core.simd.types.pas"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..."
        
        # Read current content
        $lines = Get-Content $file
        $modified = $false
        
        # Find unit line and check if mode already exists
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match "^unit\s+") {
                # Check if next few lines already contain mode directive
                $hasMode = $false
                for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Length); $j++) {
                    if ($lines[$j] -match "\{\$mode\s+objfpc\}") {
                        $hasMode = $true
                        break
                    }
                }
                
                if (-not $hasMode) {
                    # Insert mode directive after unit line
                    $newLines = @()
                    $newLines += $lines[0..$i]
                    $newLines += ""
                    $newLines += "{`$mode objfpc}{`$H+}"
                    if ($i + 1 -lt $lines.Length) {
                        $newLines += $lines[($i+1)..($lines.Length-1)]
                    }
                    
                    Set-Content -Path $file -Value $newLines
                    Write-Host "Fixed $file - added compiler mode directive"
                    $modified = $true
                } else {
                    Write-Host "File $file already has compiler mode directive"
                }
                break
            }
        }
        
        if (-not $modified -and -not (Get-Content $file | Select-String "{\`$mode\s+objfpc}")) {
            Write-Host "Warning: Could not process $file - unit declaration not found or mode not added"
        }
    } else {
        Write-Host "File $file not found"
    }
}

Write-Host "Done fixing remaining SIMD modules"