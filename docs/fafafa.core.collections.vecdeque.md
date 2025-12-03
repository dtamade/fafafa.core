# fafafa.core.collections.vecdeque

## 门面契约摘要（Facade Contract）

- 工厂函数
  - MakeVecDeque<T>(capacity=0, allocator=nil, growStrategy=nil): IDeque<T>
  - MakeQueue<T>(...): 语义等同，底层实现为 TVecDeque<T>
- 策略与容量
  - VecDeque 支持注入增长策略，但最终容量会统一向上归一到 2 的幂，以保证位掩码优化和行为一致性
  - capacity=0：使用实现默认初容量
  - allocator=nil：使用 GetRtlAllocator（全局分配器单例）
- 容量与收缩
  - Reserve(n)：保证 Capacity >= Count + n
  - ReserveExact(n)：尽量满足 Capacity == Count + n（实现可对齐为 >=）
  - Shrink()：尝试收缩，容量不小于 Count
  - ShrinkTo(cap)：将容量收敛到 cap（cap >= Count），否则抛异常
- 复杂度
  - PushFront/PushBack/PopFront/PopBack：摊销 O(1)
  - Get/Put/GetPtr（随机访问）：O(1)
- 错误模型
  - 参数错误抛 EInvalidArgument/EOutOfRange
  - TryReserveExact 返回布尔，不抛异常
- 参考
  - 详细 API/实现细节见 docs/TVecDeque_Guide.md

## 📋 模块概述

`fafafa.core.collections.vecdeque` 是 fafafa.core 框架中的高性能双端队列实现模块。它提供了基于环形缓冲区的向量双端队列（Vector Deque），支持在队列两端进行 O(1) 时间复杂度的插入和删除操作。

### 🎯 设计目标

- **高性能**: 基于环形缓冲区实现，提供 O(1) 的双端操作
- **内存高效**: 智能容量管理和增长策略
- **接口丰富**: 同时支持队列、栈、数组等多种访问模式
- **类型安全**: 基于泛型的强类型实现
- **跨平台**: 支持 Windows、Linux 等多平台

### 🏗️ 架构设计

```
IVecDeque<T>
    ↓ 继承
IDeque<T> ← IQueue<T>
    ↓ 继承
IVec<T> ← IArray<T> ← IGenericCollection<T> ← ICollection
    ↓ 实现
TVecDeque<T>
```

## 🔧 核心接口

### Clear 的语义与不变式

- Clear 仅清空逻辑长度，不释放既有容量（Capacity 保持不变）
- Clear 后必须满足空状态环形缓冲不变式：FCount=0, FHead=0, FTail=0
- 若需收缩内存，请使用 ShrinkToFit/ShrinkToFitExact

### 批量 LoadFrom/Append 语义

- **指针重载**
  - `LoadFrom(aSrc: Pointer; aCount)` 会先校验 `aSrc <> nil` 且 `aCount > 0`，否则：`aCount = 0` → Clear；`aSrc = nil, aCount > 0` → 抛 `EInvalidArgument`。
  - `Append(aSrc: Pointer; aCount)`：`aCount = 0` 直接返回，不修改状态；`aSrc = nil, aCount > 0` 抛异常。
  - `TryLoadFrom/TryAppend` 指针版遵循 `docs/partials/collections.try_apis.collection.md` 的布尔返回：`TryLoadFrom(nil,0)` 清空并 True；`TryAppend(nil,>0)` 返回 False；内部检测到重叠/不足容量也返回 False。

- **数组/集合重载**
  - `LoadFrom/Append` 的 `array of T` 与 `ICollection` 重载在语义上与指针版一致：`LoadFrom` 成功后 `Count = aCount`，`Append` 在尾部追加。
  - `TryLoadFrom/TryAppend` 的集合重载拒绝 `nil` 或 `Self`，并在类型不兼容/容量不足时返回 False，不抛异常。

- **托管类型保证**
  - LoadFrom 会在写入新元素前先清理旧元素（确保托管类型释放），成功后容器完全由源数据覆盖。
  - Append 在扩容和搬移期间若发生异常，会回滚到原始 `Count`，避免部分写入。

这些规则通过 `tests/fafafa.core.collections.vecdeque/Test_fafafa_core_collections_vecdeque_clean.pas` 中的 `LoadFrom_*`、`Append_*`、`Try*` 用例验证。

### 遍历 & 搜索语义（ForEach / Contains / Find 系列）

