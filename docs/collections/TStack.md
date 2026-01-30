# TStack - 栈容器使用指南

## 概述

`IStack<T>` 是一个 **LIFO (后进先出)** 泛型栈接口，提供两种实现：

| 实现类 | 底层结构 | 特点 |
|--------|----------|------|
| `TArrayStack<T>` | TVecDeque | 连续内存，缓存友好 |
| `TLinkedStack<T>` | TVecDeque | 与 TArrayStack 相同实现 |

> **推荐**：使用 `MakeArrayStack<T>()` 工厂函数创建，通过 `IStack<T>` 接口访问。

## 快速开始

```pascal
uses
  fafafa.core.collections.stack;

var
  Stack: specialize IStack<Integer>;
begin
  // 创建栈（接口引用计数，自动释放）
  Stack := specialize MakeArrayStack<Integer>();
  
  // 压栈
  Stack.Push(1);
  Stack.Push(2);
  Stack.Push(3);
  
  // 弹栈（LIFO 顺序）
  WriteLn(Stack.Pop);  // 输出: 3
  WriteLn(Stack.Pop);  // 输出: 2
  WriteLn(Stack.Pop);  // 输出: 1
end;
```

## API 参考

### 创建

```pascal
// 空栈
Stack := specialize MakeArrayStack<Integer>();

// 从数组初始化
Stack := specialize MakeArrayStack<Integer>([1, 2, 3]);

// 自定义分配器
Stack := specialize MakeArrayStack<Integer>(MyAllocator);
```

### 核心操作

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `Push(item)` | 压入元素 | O(1) 摊销 |
| `Pop: T` | 弹出元素（空时抛异常） | O(1) |
| `Pop(out item): Boolean` | 安全弹出（空返回 False） | O(1) |
| `Peek: T` | 查看栈顶（空时抛异常） | O(1) |
| `TryPeek(out item): Boolean` | 安全查看（空返回 False） | O(1) |

### 状态查询

| 方法 | 描述 | 复杂度 |
|------|------|--------|
| `IsEmpty: Boolean` | 是否为空 | O(1) |
| `Count: SizeUInt` | 元素数量 | O(1) |
| `Clear` | 清空所有元素 | O(n) |

## 使用模式

### 模式 1：异常语义（确定非空时）

```pascal
// 确定栈非空时，直接使用 Pop/Peek
if not Stack.IsEmpty then
begin
  Top := Stack.Peek;    // 查看栈顶
  Value := Stack.Pop;   // 弹出栈顶
end;
```

### 模式 2：Try 语义（可能为空时）

```pascal
// 处理空栈情况
if Stack.Pop(Value) then
  ProcessValue(Value)
else
  HandleEmpty;
```

### 模式 3：批量压栈

```pascal
// 从数组批量压入
Stack.Push([1, 2, 3, 4, 5]);

// 从指针批量压入
Stack.Push(@Data[0], Length(Data));
```

## 典型应用

### 表达式求值

```pascal
function EvaluatePostfix(const Expr: array of string): Integer;
var
  Stack: specialize IStack<Integer>;
  Token: string;
  A, B: Integer;
begin
  Stack := specialize MakeArrayStack<Integer>();
  
  for Token in Expr do
  begin
    if TryStrToInt(Token, A) then
      Stack.Push(A)
    else begin
      B := Stack.Pop;
      A := Stack.Pop;
      case Token of
        '+': Stack.Push(A + B);
        '-': Stack.Push(A - B);
        '*': Stack.Push(A * B);
        '/': Stack.Push(A div B);
      end;
    end;
  end;
  
  Result := Stack.Pop;
end;
```

### 括号匹配

```pascal
function IsBalanced(const S: string): Boolean;
var
  Stack: specialize IStack<Char>;
  C, Top: Char;
begin
  Stack := specialize MakeArrayStack<Char>();
  
  for C in S do
  begin
    case C of
      '(', '[', '{': Stack.Push(C);
      ')', ']', '}':
        begin
          if not Stack.Pop(Top) then Exit(False);
          if ((C = ')') and (Top <> '(')) or
             ((C = ']') and (Top <> '[')) or
             ((C = '}') and (Top <> '{')) then
            Exit(False);
        end;
    end;
  end;
  
  Result := Stack.IsEmpty;
end;
```

### DFS 遍历（非递归）

```pascal
procedure DFS(Root: TNode);
var
  Stack: specialize IStack<TNode>;
  Node: TNode;
begin
  if Root = nil then Exit;
  
  Stack := specialize MakeArrayStack<TNode>();
  Stack.Push(Root);
  
  while not Stack.IsEmpty do
  begin
    Node := Stack.Pop;
    Process(Node);
    
    // 注意：先压右子树，再压左子树（LIFO 会先处理左）
    if Node.Right <> nil then Stack.Push(Node.Right);
    if Node.Left <> nil then Stack.Push(Node.Left);
  end;
end;
```

## 异常处理

| 异常 | 触发条件 |
|------|----------|
| `EEmptyCollection` | 对空栈调用 `Pop` 或 `Peek` |
| `EOutOfMemory` | 内存分配失败 |

**推荐**：在不确定栈状态时，使用 Try 版本方法：

```pascal
// 安全弹出
if Stack.Pop(Value) then
  // 处理 Value
  
// 安全查看
if Stack.TryPeek(Value) then
  // 使用 Value
```

## 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|-----------|-----------|
| Push | O(1) 摊销 | O(1) |
| Pop | O(1) | O(1) |
| Peek | O(1) | O(1) |
| IsEmpty | O(1) | O(1) |
| Clear | O(n) | O(1) |

> **注意**：Push 在扩容时为 O(n)，但摊销后为 O(1)。

## TArrayStack vs TLinkedStack

当前两种实现实际使用相同的底层结构（TVecDeque），因此性能特征相同。

**选择建议**：
- 通用场景：使用 `MakeArrayStack<T>()`
- 接口引用：通过 `IStack<T>` 使用，便于依赖注入

## 相关容器

| 容器 | 场景 |
|------|------|
| `IQueue<T>` | FIFO 语义 |
| `TVecDeque<T>` | 双端操作 |
| `TPriorityQueue<T>` | 优先级出队 |

## 最佳实践

1. **优先使用接口类型**
   ```pascal
   var Stack: specialize IStack<Integer>;  // ✅ 推荐
   var Stack: specialize TArrayStack<Integer>;  // ❌ 不推荐
   ```

2. **使用工厂函数创建**
   ```pascal
   Stack := specialize MakeArrayStack<Integer>();  // ✅ 推荐
   Stack := specialize TArrayStack<Integer>.Create;  // ❌ 需要手动释放
   ```

3. **处理空栈情况**
   ```pascal
   // ✅ 安全方式
   if Stack.Pop(Value) then Process(Value);
   
   // ⚠️ 需要先检查
   if not Stack.IsEmpty then Value := Stack.Pop;
   ```
