# fafafa.core.atomic 基准测试

本目录包含 fafafa.core.atomic 模块与操作系统原子操作接口的性能对比基准测试。

## 📊 测试目标

对比 fafafa.core.atomic 实现与操作系统提供的原子操作接口（如 Windows Interlocked 函数）的性能差异。

## 🧪 测试类别

### 1. 基础原子操作
- `atomic_load` vs 直接内存读取
- `atomic_store` vs 直接内存写入
- `atomic_exchange` vs `InterlockedExchange`
- `atomic_compare_exchange_strong` vs `InterlockedCompareExchange`

### 2. 算术原子操作
- `atomic_fetch_add` vs `InterlockedExchangeAdd`
- `atomic_fetch_sub` vs `InterlockedExchangeAdd(-value)`
- `atomic_increment` vs `InterlockedIncrement`
- `atomic_decrement` vs `InterlockedDecrement`

### 3. 位操作原子操作
- `atomic_fetch_and` vs 自实现 CAS 循环
- `atomic_fetch_or` vs 自实现 CAS 循环
- `atomic_fetch_xor` vs 自实现 CAS 循环

### 4. 指针原子操作
- `atomic_load` (Pointer) vs 直接指针读取
- `atomic_store` (Pointer) vs 直接指针写入
- `atomic_exchange` (Pointer) vs `InterlockedExchangePointer`
- `atomic_compare_exchange_strong` (Pointer) vs `InterlockedCompareExchangePointer`

### 5. 64位原子操作
- `atomic_load_64` vs 直接读取（32位系统对比）
- `atomic_store_64` vs 直接写入（32位系统对比）
- `atomic_fetch_add_64` vs `InterlockedExchangeAdd64`

### 6. 内存序性能影响
- `mo_relaxed`
- `mo_acquire`
- `mo_release`
- `mo_acq_rel`
- `mo_seq_cst`

### 7. 多线程并发测试
- 单线程 vs 2线程 vs 4线程 vs 8线程
- 高竞争场景下的性能表现
- 缓存行争用影响

## 📁 文件结构

```
benchmarks/fafafa.core.atomic/
├── README.md                           # 本文件
├── bench_atomic_basic.lpr              # 基础原子操作基准测试
├── bench_atomic_arithmetic.lpr         # 算术原子操作基准测试
├── bench_atomic_bitwise.lpr            # 位操作原子操作基准测试
├── bench_atomic_pointer.lpr            # 指针原子操作基准测试
├── bench_atomic_64bit.lpr              # 64位原子操作基准测试
├── bench_atomic_memory_order.lpr       # 内存序性能测试
├── bench_atomic_concurrent.lpr         # 多线程并发测试
├── bench_atomic_comprehensive.lpr      # 综合性能测试
├── buildAndRun.bat                     # Windows 构建运行脚本
├── buildAndRun.sh                      # Linux/macOS 构建运行脚本
├── results/                            # 测试结果目录
│   ├── basic_results.json
│   ├── arithmetic_results.json
│   ├── concurrent_results.json
│   └── comprehensive_report.html
└── utils/                              # 工具函数
    ├── benchmark_utils.pas
    └── os_atomic_wrappers.pas
```

## 🚀 运行方式

### Windows
```batch
buildAndRun.bat
```

### Linux/macOS
```bash
chmod +x buildAndRun.sh
./buildAndRun.sh
```

## 📈 预期结果

基准测试将生成详细的性能对比报告，包括：
- 每种操作的平均执行时间
- 吞吐量对比（ops/sec）
- 内存序开销分析
- 多线程扩展性分析
- 推荐使用场景

## 🎯 性能目标

- fafafa.core.atomic 实现应与系统原子操作性能相当（±10%以内）
- 内存序开销应控制在合理范围内
- 多线程场景下应保持良好的扩展性
