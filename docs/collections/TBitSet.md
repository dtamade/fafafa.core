# TBitSet - 位集合使用指南

## 概述

`IBitSet` 是高效的**位集合**，用于存储布尔标志。

| 特性 | 描述 |
|------|------|
| 存储 | 每个布尔值仅占 1 bit（vs Boolean 的 1 byte） |
| 底层 | UInt64 数组（64 bits per word） |
| 位运算 | 支持 AND、OR、XOR、NOT |

> **适用场景**：布隆过滤器、权限位、特征标记、稀疏集合等需要高效存储大量布尔值的场景。

## 快速开始

```pascal
uses
  fafafa.core.collections.bitset;

var
  Bits: IBitSet;
begin
  Bits := TBitSet.Create(1000);  // 1000 位容量
  
  // 设置位
  Bits.SetBit(0);
  Bits.SetBit(5);
  Bits.SetBit(100);
  
  // 测试位
  if Bits.Test(5) then
    WriteLn('Bit 5 is set');
  
  // 翻转位
  Bits.Flip(5);  // 5 变为 0
  
  // 统计设置的位数
  WriteLn('Set bits: ', Bits.Cardinality);  // 输出: 2
end;
```

## API 参考

### 创建

```pascal
// 默认容量（64 位）
Bits := TBitSet.Create;

// 指定容量
Bits := TBitSet.Create(10000);

// 自定义分配器
Bits := TBitSet.Create(1000, MyAllocator);
```

### 位操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `SetBit(i)` | 设置第 i 位为 1 | O(1) |
| `ClearBit(i)` | 清除第 i 位为 0 | O(1) |
| `Test(i): Boolean` | 测试第 i 位是否为 1 | O(1) |
| `Flip(i)` | 翻转第 i 位 | O(1) |

### 批量操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `SetAll` | 设置所有位为 1 | O(n/64) |
| `ClearAll` | 清除所有位为 0 | O(n/64) |
| `Cardinality: SizeUInt` | 统计 1 的数量 | O(n/64) |

### 位运算

| 方法 | 描述 | 返回 |
|------|------|------|
| `AndWith(other): IBitSet` | 按位与 | 新 BitSet |
| `OrWith(other): IBitSet` | 按位或 | 新 BitSet |
| `XorWith(other): IBitSet` | 按位异或 | 新 BitSet |
| `NotBits: IBitSet` | 按位取反 | 新 BitSet |

### 状态查询

| 方法 | 描述 |
|------|------|
| `GetBitCapacity: SizeUInt` | 位容量 |
| `IsEmpty: Boolean` | 是否为空（无设置位） |
| `Clear` | 清空 |

## 使用模式

### 模式 1：标志位集合

```pascal
type
  TPermission = (Read, Write, Execute, Admin);

var
  Perms: IBitSet;
begin
  Perms := TBitSet.Create(4);
  
  Perms.SetBit(Ord(Read));
  Perms.SetBit(Ord(Write));
  
  if Perms.Test(Ord(Write)) then
    WriteLn('Has write permission');
end;
```

### 模式 2：集合交并差

```pascal
var
  A, B, Union, Intersection, Diff: IBitSet;
begin
  // A = {0, 2, 4}
  A := TBitSet.Create(10);
  A.SetBit(0); A.SetBit(2); A.SetBit(4);
  
  // B = {2, 3, 4}
  B := TBitSet.Create(10);
  B.SetBit(2); B.SetBit(3); B.SetBit(4);
  
  Union := A.OrWith(B);         // {0, 2, 3, 4}
  Intersection := A.AndWith(B); // {2, 4}
  Diff := A.XorWith(B);         // {0, 3} (对称差)
end;
```

### 模式 3：快速成员测试

```pascal
// 用 BitSet 做快速查找表
var
  PrimeSet: IBitSet;
begin
  PrimeSet := TBitSet.Create(1000);
  
  // 标记素数
  for var P in [2, 3, 5, 7, 11, 13, ...] do
    PrimeSet.SetBit(P);
  
  // O(1) 判断
  if PrimeSet.Test(N) then
    WriteLn(N, ' is prime');
end;
```

## 典型应用

### 布隆过滤器

```pascal
type
  TBloomFilter = class
  private
    FBits: IBitSet;
    FHashCount: Integer;
  public
    procedure Add(const Item: String);
    function MayContain(const Item: String): Boolean;
  end;

procedure TBloomFilter.Add(const Item: String);
begin
  for var i := 0 to FHashCount - 1 do
    FBits.SetBit(Hash(Item, i) mod FBits.BitCapacity);
end;

function TBloomFilter.MayContain(const Item: String): Boolean;
begin
  for var i := 0 to FHashCount - 1 do
    if not FBits.Test(Hash(Item, i) mod FBits.BitCapacity) then
      Exit(False);
  Result := True;
end;
```

