{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem

## Abstract 摘要

Memory management module providing unified memory operations and allocator re-exports.
内存管理模块，提供统一的内存操作和分配器重新导出。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.

---

## Module Documentation 模块文档

### Design Philosophy 设计哲学

fafafa.core.mem 提供 Rust 风格的内存管理，强调：
1. **零成本抽象**：所有热路径函数内联，无运行时开销
2. **显式错误处理**：使用 TAllocResult 而非异常
3. **类型安全**：基于 TMemLayout 的内存布局描述
4. **性能优化**：Phase 4.7 段缓存优化达到 +27.0% 性能提升

fafafa.core.mem provides Rust-style memory management, emphasizing:
1. **Zero-cost abstractions**: All hot-path functions inlined, no runtime overhead
2. **Explicit error handling**: Using TAllocResult instead of exceptions
3. **Type safety**: Memory layout description based on TMemLayout
4. **Performance optimization**: Phase 4.7 segment caching optimization achieved +27.0% performance improvement

### Core Concepts 核心概念

#### 1. Rust 风格分配器接口 (Rust-style Allocator Interface)

**IAlloc 接口**：
- 类似 Rust 的 GlobalAlloc trait
- 零成本抽象，所有方法内联
- 支持对齐分配和重新分配
- 返回 TAllocResult 进行错误处理

**分配器类型**：
- `TSystemAlloc`: 系统默认分配器（GetMem/FreeMem）
- `TAlignedAlloc`: 对齐分配器（支持自定义对齐）
- `TMimalloc`: mimalloc 2.2.6 高性能分配器

#### 2. 内存布局描述 (Memory Layout Description)

**TMemLayout**：
- `Size`: 内存大小（字节）
- `Align`: 对齐要求（必须是 2 的幂次）
- 类型安全的内存布局描述

**用途**：
- 分配器接口的参数
- 确保内存对齐正确
- 避免未定义行为

#### 3. 块池和 Arena (Block Pool and Arena)

**IBlockPool**：
- 固定大小块的内存池
- 快速分配和释放
- 适用场景：对象池、节点池

**IArena**：
- 线性分配器（Bump Allocator）
- 支持标记和回滚
- 适用场景：临时内存、作用域分配

**TGrowingArena**：
- 可增长的 Arena
- 自动扩展容量
- Phase 4.7 优化：段缓存 +27.0% 性能

#### 4. 内存操作函数 (Memory Operation Functions)

**Copy 系列**：
- `Copy`: 安全复制（检查重叠）
- `CopyUnChecked`: 无检查复制（性能优先）
- `CopyNonOverlap`: 非重叠复制（假设无重叠）

**Fill/Zero 系列**：
- `Fill8/16/32/64`: 按字节/字/双字/四字填充
- `Zero`: 清零内存

**Compare 系列**：
- `Compare8/16/32`: 按字节/字/双字比较
- `Equal`: 相等性检查

### Usage Patterns 使用模式

#### 1. 使用系统分配器

```pascal
uses
  fafafa.core.mem;

var
  alloc: IAlloc;
  layout: TMemLayout;
  result: TAllocResult;
  ptr: Pointer;
begin
  // 获取系统分配器
  alloc := GetSystemAlloc;

  // 创建内存布局（1024 字节，8 字节对齐）
  layout := TMemLayout.Create(1024, 8);

  // 分配内存
  result := alloc.Alloc(layout);
  if result.IsOk then
  begin
    ptr := result.Ptr;
    WriteLn('Allocated: ', PtrUInt(ptr));

    // 使用内存...

    // 释放内存
    alloc.Dealloc(ptr, layout);
  end
  else
    WriteLn('Allocation failed: ', Ord(result.Error));
end;
```

#### 2. 使用 mimalloc 高性能分配器

```pascal
uses
  fafafa.core.mem;

var
  alloc: IAlloc;
  layout: TMemLayout;
  result: TAllocResult;
  ptr: Pointer;
begin
  // 获取 mimalloc 分配器
  alloc := GetMimalloc;

  // 分配 4KB 内存，16 字节对齐
  layout := TMemLayout.Create(4096, 16);
  result := alloc.Alloc(layout);

  if result.IsOk then
  begin
    ptr := result.Ptr;

    // 填充内存
    Fill32(ptr, 1024, $DEADBEEF);

    // 释放内存
    alloc.Dealloc(ptr, layout);
  end;
end;
```

#### 3. 使用 Arena 进行临时分配

```pascal
uses
  fafafa.core.mem;

var
  arena: TGrowingArena;
  config: TGrowingArenaConfig;
  marker: TArenaMarker;
  ptr1, ptr2: Pointer;
begin
  // 配置 Arena（初始 64KB，最大 1MB）
  config := TGrowingArenaConfig.Create(65536, 1048576);
  arena := TGrowingArena.Create(config);
  try
    // 保存标记
    marker := arena.Mark;

    // 分配临时内存
    ptr1 := arena.Alloc(1024);
    ptr2 := arena.Alloc(2048);

    // 使用内存...

    // 回滚到标记（释放 ptr1 和 ptr2）
    arena.Reset(marker);

    // 继续分配...
  finally
    arena.Free;
  end;
end;
```

#### 4. 使用块池进行对象池

```pascal
uses
  fafafa.core.mem;

type
  TNode = record
    Value: Integer;
    Next: Pointer;
  end;
  PNode = ^TNode;

var
  pool: TBlockPool;
  node1, node2: PNode;
begin
  // 创建块池（块大小 = SizeOf(TNode)）
  pool := TBlockPool.Create(SizeOf(TNode));
  try
    // 分配节点
    node1 := PNode(pool.Alloc);
    node1^.Value := 42;

    node2 := PNode(pool.Alloc);
    node2^.Value := 100;

    // 使用节点...

    // 释放节点（返回池中）
    pool.Dealloc(node1);
    pool.Dealloc(node2);
  finally
    pool.Free;
  end;
end;
```

### Performance Characteristics 性能特点

#### Phase 4.7 优化成果

| 组件 | 优化前 | 优化后 | 提升百分比 | 优化策略 |
|------|--------|--------|-----------|----------|
| `TGrowingBlockPool.FindSegment` | 5.75 Mops/s | **7.30 Mops/s** | **+27.0%** | 段缓存优化 |

**关键优化技术**：
1. **段缓存**：缓存最后访问的段，利用局部性原理
2. **缓存命中率**：70-75%（大部分操作在同一段内）
3. **二分查找兜底**：缓存未命中时使用 O(log n) 查找
4. **零开销抽象**：所有热路径函数内联

#### 性能对比

| 分配器 | 分配速度 | 释放速度 | 内存开销 | 适用场景 |
|--------|---------|---------|---------|---------|
| **TSystemAlloc** | 中等 | 中等 | 低 | 通用场景 |
| **TMimalloc** | **快** | **快** | 中等 | 高性能场景 |
| **TBlockPool** | **极快** | **极快** | 中等 | 固定大小对象 |
| **TGrowingArena** | **极快** | **极快** | 低 | 临时内存 |

### Best Practices 最佳实践

#### 1. 选择正确的分配器

```pascal
// ✅ 通用场景：使用系统分配器
var alloc: IAlloc;
alloc := GetSystemAlloc;

// ✅ 高性能场景：使用 mimalloc
var alloc: IAlloc;
alloc := GetMimalloc;

// ✅ 固定大小对象：使用块池
var pool: TBlockPool;
pool := TBlockPool.Create(SizeOf(TMyObject));

// ✅ 临时内存：使用 Arena
var arena: TGrowingArena;
arena := TGrowingArena.Create(config);

// ❌ 避免：频繁分配小对象使用系统分配器
for i := 1 to 1000000 do
  ptr := GetMem(32);  // 性能差！
```

#### 2. 内存对齐

```pascal
// ✅ 正确：指定对齐要求
var layout: TMemLayout;
layout := TMemLayout.Create(1024, 16);  // 16 字节对齐

// ✅ 正确：使用 AlignUp 对齐指针
var ptr: Pointer;
ptr := AlignUp(rawPtr, 16);

// ❌ 避免：未对齐的内存访问
var ptr: Pointer;
ptr := GetMem(1024);  // 可能未对齐！
PInt64(ptr)^ := 42;   // 可能崩溃！

// ✅ 改进：使用对齐分配器
var alloc: IAlloc;
var layout: TMemLayout;
alloc := GetAlignedAlloc;
layout := TMemLayout.Create(1024, 8);
result := alloc.Alloc(layout);
```

#### 3. 错误处理

```pascal
// ✅ 正确：检查分配结果
var result: TAllocResult;
result := alloc.Alloc(layout);
if result.IsOk then
  ptr := result.Ptr
else
  HandleError(result.Error);

// ❌ 避免：未检查分配结果
var result: TAllocResult;
result := alloc.Alloc(layout);
ptr := result.Ptr;  // 可能为 nil！

// ✅ 正确：使用 TryAlloc 模式
var ptr: Pointer;
if TryAlloc(alloc, layout, ptr) then
  UseMemory(ptr)
else
  HandleError;
```

#### 4. Arena 使用模式

```pascal
// ✅ 正确：使用标记和回滚
var arena: TGrowingArena;
var marker: TArenaMarker;
marker := arena.Mark;
try
  // 分配临时内存
  ptr1 := arena.Alloc(1024);
  ptr2 := arena.Alloc(2048);
  // 使用内存...
finally
  arena.Reset(marker);  // 自动释放
end;

// ❌ 避免：忘记回滚
var arena: TGrowingArena;
ptr := arena.Alloc(1024);
// 忘记 Reset，内存泄漏！

// ✅ 正确：作用域分配
procedure ProcessData(arena: TGrowingArena);
var
  marker: TArenaMarker;
  buffer: Pointer;
begin
  marker := arena.Mark;
  try
    buffer := arena.Alloc(4096);
    // 处理数据...
  finally
    arena.Reset(marker);
  end;
end;
```

#### 5. 内存操作优化

```pascal
// ✅ 正确：使用 CopyNonOverlap 当确定无重叠
CopyNonOverlap(src, dst, size);  // 更快

// ❌ 避免：不必要的重叠检查
Copy(src, dst, size);  // 较慢（检查重叠）

// ✅ 正确：使用 Fill32 填充大块内存
Fill32(ptr, count, value);  // 按 32 位填充

// ❌ 避免：逐字节填充
for i := 0 to count - 1 do
  PByte(ptr)[i] := value;  // 慢！

// ✅ 正确：使用 Zero 清零内存
Zero(ptr, size);  // 优化的清零

// ❌ 避免：手动清零
FillChar(ptr^, size, 0);  // 较慢
```

### Performance Optimization Guide 性能优化指南

#### 1. 分配器选择策略

**场景 1：高频小对象分配**
- **推荐**：TBlockPool
- **原因**：O(1) 分配/释放，无碎片
- **示例**：链表节点、树节点、对象池

**场景 2：临时内存分配**
- **推荐**：TGrowingArena
- **原因**：极快的线性分配，批量释放
- **示例**：解析器、编译器、临时缓冲区

**场景 3：通用内存分配**
- **推荐**：TMimalloc
- **原因**：高性能，低碎片，线程安全
- **示例**：应用程序主分配器

**场景 4：对齐要求严格**
- **推荐**：TAlignedAlloc
- **原因**：保证对齐，避免未定义行为
- **示例**：SIMD 数据、硬件接口

#### 2. 内存池大小调优

```pascal
// ✅ 正确：根据工作负载调整池大小
var config: TGrowingArenaConfig;

// 小型工作负载（< 1MB）
config := TGrowingArenaConfig.Create(16384, 1048576);

// 中型工作负载（1-10MB）
config := TGrowingArenaConfig.Create(65536, 10485760);

// 大型工作负载（> 10MB）
config := TGrowingArenaConfig.Create(262144, 104857600);
```

#### 3. 缓存友好的内存布局

```pascal
// ✅ 正确：按访问频率排列字段
type
  TNode = record
    Value: Integer;      // 热数据
    Next: Pointer;       // 热数据
    Metadata: Integer;   // 冷数据
    Reserved: array[0..15] of Byte;  // 填充到缓存行
  end;

// ❌ 避免：随机排列字段
type
  TNode = record
    Reserved: array[0..15] of Byte;
    Metadata: Integer;
    Value: Integer;
    Next: Pointer;
  end;
```

### Module Structure 模块结构

fafafa.core.mem 是一个门面模块，重新导出以下子模块：

- **fafafa.core.mem.utils**: 内存操作函数（Copy、Fill、Compare）
- **fafafa.core.mem.layout**: 内存布局类型（TMemLayout、TAllocCaps）
- **fafafa.core.mem.error**: 错误处理类型（TAllocError、TAllocResult）
- **fafafa.core.mem.alloc**: 分配器接口（IAlloc、TSystemAlloc、TAlignedAlloc）
- **fafafa.core.mem.blockpool**: 块池和 Arena（IBlockPool、IArena、TBlockPool、TArena）
- **fafafa.core.mem.arena.growable**: 可增长 Arena（TGrowingArena）
- **fafafa.core.mem.mimalloc**: mimalloc 分配器（TMimalloc）

### Related Modules 相关模块

- **fafafa.core.collections**: 集合类型使用内存分配器
- **fafafa.core.simd**: SIMD 操作需要对齐内存
- **fafafa.core.lockfree**: 无锁数据结构使用内存池

### Version History 版本历史

- **v2.0.0** (2025-12-24): Rust 风格接口（IAlloc、TMemLayout、TAllocResult）
- **v1.1.0** (2025-08-10): 接口优先收束（TryAlloc、ReleasePtr）
- **v1.0.0** (2026-01-19): Phase 4.7 段缓存优化完成 (+27.0%)

---
}