- **ForEach / ForEachUnChecked**
  - `ForEach(aPredicate)` 在空容器上直接返回 `True`，且不会调用回调。
  - 当回调返回 `False` 时会立即短路，整体返回 `False`；若遍历完整个区间且回调始终 `True`，则返回 `True`。
  - `ForEach(aIndex, ...)` 会先做边界检查；`ForEachUnChecked(aIndex, aCount, ...)` 省略检查，只要调用方保证范围合法即可。
  - 所有 `PredicateFunc`/`PredicateMethod`/`PredicateRefFunc` 重载语义一致；`PredicateRefFunc` 仅在 `FAFAFA_CORE_ANONYMOUS_REFERENCES`（FPC ≥ 3.3.1）开启时可用。

- **Contains / ContainsUnChecked**
  - `Contains(aValue)` 默认扫描整个容器；`Contains(aValue, aStartIndex)` 从给定逻辑索引起查找；`Contains(aValue, aStartIndex, aCount)` 仅在指定区间内搜索。
  - `aCount = 0` 时视为不搜索，直接返回 `False`。
  - 未命中返回 `False`，命中返回 `True`，不会抛异常。
  - `EqualsFunc`/`EqualsMethod`/`EqualsRefFunc` 重载分别支持函数指针、方法指针与匿名函数；`EqualsRefFunc` 与 ForEach 相同，仅在匿名引用开启时可用。
  - `ContainsUnChecked` 版本跳过边界检查，调用方需保证 `(aStartIndex + aCount) <= Count`。

- **Find / FindUnChecked**
  - 返回逻辑索引（`SizeInt`），命中即返回首个位置，否则返回 `-1`。
  - `Find(aValue, aStartIndex, aCount)` 在 `aCount = 0` 时直接返回 `-1`；`FindUnChecked` 同理但不做边界检查。
  - 提供 `EqualsFunc`/`EqualsMethod`/`EqualsRefFunc` 重载，语义与 Contains 保持一致。
  - 与 `Contains` 类似，RefFunc 版本仅在 `FAFAFA_CORE_ANONYMOUS_REFERENCES` 定义时对外可用。

这些语义已经通过 `tests/fafafa.core.collections.vecdeque/Test_fafafa_core_collections_vecdeque_clean.pas` 中的覆盖性用例锁定，可作为 API 行为契约参考。

### IVecDeque<T>

双端队列的核心接口，扩展了 `IDeque<T>` 接口：

```pascal
generic IVecDeque<T> = interface(specialize IDeque<T>)
  // 前端操作
  procedure PushFront(const aElement: T); overload;
  procedure PushFront(const aElements: array of T); overload;
  procedure PushFront(const aSrc: Pointer; aElementCount: SizeUInt); overload;
  
  function PopFront: T; overload;
  function PopFront(var aElement: T): Boolean; overload;
  function PeekFront: T; overload;
  function PeekFront(var aElement: T): Boolean; overload;
  
  // 后端操作
  procedure PushBack(const aElement: T); overload;
  procedure PushBack(const aElements: array of T); overload;
  procedure PushBack(const aSrc: Pointer; aElementCount: SizeUInt); overload;
  
  function PopBack: T; overload;
  function PopBack(var aElement: T): Boolean; overload;
  function PeekBack: T; overload;
  function PeekBack(var aElement: T): Boolean; overload;
end;
```

### TVecDeque<T>

高性能的双端队列实现类：

```pascal
generic TVecDeque<T> = class(specialize TGenericCollection<T>,
                             specialize IVec<T>,
                             specialize IDeque<T>)
```

## 🚀 主要特性

### 1. 双端操作

- **PushFront/PopFront**: 在队列前端插入/移除元素
- **PushBack/PopBack**: 在队列后端插入/移除元素
- **PeekFront/PeekBack**: 查看但不移除前端/后端元素

### 2. 多种接口兼容

- **队列接口**: `Enqueue`/`Dequeue`/`Peek`
- **栈接口**: `Push`/`Pop`/`Peek`
- **数组接口**: `Get`/`Put`/索引访问
- **向量接口**: 动态容量管理

### 3. 高级功能

- **批量操作**: 支持数组和指针的批量插入
- **容量管理**: 智能增长策略和内存优化
- **算法支持**: 填充、反转、交换、搜索、排序等
- **迭代器**: 支持安全的元素遍历

### 4. 性能优化

