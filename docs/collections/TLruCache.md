# TLruCache - LRU 缓存使用指南

## 概述

`ILruCache<K,V>` 是**最近最少使用 (Least Recently Used)** 缓存实现。

| 特性 | 描述 |
|------|------|
| 结构 | 哈希表 + 双向链表 |
| 查找/插入/更新 | O(1) |
| 淘汰策略 | 自动淘汰最少使用的元素 |
| 统计 | 内置 Hit/Miss 计数 |

> **适用场景**：数据库查询缓存、文件缓存、计算结果缓存等需要固定容量且自动淘汰的场景。

## 快速开始

```pascal
uses
  fafafa.core.collections.lrucache;

var
  Cache: specialize ILruCache<String, Integer>;
begin
  Cache := specialize MakeLruCache<String, Integer>(3);  // 容量 3
  
  // 插入
  Cache.Put('a', 1);
  Cache.Put('b', 2);
  Cache.Put('c', 3);
  
  // 访问（将 'a' 移到 MRU 位置）
  var Value: Integer;
  if Cache.Get('a', Value) then
    WriteLn('a = ', Value);
  
  // 插入新元素，'b' 是 LRU，被淘汰
  Cache.Put('d', 4);
  
  // 'b' 已被淘汰
  if not Cache.Get('b', Value) then
    WriteLn('b not found');
end;
```

## API 参考

### 创建

```pascal
// 指定最大容量
Cache := specialize MakeLruCache<String, Integer>(100);

// 自定义分配器
Cache := specialize MakeLruCache<String, Integer>(100, MyAllocator);
```

### 核心操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Get(key, out value): Boolean` | 获取值（更新访问顺序） | O(1) |
| `Put(key, value)` | 插入/更新（可能触发淘汰） | O(1) |
| `Peek(key, out value): Boolean` | 获取值（不更新顺序） | O(1) |
| `Remove(key): Boolean` | 移除键 | O(1) |
| `Contains(key): Boolean` | 检查键是否存在 | O(1) |

### 淘汰控制

| 方法 | 描述 |
|------|------|
| `Evict: Boolean` | 手动淘汰一个 LRU 元素 |
| `EvictLeastRecent(n): SizeUInt` | 淘汰 n 个元素 |
| `Clear` | 清空所有元素 |

### 容量管理

| 方法 | 描述 |
|------|------|
| `GetMaxSize: SizeUInt` | 获取最大容量 |
| `SetMaxSize(n)` | 设置最大容量（可能触发淘汰） |
| `GetSize: SizeUInt` | 获取当前元素数量 |

### 统计信息

| 方法 | 描述 |
|------|------|
| `GetHitCount: UInt64` | 命中次数 |
| `GetMissCount: UInt64` | 未命中次数 |
| `GetHitRate: Double` | 命中率 (0.0-1.0) |

## 使用模式

### 模式 1：基本缓存

```pascal
function GetUser(Id: Integer): TUser;
var
  User: TUser;
begin
  // 先查缓存
  if UserCache.Get(Id, User) then
    Exit(User);
  
  // 缓存未命中，从数据库加载
  User := Database.LoadUser(Id);
  UserCache.Put(Id, User);
  Result := User;
end;
```

### 模式 2：带统计的缓存

```pascal
procedure ReportCacheStats;
begin
  WriteLn('Size: ', Cache.GetSize, '/', Cache.GetMaxSize);
  WriteLn('Hits: ', Cache.GetHitCount);
  WriteLn('Misses: ', Cache.GetMissCount);
  WriteLn('Hit Rate: ', Cache.GetHitRate * 100:0:2, '%');
end;
```

### 模式 3：只读查询（不影响顺序）

```pascal
// Peek 不更新 LRU 顺序，适合只读检查
if Cache.Peek(Key, Value) then
  // 键存在，但不会影响淘汰顺序
```

### 模式 4：预热缓存

```pascal
procedure WarmUpCache;
var
  HotKeys: TArray<String>;
begin
  HotKeys := GetMostUsedKeys;
  for var Key in HotKeys do
  begin
    var Value := LoadFromDatabase(Key);
    Cache.Put(Key, Value);
  end;
end;
```

## 典型应用

### 数据库查询缓存

```pascal
type
  TQueryCache = specialize ILruCache<String, TDataSet>;

function ExecuteQuery(const SQL: String): TDataSet;
begin
  if not QueryCache.Get(SQL, Result) then
  begin
    Result := Database.Execute(SQL);
    QueryCache.Put(SQL, Result);
  end;
end;
```

