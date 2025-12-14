# TTrie - 字典树（前缀树）使用指南

## 概述

`TTrie<V>` 是基于**字典树（Trie）**实现的字符串-值映射。

| 特性 | 描述 |
|------|------|
| 键类型 | 字符串 |
| 查找/插入/删除 | O(m)，m 为键长度 |
| 前缀查询 | **高效** |
| 空间 | 与键共享前缀相关 |

> **适用场景**：自动补全、拼写检查、IP 路由表、字典查找等需要前缀匹配的场景。

## 快速开始

```pascal
uses
  fafafa.core.collections.trie;

var
  Trie: specialize TTrie<Integer>;
begin
  Trie := specialize TTrie<Integer>.Create;
  try
    // 插入
    Trie.Put('apple', 1);
    Trie.Put('app', 2);
    Trie.Put('application', 3);
    Trie.Put('banana', 4);
    
    // 精确查找
    var Value: Integer;
    if Trie.Get('app', Value) then
      WriteLn('app = ', Value);  // 2
    
    // 前缀查询
    if Trie.HasPrefix('app') then
      WriteLn('Has keys starting with "app"');
    
    // 获取所有匹配前缀的键
    var Keys := Trie.KeysWithPrefix('app');
    // ['app', 'apple', 'application']
  finally
    Trie.Free;
  end;
end;
```

## API 参考

### 创建

```pascal
Trie := specialize TTrie<Integer>.Create;
```

### 核心操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Put(key, value): Boolean` | 插入/更新 | O(m) |
| `Get(key, out value): Boolean` | 获取值 | O(m) |
| `ContainsKey(key): Boolean` | 检查键 | O(m) |
| `Remove(key): Boolean` | 删除 | O(m) |
| `Clear` | 清空 | O(n) |

### 前缀操作（TTrie 特有）

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `HasPrefix(prefix): Boolean` | 是否存在以该前缀开头的键 | O(m) |
| `KeysWithPrefix(prefix): TKeyArray` | 获取所有匹配前缀的键 | O(m + k) |

> m = 前缀长度，k = 匹配的键数量

### 状态查询

| 方法 | 描述 |
|------|------|
| `GetCount: SizeUInt` | 元素数量 |
| `IsEmpty: Boolean` | 是否为空 |

## Trie 结构图示

```
插入: "app", "apple", "application", "apply", "banana"

         (root)
         /    \
        a      b
        |      |
        p      a
        |      |
        p*     n
       /|\     |
      l i y*   a
      |  \     |
      e*  c    n
          |    |
          a    a*
          |
          t
          |
          i
          |
          o
          |
          n*

* 表示该节点是一个完整键的终点
```

## 使用模式

### 模式 1：自动补全

```pascal
function Autocomplete(Trie: TTrie<TData>; const Prefix: string; MaxResults: Integer): TStringArray;
var
  AllKeys: TTrie<TData>.TKeyArray;
begin
  AllKeys := Trie.KeysWithPrefix(Prefix);
  SetLength(Result, Min(MaxResults, Length(AllKeys)));
  for var i := 0 to High(Result) do
    Result[i] := AllKeys[i];
end;
```

### 模式 2：拼写检查

```pascal
var
  Dictionary: specialize TTrie<Boolean>;

function IsValidWord(const Word: string): Boolean;
begin
  Result := Dictionary.ContainsKey(LowerCase(Word));
end;

function GetSuggestions(const Prefix: string): TStringArray;
begin
  Result := Dictionary.KeysWithPrefix(LowerCase(Prefix));
end;
```

### 模式 3：命令解析

```pascal
type
  TCommandHandler = procedure(const Args: string);
  TCommandTrie = specialize TTrie<TCommandHandler>;

var
  Commands: TCommandTrie;

procedure RegisterCommand(const Name: string; Handler: TCommandHandler);
begin
  Commands.Put(Name, Handler);
end;

procedure ExecuteCommand(const Input: string);
var
  Handler: TCommandHandler;
  CmdName, Args: string;
begin
  // 解析命令名
  SplitCommand(Input, CmdName, Args);
  
  if Commands.Get(CmdName, Handler) then
    Handler(Args)
  else
    WriteLn('Unknown command: ', CmdName);
end;
```

## 典型应用

### IP 路由表（前缀匹配）

```pascal
type
  TRoute = record
    Gateway: string;
    Interface: string;
  end;
  TRoutingTable = specialize TTrie<TRoute>;

// IP 地址转换为二进制字符串进行前缀匹配
function IPToBinaryString(const IP: string): string;
begin
  // 将 IP 转为 32 位二进制字符串
end;

function LongestPrefixMatch(Table: TRoutingTable; const IP: string): TRoute;
var
  BinIP: string;
  Prefix: string;
begin
  BinIP := IPToBinaryString(IP);
  
  // 从长到短尝试匹配
  for var Len := Length(BinIP) downto 1 do
  begin
    Prefix := Copy(BinIP, 1, Len);
    if Table.Get(Prefix, Result) then
      Exit;
  end;
  
  // 默认路由
  Table.Get('', Result);
end;
```

