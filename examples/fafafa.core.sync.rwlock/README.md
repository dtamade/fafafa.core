# fafafa.core.sync.rwlock 示例

本目录包含 `fafafa.core.sync.rwlock` 模块的使用示例，展示读写锁的各种功能和最佳实践。

## 📁 示例文件

### 1. `example_rwlock_basic.lpr`
**基础读写锁示例**

展示读写锁的基本用法：
- 创建读写锁实例
- 多个读者并发访问
- 写者独占访问
- 状态查询方法
- 超时获取锁

**运行方式：**
```bash
# Linux/Unix
fpc example_rwlock_basic.lpr && ./example_rwlock_basic

# Windows
fpc example_rwlock_basic.lpr && example_rwlock_basic.exe
```

### 2. `example_rwlock_performance.lpr`
**性能测试示例**

展示读写锁在高并发场景下的性能特征：
- 多读者少写者的典型场景
- 缓存系统模拟
- 性能指标统计
- 读写比例分析

**运行方式：**
```bash
# Linux/Unix
fpc example_rwlock_performance.lpr && ./example_rwlock_performance

# Windows
fpc example_rwlock_performance.lpr && example_rwlock_performance.exe
```

## 🔧 编译要求

- Free Pascal Compiler (FPC) 3.2.0 或更高版本
- 支持的平台：Windows, Linux, macOS
- 需要 `fafafa.core.sync.rwlock` 模块

## 📊 性能特征

读写锁适用于以下场景：

### ✅ 适合的场景
- **读多写少**：读操作远多于写操作（如缓存系统）
- **数据共享**：多个线程需要频繁读取共享数据
- **配置管理**：配置数据读取频繁，更新较少

### ❌ 不适合的场景
- **写操作频繁**：写操作较多时，读写锁开销较大
- **短临界区**：非常短的临界区，自旋锁可能更合适
- **单线程**：单线程环境下没有必要使用

## 🎯 最佳实践

### 1. 选择合适的超时时间
```pascal
// 短超时：快速失败，避免长时间等待
if RWLock.TryAcquireWrite(10) then
begin
  // 写操作
  RWLock.ReleaseWrite;
end;

// 长超时：重要操作，可以等待更长时间
if RWLock.TryAcquireRead(1000) then
begin
  // 读操作
  RWLock.ReleaseRead;
end;
```

### 2. 使用 RAII 模式（推荐）
```pascal
uses fafafa.core.sync.base;

var
  AutoReadLock: TAutoReadLock;
begin
  AutoReadLock := TAutoReadLock.Create(RWLock);
  // 读操作，锁会自动释放
end;
```

### 3. 避免锁升级
```pascal
// ❌ 错误：不要在持有读锁时尝试获取写锁
RWLock.AcquireRead;
try
  // 读操作
  RWLock.AcquireWrite;  // 死锁！
  // 写操作
  RWLock.ReleaseWrite;
finally
  RWLock.ReleaseRead;
end;

// ✅ 正确：先释放读锁，再获取写锁
RWLock.AcquireRead;
try
  // 读操作
finally
  RWLock.ReleaseRead;
end;

RWLock.AcquireWrite;
try
  // 写操作
finally
  RWLock.ReleaseWrite;
end;
```

### 4. 监控锁状态
```pascal
// 检查锁状态，用于调试和监控
WriteLn('读者数量: ', RWLock.GetReaderCount);
WriteLn('是否有写锁: ', RWLock.IsWriteLocked);
WriteLn('写者线程: ', RWLock.GetWriterThread);
```

## 🔍 故障排除

### 常见问题

1. **死锁**
   - 原因：在持有读锁时尝试获取写锁
   - 解决：重新设计锁获取顺序

2. **性能问题**
   - 原因：写操作过于频繁
   - 解决：考虑使用互斥锁或优化写操作频率

3. **饥饿问题**
   - 原因：读者过多，写者长时间无法获取锁
   - 解决：使用超时机制，或考虑写者优先的实现

### 调试技巧

```pascal
// 添加调试输出
WriteLn('线程 ', GetCurrentThreadId, ' 尝试获取读锁');
RWLock.AcquireRead;
WriteLn('线程 ', GetCurrentThreadId, ' 获取读锁成功');
try
  // 操作
finally
  WriteLn('线程 ', GetCurrentThreadId, ' 释放读锁');
  RWLock.ReleaseRead;
end;
```

## 📚 相关文档

- [fafafa.core.sync.rwlock API 参考](../../docs/fafafa.core.sync.rwlock.md)
- [同步原语选择指南](../../docs/fafafa.core.sync.md)
- [性能优化指南](../../docs/Performance_Guide.md)