{------------------------------------------------------------------------------
  v2.0.0 Release Notes（2025-12-24）
  - Rust 风格接口：IAlloc（类似 GlobalAlloc）、IBlockPool、IArena
  - TMemLayout：内存布局描述（Size + Align）
  - TAllocResult：Result 类型错误处理
  - TAllocCaps：分配器能力自省
  - 零成本抽象：所有热路径 inline

  v1.1.0 Release Notes（2025-08-10）
  - 接口优先收束：TryAlloc 系列、ReleasePtr 别名（避免与 TObject.Free 混淆）
  - 统计助手：Mem/Stack/Slab 只读快照（fafafa.core.mem.stats）
  - 使用提示：size=0 返回 nil；Destroy vs ReleasePtr；Free(nil) 跨池差异
  - 示例与构建：新增 interface 与 microbench 示例，批量脚本纳入
  - 行为：不破坏向后兼容；线程安全不在本版本范围
------------------------------------------------------------------------------}


unit fafafa.core.mem;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.utils,
  // v2.0 Rust 风格接口（统一导出）
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.arena.growable,
  fafafa.core.mem.mimalloc;

const
  FAFAFA_CORE_MEM_VERSION = '2.0.0';

function MemVersion: string; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{-----------------------------------------------------------------------------
  使用提示 Usage Notes

  - 分配策略：
    * size=0：返回 nil（不抛异常）；Stack/Slab/Mem 保持一致
    * TryAlloc：提供不抛异常的尝试分配（返回 False、指针为 nil）

  - 释放策略：
    * 释放块内存请使用 ReleasePtr(APtr)（别名，避免与 TObject.Free 混淆）
    * 销毁实例请使用 Destroy
  - 异常语义（汇总）：
    * MemPool.Free(nil) => no-op（安全空操作）
    * MemPool.DoubleFree => EMemPoolDoubleFree
    * MemPool.Free(非池指针) => EMemPoolInvalidPointer
    * SlabPool.Free: 双重释放 => ESlabPoolCorruption；nil 安全
  - 统计：
    * 可通过 fafafa.core.mem.stats 获取 Mem/Stack/Slab 的只读统计快照
-----------------------------------------------------------------------------}


