# fafafa.core.mem 使用指南

## 概述

`fafafa.core.mem` 是 fafafa.core 框架的内存管理模块，提供：
- 统一的分配器接口（IAllocator）
- 多种内存池实现（Slab、Fixed、Growing Arena、Object Pool）
- 高性能内存分配策略
- 零碎片内存管理

## 快速入门

### 1. 使用 RTL 分配器

```pascal
uses
  fafafa.core.mem.allocator;

var
  Allocator: IAllocator;
  Ptr: Pointer;
begin
  // 获取 RTL 分配器（使用 FreePascal 的 GetMem/FreeMem）
  Allocator := GetRtlAllocator;

  // 分配内存
  Ptr := Allocator.GetMem(1024);
  try
    // 使用内存...
  finally
    Allocator.FreeMem(Ptr);
  end;
end;
```

### 2. 使用 Slab 内存池

```pascal
uses
  fafafa.core.mem.pool.slab;

var
  Pool: TSlabPool;
  Ptr: Pointer;
begin
  // 创建 Slab 池（初始容量 4KB）
  Pool := TSlabPool.Create(4096);
  try
    // 分配小对象（64 字节）
    Ptr := Pool.GetMem(64);
    try
      // 使用内存...
    finally
      Pool.FreeMem(Ptr);
    end;
  finally
    Pool.Free;
  end;
end;
```

### 3. 使用 Growing Arena

```pascal
uses
  fafafa.core.mem.arena.growable,
  fafafa.core.mem.layout;

var
  Arena: TGrowingArena;
  Config: TGrowingArenaConfig;
  Ptr1, Ptr2: Pointer;
  Mark: TArenaMarker;
begin
  // 创建 Arena（几何增长策略）
  Config := TGrowingArenaConfig.Default(4096);
  Config.GrowthKind := agkGeometric;
  Config.GrowthFactor := 2.0;
  Arena := TGrowingArena.Create(Config);
  try
    // 快速分配多个对象
    Ptr1 := Arena.Alloc(TMemLayout.Create(64, 8)).Ptr;
    Ptr2 := Arena.Alloc(TMemLayout.Create(128, 16)).Ptr;

    // 保存标记点
    Mark := Arena.SaveMark;

    // 更多分配...

    // 恢复到标记点（批量释放）
    Arena.RestoreToMark(Mark);

    // 或者重置整个 Arena
    Arena.Reset;
  finally
    Arena.Free;
  end;
end;
```

### 4. 使用对象池

```pascal
uses
  fafafa.core.mem.pool.objectPool;

type
  TConnection = class
    Host: string;
    Port: Integer;
    procedure Connect;
    procedure Disconnect;
  end;

var
  Pool: specialize TObjectPool<TConnection>;
  Conn: TConnection;
begin
  // 创建对象池（使用 Builder 模式）
  Pool := specialize TObjectPool<TConnection>.Create(
    specialize TObjectPool<TConnection>.TConfig.Default
      .WithMaxSize(10)
      .WithCreator(
        function: TConnection
        begin
          Result := TConnection.Create;
        end)
      .WithInit(
        procedure(C: TConnection)
        begin
          C.Connect;
        end)
      .WithFinalize(
        procedure(C: TConnection)
        begin
          C.Disconnect;
        end)
  );
  try
    // 获取对象
    if Pool.AcquireObject(Conn) then
    begin
      try
        // 使用连接...
      finally
        Pool.ReleaseObject(Conn);
      end;
    end;
  finally
    Pool.Free;
  end;
end;
```

## 常见使用场景

### 场景 1: 频繁分配小对象（使用 Slab Pool）

```pascal
type
  TNode = record
    Value: Integer;
    Next: Pointer;
  end;
  PNode = ^TNode;

var
  Pool: TSlabPool;
  Node: PNode;
  I: Integer;
begin
  // 创建 Slab 池
  Pool := TSlabPool.Create(8192);
  try
    // 频繁分配节点
    for I := 1 to 1000 do
    begin
      Node := PNode(Pool.GetMem(SizeOf(TNode)));
      Node^.Value := I;
      // 使用节点...
    end;

    // 批量释放（重置池）
    Pool.Reset;
  finally
    Pool.Free;
  end;
end;
```

### 场景 2: 临时对象批量分配（使用 Growing Arena）

