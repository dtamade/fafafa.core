# fafafa.core.mem.slabPool - nginx风格实现

## 📋 概述

根据您的指导，重新实现了参考 nginx 的 slab 分配器。这个实现采用了 nginx 的核心设计理念，提供高效的页面管理和多大小类别支持。

## 🏗️ nginx 设计特点

### 1. 页面管理
- **页面大小**: 4KB (4096字节)
- **页面对齐**: 所有分配都基于页面边界
- **页面数组**: 统一管理所有页面的元数据

### 2. 大小类别
nginx 使用预定义的大小类别来减少内存碎片：
```
8, 16, 32, 64, 128, 256, 512, 1024, 2048 字节
```

### 3. 位图管理
每个页面使用位图来跟踪已分配的块：
- 1 bit = 1 个对象
- 快速查找空闲位
- O(1) 设置和清除操作

### 4. 链表管理
- **空闲页面链表**: 未使用的页面
- **大小类别链表**: 每个大小类别维护自己的页面链表

## 🔧 核心数据结构

### TSlabPage
```pascal
TSlabPage = record
  Slab: PtrUInt;             // 位图，标记已使用的块
  Next: PSlabPage;           // 下一个页面
  Prev: PSlabPage;           // 上一个页面
  SizeClass: Byte;           // 大小类别索引
end;
```

### TSlabPool
```pascal
TSlabPool = class
private
  FStart: Pointer;           // 内存池起始地址
  FEnd: Pointer;             // 内存池结束地址
  FSize: SizeUInt;           // 内存池大小
  FBaseAllocator: TAllocator;

  FPages: PSlabPage;         // 页面数组
  FPageCount: SizeUInt;      // 页面数量
  FFreePages: PSlabPage;     // 空闲页面链表

  // 大小类别的页面链表
  FSlots: array[0..SLAB_SIZE_CLASSES-1] of PSlabPage;
  FSizes: array[0..SLAB_SIZE_CLASSES-1] of SizeUInt;

  // 统计信息
  FTotalAllocs: SizeUInt;
  FTotalFrees: SizeUInt;
  FFailedAllocs: SizeUInt;
```

## 🚀 核心算法

### 分配算法
1. **大小类别映射**: 将请求大小映射到合适的大小类别
2. **页面查找**: 在对应大小类别中查找有空闲空间的页面
3. **位图搜索**: 在页面的位图中查找空闲位
4. **地址计算**: 根据页面地址和位索引计算最终地址

### 释放算法
1. **页面定位**: 根据指针地址计算页面索引
2. **位图更新**: 清除对应的位
3. **页面管理**: 如果页面变空，可以释放回空闲链表

## 📊 性能特点

### 时间复杂度
- **分配**: O(1) - 位图查找和地址计算都是常数时间
- **释放**: O(1) - 直接地址计算和位图操作
- **页面管理**: O(1) - 链表操作

### 空间效率
- **内存对齐**: 所有分配都是对齐的
- **碎片减少**: 大小类别设计减少内部碎片
- **元数据开销**: 每页面只需要一个 TSlabPage 结构

## 🎯 使用示例

### 基本使用
```pascal
var
  LPool: TSlabPool;
  LPtr: Pointer;
begin
  LPool := TSlabPool.Create(8192); // 2个页面
  try
    LPtr := LPool.Alloc(64);  // 分配64字节
    // 使用内存...
    LPool.Free(LPtr);         // 释放内存
  finally
    LPool.Free;
  end;
end;
```

### 多大小分配
```pascal
var
  LPool: TSlabPool;
  LPtrs: array[0..3] of Pointer;
begin
  LPool := TSlabPool.Create(16384); // 4个页面
  try
    LPtrs[0] := LPool.Alloc(8);    // 8字节类别
    LPtrs[1] := LPool.Alloc(64);   // 64字节类别
    LPtrs[2] := LPool.Alloc(256);  // 256字节类别
    LPtrs[3] := LPool.Alloc(1024); // 1024字节类别
    
    // 使用内存...
    
    // 释放所有内存
    LPool.Free(LPtrs[0]);
    LPool.Free(LPtrs[1]);
    LPool.Free(LPtrs[2]);
    LPool.Free(LPtrs[3]);
  finally
    LPool.Free;
  end;
end;
```

### 统计信息
```pascal
var
  LPool: TSlabPool;
begin
  LPool := TSlabPool.Create(4096);
  try
    // 进行一些分配和释放操作...
    
    WriteLn('总分配次数: ', LPool.TotalAllocs);
    WriteLn('总释放次数: ', LPool.TotalFrees);
    WriteLn('失败次数: ', LPool.FailedAllocs);
    WriteLn('池大小: ', LPool.PoolSize);
    WriteLn('页面数: ', LPool.PageCount);
  finally
    LPool.Free;
  end;
end;
```

## 🔍 与原版 nginx 的对比

### 相似之处
1. **页面管理**: 都使用4KB页面作为基本单位
2. **大小类别**: 都使用预定义的大小类别
3. **位图管理**: 都使用位图跟踪空闲块
4. **链表结构**: 都使用链表管理页面

### 简化之处
1. **内存池**: 使用预分配的内存池而不是系统内存映射
2. **统计信息**: 简化的统计信息收集
3. **线程安全**: 当前版本不包含线程同步
4. **内存回收**: 简化的页面回收策略

## 🎯 适用场景

1. **高性能服务器**: 需要频繁分配不同大小对象
2. **内存池应用**: 预知内存使用模式的应用
3. **减少碎片**: 需要减少内存碎片的场景
4. **统计监控**: 需要详细内存使用统计的场景

## 🔮 扩展方向

1. **线程安全**: 添加线程同步支持
2. **动态扩展**: 支持内存池动态扩展
3. **内存回收**: 更智能的页面回收策略
4. **性能优化**: 进一步优化位图搜索算法

这个 nginx 风格的实现为 fafafa 框架提供了工业级的内存管理能力，兼顾了性能和内存效率。
