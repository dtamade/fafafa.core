# Lock-Free Data Structures - Build Instructions

## 🏗️ **Project Standards Compliance**

This project follows **Lazarus IDE development standards** and uses `lazbuild` (Lazarus Build Tool) for all compilation tasks instead of direct `fpc` usage.

## 📁 **Project Structure**

```
tests/fafafa.core.lockfree/
├── BUILD.md                           # This file
├── test_correctness_verification.lpr  # Correctness verification program
├── test_correctness_verification.lpi  # Lazarus project file
├── test_all_lockfree.lpr             # Comprehensive test suite
├── test_all_lockfree.lpi             # Lazarus project file
├── test_improved_lockfree.lpr        # Original improvement tests
├── test_improved_lockfree.lpi        # Lazarus project file
└── lib/                              # Build output directory
    └── x86_64-win64/                 # Platform-specific binaries
```

## 🔁 Feature toggles (Macros)

- FAFAFA_CORE_PERF_TESTS: 启用性能/压力类单元测试（默认关闭，日常运行更快）
- FAFAFA_CORE_MAP_INTERFACE: 启用 ILockFreeMap 接口单元与其契约测试（默认关闭，避免影响现有工程）

启用方法：
- Lazarus IDE: Project → Project Options → Compiler Options → Other → Custom Options，添加：
  -dFAFAFA_CORE_PERF_TESTS -dFAFAFA_CORE_MAP_INTERFACE
- lazbuild（示例）：
```bat
lazbuild --build-mode=Debug --build-ide-options=" -dFAFAFA_CORE_PERF_TESTS -dFAFAFA_CORE_MAP_INTERFACE" fafafa.core.lockfree.tests.lpi
```

说明：不定义这些宏时，默认只执行功能/并发基础用例，构建和运行速度更快。

## 🧭 Production Guide（生产使用指南）

- 选择建议（OA vs MM）
  - OA（开放寻址）优先：容量可预估、键/值简单、删除比例低、追求低延迟/高命中
  - MM（分离链接）优先：插入/删除频繁、冲突/并发高、规模动态变化
- Clear/Resize 边界
  - Clear：仅在“无并发访问”时调用（quiescent-only）；用于重新上电、场景切换或测试清理
  - Resize：当前不支持在线扩容；请在创建时规划 Capacity（建议 2^n，装载因子 ≤ 0.7）
- Put/Insert/Remove 语义
  - Put = Upsert：存在则覆盖值（Size 不增加），不存在则插入（Size +1）
  - Remove 幂等：存在返回 True 并 Size -1；不存在返回 False
- Key/Value 类型
  - OA：默认使用“=”运算符比较 Key；若 K 无 operator = 或为复杂类型，请提供自定义 Equal/Hash，或选用 MM 实现/接口适配器
- 观测性与统计
  - Size/Capacity 提供基础指标；更详细统计（如 CAS 失败数、探测长度等）按需开启（后续版本逐步提供），默认保持低开销

## 🔒 Concurrency Semantics（并发语义要点）

- OA HashMap 的发布（publish）采用“两相发布” (two-phase publish)：
  - 写入流程：Empty → CAS→Writing → 写 Key/Value/Hash → StoreRelease State=Occupied
  - 读取流程：LoadAcquire State，只有 State=Occupied 才读取/比较并返回 Value
  - 删除流程：CAS Occupied→Deleted（保持探测链连续），Size 使用 relaxed 方式更新
- Clear 并发边界：调用方需保证清空期间无并发读写（quiescent-only）
- 负载与退避：高并发/高负载下建议采用指数退避策略（Sleep(0)/Yield）来减少自旋冲突（后续会在实现/示例中补充）

## 📐 Capacity Planning（容量规划）

- 建议 Capacity 取 2^n（例如 1024/2048/4096），便于按位与寻址与均匀分布
- 目标装载因子 ≤ 0.7：
  - Size ≤ 0.7 × Capacity 时，平均探测长度与延迟更稳定
  - 删除占比高时，建议定期重建或预留更大 Capacity

## 🧪 Contract Tests & Feature Flags（契约测试与开关）

- 若需在统一接口下验证替换实现（OA/MM）：
  - 定义：-dFAFAFA_CORE_MAP_INTERFACE（启用 ILockFreeMap 接口与适配器）
  - 运行：一键构建后自动纳入 fpcunit 测试（默认不开启该宏）
- 性能/压力用例：-dFAFAFA_CORE_PERF_TESTS（默认关闭，建议仅在需要时开启）



## ⚡ Quick Micro Benchmark → Normalize → Summary（建议流程）

- 一键运行（独立命令行/PowerShell 窗口中，避免 IDE 占用文件句柄）：
  - 进入目录：tests/fafafa.core.lockfree
  - 运行：Run_Micro_BatchMatrix_Quick.bat
- 完成后产物：
  - 原始 CSV：tests/fafafa.core.lockfree/logs/micro_matrix_quick_YYYYMMDD_HHMMSS.csv
  - 归一化 CSV：同目录 *_normalized.csv（脚本自动生成）
  - 摘要 Markdown：report/latest/perf_quick_summary_YYYYMMDD-HHMMSS.md（脚本自动生成）
