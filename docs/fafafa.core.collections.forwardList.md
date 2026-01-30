# fafafa.core.collections.forwardList

## 📋 概述

`fafafa.core.collections.forwardList` 是 fafafa.core 框架中的单向链表容器实现。它提供了高效的前向迭代、头部插入/删除操作，以及完整的容器算法支持。

## 🎯 设计特点

- **单向链表结构**: 每个节点只包含指向下一个节点的指针
- **高效头部操作**: O(1) 时间复杂度的头部插入和删除
- **内存安全**: 自动管理托管类型的生命周期
- **类型安全**: 完整的泛型支持
- **算法丰富**: 继承自基类的完整容器算法
- **跨平台**: 支持 Windows 和 Linux

## 🏗️ 架构设计

### 接口层次结构

```
ICollection
  └── IGenericCollection<T>
      └── IForwardList<T>
```

### 核心组件

- **IForwardList<T>**: 单向链表接口
- **TForwardList<T>**: 具体实现类
- **TForwardListNode<T>**: 内部节点结构

### 能力与语义（总览）

- 最小必需：Front / PushFront / PopFront
- 扩展能力：InsertAfter / EraseAfter / Remove / RemoveIf / Find / FindIf / Sort / Unique / Merge / Splice / Resize 等
- 无 Back / PushBack / PopBack（单向链表特性）
- Checked / Try* / Unchecked 分层：
  - Checked 抛出异常（空表 Front/PopFront 抛 EEmptyCollection；无效迭代器抛 EInvalidOperation）
  - Try* 返回 False，不抛异常（如 TryFront/TryPopFront）
  - Unchecked 跳过检查，仅用于性能敏感且前置条件已由调用方保证的场景；建议在 DEBUG 构建下配合 DebugValidateTail 等检查不变量


## 📚 API 参考

### 构造函数

```pascal
// 默认构造函数
constructor Create;

// 指定分配器
constructor Create(aAllocator: TAllocator);

// 从数组构造
constructor Create(const aSrc: array of T);

// 从其他容器构造
constructor Create(const aSrc: TCollection);

// 从内存指针构造
constructor Create(aSrc: Pointer; aElementCount: SizeUInt);
```

### 基础操作

#### PushFront - 头部插入
```pascal
procedure PushFront(const aElement: T);
```
在链表头部插入一个元素，时间复杂度 O(1)。

#### PopFront - 头部删除
```pascal
function PopFront: T;
function TryPopFront(out aElement: T): Boolean;
```
移除并返回头部元素。`TryPopFront` 是安全版本，不会抛出异常。

#### Front - 访问头部
```pascal
function Front: T;
function TryFront(out aElement: T): Boolean;
```
获取头部元素的值（按值返回），不移除元素。

> 迭代器约定：Find/FindIf 返回的迭代器保持 Started=False，调用方在首次 MoveNext 时即命中当前匹配元素。


### 高级操作

> 语义补充：详见 docs/fafafa.core.collections.forwardList.addendum.md（before_begin 约定、Splice 约束、EraseAfter 调试断言）。

#### InsertAfter - 位置插入
```pascal
function InsertAfter(aPosition: TIter; const aElement: T): TIter;
```
在指定迭代器位置之后插入元素，返回指向新元素的迭代器。

#### EraseAfter - 位置删除
```pascal
function EraseAfter(aPosition: TIter): TIter;
```
删除指定迭代器位置之后的元素。

#### Remove - 值删除
```pascal
function Remove(const aElement: T): SizeUInt;
function Remove(const aElement: T; aEquals: TEqualsFunc; aData: Pointer): SizeUInt;
```
移除所有等于指定值的元素，返回移除的数量。

#### RemoveIf - 条件删除
```pascal
function RemoveIf(aPredicate: TPredicateFunc; aData: Pointer): SizeUInt;
```
移除所有满足条件的元素。

#### Find - 查找
```pascal
function Find(const aElement: T): TIter;
function FindIf(aPredicate: TPredicateFunc; aData: Pointer): TIter;
```
查找元素，返回迭代器。

### 容器算法

继承自 `IGenericCollection<T>` 的算法：

- **ForEach**: 遍历所有元素
- **Contains**: 检查是否包含元素
- **CountOf**: 统计指定元素数量
- **CountIF**: 统计满足条件的元素数量
- **Fill**: 填充所有元素
- **Zero**: 将所有元素清零
- **Replace**: 替换元素
- **ReplaceIf**: 条件替换
- **Reverse**: 反转链表

## 💡 使用示例

### 基础用法

```pascal
var
  LList: specialize TForwardList<Integer>;
  LValue: Integer;
begin
  LList := specialize TForwardList<Integer>.Create;
  try
    // 添加元素
    LList.PushFront(3);
    LList.PushFront(2);
    LList.PushFront(1);

    // 访问头部
    WriteLn('头部元素: ', LList.Front); // 输出: 1

    // 遍历
    for LValue in LList do
      WriteLn('元素: ', LValue);

    // 弹出元素
    while not LList.IsEmpty do
      WriteLn('弹出: ', LList.PopFront);

  finally
    LList.Free;
  end;
end;
```

### 插入和删除

```pascal
var
  LList: specialize TForwardList<Integer>;
  LIter: specialize TIter<Integer>;
begin
  LList := specialize TForwardList<Integer>.Create;
  try
    LList.PushFront(3);
    LList.PushFront(1);

    // 在第一个元素后插入2
    LIter := LList.Iter;
    LIter.MoveNext; // 移动到第一个元素
    LList.InsertAfter(LIter, 2);

    // 现在链表为: 1 -> 2 -> 3

  finally
    LList.Free;
  end;
end;
```