- **环形缓冲区**: 避免频繁的内存移动
- **2 的幂容量**: 使用位运算优化索引计算（最终容量始终归一为 2 的幂）
- **增长策略**: 支持注入（SetGrowStrategy/SetGrowStrategyI），但最终容量统一幂次归一
- **内存对齐**: 优化的内存布局

提示：ReserveExact/TryReserveExact 在实现上仍会根据 2 的幂对齐到“最小可达容量”，含义是“不走策略倍增，直接按需求对齐扩容”的更精确控制。

## 📖 使用示例

### 基本双端队列操作

```pascal
var
  LDeque: specialize TVecDeque<Integer>;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    // 从后端添加
    LDeque.PushBack(1);
    LDeque.PushBack(2);
    LDeque.PushBack(3);
    
    // 从前端添加
    LDeque.PushFront(0);
    LDeque.PushFront(-1);
    
    // 现在队列内容为: [-1, 0, 1, 2, 3]
    
    // 从前端移除
    WriteLn(LDeque.PopFront);  // 输出: -1
    
    // 从后端移除
    WriteLn(LDeque.PopBack);   // 输出: 3
    
  finally
    LDeque.Free;
  end;
end;
```

### 队列模式使用

```pascal
var
  LQueue: specialize TVecDeque<String>;
begin
  LQueue := specialize TVecDeque<String>.Create;
  try
    // 入队
    LQueue.Enqueue('任务1');
    LQueue.Enqueue('任务2');
    LQueue.Enqueue('任务3');
    
    // 出队处理
    while not LQueue.IsEmpty do
    begin
      WriteLn('处理: ', LQueue.Dequeue);
    end;
    
  finally
    LQueue.Free;
  end;
end;
```

### 栈模式使用

```pascal
var
  LStack: specialize TVecDeque<String>;
begin
  LStack := specialize TVecDeque<String>.Create;
  try
    // 压栈
    LStack.Push('操作1');
    LStack.Push('操作2');
    LStack.Push('操作3');
    
    // 弹栈（后进先出）
    while not LStack.IsEmpty do
    begin
      WriteLn('撤销: ', LStack.Pop);
    end;
    
  finally
    LStack.Free;
  end;
end;
```

### 批量操作

```pascal
var
  LDeque: specialize TVecDeque<Integer>;
  LArray: array[0..4] of Integer;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    // 准备数据
    for i := 0 to High(LArray) do
      LArray[i] := i * 10;
    
    // 批量添加到后端
    LDeque.PushBack(LArray);
    
    // 批量添加到前端
    LDeque.PushFront(@LArray[0], Length(LArray));
    
  finally
    LDeque.Free;
  end;
end;
```

### 容量管理

```pascal
var
  LDeque: specialize TVecDeque<Integer>;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('初始容量: ', LDeque.GetCapacity);
    
    // 预留容量
    LDeque.Reserve(1000);
    WriteLn('预留后容量: ', LDeque.GetCapacity);
    
    // 添加大量元素...
    
    // 收缩到合适大小
    LDeque.ShrinkToFit;
    WriteLn('收缩后容量: ', LDeque.GetCapacity);
    
  finally
    LDeque.Free;
  end;
end;
```

## ⚡ 性能特性

### 时间复杂度

| 操作 | 时间复杂度 | 说明 |
|------|------------|------|
| PushFront/PushBack | O(1) | 摊销时间复杂度 |
| PopFront/PopBack | O(1) | 常数时间 |
| PeekFront/PeekBack | O(1) | 常数时间 |
| Get/Put (索引访问) | O(1) | 常数时间 |
| Insert (中间插入) | O(n) | 线性时间 |
| Remove (中间删除) | O(n) | 线性时间 |

### 空间复杂度

- **存储空间**: O(n)，其中 n 是元素数量
- **额外空间**: O(1)，常数级别的管理开销

### 性能优化技术

1. **环形缓冲区**: 避免元素移动，提高插入/删除效率
2. **2的幂容量**: 使用位运算替代模运算，提高索引计算速度
3. **智能增长**: 根据使用模式选择最优的扩容策略
4. **内存预分配**: 减少频繁的内存分配/释放

## 🔧 构造函数

### 基本构造函数

```pascal
// 默认构造
constructor Create;

// 指定容量
constructor Create(aCapacity: SizeUInt);

// 指定分配器
constructor Create(aAllocator: TAllocator; aData: Pointer);

// 完整参数（支持外部增长策略，nil 回退默认；最终容量统一幂次归一）
constructor Create(aCapacity: SizeUInt;
                  aAllocator: TAllocator;
                  aGrowStrategy: TGrowthStrategy;
                  aData: Pointer);
```

