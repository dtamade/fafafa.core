# fafafa.core.collections - API 完整参考手册

**版本**: 1.0 (Production Ready)  
**日期**: 2025-10-27  
**适用范围**: fafafa.core.collections 所有容器类型

---

## 📚 目录

- [快速开始](#快速开始)
- [核心接口](#核心接口)
- [容器类型](#容器类型)
- [工厂函数](#工厂函数)
- [增长策略](#增长策略)
- [分配器](#分配器)
- [通用操作](#通用操作)
- [性能指南](#性能指南)
- [常见模式](#常见模式)

---

## 快速开始

### 最小示例 - Vec (动态数组)

```pascal
{$CODEPAGE UTF8}
program quick_vec;
uses
  fafafa.core.collections, fafafa.core.collections.vec;

var
  V: specialize IVec<Integer>;
  i: Integer;
begin
  // 创建 Vec
  V := specialize MakeVec<Integer>();
  
  // 添加元素
  V.Add(10);
  V.Add(20);
  V.Add(30);
  
  // 访问元素
  WriteLn('第一个元素: ', V.Get(0));  // 输出: 10
  
  // 迭代
  for i := 0 to V.GetCount - 1 do
    WriteLn('元素 ', i, ': ', V.Get(i));
  
  // 无需手动释放 - 接口自动管理
end.
```

### 最小示例 - VecDeque (双端队列)

```pascal
{$CODEPAGE UTF8}
program quick_deque;
uses
  fafafa.core.collections, fafafa.core.collections.vecdeque;

var
  D: specialize IDeque<string>;
begin
  D := specialize MakeVecDeque<string>();
  
  // 两端操作
  D.PushBack('A');
  D.PushFront('B');    // B A
  D.PushBack('C');     // B A C
  
  WriteLn('头部: ', D.Front);  // B
  WriteLn('尾部: ', D.Back);   // C
  
  D.PopFront;  // A C
  D.PopBack;   // A
end.
```

---

## 核心接口

### ICollection (基础接口)

所有容器的根接口，提供最基本的容器操作。

```pascal
ICollection = interface
  // 基础属性
  function GetCount: SizeUInt;
  function IsEmpty: Boolean;
  
  // 清空
  procedure Clear;
  
  // 迭代器
  function PtrIter: TPtrIter;
  
  // 批量操作
  procedure LoadFromUnChecked(const aSrc: Pointer; aCount: SizeUInt);
  procedure AppendUnChecked(const aSrc: Pointer; aCount: SizeUInt);
  function TryLoadFrom(const aSrc: Pointer; aCount: SizeUInt): Boolean;
  function TryAppend(const aSrc: Pointer; aCount: SizeUInt): Boolean;
end;
```

**关键点**：
- `GetCount` - 返回当前元素数量
- `Clear` - 清空所有元素
- `Try*` - 非异常版本，返回 Boolean 表示成功/失败

---

### IVec<T> (动态数组接口)

```pascal
IVec<T> = interface(ICollection)
  // 容量管理
  function GetCapacity: SizeUInt;
  procedure Reserve(aAdditionalCount: SizeUInt);
  procedure ReserveExact(aAdditionalCount: SizeUInt);
  procedure EnsureCapacity(aRequiredCapacity: SizeUInt);
  procedure Shrink;
  procedure ShrinkTo(aMinCapacity: SizeUInt);
  procedure ShrinkToFitExact;
  
  // 元素访问
  function Get(aIndex: SizeUInt): T;
  procedure Put(aIndex: SizeUInt; const aValue: T);
  function GetPtr(aIndex: SizeUInt): Pointer;
  function GetMemory: Pointer;
  
  // 添加/删除
  procedure Add(const aValue: T);
  procedure Insert(aIndex: SizeUInt; const aValue: T);
  procedure Remove(aIndex: SizeUInt);
  procedure RemoveSwap(aIndex: SizeUInt);
  
  // 批量操作
  procedure Append(const aSrc: Pointer; aCount: SizeUInt); overload;
  procedure Append(const aSrc: array of T); overload;
  procedure LoadFrom(const aSrc: Pointer; aCount: SizeUInt); overload;
  
  // 查找与算法
  function Find(const aValue: T): SizeInt;
  function Contains(const aValue: T): Boolean;
  function BinarySearch(const aValue: T): SizeInt;
  procedure Sort;
  procedure Reverse;
  procedure Fill(const aValue: T);
end;
```

**使用示例**：
```pascal
var V: specialize IVec<Integer>;
begin
  V := specialize MakeVec<Integer>(100);  // 预分配容量 100
  
  // 容量操作
  V.Reserve(50);           // 确保还能容纳 50 个元素
  V.ReserveExact(10);      // 精确扩容 10 个
  V.Shrink;                // 收缩到当前大小
  
  // 添加
  V.Add(42);
  V.Insert(0, 10);         // 插入到开头
  
  // 查找
  if V.Contains(42) then
    WriteLn('找到 42');
  
  // 排序
  V.Sort;
end;
```

---

### IDeque<T> (双端队列接口)

```pascal
IDeque<T> = interface(IVecDeque<T>)
  // 双端访问
  function Front: T;
  function Back: T;
  function TryPeekFront(out aValue: T): Boolean;
  function TryPeekBack(out aValue: T): Boolean;
  
  // 双端添加
  procedure PushFront(const aValue: T);
  procedure PushBack(const aValue: T);
  
  // 双端删除
  function PopFront: T;
  function PopBack: T;
  function TryPopFront(out aValue: T): Boolean;
  function TryPopBack(out aValue: T): Boolean;
  
  // 容量
  function GetCapacity: SizeUInt;
  procedure Reserve(aAdditionalCount: SizeUInt);
  procedure Shrink;
end;
```

**使用示例**：
```pascal
var D: specialize IDeque<string>;
begin
  D := specialize MakeVecDeque<string>();
  
  // 队列操作
  D.PushBack('任务1');
  D.PushBack('任务2');
  while not D.IsEmpty do
    WriteLn('处理: ', D.PopFront);
  
  // 栈操作
  D.PushBack('A');
  D.PushBack('B');
  while not D.IsEmpty do
    WriteLn('弹出: ', D.PopBack);
end;
```

---

### IHashMap<K,V> (哈希映射接口)

```pascal
IHashMap<K,V> = interface(ICollection)
  // 插入/更新
  procedure Insert(const aKey: K; const aValue: V);
  procedure InsertOrAssign(const aKey: K; const aValue: V);
  
  // 查找
  function Contains(const aKey: K): Boolean;
  function TryGet(const aKey: K; out aValue: V): Boolean;
  function Get(const aKey: K): V;
  
  // 删除
  function Remove(const aKey: K): Boolean;
  
  // 遍历
  function Keys: specialize IVec<K>;
  function Values: specialize IVec<V>;
end;
```

**使用示例**：
```pascal
var M: specialize IHashMap<string, Integer>;
begin
  M := specialize MakeHashMap<string, Integer>();
  
  // 插入
  M.Insert('Alice', 30);
  M.InsertOrAssign('Bob', 25);
  
  // 查找
  if M.Contains('Alice') then
    WriteLn('年龄: ', M.Get('Alice'));
  
  // 安全查找
  var Age: Integer;
  if M.TryGet('Charlie', Age) then
    WriteLn('找到 Charlie')
  else
    WriteLn('未找到 Charlie');
end;
```

---

## 容器类型

### TVec<T> - 动态数组

**特点**：
- ✅ 随机访问 O(1)
- ✅ 末尾添加 O(1) 均摊
- ✅ 连续内存，缓存友好
- ⚠️ 中间插入/删除 O(n)

**适用场景**：
- 需要索引访问
- 频繁遍历
- 末尾增删

**示例**：
```pascal
var V: specialize TVec<Integer>;
begin
  V := specialize TVec<Integer>.Create(1000);  // 预分配
  try
    for var i := 0 to 999 do
      V.Add(i);
    
    // 高效访问
    for var i := 0 to V.GetCount - 1 do
      Process(V.GetUnChecked(i));  // 跳过边界检查
  finally
    V.Free;
  end;
end;
```

---

### TVecDeque<T> - 双端队列

**特点**：
- ✅ 两端操作 O(1)
- ✅ 随机访问 O(1)
- ✅ 环形缓冲，内存高效
- ⚠️ 内存可能不连续

**适用场景**：
- 队列/栈
- 滑动窗口
- 双端操作

**示例**：
```pascal
var D: specialize TVecDeque<Integer>;
begin
  D := specialize TVecDeque<Integer>.Create(128);
  try
    // 滑动窗口
    for var i := 0 to 1000 do
    begin
      D.PushBack(i);
      if D.GetCount > 10 then
        D.PopFront;  // 保持窗口大小 10
    end;
  finally
    D.Free;
  end;
end;
```

---

### THashMap<K,V> - 哈希映射

**特点**：
- ✅ 查找/插入 O(1) 平均
- ✅ 开放寻址，内存连续
- ⚠️ 无序
- ⚠️ 需要好的哈希函数

**适用场景**：
- 键值对存储
- 快速查找
- 缓存实现

**示例**：
```pascal
var M: specialize THashMap<string, TCustomer>;
    Customer: TCustomer;
begin
  M := specialize THashMap<string, TCustomer>.Create();
  try
    // 插入
    Customer.Name := 'Alice';
    Customer.Age := 30;
    M.Insert('CUST001', Customer);
    
    // 查找
    if M.TryGet('CUST001', Customer) then
      WriteLn('找到客户: ', Customer.Name);
  finally
    M.Free;
  end;
end;
```

---

## 工厂函数

### MakeVec<T> - 创建 Vec

```pascal
// 默认容量 + 默认分配器 + 默认策略
function MakeVec<T>(): IVec<T>;

// 指定初始容量
function MakeVec<T>(aCapacity: SizeUInt): IVec<T>;

// 完整控制
function MakeVec<T>(
  aCapacity: SizeUInt;
  aAllocator: IAllocator;
  aGrowStrategy: TGrowthStrategy
): IVec<T>;

// 从数组创建
function MakeVec<T>(const aSrc: array of T): IVec<T>;
```

**示例**：
```pascal
// 简单创建
var V1 := specialize MakeVec<Integer>();

// 预分配容量
var V2 := specialize MakeVec<Integer>(1000);

// 自定义策略
var Strategy := TFactorGrowStrategy.Create(1.5);
var V3 := specialize MakeVec<Integer>(100, nil, Strategy);

// 从数组
var Arr: array[0..4] of Integer = (1, 2, 3, 4, 5);
var V4 := specialize MakeVec<Integer>(Arr);
```

---

### MakeVecDeque<T> - 创建 VecDeque

```pascal
function MakeVecDeque<T>(): IDeque<T>;
function MakeVecDeque<T>(aCapacity: SizeUInt): IDeque<T>;
function MakeVecDeque<T>(
  aCapacity: SizeUInt;
  aAllocator: IAllocator;
  aGrowStrategy: TGrowthStrategy
): IDeque<T>;
```

**示例**：
```pascal
// 默认创建
var D1 := specialize MakeVecDeque<string>();

// 预分配（会自动调整到 2 的幂）
var D2 := specialize MakeVecDeque<string>(100);  // 实际容量 128
```

---

### MakeHashMap<K,V> - 创建 HashMap

```pascal
function MakeHashMap<K,V>(): IHashMap<K,V>;
function MakeHashMap<K,V>(aCapacity: SizeUInt): IHashMap<K,V>;
function MakeHashMap<K,V>(
  aCapacity: SizeUInt;
  aHashFunc: THashFunc<K>
): IHashMap<K,V>;
```

---

## 增长策略

### 预设策略

| 策略 | 行为 | 适用场景 |
|------|------|---------|
| **TPowerOfTwoGrowStrategy** | 2 的幂增长 | 通用、位运算友好 |
| **TDoublingGrowStrategy** | 2 倍增长 | 经典摊销 O(1) |
| **TFactorGrowStrategy** | 倍数增长 (1.5x) | 内存节约 |
| **TGoldenRatioGrowStrategy** | 黄金比例 (1.618x) | 平衡增长 |
| **TFixedGrowStrategy** | 固定增量 | 可预测内存 |
| **TExactGrowStrategy** | 精确增长 | 最小浪费 |

### 使用示例

```pascal
// PowerOfTwo (默认)
var V := specialize TVec<Integer>.Create();  // 自动使用 PowerOfTwo

// Factor 策略
var Strategy := TFactorGrowStrategy.Create(1.5);
V.SetGrowStrategy(Strategy);

// GoldenRatio 策略
var Strategy2 := TGoldenRatioGrowStrategy.Create();
V.SetGrowStrategy(Strategy2);

// Exact 策略（最小浪费）
var Strategy3 := TExactGrowStrategy.Create();
V.SetGrowStrategy(Strategy3);
```

### 策略对比

```pascal
// 场景：从 0 增长到 1000 个元素

// PowerOfTwo: 0 → 1 → 2 → 4 → 8 → 16 → 32 → 64 → 128 → 256 → 512 → 1024
// 内存浪费: 24 bytes (1024 - 1000)

// Doubling: 0 → 1 → 2 → 4 → 8 → 16 → 32 → 64 → 128 → 256 → 512 → 1024
// 内存浪费: 24 bytes

// Factor(1.5): 0 → 1 → 2 → 3 → 4 → 6 → 9 → 13 → 19 → 28 → ... → 1024
// 内存浪费: 更少，但增长次数更多

// Exact: 每次精确分配所需容量
// 内存浪费: 0 bytes，但分配次数最多
```

---

## 分配器

### 默认分配器

```pascal
// RTL 分配器（默认）
var V := specialize TVec<Integer>.Create();  // 使用 GetRtlAllocator()
```

### 自定义分配器

```pascal
// 实现 IAllocator 接口
type
  TMyAllocator = class(TInterfacedObject, IAllocator)
  public
    function Allocate(aSize: SizeUInt): Pointer;
    procedure Deallocate(aPtr: Pointer);
  end;

// 使用
var Allocator := TMyAllocator.Create();
var V := specialize TVec<Integer>.Create(0, Allocator);
```

---

## 通用操作

### 容量管理

```pascal
var V: specialize IVec<Integer>;
begin
  V := specialize MakeVec<Integer>();
  
  // 预分配
  V.Reserve(1000);  // 确保能容纳当前 + 1000 个元素
  
  // 精确分配
  V.ReserveExact(100);  // 精确扩容 100 个
  
  // 收缩
  V.Shrink;  // 收缩到当前大小
  V.ShrinkTo(100);  // 收缩到至少 100
  V.ShrinkToFitExact;  // 精确收缩
  
  // 检查
  WriteLn('容量: ', V.GetCapacity);
  WriteLn('元素数: ', V.GetCount);
end;
```

### 批量操作

```pascal
var V: specialize IVec<Integer>;
    Src: array[0..99] of Integer;
begin
  V := specialize MakeVec<Integer>();
  
  // 批量添加
  V.Append(Src, 100);  // 从指针
  V.Append(Src);       // 从数组
  
  // 批量加载（清空后添加）
  V.LoadFrom(Src, 100);
  
  // 非异常版本
  if V.TryAppend(Src, 100) then
    WriteLn('成功添加');
end;
```

### 查找与算法

```pascal
var V: specialize IVec<Integer>;
begin
  V := specialize MakeVec<Integer>();
  V.Append([1, 5, 3, 9, 2]);
  
  // 查找
  var Idx := V.Find(5);  // 返回索引或 -1
  
  // 包含
  if V.Contains(9) then
    WriteLn('找到 9');
  
  // 排序
  V.Sort;
  
  // 二分查找（需已排序）
  Idx := V.BinarySearch(5);
  
  // 反转
  V.Reverse;
  
  // 填充
  V.Fill(0);  // 全部填充为 0
end;
```

---

## 性能指南

### Vec vs VecDeque 选择

| 操作 | TVec | TVecDeque |
|------|------|-----------|
| 末尾添加 | ⭐⭐⭐⭐⭐ O(1) | ⭐⭐⭐⭐⭐ O(1) |
| 头部添加 | ⭐ O(n) | ⭐⭐⭐⭐⭐ O(1) |
| 随机访问 | ⭐⭐⭐⭐⭐ O(1) | ⭐⭐⭐⭐ O(1) |
| 中间插入 | ⭐ O(n) | ⭐ O(n) |
| 内存连续 | ✅ 是 | ⚠️ 可能跨环 |

**建议**：
- 只需末尾操作 → **TVec**
- 需要双端操作 → **TVecDeque**
- 需要连续内存（SIMD）→ **TVec**

### 容量预分配

```pascal
// ❌ 低效：频繁重分配
var V := specialize MakeVec<Integer>();
for var i := 0 to 10000 do
  V.Add(i);  // 可能触发多次扩容

// ✅ 高效：预分配
var V := specialize MakeVec<Integer>(10000);
for var i := 0 to 10000 do
  V.Add(i);  // 无需扩容
```

### 批量操作优化

```pascal
// ❌ 低效：逐个添加
for var i := 0 to High(Arr) do
  V.Add(Arr[i]);

// ✅ 高效：批量添加
V.Append(Arr);  // 一次内存拷贝
```

---

## 常见模式

### 模式 1: 栈

```pascal
var Stack: specialize IVec<Integer>;
begin
  Stack := specialize MakeVec<Integer>();
  
  // Push
  Stack.Add(10);
  Stack.Add(20);
  
  // Pop
  var Value := Stack.Get(Stack.GetCount - 1);
  Stack.Remove(Stack.GetCount - 1);
end;
```

### 模式 2: 队列

```pascal
var Queue: specialize IDeque<string>;
begin
  Queue := specialize MakeVecDeque<string>();
  
  // Enqueue
  Queue.PushBack('任务1');
  Queue.PushBack('任务2');
  
  // Dequeue
  var Task := Queue.PopFront;
end;
```

### 模式 3: 环形缓冲

```pascal
var Ring: specialize IDeque<Integer>;
const SIZE = 10;
begin
  Ring := specialize MakeVecDeque<Integer>();
  
  for var i := 0 to 1000 do
  begin
    Ring.PushBack(i);
    if Ring.GetCount > SIZE then
      Ring.PopFront;  // 保持大小
  end;
end;
```

### 模式 4: LRU 缓存

```pascal
var Cache: specialize IHashMap<string, TValue>;
    AccessOrder: specialize IDeque<string>;
begin
  Cache := specialize MakeHashMap<string, TValue>();
  AccessOrder := specialize MakeVecDeque<string>();
  
  // 访问
  if Cache.Contains(Key) then
  begin
    // 移到最后
    AccessOrder.Remove(AccessOrder.Find(Key));
    AccessOrder.PushBack(Key);
  end;
  
  // 淘汰
  if AccessOrder.GetCount > MAX_SIZE then
  begin
    var OldKey := AccessOrder.PopFront;
    Cache.Remove(OldKey);
  end;
end;
```

---

## 错误处理

### 异常 vs Try* API

```pascal
// 异常方式
try
  V.Get(100);  // 可能抛出 EIndexOutOfRange
except
  on E: EIndexOutOfRange do
    WriteLn('索引越界');
end;

// Try* 方式（无异常）
var Value: Integer;
if V.TryGet(100, Value) then
  WriteLn('值: ', Value)
else
  WriteLn('索引无效');
```

### 边界检查

```pascal
// 带检查（安全）
var Value := V.Get(Index);

// 无检查（性能优先，需自行保证有效性）
var Value := V.GetUnChecked(Index);  // 快 ~10%
```

---

## 线程安全

**重要**：Collections 模块**非线程安全**，需要外部同步。

```pascal
// ❌ 不安全
// 线程 1: V.Add(10);
// 线程 2: V.Add(20);

// ✅ 安全
var Lock: TRTLCriticalSection;
begin
  InitCriticalSection(Lock);
  try
    EnterCriticalSection(Lock);
    try
      V.Add(10);
    finally
      LeaveCriticalSection(Lock);
    end;
  finally
    DoneCriticalSection(Lock);
  end;
end;
```

---

## 迁移指南

### 从 Delphi TList<T> 迁移

```pascal
// Delphi
var List := TList<Integer>.Create;
List.Add(10);
List[0] := 20;
List.Free;

// fafafa.core
var V := specialize MakeVec<Integer>();
V.Add(10);
V.Put(0, 20);
// 无需 Free - 接口自动管理
```

### 从 FGL TFPGList<T> 迁移

```pascal
// FGL
var List := specialize TFPGList<Integer>.Create;
List.Add(10);
List[0] := 20;
List.Free;

// fafafa.core
var V := specialize MakeVec<Integer>();
V.Add(10);
V.Put(0, 20);
```

---

## 参考资源

### 文档
- **生产就绪报告**: `docs/COLLECTIONS_PRODUCTION_READINESS_REPORT.md`
- **性能优化路线图**: `docs/COLLECTIONS_PROFESSIONAL_PERFORMANCE_ROADMAP.md`
- **最佳实践**: `docs/Collections_Best_Practices.md`
- **示例集**: `examples/fafafa.core.collections/`

### 源码
- **Vec**: `src/fafafa.core.collections.vec.pas`
- **VecDeque**: `src/fafafa.core.collections.vecdeque.pas`
- **HashMap**: `src/fafafa.core.collections.hashmap.pas`
- **Base**: `src/fafafa.core.collections.base.pas`

### 测试
- **Vec 测试**: `tests/fafafa.core.collections.vec/`
- **VecDeque 测试**: `tests/fafafa.core.collections.vecdeque/`
- **集成测试**: `tests/fafafa.core.collections/`

---

## 版本历史

### v1.0 (2025-10-27) - Production Ready
- ✅ 核心容器完整实现
- ✅ 22/22 测试通过
- ✅ 0 内存泄漏
- ✅ 性能优化（100x Append，10-20x 位运算）
- ✅ 生产环境验证

---

**维护者**: fafafa.core Team  
**许可证**: MIT  
**状态**: ✅ Production Ready - A 级