- 手动执行（可选）：
  - 仅归一化：powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\normalize_micro_csv.ps1 "tests\fafafa.core.lockfree\logs\micro_matrix_quick_*.csv"
  - 仅摘要：powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\summarize_quick_matrix.ps1 "tests\fafafa.core.lockfree\logs\micro_matrix_quick_*.csv"
- 备注：
  - PadOn 通常对多核/多线程有显著收益；BackoffOn 需结合场景评估
  - 建议关注 median（中位数）与 mean（均值），过滤个别噪声 run 的影响


## 🔧 **Build Requirements**

- **Lazarus IDE** (with lazbuild tool)
- **Free Pascal Compiler** (FPC) 3.3.1 or later
- **Target Platform**: Windows x64 (can be adapted for other platforms)

## 🚀 **Standard Build Commands**

### **Using lazbuild (Recommended)**

#### **Release Build (Optimized)**
```bash
# Build correctness verification test
lazbuild --build-mode=Release test_correctness_verification.lpi

# Build comprehensive test suite
lazbuild --build-mode=Release test_all_lockfree.lpi

# Build original improvement tests
lazbuild --build-mode=Release test_improved_lockfree.lpi
```

#### **Debug Build (With Debug Info)**
```bash
# Build with debug information and runtime checks
lazbuild --build-mode=Debug test_correctness_verification.lpi
lazbuild --build-mode=Debug test_all_lockfree.lpi
lazbuild --build-mode=Debug test_improved_lockfree.lpi
```

#### **Clean Build (Force Rebuild)**
```bash
# Clean and rebuild from scratch
lazbuild --build-all --build-mode=Release test_correctness_verification.lpi
```

### **Build Modes Explained**

#### **Release Mode**
- **Optimization**: Level 3 (-O3)
- **Debug Info**: Disabled
- **Runtime Checks**: Disabled
- **Smart Linking**: Enabled
- **Use Case**: Production testing, performance benchmarks

#### **Debug Mode**
- **Optimization**: Disabled
- **Debug Info**: DWARF3 format
- **Runtime Checks**: IO, Range, Overflow, Stack checks enabled
- **Heap Tracing**: Enabled
- **Use Case**: Development, debugging, correctness verification

## 🎯 **Running Tests**

### **Correctness Verification**
```bash
# Build and run correctness tests
lazbuild --build-mode=Release test_correctness_verification.lpi
./test_correctness_verification.exe
```

**Expected Output:**
- ✅ ABA Problem Prevention Test
- ✅ Edge Cases Test
- ✅ Memory Ordering Correctness Test
- ✅ Algorithm Implementation Correctness Test

### **Comprehensive Test Suite**
```bash
# Build and run all lock-free data structure tests
lazbuild --build-mode=Release test_all_lockfree.lpi
./test_all_lockfree.exe
```

**Tests Included:**
- Michael & Michael's Hash Map
- Lock-free Priority Queue (Skip List)
- Lock-free Deque (Work-Stealing)
- Lock-free Ring Buffer (Disruptor Style)
- Performance Benchmarks

### **OA HashMap Extra Tests**
```bash
# Build and run OA HashMap extra tests
fpc -Fu"../../src" -FE"./bin" test_oa_hashmap_extras.lpr
./bin/test_oa_hashmap_extras
```

### **Original Improvement Tests**
```bash
# Build and run original improvement verification
lazbuild --build-mode=Release test_improved_lockfree.lpi

### **Padding Smoke Test**
```bash
# Build and run padding smoke test
fpc -Fu"../../src" -FE"./bin" test_padding_smoke.lpr
./bin/test_padding_smoke
```

### **Windows 一键脚本（推荐）**
```bat
REM 进入目录
tests\fafafa.core.lockfree

REM 使用通用一键脚本
BuildAndTest.bat