### 文件内容缓存

```pascal
type
  TFileCache = specialize ILruCache<String, TBytes>;

function ReadFile(const Path: String): TBytes;
begin
  if not FileCache.Get(Path, Result) then
  begin
    Result := TFile.ReadAllBytes(Path);
    FileCache.Put(Path, Result);
  end;
end;
```

### 计算结果缓存（Memoization）

```pascal
type
  TFibCache = specialize ILruCache<Integer, Int64>;

function Fibonacci(N: Integer): Int64;
var
  Result: Int64;
begin
  if N <= 1 then Exit(N);
  
  if FibCache.Get(N, Result) then
    Exit(Result);
  
  Result := Fibonacci(N - 1) + Fibonacci(N - 2);
  FibCache.Put(N, Result);
  Exit(Result);
end;
```

### Web 会话缓存

```pascal
type
  TSessionCache = specialize ILruCache<String, TSession>;

function GetSession(const SessionId: String): TSession;
begin
  if not SessionCache.Get(SessionId, Result) then
  begin
    Result := TSession.Create;
    SessionCache.Put(SessionId, Result);
  end;
end;
```

## LRU 淘汰原理

```
初始状态 (容量=3):

  MRU                      LRU
   │                        │
   ▼                        ▼
  [C] ←→ [B] ←→ [A]

访问 A 后:

  [A] ←→ [C] ←→ [B]
   ▲                 ▲
  MRU               LRU

插入 D (容量满，淘汰 B):

  [D] ←→ [A] ←→ [C]
   ▲                 ▲
  MRU               LRU
```

## Get vs Peek

| 方法 | 更新顺序 | 计入统计 | 适用场景 |
|------|----------|----------|----------|
| `Get` | ✅ | ✅ | 正常访问 |
| `Peek` | ❌ | ❌ | 只读检查 |

```pascal
// Get: 更新顺序，计入命中统计
if Cache.Get(Key, Value) then ...

// Peek: 不更新顺序，不影响淘汰
if Cache.Peek(Key, Value) then ...
```

## 容量调整

```pascal
// 增加容量
Cache.SetMaxSize(200);

// 减少容量（会触发淘汰）
Cache.SetMaxSize(50);  // 如果当前有 100 个，会淘汰 50 个 LRU 元素
```

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| Get | O(1) | O(1) |
| Put | O(1) 摊销 | O(1) |
| Peek | O(1) | O(1) |
| Remove | O(1) | O(1) |
| Evict | O(1) | O(1) |
| Clear | O(n) | O(1) |

## LRU vs 其他缓存策略

| 策略 | 特点 | 适用场景 |
|------|------|----------|
| LRU | 淘汰最少使用 | 通用，时间局部性好 |
| LFU | 淘汰最少频次 | 热点数据明显 |
| FIFO | 先进先出 | 简单场景 |
| Random | 随机淘汰 | 访问模式不确定 |

## 注意事项

1. **引用类型的生命周期**
   ```pascal
   // ⚠️ 如果 V 是对象类型，淘汰时不会自动释放
   // 需要自行管理或使用智能指针
   ```

2. **线程安全**
   ```pascal
   // ❌ TLruCache 不是线程安全的
   // 并发访问需要外部同步
   Lock.Enter;
   try
     Cache.Get(Key, Value);
   finally
     Lock.Leave;
   end;
   ```

3. **容量为 0 的缓存**
   ```pascal
   // 容量为 0 时，Put 会立即淘汰，相当于禁用缓存
   Cache.SetMaxSize(0);
   ```

## 最佳实践

1. **合理设置容量**
   ```pascal
   // 根据内存和访问模式设置
   // 太小：命中率低
   // 太大：内存浪费
   ```

2. **监控命中率**
   ```pascal
   if Cache.GetHitRate < 0.5 then
     // 考虑增加容量或检查访问模式
   ```

3. **使用 Peek 进行检查**
   ```pascal
   // 如果只需要检查存在性，使用 Contains 或 Peek
   if Cache.Contains(Key) then ...
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `THashMap<K,V>` | 无容量限制的映射 |
| `TLinkedHashMap<K,V>` | 保持插入顺序的映射 |
| `TTreeMap<K,V>` | 有序映射 |
