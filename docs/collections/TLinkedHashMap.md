# TLinkedHashMap - 有序哈希映射使用指南

## 概述

`ILinkedHashMap<K,V>` 是**保持插入顺序**的哈希映射。

| 特性 | 描述 |
|------|------|
| 结构 | HashMap + 双向链表 |
| 查找/插入/删除 | O(1) |
| 迭代顺序 | **按插入顺序** |

> **适用场景**：需要 O(1) 查找，同时保持元素顺序的场景，如配置解析、JSON 对象、历史记录等。

## 快速开始

```pascal
uses
  fafafa.core.collections.linkedhashmap;

var
  Map: specialize TLinkedHashMap<String, Integer>;
begin
  Map := specialize TLinkedHashMap<String, Integer>.Create;
  try
    // 插入（保持顺序）
    Map.Put('c', 3);
    Map.Put('a', 1);
    Map.Put('b', 2);
    
    // 迭代按插入顺序: c, a, b
    var Pair := Map.First;
    WriteLn(Pair.Key);  // 输出: c
    
    Pair := Map.Last;
    WriteLn(Pair.Key);  // 输出: b
  finally
    Map.Free;
  end;
end;
```

## API 参考

### 创建

```pascal
// 默认创建
Map := specialize TLinkedHashMap<String, Integer>.Create;

// 指定初始容量
Map := specialize TLinkedHashMap<String, Integer>.Create(100);

// 自定义分配器
Map := specialize TLinkedHashMap<String, Integer>.Create(100, MyAllocator);
```

### 核心操作（继承 IHashMap）

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Put(key, value): Boolean` | 插入/更新 | O(1) |
| `Get(key, out value): Boolean` | 获取值 | O(1) |
| `TryGetValue(key, out value): Boolean` | 同 Get | O(1) |
| `ContainsKey(key): Boolean` | 检查键 | O(1) |
| `Remove(key): Boolean` | 删除 | O(1) |
| `Add(key, value): Boolean` | 仅插入（不覆盖） | O(1) |
| `AddOrAssign(key, value): Boolean` | 同 Put | O(1) |

### 顺序访问（LinkedHashMap 特有）

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `First: TPair<K,V>` | 第一个插入的键值对 | O(1) |
| `Last: TPair<K,V>` | 最后一个插入的键值对 | O(1) |
| `TryGetFirst(out pair): Boolean` | 安全获取第一个 | O(1) |
| `TryGetLast(out pair): Boolean` | 安全获取最后一个 | O(1) |
| `GetAllKeys: TKeysArray` | 按顺序获取所有键 | O(n) |

### Entry API（Rust 风格）

| 方法 | 描述 |
|------|------|
| `GetOrInsert(key, default): V` | 获取或插入默认值 |
| `GetOrInsertWith(key, supplier): V` | 获取或用函数生成 |
| `ModifyOrInsert(key, modifier, default)` | 修改或插入 |

### 容量管理

| 方法 | 描述 |
|------|------|
| `GetCapacity: SizeUInt` | 当前容量 |
| `GetLoadFactor: Single` | 负载因子 |
| `Reserve(n)` | 预留空间 |
| `Clear` | 清空 |

## LinkedHashMap vs HashMap vs TreeMap

| 特性 | LinkedHashMap | HashMap | TreeMap |
|------|---------------|---------|---------|
| 查找 | O(1) | O(1) | O(log n) |
| 插入 | O(1) | O(1) | O(log n) |
| 迭代顺序 | **插入顺序** | 无序 | **键排序** |
| 内存 | 较高 | 低 | 中 |

## 使用模式

### 模式 1：保持配置顺序

```pascal
var
  Config: specialize TLinkedHashMap<String, String>;
begin
  Config := specialize TLinkedHashMap<String, String>.Create;
  try
    // 配置按定义顺序保存
    Config.Put('host', 'localhost');
    Config.Put('port', '8080');
    Config.Put('debug', 'true');
    
    // 序列化时保持顺序
    for var Key in Config.GetAllKeys do
      WriteLn(Key, '=', Config.Get(Key));
  finally
    Config.Free;
  end;
end;
```

### 模式 2：LRU 基础（访问不改变顺序）

```pascal
// 注意：LinkedHashMap 只保持插入顺序
// 如需访问顺序（LRU），使用 TLruCache

var
  History: specialize TLinkedHashMap<String, TDateTime>;
begin
  // 记录访问历史，先访问的在前
  History.Put('page1', Now);
  History.Put('page2', Now);
  
  var FirstVisit := History.First;  // page1
