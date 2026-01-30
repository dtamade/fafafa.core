# fafafa.core.mem 使用指南

## 📋 概述

`fafafa.core.mem` 是 fafafa 框架的核心内存管理模块，提供统一的内存操作接口和多种高性能内存池实现。

## 🏗️ 模块架构

```
fafafa.core.mem/
├── fafafa.core.mem.pas           # 主门面模块
├── fafafa.core.mem.memPool.pas   # 通用内存池
├── fafafa.core.mem.stackPool.pas # 栈式内存池
└── fafafa.core.mem.pool.slab.pas  # nginx风格Slab分配器
```

## 🚀 快速开始

### 基本内存操作

```pascal
uses
  fafafa.core.mem;

var
  LAllocator: IAllocator;
  LPtr1, LPtr2: Pointer;
begin
  // 获取RTL分配器
  LAllocator := GetRtlAllocator;
  
  // 分配内存
  LPtr1 := LAllocator.GetMem(1024);
  LPtr2 := LAllocator.GetMem(1024);
  
  // 内存操作
  Fill(LPtr1, 1024, $AA);        // 填充
  Copy(LPtr1, LPtr2, 1024);      // 复制
  Zero(LPtr1, 1024);             // 清零
  
  // 比较内存
  if not Equal(LPtr1, LPtr2, 1024) then
    WriteLn('内存内容不同');
  
  // 释放内存
  LAllocator.FreeMem(LPtr1);
  LAllocator.FreeMem(LPtr2);
end;
```

## 🎯 内存池选择指南

### TMemPool - 通用内存池
**适用场景**：
- 频繁分配/释放固定大小对象
- 需要控制内存使用量
- 避免内存碎片

**特点**：
- 预分配固定数量的固定大小块
- O(1) 分配和释放
- 容量限制，防止内存滥用

```pascal
uses
  fafafa.core.mem.memPool;

var
  LPool: TMemPool;
  LPtr: Pointer;
begin
  // 创建64字节块，容量100个
  LPool := TMemPool.Create(64, 100);
  try
    LPtr := LPool.Alloc;
    if LPtr <> nil then
    begin
      // 使用内存...
      LPool.ReleasePtr(LPtr);
    end;
  finally
    LPool.Free;
  end;
end;
```

### TStackPool - 栈式内存池
**适用场景**：
- 临时对象分配
- 需要批量释放
- 解析器、编译器等场景

**特点**：
- 顺序分配，快速释放
- 支持状态保存/恢复
- 支持对齐要求

```pascal
uses
  fafafa.core.mem.stackPool;

var
  LPool: TStackPool;
  LPtr1, LPtr2: Pointer;
  LState: SizeUInt;
begin
  LPool := TStackPool.Create(4096); // 4KB栈
  try
    LPtr1 := LPool.Alloc(100);
    LState := LPool.SaveState;      // 保存状态
    
    LPtr2 := LPool.Alloc(200);
    // 使用内存...
    
    LPool.RestoreState(LState);     // 批量释放
  finally
    LPool.Free;
  end;
end;
```

### TSlabPool - nginx风格Slab分配器
**适用场景**：
- 需要分配不同大小对象
- 高性能服务器程序
- 减少内存碎片

**特点**：
- 基于页面管理 (4KB)
- 9个预定义大小类别
- O(1) 分配和释放
- 详细统计信息

```pascal
uses
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.stats;

var
  LPool: TSlabPool;
  LPtr1, LPtr2: Pointer;
  LStats: TSlabPoolStats;
  LPerf: TSlabPerfCounters;
begin
  LPool := TSlabPool.Create(8192); // 2个页面
  try
    LPtr1 := LPool.Alloc(64);      // 64字节
    LPtr2 := LPool.Alloc(256);     // 256字节
    
    // 使用内存...
    
    LPool.ReleasePtr(LPtr1);
    LPool.ReleasePtr(LPtr2);
    
    // 查看统计
    LStats := GetSlabPoolStats(LPool);
    LPerf := LPool.GetPerfCounters;
    WriteLn('容量: ', LStats.TotalUsed, '/', LStats.TotalCapacity);
    WriteLn('Fallback: ', LStats.FallbackAllocCount);
    WriteLn('分配/释放: ', LPerf.AllocCalls, '/', LPerf.FreeCalls);
  finally
    LPool.Free;
  end;
end;
```

## 📊 性能对比

