# TMultiMap - 一对多映射使用指南

## 概述

`TMultiMap<K, V>` 是允许一个键对应**多个值**的映射容器。

| 特性 | 描述 |
|------|------|
| 底层实现 | HashMap<K, TVec<V>> |
| 键值关系 | 一对多 |
| 添加 | O(1) 摊销 |
| 移除特定值 | O(n)，n = 该键的值数量 |

> **适用场景**：标签系统、事件订阅、HTTP 头处理、数据分组。

## 快速开始

```pascal
uses
  fafafa.core.collections.multimap;

var
  Tags: specialize TMultiMap<Integer, string>;  // 文章ID -> 标签们
begin
  Tags := specialize TMultiMap<Integer, string>.Create;
  try
    // 一个键添加多个值
    Tags.Add(1, 'Pascal');
    Tags.Add(1, 'Tutorial');
    Tags.Add(1, 'Beginner');
    
    Tags.Add(2, 'Pascal');
    Tags.Add(2, 'Advanced');
    
    // 获取文章1的所有标签
    var ArticleTags := Tags.GetValues(1);
    // ['Pascal', 'Tutorial', 'Beginner']
    
    // 统计
    WriteLn('文章数: ', Tags.KeyCount);     // 2
    WriteLn('总标签数: ', Tags.TotalCount); // 5
  finally
    Tags.Free;
  end;
end;
```

## API 参考

### 创建与销毁

```pascal
MultiMap := specialize TMultiMap<K, V>.Create;
MultiMap.Free;
```

### 添加

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Add(key, value)` | 添加键值对（允许重复值） | O(1) 摊销 |

```pascal
// 同一键可以添加多个相同或不同的值
MultiMap.Add('event', Handler1);
MultiMap.Add('event', Handler2);
MultiMap.Add('event', Handler1);  // 允许重复
```

### 移除

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Remove(key, value): Boolean` | 移除第一个匹配的键值对 | O(n) |
| `RemoveAll(key): SizeUInt` | 移除键的所有值 | O(n) |

```pascal
// 移除特定值
if MultiMap.Remove('tags', 'old') then
  WriteLn('Removed one occurrence');

// 移除键的所有值
var RemovedCount := MultiMap.RemoveAll('expired');
```

### 查询

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Contains(key): Boolean` | 键是否存在 | O(1) |
| `ContainsValue(key, value): Boolean` | 特定键值对是否存在 | O(n) |
| `GetValues(key): TValueArray` | 获取键的所有值 | O(n) |
| `TryGetValues(key, out values): Boolean` | 安全获取值 | O(n) |
| `GetValueCount(key): SizeUInt` | 键的值数量 | O(1) |
| `GetKeys: TKeyArray` | 获取所有键 | O(k) |

### 状态

| 方法 | 描述 |
|------|------|
| `IsEmpty: Boolean` | 是否为空 |
| `KeyCount: SizeUInt` | 键的数量 |
| `TotalCount: SizeUInt` | 所有值的总数 |
| `Clear` | 清空 |

## 使用模式

### 模式 1：事件订阅系统

```pascal
type
  TEventHandler = procedure(Sender: TObject) of object;
  TEventMultiMap = specialize TMultiMap<string, TEventHandler>;

var
  EventBus: TEventMultiMap;

procedure Subscribe(const EventName: string; Handler: TEventHandler);
begin
  EventBus.Add(EventName, Handler);
end;

procedure Unsubscribe(const EventName: string; Handler: TEventHandler);
begin
  EventBus.Remove(EventName, Handler);
end;

procedure FireEvent(const EventName: string; Sender: TObject);
var
  Handlers: TEventMultiMap.TValueArray;
begin
  Handlers := EventBus.GetValues(EventName);
  for var Handler in Handlers do
    Handler(Sender);
end;
```

### 模式 2：标签系统

```pascal
type
  TTagSystem = specialize TMultiMap<Integer, string>;  // 对象ID -> 标签

var
  Tags: TTagSystem;

procedure AddTag(ObjectID: Integer; const Tag: string);
begin
  if not Tags.ContainsValue(ObjectID, Tag) then  // 防止重复
    Tags.Add(ObjectID, Tag);
end;

function GetObjectsWithTag(const Tag: string): TIntegerArray;
var
  Keys: TTagSystem.TKeyArray;
begin
  SetLength(Result, 0);
  Keys := Tags.GetKeys;
  
  for var Key in Keys do
  begin
    if Tags.ContainsValue(Key, Tag) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Key;
    end;
  end;
end;
```

### 模式 3：HTTP 头处理

```pascal
type
  THttpHeaders = specialize TMultiMap<string, string>;

var
  Headers: THttpHeaders;

// 解析多值头
procedure ParseHeaders(const RawHeaders: string);
begin
  // Set-Cookie 可以有多个
  Headers.Add('Set-Cookie', 'session=abc123');
  Headers.Add('Set-Cookie', 'tracking=xyz789');
  
  // 单值头
  Headers.Add('Content-Type', 'application/json');
end;

// 获取所有 Cookie
var Cookies := Headers.GetValues('Set-Cookie');
// ['session=abc123', 'tracking=xyz789']
```

### 模式 4：数据分组

```pascal
type
  TStudent = record
    Name: string;
    Grade: Integer;
  end;
  TGradeGroup = specialize TMultiMap<Integer, TStudent>;

