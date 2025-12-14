# TSkipList - 跳表使用指南

## 概述

`TSkipList<K,V>` 是基于**随机化跳表**实现的有序映射。

| 特性 | 描述 |
|------|------|
| 结构 | 多层链表 |
| 查找/插入/删除 | O(log n) 平均 |
| 迭代顺序 | **按键排序** |
| 范围查询 | O(log n + k) |

> **适用场景**：需要有序遍历、范围查询，且实现简单的场景。比红黑树更易实现和调试。

## 快速开始

```pascal
uses
  fafafa.core.collections.skiplist;

var
  SL: specialize TSkipList<Integer, String>;
begin
  SL := specialize TSkipList<Integer, String>.Create;
  try
    // 插入（自动排序）
    SL.Put(3, 'three');
    SL.Put(1, 'one');
    SL.Put(2, 'two');
    
    // 按键顺序遍历
    for var Entry in SL.ToArray do
      WriteLn(Entry.Key, ': ', Entry.Value);
    // 输出: 1: one, 2: two, 3: three
    
    // 范围查询
    var Range := SL.Range(1, 2);  // 键在 [1, 2] 的条目
  finally
    SL.Free;
  end;
end;
```

## API 参考

### 创建

```pascal
// 默认比较器
SL := specialize TSkipList<Integer, String>.Create;

// 自定义比较器
function MyCompare(const A, B: String): SizeInt;
begin
  Result := CompareStr(A, B);
end;

SL := specialize TSkipList<String, Integer>.Create(@MyCompare);
```

### 核心操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Put(key, value): Boolean` | 插入/更新 | O(log n) |
| `Get(key, out value): Boolean` | 获取值 | O(log n) |
| `ContainsKey(key): Boolean` | 检查键 | O(log n) |
| `Remove(key): Boolean` | 删除 | O(log n) |
| `Clear` | 清空 | O(n) |

### 有序操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Min(out key, out value): Boolean` | 最小键值对 | O(1) |
| `Max(out key, out value): Boolean` | 最大键值对 | O(n)* |
| `Range(from, to): TEntryArray` | 范围查询 | O(log n + k) |
| `ToArray: TEntryArray` | 导出有序数组 | O(n) |

> *可以优化为 O(1)，当前实现是 O(n)

### 状态查询

| 方法 | 描述 |
|------|------|
| `GetCount: SizeUInt` | 元素数量 |
| `IsEmpty: Boolean` | 是否为空 |

## 跳表原理

```
Level 3:  H ────────────────────────────> 9 ──> nil
Level 2:  H ──────────> 3 ──────────────> 9 ──> nil
Level 1:  H ────> 1 ──> 3 ────> 5 ──────> 9 ──> nil
Level 0:  H -> 1 -> 2 -> 3 -> 4 -> 5 -> 7 -> 9 -> nil

查找 5:
  从最高层开始，跳跃前进
  Level 3: H -> 9 (5 < 9, 下降)
  Level 2: H -> 3 -> 9 (5 > 3, 5 < 9, 下降)
  Level 1: 3 -> 5 (找到!)
```

## 使用模式

### 模式 1：有序存储

```pascal
var
  Scores: specialize TSkipList<Integer, String>;
begin
  Scores.Put(85, 'Bob');
  Scores.Put(95, 'Alice');
  Scores.Put(75, 'Carol');
  
  // 按分数顺序遍历
  for var Entry in Scores.ToArray do
    WriteLn(Entry.Key, ': ', Entry.Value);
end;
```

### 模式 2：范围查询

```pascal
var
  Events: specialize TSkipList<TDateTime, String>;
begin
  // 查询某日期范围内的事件
  var Today := Date;
  var Tomorrow := Today + 1;
  
  var TodayEvents := Events.Range(Today, Tomorrow);
  for var E in TodayEvents do
    WriteLn(E.Value);
end;
```

### 模式 3：排行榜

```pascal
type
  TLeaderboard = specialize TSkipList<Integer, String>;

var
  Board: TLeaderboard;
  
procedure UpdateScore(const Player: String; Score: Integer);
begin
  // 分数作为键，自动排序
  Board.Put(-Score, Player);  // 负数实现降序
end;

function TopN(N: Integer): TArray<String>;
var
  All: TLeaderboard.TEntryArray;
begin
  All := Board.ToArray;
  SetLength(Result, Min(N, Length(All)));
  for var i := 0 to High(Result) do
    Result[i] := All[i].Value;
end;
```