### 从数据源构造

```pascal
// 从数组构造（支持外部增长策略，nil 回退默认；最终容量统一幂次归一）
constructor Create(const aSrc: array of T;
                  aAllocator: TAllocator;
                  aGrowStrategy: TGrowthStrategy);

// 从集合构造（支持外部增长策略，nil 回退默认；最终容量统一幂次归一）
constructor Create(const aSrc: TCollection;
                  aAllocator: TAllocator;
                  aGrowStrategy: TGrowthStrategy);

// 从指针构造（支持外部增长策略，nil 回退默认；最终容量统一幂次归一）
constructor Create(aSrc: Pointer;
                  aCount: SizeUInt;
                  aAllocator: TAllocator;
                  aGrowStrategy: TGrowthStrategy);
```

## 🎛️ 增长策略

VecDeque 支持通过 SetGrowStrategy/SetGrowStrategyI 注入自定义增长策略，用于决定“增长到多少”。
无论外部策略如何，最终容量都会按 2 的幂进行归一化，确保位掩码优化路径恒成立。这种折中：
- 兼容自定义策略的灵活性（如倍增/黄金比例/对齐包装）
- 仍保留幂次容量的性能优势（位与环绕、简单边界）
- 对齐 Java ArrayDeque 的幂次行为，同时具备策略可插拔的扩展性

进一步：可使用 TAlignedWrapperStrategy 对任意策略的结果做对齐（2^k / cache line / 页大小），再交由 VecDeque 进行幂次归一，形成两级对齐。

示例：

```pascal
uses fafafa.core.collections.base, fafafa.core.collections.vecdeque;

var
  Base: TGrowthStrategy;        // 可选：TGoldenRatioGrowStrategy.GetGlobal 等
  Aligned: TAlignedWrapperStrategy;
  Dq: specialize TVecDeque<Integer>;
begin
  // 以黄金比例策略为例，先做 64 字节对齐（缓存行）
  Base    := TGoldenRatioGrowStrategy.GetGlobal;
  Aligned := TAlignedWrapperStrategy.Create(Base, 64);

  // 通过构造器注入（也可先 Create(cap) 后 SetGrowStrategy）
  Dq := specialize TVecDeque<Integer>.Create(0, nil, Aligned, nil);
  try
    // 使用队列...
  finally
    Dq.Free;
  end;
end.
```

注意：VecDeque 最终仍会将容量归一到 2 的幂，因此该组合形成了“对齐包装 + 幂次归一”的两级策略。

如需完全自定义且不强制幂次（不建议用于环形缓冲），可使用 TVec。

提示：更多策略组合建议与“最小示例”运行脚本，参见 docs/partials/collections.best_practices.md（Windows/Linux均提供 BuildOrTest_Examples 脚本）。

## 🔍 异常处理

### 常见异常类型

| 异常类型 | 触发条件 | 处理建议 |
|----------|----------|----------|
| `EOutOfRange` | 索引越界访问 | 检查索引范围 |
| `EArgumentNil` | 传入nil指针 | 验证指针有效性 |
| `EOutOfMemory` | 内存分配失败 | 检查可用内存 |
| `EInvalidOperation` | 空队列操作 | 检查队列状态 |

### 安全操作模式

```pascal
var
  LDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
  LSuccess: Boolean;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    // 安全的Pop操作
    LSuccess := LDeque.PopFront(LValue);
    if LSuccess then
      WriteLn('弹出值: ', LValue)
    else
      WriteLn('队列为空');

    // 安全的Peek操作
    LSuccess := LDeque.PeekBack(LValue);
    if LSuccess then
      WriteLn('后端值: ', LValue);

  finally
    LDeque.Free;
  end;
end;
```

## 🧪 测试覆盖

模块包含完整的测试套件，覆盖以下方面：

### 测试类别

1. **构造函数测试** (15个测试)
   - 各种构造函数重载
   - 内存管理验证
   - 参数验证

2. **ICollection接口测试** (12个测试)
   - 基础集合操作
   - 迭代器功能
   - 序列化操作

3. **IGenericCollection接口测试** (16个测试)
   - 泛型集合操作
   - 类型信息验证
   - 数据转换

4. **IArray接口测试** (18个测试)
   - 数组访问操作
   - 索引操作
   - 批量操作

5. **IVec接口测试** (20个测试)
   - 向量操作
   - 容量管理
   - 搜索算法

