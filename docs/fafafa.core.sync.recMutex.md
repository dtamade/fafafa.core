# fafafa.core.sync.recMutex

## 概述

`fafafa.core.sync.recMutex` 是一个现代化、跨平台的 FreePascal 可重入互斥锁实现，提供统一的 API 接口。支持同一线程多次获取锁，自动管理重入计数。

## 特性

- **跨平台支持**：Windows、Linux、macOS、FreeBSD 等
- **可重入设计**：同一线程可多次获取锁，自动计数管理
- **高性能实现**：使用平台原生 API 优化
- **智能等待策略**：三段式等待 + 渐进式退避，最大化性能并减少 CPU 占用
- **超时支持**：可配置的获取超时机制
- **RAII 支持**：自动锁管理和异常安全
- **零本地状态**：Windows 实现完全依赖系统原生重入支持

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.recMutex;

var
  RecMutex: IRecMutex;
begin
  RecMutex := MakeRecMutex;
  
  RecMutex.Acquire;
  try
    // 临界区代码
  finally
    RecMutex.Release;
  end;
end;
```

### 重入使用

```pascal
var
  RecMutex: IRecMutex;
begin
  RecMutex := MakeRecMutex;
  
  RecMutex.Acquire;  // 第一次获取
  try
    RecMutex.Acquire;  // 重入获取，计数 = 2
    try
      // 嵌套临界区代码
    finally
      RecMutex.Release;  // 计数 = 1
    end;
  finally
    RecMutex.Release;  // 计数 = 0，真正释放锁
  end;
end;
```

### RAII 使用

```pascal
var
  RecMutex: IRecMutex;
  Guard: ILockGuard;
begin
  RecMutex := MakeRecMutex;
  
  Guard := RecMutex.LockGuard;
  // Guard 会在作用域结束时自动释放锁
  
  // 嵌套 RAII
  begin
    var NestedGuard := RecMutex.LockGuard;
    // 支持重入，NestedGuard 也会自动释放
  end;
end;
```

### 非阻塞尝试

```pascal
var
  RecMutex: IRecMutex;
begin
  RecMutex := MakeRecMutex;
  
  if RecMutex.TryAcquire then
  try
    // 成功获取锁
  finally
    RecMutex.Release;
  end
  else
    // 锁被其他线程持有
    WriteLn('Lock is busy');
end;
```

### 超时等待

```pascal
var
  RecMutex: IRecMutex;
begin
  RecMutex := MakeRecMutex;
  
  if RecMutex.TryAcquire(1000) then  // 等待最多 1 秒
  try
    // 成功获取锁
  finally
    RecMutex.Release;
  end
  else
    // 超时未能获取锁
    WriteLn('Timeout waiting for lock');
end;
```

## 平台实现

### Windows 实现

- 基于 `TRTLCriticalSection`
- 天然支持重入，无额外开销
- 支持自旋计数优化
- 用户态锁，性能优异

```pascal
// 使用默认自旋计数（4000）
var RecMutex := MakeRecMutex;