## 典型应用

### 时间序列数据

```pascal
type
  TTimeSeries = specialize TSkipList<Int64, Double>;  // timestamp -> value

var
  Series: TTimeSeries;

// 查询时间范围内的数据点
function QueryRange(Start, End: TDateTime): TArray<Double>;
var
  Entries: TTimeSeries.TEntryArray;
begin
  Entries := Series.Range(
    DateTimeToUnix(Start),
    DateTimeToUnix(End)
  );
  SetLength(Result, Length(Entries));
  for var i := 0 to High(Entries) do
    Result[i] := Entries[i].Value;
end;
```

### 区间调度

```pascal
type
  TInterval = record
    Start, End: Integer;
  end;
  TIntervalMap = specialize TSkipList<Integer, TInterval>;

// 按开始时间排序，快速查找重叠
function FindOverlapping(Map: TIntervalMap; Query: TInterval): TArray<TInterval>;
var
  Candidates: TIntervalMap.TEntryArray;
begin
  // 查找可能重叠的区间
  Candidates := Map.Range(Query.Start - MaxLength, Query.End);
  // 精确过滤...
end;
```

### 有序事件队列

```pascal
type
  TEventQueue = specialize TSkipList<TDateTime, TProc>;

procedure ProcessEvents(Queue: TEventQueue);
var
  Key: TDateTime;
  Handler: TProc;
begin
  while Queue.Min(Key, Handler) do
  begin
    if Key > Now then Break;  // 未到时间
    Handler();
    Queue.Remove(Key);
  end;
end;
```

## SkipList vs TreeMap

| 特性 | SkipList | TreeMap |
|------|----------|---------|
| 平均复杂度 | O(log n) | O(log n) |
| 最坏复杂度 | O(n)* | O(log n) |
| 实现复杂度 | 简单 | 复杂 |
| 内存使用 | 较高 | 中等 |
| 并发友好 | **更好** | 一般 |
| 范围查询 | 高效 | 高效 |

> *极小概率，可忽略

### 选择建议

| 场景 | 推荐 |
|------|------|
| 生产环境有序映射 | `TTreeMap` |
| 快速原型/调试 | `TSkipList` |
| 需要并发支持 | `TSkipList` (更易实现并发版) |
| 频繁范围查询 | 两者皆可 |

## 性能特征

| 操作 | 平均 | 最坏 | 空间 |
|------|------|------|------|
| Put | O(log n) | O(n) | O(log n) |
| Get | O(log n) | O(n) | O(1) |
| Remove | O(log n) | O(n) | O(1) |
| Min | O(1) | O(1) | O(1) |
| Range | O(log n + k) | O(n) | O(k) |

## 内存布局

```
跳表节点:
+-------+-------+---------+---------+-----+
| Key   | Value | Forward[0] | Forward[1] | ... |
+-------+-------+---------+---------+-----+

Forward 数组大小由 RandomLevel() 决定
平均每个节点 1/(1-P) 个指针 (P=0.25 时约 1.33)
```

## 注意事项

1. **随机性**
   ```pascal
   // 跳表性能依赖随机数质量
   // 内部调用 Randomize 初始化
   ```

2. **比较函数**
   ```pascal
   // 对于非基本类型，必须提供比较函数
   SL := TSkipList<TMyRecord, Integer>.Create(@MyRecordCompare);
   ```

3. **内存管理**
   ```pascal
   // 手动 Free
   SL := TSkipList<K,V>.Create;
   try
     // 使用
   finally
     SL.Free;
   end;
   ```

## 最佳实践

1. **预估数据量**
   ```pascal
   // 跳表自动调整层数，无需预分配
   // 但大数据量时内存开销较大
   ```

2. **范围查询优先**
   ```pascal
   // 如果主要是精确查找，考虑 HashMap
   // 如果需要范围查询，SkipList 是好选择
   ```

3. **简单优先**
   ```pascal
   // 跳表易于理解和调试
   // 原型阶段可先用 SkipList，后期按需替换
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `TTreeMap<K,V>` | 生产级有序映射 |
| `THashMap<K,V>` | O(1) 无序映射 |
| `TPriorityQueue<T>` | 优先队列 |
