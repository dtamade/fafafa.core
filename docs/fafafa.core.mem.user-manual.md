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
BuildAndTest.bat

# Linux/macOS
cd tests/fafafa.core.mem
chmod +x BuildOrTest.sh
./BuildOrTest.sh
```

#### 3. 运行测试
```batch
# 运行完整测试套件
RunAllTests.bat

# 运行单个测试
..\..\bin\integration_test.exe
```

### 📋 模块选择指南

#### TMemPool - 固定大小内存池
**适用场景:**
- 频繁分配相同大小的对象
- 需要控制内存使用量
- 对象生命周期相对独立

**使用示例:**
```pascal
var
  LPool: TMemPool;
  LNode: PMyNode;
begin
  LPool := TMemPool.Create(SizeOf(TMyNode), 1000);
  try
    LNode := PMyNode(LPool.Alloc);
    if LNode <> nil then
    begin
      // 使用节点...
      LPool.Free(LNode);
    end;
  finally
    LPool.Free;
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
var
  LPool: TSlabPool;
  LSmallPtr, LLargePtr: Pointer;
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
      LPool.Free(LSmallPtr);
      LPool.Free(LLargePtr);
    end;
    
    // 查看统计
    WriteLn('分配: ', LPool.TotalAllocs);
    WriteLn('释放: ', LPool.TotalFrees);
  finally
    LPool.Free;
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

#### 1. 使用内存监控工具
```batch
# 运行内存监控
..\..\bin\memory_monitor.exe
```

#### 2. 检查内存泄漏
```batch
# 运行泄漏检测
..\..\bin\leak_test.exe
```

#### 3. 性能基准测试
```batch
# 运行性能测试
..\..\bin\benchmark.exe
```

#### 4. 压力测试
```batch
# 运行压力测试
..\..\bin\stress_test.exe
```

### 📊 监控和统计

#### TMemPool 统计
```pascal
WriteLn('块大小: ', LMemPool.BlockSize);
WriteLn('容量: ', LMemPool.Capacity);
WriteLn('已分配: ', LMemPool.AllocatedCount);
WriteLn('可用: ', LMemPool.AvailableCount);
WriteLn('是否为空: ', LMemPool.IsEmpty);
WriteLn('是否满: ', LMemPool.IsFull);
```

#### TStackPool 统计
```pascal
WriteLn('总大小: ', LStackPool.TotalSize);
WriteLn('已用大小: ', LStackPool.UsedSize);
WriteLn('可用大小: ', LStackPool.AvailableSize);
WriteLn('是否为空: ', LStackPool.IsEmpty);
WriteLn('是否满: ', LStackPool.IsFull);
```

#### TSlabPool 统计
```pascal
WriteLn('池大小: ', LSlabPool.PoolSize);
WriteLn('页面数: ', LSlabPool.PageCount);
WriteLn('总分配: ', LSlabPool.TotalAllocs);
WriteLn('总释放: ', LSlabPool.TotalFrees);
WriteLn('失败分配: ', LSlabPool.FailedAllocs);
```

### ⚠️ 注意事项

#### 1. 内存对齐
```pascal
// 所有内存池都会自动处理内存对齐
// 无需手动处理对齐问题
```

#### 2. 线程安全
```pascal
// 当前版本不支持多线程
// 在多线程环境下需要外部同步
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
// 所有内存池都能安全处理重复释放
LPool.Free(LPtr);
LPool.Free(LPtr); // 安全，会被忽略
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
3. 运行性能基准测试对比

### 📞 获取帮助

1. **查看文档** - docs/ 目录下的完整文档
2. **运行示例** - tests/fafafa.core.mem/examples/ 目录
3. **查看测试** - 了解正确的使用方式
4. **联系作者** - dtamade@gmail.com

这个用户手册提供了完整的使用指导，帮助您充分利用 fafafa.core.mem 的强大功能！
