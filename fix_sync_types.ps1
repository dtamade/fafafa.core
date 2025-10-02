$filePath = "D:\projects\Pascal\lazarus\My\libs\fafafa.core\src\fafafa.core.sync.pas"
$lines = Get-Content $filePath

$newLines = @()
$inserted = $false

foreach ($line in $lines) {
    # Insert new type aliases before "// Re-export exceptions"
    if (-not $inserted -and $line -match '^\s*// Re-export exceptions') {
        $newLines += ""
        $newLines += "  // Re-export Once callback types"
        $newLines += "  TOnceProc = fafafa.core.sync.once.base.TOnceProc;"
        $newLines += "  TOnceMethod = fafafa.core.sync.once.base.TOnceMethod;"
        $newLines += "{`$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}"
        $newLines += "  TOnceAnonymousProc = fafafa.core.sync.once.base.TOnceAnonymousProc;"
        $newLines += "{`$ENDIF}"
        $newLines += ""
        $inserted = $true
    }
    
    # Replace long qualified names in function signatures
    $line = $line -replace 'fafafa\.core\.sync\.once\.base\.TOnceProc', 'TOnceProc'
    $line = $line -replace 'fafafa\.core\.sync\.once\.base\.TOnceMethod', 'TOnceMethod'
    $line = $line -replace 'fafafa\.core\.sync\.once\.base\.TOnceAnonymousProc', 'TOnceAnonymousProc'
    
    $newLines += $line
}

$newLines | Set-Content $filePath
Write-Host "Fixed sync.pas - added type aliases and updated function signatures"