end;
```

### 模式 3：JSON 对象顺序

```pascal
type
  TJsonObject = specialize TLinkedHashMap<String, TJsonValue>;

procedure SerializeJson(Obj: TJsonObject);
begin
  Write('{');
  var First := True;
  for var Key in Obj.GetAllKeys do
  begin
    if not First then Write(', ');
    Write('"', Key, '": ', Obj.Get(Key).ToString);
    First := False;
  end;
  Write('}');
end;
```

## 典型应用

### HTTP Headers

```pascal
type
  THttpHeaders = specialize TLinkedHashMap<String, String>;

var
  Headers: THttpHeaders;
begin
  Headers := THttpHeaders.Create;
  try
    Headers.Put('Content-Type', 'application/json');
    Headers.Put('Authorization', 'Bearer xxx');
    Headers.Put('Accept', '*/*');
    
    // 按添加顺序发送
    for var Key in Headers.GetAllKeys do
      SendHeader(Key, Headers.Get(Key));
  finally
    Headers.Free;
  end;
end;
```

### 表单字段顺序

```pascal
type
  TFormData = specialize TLinkedHashMap<String, String>;

procedure BuildForm(Form: TFormData);
begin
  Form.Put('username', 'admin');
  Form.Put('password', '***');
  Form.Put('remember', 'true');
  
  // 按字段定义顺序生成 HTML
  for var Key in Form.GetAllKeys do
    WriteLn('<input name="', Key, '" value="', Form.Get(Key), '">');
end;
```

### 有序查找表

```pascal
type
  TMenuItems = specialize TLinkedHashMap<String, TProc>;

var
  Menu: TMenuItems;
begin
  Menu := TMenuItems.Create;
  try
    Menu.Put('New', @HandleNew);
    Menu.Put('Open', @HandleOpen);
    Menu.Put('Save', @HandleSave);
    Menu.Put('Exit', @HandleExit);
    
    // 菜单按定义顺序显示
    var Index := 1;
    for var Key in Menu.GetAllKeys do
    begin
      WriteLn(Index, '. ', Key);
      Inc(Index);
    end;
  finally
    Menu.Free;
  end;
end;
```

## 内存布局

```
LinkedHashMap:

HashMap: [K1->V1] [K2->V2] [K3->V3] (无序存储)
         
NodeMap: [K1->Node1] [K2->Node2] [K3->Node3]

Linked List (插入顺序):
  Head -> [Node1] <-> [Node2] <-> [Node3] <- Tail
            K1          K2          K3
```

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| Put/Get/Remove | O(1) 摊销 | O(1) |
| First/Last | O(1) | O(1) |
| GetAllKeys | O(n) | O(n) |
| 迭代 | O(n) | O(1) |
| 内存开销 | - | 2x HashMap |

## 选择指南

| 需求 | 推荐 |
|------|------|
| 只需 O(1) 查找 | `THashMap` |
| 需要保持插入顺序 | `TLinkedHashMap` |
| 需要键排序 | `TTreeMap` |
| 需要 LRU 淘汰 | `TLruCache` |

## 注意事项

1. **更新不改变顺序**
   ```pascal
   Map.Put('a', 1);
   Map.Put('b', 2);
   Map.Put('a', 100);  // 更新 a 的值，但 a 仍在 b 前面
   ```

2. **删除后重新插入**
   ```pascal
   Map.Put('a', 1);
   Map.Put('b', 2);
   Map.Remove('a');
   Map.Put('a', 1);  // a 现在在 b 后面
   ```

3. **内存开销**
   ```pascal
   // LinkedHashMap 比 HashMap 多约 2 个指针/元素
   // 如果不需要顺序，使用 HashMap 更省内存
   ```

## 最佳实践

1. **需要顺序时使用**
   ```pascal
   // ✅ 需要保持顺序
   var Config: TLinkedHashMap<String, String>;
   
   // ❌ 不需要顺序时，HashMap 更高效
   var Cache: THashMap<String, TData>;
   ```

2. **预估容量**
   ```pascal
   // ✅ 避免 rehash
   Map := TLinkedHashMap<K,V>.Create(ExpectedSize);
   ```

3. **遍历用 GetAllKeys**
   ```pascal
   // ✅ 按插入顺序遍历
   for var Key in Map.GetAllKeys do
     Process(Key, Map.Get(Key));
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `THashMap<K,V>` | 无序，最高效 |
| `TTreeMap<K,V>` | 键排序 |
| `TLruCache<K,V>` | 访问顺序 + 淘汰 |
