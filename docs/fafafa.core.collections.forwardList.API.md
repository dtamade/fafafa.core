# ForwardList API 完整文档

## 📋 **概述**

`TForwardList<T>` 是一个高性能的单向链表容器，提供常数时间的前端插入和删除操作。

### **特点**
- ✅ **高效前端操作**：O(1) 时间复杂度的 PushFront/PopFront
- ✅ **内存友好**：只在需要时分配内存，无预分配开销
- ✅ **类型安全**：完全泛型化，支持任意类型
- ✅ **异常安全**：所有操作都有适当的异常处理
- ✅ **迭代器支持**：标准的前向迭代器

### **适用场景**
- 频繁的前端插入/删除操作
- 内存使用量敏感的应用
- 不需要随机访问的数据结构
- 实现栈、队列等数据结构的底层容器

## 🏗️ **构造函数**

### **基础构造函数**

```pascal
// 1. 默认构造函数
constructor Create;
// 创建空的 ForwardList

// 2. 使用自定义分配器
constructor Create(aAllocator: TAllocator);
// 使用指定的内存分配器

// 3. 使用自定义分配器和数据
constructor Create(aAllocator: TAllocator; aData: Pointer);
// 使用指定的分配器和自定义数据指针
```

### **从数组构造**

```pascal
// 4. 从静态数组构造
constructor Create(const aSrc: array of T);
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 3, 4, 5]);
  // 结果：Front=1, Count=5
end;

// 5. 从数组 + 自定义分配器
constructor Create(const aSrc: array of T; aAllocator: TAllocator);

// 6. 从数组 + 分配器 + 数据
constructor Create(const aSrc: array of T; aAllocator: TAllocator; aData: Pointer);
```

### **从其他容器构造**

```pascal
// 7. 从其他集合构造
constructor Create(const aSrc: TCollection);
// 示例：
var LList1, LList2: TIntList;
begin
  LList1 := TIntList.Create([1, 2, 3]);
  LList2 := TIntList.Create(LList1);  // 复制构造
  // LList2 现在包含 [1, 2, 3]
end;

// 8. 从集合 + 自定义分配器
constructor Create(const aSrc: TCollection; aAllocator: TAllocator);

// 9. 从集合 + 分配器 + 数据
constructor Create(const aSrc: TCollection; aAllocator: TAllocator; aData: Pointer);
```

### **从内存指针构造**

```pascal
// 10. 从内存指针构造
constructor Create(aSrc: Pointer; aElementCount: SizeUInt);
// 示例：
var 
  LArray: array[0..2] of Integer = (10, 20, 30);
  LList: TIntList;
begin
  LList := TIntList.Create(@LArray[0], Length(LArray));
  // 结果：包含 [10, 20, 30]
end;

// 11. 从指针 + 自定义分配器
constructor Create(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator);

// 12. 从指针 + 分配器 + 数据
constructor Create(aSrc: Pointer; aElementCount: SizeUInt; aAllocator: TAllocator; aData: Pointer);
```

## 🔧 **基础操作**

### **元素访问**

```pascal
// 获取第一个元素
function Front: T;
// 抛出异常：空链表时抛出 EEmptyCollection
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 3]);
  WriteLn(LList.Front);  // 输出：1
end;

// 安全获取第一个元素
function TryFront(out aElement: T): Boolean;
// 返回：成功时 True，空链表时 False
// 示例：
var 
  LList: TIntList;
  LValue: Integer;
begin
  LList := TIntList.Create;
  if LList.TryFront(LValue) then
    WriteLn('Front: ', LValue)
  else
    WriteLn('链表为空');
end;
```

### **元素修改**

```pascal
// 在前端添加元素
procedure PushFront(const aElement: T);
// 时间复杂度：O(1)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create;
  LList.PushFront(1);
  LList.PushFront(2);
  // 结果：[2, 1]
end;

// 移除第一个元素
procedure PopFront;
// 抛出异常：空链表时抛出 EEmptyCollection
// 时间复杂度：O(1)

// 安全移除第一个元素
function TryPopFront(out aElement: T): Boolean;
// 返回：成功时 True 并返回元素，空链表时 False
// 时间复杂度：O(1)
// 示例：
var 
  LList: TIntList;
  LValue: Integer;
begin
  LList := TIntList.Create([1, 2, 3]);
  while LList.TryPopFront(LValue) do
    WriteLn('弹出: ', LValue);
  // 输出：弹出: 1, 弹出: 2, 弹出: 3
end;
```