| 内存池类型 | 分配速度 | 释放速度 | 内存效率 | 适用场景 |
|-----------|---------|---------|---------|---------|
| TMemPool | O(1) | O(1) | 高 | 固定大小对象 |
| TStackPool | O(1) | O(1)批量 | 很高 | 临时对象 |
| TSlabPool | O(1) | O(1) | 高 | 多种大小对象 |

## 🔧 高级用法

### 自定义分配器
```pascal
var
  LCustomAllocator: IAllocator;
  LPool: TMemPool;
begin
  LCustomAllocator := GetCrtAllocator; // 使用CRT分配器
  LPool := TMemPool.Create(128, 50, LCustomAllocator);
  // ...
end;
```

### 内存对齐
```pascal
var
  LPool: TStackPool;
  LPtr: Pointer;
begin
  LPool := TStackPool.Create(4096);
  try
    // 16字节对齐分配
    LPtr := LPool.Alloc(100, 16);
    if IsAligned(LPtr, 16) then
      WriteLn('内存已正确对齐');
  finally
    LPool.Free;
  end;
end;
```

### 批量操作
```pascal
var
  LPool: TMemPool;
  LPtrs: array[0..9] of Pointer;
  I: Integer;
begin
  LPool := TMemPool.Create(32, 20);
  try
    // 批量分配
    for I := 0 to 9 do
      LPtrs[I] := LPool.Alloc;
    
    // 批量释放
    for I := 0 to 9 do
      LPool.Free(LPtrs[I]);
  finally
    LPool.Free;
  end;
end;
```

## 🛡️ 最佳实践

### 1. 选择合适的内存池
- **固定大小对象** → TMemPool
- **临时对象** → TStackPool  
- **多种大小对象** → TSlabPool

### 2. 合理设置容量
```pascal
// 根据实际需求设置容量
LPool := TMemPool.Create(64, 1000); // 不要过大或过小
```

### 3. 及时释放资源
```pascal
LPool := TMemPool.Create(32, 100);
try
  // 使用内存池...
finally
  LPool.Free; // 确保释放
end;
```

### 4. 监控内存使用
```pascal
// 对于SlabPool，定期检查使用率
LSlabStats := GetSlabPoolStats(LSlabPool);
if (LSlabStats.TotalCapacity > 0) and (LSlabStats.TotalUsed * 4 > LSlabStats.TotalCapacity * 3) then
  WriteLn('使用率偏高，考虑增加池大小');
```

### 5. 避免内存泄漏
```pascal
LPtr := LPool.Alloc;
try
  // 使用内存...
finally
  LPool.ReleasePtr(LPtr); // 确保释放
end;
```

## 🚨 注意事项

1. **不要混用分配器**：用哪个池分配的内存就用哪个池释放
2. **检查分配结果**：分配可能失败，要检查返回值
3. **避免重复释放**：同一个指针不要释放多次
4. **内存对齐**：如有对齐要求，使用相应的参数
5. **容量规划**：根据实际需求合理设置池容量

## 🔍 调试技巧

### 内存使用统计
```pascal
// TMemPool
LMemStats := GetMemPoolStats(LMemPool);
WriteLn('已分配: ', LMemStats.AllocatedCount, '/', LMemStats.Capacity);

// TStackPool  
LStackStats := GetStackPoolStats(LStackPool);
WriteLn('已使用: ', LStackStats.UsedSize, '/', LStackStats.TotalSize);

// TSlabPool
LSlabStats := GetSlabPoolStats(LSlabPool);
LSlabPerf := LSlabPool.GetPerfCounters;
WriteLn('容量: ', LSlabStats.TotalUsed, '/', LSlabStats.TotalCapacity);
WriteLn('分配/释放: ', LSlabPerf.AllocCalls, '/', LSlabPerf.FreeCalls);
```

### 内存状态检查
```pascal
if LMemPool.Available = 0 then
  WriteLn('内存池已满，考虑增加容量');
  
if LStackPool.AvailableSize < 1024 then
  WriteLn('栈空间不足');
```

## 📚 扩展阅读

- [架构文档](fafafa.core.mem.architecture.md) - 详细的架构设计
- [nginx风格Slab](fafafa.core.mem.nginx-slab.md) - nginx风格实现详解
- [API参考](../src/fafafa.core.mem.pas) - 完整的API文档

这个使用指南涵盖了 `fafafa.core.mem` 的所有核心功能和最佳实践，帮助开发者高效使用内存管理功能。