### 图的邻接矩阵

```pascal
// 紧凑存储无向图
type
  TAdjMatrix = class
  private
    FBits: IBitSet;
    FVertexCount: Integer;
  public
    procedure AddEdge(U, V: Integer);
    function HasEdge(U, V: Integer): Boolean;
  end;

function TAdjMatrix.HasEdge(U, V: Integer): Boolean;
begin
  Result := FBits.Test(U * FVertexCount + V);
end;
```

### 状态压缩 DP

```pascal
// 旅行商问题状态表示
function TSP(Graph: TGraph): Integer;
var
  Visited: IBitSet;
begin
  Visited := TBitSet.Create(N);
  
  // 状态: 访问过的城市集合
  for var State := 0 to (1 shl N) - 1 do
  begin
    // 用 BitSet 操作
    Visited.ClearAll;
    for var i := 0 to N - 1 do
      if (State and (1 shl i)) <> 0 then
        Visited.SetBit(i);
    
    // ... DP 计算
  end;
end;
```

### 权限系统

```pascal
type
  TUserPermissions = class
  private
    FPerms: IBitSet;
  public
    procedure Grant(Perm: TPermission);
    procedure Revoke(Perm: TPermission);
    function Has(Perm: TPermission): Boolean;
    function HasAll(const Perms: array of TPermission): Boolean;
    function HasAny(const Perms: array of TPermission): Boolean;
  end;

function TUserPermissions.HasAll(const Perms: array of TPermission): Boolean;
begin
  for var P in Perms do
    if not FPerms.Test(Ord(P)) then
      Exit(False);
  Result := True;
end;
```

## 位运算真值表

### AND (AndWith)
```
A | B | A AND B
0 | 0 |   0
0 | 1 |   0
1 | 0 |   0
1 | 1 |   1
```

### OR (OrWith)
```
A | B | A OR B
0 | 0 |   0
0 | 1 |   1
1 | 0 |   1
1 | 1 |   1
```

### XOR (XorWith)
```
A | B | A XOR B
0 | 0 |   0
0 | 1 |   1
1 | 0 |   1
1 | 1 |   0
```

### NOT (NotBits)
```
A | NOT A
0 |   1
1 |   0
```

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| SetBit/ClearBit/Test/Flip | O(1) | O(1) |
| Cardinality | O(n/64) | O(1) |
| SetAll/ClearAll | O(n/64) | O(1) |
| AndWith/OrWith/XorWith | O(n/64) | O(n) |
| NotBits | O(n/64) | O(n) |

## 内存布局

```
BitSet (BitCapacity = 200):

Words: [Word0][Word1][Word2][Word3]
        64     64     64     8 (有效)

内存: 4 * 8 = 32 bytes
      (vs Boolean[200] = 200 bytes)

压缩比: 1:6.25
```

## BitSet vs Boolean 数组

| 特性 | BitSet | Boolean[] |
|------|--------|-----------|
| 每元素空间 | 1 bit | 1 byte |
| 1000 元素内存 | 125 bytes | 1000 bytes |
| 随机访问 | O(1) + 位运算 | O(1) |
| 批量运算 | **64x 并行** | 逐个 |
| 缓存友好性 | 更好 | 一般 |

## 注意事项

1. **自动扩容**
   ```pascal
   // SetBit 会自动扩容
   Bits := TBitSet.Create(10);
   Bits.SetBit(1000);  // 自动扩容到 >= 1001
   ```

2. **位运算返回新对象**
   ```pascal
   // AndWith 等返回新 IBitSet
   var Result := A.AndWith(B);  // 新对象
   // A 和 B 不变
   ```

3. **Cardinality 使用 PopCount**
   ```pascal
   // 内部使用 CPU 指令优化（如果可用）
   // 否则使用高效的位运算算法
   ```

## 最佳实践

1. **预分配容量**
   ```pascal
   // ✅ 避免重复扩容
   Bits := TBitSet.Create(ExpectedMax);
   ```

2. **批量操作优于逐位**
   ```pascal
   // ✅ 高效
   Result := A.AndWith(B);
   
   // ❌ 低效
   for i := 0 to Max do
     if A.Test(i) and B.Test(i) then
       Result.SetBit(i);
   ```

3. **枚举转整数**
   ```pascal
   // ✅ 使用 Ord 转换
   Bits.SetBit(Ord(MyEnum));
   ```

## 相关容器

| 容器 | 场景 |
|------|------|
| `THashSet<T>` | 任意类型集合 |
| `TTreeSet<T>` | 有序集合 |
| `TVec<Boolean>` | 需要迭代的布尔数组 |