```pascal
// 编译器 AST 节点的临时分配
type
  TASTNode = record
    NodeType: Integer;
    Value: string;
    Children: array of Pointer;
  end;
  PASTNode = ^TASTNode;

procedure ParseExpression(Arena: TGrowingArena);
var
  Node: PASTNode;
  Mark: TArenaMarker;
begin
  // 保存标记点
  Mark := Arena.SaveMark;
  try
    // 分配 AST 节点
    Node := PASTNode(Arena.Alloc(TMemLayout.Create(SizeOf(TASTNode), 8)).Ptr);
    Node^.NodeType := 1;
    Node^.Value := 'expression';

    // 解析子表达式...

    // 如果解析失败，恢复到标记点
    if ParseFailed then
      Arena.RestoreToMark(Mark);
  except
    // 异常时恢复
    Arena.RestoreToMark(Mark);
    raise;
  end;
end;
```

### 场景 3: 数据库连接池（使用 Object Pool）

```pascal
type
  TDBConnection = class
  private
    FConnected: Boolean;
  public
    Host: string;
    Port: Integer;
    Database: string;
    procedure Connect;
    procedure Disconnect;
    function ExecuteQuery(const SQL: string): Boolean;
  end;

var
  ConnectionPool: specialize TObjectPool<TDBConnection>;

procedure InitializeConnectionPool;
begin
  ConnectionPool := specialize TObjectPool<TDBConnection>.Create(
    specialize TObjectPool<TDBConnection>.TConfig.Default
      .WithMaxSize(20)  // 最多 20 个连接
      .WithCreator(
        function: TDBConnection
        begin
          Result := TDBConnection.Create;
          Result.Host := 'localhost';
          Result.Port := 5432;
          Result.Database := 'mydb';
        end)
      .WithInit(
        procedure(Conn: TDBConnection)
        begin
          Conn.Connect;  // 获取时自动连接
        end)
      .WithFinalize(
        procedure(Conn: TDBConnection)
        begin
          // 释放时不断开连接，保持连接池
        end)
  );
end;

procedure ExecuteDatabaseQuery(const SQL: string);
var
  Conn: TDBConnection;
begin
  if ConnectionPool.AcquireObject(Conn) then
  begin
    try
      Conn.ExecuteQuery(SQL);
    finally
      ConnectionPool.ReleaseObject(Conn);
    end;
  end
  else
    raise Exception.Create('No available connections');
end;
```

### 场景 4: 固定大小块分配（使用 Fixed Pool）

```pascal
uses
  fafafa.core.mem.pool.fixed;

type
  TMessage = record
    ID: Integer;
    Timestamp: Int64;
    Data: array[0..255] of Byte;
  end;
  PMessage = ^TMessage;

var
  MessagePool: TFixedPool;
  Msg: PMessage;
begin
  // 创建固定块池（256 字节块，容量 1000）
  MessagePool := TFixedPool.Create(SizeOf(TMessage), 1000);
  try
    // 分配消息
    Msg := PMessage(MessagePool.Alloc);
    if Msg <> nil then
    begin
      Msg^.ID := 1;
      Msg^.Timestamp := GetTickCount64;
      // 使用消息...

      // 释放消息
      MessagePool.ReleasePtr(Msg);
    end;
  finally
    MessagePool.Free;
  end;
end;
```

## 最佳实践

### 1. 选择合适的内存池

✅ **推荐做法**：
```pascal
// 小对象频繁分配 -> Slab Pool
if ObjectSize <= 2048 then
  Pool := TSlabPool.Create(InitialCapacity);

// 临时对象批量分配 -> Growing Arena
if TemporaryObjects then
  Arena := TGrowingArena.Create(InitialSize);

// 固定大小对象 -> Fixed Pool
if FixedSizeObjects then
  Pool := TFixedPool.Create(ObjectSize, Capacity);

// 可重用对象 -> Object Pool
if ReusableObjects then
  Pool := TObjectPool<T>.Create(Config);
```

❌ **避免做法**：
```pascal
// 不要为大对象使用 Slab Pool
Pool := TSlabPool.Create(1024);
Ptr := Pool.GetMem(10 * 1024 * 1024);  // 太大，应该使用标准分配器

// 不要为长期对象使用 Arena
Arena := TGrowingArena.Create(4096);
GlobalData := Arena.Alloc(...);  // Arena 适合临时对象
```

### 2. 内存池生命周期管理

✅ **推荐做法**：
```pascal
// 使用 try-finally 确保释放
var
  Pool: TSlabPool;
begin
  Pool := TSlabPool.Create(4096);
  try
    // 使用池...
  finally
    Pool.Free;
  end;
end;

// 或者使用接口自动管理
var
  Allocator: IAllocator;
begin
  Allocator := GetRtlAllocator;
  // 使用 Allocator...
  // 自动释放
end;
```