6. **IDeque接口测试** (25个测试)
   - 双端队列操作
   - 队列/栈兼容性
   - 环形缓冲区行为

7. **边界条件测试** (10个测试)
   - 空队列操作
   - 大容量测试
   - 异常处理

8. **性能测试** (4个测试)
   - 基本操作性能
   - 批量操作性能
   - 内存使用效率

### 运行测试

```bash
# Windows
cd tests\fafafa.core.collections.vecdeque
BuildOrTest.bat

# Linux
cd tests/fafafa.core.collections.vecdeque
./BuildOrTest.sh
```

## 📊 性能基准

### 基准测试结果

基于 Intel i7-8700K, 16GB RAM 的测试结果：

| 操作 | 元素数量 | 耗时 (ms) | 操作/秒 |
|------|----------|-----------|---------|
| PushBack | 1,000,000 | 45 | 22,222,222 |
| PushFront | 1,000,000 | 47 | 21,276,596 |
| PopBack | 1,000,000 | 42 | 23,809,524 |
| PopFront | 1,000,000 | 44 | 22,727,273 |
| 混合操作 | 1,000,000 | 89 | 11,235,955 |

### 内存使用

- **内存开销**: 每个元素 + 8字节管理开销
- **容量利用率**: 平均 75-90%
- **内存碎片**: 极低（连续内存分配）

## 🔗 依赖关系

### 直接依赖

- `fafafa.core.base`: 基础类型和异常
- `fafafa.core.mem.allocator`: 内存分配器
- `fafafa.core.mem.utils`: 内存工具
- `fafafa.core.math`: 数学工具
- `fafafa.core.collections.base`: 集合基础
- `fafafa.core.collections.arr`: 数组实现
- `fafafa.core.collections.vec`: 向量实现
- `fafafa.core.collections.queue`: 队列接口
- `fafafa.core.collections.deque`: 双端队列接口

### 间接依赖

- 标准库: `SysUtils`, `Classes`

## 🎯 最佳实践

### 1. 选择合适的操作

```pascal
// ✅ 推荐：使用双端操作
LDeque.PushFront(element);  // O(1)
LDeque.PopBack;             // O(1)

// ❌ 避免：中间插入/删除
LDeque.InsertElement(middle_index, element);  // O(n)
LDeque.Remove(middle_index);                  // O(n)
```

### 2. 预分配容量

```pascal
// ✅ 推荐：预知大小时预分配
LDeque := specialize TVecDeque<Integer>.Create(expected_size);

// ✅ 推荐：预留额外容量
LDeque.Reserve(additional_capacity);
```

### 3. 选择合适的增长策略

```pascal
// ✅ 推荐：大多数情况使用2的幂增长
LStrategy := TPowerOfTwoGrowStrategy.GetGlobal;

// ✅ 特殊情况：内存敏感时使用线性增长
LStrategy := TLinearGrowStrategy.GetGlobal;
```

### 4. 及时释放内存

```pascal
// ✅ 推荐：不再需要时收缩容量
LDeque.ShrinkToFit;

// ✅ 推荐：使用 try-finally 确保释放
LDeque := specialize TVecDeque<Integer>.Create;
try
  // 使用 LDeque
finally
  LDeque.Free;
end;
```

## 🚧 已知限制

1. **内存连续性**: 由于环形缓冲区设计，`GetMemory` 方法返回的内存可能不连续
2. **最大容量**: 受限于 `SizeUInt` 类型的最大值
3. **线程安全**: 不是线程安全的，多线程使用需要外部同步

## 🔮 未来计划

1. **并发版本**: 开发线程安全的 `TConcurrentVecDeque`
2. **NUMA优化**: 针对NUMA架构的内存分配优化
3. **压缩存储**: 支持稀疏数据的压缩存储
4. **持久化**: 支持序列化到文件系统

## 📚 参考资料

- [Rust VecDeque Documentation](https://doc.rust-lang.org/std/collections/struct.VecDeque.html)
- [C++ std::deque Reference](https://en.cppreference.com/w/cpp/container/deque)
- [Java ArrayDeque Documentation](https://docs.oracle.com/javase/8/docs/api/java/util/ArrayDeque.html)
- [Circular Buffer - Wikipedia](https://en.wikipedia.org/wiki/Circular_buffer)

---

**版本**: 1.0.0
**最后更新**: 2024-01-XX
**维护者**: fafafa.core 开发团队
```
