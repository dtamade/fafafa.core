# VecDeque 架构设计文档

## 目录

- [总体架构](#总体架构)
- [核心组件](#核心组件)
- [内存管理](#内存管理)
- [算法实现](#算法实现)
- [类型系统](#类型系统)
- [性能优化](#性能优化)
- [扩展机制](#扩展机制)
- [设计决策](#设计决策)

## 总体架构

### 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                    VecDeque 架构层次                        │
├─────────────────────────────────────────────────────────────┤
│  应用层    │ 用户代码 │ 特化类型 │ 并行操作 │ 高级功能      │
├─────────────────────────────────────────────────────────────┤
│  API层     │ 公共接口 │ 类型安全 │ 错误处理 │ 参数验证      │
├─────────────────────────────────────────────────────────────┤
│  核心层    │ 环形缓冲 │ 内存管理 │ 算法实现 │ 索引计算      │
├─────────────────────────────────────────────────────────────┤
│  基础层    │ 内存分配 │ 类型操作 │ 系统调用 │ 平台抽象      │
└─────────────────────────────────────────────────────────────┘
```

### 模块依赖关系

```
fafafa.core.collections.vecdeque.specialized
    ↓ 依赖
fafafa.core.collections.vecdeque
    ↓ 依赖
fafafa.core.collections.base
    ↓ 依赖
fafafa.core.mem.allocator
    ↓ 依赖
fafafa.core.base
```

## 核心组件

### 1. TVecDeque<T> 核心类

```pascal
type
  generic TVecDeque<T> = class
  private
    FBuffer: TBuffer;           // 环形缓冲区
    FHead: SizeUInt;           // 头部索引
    FTail: SizeUInt;           // 尾部索引
    FCount: SizeUInt;          // 元素数量
    
    // 核心方法
    function GetPhysicalIndex(aLogicalIndex: SizeUInt): SizeUInt;
    procedure DoGrow(aNewCapacity: SizeUInt);
    procedure DoShrink(aNewCapacity: SizeUInt);
    
  public
    // 公共接口
  end;
```

**设计要点**:
- 使用环形缓冲区实现双端队列
- 分离逻辑索引和物理索引
- 延迟内存分配和释放

### 2. TBuffer 内存管理器

```pascal
type
  TBuffer = class
  private
    FData: Pointer;            // 原始内存指针
    FCapacity: SizeUInt;       // 容量（元素数量）
    FElementSize: SizeUInt;    // 单个元素大小
    
  public
    procedure Put(aIndex: SizeUInt; const aValue: T);
    function Get(aIndex: SizeUInt): T;
    function GetPtr(aIndex: SizeUInt): Pointer;
    procedure Resize(aNewCapacity: SizeUInt);
  end;
```

**设计要点**:
- 封装原始内存操作
- 提供类型安全的访问接口
- 支持动态调整大小

### 3. 特化类型层次

```
TVecDeque<T>
    ├── TIntegerVecDeque
    │   ├── Sum, Min, Max, Average
    │   └── 默认比较器
    ├── TStringVecDeque
    │   ├── Join, SortIgnoreCase
    │   └── 字符串比较器
    └── 其他特化类型...
```

## 内存管理

### 1. 环形缓冲区实现

```
物理内存布局:
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  0  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

情况1: 连续存储 (Head <= Tail)
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│     │     │ H→A │ B   │ C   │ D←T │     │     │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
逻辑顺序: A, B, C, D

情况2: 分割存储 (Head > Tail)
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ C   │ D←T │     │     │     │     │ H→A │ B   │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
逻辑顺序: A, B, C, D
```

### 2. 索引计算

```pascal
function TVecDeque.GetPhysicalIndex(aLogicalIndex: SizeUInt): SizeUInt;
begin
  // 环形缓冲区索引计算
  Result := (FHead + aLogicalIndex) mod FBuffer.GetCapacity;
end;

function TVecDeque.GetLogicalIndex(aPhysicalIndex: SizeUInt): SizeUInt;
begin
  // 反向计算逻辑索引
  if aPhysicalIndex >= FHead then
    Result := aPhysicalIndex - FHead
  else
    Result := FBuffer.GetCapacity - FHead + aPhysicalIndex;
end;
```

### 3. 内存增长策略

```pascal
procedure TVecDeque.DoGrow(aNewCapacity: SizeUInt);
var
  LNewBuffer: TBuffer;
  i: SizeUInt;
begin
  // 创建新缓冲区
  LNewBuffer := TBuffer.Create(aNewCapacity);
  
  // 复制现有元素到新缓冲区（线性排列）
  for i := 0 to FCount - 1 do
    LNewBuffer.Put(i, FBuffer.GetUnChecked(GetPhysicalIndex(i)));
  
  // 替换缓冲区
  FBuffer.Free;
  FBuffer := LNewBuffer;
  
  // 重置索引
  FHead := 0;
  FTail := FCount;
end;
```

**增长策略**:
- 容量不足时，按 2 倍增长
- 最小容量为 4 个元素
- 增长时重新排列为线性布局

## 算法实现

### 1. 排序算法架构

```
排序算法层次:
┌─────────────────────────────────────────┐
│           排序算法选择器                 │
├─────────────────────────────────────────┤
│ QuickSort │ MergeSort │ HeapSort │ ... │
├─────────────────────────────────────────┤
│           统一比较接口                   │
├─────────────────────────────────────────┤
│           元素交换操作                   │
└─────────────────────────────────────────┘
```

### 2. 比较器系统

```pascal
type
  TCompareFunc = function(const aLeft, aRight: T; aData: Pointer): Integer;
  TCompareRefFunc = function(const aLeft, aRight: T): Integer;

// 统一比较接口
function TVecDeque.DoCompare(const aLeft, aRight: T; 
                            aComparer: TCompareFunc; 
                            aData: Pointer): Integer;
begin
  if Assigned(aComparer) then
    Result := aComparer(aLeft, aRight, aData)
  else
    raise EInvalidOperation.Create('No comparer provided');
end;
```

### 3. Rust 风格操作实现

```pascal
// AsSlices: 零拷贝内存访问
procedure TVecDeque.AsSlices(out aFirst: Pointer; out aFirstLen: SizeUInt; 
                            out aSecond: Pointer; out aSecondLen: SizeUInt);
begin
  if FHead <= FTail then
  begin
    // 连续存储
    aFirst := FBuffer.GetPtr(FHead);
    aFirstLen := FCount;
    aSecond := nil;
    aSecondLen := 0;
  end
  else
  begin
    // 分割存储
    aFirst := FBuffer.GetPtr(FHead);
    aFirstLen := FBuffer.GetCapacity - FHead;
    aSecond := FBuffer.GetPtr(0);
    aSecondLen := FTail;
  end;
end;
```

## 类型系统

### 1. 泛型类型设计

```pascal
// 基础泛型类型
generic TVecDeque<T> = class
  // 核心功能，不假设 T 的特性
end;

// 约束泛型（概念性，FreePascal 不直接支持）
generic TComparableVecDeque<T: IComparable> = class(TVecDeque<T>)
  // 可以使用 T 的比较功能
end;
```

### 2. 特化类型实现

```pascal
// Integer 特化
TIntegerVecDeque = class(specialize TVecDeque<Integer>)
private
  class function DefaultCompare(const A, B: Integer; Data: Pointer): Integer; static;
public
  procedure Sort; override;  // 使用默认比较器
  function Sum: Int64;       // 数值特有功能
end;

// String 特化
TStringVecDeque = class(specialize TVecDeque<String>)
private
  class function DefaultCompare(const A, B: String; Data: Pointer): Integer; static;
public
  procedure Sort; override;  // 使用默认比较器
  function Join(const Sep: String): String;  // 字符串特有功能
end;
```

### 3. 类型安全机制

```pascal
// 编译时类型检查
procedure TypeSafetyExample;
var
  LIntDeque: TIntegerVecDeque;
  LStrDeque: TStringVecDeque;
begin
  LIntDeque := TIntegerVecDeque.Create;
  LStrDeque := TStringVecDeque.Create;
  
  // 编译时错误：类型不匹配
  // LIntDeque.PushBack('string');  // 编译错误
  // LStrDeque.PushBack(42);        // 编译错误
  
  // 正确的类型使用
  LIntDeque.PushBack(42);
  LStrDeque.PushBack('hello');
end;
```

## 性能优化

### 1. 内存访问优化

```pascal
// 缓存友好的遍历
procedure OptimizedTraversal(ADeque: TVecDeque);
var
  LFirst, LSecond: Pointer;
  LFirstLen, LSecondLen: SizeUInt;
begin
  // 获取连续内存片段
  ADeque.AsSlices(LFirst, LFirstLen, LSecond, LSecondLen);
  
  // 顺序访问第一片段（缓存友好）
  ProcessMemoryBlock(LFirst, LFirstLen);
  
  // 顺序访问第二片段（如果存在）
  if LSecondLen > 0 then
    ProcessMemoryBlock(LSecond, LSecondLen);
end;
```

### 2. 分支预测优化

```pascal
// 优化分支预测
function TVecDeque.Get(aIndex: SizeUInt): T;
begin
  // 常见情况：索引有效
  if aIndex < FCount then  // 大概率为真
    Result := FBuffer.GetUnChecked(GetPhysicalIndex(aIndex))
  else
    raise EOutOfRange.CreateFmt('Index %d >= Count %d', [aIndex, FCount]);
end;
```

### 3. 内联优化

```pascal
// 关键路径内联
function TVecDeque.GetPhysicalIndex(aLogicalIndex: SizeUInt): SizeUInt; 
{$IFDEF FAFAFA_CORE_INLINE} inline; {$ENDIF}
begin
  Result := (FHead + aLogicalIndex) mod FBuffer.GetCapacity;
end;
```

## 扩展机制

### 1. 插件式算法

```pascal
type
  TSortAlgorithm = (saQuickSort, saMergeSort, saHeapSort, saIntroSort, saInsertionSort);
  
  TSortAlgorithmRegistry = class
  private
    class var FAlgorithms: array[TSortAlgorithm] of TSortProcedure;
  public
    class procedure RegisterAlgorithm(AType: TSortAlgorithm; AProc: TSortProcedure);
    class function GetAlgorithm(AType: TSortAlgorithm): TSortProcedure;
  end;
```

### 2. 自定义内存分配器

```pascal
type
  IMemoryAllocator = interface
    function Allocate(ASize: SizeUInt): Pointer;
    procedure Deallocate(APtr: Pointer);
    function Reallocate(APtr: Pointer; ANewSize: SizeUInt): Pointer;
  end;

  TVecDeque = class
  private
    FAllocator: IMemoryAllocator;
  public
    constructor Create(AAllocator: IMemoryAllocator = nil);
  end;
```

### 3. 事件和回调

```pascal
type
  TCapacityChangeEvent = procedure(AOldCapacity, ANewCapacity: SizeUInt) of object;
  
  TVecDeque = class
  private
    FOnCapacityChange: TCapacityChangeEvent;
  protected
    procedure DoCapacityChange(AOldCapacity, ANewCapacity: SizeUInt); virtual;
  public
    property OnCapacityChange: TCapacityChangeEvent read FOnCapacityChange write FOnCapacityChange;
  end;
```

## 设计决策

### 1. 环形缓冲区 vs 动态数组

**选择**: 环形缓冲区

**理由**:
- O(1) 双端操作
- 更好的内存利用率
- 减少元素移动

**权衡**:
- 索引计算稍复杂
- 内存不连续时访问性能略低

### 2. 泛型 vs 特化类型

**选择**: 混合方案

**理由**:
- 泛型提供通用性
- 特化类型提供便利性和性能
- 满足不同使用场景

### 3. 异常 vs 错误码

**选择**: 异常机制

**理由**:
- 符合 Pascal 传统
- 强制错误处理
- 代码更清晰

### 4. 内存增长策略

**选择**: 2倍增长

**理由**:
- 摊销 O(1) 性能
- 平衡内存使用和性能
- 简单易实现

### 5. 线程安全

**选择**: 非线程安全 + 外部同步

**理由**:
- 避免不必要的同步开销
- 用户可根据需要选择同步策略
- 保持 API 简洁

## 未来扩展

### 1. 可能的改进

- **SIMD 优化**: 利用向量指令加速批量操作
- **内存池**: 减少内存分配开销
- **压缩存储**: 对于特定类型的空间优化
- **持久化**: 支持序列化和反序列化

### 2. API 演进

- **迭代器支持**: 提供更丰富的遍历方式
- **函数式操作**: map, filter, reduce 等
- **异步操作**: 支持异步 I/O 场景
- **更多特化类型**: 支持更多常用类型

这个架构设计确保了 VecDeque 的高性能、类型安全和可扩展性，为 FreePascal 生态系统提供了现代化的数据结构实现。
