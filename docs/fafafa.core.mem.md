# fafafa.core.mem

## 概述 Overview

`fafafa.core.mem` 是 fafafa.core 框架中的核心内存管理模块，作为统一的内存管理入口，重新导出了 `fafafa.core.mem.utils` 和 `fafafa.core.mem.allocator` 模块的功能。

`fafafa.core.mem` is the core memory management module in the fafafa.core framework, serving as a unified entry point for memory management by re-exporting functionality from `fafafa.core.mem.utils` and `fafafa.core.mem.allocator` modules.

## 设计理念 Design Philosophy

### 核心原则 Core Principles

- **简洁性 Simplicity**: 作为重新导出模块，保持 API 简洁明了
- **一致性 Consistency**: 与现有 fafafa.core 模块风格保持一致
- **易用性 Usability**: 提供统一的内存管理入口
- **跨平台 Cross-platform**: Windows/Linux 兼容

### FreePascal 编程范式

本模块遵循传统的 Pascal 内存管理方式，避免复杂的泛型和操作符重载，保持代码简洁和可读性。

## 功能特性 Features

### 内存操作函数 Memory Operation Functions

重新导出自 `fafafa.core.mem.utils`：

- **重叠检查 Overlap Detection**: `IsOverlap`, `IsOverlapUnChecked`
- **内存复制 Memory Copy**: `Copy`, `CopyUnChecked`, `CopyNonOverlap`, `CopyNonOverlapUnChecked`
- **内存填充 Memory Fill**: `Fill`, `Zero`
- **内存比较 Memory Compare**: `Compare`, `Equal`
- **内存对齐 Memory Alignment**: `IsAligned`, `AlignUp`, `AlignUpUnChecked`

### 内存分配器 Memory Allocators

重新导出自 `fafafa.core.mem.allocator`：

- 分配器类型：本框架示例与测试统一使用 `TAllocator`（不在门面层导出接口类型）
- 具体实现：`TCallbackAllocator`, `TRtlAllocator`, `TCrtAllocator`
- 获取函数：`GetRtlAllocator`, `GetCrtAllocator`

### 基础池（按需直接 uses 子单元）

- `fafafa.core.mem.memPool`：固定大小块的通用内存池 TMemPool
- `fafafa.core.mem.stackPool`：顺序分配/批量释放的栈式内存池 TStackPool
- `fafafa.core.mem.pool.slab`：基于页的 slab 分配器 TSlabPool（支持统计/预热/可选页面合并）

## API 参考 API Reference

### 内存操作函数 Memory Operation Functions

#### 重叠检查 Overlap Detection

```pascal
function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean;
function IsOverlap(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
```

检查两个内存区域是否重叠。

**参数 Parameters:**
- `aPtr1`, `aPtr2`: 内存指针 Memory pointers
- `aSize1`, `aSize2`, `aSize`: 内存大小 Memory sizes

**返回值 Returns:** 如果重叠返回 `True` Returns `True` if overlapping

#### 内存复制 Memory Copy

```pascal
procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt);
procedure CopyNonOverlap(aSrc, aDst: Pointer; aSize: SizeUInt);
```

复制内存内容。`Copy` 处理重叠情况，`CopyNonOverlap` 假设无重叠。

**参数 Parameters:**
- `aSrc`: 源指针 Source pointer
- `aDst`: 目标指针 Destination pointer
- `aSize`: 复制大小 Copy size

#### 内存填充 Memory Fill

```pascal
procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8);
procedure Zero(aDst: Pointer; aSize: SizeUInt);
```

填充内存。`Fill` 用指定值填充，`Zero` 用零填充。

**参数 Parameters:**
- `aDst`: 目标指针 Destination pointer
- `aCount`, `aSize`: 填充大小 Fill size
- `aValue`: 填充值 Fill value

#### 内存比较 Memory Compare

```pascal
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
```

比较内存内容。`Compare` 返回比较结果，`Equal` 返回是否相等。

**参数 Parameters:**
- `aPtr1`, `aPtr2`: 比较的指针 Pointers to compare
- `aCount`, `aSize`: 比较大小 Compare size

**返回值 Returns:**
- `Compare`: `<0`, `0`, `>0` 表示小于、等于、大于
- `Equal`: `True` 如果相等 if equal

#### 内存对齐 Memory Alignment

