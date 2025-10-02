# 修复所有sync相关文件中的重复mode声明问题
$srcPath = "D:\projects\Pascal\lazarus\My\libs\fafafa.core\src"
$files = Get-ChildItem -Path $srcPath -Filter "fafafa.core.sync.*.pas"

$fixedCount = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # 检查是否有重复的mode声明
    if ($content -match '\{\$mode objfpc\}\{\$H\+\}\s*\r?\n\s*\{\$I fafafa\.core\.settings\.inc\}') {
        # 移除重复的mode声明，只保留settings.inc包含
        $newContent = $content -replace '\{\$mode objfpc\}\{\$H\+\}\s*\r?\n\s*(\{\$I fafafa\.core\.settings\.inc\})', '$1'
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
        $fixedCount++
    }
    elseif ($content -match '\{\$mode objfpc\}') {
        # 检查其他形式的mode声明
        Write-Host "Needs manual check: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`nTotal files fixed: $fixedCount" -ForegroundColor Cyan