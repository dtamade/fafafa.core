# fafafa.core.mem 架构文档

## 📋 架构概述

`fafafa.core.mem` 采用了标准的门面模式架构，符合 fafafa 框架的统一设计理念。

### 🏗️ 模块结构

```
fafafa.core.mem/
├── fafafa.core.mem.pas           # 主门面模块 (140行)
├── fafafa.core.mem.memPool.pas   # 通用内存池 (200行)
├── fafafa.core.mem.stackPool.pas # 栈式内存池 (180行)
└── fafafa.core.mem.slabPool.pas  # Slab分配器 (425行)
```

## 🎯 设计原则

1. **职责分离** - 每个模块功能单一，易于维护
2. **可选使用** - 用户可以只使用需要的功能模块
3. **扩展性好** - 可以轻松添加新的池类型
4. **中规中矩** - 遵循传统的设计模式，避免过度复杂

## 📝 模块详细说明

### fafafa.core.mem (主门面)

**职责**: 重新导出基础内存操作和分配器功能

**功能**:
- 重新导出 `fafafa.core.mem.utils` 的内存操作函数
- 重新导出 `fafafa.core.mem.allocator` 的分配器接口和类
- 提供统一的访问入口

**API**:
```pascal
// 内存操作函数
function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean;
procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt);
procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8);
procedure Zero(aDst: Pointer; aSize: SizeUInt);
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
function IsAligned(aPtr: Pointer; aAlignment: SizeUInt = SizeOf(Pointer)): Boolean;
function AlignUp(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer;

// 分配器类型
type
  IAllocator = fafafa.core.mem.allocator.IAllocator;
  TAllocator = fafafa.core.mem.allocator.TAllocator;
  // ...

// 注意：所有 Pool 类都统一使用 TAllocator 而不是 IAllocator

// 分配器获取函数
function GetRtlAllocator: TAllocator;
function GetCrtAllocator: TAllocator; // 条件编译
```

### fafafa.core.mem.memPool (通用内存池)

**职责**: 提供固定大小块的通用内存池

**特点**:
- 预分配固定数量的固定大小内存块
- 快速分配和释放
- 支持容量管理和统计

**API**:
```pascal
type
  TMemPool = class
    constructor Create(aBlockSize: SizeUInt; aCapacity: Integer; aAllocator: TAllocator = nil);
    destructor Destroy; override;
    
    function Alloc: Pointer;
    procedure Free(aPtr: Pointer);
    procedure Reset;
    
    property BlockSize: SizeUInt read FBlockSize;
    property Capacity: Integer read FCapacity;
    property AllocatedCount: Integer read FAllocatedCount;
    property AvailableCount: Integer read GetAvailableCount;
    
    function IsEmpty: Boolean;
    function IsFull: Boolean;
  end;
```

**使用场景**:
- 频繁分配/释放固定大小对象
- 需要控制内存使用量的场景
- 避免内存碎片的场景

### fafafa.core.mem.stackPool (栈式内存池)

**职责**: 提供快速顺序分配的栈式内存池

**特点**:
- 顺序分配，快速释放
- 支持状态保存和恢复
- 支持对齐要求

**API**:
```pascal
type
  TStackPool = class
    constructor Create(aSize: SizeUInt; aAllocator: TAllocator = nil);
    destructor Destroy; override;
    
    function Alloc(aSize: SizeUInt; aAlignment: SizeUInt = SizeOf(Pointer)): Pointer;
    procedure Reset;
    
    function SaveState: SizeUInt;
    procedure RestoreState(aState: SizeUInt);
    
    property TotalSize: SizeUInt read FSize;
    property UsedSize: SizeUInt read FOffset;
    property AvailableSize: SizeUInt read GetAvailableSize;
    
    function IsEmpty: Boolean;
    function IsFull: Boolean;
  end;
```

**使用场景**:
- 临时对象分配
- 需要批量释放的场景
- 解析器、编译器等需要大量临时内存的场景

### fafafa.core.mem.slabPool (nginx风格Slab分配器)

**职责**: 提供 nginx 风格的页面管理 Slab 分配器

