# fafafa.core.sync.namedEvent 性能优化指南

## 性能优化总结

### 已完成的优化

#### 1. Unix 平台优化 ✅
- **消除忙等待**: 将 `Sleep(1)` 忙等待替换为 `pthread_cond_wait` 条件变量等待
- **改进初始化同步**: 添加专用的 `InitCond` 条件变量用于初始化同步
- **错误处理增强**: 改进引用计数的错误处理，避免静默失败

#### 2. Windows 平台优化 ✅
- **修复竞态条件**: 重新设计 `IsSignaled` 方法，减少竞态窗口
- **替换 PulseEvent**: 用 `SetEvent + ResetEvent` 组合替换已弃用的 `PulseEvent`
- **改进错误处理**: 增加更详细的错误状态检查

#### 3. 接口简化 ✅
- **减少工厂函数**: 从 9 个减少到 3 个核心函数
- **统一命名**: `SetEvent` → `Signal`, `ResetEvent` → `Reset`, `PulseEvent` → `Pulse`
- **移除过时方法**: 删除所有 deprecated 兼容性方法

### 性能基准测试

使用 `benchmark_performance.lpr` 进行性能测试：

```bash
fpc -Mobjfpc -Sh -Fu../../src benchmark_performance.lpr
./benchmark_performance
```

#### 预期性能指标

| 操作类型 | 目标性能 | 说明 |
|---------|---------|------|
| 创建/销毁 | > 1000 次/秒 | 事件对象生命周期管理 |
| 信号/等待 | > 50000 次/秒 | 基本同步操作 |
| 并发访问 | > 20000 次/秒 | 多线程竞争场景 |

### 与主流框架对比

#### Rust std::sync
```rust
// Rust 的设计理念：零成本抽象
let (tx, rx) = mpsc::channel();
tx.send(data).unwrap();
let result = rx.recv().unwrap();
```

#### Java java.util.concurrent
```java
// Java 的设计理念：企业级可靠性
CountDownLatch latch = new CountDownLatch(1);
latch.await();
latch.countDown();
```

#### Go sync
```go
// Go 的设计理念：简洁高效
var wg sync.WaitGroup
wg.Add(1)
go func() { defer wg.Done(); doWork() }()
wg.Wait()
```

#### 我们的实现
```pascal
// FreePascal 的设计理念：现代化 + 高性能
var LEvent := CreateNamedEvent('MyEvent');
var LGuard := LEvent.Wait;
// RAII 自动清理
```

## 进一步优化建议

### 高优先级优化

#### 1. 内存池优化
- **问题**: 频繁的对象创建/销毁开销
- **解决方案**: 实现事件对象池
- **预期收益**: 创建性能提升 50-100%

#### 2. 锁粒度优化
- **问题**: Unix 实现中锁竞争激烈
- **解决方案**: 使用读写锁或无锁算法
- **预期收益**: 并发性能提升 30-50%

#### 3. 平台特定优化
- **Windows**: 使用 `WaitOnAddress` API (Windows 8+)
- **Linux**: 使用 `futex` 系统调用
- **预期收益**: 延迟降低 20-40%

### 中优先级优化

#### 4. 缓存友好设计
- **问题**: 共享内存结构可能导致缓存失效
- **解决方案**: 优化内存布局，减少 false sharing
- **预期收益**: 高并发场景性能提升 10-20%

#### 5. 批量操作支持
- **问题**: 单次操作开销相对较高
- **解决方案**: 支持批量信号/等待操作
- **预期收益**: 吞吐量提升 2-3倍

### 低优先级优化

#### 6. 自适应策略
- **问题**: 固定策略无法适应不同工作负载
- **解决方案**: 根据使用模式动态调整策略
- **预期收益**: 特定场景性能提升 10-30%

## 性能测试矩阵

### 测试场景

| 场景 | 线程数 | 事件数 | 操作类型 | 预期 QPS |
|------|--------|--------|----------|----------|
| 单线程基准 | 1 | 1 | Signal/Wait | 50000+ |
| 轻度并发 | 4 | 1 | Signal/Wait | 40000+ |
| 中度并发 | 16 | 4 | Signal/Wait | 30000+ |
| 重度并发 | 64 | 16 | Signal/Wait | 20000+ |
| 跨进程 | 2进程 | 1 | Signal/Wait | 10000+ |

### 延迟要求

| 百分位 | 目标延迟 | 说明 |
|--------|----------|------|
| P50 | < 10μs | 中位数延迟 |
| P95 | < 100μs | 95% 操作延迟 |
| P99 | < 1ms | 99% 操作延迟 |
| P99.9 | < 10ms | 极端情况延迟 |

## 最佳实践

### 1. 选择合适的事件类型
```pascal
// 状态通知 - 使用手动重置
LEvent := CreateNamedEvent('StatusChanged', True);

// 任务分发 - 使用自动重置  
LEvent := CreateNamedEvent('TaskReady', False);
```

### 2. 避免长时间持有守卫
```pascal
// 好的做法
procedure ProcessEvent;
var LGuard: INamedEventGuard;
begin
  LGuard := LEvent.TryWaitFor(1000);
  if Assigned(LGuard) then
  begin
    // 快速处理
    ProcessData;
    LGuard := nil; // 立即释放
  end;
end;
```

### 3. 合理设置超时
```pascal
// 交互式应用 - 短超时
LGuard := LEvent.TryWaitFor(100);

// 批处理应用 - 长超时
LGuard := LEvent.TryWaitFor(30000);
```

### 4. 错误处理
```pascal
try
  LGuard := LEvent.Wait;
  // 处理事件
except
  on E: ELockError do
    // 处理同步错误
    HandleSyncError(E);
  on E: ETimeoutError do
    // 处理超时
    HandleTimeout(E);
end;
```

## 监控和调试

### 性能监控指标
- 事件创建/销毁频率
- 平均等待时间
- 锁竞争次数
- 内存使用量

### 调试工具
- `GetLastError` 获取错误状态
- 性能基准测试程序
- 内存泄漏检测 (heaptrc)

## 版本演进计划

### v1.1 (性能优化版)
- [ ] 内存池实现
- [ ] 锁粒度优化
- [ ] 平台特定优化

### v1.2 (功能增强版)
- [ ] 批量操作支持
- [ ] 自适应策略
- [ ] 更多平台支持

### v2.0 (架构升级版)
- [ ] 无锁实现
- [ ] 异步支持
- [ ] 分布式事件