### 字符串链表

```pascal
var
  LList: specialize TForwardList<String>;
begin
  LList := specialize TForwardList<String>.Create;
  try
    LList.PushFront('World');
    LList.PushFront('Hello');

    // 查找
    if LList.Contains('Hello') then
      WriteLn('找到 Hello');

    // 移除
    LList.Remove('Hello');

  finally
    LList.Free;
  end;
end;
```

### 数组操作

```pascal
var
  LList: specialize TForwardList<Integer>;
  LArray: array[0..2] of Integer = (1, 2, 3);
  LResult: specialize TGenericArray<Integer>;
begin
  LList := specialize TForwardList<Integer>.Create;
  try
    // 从数组加载
    LList.LoadFrom(LArray);

    // 转换为数组
    LResult := LList.ToArray;

    // 反转
    LList.Reverse;

  finally
    LList.Free;
  end;
end;

## 语义注意事项与约束

- Resize 语义：
  - 本容器仅对头部操作高效，Resize 扩大时通过 PushFront 在“头部补齐”，因此元素的相对顺序与“尾部补齐”的容器不同；请按需调整调用顺序或改用更合适的容器。
- Merge 前置条件：
  - Merge 假定参与合并的两个链表均已按同一比较器有序；若未排序，合并结果不保证整体有序。
- Splice 约束：
  - 不支持将同一链表自拼接（self-splice），调用将抛出 EInvalidOperation。
  - 迭代器归属必须正确（aPosition 属于目标、aFirst/aLast 属于源），否则抛出 EInvalidArgument。

```

## ⚡ 性能特征

| 操作 | 时间复杂度 | 说明 |
|------|------------|------|
| PushFront | O(1) | 头部插入 |
| PopFront | O(1) | 头部删除 |
| Front | O(1) | 访问头部 |
| InsertAfter | O(1) | 位置插入 |
| EraseAfter | O(1) | 位置删除 |
| Find | O(n) | 线性查找 |
| Remove | O(n) | 线性删除 |
| Count | O(1) | 元素计数 |
| Clear | O(n) | 清空容器 |

## 🛡️ 安全与异常模型

- 层级模型：Checked / Try* / Unchecked（三层）
  - 空容器 Front/PopFront：EEmptyCollection
  - 迭代器越界/位置无效：EInvalidOperation
  - 指针参数为 nil：EArgumentNil
  - 保存容量不足/越界：EOutOfRange
- 异常安全：
  - 强保证：失败的操作不改变容器状态（InsertAfter/EraseAfter 等）
  - 基本保证：异常发生时容器保持有效状态
  - 无抛出：Try* 系列不抛异常
- 线程安全：本容器非并发安全；并发场景请在外层加锁或使用并发安全包装

## 🧪 测试覆盖

模块包含完整的测试套件：

- 构造函数和析构函数测试
- ICollection 接口测试
- IGenericCollection 接口测试
- IForwardList 接口测试
- 容器算法测试
- 异常处理测试
- 性能基准测试
- 托管类型测试

## 📦 依赖关系

- `fafafa.core.base`: 基础类型和异常
- `fafafa.core.mem.allocator`: 内存分配器
- `fafafa.core.collections.base`: 容器基类
- `fafafa.core.collections.elementManager`: 元素管理器

## 🔄 版本历史

### v1.0.0 (2025-08-06)
- 初始版本
- 完整的单向链表实现
- 支持所有标准容器操作
- 完整的测试覆盖

提示：集合策略组合与增长建议，参见 docs/partials/collections.best_practices.md。

## 迭代器失效规则与复杂度说明（补充）

- 迭代器类别：前向迭代器（forward iterator）。
- 失效规则：
  - PushFront/PopFront 会影响头部元素；指向被删除节点的迭代器失效，但其他节点的迭代器保持有效。
  - InsertAfter/EraseAfter 仅影响被插入/删除位置之后的直接邻接关系；指向被删除节点的迭代器失效，指向其他节点的迭代器保持有效。
  - Splice/Merge/Unique/Sort/Reverse 可能全表重连，指向节点的迭代器在节点仍存在时仍有效，但任何指向已移除节点的迭代器失效；Sort/Reverse 后元素次序改变，依赖次序的遍历逻辑需重启迭代。
- 复杂度总览（与正文表一致）：
  - PushFront/PopFront/Front/InsertAfter/EraseAfter：O(1)
  - Find/Remove/RemoveIf：O(n)
  - Sort/Merge/Unique/Reverse：O(n log n) 或 O(n)（视实现，当前实现：归并排序 O(n log n)，Unique O(n)，Reverse O(n)）

## UnChecked 系列方法使用说明

- UnChecked 方法（如 PushFrontUnChecked/PopFrontUnChecked/ClearUnChecked 等）绕过参数与状态检查以获取更高性能。
- 适用场景：
  - 上层已通过逻辑保证非空/范围正确的热路径；
  - 性能敏感且可接受由调用方保证前置条件的场合。
- 风险与约束：
  - 调用者必须确保前置条件（如链表非空、迭代器归属正确、无越界等）；
  - 违规使用可能导致未定义行为（访问违规/内存泄漏/数据损坏）。
- 建议：
  - 在调试/开发期优先使用安全版本；经性能分析确认瓶颈后再替换为 UnChecked 版本。