procedure GroupByGrade(Students: array of TStudent; Groups: TGradeGroup);
begin
  for var S in Students do
    Groups.Add(S.Grade, S);
end;

// 获取某年级所有学生
var Grade10Students := Groups.GetValues(10);
```

## 典型应用

### 依赖注入容器

```pascal
type
  TServiceKey = string;
  TServiceFactory = function: TObject;
  TDIContainer = specialize TMultiMap<TServiceKey, TServiceFactory>;

var
  Container: TDIContainer;

// 注册多个实现
Container.Add('ILogger', @CreateFileLogger);
Container.Add('ILogger', @CreateConsoleLogger);
Container.Add('ILogger', @CreateNetworkLogger);

// 获取所有实现
function GetAllServices(const Key: TServiceKey): TObjectArray;
var
  Factories: TDIContainer.TValueArray;
begin
  Factories := Container.GetValues(Key);
  SetLength(Result, Length(Factories));
  
  for var i := 0 to High(Factories) do
    Result[i] := Factories[i]();
end;
```

### 索引系统

```pascal
type
  TWordIndex = specialize TMultiMap<string, Integer>;  // 单词 -> 文档ID列表

var
  Index: TWordIndex;

procedure IndexDocument(DocID: Integer; const Content: string);
var
  Words: TStringArray;
begin
  Words := SplitWords(LowerCase(Content));
  
  for var Word in Words do
  begin
    if not Index.ContainsValue(Word, DocID) then
      Index.Add(Word, DocID);
  end;
end;

function Search(const Word: string): TIntegerArray;
begin
  Result := Index.GetValues(LowerCase(Word));
end;
```

## MultiMap vs 其他方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| `TMultiMap<K,V>` | 语义清晰，API 简洁 | 依赖库 |
| `THashMap<K, TList<V>>` | 标准结构 | 需手动管理内部列表 |
| `THashMap<K, TArray<V>>` | 无需释放内部列表 | 数组操作麻烦 |

### 选择建议

| 场景 | 推荐 |
|------|------|
| 一对多关系 | `TMultiMap` |
| 一对一关系 | `THashMap` |
| 需要有序值 | 自定义 `THashMap<K, TSortedList<V>>` |

## 性能特征

| 操作 | 时间复杂度 | 说明 |
|------|-----------|------|
| Add | O(1) 摊销 | HashMap + Vec push |
| Remove(key, value) | O(n) | 需线性查找值 |
| RemoveAll(key) | O(n) | 释放内部 Vec |
| Contains(key) | O(1) | HashMap 查找 |
| ContainsValue | O(n) | 线性查找 |
| GetValues | O(n) | 复制值数组 |
| GetValueCount | O(1) | 直接返回 Vec.Count |
| KeyCount | O(1) | HashMap.Count |
| TotalCount | O(1) | 维护的计数器 |

> n = 该键对应的值数量

## 内存结构

```
TMultiMap
├── FMap: THashMap<K, TVec<V>>
│   ├── Key1 → TVec [V1, V2, V3]
│   ├── Key2 → TVec [V4]
│   └── Key3 → TVec [V5, V6]
└── FTotalValueCount: 6
```

## 注意事项

1. **允许重复值**
   ```pascal
   // Add 不检查重复
   MultiMap.Add('k', 'v');
   MultiMap.Add('k', 'v');  // 现在有两个相同的值
   
   // 如需防止重复，先检查
   if not MultiMap.ContainsValue('k', 'v') then
     MultiMap.Add('k', 'v');
   ```

2. **Remove 只移除第一个**
   ```pascal
   // 如果有多个相同值，Remove 只移除第一个
   MultiMap.Add('k', 'v');
   MultiMap.Add('k', 'v');
   MultiMap.Remove('k', 'v');  // 还剩一个 'v'
   ```

3. **GetValues 返回副本**
   ```pascal
   // 修改返回的数组不影响原数据
   var Values := MultiMap.GetValues('k');
   SetLength(Values, 0);  // MultiMap 不受影响
   ```

4. **空键自动清理**
   ```pascal
   // 当键的最后一个值被移除时，键也会被移除
   MultiMap.Add('k', 'v');
   MultiMap.Remove('k', 'v');
   MultiMap.Contains('k');  // False
   ```

## 最佳实践

1. **明确是否允许重复**
   ```pascal
   // 如果值不应重复，封装添加逻辑
   procedure AddUnique(const Key: K; const Value: V);
   begin
     if not MultiMap.ContainsValue(Key, Value) then
       MultiMap.Add(Key, Value);
   end;
   ```

2. **批量操作时先检查键**
   ```pascal
   // 减少重复的 HashMap 查找
   if MultiMap.Contains(Key) then
   begin
     var Values := MultiMap.GetValues(Key);
     // 处理所有值...
   end;
   ```

3. **用 TryGetValues 处理可能不存在的键**
   ```pascal
   var Values: TValueArray;
   if MultiMap.TryGetValues(Key, Values) then
     ProcessValues(Values)
   else
     HandleMissing;
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `THashMap<K, V>` | 一对一映射 |
| `TLinkedHashMap<K, V>` | 保持插入顺序的一对一映射 |
| `TTreeMap<K, V>` | 有序一对一映射 |
