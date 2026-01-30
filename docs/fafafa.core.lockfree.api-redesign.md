# LockFree 模块 API 重构设计

## 📋 **概述**

为了与 `fafafa.core.collections` 框架保持一致的 API 风格，我们需要重构 `fafafa.core.lockfree` 模块的接口设计，同时保持其高性能的无锁特性。

## 🎯 **设计目标**

1. **API 风格统一**：与 collections 框架保持一致的命名和参数风格
2. **内存分配器集成**：使用统一的 `TAllocator` 进行内存管理
3. **向后兼容**：保留原有 API，标记为 deprecated
4. **性能保持**：不影响无锁数据结构的性能特征

## 🏗️ **重构方案**

### **1. 构造函数统一化**

#### **现有风格**
```pascal
// 旧版本构造函数
constructor Create(ACapacity: Integer = 1024);
constructor Create;
```

#### **新的 Collections 风格**
```pascal
// Collections 风格的构造函数
constructor Create; overload;
constructor Create(aCapacity: SizeUInt); overload;
constructor Create(aAllocator: TAllocator); overload;
constructor Create(aAllocator: TAllocator; aData: Pointer); overload;
constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator); overload;
constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator; aData: Pointer); overload;

// 兼容旧版本（标记为 deprecated）
constructor Create(ACapacity: Integer = 1024); overload; deprecated;
```

### **2. 方法命名统一化**

#### **队列操作**
```pascal
// Collections 风格的队列操作
procedure Push(const aElement: T);           // 入队
function Pop(var aElement: T): Boolean;      // 出队（返回是否成功）
procedure Pop; overload;                     // 出队（抛异常版本）

// 原始的无锁操作（保持兼容性）
function Enqueue(const AItem: T): Boolean;   // 原有方法
function Dequeue(out AItem: T): Boolean;     // 原有方法
```

#### **栈操作**
```pascal
// Collections 风格的栈操作
procedure Push(const aElement: T);           // 入栈
function Pop(var aElement: T): Boolean;      // 出栈（返回是否成功）
procedure Pop; overload;                     // 出栈（抛异常版本）
function Peek(var aElement: T): Boolean;     // 查看栈顶

// 原始的无锁操作（保持兼容性）
function Push(const AItem: T): Boolean;      // 原有方法
function Pop(out AItem: T): Boolean;         // 原有方法
```

### **3. 状态查询统一化**

```pascal
// Collections 风格的状态查询
function IsEmpty: Boolean;
function GetCount: SizeUInt;                 // 替代 GetSize
function GetCapacity: SizeUInt;              // 统一返回类型

// Collections 风格的内存管理
function GetAllocator: TAllocator;
function GetData: Pointer;

// 兼容旧版本
function GetSize: Integer; deprecated 'Use GetCount instead';

// Collections 风格的属性
property Count: SizeUInt read GetCount;
property Capacity: SizeUInt read GetCapacity;
property Allocator: TAllocator read GetAllocator;
property Data: Pointer read GetData;
```

### **4. 异常处理统一化**

```pascal
// Collections 风格的异常处理
procedure Push(const aElement: T);           // 失败时抛出异常
procedure Pop;                               // 空时抛出 EEmptyCollection
function TryPush(const aElement: T): Boolean; // 不抛异常版本
function TryPop(var aElement: T): Boolean;   // 不抛异常版本
```

## 📊 **各数据结构的 API 设计**

### **TSPSCQueue<T> - 单生产者单消费者队列**

```pascal
generic TSPSCQueue<T> = class
private
  FBuffer: array of TNode;
  FCapacity: Integer;
  FMask: Integer;
  FEnqueuePos: QWord;
  FDequeuePos: QWord;
  FAllocator: TAllocator;    // 新增
  FData: Pointer;            // 新增

public
  // Collections 风格构造函数
  constructor Create; overload;
  constructor Create(aCapacity: SizeUInt); overload;
  constructor Create(aAllocator: TAllocator); overload;
  constructor Create(aAllocator: TAllocator; aData: Pointer); overload;
  constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator); overload;
  constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator; aData: Pointer); overload;
  
  // Collections 风格队列操作
  procedure Push(const aElement: T);
  function Pop(var aElement: T): Boolean;
  procedure Pop; overload;
  
  // Collections 风格状态查询
  function IsEmpty: Boolean;
  function IsFull: Boolean;
  function GetCount: SizeUInt;
  function GetCapacity: SizeUInt;
  function GetAllocator: TAllocator;
  function GetData: Pointer;
  
  // Collections 风格属性
  property Count: SizeUInt read GetCount;
  property Capacity: SizeUInt read GetCapacity;
  property Allocator: TAllocator read GetAllocator;
  property Data: Pointer read GetData;
  
  // 兼容旧版本（deprecated）
  constructor Create(ACapacity: Integer = 1024); overload; deprecated;
  function Enqueue(const AItem: T): Boolean; deprecated;
  function Dequeue(out AItem: T): Boolean; deprecated;
  function GetSize: Integer; deprecated;
end;
```

### **TMichaelScottQueue<T> - Michael-Scott 无锁队列**