❌ **避免做法**：
```pascal
// 不要忘记释放池
Pool := TSlabPool.Create(4096);
// 使用池...
// 忘记 Pool.Free; - 内存泄漏！
```

### 3. Arena 标记使用

✅ **推荐做法**：
```pascal
// 使用标记进行嵌套分配
procedure ProcessData(Arena: TGrowingArena);
var
  Mark: TArenaMarker;
begin
  Mark := Arena.SaveMark;
  try
    // 临时分配...
    ProcessSubData(Arena);
  finally
    Arena.RestoreToMark(Mark);  // 确保恢复
  end;
end;
```

❌ **避免做法**：
```pascal
// 不要忘记恢复标记
Mark := Arena.SaveMark;
// 分配...
// 忘记 Arena.RestoreToMark(Mark); - 内存泄漏！
```

### 4. 对象池配置

✅ **推荐做法**：
```pascal
// 使用 Builder 模式配置
Pool := TObjectPool<T>.Create(
  TObjectPool<T>.TConfig.Default
    .WithMaxSize(100)
    .WithCreator(@CreateObject)
    .WithInit(@InitObject)
    .WithFinalize(@FinalizeObject)
);

// 提供有意义的回调
function CreateConnection: TConnection;
begin
  Result := TConnection.Create;
  Result.Timeout := 30;
end;
```

❌ **避免做法**：
```pascal
// 不要使用空回调
Pool := TObjectPool<T>.Create(
  TObjectPool<T>.TConfig.Default
    .WithCreator(nil)  // 错误！必须提供创建函数
);
```

## 常见陷阱和解决方案

### 陷阱 1: 忘记释放内存

❌ **问题代码**：
```pascal
var
  Pool: TSlabPool;
  Ptr: Pointer;
begin
  Pool := TSlabPool.Create(4096);
  Ptr := Pool.GetMem(64);
  // 使用 Ptr...
  Pool.Free;  // 忘记释放 Ptr！
end;
```

✅ **解决方案**：
```pascal
var
  Pool: TSlabPool;
  Ptr: Pointer;
begin
  Pool := TSlabPool.Create(4096);
  try
    Ptr := Pool.GetMem(64);
    try
      // 使用 Ptr...
    finally
      Pool.FreeMem(Ptr);  // 确保释放
    end;
  finally
    Pool.Free;
  end;
end;
```

### 陷阱 2: Arena 标记混乱

❌ **问题代码**：
```pascal
var
  Arena: TGrowingArena;
  Mark1, Mark2: TArenaMarker;
begin
  Arena := TGrowingArena.Create(4096);
  Mark1 := Arena.SaveMark;
  // 分配...
  Mark2 := Arena.SaveMark;
  // 分配...
  Arena.RestoreToMark(Mark1);  // 跳过 Mark2，可能导致问题
end;
```

✅ **解决方案**：
```pascal
var
  Arena: TGrowingArena;
  Mark1, Mark2: TArenaMarker;
begin
  Arena := TGrowingArena.Create(4096);
  Mark1 := Arena.SaveMark;
  try
    // 分配...
    Mark2 := Arena.SaveMark;
    try
      // 分配...
    finally
      Arena.RestoreToMark(Mark2);  // 先恢复内层标记
    end;
  finally
    Arena.RestoreToMark(Mark1);  // 再恢复外层标记
  end;
end;
```

### 陷阱 3: 对象池容量不足

❌ **问题代码**：
```pascal
var
  Pool: specialize TObjectPool<TConnection>;
  Conns: array[0..99] of TConnection;
  I: Integer;
begin
  // 创建容量为 10 的池
  Pool := specialize TObjectPool<TConnection>.Create(
    specialize TObjectPool<TConnection>.TConfig.Default
      .WithMaxSize(10)
  );

  // 尝试获取 100 个连接
  for I := 0 to 99 do
    Pool.AcquireObject(Conns[I]);  // 超过容量后失败
end;
```

✅ **解决方案**：
```pascal
var
  Pool: specialize TObjectPool<TConnection>;
  Conn: TConnection;
begin
  // 设置合适的容量
  Pool := specialize TObjectPool<TConnection>.Create(
    specialize TObjectPool<TConnection>.TConfig.Default
      .WithMaxSize(100)  // 根据实际需求设置
  );

  // 使用完立即释放
  if Pool.AcquireObject(Conn) then
  begin
    try
      // 使用连接...
    finally
      Pool.ReleaseObject(Conn);  // 立即释放，供其他代码使用
    end;
  end;
end;
```