```pascal
function IsAligned(aPtr: Pointer; aAlignment: SizeUInt = SizeOf(Pointer)): Boolean;
function AlignUp(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer;
function AlignDown(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer;
function IsPowerOfTwo(N: SizeUInt): Boolean;
```

检查和调整内存对齐。

重要：Alignment 参数必须是 2 的幂（power of two）。否则 `AlignUp/AlignDown` 将抛出 `EInvalidArgument`。

最小示例（异常语义）：
```pascal
uses fafafa.core.mem.utils;
var P: Pointer;
begin
  GetMem(P, 64);
  try
    AlignUp(P, 16);   // OK
    AlignDown(P, 16); // OK
    AlignUp(P, 3);    // 抛 EInvalidArgument
  finally
    FreeMem(P);
  end;
end;
```
更多示例：`examples/fafafa.core.mem/example_align_exceptions.lpr`。

**参数 Parameters:**
- `aPtr`: 要检查的指针 Pointer to check
- `aAlignment`: 对齐字节数 Alignment bytes

### 对齐分配（独立单元，不在门面导出） Aligned Allocation (separate unit)

本框架提供独立的对齐分配单元 `fafafa.core.mem.aligned`，用于申请特定对齐的内存块：

- 函数：`AllocAligned(size, alignment): Pointer` / `FreeAligned(ptr: Pointer)`
- 约束：`alignment` 必须是 2 的幂，且 `alignment >= SizeOf(Pointer)`，否则抛 `EInvalidArgument`
- 平台策略：
  - Windows：使用 `_aligned_malloc/_aligned_free`
  - Unix：使用 `posix_memalign`（释放用 `libc free`）
  - 其他：回退到 over-allocate + 手工对齐（返回指针前保存原始指针，释放时先还原）
- 门面不导出：请按需 `uses fafafa.core.mem.aligned`




示例：
```pascal
uses fafafa.core.mem.aligned;
var P: Pointer;
begin
  P := AllocAligned(1024, 32);
  try
    // 使用 P（32 字节对齐）
  finally
    FreeAligned(P);
  end;
end;
```

最佳实践：大多数情形推荐使用 `TStackPool.Alloc(ASize, AAlignment)` 或 `AllocAligned/TryAllocAligned`（适合短生命周期临时缓冲），确需独立生命周期或与 C API 交互时再使用 `AllocAligned/FreeAligned`。

对齐矩阵建议（Alignment Matrix — 常见场景）：
- 8 bytes：通用 CPU 指针对齐；默认足够
- 16 bytes：SSE/NEON 等 SIMD 基本对齐；小型向量运算
- 32 bytes：AVX/宽向量；更高带宽场景
- 64 bytes：cache line 对齐；避免伪共享/提升顺序扫描性能
注意：实际需求取决于目标平台和编译选项；请依据真实性能数据做选择。过度对齐可能浪费内存。

### 内存分配器 Memory Allocators

#### 获取分配器 Getting Allocators

```pascal
function GetRtlAllocator: TAllocator;
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
function GetCrtAllocator: TAllocator;
{$ENDIF}
```

获取系统分配器实例。

**返回值 Returns:** 分配器实例 Allocator instance

#### 分配器能力（Traits）

分配器的能力可通过 `IAllocator.Traits: TAllocatorTraits` 查询（只读、不抛异常）：

- `ZeroInitialized`: `AllocMem` 是否保证零填充（当前 TRtl/TCrt/TMimalloc 均为 True）
- `ThreadSafe`: 是否线程安全（默认 True）
- `SupportsAligned`: 是否原生支持对齐分配（当前均为 False；请使用 `fafafa.core.mem.aligned` 或桥接器）
- `HasMemSize`: 是否支持查询已分配块大小（当前均为 False；未来若接入 `mi_usable_size` 等再开启）

#### 分配器类型（本框架不使用接口）

```pascal
type
  TAllocator = class
    function GetMem(aSize: SizeUInt): Pointer;
    function ReallocMem(aPtr: Pointer; aSize: SizeUInt): Pointer;
    procedure FreeMem(aPtr: Pointer);
  end;
```

## 使用示例 Usage Examples

### 基本内存操作 Basic Memory Operations