REM 或使用专业版（lazbuild 优先）
BuildOrTest-Lazbuild.bat all
```

### 最小回归测试（Minimal）
- 目的：快速验证关键 API 一致性（MM/OA）、OA 墓碑与容量边界、托管类型资源安全路径
- 入口（推荐）：
  - Windows: `BuildOrTest.bat minimal`
  - 或 `BuildAndTest.bat minimal`（内部转调 BuildOrTest.bat minimal）
  - Runner 工程：`BuildOrTest.bat minimal-runner` 或 `BuildAndTest.bat minimal-runner`
- 运行内容：
  - `test_api_aliases.exe`（API 别名一致性/插入与 Upsert 差异）
  - `test_oa_tombstone_stress.exe`（小容量下删除/再插入与墓碑复用行为）
  - `test_resource_safety_basic.exe`（string 键/值的 Put/Update/Remove/Clear/Destroy 路径）
- 可选 runner：`test_minimal_suite.lpi/.lpr`（一次性调用上述三个 exe）

- 日志快速摘要：
  - 最小三项：`Summarize_Minimal.bat`（默认读取 logs\latest_minimal.log）
  - runner：`Summarize_Minimal_Runner.bat`（默认读取 logs\latest_minimal_runner.log）
  - 接口/工厂扩展：`Summarize_Ifaces_Factories.bat`（默认读取 logs\latest_ifaces_factories.log）

- 日志一键汇总：
  - `Summarize_All_Logs.bat`（依次汇总 Minimal/Runner/Ifaces_Factories/Benchmark 摘要）
  - 输出文件：`logs\summary_latest.txt`
- Smoke 队列（SPSC/MPMC + RingBuffer）计时：
  - 运行：`set SMOKE_TIMER=1 && set SMOKE_OPS=200000 && BuildOrTest.bat minimal`
  - 日志：`logs\latest_smoke_queues.log`（包含 `RingBuffer smoke timer: ...`）

- 生成 RingBuffer 性能报告（Markdown）：
  - 先运行摘要/CSV：`Summarize_Smoke_Queues.bat`（会生成 logs\smoke_ringbuffer_times.csv）
  - 一键生成与预览：`Summarize_All_Logs.bat`（自动调用生成报告并将前 40 行预览插入 summary_latest.txt）
  - 或单独生成：`powershell -NoProfile -ExecutionPolicy Bypass -File .\Generate_Smoke_Report.ps1 -RecentN 15`
  - 报告与原始数据：
    - 报告：`logs\report_smoke_ringbuffer.md`
    - CSV：`logs\smoke_ringbuffer_times.csv`



./test_improved_lockfree.exe
```

## 🔍 **Troubleshooting**

### **Common Issues**

#### **"lazbuild not found"**
```bash
# Ensure Lazarus is in PATH, or use full path:
"C:\lazarus\lazbuild.exe" --build-mode=Release test_correctness_verification.lpi
```

#### **"Unit not found" errors**
- Verify that `../../src` path is correct in .lpi files
- Check that all source files exist in the src directory
- Ensure proper unit search paths in project options

#### **Build fails with optimization errors**
```bash
# Try building without optimization first
lazbuild --build-mode=Debug test_correctness_verification.lpi
```

### **Verbose Build Output**
```bash
# Get detailed build information
lazbuild --verbose --build-mode=Release test_correctness_verification.lpi
```

## 📋 **Project File Configuration**

Each `.lpi` file is configured with:

### **Search Paths**
- **Source Units**: `../../src` (relative to test directory)
- **Include Files**: `$(ProjOutDir)`
- **Unit Output**: `lib/$(TargetCPU)-$(TargetOS)/`

### **Compiler Options**
- **Mode**: ObjFPC with {$H+} (AnsiString)
- **Syntax**: Include assertion code (Debug mode)
- **Optimization**: Level 2-3 (Release mode)
- **Linking**: Smart linking enabled

### **Target Configuration**
- **Platform**: x86_64-win64
- **Executable**: Same name as .lpr file
- **Output Directory**: Project root

## 🎨 **IDE Integration**

### **Opening in Lazarus IDE**
1. Launch Lazarus IDE
2. File → Open Project
3. Select any `.lpi` file
4. Use IDE's build commands (F9, Ctrl+F9, etc.)

### **IDE Build Commands**
- **F9**: Compile and Run
- **Ctrl+F9**: Compile Only
- **Shift+F9**: Quick Compile
- **Ctrl+Shift+F9**: Build All

## ⚠️ **Important Notes**

### **DO NOT Use Direct FPC**
❌ **Incorrect:**
```bash
fpc -O3 test_correctness_verification.lpr -Fu../../src
```

✅ **Correct:**
```bash
lazbuild --build-mode=Release test_correctness_verification.lpi
```

### **Why lazbuild?**
1. **Project Standards**: Follows established development workflow
2. **IDE Integration**: Seamless integration with Lazarus IDE
3. **Build Modes**: Proper Debug/Release configuration management
4. **Dependency Management**: Automatic unit path resolution
5. **Cross-Platform**: Consistent builds across different platforms

## 📈 **Performance Considerations**

### **Release vs Debug Performance**
- **Release builds** are ~3-5x faster due to optimizations
- **Debug builds** include runtime checks that impact performance
- **Always use Release mode** for performance benchmarks

### **Expected Performance (Release Mode)**
- **Hash Map Insert**: ~300K ops/sec
- **Hash Map Lookup**: ~350K ops/sec
- **Ring Buffer**: ~6M ops/sec
- **Stack Operations**: ~7-9M ops/sec

## 🔄 **Continuous Integration**

For CI/CD pipelines, use:
```bash
# Automated build script

### 基准结果摘要（PadOn/PadOff）
- 运行基准并生成日志：
  - `BuildAndTest.bat benchmark-compare`
- 快速查看摘要：
  - `Summarize_Benchmark_PadCompare.bat`（默认读取 logs\latest.log）
  - 或指定日志：`Summarize_Benchmark_PadCompare.bat logs\benchmark_pad_compare_YYYY-MM-DD_HH-MM-SS.log 80`

lazbuild --no-write-project --build-mode=Release test_correctness_verification.lpi
lazbuild --no-write-project --build-mode=Release test_all_lockfree.lpi
lazbuild --no-write-project --build-mode=Release test_improved_lockfree.lpi
```

The `--no-write-project` flag prevents modification of .lpi files during automated builds.
