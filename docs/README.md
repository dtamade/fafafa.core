- 测试执行指南：见 docs/TESTING.md（bat/sh 全仓测试脚本、快速回归与全量策略、日志与汇总位置）

# fafafa.core - Documentation Index

- See partial: docs/partials/xml.best_practices.md for XML output best practices (XmlEscape vs XmlEscapeXML10Strict)




## Collections 快速入口
- TVec 快速上手与容量管理：docs/README_TVec.md
- VecDeque 参考：docs/README_VecDeque.md

## 构建与运行（Windows）
- 请使用模块内脚本（符合目录规范）：
  - 测试与基准一键：src/tests/run_all_tests_and_bench.bat
  - TOML 子集：src/tests/BuildOrTest.bat
  - Vec 基准（扩展）：src/tests/tools/run_vec_bench_ext.bat


## YAML 模块文档
- 快速上手：docs/yaml_quickstart.md
- 设计与进度：report/fafafa.core.yaml.md
- 实现路线：统一采用 tokenizer（src/fafafa.core.yaml.tokenizer.pas）；旧 scan/input/scanner 栈已移除，避免重复维护与混淆
- 使用规范：仅通过门面单元 `fafafa.core.yaml` 访问 API；内部 TYaml*/PYaml* 为实现细节
- 示例：examples/fafafa.core.yaml/quick_example

# JSON Facade Update (MIGRATION)

- The facade was merged into `fafafa.core.json`. Remove `fafafa.core.json.facade` from your uses and import `fafafa.core.json` instead.
- Writer now throws `EJsonParseError('Document has no root value')` when writing a document without root.
- `IJsonDocument` exposes `Root`, `Allocator`, `BytesRead`, `ValuesRead`.

Quick example:

```
var R: IJsonReader; W: IJsonWriter; D: IJsonDocument; S: String;
R := CreateJsonReader(nil);
D := R.ReadFromString('{"a":1}', []);
W := CreateJsonWriter;
S := W.WriteToString(D, [jwfPretty]);
```


## Upgrade Guide (Facade helpers)

- Replace exception-throwing Get* with TryGet/OrDefault when tolerant behavior is desired.
- Replace manual loops with JsonArrayForEach / JsonObjectForEach for clarity and early-stop.
- Prefer JsonPointerGet for read-only path access.

Examples:

- Replace Get* with TryGet/OrDefault
```
// Before (may raise EJsonValueError)
val := V.GetInteger;

// After (no exception)
var i: Int64; if JsonTryGetInt(V, i) then ... else ...;
// Or
var j := JsonGetIntOrDefault(V, -1);
```

- Replace manual loops with ForEach (array)
```
// Before
for i := 0 to Arr.GetArraySize-1 do
begin
  Item := Arr.GetArrayItem(i);
  ...
end;

// After
JsonArrayForEach(Arr, function(I: SizeUInt; Item: IJsonValue): Boolean
begin
  ...
  Result := True; // return False to stop early
end);
```

- Replace manual key iteration with ForEach (object)
```
JsonObjectForEach(Obj, function(const Key: String; Val: IJsonValue): Boolean
begin
  ...
  Result := True;
end);
```

- Combine ForEach + Typed TryGet to reduce string compares in hot paths
```
if JsonTryGetObjectValue(Root, 'nums', V) then
  JsonArrayForEach(V, function(I: SizeUInt; Item: IJsonValue): Boolean
  var n: Int64; ok: Boolean;
  begin
    ok := JsonTryGetInt(Item, n); if ok then Inc(sum, n);
    Result := True;
  end);
```


## GHASH Backend & Bench Quick Links
- GHASH 后端选择与环境变量：docs/README_crypto_GHASH_backends.md
- GHASH 基准快照：README_benchmark_GHASH.md