```pascal
uses fafafa.core.mem;

var
  LBuffer1, LBuffer2: Pointer;
  LSize: SizeUInt;
begin
  LSize := 256;
  LBuffer1 := GetMem(LSize);
  LBuffer2 := GetMem(LSize);

  try
    // 填充内存
    Fill(LBuffer1, LSize, $AA);

    // 复制内存
    Copy(LBuffer1, LBuffer2, LSize);

    // 比较内存
    if Equal(LBuffer1, LBuffer2, LSize) then
      WriteLn('Memory contents are equal');

    // 清零内存
    Zero(LBuffer1, LSize);

  finally
    FreeMem(LBuffer1);
    FreeMem(LBuffer2);
  end;
end;
```

### 使用分配器 Using Allocators

```pascal
uses fafafa.core.mem;

var
  LAllocator: TAllocator;
  LPtr: Pointer;
begin
  LAllocator := GetRtlAllocator;

  LPtr := LAllocator.GetMem(1024);
  try
    // 使用内存
    Fill(LPtr, 1024, $55);

    // 重新分配
    LPtr := LAllocator.ReallocMem(LPtr, 2048);

  finally
    LAllocator.FreeMem(LPtr);
  end;
end;
```

### StackPool 作用域（最佳实践） StackPool Scoped Usage (Best Practice)

使用 RAII 风格的作用域守卫，进入作用域保存状态、离开作用域自动恢复状态：

```pascal
uses fafafa.core.mem.stackPool, fafafa.core.mem.stack_scope_helpers;
var S: TStackPool; Guard: TStackScopeGuard; P1, P2: Pointer;
begin
  S := TStackPool.Create(1024);
  try
    Guard := TStackScopeGuard.Enter(S);
    try
      P1 := S.Alloc(128);
      P2 := S.Alloc(256, 16);
      // ... 使用 P1/P2
    finally
      Guard.Leave; // 恢复状态，隐式释放本作用域内的分配
    end;
  finally
    S.Destroy;
  end;
end;
```


## 性能考虑 Performance Considerations

- 所有重新导出的函数都是内联的，没有额外的函数调用开销
- 内存操作函数针对不同场景进行了优化
- 分配器提供了统一的接口，便于性能测试和优化
- 基准测试：mem 模块暂不提供独立 benchmark 工具。统一的 benchmark 能力将由框架层（fafafa.core.benchmark）提供与维护；当前可参考 examples 中的演示程序与 Slab 的 Diagnostics/PerfCounters。

### 分配器级统计与故障注入（宏控，默认关闭） Allocator Instrumentation (macro-controlled)

- 开关：在工程编译选项或 settings.inc 中定义 `FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION`
- API（单元：`fafafa.core.mem.allocator.instrumentation`）
  - 统计：`AllocatorStats_Reset` / `AllocatorStats_Snapshot(out S)`
  - 计数钩子（由基类调用）：`AllocatorStats_OnAlloc/OnRealloc/OnFree`
  - 故障注入：`AllocatorFaults_Enable(True|False)`、`AllocatorFaults_SetFailEvery(N)`、`AllocatorFaults_ShouldFailNow`
- 默认不开启，零开销；建议仅在测试/定位问题时启用

最小示例：
```pascal
uses fafafa.core.mem.allocator, fafafa.core.mem.allocator.instrumentation;
var A: IAllocator; P: Pointer; S: TAllocatorStats;
begin
  // 启用故障注入：每 100 次分配失败一次
  AllocatorFaults_Enable(True);
  AllocatorFaults_SetFailEvery(100);

  AllocatorStats_Reset;
  A := GetRtlAllocator;
  P := A.AllocMem(128);
  if P <> nil then A.FreeMem(P);

  AllocatorStats_Snapshot(S);
  // 此处可断言或打印 S.AllocCount/S.FreeCount 等
end;
```


## 模块边界与依赖说明

- 门面职责仅限：
  - 基础内存操作：Fill/Copy/Zero/Compare/Equal/对齐/Overlap
  - 分配器：TAllocator/TRtlAllocator/TCrtAllocator/TCallbackAllocator

### 接口抽象（预研）
- 新增接口单元：`src/fafafa.core.mem.interfaces.pas`（仅声明接口，不改变现有类用法）
- 目标（P2）：
  - IMemPool/IStackPool/ISlabPool/IAllocator 抽象
  - 未来通过适配器或装饰器对接现有实现与线程安全版本

  - 可选基础池类型：TMemPool/TStackPool/TSlabPool（直接 uses 对应单元）
