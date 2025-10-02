$srcPath = "D:\projects\Pascal\lazarus\My\libs\fafafa.core\src"
$count = 0
$processed = 0

Write-Host "=== Cleaning up redundant {`$mode objfpc} directives ===" -ForegroundColor Cyan
Write-Host "Now that settings.inc contains the mode directive, we can remove duplicates.`n"

Get-ChildItem $srcPath -Filter "*.pas" -Recurse | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { return }
    
    # Check if file has both {$mode objfpc} and {$I fafafa.core.settings.inc}
    if ($content -match '\{\$mode objfpc\}' -and 
        $content -match '\{\$I fafafa\.core\.settings\.inc\}') {
        
        $processed++
        
        # Remove standalone {$mode objfpc} lines (but keep combined ones like {$mode objfpc}{$H+})
        $newContent = $content -replace '^\{\$mode objfpc\}\s*[\r\n]+', ''
        
        if ($newContent -ne $content) {
            Set-Content $file $newContent -NoNewline
            $count++
            Write-Host "✓ Cleaned: $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "○ Skipped (complex pattern): $($_.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files processed: $processed"
Write-Host "Files cleaned: $count"
Write-Host "`nNow all files will get {`$mode objfpc} from settings.inc!" -ForegroundColor Green