### **容器信息**

```pascal
// 获取元素数量
function Count: SizeUInt;
// 时间复杂度：O(1)

// 检查是否为空
function IsEmpty: Boolean;
// 时间复杂度：O(1)
// 等价于 Count = 0

// 清空所有元素
procedure Clear;
// 时间复杂度：O(n)
// 释放所有节点内存
```

## 🔍 **查找和算法**

### **查找操作**

```pascal
// 检查是否包含元素
function Contains(const aElement: T): Boolean;
// 时间复杂度：O(n)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 3]);
  if LList.Contains(2) then
    WriteLn('找到了 2');
end;

// 计算元素出现次数
function CountOf(const aElement: T): SizeUInt;
// 时间复杂度：O(n)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 2, 3, 2]);
  WriteLn('2 出现了 ', LList.CountOf(2), ' 次');  // 输出：3
end;
```

### **修改操作**

```pascal
// 移除所有匹配的元素
function Remove(const aElement: T): SizeUInt;
// 返回：移除的元素数量
// 时间复杂度：O(n)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 2, 3, 2]);
  WriteLn('移除了 ', LList.Remove(2), ' 个元素');  // 输出：3
  // 结果：[1, 3]
end;

// 替换所有匹配的元素
procedure Replace(const aOldElement, aNewElement: T);
// 时间复杂度：O(n)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 2, 3]);
  LList.Replace(2, 99);
  // 结果：[1, 99, 99, 3]
end;

// 用指定值填充所有元素
procedure Fill(const aElement: T);
// 时间复杂度：O(n)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 3]);
  LList.Fill(0);
  // 结果：[0, 0, 0]
end;

// 将所有元素设为零值
procedure Zero;
// 时间复杂度：O(n)
// 对于数值类型设为 0，对于指针类型设为 nil
```

## 🔄 **迭代器操作**

### **基础迭代**

```pascal
// 获取迭代器
function Iter: specialize TIter<T>;
// 示例：
var 
  LList: TIntList;
  LIter: specialize TIter<Integer>;
begin
  LList := TIntList.Create([1, 2, 3]);
  LIter := LList.Iter;
  while LIter.MoveNext do
    WriteLn(LIter.Current);
  // 输出：1, 2, 3
end;

// for-in 循环支持
// 示例：
var 
  LList: TIntList;
  LValue: Integer;
begin
  LList := TIntList.Create([1, 2, 3]);
  for LValue in LList do
    WriteLn(LValue);
  // 输出：1, 2, 3
end;
```

### **迭代器方法**

```pascal
// 移动到下一个元素
function MoveNext: Boolean;
// 返回：有下一个元素时 True，到达末尾时 False

// 获取当前元素
function Current: T;
// 抛出异常：无效位置时抛出 EInvalidOperation

// 重置迭代器到开始位置
procedure Reset;
```

### **高级迭代操作**

```pascal
// 在迭代器位置后插入元素
procedure InsertAfter(var aIter: specialize TIter<T>; const aElement: T);
// 时间复杂度：O(1)
// 示例：
var 
  LList: TIntList;
  LIter: specialize TIter<Integer>;
begin
  LList := TIntList.Create([1, 3]);
  LIter := LList.Iter;
  LIter.MoveNext;  // 移动到第一个元素 (1)
  LList.InsertAfter(LIter, 2);
  // 结果：[1, 2, 3]
end;

// 删除迭代器位置后的元素
procedure EraseAfter(var aIter: specialize TIter<T>);
// 时间复杂度：O(1)
// 抛出异常：没有后续元素时抛出 EInvalidOperation
```

## 📦 **数组操作**

### **转换操作**

```pascal
// 转换为动态数组
function ToArray: specialize TGenericArray<T>;
// 时间复杂度：O(n)
// 示例：
var 
  LList: TIntList;
  LArray: specialize TGenericArray<Integer>;
begin
  LList := TIntList.Create([1, 2, 3]);
  LArray := LList.ToArray;
  // LArray 现在包含 [1, 2, 3]
end;

// 从数组加载数据
procedure LoadFrom(aSrc: Pointer; aElementCount: SizeUInt);
// 清空当前内容并从指针加载数据
// 抛出异常：aSrc 为 nil 时抛出 EArgumentNilException

// 保存到数组
procedure SaveTo(aDest: Pointer; aElementCount: SizeUInt);
// 将链表内容复制到指定内存位置
// 抛出异常：aDest 为 nil 或容量不足时抛出异常

// 追加数组内容
procedure Append(aSrc: Pointer; aElementCount: SizeUInt);
// 在链表末尾追加数组内容
```