## Collections 快速入口
- TVec 模块文档与增长策略说明：docs/fafafa.core.collections.vec.md
- 集合系统概览与增长策略要点：docs/fafafa.core.collections.md（含“TVec 接口与增长策略要点（重要）”小节）
- Collections API 索引：docs/API_collections.md
- Best Practices（策略组合与对齐建议）：docs/partials/collections.best_practices.md
- 示例总表（TVec/TVecDeque）：docs/EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque）
- 示例索引（一键脚本与示例清单）：examples/fafafa.core.collections/README.md


See CHANGELOG.md for details.
- Term Paste 后端微基准：docs/benchmarks.md#term-paste-backends-微基准legacy-vs-ring；模块章节详解：docs/fafafa.core.term.md#paste-后端选择与推荐配置



# 🚀 FaFaFa 无锁数据结构库

## Testing (framework-first, no-CI)
- ADR: docs/adr/ADR-0001-test-kernel-design.md
- Console listener: docs/fafafa.core.test.console.md
- Adapters (external formats, optional): docs/fafafa.core.test.adapters.md
- Quickstart: docs/fafafa.core.test.quickstart.md
  - Best practices: docs/partials/testing.best_practices.md
  - TOML testing guidelines: docs/fafafa.core.toml.testing-guidelines.md

  - Runner 文档：docs/fafafa.core.test.md → 章节「Runner 环境变量与退出码策略」
  - 辅助脚本：scripts/list-tests.ps1, scripts/list-tests.sh（输出匹配用例 JSON）

  - 速查表（Runner & Scripts）：docs/QUICK_REFERENCE.md




## CLI Args Module Positioning (Core vs Extensions)

- Core (stable, minimal, no implicit output)
  - Parsing: GNU/Windows styles, double-dash sentinel, case-insensitive keys (opt), short-flags combo (opt), negative-number ambiguity control, no-prefix negation
  - Subcommands: arbitrary depth, aliases, default subcommand, Run/RunPath
  - Behavior: return integer codes only; printing help/errors is the caller’s job
- Extensions (opt-in)
  - Usage rendering: RenderUsage(Node) returns text; the caller decides whether/when to print
  - Light schema for rendering metadata
  - ENV → argv: ArgsArgvFromEnv('APP_')
  - Persistent flags (registration-time propagation), first-wins
- Reserved (not implemented)
  - CONFIG → argv: ArgsArgvFromToml/ArgsArgvFromJson (opt-in via macros); YAML stub; Completion generators under consideration

Examples: see
- examples/fafafa.core.args.command/example_usage_default
- examples/fafafa.core.args.command/example_help_schema
- examples/fafafa.core.args.command/example_env_merge


## Examples Quick Links

## Quick Switch for Sinks
- Quick Reference: docs/QUICK_REFERENCE.md → “Sink 快速切换（Runner/Benchmark）”
- Full examples: docs/EXAMPLES.md → “Runner/Benchmark Sink 开关最小示例”
- AEAD 最小示例（Append/In‑Place，一键运行）
  - Windows：examples\fafafa.core.crypto\BuildOrRun_MinExample.bat
  - Linux/macOS：./examples/fafafa.core.crypto/BuildOrRun_MinExample.sh
  - 源码：examples/fafafa.core.crypto/example_aead_inplace_append_min.pas
  - 文档：docs/fafafa.core.crypto.aead.md（契约/脚本/期望输出）


- Socket minimal nonblocking poller (one-click run):
  - Windows: examples\fafafa.core.socket\run_example_min.bat
  - Linux/macOS: ./examples/fafafa.core.socket/run_example_min.sh


