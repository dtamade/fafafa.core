# PowerShell script to help identify and fix inline variable declarations
$file = "D:\projects\Pascal\lazarus\My\libs\fafafa.core\src\fafafa.core.graphics.validator.pas"
$content = Get-Content $file -Raw

# Find all inline var declarations
$pattern = '(?m)^\s+var\s+(\w+.*?)(?:;|:)'
$matches = [regex]::Matches($content, $pattern)

Write-Host "Found $($matches.Count) inline variable declarations:"
foreach ($match in $matches) {
    $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
    Write-Host "Line $lineNumber : $($match.Value)"
}

Write-Host "`nThese need to be moved to the function/procedure var section"