# Collections 内存泄漏验证脚本 (Windows PowerShell)
# 使用 HeapTrc 运行所有 collections 泄漏测试

param(
    [string]$FpcPath = "fpc"  # FPC编译器路径，默认从PATH查找
)

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = $PSScriptRoot
$TEST_DIR = Join-Path $PROJECT_ROOT "tests"
$BIN_DIR = Join-Path $TEST_DIR "leak_test_bin"
$LOG_DIR = Join-Path $TEST_DIR "leak_test_logs"
$REPORT_FILE = Join-Path $TEST_DIR "COLLECTIONS_MEMORY_LEAK_REPORT.md"

# 创建输出目录
New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null

# 测试列表（10个核心集合内存测试）
$TESTS = @(
    "test_vec_leak",
    "test_vecdeque_leak",
    "test_list_leak",
    "test_hashmap_leak",
    "test_hashset_leak",
    "test_linkedhashmap_leak",
    "test_bitset_leak",
    "test_treeset_leak",
    "test_treemap_leak",
    "test_priorityqueue_leak"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Collections Memory Leak Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Project: fafafa.core"
Write-Host "Tool: Free Pascal HeapTrc (-gh -gl)"
Write-Host ""

$TOTAL = $TESTS.Count
$PASSED = 0
$FAILED = 0
$FAILED_TESTS = @()

# 编译和运行每个测试
foreach ($TEST_NAME in $TESTS) {
    $TEST_FILE = Join-Path $TEST_DIR "$TEST_NAME.pas"
    $BIN_FILE = Join-Path $BIN_DIR "$TEST_NAME.exe"
    $LOG_FILE = Join-Path $LOG_DIR "$TEST_NAME.log"
    
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "Testing: $TEST_NAME" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    # 检查测试文件是否存在
    if (-not (Test-Path $TEST_FILE)) {
        Write-Host "  ⚠️  Test file not found: $TEST_FILE" -ForegroundColor Yellow
        Write-Host "  SKIPPED" -ForegroundColor Yellow
        $FAILED++
        $FAILED_TESTS += "$TEST_NAME (file not found)"
        continue
    }
    
    # 编译测试（带 HeapTrc）
    Write-Host "  Compiling with HeapTrc..."
    $SRC_DIR = Join-Path $PROJECT_ROOT "src"
    
    $CompileArgs = @(
        "-gh",           # 启用堆追踪
        "-gl",           # 启用行号信息
        "-B",            # 完全重新编译
        "-Fi$SRC_DIR",   # Include路径
        "-Fu$SRC_DIR",   # Unit路径
        "-FE$BIN_DIR",   # 输出目录
        "-o$BIN_FILE",   # 输出文件
        $TEST_FILE       # 源文件
    )
    
    try {
        & $FpcPath $CompileArgs > $LOG_FILE 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Compilation successful" -ForegroundColor Green
        } else {
            throw "Compilation failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "  ❌ Compilation failed" -ForegroundColor Red
        Write-Host "  See log: $LOG_FILE" -ForegroundColor Red
        $FAILED++
        $FAILED_TESTS += "$TEST_NAME (compilation failed)"
        continue
    }
    
    # 运行测试
    Write-Host "  Running test..."
    $RUN_LOG = "$LOG_FILE.run"
    
    try {
        & $BIN_FILE > $RUN_LOG 2>&1
        $RUN_RC = $LASTEXITCODE
        
        if ($RUN_RC -eq 0) {
            Write-Host "  ✅ Test executed" -ForegroundColor Green
        } else {
            throw "Test execution failed with exit code $RUN_RC"
        }
        
        # 将运行输出追加到日志
        Get-Content $RUN_LOG | Add-Content $LOG_FILE
        Remove-Item $RUN_LOG -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "  ❌ Test execution failed" -ForegroundColor Red
        if (Test-Path $RUN_LOG) {
            Get-Content $RUN_LOG | Add-Content $LOG_FILE
            Remove-Item $RUN_LOG -ErrorAction SilentlyContinue
        }
        $FAILED++
        $FAILED_TESTS += "$TEST_NAME (execution failed)"
        continue
    }
    
    # 检查内存泄漏
    $LogContent = Get-Content $LOG_FILE -Raw
    if ($LogContent -match "0 unfreed memory blocks") {
        Write-Host "  ✅ NO MEMORY LEAKS - Test passed!" -ForegroundColor Green
        $PASSED++
    } else {
        Write-Host "  ❌ MEMORY LEAK DETECTED!" -ForegroundColor Red
        Write-Host "  See details: $LOG_FILE" -ForegroundColor Red
        $FAILED++
        $FAILED_TESTS += "$TEST_NAME (memory leak)"
    }
    
    Write-Host ""
}

# 生成报告
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total tests: $TOTAL"
Write-Host "Passed: $PASSED" -ForegroundColor Green
Write-Host "Failed: $FAILED" -ForegroundColor Red
Write-Host ""

if ($FAILED -gt 0) {
    Write-Host "Failed tests:" -ForegroundColor Red
    foreach ($FAILED_TEST in $FAILED_TESTS) {
        Write-Host "  - $FAILED_TEST" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "Detailed logs: $LOG_DIR"
Write-Host "Report will be generated: $REPORT_FILE"
Write-Host ""

# 生成 Markdown 报告
$PASS_RATE = [math]::Round(($PASSED / $TOTAL) * 100, 0)
if ($FAILED -eq 0) {
    $CONCLUSION = "✅ 所有测试通过，无内存泄漏"
} else {
    $CONCLUSION = "❌ 检测到内存泄漏或测试失败"
}

$ReportContent = "# Collections 内存泄漏验证报告`n`n"
$ReportContent += "**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$ReportContent += "**测试工具**: Free Pascal HeapTrc`n"
$ReportContent += "**编译选项**: ``-gh -gl`` (启用堆追踪和行号信息)`n`n"
$ReportContent += "---`n`n"
$ReportContent += "## 📊 执行摘要`n`n"
$ReportContent += "| 指标 | 值 |`n"
$ReportContent += "|------|-----|`n"
$ReportContent += "| 总测试数 | $TOTAL |`n"
$ReportContent += "| ✅ 通过 | $PASSED |`n"
$ReportContent += "| ❌ 失败 | $FAILED |`n"
$ReportContent += "| 通过率 | $PASS_RATE% |`n`n"
$ReportContent += "**结论**: $CONCLUSION`n`n"
$ReportContent += "---`n`n"
$ReportContent += "## 📋 测试结果详情`n`n"

# 为每个测试添加详情
foreach ($TEST_NAME in $TESTS) {
    $LOG_FILE = Join-Path $LOG_DIR "$TEST_NAME.log"
    
    $ReportContent += "`n### $TEST_NAME`n`n"
    
    if (-not (Test-Path $LOG_FILE)) {
        $ReportContent += "⚠️ **状态**: SKIPPED (测试文件不存在)`n"
    } elseif ((Get-Content $LOG_FILE -Raw) -match "0 unfreed memory blocks") {
        $ReportContent += "✅ **状态**: PASSED (无内存泄漏)`n`n"
        $ReportContent += "**HeapTrc 输出**:`n``````n"
        
        # 提取HeapTrc输出
        $LogContent = Get-Content $LOG_FILE -Raw
        if ($LogContent -match "Heap dump[\s\S]*?(?=\r?\n\r?\n|\z)") {
            $HeapDump = $Matches[0] -split "`n" | Select-Object -First 10
            $ReportContent += ($HeapDump -join "`n") + "`n"
        } else {
            $ReportContent += "(未找到 HeapTrc 输出)`n"
        }
        $ReportContent += "```````n"
    } else {
        $ReportContent += "❌ **状态**: FAILED`n`n"
        $ReportContent += "**错误信息**: 请查看日志文件 ``$LOG_FILE```n"
    }
    
    $ReportContent += "`n---`n"
}

# 添加报告尾部
$ReportContent += "`n## 📁 日志文件`n`n"
$ReportContent += "所有详细日志保存在: ``$LOG_DIR```n`n"
$ReportContent += "- 编译日志和运行输出在各自的 ``.log`` 文件中`n"
$ReportContent += "- HeapTrc 内存泄漏报告包含在运行输出中`n`n"
$ReportContent += "---`n`n"
$ReportContent += "## 🔍 如何手动运行单个测试`n`n"
$ReportContent += "``````powershell`n"
$ReportContent += "# 编译`n"
$ReportContent += "fpc -gh -gl -B -Fu./src -Fi./src -FE./tests/leak_test_bin -otest_name.exe tests/test_name.pas`n`n"
$ReportContent += "# 运行`n"
$ReportContent += "./tests/leak_test_bin/test_name.exe`n`n"
$ReportContent += "# 检查输出中是否包含:`n"
$ReportContent += "# `"0 unfreed memory blocks`"`n"
$ReportContent += "```````n`n"
$ReportContent += "---`n`n"
$ReportContent += "**报告结束**`n"

# 写入报告
$ReportContent | Out-File -FilePath $REPORT_FILE -Encoding UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Report generated: $REPORT_FILE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 返回退出码
if ($FAILED -eq 0) {
    exit 0
} else {
    exit 1
}