- 不由门面导出的功能：
  - 对象池/环形缓冲区/增强版池：请直接 uses 相应单元（如 fafafa.core.mem.objectPool 等）
  - 内存映射/共享内存：请使用 fs 子域（如 fafafa.core.fs.mmap）
    - 对齐分配（AllocAligned/FreeAligned）：请使用 `fafafa.core.mem.aligned` 独立单元

建议：在工程中按需精确引用子单元，避免通过门面获取跨域能力，以保持耦合面最小与可维护性最佳。

## 测试 Testing

模块包含完整的单元测试，位于 `tests/fafafa.core.mem/`：

- 内存操作函数测试
- 分配器功能测试
- 基础池（MemPool/StackPool/SlabPool）测试
- 边界用例（Edge Cases）：
  - MemPool：Free(nil) / Double Free / Free 非池指针（分别抛 EMemPoolInvalidPointer/EMemPoolDoubleFree）
  - StackPool：超容量分配返回 nil；RestoreState 越界输入被忽略
  - SlabPool：Warmup 计数；Double Free 宽容断言（抛 ESlabPoolCorruption 或安全忽略）

**测试统计 Test Statistics:**
- 样例（以当前环境为准）：Number of run tests: 106; Errors: 0; Failures: 0
- 启用内存泄漏检测：-gh -gl（Debug 构建）
- 构建工具：lazbuild

运行测试：
```bash
cd tests/fafafa.core.mem
./BuildOrTest.bat  # Windows
./BuildOrTest.sh   # Linux
```

## 示例程序 Example Programs

- 基础门面示例：`examples/fafafa.core.mem/example_mem.lpr`
- 接口优先示例：`examples/fafafa.core.mem/example_mem_interface.lpr`
- 对齐异常语义示例：`examples/fafafa.core.mem/example_align_exceptions.lpr`
- 基础池最小示例：`examples/fafafa.core.mem/example_mem_pool_basic.lpr`

### 接口式使用（建议） Interface-based Usage (Recommended)

对于需要面向抽象编程的场景，可使用 `fafafa.core.mem.interfaces` 与 `fafafa.core.mem.adapters`：

```pascal
uses
  fafafa.core.mem.interfaces,
  fafafa.core.mem.adapters,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.pool.slab;

var
  LMemPool: TMemPool;
  LStack: TStackPool;
  LSlab: TSlabPool;
  IMem: IMemPool;
  IStack: IStackPool;
  ISlab: ISlabPool;
  P: Pointer;
begin
  LMemPool := TMemPool.Create(64, 16);
  try
    IMem := TMemPoolAdapter.Create(LMemPool);
    P := IMem.Alloc;
    TMemPool(LMemPool).ReleasePtr(P); // 推荐别名避免与 TObject.Free 混淆
    IMem.Reset;
  finally
    LMemPool.Destroy;
  end;

  LStack := TStackPool.Create(2048);
  try
    IStack := TStackPoolAdapter.Create(LStack);
    P := IStack.Alloc(128, 16);
    IStack.Reset;
  finally
    LStack.Destroy;
### Try 系列 API 与释放别名（已提供）

- TryAlloc（不抛异常）：
  - MemPool: `function TryAlloc(out APtr: Pointer): Boolean;`
  - StackPool: `function TryAlloc(out APtr: Pointer; ASize: SizeUInt): Boolean; // 默认指针对齐`
  - SlabPool: `function TryAlloc(out APtr: Pointer; ASize: SizeUInt): Boolean;`
- 使用建议：
  - 高频路径尽量使用 Try 系列（失败返回 False、APtr=nil），避免异常开销
  - 需要异常语义时使用 Alloc 原方法
- 释放别名：
  - 为避免与 `TObject.Free` 混淆，建议使用 `ReleasePtr(APtr)` 释放块内存；销毁实例统一使用 `Destroy`

示例：
```pascal
var P: Pointer; ok: Boolean;
ok := LMemPool.TryAlloc(P);
if ok then begin
  try
    // 使用 P
  finally
    LMemPool.ReleasePtr(P);
  end;
end;
```

  end;

  LSlab := TSlabPool.Create(8192);
  try
    ISlab := TSlabPoolAdapter.Create(LSlab);
    P := ISlab.Alloc(256);
    TSlabPool(LSlab).ReleasePtr(P);
    ISlab.Reset;
  finally
    LSlab.Destroy;
  end;
