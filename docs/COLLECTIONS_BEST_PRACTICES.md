# Collections 最佳实践指南

**目的**: 帮助开发者避免常见陷阱，编写高效、安全的容器代码  
**更新时间**: 2025-10-28  
**适用版本**: fafafa.core.collections v1.1+

---

## 📋 目录

1. [容器选择原则](#容器选择原则)
2. [性能优化技巧](#性能优化技巧)
3. [常见陷阱](#常见陷阱)
4. [内存管理](#内存管理)
5. [线程安全](#线程安全)
6. [实用模式](#实用模式)

---

## 🎯 容器选择原则

### 原则 1：明确主要操作类型

✅ **好的做法**:
```pascal
// 分析需求：需要频繁查找，偶尔插入
// → 选择 HashMap（查找 O(1)）
var LUserCache := specialize MakeHashMap<Integer, TUserInfo>();
```

❌ **不好的做法**:
```pascal
// 不分析需求，随便选一个
var LUserCache := specialize MakeList<TUserInfo>(); // 查找 O(n)，慢！
```

### 原则 2：先用简单容器，需要时再优化

**默认选择**:
- 键值对 → `HashMap`
- 序列 → `Vec`
- 集合 → `HashSet`

只有在确实需要时才使用特殊容器（TreeMap, LinkedHashMap, BitSet 等）。

### 原则 3：考虑数据量级

```pascal
// 小数据量（< 100）：简单即可
var LSmallMap := specialize MakeHashMap<string, Integer>();

// 大数据量（> 100K）：考虑稳定性
var LLargeMap := specialize MakeTreeMap<string, Integer>(); // 避免哈希冲突
```

---

## ⚡ 性能优化技巧

### 技巧 1：预分配容量

✅ **好的做法** - 预分配避免多次扩容:
```pascal
var LVec := specialize MakeVec<Integer>(10000); // 预留10000个空间
for i := 0 to 9999 do
  LVec.Append(i); // 不会触发扩容，快！
```

❌ **不好的做法** - 频繁扩容:
```pascal
var LVec := specialize MakeVec<Integer>(); // 默认容量很小
for i := 0 to 9999 do
  LVec.Append(i); // 可能触发10+次扩容，慢！
```

**性能差异**: 预分配可提升 **2-3倍** 性能。

### 技巧 2：选择正确的操作位置

✅ **好的做法** - Vec 尾部追加:
```pascal
var LVec := specialize MakeVec<Integer>();
for i := 0 to 9999 do
  LVec.Append(i); // O(1)，快！
```

❌ **不好的做法** - Vec 头部插入:
```pascal
var LVec := specialize MakeVec<Integer>();
for i := 0 to 9999 do
  LVec.Insert(0, i); // O(n)，慢！每次移动所有元素
```

**修正**: 如需频繁头部操作，使用 `VecDeque`:
```pascal
var LDeque := specialize MakeVecDeque<Integer>();
for i := 0 to 9999 do
  LDeque.PushFront(i); // O(1)，快！
```

### 技巧 3：使用批量操作

✅ **好的做法** - 批量追加:
```pascal
var LSource: array[0..999] of Integer;
// ... 填充数据 ...
LVec.AppendFrom(@LSource[0], Length(LSource)); // 一次操作
```

❌ **不好的做法** - 逐个追加:
```pascal
for i := 0 to High(LSource) do
  LVec.Append(LSource[i]); // 1000次函数调用
```

**性能差异**: 批量操作可提升 **5-10倍** 性能。

### 技巧 4：避免不必要的拷贝

✅ **好的做法** - 使用接口引用:
```pascal
procedure ProcessData(const aMap: specialize IHashMap<string, Integer>);
begin
  // 直接使用，不拷贝
end;
```

❌ **不好的做法** - 值传递:
```pascal
procedure ProcessData(aMap: specialize THashMap<string, Integer>);
begin
  // 可能触发拷贝（虽然 Pascal 通常是引用语义）
end;
```

### 技巧 5：选择合适的哈希函数

对于自定义类型作为 HashMap 的键，提供高质量的哈希函数：

```pascal
type
  TPoint = record
    X, Y: Integer;
  end;

// ✅ 好的哈希函数
function HashPoint(const aPoint: TPoint; aData: Pointer): SizeUInt;
begin
  Result := (aPoint.X * 73856093) xor (aPoint.Y * 19349663);
end;

// ❌ 不好的哈希函数
function BadHashPoint(const aPoint: TPoint; aData: Pointer): SizeUInt;
begin
  Result := aPoint.X; // 只用 X，Y 不同的点会冲突！
end;
```

---

## ⚠️ 常见陷阱

### 陷阱 1：HashMap 哈希冲突

**问题**: 糟糕的哈希函数导致性能退化。

❌ **错误示例**:
```pascal
// 所有长度相同的字符串产生相同哈希！
function BadHash(const s: string; aData: Pointer): UInt32;
begin
  Result := Length(s); // 太简单，大量冲突
end;
```

✅ **正确做法**:
```pascal
// 使用库提供的默认哈希函数
var LMap := specialize MakeHashMap<string, Integer>();
// 或者为自定义类型提供良好的哈希函数
```

### 陷阱 2：忘记管理对象生命周期

**问题**: 容器只存储指针/引用，不负责对象释放。

❌ **内存泄漏**:
```pascal
var LMap := specialize MakeHashMap<string, TObject>();
LMap.Add('key', TMyObject.Create); // 创建对象
LMap.Clear; // ❌ 泄漏！对象未释放
```

✅ **正确做法** - 手动释放:
```pascal
// 方案 1：遍历释放
for LPair in LMap do
  LPair.Value.Free;
LMap.Clear;

// 方案 2：使用智能指针/接口
var LMap := specialize MakeHashMap<string, IMyInterface>();
LMap.Clear; // ✅ 自动释放
```

### 陷阱 3：迭代中修改容器

❌ **未定义行为**:
```pascal
for LItem in LVec do
begin
  if SomeCondition(LItem) then
    LVec.Remove(LItem); // ❌ 迭代中删除，危险！
end;
```

✅ **正确做法** - 标记后删除:
```pascal
// 方案 1：反向遍历删除
for i := LVec.GetCount - 1 downto 0 do
  if SomeCondition(LVec[i]) then
    LVec.RemoveAt(i);

// 方案 2：收集待删除项
var LToRemove := specialize MakeVec<T>();
for LItem in LVec do
  if SomeCondition(LItem) then
    LToRemove.Append(LItem);
for LItem in LToRemove do
  LVec.Remove(LItem);
```

### 陷阱 4：使用已失效的迭代器/索引

❌ **悬垂引用**:
```pascal
var LFirst := LVec[0]; // 获取引用
LVec.Insert(0, newItem); // 扩容可能使 LFirst 失效
WriteLn(LFirst); // ❌ 可能访问已释放的内存
```

✅ **正确做法** - 重新获取:
```pascal
LVec.Insert(0, newItem);
var LFirst := LVec[0]; // 重新获取
WriteLn(LFirst);
```

### 陷阱 5：TreeMap/TreeSet 的比较函数不一致

**问题**: 比较函数必须满足严格弱序（strict weak ordering）。

❌ **错误的比较函数**:
```pascal
// ❌ 不满足传递性
function BadCompare(const a, b: Integer; aData: Pointer): SizeInt;
begin
  if Random(2) = 0 then
    Result := -1
  else
    Result := 1; // 随机比较，破坏树结构！
end;
```

✅ **正确的比较函数**:
```pascal
function GoodCompare(const a, b: Integer; aData: Pointer): SizeInt;
begin
  if a < b then Result := -1
  else if a > b then Result := 1
  else Result := 0;
end;
```

**要求**:
1. `Compare(a, a) = 0`（自反性）
2. 如果 `Compare(a, b) < 0` 则 `Compare(b, a) > 0`（反对称性）
3. 如果 `Compare(a, b) < 0` 且 `Compare(b, c) < 0`，则 `Compare(a, c) < 0`（传递性）

---

## 🧠 内存管理

### 原则 1：使用接口而非具体类型

✅ **好的做法**:
```pascal
var LMap: specialize IHashMap<string, Integer>;
LMap := specialize MakeHashMap<string, Integer>();
// ... 使用 ...
// ✅ 自动释放，无需手动 Free
```

❌ **不好的做法**:
```pascal
var LMap: specialize THashMap<string, Integer>;
LMap := specialize THashMap<string, Integer>.Create;
try
  // ... 使用 ...
finally
  LMap.Free; // 需要手动管理
end;
```

### 原则 2：预分配减少内存碎片

```pascal
// ✅ 一次性分配，减少碎片
var LVec := specialize MakeVec<TLargeRecord>(10000);

// ❌ 多次小块分配，产生碎片
var LVec := specialize MakeVec<TLargeRecord>();
for i := 0 to 9999 do
  LVec.Append(...); // 可能多次重新分配
```

### 原则 3：及时释放不需要的容器

```pascal
procedure ProcessData;
var
  LTempMap: specialize IHashMap<string, Integer>;
begin
  LTempMap := specialize MakeHashMap<string, Integer>();
  // ... 临时使用 ...
  LTempMap := nil; // ✅ 显式释放（虽然通常自动）
end;
```

### 原则 4：注意 Clear vs 释放

```pascal
// Clear：清空内容，保留容量
LVec.Clear; // 内存仍占用，可复用

// 释放：彻底释放内存
LVec := nil; // 完全释放
```

**建议**: 如果容器还会复用，用 `Clear`；如果不再使用，置 `nil`。

---

## 🔒 线程安全

### 重要提示

⚠️ **fafafa.core.collections 的所有容器都不是线程安全的！**

### 多线程场景的解决方案

#### 方案 1：外部加锁

```pascal
uses fafafa.core.sync;

var
  LMap: specialize IHashMap<string, Integer>;
  LLock: TCriticalSection;

// 读操作
procedure ReadValue(const aKey: string);
var
  LValue: Integer;
begin
  LLock.Enter;
  try
    if LMap.TryGetValue(aKey, LValue) then
      WriteLn(LValue);
  finally
    LLock.Leave;
  end;
end;

// 写操作
procedure WriteValue(const aKey: string; aValue: Integer);
begin
  LLock.Enter;
  try
    LMap.AddOrAssign(aKey, aValue);
  finally
    LLock.Leave;
  end;
end;
```

#### 方案 2：每线程一个容器

```pascal
// 为每个线程创建独立的容器，避免竞争
type
  TWorkerThread = class(TThread)
  private
    FLocalMap: specialize IHashMap<string, Integer>;
  public
    constructor Create;
    procedure Execute; override;
  end;

constructor TWorkerThread.Create;
begin
  inherited Create(False);
  FLocalMap := specialize MakeHashMap<string, Integer>();
end;
```

#### 方案 3：读写锁（读多写少场景）

```pascal
var
  LMap: specialize IHashMap<string, Integer>;
  LRWLock: TMultiReadExclusiveWriteSynchronizer;

// 读操作（多个线程可同时读）
function ReadValue(const aKey: string): Integer;
begin
  LRWLock.BeginRead;
  try
    LMap.TryGetValue(aKey, Result);
  finally
    LRWLock.EndRead;
  end;
end;

// 写操作（独占）
procedure WriteValue(const aKey: string; aValue: Integer);
begin
  LRWLock.BeginWrite;
  try
    LMap.AddOrAssign(aKey, aValue);
  finally
    LRWLock.EndWrite;
  end;
end;
```

---

## 💡 实用模式

### 模式 1：LRU 缓存（使用 LinkedHashMap）

```pascal
type
  generic TLRUCache<K, V> = class
  private
    FMap: specialize ILinkedHashMap<K, V>;
    FMaxSize: SizeUInt;
    procedure EvictOldest;
  public
    constructor Create(aMaxSize: SizeUInt);
    procedure Put(const aKey: K; const aValue: V);
    function TryGet(const aKey: K; out aValue: V): Boolean;
  end;

constructor TLRUCache.Create(aMaxSize: SizeUInt);
begin
  FMaxSize := aMaxSize;
  FMap := specialize MakeLinkedHashMap<K, V>(aMaxSize);
end;

procedure TLRUCache.EvictOldest;
var
  LFirst: specialize TPair<K, V>;
begin
  if FMap.GetCount >= FMaxSize then
  begin
    LFirst := FMap.First;
    FMap.Remove(LFirst.Key);
  end;
end;

procedure TLRUCache.Put(const aKey: K; const aValue: V);
begin
  if FMap.ContainsKey(aKey) then
    FMap.Remove(aKey); // 更新时先删除（移到尾部）
  
  EvictOldest;
  FMap.Add(aKey, aValue);
end;

function TLRUCache.TryGet(const aKey: K; out aValue: V): Boolean;
begin
  Result := FMap.TryGetValue(aKey, aValue);
end;
```

### 模式 2：多值映射（MultiMap 模拟）

```pascal
// 使用 HashMap<K, Vec<V>> 模拟 MultiMap
type
  TMultiMap<K, V> = specialize THashMap<K, specialize IVec<V>>;

procedure AddValue(aMap: TMultiMap; const aKey: K; const aValue: V);
var
  LVec: specialize IVec<V>;
begin
  if not aMap.TryGetValue(aKey, LVec) then
  begin
    LVec := specialize MakeVec<V>();
    aMap.Add(aKey, LVec);
  end;
  LVec.Append(aValue);
end;
```

### 模式 3：计数器（使用 HashMap）

```pascal
// 统计元素出现次数
procedure CountElements(const aItems: specialize IVec<string>);
var
  LCounts: specialize IHashMap<string, Integer>;
  LItem: string;
  LCount: Integer;
begin
  LCounts := specialize MakeHashMap<string, Integer>();
  
  for LItem in aItems do
  begin
    if LCounts.TryGetValue(LItem, LCount) then
      LCounts.AddOrAssign(LItem, LCount + 1)
    else
      LCounts.Add(LItem, 1);
  end;
  
  // 输出统计结果
  for LPair in LCounts do
    WriteLn(LPair.Key, ': ', LPair.Value);
end;
```

### 模式 4：权限管理（使用 BitSet）

```pascal
const
  PERM_READ    = 0;
  PERM_WRITE   = 1;
  PERM_EXECUTE = 2;
  PERM_DELETE  = 3;
  PERM_ADMIN   = 4;

type
  TPermissionManager = class
  private
    FUserPerms: specialize THashMap<Integer, IBitSet>; // UserID -> Permissions
  public
    procedure GrantPermission(aUserID: Integer; aPerm: SizeUInt);
    procedure RevokePermission(aUserID: Integer; aPerm: SizeUInt);
    function HasPermission(aUserID: Integer; aPerm: SizeUInt): Boolean;
    function HasAllPermissions(aUserID: Integer; const aPerms: array of SizeUInt): Boolean;
  end;

procedure TPermissionManager.GrantPermission(aUserID: Integer; aPerm: SizeUInt);
var
  LPerms: IBitSet;
begin
  if not FUserPerms.TryGetValue(aUserID, LPerms) then
  begin
    LPerms := MakeBitSet();
    FUserPerms.Add(aUserID, LPerms);
  end;
  LPerms.SetBit(aPerm);
end;

function TPermissionManager.HasPermission(aUserID: Integer; aPerm: SizeUInt): Boolean;
var
  LPerms: IBitSet;
begin
  if FUserPerms.TryGetValue(aUserID, LPerms) then
    Result := LPerms.Test(aPerm)
  else
    Result := False;
end;
```

### 模式 5：对象池（使用 Vec）

```pascal
type
  generic TObjectPool<T: class> = class
  private
    FAvailable: specialize IVec<T>;
    FCreateFunc: function: T;
  public
    constructor Create(aCreateFunc: function: T; aInitialSize: SizeUInt);
    function Acquire: T;
    procedure Release(aObject: T);
  end;

constructor TObjectPool.Create(aCreateFunc: function: T; aInitialSize: SizeUInt);
var
  i: SizeUInt;
begin
  FCreateFunc := aCreateFunc;
  FAvailable := specialize MakeVec<T>(aInitialSize);
  for i := 0 to aInitialSize - 1 do
    FAvailable.Append(FCreateFunc());
end;

function TObjectPool.Acquire: T;
begin
  if FAvailable.GetCount > 0 then
  begin
    Result := FAvailable[FAvailable.GetCount - 1];
    FAvailable.RemoveAt(FAvailable.GetCount - 1);
  end
  else
    Result := FCreateFunc(); // 池空，创建新对象
end;

procedure TObjectPool.Release(aObject: T);
begin
  FAvailable.Append(aObject);
end;
```

---

## 📏 性能测量建议

### 使用 Stopwatch 测量

```pascal
uses fafafa.core.time;

var
  LStopwatch: TStopwatch;
  LMap: specialize IHashMap<Integer, Integer>;
  i: Integer;
begin
  LMap := specialize MakeHashMap<Integer, Integer>(100000);
  
  LStopwatch := TStopwatch.StartNew;
  for i := 0 to 99999 do
    LMap.Add(i, i * 2);
  LStopwatch.Stop;
  
  WriteLn(Format('插入100K元素耗时: %d ms', [LStopwatch.ElapsedMilliseconds]));
end;
```

### 对比测试

```pascal
procedure ComparePerformance;
var
  LHashMap: specialize IHashMap<Integer, Integer>;
  LTreeMap: specialize ITreeMap<Integer, Integer>;
  LStopwatch: TStopwatch;
  i: Integer;
begin
  // 测试 HashMap
  LHashMap := specialize MakeHashMap<Integer, Integer>(10000);
  LStopwatch := TStopwatch.StartNew;
  for i := 0 to 9999 do
    LHashMap.Add(i, i);
  LStopwatch.Stop;
  WriteLn('HashMap: ', LStopwatch.ElapsedMilliseconds, ' ms');
  
  // 测试 TreeMap
  LTreeMap := specialize MakeTreeMap<Integer, Integer>();
  LStopwatch := TStopwatch.StartNew;
  for i := 0 to 9999 do
    LTreeMap.Put(i, i);
  LStopwatch.Stop;
  WriteLn('TreeMap: ', LStopwatch.ElapsedMilliseconds, ' ms');
end;
```

---

## ✅ 检查清单

在使用容器前，检查：

- [ ] 选择的容器类型是否适合主要操作？
- [ ] 是否预分配了合适的容量？
- [ ] 如果存储对象，是否考虑了生命周期管理？
- [ ] 多线程场景是否添加了同步保护？
- [ ] 是否避免了迭代中修改容器？
- [ ] 自定义类型是否提供了正确的哈希/比较函数？

---

## 📚 更多资源

- **容器选择**: [COLLECTIONS_DECISION_TREE.md](COLLECTIONS_DECISION_TREE.md)
- **API 参考**: [COLLECTIONS_API_REFERENCE.md](COLLECTIONS_API_REFERENCE.md)
- **性能分析**: [COLLECTIONS_PERFORMANCE_ANALYSIS.md](COLLECTIONS_PERFORMANCE_ANALYSIS.md)（待创建）
- **示例代码**: `examples/collections/`

---

**维护者**: fafafa.core Team  
**最后更新**: 2025-10-28  
**版本**: v1.1