// 使用自定义自旋计数
var RecMutex := MakeRecMutex(8000);
```

### Unix 实现

- 基于 `pthread_mutex_t`
- 使用 `PTHREAD_MUTEX_RECURSIVE` 属性
- 系统级重入支持
- 跨 Unix 系统兼容

## API 参考

### 工厂函数

#### `MakeRecMutex(): IRecMutex`

创建可重入互斥锁实例，使用平台默认参数。

#### `MakeRecMutex(ASpinCount: DWORD): IRecMutex` (Windows 专用)

创建带自旋计数的可重入互斥锁实例。

**参数：**
- `ASpinCount`: 自旋计数，建议值：
  - 单核系统：0（禁用自旋）
  - 多核系统：1000-4000（默认 4000）
  - 高竞争场景：8000-16000

### IRecMutex 接口

继承自 `ITryLock`，具备完整的锁操作能力。

#### 基本操作

- `Acquire()`: 获取锁，支持重入
- `Release()`: 释放锁，必须与 Acquire 配对
- `TryAcquire(): Boolean`: 非阻塞尝试获取锁
- `TryAcquire(ATimeoutMs: Cardinal): Boolean`: 超时等待获取锁
  - `ATimeoutMs = 0`: 等同于非阻塞的 `TryAcquire()`
  - `ATimeoutMs > 0`: 使用智能等待策略，包括三段式自旋和渐进式退避

#### RAII 支持

- `LockGuard(): ILockGuard`: 创建自动锁守卫

## 性能特征

### 基准测试结果

基于 34 个测试用例的性能数据：

- **高频操作**：10,000 次获取/释放仅用时 1ms
- **多线程竞争**：4 线程 × 1000 次操作用时 11-30ms
- **深度重入**：100 层嵌套瞬间完成
- **超时等待**：智能退避策略，长期等待时 CPU 占用极低
- **内存安全**：零内存泄漏

### 性能建议

1. **Windows 平台**：
   - 使用默认自旋计数（4000）适合大多数场景
   - 高竞争场景可增加到 8000-16000
   - 单核系统设置为 0 禁用自旋

2. **重入深度**：
   - 支持任意深度重入
   - 深度重入（100+ 层）性能依然优异

3. **并发场景**：
   - 多线程竞争下表现良好
   - 适合中等到高等竞争强度的场景

4. **超时等待优化**：
   - 使用渐进式退避策略：1ms → 2ms → 4ms → 8ms → 16ms → 32ms
   - 短期锁保持高响应性，长期等待减少 CPU 占用
   - 零超时等同于非阻塞调用，性能最优

## 高级特性

### 超时等待策略

`TryAcquire(ATimeoutMs)` 使用智能的多阶段等待策略：

1. **立即尝试**：首先进行非阻塞尝试
2. **三段式自旋**：
   - 紧密自旋（高性能短期等待）
   - 退避自旋（平衡性能和资源）
   - 阻塞等待（长期等待，最小化 CPU 占用）
3. **渐进式退避**：如果所有自旋阶段都被关闭，使用渐进式睡眠间隔
   - 睡眠时间：1ms → 2ms → 4ms → 8ms → 16ms → 32ms（最大）
   - 既保证短期锁的响应性，又避免长期等待时的 CPU 浪费

**超时行为保证**：
- 严格遵守超时时间，不会在超时后进行额外尝试
- 零超时（`ATimeoutMs = 0`）等同于非阻塞的 `TryAcquire()`
- 超时精度取决于系统调度器，通常在 1-15ms 范围内

## 最佳实践

### 1. 选择合适的锁类型

```pascal
// 需要重入时使用 RecMutex
var RecMutex := MakeRecMutex;

// 不需要重入时使用普通 Mutex（性能更好）
var Mutex := MakeMutex;
```

### 2. 使用 RAII 模式

```pascal
// 推荐：使用 RAII 自动管理
var Guard := RecMutex.LockGuard;

// 避免：手动管理容易出错
RecMutex.Acquire;
try
  // ...
finally
  RecMutex.Release;
end;
```

### 3. 避免死锁

```pascal
// 安全：可重入锁支持同一线程多次获取
procedure RecursiveFunction(RecMutex: IRecMutex; Depth: Integer);
begin
  var Guard := RecMutex.LockGuard;
  
  if Depth > 0 then
    RecursiveFunction(RecMutex, Depth - 1);  // 安全的重入
end;
```

### 4. 异常安全

```pascal
// RAII 确保异常安全
var Guard := RecMutex.LockGuard;
try
  // 可能抛出异常的代码
  raise Exception.Create('Test');
except
  // Guard 会自动释放锁
end;
```

## 线程安全性

- **线程间互斥**：不同线程不能同时持有锁
- **线程内重入**：同一线程可以递归获取锁
- **计数管理**：自动管理重入深度
- **异常安全**：RAII 守卫确保异常情况下正确释放

## 适用场景

### 推荐使用

- 递归函数需要获取同一锁
- 嵌套函数调用中的锁保护
- 复杂的调用链中的资源保护
- 需要在持有锁的情况下调用其他可能获取同一锁的函数

### 不推荐使用

- 简单的临界区保护（使用普通 Mutex 性能更好）
- 读写分离场景（使用 RWLock 更合适）
- 高频短期锁定（考虑 SpinMutex）

## 故障排除

### 常见问题

1. **性能不如预期**
   - 检查是否真的需要重入特性
   - 考虑调整 Windows 平台的自旋计数
   - 评估是否适合使用其他类型的锁

2. **死锁问题**
   - 可重入锁避免了同一线程的死锁
   - 但不能避免不同线程间的死锁
   - 确保锁的获取顺序一致

3. **内存泄漏**
   - 使用 RAII 模式避免忘记释放锁
   - 检查异常处理路径

## 版本历史

- **v1.0.0**: 初始版本，支持基本重入功能
- **v1.1.0**: 添加 Windows 自旋计数优化
- **v1.2.0**: 完善 Unix 平台支持
- **v1.3.0**: 添加 RAII 支持和异常安全
- **v1.4.0**: 零本地状态优化，完全依赖系统原生重入支持
- **v1.5.0**: 修复超时等待逻辑，添加渐进式退避策略，优化 CPU 占用

## 参考资料

- [同步原语设计文档](fafafa.core.sync.md)
- [性能基准测试](../benchmarks/sync_recmutex_benchmark.md)
- [最佳实践指南](../BestPractices-Cheatsheet.md)