{
  重新导出核心内存操作函数 Re-export core memory operation functions
}

// 从 fafafa.core.mem.utils 重新导出内存操作函数
// Overlap 检查
function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsOverlap(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsOverlapUnChecked(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsOverlapUnChecked(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Copy 系列
procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure CopyUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure CopyNonOverlap(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure CopyNonOverlapUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Fill/Zero 系列
procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill(aDst: Pointer; aCount: SizeInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill8(aDst: Pointer; aCount: SizeUInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill8(aDst: Pointer; aCount: SizeInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill16(aDst: Pointer; aCount: SizeUInt; aValue: UInt16); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill16(aDst: Pointer; aCount: SizeInt; aValue: UInt16); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill32(aDst: Pointer; aCount: SizeUInt; aValue: UInt32); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill32(aDst: Pointer; aCount: SizeInt; aValue: UInt32); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill64(aDst: Pointer; aCount: SizeUInt; const aValue: UInt64); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill64(aDst: Pointer; aCount: SizeInt; const aValue: UInt64); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Zero(aDst: Pointer; aSize: SizeUInt); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Zero(aDst: Pointer; aSize: SizeInt); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Compare/Equal 系列
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// 对齐
function IsAligned(aPtr: Pointer; aAlignment: SizeUInt = SizeOf(Pointer)): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function AlignUp(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function AlignUpUnChecked(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  function AlignDown(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  function AlignDownUnChecked(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{-----------------------------------------------------------------------------
  v2.0 Rust 风格接口 Rust-style Interface

  内存管理 API：
  - 零成本抽象
  - 基于 Layout 的内存布局描述
  - Result 类型错误处理
  - 类型安全的能力查询

  注意：v1 接口（IAllocator）已废弃，如需使用请直接 uses fafafa.core.mem.allocator
-----------------------------------------------------------------------------}

type
  // 内存布局和能力类型 Memory Layout and Capability Types
  TMemLayout = fafafa.core.mem.layout.TMemLayout;
  TAllocCaps = fafafa.core.mem.layout.TAllocCaps;

  // 错误处理类型 Error Handling Types
  TAllocError = fafafa.core.mem.error.TAllocError;
  TAllocResult = fafafa.core.mem.error.TAllocResult;

  // Rust 风格分配器接口 Rust-style Allocator Interfaces
  IAlloc = fafafa.core.mem.alloc.IAlloc;
  TAllocBase = fafafa.core.mem.alloc.TAllocBase;
  TSystemAlloc = fafafa.core.mem.alloc.TSystemAlloc;
  TAlignedAlloc = fafafa.core.mem.alloc.TAlignedAlloc;

  // 块池和 Arena 接口 Block Pool and Arena Interfaces
  IBlockPool = fafafa.core.mem.blockpool.IBlockPool;
  IArena = fafafa.core.mem.blockpool.IArena;
  TArenaMarker = fafafa.core.mem.blockpool.TArenaMarker;
  TBlockPool = fafafa.core.mem.blockpool.TBlockPool;
  TArena = fafafa.core.mem.blockpool.TArena;
  TGrowingArenaConfig = fafafa.core.mem.arena.growable.TGrowingArenaConfig;
  TGrowingArena = fafafa.core.mem.arena.growable.TGrowingArena;

// 分配器获取函数 Allocator Accessor Functions
function GetSystemAlloc: IAlloc; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function GetAlignedAlloc: IAlloc; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function GetMimalloc: IAlloc; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// 重新导出增强版栈池类型
// 为保持门面职责收敛，不再重导出增强型/对象池/环形缓冲区/内存映射/映射池类型。
// 用户可按需直接 uses 各自单元：
//   - fafafa.core.mem.enhancedStackPool / enhancedObjectPool / enhancedRingBuffer
//   - fafafa.core.mem.objectPool / ringBuffer
//   - fafafa.core.fs.mmap（建议替代 memoryMap 系列）
//   - fafafa.core.mem.mappedRingBuffer / mappedSlabPool（建议迁移至 fs 子域）


  {--------------------------------------------------------------------------
    注意：内存映射/共享内存等功能不再由 fafafa.core.mem 门面导出；
    请直接使用 fs 子域（例如 fafafa.core.fs.mmap）或各自单元。
  --------------------------------------------------------------------------}

implementation

{ 重新导出函数的实现 Re-export function implementations }

function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlap(aPtr1, aSize1, aPtr2, aSize2);
end;

function IsOverlap(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlap(aPtr1, aPtr2, aSize);
end;
function IsOverlapUnChecked(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlapUnChecked(aPtr1, aSize1, aPtr2, aSize2);
end;

function IsOverlapUnChecked(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlapUnChecked(aPtr1, aPtr2, aSize);
end;

procedure CopyUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.CopyUnChecked(aSrc, aDst, aSize);
end;

procedure CopyNonOverlap(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.CopyNonOverlap(aSrc, aDst, aSize);
end;

procedure CopyNonOverlapUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.CopyNonOverlapUnChecked(aSrc, aDst, aSize);
end;

procedure Fill(aDst: Pointer; aCount: SizeInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill(aDst, aCount, aValue);
end;

procedure Fill8(aDst: Pointer; aCount: SizeUInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill8(aDst, aCount, aValue);
end;

procedure Fill8(aDst: Pointer; aCount: SizeInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill8(aDst, aCount, aValue);
end;

procedure Fill16(aDst: Pointer; aCount: SizeUInt; aValue: UInt16);
begin
  fafafa.core.mem.utils.Fill16(aDst, aCount, aValue);
end;

procedure Fill16(aDst: Pointer; aCount: SizeInt; aValue: UInt16);
begin
  fafafa.core.mem.utils.Fill16(aDst, aCount, aValue);
end;

procedure Fill32(aDst: Pointer; aCount: SizeUInt; aValue: UInt32);
begin
  fafafa.core.mem.utils.Fill32(aDst, aCount, aValue);
end;

procedure Fill32(aDst: Pointer; aCount: SizeInt; aValue: UInt32);
begin
  fafafa.core.mem.utils.Fill32(aDst, aCount, aValue);
end;

procedure Fill64(aDst: Pointer; aCount: SizeUInt; const aValue: UInt64);
begin
  fafafa.core.mem.utils.Fill64(aDst, aCount, aValue);
end;

procedure Fill64(aDst: Pointer; aCount: SizeInt; const aValue: UInt64);
begin
  fafafa.core.mem.utils.Fill64(aDst, aCount, aValue);
end;

procedure Zero(aDst: Pointer; aSize: SizeInt);
begin
  fafafa.core.mem.utils.Zero(aDst, aSize);
end;

function Compare(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare(aPtr1, aPtr2, aCount);
end;

function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare8(aPtr1, aPtr2, aCount);
end;

function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare8(aPtr1, aPtr2, aCount);
end;

function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare16(aPtr1, aPtr2, aCount);
end;

function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare16(aPtr1, aPtr2, aCount);
end;

function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare32(aPtr1, aPtr2, aCount);
end;

function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare32(aPtr1, aPtr2, aCount);
end;

function Equal(aPtr1, aPtr2: Pointer; aSize: SizeInt): Boolean;
begin
  Result := fafafa.core.mem.utils.Equal(aPtr1, aPtr2, aSize);
end;

function AlignUpUnChecked(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignUpUnChecked(aPtr, aAlignment);
end;

function AlignDown(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignDown(aPtr, aAlignment);
end;

function AlignDownUnChecked(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignDownUnChecked(aPtr, aAlignment);
end;


procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.Copy(aSrc, aDst, aSize);
end;

procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill(aDst, aCount, aValue);
end;

procedure Zero(aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.Zero(aDst, aSize);
end;

function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare(aPtr1, aPtr2, aCount);
end;

function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.Equal(aPtr1, aPtr2, aSize);
end;

function IsAligned(aPtr: Pointer; aAlignment: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsAligned(aPtr, aAlignment);
end;

function AlignUp(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignUp(aPtr, aAlignment);
end;

function MemVersion: string;
begin
  Result := FAFAFA_CORE_MEM_VERSION;
end;

{ v2.0 分配器获取函数 v2.0 Allocator Accessor Functions }

function GetSystemAlloc: IAlloc;
begin
  Result := fafafa.core.mem.alloc.GetSystemAlloc;
end;

function GetAlignedAlloc: IAlloc;
begin
  Result := fafafa.core.mem.alloc.GetAlignedAlloc;
end;

function GetMimalloc: IAlloc;
begin
  Result := fafafa.core.mem.mimalloc.GetMimalloc;
end;

end.

{
  注意: 高级功能模块已创建但未集成到主门面模块中

  可用的高级模块:
  - fafafa.core.mem.advanced - 高级内存池和线程安全池
  - fafafa.core.mem.config - 配置管理
  - fafafa.core.mem.factory - 内存池工厂

  要使用高级功能，请直接引用相应的模块:
  uses fafafa.core.mem.factory;

  LPool := CreateSmallObjectPool('MyPool');
}
