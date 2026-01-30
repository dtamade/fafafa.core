# fafafa.core.mem 用户手册

## 📖 完整使用指南

### 🚀 快速开始

#### 1. 环境准备
```bash
# 确保安装了 Free Pascal Compiler
fpc -h

# 确保项目依赖存在
ls src/fafafa.core.base.pas
ls src/fafafa.core.mem.utils.pas
ls src/fafafa.core.mem.allocator.pas
```

#### 2. 构建测试
```batch
# Windows
cd tests\fafafa.core.mem
tests\fafafa.core.mem\BuildOrTest.bat
```

```bash
# Linux/macOS
cd tests/fafafa.core.mem
bash BuildOrTest.sh
```

#### 3. 运行测试
```batch
# Windows
tests\fafafa.core.mem\BuildOrTest.bat test
```

```bash
# Linux/macOS
bash tests/fafafa.core.mem/BuildOrTest.sh
```

### 📋 模块选择指南

#### TMemPool - 固定大小内存池
**适用场景:**
- 频繁分配相同大小的对象
- 需要控制内存使用量
- 对象生命周期相对独立

**使用示例:**
```pascal
uses
  fafafa.core.mem.memPool;

var
  LPool: TMemPool;
  LPtr: Pointer;
begin
  LPool := TMemPool.Create(64, 10);
  try
    LPtr := LPool.Alloc;
    if LPtr <> nil then
      LPool.ReleasePtr(LPtr);
  finally
    LPool.Destroy;
  end;
end;
```

#### TStackPool - 栈式内存池
**适用场景:**
- 临时计算需要大量内存
- 解析器、编译器等场景
- 需要批量释放内存

**使用示例:**
```pascal
var
  LPool: TStackPool;
  LBuffer: PChar;
  LState: SizeUInt;
begin
  LPool := TStackPool.Create(64 * 1024); // 64KB
  try
    // 保存状态
    LState := LPool.SaveState;
    
    // 分配临时缓冲区
    LBuffer := PChar(LPool.Alloc(1024));
    if LBuffer <> nil then
    begin
      // 使用缓冲区...
    end;
    
    // 恢复状态（批量释放）
    LPool.RestoreState(LState);
  finally
    LPool.Free;
  end;
end;
```

#### TSlabPool - nginx风格Slab池
**适用场景:**
- 需要分配不同大小的对象
- 服务器程序、网络应用
- 需要详细的统计信息

**使用示例:**
```pascal
uses
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.stats;

var
  LPool: TSlabPool;
  LSmallPtr, LLargePtr: Pointer;
  LStats: TSlabPoolStats;
  LPerf: TSlabPerfCounters;
begin
  LPool := TSlabPool.Create(16 * 1024); // 16KB
  try
    // 分配不同大小
    LSmallPtr := LPool.Alloc(64);
    LLargePtr := LPool.Alloc(512);
    
    if (LSmallPtr <> nil) and (LLargePtr <> nil) then
    begin
      // 使用内存...
      
      // 单独释放
      LPool.ReleasePtr(LSmallPtr);
      LPool.ReleasePtr(LLargePtr);
    end;
    
    // 查看统计
    LStats := GetSlabPoolStats(LPool);
    LPerf := LPool.GetPerfCounters;
    WriteLn('容量: ', LStats.TotalUsed, '/', LStats.TotalCapacity);
    WriteLn('Fallback: ', LStats.FallbackAllocCount);
    WriteLn('分配/释放: ', LPerf.AllocCalls, '/', LPerf.FreeCalls);
  finally
    LPool.Destroy;
  end;
end;
```


### 🎯 性能优化建议

#### 1. 选择合适的内存池
```pascal
// 固定大小对象 -> TMemPool
LNodePool := TMemPool.Create(SizeOf(TNode), 1000);

// 临时计算 -> TStackPool  
LTempPool := TStackPool.Create(64 * 1024);

// 多种大小 -> TSlabPool
LGeneralPool := TSlabPool.Create(256 * 1024);
```