## FAQ Quick Links
- Socket troubleshooting (Windows “Disk Full” on console/redirect): see docs/FAQ.md → section “fafafa.core.socket”


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pascal](https://img.shields.io/badge/Pascal-Free%20Pascal-blue.svg)](https://www.freepascal.org/)
[![Performance](https://img.shields.io/badge/Performance-125M%20ops%2Fsec-green.svg)](#性能基准)

一个高性能的无锁数据结构库，基于学术界验证的算法实现，为 Pascal/Delphi 提供工业级的并发数据结构。

## 🌟 特性

### 📦 数据结构
- **Treiber栈** - 经典无锁栈 (R. Kent Treiber, 1986)
- **预分配安全栈** - 解决ABA问题的安全栈
- **MPSC（Michael-Scott）队列** - 经典无锁队列 (Michael & Scott, 1996)
- **预分配MPMC队列** - 基于Dmitry Vyukov算法
- **SPSC队列** - 高性能单生产者单消费者队列

### 🚀 性能
- **SPSC队列**: 125,000,000 ops/sec
- **MPSC（Michael-Scott）队列**: 31,746,031 ops/sec

## Thread Pool Quick Recipes

常见线程池配置与策略示例：

- 固定线程池（fixed）
```pascal
var P: IThreadPool;
begin
  P := CreateThreadPool(4, 4, 60000, -1, rpAbort);
  P.Submit(function(): Boolean begin Result := True; end);
  P.Shutdown; P.AwaitTermination(3000);
end;
```

- 缓存线程池（cached）
```pascal
var P: IThreadPool;
begin
  P := CreateThreadPool(0, MaxInt, 60000, -1, rpAbort);
  P.Submit(function(): Boolean begin Result := True; end);
  P.Shutdown; P.AwaitTermination(3000);
end;
```

- 单线程池（single）
```pascal
var P: IThreadPool;
begin
  P := CreateThreadPool(1, 1, 60000, -1, rpAbort);
  P.Submit(function(): Boolean begin Result := True; end);
  P.Shutdown; P.AwaitTermination(3000);
end;
```

- 有界队列 + Abort（适合强一致）
```pascal
P := CreateThreadPool(2, 4, 60000, 128, rpAbort);
```

- 有界队列 + CallerRuns（来不及排队则在调用线程执行，保障吞吐）
```pascal
P := CreateThreadPool(2, 4, 60000, 128, rpCallerRuns);
```

- 有界队列 + Discard（可丢弃，业务自行兜底）
```pascal
P := CreateThreadPool(2, 4, 60000, 128, rpDiscard);
```

- 有界队列 + DiscardOldest（丢弃最旧请求，保留新请求的时效性）
```pascal
P := CreateThreadPool(2, 4, 60000, 128, rpDiscardOldest);
```

- OnComplete 回调与 Metrics 快照
```pascal
var P: IThreadPool; M: IThreadPoolMetrics; F: IFuture;
begin
  P := CreateThreadPool(2, 2, 60000, -1, rpAbort);
  F := P.Submit(function(): Boolean begin Result := True; end);
  F.OnComplete(function(): Boolean begin
    WriteLn('Done');
    Result := True;
  end);
  M := P.GetMetrics;
  WriteLn('Active=', M.ActiveCount, ' Submitted=', M.TotalSubmitted);
  P.Shutdown; P.AwaitTermination(3000);
end;
```

## TaskScheduler Quick Metrics

```pascal
var S: ITaskScheduler; M: ITaskSchedulerMetrics; F: IFuture;
begin
  S := CreateTaskScheduler;
  F := S.Schedule(function (Data: Pointer): Boolean begin Result := True; end, 200, nil);
  F.WaitFor(2000);
  M := S.GetMetrics;
  WriteLn('Scheduled=', M.GetTotalScheduled, ' Executed=', M.GetTotalExecuted,
          ' Cancelled=', M.GetTotalCancelled, ' Active=', M.GetActiveTasks,
          ' AvgDelayMs=', M.GetAverageDelayMs:0:1);
  S.Shutdown;
end;
```


- **Treiber栈**: 18,348,623 ops/sec
- **所有实现都达到千万级吞吐量**

### 🔬 质量保证
- **基于学术研究**: 所有算法都有权威论文支持
- **线性化验证**: 通过Lincheck方法论验证
- **严格测试**: 包含正确性、性能、边界条件测试
- **内存安全**: 解决ABA问题，避免内存泄漏

## 🚀 快速开始

### 安装

1. 将 `src` 目录添加到您的项目路径
2. 在您的代码中引用：

```pascal
uses
  fafafa.core.lockfree;
```

### 基本使用

#### SPSC队列 (最高性能)
```pascal
var
  LQueue: TIntegerSPSCQueue;
  LValue: Integer;
begin
  LQueue := CreateIntSPSCQueue(1024);
  try
    // 生产者线程
    LQueue.Enqueue(42);

    // 消费者线程
    if LQueue.Dequeue(LValue) then
      WriteLn('Got: ', LValue);
  finally
    LQueue.Free;
  end;
end;
```

#### Treiber栈 (经典无锁栈)
```pascal
type
  TIntStack = specialize TTreiberStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
begin
  LStack := TIntStack.Create;
  try
    LStack.Push(1);
    LStack.Push(2);
    LStack.Push(3);

    while LStack.Pop(LValue) do
      WriteLn(LValue); // 输出: 3 2 1 (LIFO)
  finally
    LStack.Free;
  end;
end;
```

#### Michael-Scott队列 (经典无锁队列)
```pascal
var
  LQueue: TIntMSQueue;
  LValue: Integer;
begin
  LQueue := CreateIntMSQueue;
  try
    LQueue.Enqueue(1);
    LQueue.Enqueue(2);
    LQueue.Enqueue(3);

    while LQueue.Dequeue(LValue) do
      WriteLn(LValue); // 输出: 1 2 3 (FIFO)
  finally
    LQueue.Free;
  end;
end;
```

#### 预分配MPMC队列 (多生产者多消费者)
```pascal
var
  LQueue: TIntMPMCQueue;
  LValue: Integer;
begin
  LQueue := CreateIntMPMCQueue(1024); // 预分配1024个槽位
  try
    // 多个线程可以同时调用
    if LQueue.Enqueue(42) then
      WriteLn('入队成功');

    if LQueue.Dequeue(LValue) then
      WriteLn('出队: ', LValue);
  finally
    LQueue.Free;
  end;
end;
```

## 📊 性能基准

基于学术级测试框架的真实性能数据：

| 数据结构 | 吞吐量 (ops/sec) | 用例 |
|---------|-----------------|------|
| SPSC队列 | 125,000,000 | 单生产者单消费者 |
| MPSC（Michael-Scott）队列 | 31,746,031 | 多生产者多消费者 |
| 预分配MPMC队列 | 31,746,031 | 多生产者多消费者 |
| Treiber栈 | 18,348,623 | 多线程栈操作 |
| 预分配安全栈 | 9,132,420 | ABA安全的栈操作 |

*测试环境: Intel Core i7, 100万次操作*

## 🔬 算法基础

### 学术支持
我们的实现基于以下权威研究：

1. **Treiber栈**: R. Kent Treiber "Systems Programming: Coping with Parallelism" (1986)
2. **MPSC（Michael-Scott）队列**: Maged M. Michael & Michael L. Scott "Simple, Fast, and Practical Non-Blocking and Blocking Concurrent Queue Algorithms" (PODC 1996)
3. **MPMC队列**: Dmitry Vyukov的多生产者多消费者队列算法
4. **测试方法**: Nikita Koval et al. "Lincheck: A Practical Framework for Testing Concurrent Data Structures on JVM" (CAV 2023)

### 技术特点
- **无锁设计**: 基于原子操作，避免锁竞争
- **ABA安全**: 预分配版本解决了经典的ABA问题
- **内存效率**: 预分配减少动态内存分配开销
- **缓存友好**: 优化的内存访问模式

## 🧪 测试验证

### 线性化测试
```pascal
// 运行学术级测试
academic_stress_test.exe
```

### 性能测试
```pascal
// 运行性能基准测试
final_verification.exe
```

### 测试覆盖
- ✅ 线性化正确性验证 (基于Lincheck方法)
- ✅ 高强度并发压力测试
- ✅ ABA问题专项检测
- ✅ 内存序可见性测试
- ✅ 边界条件稳定性测试
- ✅ 性能回归检测

- [接口抽象与HY策略草案](fafafa.core.lockfree.interfaces.md)
- [配置统一与CODEPAGE清理计划](fafafa.core.settings.plan.md)

- [lockfree 子系统 CODEPAGE 清理完成说明](fafafa.core.lockfree.cleanup.md)



### 文件系统（fafafa.core.fs）快速要点

- Walk OnError 策略（简述）：
  - 策略：`weaContinue / weaSkipSubtree / weaAbort`
  - 默认（OnError=nil）：根路径无效返回负统一错误码；设置为 `weaContinue` 可将此情况视为空遍历（返回 0）
- OpenFileEx 工厂方法：
  - `OpenFileEx(Path, Opts): IFsFile`，失败抛出 EFsError，且异常路径释放实例
- FsOpts* 便捷函数：
  - `FsOptsReadOnly / FsOptsWriteTruncate / FsOptsReadWrite` 为快速构造选项的别名
- 详见：`README_fafafa_core_fs.md` 与 `docs/API.md`

### 文档与最佳实践
- 常见问题：FAQ.md

- API 参考：API.md
- Frequently Asked Questions: FAQ.en.md

- IFsFile 设计说明：../docs/fafafa.core.fs.ifile.md
- 最佳实践速查：BestPractices-Cheatsheet.md（含“终端测试速查”条目）
- Best Practices (EN): BestPractices-Cheatsheet.en.md
- 最佳实践速查（中文）：BestPractices-Cheatsheet.cn.md
- 终端模块测试最佳实践（分片）：partials/term.testing.md | EN: partials/term.testing.en.md
- 终端模块核心合约：../docs/fafafa.core.term.contracts.md
- 事件语义与合并策略：../docs/fafafa.core.term.events.md
- UI 帧循环与双缓冲 diff：../docs/fafafa.core.term.ui_loop.md

- 并发/Lock-Free 代码评审清单：Concurrency_Review_Checklist.md

- 进程模块最佳实践：fafafa.core.process.bestpractices.md（默认配置、宏开关、资源安全、测试与发布清单）



## 📚 文档

- [API参考](docs/API.md)
- [性能调优指南](docs/Performance.md)
- [并发编程最佳实践](docs/BestPractices.md)
- [线程并发模块 · 最佳实践与指南](fafafa.core.thread.md)
- [JSON 模块 Flags（AllowComments/TrailingCommas 等）](fafafa.core.json.md#flags)
- [算法详解](docs/Algorithms.md)

### 并发子系统（线程）
- 线程池（IThreadPool/TFuture）
  - 使用与指标指南：详见 [线程并发模块 · 最佳实践与指南](fafafa.core.thread.md#公共-api-说明摘要)
- 调度器（ITaskScheduler）
  - 指标与示例：详见 [TaskScheduler 指标](fafafa.core.thread.md#taskscheduler-指标)
- 通道（IChannel）
  - 无缓冲/有缓冲语义与示例：详见 [线程并发模块 · 最佳实践与指南](fafafa.core.thread.md#公共-api-说明摘要)


## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

感谢以下研究者和项目的启发：
- R. Kent Treiber (Treiber栈)
- Maged M. Michael & Michael L. Scott（MPSC（Michael-Scott）队列）
- Dmitry Vyukov (MPMC队列算法)
- Nikita Koval et al. (Lincheck测试框架)
- nullprogram.com (C11无锁栈设计)

---

**让并发编程变得简单而高效！** 🚀