**特点**:
- 参考 nginx 的 slab 分配器设计
- 基于页面的内存管理 (4KB 页面)
- 预定义的大小类别 (8, 16, 32, 64, 128, 256, 512, 1024, 2048)
- 位图管理空闲块
- 高效的 O(1) 分配和释放

**API**:
```pascal
type
  TSlabPool = class
    constructor Create(aSize: SizeUInt; aAllocator: TAllocator = nil);
    destructor Destroy; override;

    function Alloc(aSize: SizeUInt): Pointer;
    procedure Free(aPtr: Pointer);
    procedure Reset;

    property PoolSize: SizeUInt read FSize;
    property PageCount: SizeUInt read FPageCount;
    property TotalAllocs: SizeUInt read FTotalAllocs;
    property TotalFrees: SizeUInt read FTotalFrees;
    property FailedAllocs: SizeUInt read FFailedAllocs;
  end;
```

**使用场景**:
- 需要分配不同大小对象的场景
- 高性能服务器程序
- 减少内存碎片的场景
- 需要详细统计信息的场景

## 🔧 使用示例

### 基本使用

```pascal
uses
  fafafa.core.mem;

var
  LAllocator: IAllocator;
  LPtr: Pointer;
begin
  // 使用重新导出的分配器
  LAllocator := GetRtlAllocator;
  LPtr := LAllocator.GetMem(100);
  
  // 使用重新导出的内存操作
  Fill(LPtr, 100, 0);
  
  LAllocator.FreeMem(LPtr);
end;
```

### 内存池使用

```pascal
uses
  fafafa.core.mem.memPool;

var
  LPool: TMemPool;
  LPtr: Pointer;
begin
  LPool := TMemPool.Create(64, 100); // 64字节块，100个容量
  try
    LPtr := LPool.Alloc;
    // 使用内存...
    LPool.Free(LPtr);
  finally
    LPool.Free;
  end;
end;
```

### 栈池使用

```pascal
uses
  fafafa.core.mem.stackPool;

var
  LPool: TStackPool;
  LPtr1, LPtr2: Pointer;
  LState: SizeUInt;
begin
  LPool := TStackPool.Create(4096); // 4KB栈
  try
    LPtr1 := LPool.Alloc(100);
    LState := LPool.SaveState;
    
    LPtr2 := LPool.Alloc(200);
    // 使用内存...
    
    LPool.RestoreState(LState); // 批量释放
  finally
    LPool.Free;
  end;
end;
```

### nginx风格Slab池使用

```pascal
uses
  fafafa.core.mem.slabPool;

var
  LPool: TSlabPool;
  LPtr1, LPtr2: Pointer;
begin
  LPool := TSlabPool.Create(8192); // 2个页面的池
  try
    LPtr1 := LPool.Alloc(64);   // 分配64字节
    LPtr2 := LPool.Alloc(128);  // 分配128字节

    // 使用内存...

    LPool.Free(LPtr1);
    LPool.Free(LPtr2);

    // 查看统计信息
    WriteLn('总分配: ', LPool.TotalAllocs);
    WriteLn('总释放: ', LPool.TotalFrees);
    WriteLn('失败数: ', LPool.FailedAllocs);
  finally
    LPool.Free;
  end;
end;
```

## 🎯 架构优势

1. **清晰的职责分离** - 每个模块都有明确的职责
2. **易于扩展** - 可以轻松添加新的池类型
3. **可选使用** - 用户只需要引用需要的模块
4. **性能优化** - 每种池都针对特定场景优化
5. **内存安全** - 完整的错误处理和资源管理

## 📊 性能特点

- **TMemPool**: 固定时间分配/释放 O(1)
- **TStackPool**: 极快的顺序分配 O(1)，批量释放 O(1)
- **TSlabPool**: nginx风格页面管理，O(1)分配/释放，减少碎片，支持多种大小类别

## 🔮 扩展方向

未来可以考虑添加的模块：
- `fafafa.core.mem.ringPool` - 环形缓冲区池
- `fafafa.core.mem.objectPool` - 泛型对象池
- `fafafa.core.mem.threadPool` - 线程安全内存池
- `fafafa.core.mem.monitor` - 内存使用监控

这个架构为 fafafa 框架提供了强大而灵活的内存管理基础。