#### 2. 合理设置容量
```pascal
// 根据实际需求设置，避免过大或过小
LPool := TMemPool.Create(64, 100);  // 100个64字节块

// 栈池设置足够大小
LStackPool := TStackPool.Create(1024 * 1024); // 1MB

// Slab池按页面大小设置
LSlabPool := TSlabPool.Create(64 * 4096); // 64个页面
```

#### 3. 及时释放资源
```pascal
LPool := TMemPool.Create(32, 50);
try
  // 使用内存池...
finally
  LPool.Free; // 确保释放
end;
```

### 🔧 调试和监控

#### 1. 运行单测（含 heaptrc）
```batch
# Windows
tests\fafafa.core.mem\BuildOrTest.bat test
```

```bash
# Linux/macOS
bash tests/fafafa.core.mem/BuildOrTest.sh
```

#### 2. 性能对比
```batch
# Windows
tests\fafafa.core.mem\VerifyImprovements.bat
```

```bash
# Linux/macOS
tests/fafafa.core.mem/bin/tests_mem_debug --suite=TTestCase_SlabPool_PerformanceBenchmark --format=plain
```

#### 3. 示例运行
```batch
# Windows
examples\fafafa.core.mem\BuildAndRun.bat debug run
```

```bash
# Linux/macOS
./examples/fafafa.core.mem/BuildAndRun.sh debug run
```

### 📊 监控和统计

> 统计快照使用 `fafafa.core.mem.stats`（只读，不改变池行为）

#### TMemPool 统计
```pascal
LMemStats := GetMemPoolStats(LMemPool);
WriteLn('块大小: ', LMemStats.BlockSize);
WriteLn('容量: ', LMemStats.Capacity);
WriteLn('已分配: ', LMemStats.AllocatedCount);
WriteLn('可用: ', LMemStats.AvailableCount);
WriteLn('利用率: ', LMemStats.Utilization:0:2);
```

#### TStackPool 统计
```pascal
LStackStats := GetStackPoolStats(LStackPool);
WriteLn('总大小: ', LStackStats.TotalSize);
WriteLn('已用大小: ', LStackStats.UsedSize);
WriteLn('可用大小: ', LStackStats.AvailableSize);
WriteLn('利用率: ', LStackStats.Utilization:0:2);
```

#### TSlabPool 统计
```pascal
LSlabStats := GetSlabPoolStats(LSlabPool);
LSlabPerf := LSlabPool.GetPerfCounters;

WriteLn('容量: ', LSlabStats.TotalUsed, '/', LSlabStats.TotalCapacity);
WriteLn('Fallback: ', LSlabStats.FallbackAllocCount);
WriteLn('分配/释放: ', LSlabPerf.AllocCalls, '/', LSlabPerf.FreeCalls);
```

### ⚠️ 注意事项

#### 1. 内存对齐
```pascal
// 所有内存池都会自动处理内存对齐
// 无需手动处理对齐问题
```

#### 2. 线程安全
```pascal
// 基础池默认非线程安全；并发场景请使用 concurrent/sharded 版本或外部锁
```

#### 3. 错误处理
```pascal
LPtr := LPool.Alloc;
if LPtr = nil then
begin
  // 处理分配失败
  WriteLn('内存分配失败');
  Exit;
end;
```

#### 4. 重复释放
```pascal
// 避免重复释放，同一指针只释放一次
LPool.ReleasePtr(LPtr);
LPtr := nil; // 清空引用，防止误用
```

### 🛠️ 故障排除

#### 编译问题
1. 检查FPC版本：`fpc -h`
2. 检查依赖模块是否存在
3. 使用提供的构建脚本

#### 运行问题
1. 检查可执行文件是否生成
2. 确认运行时库完整
3. 查看测试日志了解详细错误

#### 性能问题
1. 选择合适的内存池类型
2. 调整容量设置
3. 运行性能对比：tests\fafafa.core.mem\VerifyImprovements.bat 或 tests_mem_debug 性能套件

### 📞 获取帮助

1. **查看文档** - docs/ 目录下的完整文档
2. **运行示例** - examples/fafafa.core.mem/ 目录
3. **查看测试** - 了解正确的使用方式
4. **联系作者** - dtamade@gmail.com

这个用户手册提供了完整的使用指导，帮助您充分利用 fafafa.core.mem 的强大功能！