```pascal
generic TMichaelScottQueue<T> = class
private
  FHead: PNode;
  FTail: PNode;
  FAllocator: TAllocator;    // 新增
  FData: Pointer;            // 新增

public
  // Collections 风格构造函数
  constructor Create; overload;
  constructor Create(aAllocator: TAllocator); overload;
  constructor Create(aAllocator: TAllocator; aData: Pointer); overload;
  
  // Collections 风格队列操作
  procedure Push(const aElement: T);
  function Pop(var aElement: T): Boolean;
  procedure Pop; overload;
  
  // Collections 风格状态查询
  function IsEmpty: Boolean;
  function GetAllocator: TAllocator;
  function GetData: Pointer;
  
  // Collections 风格属性
  property Allocator: TAllocator read GetAllocator;
  property Data: Pointer read GetData;
  
  // 兼容旧版本（deprecated）
  procedure Enqueue(const AItem: T); deprecated;
  function Dequeue(out AItem: T): Boolean; deprecated;
end;
```

### **TTreiberStack<T> - Treiber 无锁栈**

```pascal
generic TTreiberStack<T> = class
private
  FTop: PNode;
  FAllocator: TAllocator;    // 新增
  FData: Pointer;            // 新增

public
  // Collections 风格构造函数
  constructor Create; overload;
  constructor Create(aAllocator: TAllocator); overload;
  constructor Create(aAllocator: TAllocator; aData: Pointer); overload;
  
  // Collections 风格栈操作
  procedure Push(const aElement: T);
  function Pop(var aElement: T): Boolean;
  procedure Pop; overload;
  function Peek(var aElement: T): Boolean;
  
  // Collections 风格状态查询
  function IsEmpty: Boolean;
  function GetAllocator: TAllocator;
  function GetData: Pointer;
  
  // Collections 风格属性
  property Allocator: TAllocator read GetAllocator;
  property Data: Pointer read GetData;
  
  // 兼容旧版本（deprecated）
  function Push(const AItem: T): Boolean; deprecated;
  function Pop(out AItem: T): Boolean; deprecated;
end;
```

## 🔧 **内存分配器集成**

### **默认分配器**
```pascal
// 使用 RTL 分配器作为默认值
constructor TSPSCQueue.Create;
begin
  Create(1024, GetRtlAllocator(), nil);
end;

constructor TSPSCQueue.Create(aCapacity: SizeUInt);
begin
  Create(aCapacity, GetRtlAllocator(), nil);
end;
```

### **自定义分配器支持**
```pascal
// 支持自定义内存分配器
constructor TSPSCQueue.Create(aAllocator: TAllocator; aData: Pointer);
begin
  Create(1024, aAllocator, aData);
end;

// 主构造函数
constructor TSPSCQueue.Create(aCapacity: SizeUInt; aAllocator: TAllocator; aData: Pointer);
begin
  inherited Create;
  
  if aAllocator = nil then
    FAllocator := GetRtlAllocator()
  else
    FAllocator := aAllocator;
    
  FData := aData;
  
  // 使用分配器分配内存
  FCapacity := NextPowerOfTwo(aCapacity);
  FMask := FCapacity - 1;
  SetLength(FBuffer, FCapacity);
  
  // 初始化序列号
  for var i := 0 to FCapacity - 1 do
    FBuffer[i].Sequence := i;
    
  FEnqueuePos := 0;
  FDequeuePos := 0;
end;
```

## 📋 **实现优先级**

### **P0 - 立即实现**
1. **TSPSCQueue** - 最常用的高性能队列
2. **TMichaelScottQueue** - 通用多线程队列
3. **TTreiberStack** - 通用无锁栈

### **P1 - 后续实现**
1. **TPreAllocMPMCQueue** - 预分配 MPMC 队列
2. **TPreAllocStack** - 预分配安全栈
3. **TLockFreeHashMap** - 无锁哈希表

## 🎯 **使用示例**

### **新的 API 风格**
```pascal
var
  LQueue: specialize TSPSCQueue<Integer>;
  LValue: Integer;
begin
  // Collections 风格的创建
  LQueue := specialize TSPSCQueue<Integer>.Create(1024, GetRtlAllocator());
  
  // Collections 风格的操作
  LQueue.Push(42);
  if LQueue.Pop(LValue) then
    WriteLn('Popped: ', LValue);
    
  // Collections 风格的属性访问
  WriteLn('Count: ', LQueue.Count);
  WriteLn('Capacity: ', LQueue.Capacity);
  
  LQueue.Free;
end;
```

### **向后兼容**
```pascal
var
  LQueue: specialize TSPSCQueue<Integer>;
  LValue: Integer;
begin
  // 旧版本 API 仍然可用（但会有 deprecated 警告）
  LQueue := specialize TSPSCQueue<Integer>.Create(1024);
  
  if LQueue.Enqueue(42) then
    WriteLn('Enqueued successfully');
    
  if LQueue.Dequeue(LValue) then
    WriteLn('Dequeued: ', LValue);
    
  LQueue.Free;
end;
```

## 📊 **总结**

这个重构方案实现了：

1. ✅ **API 风格统一**：与 collections 框架保持一致
2. ✅ **内存分配器集成**：支持自定义内存管理
3. ✅ **向后兼容**：保留原有 API
4. ✅ **性能保持**：不影响无锁特性
5. ✅ **易用性提升**：提供更友好的接口

通过这个设计，用户可以享受到统一的 API 体验，同时保持无锁数据结构的高性能特征。
