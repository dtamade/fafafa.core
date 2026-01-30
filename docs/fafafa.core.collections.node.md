# fafafa.core.collections.node

## 概述

`fafafa.core.collections.node` 模块提供了高性能的节点数据结构，作为各种集合类型（链表、树、图等）的基础组件。该模块采用现代化的设计理念，参考了 Rust、Go、Java 等语言的集合框架设计。

## 设计理念

### 高性能优先
- **Record 结构**：使用 `record` 而非 `class`，避免对象开销和堆分配
- **内联方法**：所有关键操作都使用内联以获得最佳性能
- **零成本抽象**：提供高级抽象的同时保持底层性能

### 内存安全
- **集成内存管理**：与现有的 `TAllocator` 和 `TElementManager<T>` 完美集成
- **托管类型支持**：自动处理字符串、接口等托管类型的生命周期
- **异常安全**：确保在异常情况下不会发生内存泄漏

### 现代化设计
- **泛型支持**：支持任意数据类型
- **类型安全**：编译时类型检查，避免运行时错误
- **接口一致性**：提供统一的节点操作接口

### 命名规范
- **遵循项目规范**：严格遵循 fafafa.core 项目的命名规范
- **UnChecked 后缀**：无安全检查的高性能方法使用 `*UnChecked` 后缀
- **性能优先**：`InitUnChecked`、`UnlinkUnChecked` 等方法跳过安全检查以获得最佳性能

## 核心组件

### 1. TSingleLinkedNode<T> - 单向链接节点

单向链接节点是最基础的节点类型，适用于单向链表、栈、队列等数据结构。

```pascal
type
  TSingleLinkedNode<T> = record
    Data: T;              // 节点存储的数据
    Next: Pointer;        // 指向下一个节点的指针
    
    // 标准方法
    procedure Init(const aData: T; aNext: Pointer = nil); inline;
    procedure Clear; inline;
    function GetNext: Pointer; inline;
    procedure SetNext(aNext: Pointer); inline;
    function HasNext: Boolean; inline;

    // 高性能方法（无安全检查）
    procedure InitUnChecked(const aData: T; aNext: Pointer); inline;
  end;
```

**特性：**
- 占用内存最小（只有数据和一个指针）
- 支持单向遍历
- 适合实现栈、队列、单向链表

**使用示例：**
```pascal
var
  Node1, Node2: TSingleLinkedNode<Integer>;
begin
  Node1.Init(100);
  Node2.Init(200);
  Node1.SetNext(@Node2);
  
  // 遍历
  var Current := @Node1;
  while Current <> nil do
  begin
    WriteLn(Current^.Data);
    Current := Pointer(Current^.GetNext);
  end;
end;
```

### 2. TDoubleLinkedNode<T> - 双向链接节点

双向链接节点支持前后双向遍历，适用于双向链表、双端队列等数据结构。

```pascal
type
  TDoubleLinkedNode<T> = record
    Data: T;              // 节点存储的数据
    Prev: Pointer;        // 指向前一个节点的指针
    Next: Pointer;        // 指向下一个节点的指针
    
    // 标准方法
    procedure Init(const aData: T; aPrev: Pointer = nil; aNext: Pointer = nil); inline;
    procedure Clear; inline;
    function GetPrev: Pointer; inline;
    procedure SetPrev(aPrev: Pointer); inline;
    function GetNext: Pointer; inline;
    procedure SetNext(aNext: Pointer); inline;
    function HasPrev: Boolean; inline;
    function HasNext: Boolean; inline;
    procedure Unlink; inline;

    // 高性能方法（无安全检查）
    procedure UnlinkUnChecked; inline;
  end;
```

**特性：**
- 支持双向遍历
- 提供 `Unlink` 方法快速从链表中移除节点
- 适合实现双向链表、LRU 缓存等

**使用示例：**
```pascal
var
  Node1, Node2, Node3: TDoubleLinkedNode<String>;
begin
  Node1.Init('First');
  Node2.Init('Second');
  Node3.Init('Third');
  
  // 连接节点
  Node1.SetNext(@Node2);
  Node2.SetPrev(@Node1);
  Node2.SetNext(@Node3);
  Node3.SetPrev(@Node2);
  
  // 移除中间节点
  Node2.Unlink;  // Node1 和 Node3 现在直接相连
end;
```

### 3. TTreeNode<T> - 树节点

树节点使用 FirstChild-NextSibling 表示法，能够高效地表示任意数量的子节点。

```pascal
type
  TTreeNode<T> = record
    Data: T;              // 节点存储的数据
    Parent: Pointer;      // 指向父节点的指针
    FirstChild: Pointer;  // 指向第一个子节点的指针
    NextSibling: Pointer; // 指向下一个兄弟节点的指针
    
    // 方法
    procedure Init(const aData: T; aParent: Pointer = nil); inline;
    procedure Clear; inline;
    function GetParent: Pointer; inline;
    procedure SetParent(aParent: Pointer); inline;
    function GetFirstChild: Pointer; inline;
    procedure SetFirstChild(aChild: Pointer); inline;
    function GetNextSibling: Pointer; inline;
    procedure SetNextSibling(aSibling: Pointer); inline;
    function IsRoot: Boolean; inline;
    function IsLeaf: Boolean; inline;
    function HasChildren: Boolean; inline;
    function HasSiblings: Boolean; inline;
  end;
```