### 陷阱 4: 混用不同分配器

❌ **问题代码**：
```pascal
var
  Pool: TSlabPool;
  Ptr: Pointer;
begin
  Pool := TSlabPool.Create(4096);
  Ptr := Pool.GetMem(64);
  FreeMem(Ptr);  // 错误！使用了 RTL 的 FreeMem
end;
```

✅ **解决方案**：
```pascal
var
  Pool: TSlabPool;
  Ptr: Pointer;
begin
  Pool := TSlabPool.Create(4096);
  Ptr := Pool.GetMem(64);
  Pool.FreeMem(Ptr);  // 正确！使用池的 FreeMem
end;
```

## 性能考虑

### 1. 内存池性能对比

| 内存池类型 | 分配速度 | 释放速度 | 内存开销 | 适用场景 |
|-----------|---------|---------|---------|---------|
| Slab Pool | O(1) | O(1) | 5-10% | 小对象频繁分配 |
| Fixed Pool | O(1) | O(1) | 1-2% | 固定大小对象 |
| Growing Arena | O(1) | O(1) 批量 | 2-5% | 临时对象批量分配 |
| Object Pool | O(1) | O(1) | 8 字节/对象 | 可重用对象 |

### 2. 性能优化建议

✅ **推荐做法**：
```pascal
// 预分配足够的容量
Pool := TSlabPool.Create(64 * 1024);  // 64KB 初始容量

// 批量操作
Arena := TGrowingArena.Create(4096);
for I := 1 to 1000 do
  Ptrs[I] := Arena.Alloc(...);
Arena.Reset;  // 批量释放，比逐个释放快

// 重用对象池
Pool := TObjectPool<T>.Create(Config);
// 长期持有池，重复使用
```

❌ **避免做法**：
```pascal
// 不要频繁创建/销毁池
for I := 1 to 1000 do
begin
  Pool := TSlabPool.Create(4096);  // 每次都创建新池，性能差
  Ptr := Pool.GetMem(64);
  Pool.Free;
end;

// 不要使用过小的初始容量
Pool := TSlabPool.Create(64);  // 太小，会频繁扩展
```

### 3. 内存对齐

```pascal
// SIMD 操作需要对齐内存
var
  Allocator: IAllocator;
  AlignedPtr: Pointer;
begin
  Allocator := GetRtlAllocator;

  // 分配 32 字节对齐的内存（用于 AVX）
  AlignedPtr := Allocator.AllocAligned(256, 32);
  try
    // 使用对齐内存进行 SIMD 操作...
  finally
    Allocator.FreeAligned(AlignedPtr);
  end;
end;
```

## 调试和诊断

### 1. 内存泄漏检测

```pascal
// 使用 HeapTrc 检测泄漏
{$IFDEF DEBUG}
{$DEFINE HEAPTRC}
{$ENDIF}

program MemoryLeakTest;

{$IFDEF HEAPTRC}
uses
  HeapTrc;
{$ENDIF}

var
  Pool: TSlabPool;
begin
  {$IFDEF HEAPTRC}
  SetHeapTraceOutput('heaptrc.log');
  {$ENDIF}

  Pool := TSlabPool.Create(4096);
  try
    // 测试代码...
  finally
    Pool.Free;
  end;
end.
```

### 2. 性能统计

```pascal
var
  Arena: TGrowingArena;
begin
  Arena := TGrowingArena.Create(4096);
  try
    // 使用 Arena...

    // 查看统计信息
    WriteLn('Peak Used: ', Arena.PeakUsed);
    WriteLn('Total Allocs: ', Arena.TotalAllocCount);
    WriteLn('Segment Count: ', Arena.SegmentCount);
  finally
    Arena.Free;
  end;
end;
```

## 相关文档

- [fafafa.core.mem API 参考](fafafa.core.mem.md) - 完整的 API 文档
- [内存管理架构](fafafa.core.mem.architecture.md) - 架构设计文档
- [性能优化指南](fafafa.core.mem.advanced-features.md) - 高级特性和优化

## 总结

`fafafa.core.mem` 提供了多种高性能内存管理策略：

1. **Slab Pool**：适合频繁分配小对象（8B-2048B）
2. **Fixed Pool**：适合固定大小对象，O(1) 分配/释放
3. **Growing Arena**：适合临时对象批量分配，支持标记/恢复
4. **Object Pool**：适合可重用对象，减少创建/销毁开销

选择合适的内存池，遵循最佳实践，可以显著提升应用性能并减少内存碎片。
