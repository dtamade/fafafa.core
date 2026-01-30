# THashMap / THashSet 使用指南

## 概述

`THashMap<K,V>` 是基于开放寻址法的哈希映射实现，提供 O(1) 平均时间复杂度的键值存取。
`THashSet<K>` 是 `THashMap<K, Byte>` 的轻量包装，用于快速成员资格测试。

## 快速开始

### 基本使用

```pascal
uses
  fafafa.core.collections.hashmap;

var
  Map: specialize THashMap<String, Integer>;
begin
  Map := specialize THashMap<String, Integer>.Create;
  try
    // 添加键值对
    Map.Put('apple', 1);
    Map.Put('banana', 2);
    
    // 查询
    if Map.ContainsKey('apple') then
      WriteLn('Found apple');
    
    // 获取值
    var Value: Integer;
    if Map.TryGetValue('apple', Value) then
      WriteLn('apple = ', Value);
    
    // 删除
    Map.Remove('banana');
  finally
    Map.Free;
  end;
end;
```

### HashSet 示例

```pascal
var
  Visited: specialize THashSet<Integer>;
begin
  Visited := specialize THashSet<Integer>.Create;
  try
    Visited.Add(1);
    Visited.Add(2);
    Visited.Add(1);  // 重复，返回 False
    
    WriteLn('Count: ', Visited.Count);  // 输出: 2
    
    if Visited.Contains(1) then
      WriteLn('1 is visited');
  finally
    Visited.Free;
  end;
end;
```

## Entry API（Rust 风格）

THashMap 提供类似 Rust Entry API 的操作模式：

### GetOrInsert - 获取或插入默认值

```pascal
// 计数器模式：键不存在时初始化为 0
var Count: Integer;
Count := Map.GetOrInsert('visits', 0);
```

### GetOrInsertWith - 惰性初始化

```pascal
function CreateDefaultConfig: TConfig;
begin
  Result := TConfig.Create;
  Result.LoadDefaults;
end;

// 只有键不存在时才调用 CreateDefaultConfig
Config := Map.GetOrInsertWith('settings', @CreateDefaultConfig);
```

### ModifyOrInsert - 修改或插入

```pascal
procedure IncrementValue(var V: Integer);
begin
  Inc(V);
end;

// 键存在：调用 IncrementValue
// 键不存在：插入初始值 1
Map.ModifyOrInsert('counter', @IncrementValue, 1);
```

### Retain - 条件保留

```pascal
function KeepPositive(const Entry: TEntry; Data: Pointer): Boolean;
begin
  Result := Entry.Value > 0;
end;

// 只保留值大于 0 的键值对
Map.Retain(@KeepPositive, nil);
```

## 性能特性

### 复杂度对比

| 操作 | THashMap | TTreeMap |
|------|----------|----------|
| Put/Get | O(1) 平均 | O(log n) |
| Remove | O(1) 平均 | O(log n) |
| ContainsKey | O(1) 平均 | O(log n) |
| 遍历 | O(n) 无序 | O(n) 有序 |
| 范围查询 | 不支持 | O(log n + k) |

### 何时选择 THashMap

- ✅ 只需要键值存取，不需要有序遍历
- ✅ 性能敏感，需要 O(1) 操作
- ✅ 键类型有高效哈希函数

### 何时选择 TTreeMap

- ✅ 需要有序遍历
- ✅ 需要范围查询（Ceiling/Floor/GetRange）
- ✅ 键类型只能比较，不能哈希

## 自定义哈希函数

### 内置支持的类型

- Integer, Int64, UInt32, UInt64
- String (AnsiString, UnicodeString)
- Pointer
- 枚举类型

### 自定义 Record 类型

```pascal
type
  TPoint = record
    X, Y: Integer;
  end;

function HashPoint(const P: TPoint): UInt32;
begin
  Result := HashMix32(UInt32(P.X) xor (UInt32(P.Y) * $9E3779B1));
end;

function PointEquals(const A, B: TPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

var
  Map: specialize THashMap<TPoint, String>;
begin
  Map := specialize THashMap<TPoint, String>.Create(0, @HashPoint, @PointEquals);
  // ...
end;
```

## 容量管理

### 预分配

```pascal
// 已知将插入约 10000 个元素
Map := specialize THashMap<Integer, String>.Create(10000);
// 或
Map.Reserve(10000);
```

### 负载因子

- 默认阈值：0.86
- 当 `LoadFactor > 0.86` 时自动扩容（rehash）
- 容量始终为 2 的幂次

```pascal
WriteLn('Count: ', Map.Count);
WriteLn('Capacity: ', Map.Capacity);
WriteLn('LoadFactor: ', Map.LoadFactor:0:2);
```

## 迭代

### for-in 迭代

```pascal
var
  Entry: specialize TMapEntry<String, Integer>;
begin
  for Entry in Map do
    WriteLn(Entry.Key, ' = ', Entry.Value);
end;
```

### 获取所有键

```pascal
var
  Keys: array of String;
  Key: String;
begin
  Keys := Map.GetKeys;
  for Key in Keys do
    WriteLn(Key);
end;
```

## 线程安全

⚠️ **THashMap 和 THashSet 不是线程安全的**

对于并发场景，请使用：
- `TMichaelHashMap`（来自 `fafafa.core.lockfree.hashmap`）
- 或自行添加锁保护

## 内存管理

### 值类型为引用类型时

```pascal
type
  TMyMap = specialize THashMap<String, TObject>;

// 注意：THashMap 不会自动释放 Value 对象
// 需要手动遍历释放
procedure FreeMapValues(Map: TMyMap);
var
  Entry: specialize TMapEntry<String, TObject>;
begin
  for Entry in Map do
    Entry.Value.Free;
  Map.Clear;
end;
```

### 删除语义

- `Remove` 使用墓碑标记（Tombstone），不立即回收空间
- 大量删除后，可能需要创建新 Map 并迁移数据以回收空间

## 常见问题

### Q: 为什么 ContainsKey 后 TryGetValue 还要再查一次？

建议直接使用 `TryGetValue`，它一次操作完成查找和获取：

```pascal
// 不好：两次查找
if Map.ContainsKey('key') then
  Value := Map.GetOrInsert('key', 0);

// 好：一次查找
if Map.TryGetValue('key', Value) then
  // 使用 Value
```

### Q: 哈希冲突严重怎么办？

1. 检查哈希函数质量
2. 使用内置的 `HashMix32` 混洗哈希值
3. 考虑使用自定义哈希函数

### Q: 如何实现大小写不敏感的 String 键？

```pascal
function HashStringIgnoreCase(const S: String): UInt32;
begin
  Result := HashOfAnsiString(LowerCase(S));
end;

function StringEqualsIgnoreCase(const A, B: String): Boolean;
begin
  Result := SameText(A, B);
end;

Map := specialize THashMap<String, Integer>.Create(0, 
  @HashStringIgnoreCase, @StringEqualsIgnoreCase);
```

## 参见

- [TTreeMap](TTreeMap.md) - 有序映射
- [fafafa.core.lockfree.hashmap](../lockfree/hashmap.md) - 无锁并发哈希映射
- [INDEX](INDEX.md) - 容器模块索引