**特性：**
- 使用 FirstChild-NextSibling 表示法，节省内存
- 支持任意数量的子节点
- 适合实现各种树结构（二叉树、多叉树、Trie 树等）

**使用示例：**
```pascal
var
  Root, Child1, Child2, GrandChild: TTreeNode<String>;
begin
  Root.Init('Root');
  Child1.Init('Child1');
  Child2.Init('Child2');
  GrandChild.Init('GrandChild');
  
  // 构建树结构
  Child1.SetParent(@Root);
  Child2.SetParent(@Root);
  GrandChild.SetParent(@Child1);
  
  Root.SetFirstChild(@Child1);
  Child1.SetNextSibling(@Child2);
  Child1.SetFirstChild(@GrandChild);
  
  // 检查属性
  WriteLn('Root is root: ', Root.IsRoot);
  WriteLn('GrandChild is leaf: ', GrandChild.IsLeaf);
end;
```

### 4. TNodeManager<T> - 节点管理器

节点管理器提供统一的内存管理和节点创建/销毁功能。

```pascal
type
  TNodeManager<T> = class
  public
    constructor Create(aAllocator: TAllocator);
    destructor Destroy; override;
    
    // 单向节点管理
    function CreateSingleNode(const aData: T; aNext: PSingleNode = nil): PSingleNode;
    procedure DestroySingleNode(aNode: PSingleNode);
    
    // 双向节点管理
    function CreateDoubleNode(const aData: T; aPrev: PDoubleNode = nil; aNext: PDoubleNode = nil): PDoubleNode;
    procedure DestroyDoubleNode(aNode: PDoubleNode);
    
    // 树节点管理
    function CreateTreeNode(const aData: T; aParent: PTreeNode = nil): PTreeNode;
    procedure DestroyTreeNode(aNode: PTreeNode);
  end;
```

**特性：**
- 统一的内存管理
- 自动处理托管类型的生命周期
- 支持自定义内存分配器
- 异常安全的节点创建和销毁

## 性能特性

### 内存效率
- **紧凑布局**：节点使用最小的内存占用
- **缓存友好**：数据和指针紧密排列，提高缓存命中率
- **零开销**：直接内存访问，无虚函数调用开销

### 时间复杂度
- **节点操作**：所有基本操作都是 O(1) 时间复杂度
- **内联优化**：关键方法内联，消除函数调用开销
- **编译时优化**：泛型特化，编译器可以进行更好的优化

### 扩展性
- **泛型设计**：支持任意数据类型
- **可组合性**：节点可以组合成复杂的数据结构
- **可扩展性**：易于添加新的节点类型

## 最佳实践

### 1. 选择合适的节点类型
- **单向链接**：用于栈、队列、单向链表
- **双向链接**：用于双向链表、LRU 缓存、双端队列
- **树节点**：用于各种树结构

### 2. 内存管理
- **栈分配**：对于临时节点，直接在栈上分配
- **堆分配**：对于长期存在的节点，使用 `TNodeManager<T>`
- **自定义分配器**：对于特殊需求，使用自定义的 `TAllocator`

### 3. 异常安全
- **RAII 模式**：使用 `TNodeManager<T>` 确保资源正确释放
- **异常处理**：在节点操作中正确处理异常情况

## UnChecked 方法详解

### 概述
UnChecked 方法是遵循项目命名规范的高性能版本，跳过所有安全检查以获得最佳性能。

### 可用的 UnChecked 方法

#### 1. InitUnChecked
```pascal
procedure InitUnChecked(const aData: T; aNext: Pointer); inline;
```
- **用途**：无检查初始化单向链接节点
- **性能**：跳过参数验证，直接赋值
- **使用场景**：性能关键路径，确保参数有效性的情况下

#### 2. UnlinkUnChecked
```pascal
procedure UnlinkUnChecked; inline;
```
- **用途**：无检查断开双向链接节点
- **性能**：减少内存访问次数，提高缓存效率
- **使用场景**：批量操作，确保节点状态正确的情况下

### 使用注意事项
- **安全性**：调用者必须确保参数和节点状态的有效性
- **性能**：这些方法提供最佳性能，适用于性能关键路径
- **调试**：在调试模式下建议使用标准方法以获得更好的错误检测

### 示例
```pascal
// 高性能初始化
Node.InitUnChecked(42, nil);

// 高性能断开连接
DoubleNode.UnlinkUnChecked;
```

## 与现有框架的集成

该模块与 fafafa.core 框架的其他组件完美集成：

- **内存管理**：使用 `fafafa.core.mem.allocator` 进行内存分配
- **元素管理**：使用 `fafafa.core.collections.elementManager` 处理托管类型
- **基础设施**：依赖 `fafafa.core.base` 提供的基础类型和异常

## 未来扩展

计划中的功能扩展：

1. **节点池化**：实现节点对象池以提高性能
2. **遍历算法**：提供标准的树遍历算法（深度优先、广度优先）
3. **序列化支持**：支持节点结构的序列化和反序列化
4. **调试支持**：提供节点结构的可视化调试功能

## 总结

`fafafa.core.collections.node` 模块为 fafafa.core 框架提供了高性能、类型安全、内存高效的节点基础设施。通过现代化的设计和优化，它能够满足各种高性能数据结构的需求，同时保持代码的简洁性和可维护性。
