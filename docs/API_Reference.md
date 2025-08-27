# VecDeque API 参考手册

> See also: Collections
> - Collections API 索引：docs/API_collections.md
> - TVec 模块文档：docs/fafafa.core.collections.vec.md
> - 集合系统概览：docs/fafafa.core.collections.md


## 目录

- [核心类型](#核心类型)
- [构造和析构](#构造和析构)
- [基础操作](#基础操作)
- [访问操作](#访问操作)
- [容量管理](#容量管理)
- [排序和搜索](#排序和搜索)
- [Rust 风格操作](#rust-风格操作)
- [特化类型](#特化类型)
- [并行操作](#并行操作)
- [错误处理](#错误处理)

## 核心类型

### TVecDeque<T>

泛型双端队列，支持任意类型 T。

```pascal
type
  generic TVecDeque<T> = class
  // ... 方法声明
  end;
```

### 特化类型

```pascal
type
  TIntegerVecDeque = class(specialize TVecDeque<Integer>);
  TStringVecDeque = class(specialize TVecDeque<String>);
```

## 构造和析构

### Create

```pascal
constructor Create;
constructor Create(aInitialCapacity: SizeUInt);
```

**描述**: 创建新的 VecDeque 实例

**参数**:
- `aInitialCapacity`: 初始容量（可选）

**示例**:
```pascal
var
  LDeque1, LDeque2: TIntegerVecDeque;
begin
  LDeque1 := TIntegerVecDeque.Create;        // 默认容量
  LDeque2 := TIntegerVecDeque.Create(100);   // 指定容量
end;
```

### Destroy

```pascal
destructor Destroy; override;
```

**描述**: 销毁 VecDeque 实例，释放所有资源

## 基础操作

### PushBack

```pascal
procedure PushBack(const aValue: T);
```

**描述**: 在队列尾部添加元素
**时间复杂度**: O(1) 摊销
**异常**: 内存不足时可能抛出 EOutOfMemory

**示例**:
```pascal
LDeque.PushBack(42);
LDeque.PushBack(100);
```

### PushFront

```pascal
procedure PushFront(const aValue: T);
```

**描述**: 在队列头部添加元素
**时间复杂度**: O(1) 摊销

**示例**:
```pascal
LDeque.PushFront(1);
LDeque.PushFront(0);
```

### PopBack

```pascal
function PopBack: T;
```

**描述**: 移除并返回队列尾部元素
**时间复杂度**: O(1)
**异常**: 空队列时抛出 EInvalidOperation

**示例**:
```pascal
var
  LValue: Integer;
begin
  LValue := LDeque.PopBack;
end;
```

### PopFront

```pascal
function PopFront: T;
```

**描述**: 移除并返回队列头部元素
**时间复杂度**: O(1)
**异常**: 空队列时抛出 EInvalidOperation

## 访问操作

### Get

```pascal
function Get(aIndex: SizeUInt): T;
```

**描述**: 获取指定索引的元素
**时间复杂度**: O(1)
**异常**: 索引越界时抛出 EOutOfRange

**示例**:
```pascal
var
  LValue: Integer;
begin
  LValue := LDeque.Get(0);  // 获取第一个元素
end;
```

### Put

```pascal
procedure Put(aIndex: SizeUInt; const aValue: T);
```

**描述**: 设置指定索引的元素
**时间复杂度**: O(1)
**异常**: 索引越界时抛出 EOutOfRange

### Front

```pascal
function Front: T;
```

**描述**: 获取队列头部元素（不移除）
**时间复杂度**: O(1)
**异常**: 空队列时抛出 EInvalidOperation

### Back

```pascal
function Back: T;
```

**描述**: 获取队列尾部元素（不移除）
**时间复杂度**: O(1)
**异常**: 空队列时抛出 EInvalidOperation

## 容量管理

### GetCount

```pascal
function GetCount: SizeUInt;
```

**描述**: 获取元素数量
**时间复杂度**: O(1)

### GetCapacity

```pascal
function GetCapacity: SizeUInt;
```

**描述**: 获取当前容量
**时间复杂度**: O(1)

### IsEmpty

```pascal
function IsEmpty: Boolean;
```

**描述**: 检查队列是否为空
**时间复杂度**: O(1)

### Reserve

```pascal
procedure Reserve(aCapacity: SizeUInt);
```

**描述**: 预留至少指定容量的空间
**时间复杂度**: O(n) 如果需要重新分配
**异常**: 内存不足时抛出 EOutOfMemory

### TryReserve

```pascal
function TryReserve(aAdditionalCapacity: SizeUInt): Boolean;
```

**描述**: 尝试预留额外容量，不抛出异常
**返回值**: 成功返回 True，失败返回 False
**时间复杂度**: O(n) 如果需要重新分配

### ShrinkTo

```pascal
procedure ShrinkTo(aMinCapacity: SizeUInt);
```

**描述**: 收缩容量到指定最小值
**时间复杂度**: O(n) 如果需要重新分配

### Clear

```pascal
procedure Clear;
```

**描述**: 清空所有元素
**时间复杂度**: O(n)

## 排序和搜索

### Sort

```pascal
procedure Sort;
procedure Sort(aComparer: TCompareFunc; aData: Pointer);
procedure Sort(aComparer: TCompareRefFunc);
```

**描述**: 对元素进行排序
**时间复杂度**: O(n log n)
**注意**: 泛型版本需要提供比较器，特化版本有默认比较器

**示例**:
```pascal
// 特化类型的默认排序
LIntDeque.Sort;

// 泛型类型需要比较器
LDeque.Sort(@MyCompareFunc, nil);
```

### SortWith

```pascal
procedure SortWith(aAlgorithm: TSortAlgorithm);
```

**描述**: 使用指定算法排序
**参数**:
- `saQuickSort`: 快速排序
- `saMergeSort`: 归并排序
- `saHeapSort`: 堆排序
- `saIntroSort`: 内省排序
- `saInsertionSort`: 插入排序

### IndexOf

```pascal
function IndexOf(const aValue: T): SizeInt;
```

**描述**: 查找元素首次出现的位置
**时间复杂度**: O(n)
**返回值**: 找到返回索引，未找到返回 -1

### Contains

```pascal
function Contains(const aValue: T): Boolean;
```

**描述**: 检查是否包含指定元素
**时间复杂度**: O(n)

## Rust 风格操作

### AsSlices

```pascal
procedure AsSlices(out aFirst: Pointer; out aFirstLen: SizeUInt;
                   out aSecond: Pointer; out aSecondLen: SizeUInt);
```

**描述**: 获取连续内存片段，用于零拷贝访问
**用途**: 高性能操作，避免数据拷贝

**示例**:
```pascal
var
  LFirst, LSecond: Pointer;
  LFirstLen, LSecondLen: SizeUInt;
begin
  LDeque.AsSlices(LFirst, LFirstLen, LSecond, LSecondLen);
  // 直接操作内存片段
end;
```

### MakeContiguous

```pascal
function MakeContiguous: Pointer;
```

**描述**: 重新排列内存使数据连续
**返回值**: 指向连续数据的指针
**时间复杂度**: O(n) 如果需要重排

### IsContiguous

```pascal
function IsContiguous: Boolean;
```

**描述**: 检查数据是否连续存储
**时间复杂度**: O(1)

### Drain

```pascal
procedure Drain(aStartIndex, aCount: SizeUInt; out aDrainedElements: array of T);
```

**描述**: 移除指定范围的元素并返回
**时间复杂度**: O(n)

### SplitOff

```pascal
function SplitOff(aIndex: SizeUInt): TVecDeque;
```

**描述**: 在指定位置分割队列，返回后半部分
**时间复杂度**: O(n)
**注意**: 调用者负责释放返回的对象

### RotateLeft / RotateRight

```pascal
procedure RotateLeft(aSteps: SizeUInt);
procedure RotateRight(aSteps: SizeUInt);
```

**描述**: 向左/右旋转元素
**时间复杂度**: O(n)

## 特化类型

### TIntegerVecDeque 特有方法

```pascal
function Sum: Int64;
function Min: Integer;
function Max: Integer;
function Average: Double;
```

### TStringVecDeque 特有方法

```pascal
function Join(const aSeparator: String): String;
procedure SortIgnoreCase;
```

## 并行操作

### ParallelSort

```pascal
procedure ParallelSort;
procedure ParallelSort(aAlgorithm: TSortAlgorithm);
```

**描述**: 并行排序，在多核系统上提供性能提升
**注意**: 小数据集自动退化为串行排序

### ParallelFind

```pascal
function ParallelFind(const aValue: T): SizeInt;
```

**描述**: 并行查找元素

## 错误处理

### 异常类型

- `EOutOfRange`: 索引越界
- `EInvalidOperation`: 无效操作（如空队列操作）
- `EOutOfMemory`: 内存不足

### 最佳实践

```pascal
try
  LValue := LDeque.PopBack;
except
  on E: EInvalidOperation do
    WriteLn('队列为空');
  on E: EOutOfRange do
    WriteLn('索引越界');
end;
```

## 性能注意事项

1. **预留容量**: 如果知道大概大小，使用 `Reserve` 预留容量
2. **批量操作**: 优先使用批量操作而非循环单个操作
3. **AsSlices**: 对于高性能场景，使用 `AsSlices` 进行零拷贝访问
4. **并行操作**: 大数据集使用并行版本的方法

## 线程安全

**注意**: VecDeque 不是线程安全的。多线程环境下需要外部同步机制。
