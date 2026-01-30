# fafafa.core.mem 快速入门指南

## 🚀 5分钟快速上手

### 第一步：编译测试程序

```batch
# Windows
tests\fafafa.core.mem\BuildOrTest.bat
```

```bash
# Linux/macOS
bash tests/fafafa.core.mem/BuildOrTest.sh
```

### 第二步：运行基本测试

```batch
# Windows
tests\fafafa.core.mem\BuildOrTest.bat test
```

```bash
# Linux/macOS
bash tests/fafafa.core.mem/BuildOrTest.sh
```

### 第三步：查看示例代码

```pascal
program quick_example;
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
uses SysUtils, fafafa.core.mem.memPool, fafafa.core.mem.stats;

var
  LPool: TMemPool;
  LPtr: Pointer;
  LStats: TMemPoolStats;
begin
  // 创建64字节块的内存池，容量10个
  LPool := TMemPool.Create(64, 10);
  try
    // 分配内存
    LPtr := LPool.Alloc;
    if LPtr <> nil then
    begin
      // 使用内存...
      WriteLn('内存分配成功！');

      LStats := GetMemPoolStats(LPool);
      WriteLn('已分配: ', LStats.AllocatedCount, '/', LStats.Capacity);

      // 释放内存
      LPool.ReleasePtr(LPtr);
      WriteLn('内存释放成功！');
    end;
  finally
    LPool.Free;
  end;
end.
```

## 📋 三种内存池快速对比

### 1. TMemPool - 固定大小池
```pascal
// 适用：频繁分配相同大小的对象
LPool := TMemPool.Create(64, 100);  // 64字节，100个容量
LPtr := LPool.Alloc;                // O(1)分配
LPool.ReleasePtr(LPtr);                   // O(1)释放
```

### 2. TStackPool - 栈式池
```pascal
// 适用：临时对象，批量释放
LPool := TStackPool.Create(4096);   // 4KB栈
LPtr1 := LPool.Alloc(100);          // 顺序分配
LPtr2 := LPool.Alloc(200);          
LPool.Reset;                        // 批量释放所有
```

### 3. TSlabPool - nginx风格池
```pascal
// 适用：不同大小对象，高性能
LPool := TSlabPool.Create(8192);    // 2个页面
LPtr1 := LPool.Alloc(64);           // 64字节
LPtr2 := LPool.Alloc(256);          // 256字节
LPool.ReleasePtr(LPtr1);                  // 单独释放
LPool.ReleasePtr(LPtr2);
```

## 🎯 选择指南

**什么时候用 TMemPool？**
- ✅ 分配固定大小对象（如节点、记录）
- ✅ 需要控制内存使用量
- ✅ 频繁分配/释放相同大小内存

**什么时候用 TStackPool？**
- ✅ 临时计算需要大量内存
- ✅ 解析器、编译器等场景
- ✅ 需要批量释放内存

**什么时候用 TSlabPool？**
- ✅ 需要分配不同大小的对象
- ✅ 服务器程序、网络应用
- ✅ 需要详细的统计信息

## 🔧 常见问题

### Q: 编译失败怎么办？
A: 检查FPC编译器是否安装，运行 `fpc -h` 验证

### Q: 程序运行没有输出？
A: 可能是环境问题，尝试在不同环境下运行

### Q: 如何选择合适的内存池？
A: 参考上面的选择指南，或查看完整的使用指南文档

### Q: 性能如何？
A: 运行 `tests\fafafa.core.mem\VerifyImprovements.bat`，或手动执行 `tests\fafafa.core.mem\bin\tests_mem_debug.exe --suite=TTestCase_SlabPool_PerformanceBenchmark --format=plain` 查看性能对比（Linux/macOS 用 `/` 路径）

### Q: 如何检测内存泄漏？
A: 使用 Debug 模式运行测试（heaptrc 启用），例如 `tests\fafafa.core.mem\BuildOrTest.bat test` 或 `bash tests/fafafa.core.mem/BuildOrTest.sh`

## 📚 下一步

1. **阅读完整文档**
   - [架构文档](fafafa.core.mem.architecture.md)
   - [使用指南](fafafa.core.mem.usage-guide.md)

2. **运行更多测试/示例**
   - 性能对比：`tests\fafafa.core.mem\VerifyImprovements.bat`（或 `tests\fafafa.core.mem\bin\tests_mem_debug.exe --suite=TTestCase_SlabPool_PerformanceBenchmark --format=plain`）
   - 示例构建运行：`examples\fafafa.core.mem\BuildAndRun.bat debug run`（Linux/macOS 用 `./BuildAndRun.sh`）
   - 进阶示例：`examples\fafafa.core.mem/example_mem_pool_basic.lpr`（包含 MemPool/StackPool/SlabPool）

3. **集成到项目**
   - 添加 `src` 目录到编译路径
   - 引用需要的模块：`fafafa.core.mem`, `fafafa.core.mem.memPool` 等

## 💡 最佳实践

1. **及时释放资源**
```pascal
LPool := TMemPool.Create(64, 100);
try
  // 使用内存池...
finally
  LPool.Free;  // 确保释放
end;
```

2. **检查分配结果**
```pascal
LPtr := LPool.Alloc;
if LPtr <> nil then
begin
  // 使用内存...
  LPool.ReleasePtr(LPtr);
end;
```

3. **合理设置容量**
```pascal
// 根据实际需求设置，不要过大或过小
LPool := TMemPool.Create(64, 1000);
```

4. **监控内存使用**
```pascal
LMemStats := GetMemPoolStats(LMemPool);
LBlockStats := GetBlockPoolStats(LBlockPool);
LSlabStats := GetSlabPoolStats(LSlabPool);
LSlabPerf := LSlabPool.GetPerfCounters;

WriteLn('MemPool: ', LMemStats.AllocatedCount, '/', LMemStats.Capacity);
WriteLn('BlockPool: ', LBlockStats.InUse, '/', LBlockStats.Capacity);
WriteLn('Slab: ', LSlabStats.FallbackAllocCount, ' fallback, ', LSlabPerf.AllocCalls, ' allocs');
```

现在你已经掌握了 `fafafa.core.mem` 的基本使用方法！🎉
