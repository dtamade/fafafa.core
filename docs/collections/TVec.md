# TVec 使用指南

## 概述

`TVec<T>` 是动态向量（可变长度数组），提供连续内存存储、可配置增长策略，以及丰富的操作接口。

## 核心特性

- **连续内存**：底层 `TArray<T>` 保证内存连续，缓存友好
- **可配置增长策略**：默认 1.5x，可自定义
- **栈操作**：Push/Pop 支持 LIFO 语义
- **函数式操作**：Filter、Retain、Any、All
- **O(1) 删除**：DeleteSwap 不关心顺序时高效删除

## 复杂度速查

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| Push | O(1) 摊销 | 末尾追加 |
| Pop | O(1) | 末尾移除 |
| Get/Put | O(1) | 随机访问 |
| Insert | O(n) | 需移动后续元素 |
| Delete | O(n) | 需移动后续元素 |
| DeleteSwap | O(1) | 与末尾交换，破坏顺序 |
| Filter | O(n) | 创建新向量 |
| Retain | O(n) | 就地过滤 |

## 快速开始

### 基本使用

```pascal
uses
  fafafa.core.collections.vec;

var
  Vec: specialize TVec<Integer>;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    // 添加元素
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    // 随机访问
    WriteLn(Vec[0]);  // 1
    Vec[0] := 10;
    
    // 栈操作
    WriteLn(Vec.Pop);   // 3
    WriteLn(Vec.Peek);  // 2
    
    // 遍历
    for var I := 0 to Vec.Count - 1 do
      WriteLn(Vec[I]);
  finally
    Vec.Free;
  end;
end;
```

### 预分配容量

```pascal
// 已知大致元素数量时，预分配避免多次扩容
Vec := specialize TVec<Integer>.Create(1000);  // 初始容量 1000

// 或动态预留
Vec.Reserve(500);  // 预留额外 500 容量
```

## 删除操作对比

### Delete vs DeleteSwap

```pascal
Vec := specialize TVec<Integer>.Create;
Vec.Push(1); Vec.Push(2); Vec.Push(3); Vec.Push(4);
// [1, 2, 3, 4]

// Delete: 保持顺序，O(n)
Vec.Delete(1);  // 删除索引 1 的元素
// [1, 3, 4]  -- 后续元素前移

// DeleteSwap: 破坏顺序，O(1)
Vec.DeleteSwap(0);  // 用末尾元素替换
// [4, 3]  -- 元素 4 移到索引 0
```

**建议**：不关心顺序时，始终使用 `DeleteSwap`。

## 函数式操作

### Filter - 创建过滤后的新向量

```pascal
function IsEven(const X: Integer; Data: Pointer): Boolean;
begin
  Result := X mod 2 = 0;
end;

var
  Evens: specialize IVec<Integer>;
begin
  Evens := Vec.Filter(@IsEven, nil);
  // 原 Vec 不变，Evens 包含所有偶数
end;
```

### Retain - 就地过滤

```pascal
// 保留满足条件的元素，删除不满足的
Vec.Retain(@IsEven, nil);
// Vec 现在只包含偶数，无额外内存分配
```

### Any / All

```pascal
// 检查是否存在偶数
if Vec.Any(@IsEven, nil) then
  WriteLn('存在偶数');

// 检查是否全部为正数
function IsPositive(const X: Integer; Data: Pointer): Boolean;
begin
  Result := X > 0;
end;

if Vec.All(@IsPositive, nil) then
  WriteLn('全部为正数');
```

## 高级操作

### Drain - 范围删除并返回被删元素

```pascal
Vec := [1, 2, 3, 4, 5];
var Removed := Vec.Drain(1, 3);  // 删除索引 1 开始的 3 个元素
// Vec = [1, 5]
// Removed = [2, 3, 4]
```

### SplitOff - 分割向量

```pascal
Vec := [1, 2, 3, 4, 5];
var Tail := Vec.SplitOff(3);  // 从索引 3 分割
// Vec = [1, 2, 3]
// Tail = [4, 5]
```

### Splice - 删除并插入

```pascal
Vec := [1, 2, 3, 4, 5];
Vec.Splice(1, 2, [10, 20, 30]);  // 删除 2 个，插入 3 个
// Vec = [1, 10, 20, 30, 4, 5]
```

### Dedup - 移除相邻重复

```pascal
Vec := [1, 1, 2, 2, 2, 3, 1];
Vec.Dedup;
// Vec = [1, 2, 3, 1]  -- 注意：只移除相邻重复
```

## 增长策略

### 内置策略

```pascal
uses
  fafafa.core.collections.base;

// 默认：1.5 倍增长
Vec.GrowStrategy := specialize TFactorGrowStrategy.Create(1.5);

// 倍增（2x）
Vec.GrowStrategy := TDoublingGrowStrategy.Create;

// 固定增长
Vec.GrowStrategy := specialize TFixedGrowStrategy.Create(100);

// 精确增长（无浪费，但频繁分配）
Vec.GrowStrategy := TExactGrowStrategy.Create;

// 黄金比例（1.618x，低浪费）
Vec.GrowStrategy := TGoldenRatioGrowStrategy.Create;
```

### 自定义策略

```pascal
type
  TMyGrowStrategy = class(TInterfacedObject, IGrowthStrategy)
    function CalcNewCapacity(aCurrentCapacity, aRequiredCapacity: SizeUInt): SizeUInt;
    begin
      // 自定义逻辑
      Result := aRequiredCapacity * 2;
    end;
  end;

Vec.GrowStrategy := TMyGrowStrategy.Create;
```

## 容量管理

```pascal
// 预分配
Vec.Reserve(1000);     // 预留额外容量
Vec.EnsureCapacity(1000);  // 确保总容量至少 1000

// 收缩
Vec.Shrink;       // 收缩到 Count
Vec.ShrinkToFit;  // 智能收缩（滞回策略，避免抖动）
Vec.FreeBuffer;   // 完全释放内部缓冲

// 截断
Vec.Truncate(10);  // 保留前 10 个元素，不改变容量
```

## 批量操作

### Insert 批量插入

```pascal
// 从数组插入
Vec.Insert(0, [10, 20, 30]);

// 从指针插入
Vec.Insert(0, @Data[0], DataCount);

// 从其他容器插入
Vec.Insert(0, OtherVec, OtherVec.Count);
```

### Write 覆盖写入

```pascal
// 覆盖指定位置，自动扩容
Vec.Write(5, [100, 200, 300]);
```

## 性能提示

1. **预分配**：已知元素数量时，使用 `Create(capacity)` 或 `Reserve`
2. **批量操作**：优先使用 `Push(array)` 而非循环 `Push(element)`
3. **删除策略**：不关心顺序时用 `DeleteSwap`
4. **就地操作**：`Retain` 比 `Filter` 更高效（无额外分配）
5. **避免频繁收缩**：使用 `ShrinkToFit`（滞回策略）而非 `Shrink`

## 与其他容器对比

| 需求 | 推荐容器 |
|------|----------|
| 只需末尾操作 | TVec |
| 需要头尾都高效 | TVecDeque |
| 频繁中间插入 | TList |
| 需要有序且去重 | TTreeSet |
| 需要快速查找 | THashSet |

## 参见

- [TVecDeque](TVecDeque.md) - 双端队列
- [TList](TList.md) - 链表
- [增长策略](../GrowthStrategy.md) - 增长策略详解