### **容器操作**

```pascal
// 保存到其他容器
procedure SaveTo(aDest: TCollection);
// 清空目标容器并复制当前内容

// 反转链表
procedure Reverse;
// 时间复杂度：O(n)
// 示例：
var LList: TIntList;
begin
  LList := TIntList.Create([1, 2, 3]);
  LList.Reverse;
  // 结果：[3, 2, 1]
end;
```

## ⚠️ **异常处理**

### **常见异常**

```pascal
// EEmptyCollection
// 触发条件：
// - 在空链表上调用 Front()
// - 在空链表上调用 PopFront()

// EInvalidOperation
// 触发条件：
// - 在无效迭代器位置调用 Current
// - 在最后位置调用 EraseAfter()

// EArgumentNil
// 触发条件：
// - LoadFrom、SaveTo、Append 的指针参数为 nil

// EOutOfRange
// 触发条件：
// - SaveTo 的目标容量小于链表大小
```

### **异常安全保证**

- **基本保证**：异常发生时，容器保持有效状态
- **强保证**：失败的操作不会改变容器状态
- **无抛出保证**：析构函数和某些查询操作不会抛出异常

## 🛡️ 安全模型（Checked / Try* / Unchecked）

- Checked：参数/状态检查失败时抛异常；空 Front/PopFront 抛 EEmptyCollection
- Try*：不抛异常，返回 False 表示失败（如 TryFront/TryPopFront）
- Unchecked：跳过检查，要求调用方保证前置条件，仅在性能敏感路径使用；可在 DEBUG 构建下通过 DebugValidateTail 等帮助检查结构不变量

## 🎯 **使用示例**

### **基础用法**

```pascal
program ForwardListExample;

uses
  fafafa.core.collections.forwardList;

type
  TIntList = specialize TForwardList<Integer>;

var
  LList: TIntList;
  LValue: Integer;
begin
  // 创建并添加元素
  LList := TIntList.Create;
  try
    LList.PushFront(3);
    LList.PushFront(2);
    LList.PushFront(1);
    
    // 遍历元素
    for LValue in LList do
      WriteLn(LValue);  // 输出：1, 2, 3
    
    // 查找和修改
    if LList.Contains(2) then
      LList.Replace(2, 20);
    
    // 安全访问
    while LList.TryPopFront(LValue) do
      WriteLn('弹出: ', LValue);
      
  finally
    LList.Free;
  end;
end.
```

### **高级用法**

```pascal
// 自定义类型示例
type
  TPerson = record
    Name: String;
    Age: Integer;
  end;
  TPersonList = specialize TForwardList<TPerson>;

var
  LPersons: TPersonList;
  LPerson: TPerson;
begin
  LPersons := TPersonList.Create;
  try
    // 添加人员
    LPerson.Name := 'Alice';
    LPerson.Age := 25;
    LPersons.PushFront(LPerson);
    
    LPerson.Name := 'Bob';
    LPerson.Age := 30;
    LPersons.PushFront(LPerson);
    
    // 遍历
    for LPerson in LPersons do
      WriteLn(LPerson.Name, ': ', LPerson.Age);
      
  finally
    LPersons.Free;
  end;
end;
```

## 📊 **性能特征**

| 操作 | 时间复杂度 | 说明 |
|------|------------|------|
| PushFront | O(1) | 常数时间插入 |
| PopFront | O(1) | 常数时间删除 |
| Front | O(1) | 常数时间访问 |
| Count | O(1) | 维护计数器 |
| Contains | O(n) | 线性查找 |
| Remove | O(n) | 线性扫描删除 |
| Clear | O(n) | 释放所有节点 |
| InsertAfter | O(1) | 常数时间插入 |
| EraseAfter | O(1) | 常数时间删除 |

## 🔗 **相关类型**

- `TIter<T>` - 前向迭代器
- `TAllocator` - 内存分配器接口
- `TGenericArray<T>` - 动态数组类型
- `ICollection<T>` - 集合接口

---

*API 文档版本：1.0*  
*最后更新：2025年1月*  
*ForwardList 版本：生产就绪*