end;
```

- SlabPool 配置示例：`examples/fafafa.core.mem/example_mem_pool_config.lpr`

构建与运行：
- 单个工程（Windows）：
  - `examples/fafafa.core.mem/BuildAndRun.bat debug run`
  - `examples/fafafa.core.mem/BuildAndRun.bat release run`
- 批量构建（Windows）：
  - `examples/fafafa.core.mem/Build_examples.bat`（可选参数：release；默认 Debug）
- Linux（如有环境再执行）：
  - 单个工程：`examples/fafafa.core.mem/BuildAndRun.sh [release] [run]`（默认 Debug）
  - 批量构建：`examples/fafafa.core.mem/Build_examples.sh`

### 示例输出参考 Example Output (may vary)

- example_mem_pool_config（节选）：

```
--- TSlabPool Config Demo ---
Allocated 128 and 256 bytes
Pages: total=8 free=8 partial=0 full=0
Objects: total=208 free=208
--- Diagnostics ---
SlabPool Detailed Diagnostics
=============================
Pool Size: 32768 bytes (8 pages)
...
Page Distribution:
  Free Pages: 8
  Partial Pages: 0
  Full Pages: 0
...
```

## 注意事项 Notes / Best Practices

- 销毁实例：TMemPool/TSlabPool 定义了 `Free(aPtr: Pointer)` 方法，为避免与 `TObject.Free` 同名冲突，请在销毁实例时使用 `Destroy`。
- 释放块内存推荐使用 `ReleasePtr(APtr)`；销毁实例使用 `Destroy`
- 零大小策略：对零大小的分配统一返回 `nil`（不抛异常）
- Try 系列 API：`MemPool.TryAlloc(out P) / StackPool.TryAlloc(Size, out P, Align) / SlabPool.TryAlloc(Size, out P)`（不抛异常）
- SlabPool：`Free(nil)` 安全；双重释放抛 `ESlabPoolCorruption`
- 对齐分配：
  - 不要混用 `FreeMem` 与 `FreeAligned`（使用何种分配方式就用相应释放方式）
  - `alignment` 必须为 2 的幂（例如 8/16/32/64）；建议在 SIMD/设备对齐场景显式传入
  - 需要批量/短生命周期时优先用 `TStackPool.Alloc(ASize, AAlignment)`；需要独立生命周期/跨边界交互时用 `AllocAligned/FreeAligned`


### 常见问题 FAQ（对齐释放/桥接器混用与 TryGet 模式）

- 对齐释放与桥接器混用风险：
  - 用 AllocAlignedWithAllocator(A, ...) 分配的内存，必须用 FreeAlignedWithAllocator(A, P) 释放；不要用 FreeMem 或 FreeAligned 混用
  - 用 AllocAligned(...) 分配的内存，必须用 FreeAligned(P) 释放；不要传给 IAllocator.FreeMem
  - 判定要点：若分配函数需要 allocator 参数，释放也需要同一个 allocator；若分配函数不需要 allocator，则用对应的非 allocator 释放函数

- 推荐的 TryGet* 降级模式（避免异常驱动流程）：
  ```pascal
  var A: IAllocator;
  begin
    if TryGetMimallocAllocator(A) then Exit;
    if TryGetCrtAllocator(A) then Exit;
    if TryGetRtlAllocator(A) then Exit;
    // 若仍失败（极少见），记录日志或进入保底路径
  end;
  ```

- 常见误用对照示例：

  错误示例（AllocAligned 分配却用 A.FreeMem 释放）：
  ```pascal
  uses fafafa.core.mem.allocator, fafafa.core.mem.aligned;
  var A: IAllocator; P: Pointer;
  begin
    A := GetRtlAllocator;
    P := AllocAligned(256, 32);
    A.FreeMem(P); // 错误：应使用 FreeAligned(P)
  end;
  ```
  正确示例：
  ```pascal
  FreeAligned(P);
  ```


- Free(nil) 策略：当前 MemPool 抛 `EMemPoolInvalidPointer`；SlabPool 为安全空操作。收尾阶段评估是否统一为“抛异常”。
- 统计：使用 `fafafa.core.mem.stats` 获取只读统计快照（Mem/Stack/Slab）

- 空操作原则：对零大小的分配/重分配，返回 `nil` 且不进行实际操作；对 `FreeMem(nil)` 将按测试条件编译控制（通常禁止）。
- MemPool.Free 异常语义：
  - 传入 `nil`：抛 `EMemPoolInvalidPointer`
  - 重复释放同一指针：抛 `EMemPoolDoubleFree`

### 一键构建与示例运行指南
- 单元测试（Debug+泄漏跟踪）
  - tests\\fafafa.core.mem\\BuildAndTest.bat
- 示例批量构建（Debug 输出到本目录 bin）
  - examples\\fafafa.core.mem\\Build_examples.bat
- 集成 Runner（示例验证，非单测）
  - examples\\fafafa.core.mem\\bin\\example_mem_integration_runner_debug.exe

  - 非池指针：抛 `EMemPoolInvalidPointer`
- StackPool 状态恢复：`RestoreState(aState)` 仅在 `aState <= TotalSize` 时生效，越界输入被忽略（不修改状态）。
- 对齐：StackPool 的 `Alloc(aSize, aAlignment)` 默认按指针大小对齐；如需特定对齐，显式传入 `aAlignment`。需要严格校验失败即报错的场景，使用 `AllocAligned/TryAllocAligned`（对齐必须为 2 的幂）。
- 构建：推荐使用 lazbuild；Debug 模式启用 `-gh -gl` 便于内存泄漏诊断；示例与测试的输出路径统一在各自项目目录的 `bin/` 子目录（tests/.../bin、examples/.../bin、play/.../bin）。
- 模块边界：门面仅导出基础内存操作与分配器类型；基础池需按需 `uses` 各自单元；mmap/共享内存请使用 fs 子域。

### 常见坑位排查 Checklist

### 术语对照 Glossary
- MemPool.AllocatedCount ≈ 已分配块数（概念上与“UsedCount”一致）
- StackPool.UsedSize / TotalSize / AvailableSize（字节）
- SlabPool：SizeClass（大小类）、Page（页，empty/partial/full）、Double Free（双重释放）

### 版本与获取 Version & Query
- 当前版本常量：`FAFAFA_CORE_MEM_VERSION = '1.1.0'`
- mimalloc（延迟加载）Linux 说明：
  - 动态库加载顺序：`$FAFAFA_MIMALLOC_SO`（如设置）→ `libmimalloc.so` → `libmimalloc.so.2` → `mimalloc`
  - Windows 加载顺序：`mimalloc.dll` → `mimalloc-redirect.dll`
  - 未修改测试脚本：当前仅代码支持，待后续有环境时再补测试脚本
- 运行期获取：`MemVersion` 函数返回当前版本串

### 版本历史 Version History
- v1.1.0 (2025-08-10)
  - 设计收束：接口优先建议、TryAlloc 系列、ReleasePtr 别名
  - 统计助手：GetSlabPoolStats 增补、注意事项/使用提示完善
  - 示例：新增 interface-first 与 microbench；批量脚本纳入
  - 文档：术语对照、Free(nil) 跨池差异说明


- 运行期泄漏：确保回调分配器、池类实例都在 finally 中 Destroy；对象内存释放与实例销毁分开处理。
- 双重释放：TSlabPool.Free 会检测双重释放并抛出异常（ESlabPoolCorruption），出现时请检查业务释放路径。
- 指针对齐：在需要特定 SIMD/设备对齐时，StackPool.Alloc 的第二参数传入目标对齐字节数（2 的幂）。
- 零大小操作：对 Alloc/Realloc(0) 的返回为 nil，调用方不要对 nil 做写操作；FreeMem(nil) 受条件编译控制，不建议依赖。
- 构建环境：优先使用工具脚本（tools\lazbuild.bat 或 lazbuild）；Windows 环境避免手写 fpc 参数，保持与示例工程一致。
- 输出路径：示例与测试的目标统一在仓库 bin/ 目录，避免各自散落，便于清理与 CI 收集。

## 版本历史 Version History

### v1.0.0 (2025-08-06)
- 初始版本
- 重新导出 mem.utils 和 mem.allocator 功能
- 完整的测试覆盖
- 示例程序和文档
