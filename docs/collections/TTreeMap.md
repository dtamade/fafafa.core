# TTreeMap<K, V> 使用指南

## 概述

`TTreeMap<K, V>` 是基于红黑树实现的有序键值对映射容器。

**核心特性**：
- 键按升序自动排列
- O(log n) 插入、删除、查找
- 支持范围查询（Ceiling/Floor/GetRange）
- 支持 Rust 风格的 Entry API

**适用场景**：
- 需要有序遍历
- 需要范围查询（如查找某区间内的所有键）
- 需要 Floor/Ceiling 操作（如日程安排、区间查找）

**不适用场景**：
- 仅需要快速查找（使用 THashMap）
- 内存受限环境（红黑树节点开销较大）

## 快速开始

### 基本用法

```pascal
uses
  fafafa.core.collections, fafafa.core.collections.treemap;

var
  tree: specialize TTreeMap<Integer, String>;
  value: String;
begin
  // 创建（使用默认比较器）
  tree := specialize TTreeMap<Integer, String>.Create(nil, @compare_i32);
  try
    // 插入
    tree.Put(3, 'three');
    tree.Put(1, 'one');
    tree.Put(2, 'two');

    // 查询
    if tree.Get(2, value) then
      WriteLn('Found: ', value);  // 输出: Found: two

    // 检查存在性
    if tree.ContainsKey(1) then
      WriteLn('Key 1 exists');

    // 删除
    tree.Remove(2);

    // 遍历（按键升序: 1, 3）
    for entry in tree do
      WriteLn(entry.Key, ' -> ', entry.Value);

  finally
    tree.Free;
  end;
end;
```

### 自定义比较器

```pascal
// 降序比较器
function ReverseCompare(const a, b: Integer; data: Pointer): SizeInt;
begin
  Result := b - a;  // 注意顺序反转
end;

var
  tree: specialize TTreeMap<Integer, String>;
begin
  tree := specialize TTreeMap<Integer, String>.Create(nil, @ReverseCompare);
  // 现在键按降序排列
end;
```

### 字符串键

```pascal
var
  tree: specialize TTreeMap<String, Integer>;
begin
  tree := specialize TTreeMap<String, Integer>.Create(nil, @compare_string);
  tree.Put('apple', 1);
  tree.Put('banana', 2);
  // 键按字母顺序排列: apple, banana
end;
```

## 范围查询

### Ceiling - 天花板（≥ key 的最小键）

```pascal
var
  value: String;
begin
  // 树中有键: 1, 5, 10, 15
  tree.Ceiling(7, value);   // 返回 True, 键 10 对应的值
  tree.Ceiling(5, value);   // 返回 True, 键 5 对应的值
  tree.Ceiling(20, value);  // 返回 False
end;
```

### Floor - 地板（≤ key 的最大键）

```pascal
var
  value: String;
begin
  // 树中有键: 1, 5, 10, 15
  tree.Floor(7, value);   // 返回 True, 键 5 对应的值
  tree.Floor(0, value);   // 返回 False
end;
```

### GetRange - 范围遍历

```pascal
procedure ProcessEntry(const entry: specialize TMapEntry<Integer, String>; data: Pointer);
begin
  WriteLn(entry.Key, ' -> ', entry.Value);
end;

begin
  // 遍历键在 [10, 20] 范围内的所有元素
  tree.GetRange(10, 20, @ProcessEntry);
end;
```

## Entry API (Rust 风格)

### GetOrInsert - 获取或插入默认值

```pascal
var
  count: Integer;
begin
  // 如果键不存在，插入默认值 0
  count := tree.GetOrInsert('apple', 0);
  // 下次获取返回已有值
  count := tree.GetOrInsert('apple', 0);  // 返回之前的值
end;
```

### GetOrInsertWith - 惰性计算默认值

```pascal
function CreateExpensiveObject: TMyObject;
begin
  Result := TMyObject.Create;  // 只在需要时才调用
end;

begin
  // 只有键不存在时才调用 CreateExpensiveObject
  obj := tree.GetOrInsertWith('key', @CreateExpensiveObject);
end;
```

### ModifyOrInsert - 修改或插入

```pascal
procedure IncValue(var value: Integer);
begin
  Inc(value);
end;

begin
  // 统计单词频率
  tree.ModifyOrInsert('hello', @IncValue, 1);  // 第一次: 插入 1
  tree.ModifyOrInsert('hello', @IncValue, 1);  // 第二次: 变成 2
  tree.ModifyOrInsert('hello', @IncValue, 1);  // 第三次: 变成 3
end;
```

## 性能特性

| 操作 | 时间复杂度 | 说明 |
|------|-----------|------|
| Get/Put/Remove | O(log n) | 红黑树保证 |
| ContainsKey | O(log n) | |
| Ceiling/Floor | O(log n) | |
| GetRange | O(log n + k) | k = 范围内元素数 |
| GetKeys/GetValues | O(n) | 需要遍历整棵树 |
| Clear | O(n) | 递归释放节点 |
| GetCount | O(1) | 维护计数器 |

## 与 THashMap 对比

| 特性 | TTreeMap | THashMap |
|------|----------|----------|
| 查找 | O(log n) | O(1) 均摊 |
| 有序遍历 | ✅ 支持 | ❌ 不支持 |
| 范围查询 | ✅ 支持 | ❌ 不支持 |
| 内存开销 | 较高（节点指针） | 较低 |
| 适用场景 | 需要有序/范围 | 纯查找 |

**选择建议**：
- 需要有序遍历或范围查询 → TTreeMap
- 只需要快速查找 → THashMap
- 不确定时 → 从 THashMap 开始，需要有序时改用 TTreeMap

## 线程安全

TTreeMap **不是线程安全的**。并发访问需要外部同步：

```pascal
var
  lock: TCriticalSection;
  tree: specialize TTreeMap<Integer, String>;
begin
  lock := TCriticalSection.Create;
  try
    lock.Enter;
    try
      tree.Put(1, 'value');
    finally
      lock.Leave;
    end;
  finally
    lock.Free;
  end;
end;
```

## 常见问题

### Q: 比较器为 nil 会怎样？

会抛出 `EArgumentNil` 异常。对于基本类型，使用 `fafafa.core.collections.base` 中的内置比较器：
- `compare_i32` - 32位整数
- `compare_i64` - 64位整数
- `compare_string` - 字符串

### Q: 如何反向遍历？

TreeMap 不支持反向遍历。如需反向，可以：
1. 使用降序比较器创建
2. 将键收集到数组后反向遍历

### Q: GetKeys/GetValues 返回的集合谁负责释放？

调用者负责：

```pascal
var
  keys: TCollection;
begin
  keys := tree.GetKeys;
  try
    // 使用 keys
  finally
    keys.Free;  // 调用者释放
  end;
end;
```

## 参见

- [ITreeMap 接口文档](../../src/fafafa.core.collections.treemap.pas)
- [THashMap 使用指南](./THashMap.md)
- [容器选择指南](./INDEX.md)