### 词频统计

```pascal
type
  TWordCounter = specialize TTrie<Integer>;

procedure CountWords(const Text: string);
var
  Counter: TWordCounter;
  Words: TStringArray;
  Count: Integer;
begin
  Counter := TWordCounter.Create;
  try
    Words := SplitWords(Text);
    
    for var Word in Words do
    begin
      if Counter.Get(Word, Count) then
        Counter.Put(Word, Count + 1)
      else
        Counter.Put(Word, 1);
    end;
    
    // 输出所有单词及频率
    for var Key in Counter.KeysWithPrefix('') do
    begin
      Counter.Get(Key, Count);
      WriteLn(Key, ': ', Count);
    end;
  finally
    Counter.Free;
  end;
end;
```

### T9 输入法

```pascal
type
  TT9Dict = specialize TTrie<TStringArray>;  // 数字序列 -> 可能的单词

const
  T9Map: array['a'..'z'] of Char = (
    '2','2','2',  // abc
    '3','3','3',  // def
    '4','4','4',  // ghi
    '5','5','5',  // jkl
    '6','6','6',  // mno
    '7','7','7','7',  // pqrs
    '8','8','8',  // tuv
    '9','9','9','9'   // wxyz
  );

function WordToT9(const Word: string): string;
begin
  Result := '';
  for var C in LowerCase(Word) do
    if C in ['a'..'z'] then
      Result := Result + T9Map[C];
end;

// 预处理字典
procedure BuildT9Dict(Words: TStringArray; Dict: TT9Dict);
var
  Existing: TStringArray;
  T9Code: string;
begin
  for var Word in Words do
  begin
    T9Code := WordToT9(Word);
    if Dict.Get(T9Code, Existing) then
      Dict.Put(T9Code, Existing + [Word])
    else
      Dict.Put(T9Code, [Word]);
  end;
end;
```

## Trie vs HashMap vs TreeMap

| 特性 | TTrie | THashMap | TTreeMap |
|------|-------|----------|----------|
| 查找 | O(m) | O(1) 平均 | O(log n) |
| 前缀查询 | **O(m + k)** | O(n) | O(log n + k) |
| 空间效率 | 依赖数据 | 高 | 中 |
| 键类型 | 字符串 | 任意可哈希 | 任意可比较 |

### 选择建议

| 场景 | 推荐 |
|------|------|
| 精确字符串查找 | `THashMap` |
| 前缀匹配/自动补全 | `TTrie` |
| 有序字符串遍历 | `TTreeMap` |
| 大量短字符串，共享前缀多 | `TTrie` |

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| Put | O(m) | O(m) |
| Get | O(m) | O(1) |
| Remove | O(m) | O(1) |
| HasPrefix | O(m) | O(1) |
| KeysWithPrefix | O(m + k) | O(k) |

> m = 键长度，k = 匹配键数量

## 内存考虑

```
当前实现：每个节点 256 个子指针（支持全字节范围）

内存 = 节点数 × (256 × 指针大小 + 值大小 + 标志)
     ≈ 节点数 × 2KB (64位系统)

优化方向：
- 压缩 Trie（Patricia Trie）
- 使用 HashMap 存储子节点
- 只支持小写字母（26 个子指针）
```

## 注意事项

1. **键区分大小写**
   ```pascal
   // 'App' 和 'app' 是不同的键
   // 如需忽略大小写，统一转换
   Trie.Put(LowerCase(Key), Value);
   ```

2. **空字符串键**
   ```pascal
   // 支持空字符串作为键
   Trie.Put('', DefaultValue);
   ```

3. **内存管理**
   ```pascal
   // 手动释放
   Trie := TTrie<V>.Create;
   try
     // 使用
   finally
     Trie.Free;
   end;
   ```

## 最佳实践

1. **前缀查询场景优先使用**
   ```pascal
   // ✅ 自动补全、拼写检查
   var Suggestions := Trie.KeysWithPrefix(UserInput);
   
   // ❌ 只需精确查找时，HashMap 更高效
   ```

2. **预处理固定字典**
   ```pascal
   // ✅ 启动时加载，运行时查询
   LoadDictionary(Trie);
   // 后续只读查询
   ```

3. **共享前缀利用**
   ```pascal
   // Trie 对共享前缀的数据集效率高
   // 例如: URL 路径、文件路径、域名
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `THashMap<String, V>` | O(1) 精确查找 |
| `TTreeMap<String, V>` | 有序字符串映射 |
| `TSkipList<String, V>` | 范围查询 |
