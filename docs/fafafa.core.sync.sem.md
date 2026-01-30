# fafafa.core.sync.sem - 信号量模块

## 📋 概述

`fafafa.core.sync.sem` 模块提供了高性能、跨平台的信号量（Semaphore）实现，支持计数信号量和 RAII 风格的资源管理。

## 🎯 核心特性

- ✅ **计数信号量**: 支持多个许可的获取和释放
- ✅ **RAII 守卫**: 自动资源管理，异常安全
- ✅ **非阻塞操作**: 支持超时和立即返回的尝试操作
- ✅ **批量操作**: 支持一次获取/释放多个许可
- ✅ **跨平台**: Windows 和 Unix/Linux 原生实现
- ✅ **高性能**: 零开销抽象，优化的系统调用

## 🔧 核心接口

### ISem - 信号量接口

```pascal
ISem = interface(ITryLock)
  // 基础操作
  procedure Acquire; overload;                    // 获取1个许可
  procedure Acquire(ACount: Integer); overload;   // 获取指定数量许可
  procedure Release; overload;                    // 释放1个许可
  procedure Release(ACount: Integer); overload;   // 释放指定数量许可
  
  // 非阻塞操作
  function TryAcquire: Boolean; overload;
  function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  function TryAcquire(ACount: Integer): Boolean; overload;
  function TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean; overload;
  
  // 状态查询
  function GetAvailableCount: Integer;  // 获取当前可用许可数
  function GetMaxCount: Integer;        // 获取最大许可数
  
  // RAII 守卫
  function AcquireGuard: ISemGuard; overload;
  function AcquireGuard(ACount: Integer): ISemGuard; overload;
  function TryAcquireGuard: ISemGuard; overload;
  function TryAcquireGuard(ATimeoutMs: Cardinal): ISemGuard; overload;
  function TryAcquireGuard(ACount: Integer): ISemGuard; overload;
  function TryAcquireGuard(ACount: Integer; ATimeoutMs: Cardinal): ISemGuard; overload;
end;
```

### ISemGuard - 信号量守卫接口

```pascal
ISemGuard = interface(ILockGuard)
  function GetCount: Integer;  // 获取持有的许可数量
  procedure Release;           // 手动释放许可（继承自 ILockGuard）
end;
```

## 🚀 基础使用

### 创建信号量

```pascal
uses fafafa.core.sync.sem;

var
  Sem: ISem;
begin
  // 创建信号量：初始1个许可，最大3个许可
  Sem := MakeSem(1, 3);
end;
```

### 手动管理

```pascal
var
  Sem: ISem;
begin
  Sem := MakeSem(2, 5);
  
  // 获取许可
  Sem.Acquire;        // 获取1个许可
  Sem.Acquire(2);     // 获取2个许可
  
  try
    // 临界区代码
  finally
    Sem.Release(3);   // 释放3个许可
  end;
end;
```

### RAII 守卫模式（推荐）

```pascal
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(1, 3);
  
  // 自动管理许可
  Guard := Sem.AcquireGuard;
  try
    // 临界区代码
    WriteLn('持有许可数: ', Guard.GetCount);
  finally
    // Guard 析构时自动释放许可
  end;
end;
```

### with 语句模式（最简洁）

```pascal
var
  Sem: ISem;
begin
  Sem := MakeSem(2, 4);
  
  with Sem.AcquireGuard(2) do
  begin
    // 临界区代码
    WriteLn('持有许可数: ', GetCount);
  end; // 自动释放
end;
```

## 🔄 非阻塞操作

### 立即尝试

```pascal
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(1, 2);
  
  Guard := Sem.TryAcquireGuard;
  if Guard <> nil then
  begin
    WriteLn('获取成功，持有许可数: ', Guard.GetCount);
    // 使用资源
  end
  else
    WriteLn('无可用许可');
end;
```

### 超时等待

```pascal
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(0, 1);  // 初始无许可
  
  // 等待最多1000毫秒
  Guard := Sem.TryAcquireGuard(1000);
  if Guard <> nil then
    WriteLn('在超时前获取到许可')
  else
    WriteLn('超时，未获取到许可');
end;
```

## 🎭 高级用法

### 批量操作

```pascal
var
  Sem: ISem;
begin
  Sem := MakeSem(5, 10);
  
  // 批量获取
  with Sem.AcquireGuard(3) do
  begin
    WriteLn('批量获取3个许可');
    WriteLn('剩余可用许可: ', Sem.GetAvailableCount);
  end; // 批量释放3个许可
end;
```

### 条件获取

```pascal
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(2, 5);
  
  // 尝试获取3个许可
  Guard := Sem.TryAcquireGuard(3);
  if Guard <> nil then
  begin
    WriteLn('成功获取3个许可');
    
    // 可以提前手动释放
    if SomeCondition then
      Guard.Release;
  end
  else
    WriteLn('许可不足，无法获取3个许可');
end;
```

### 嵌套作用域

```pascal
var
  Sem: ISem;
  Guard1: ISemGuard;
  Guard2: ISemGuard;
begin
  Sem := MakeSem(3, 3);

  Guard1 := Sem.AcquireGuard;
  try
    WriteLn('外层获取1个许可，剩余: ', Sem.GetAvailableCount);

    Guard2 := Sem.AcquireGuard(2);
    try
      WriteLn('内层获取2个许可，剩余: ', Sem.GetAvailableCount);
    finally
      // 可省略，Guard2 析构会自动释放
      Guard2.Release;
    end;

    WriteLn('内层结束后剩余: ', Sem.GetAvailableCount);
  finally
    // 可省略，Guard1 析构会自动释放
    Guard1.Release;
  end;

  WriteLn('外层结束后剩余: ', Sem.GetAvailableCount);
end;
```

## 🛡️ 异常安全

```pascal
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(1, 1);
  
  Guard := Sem.AcquireGuard;
  try
    // 即使这里抛异常，Guard 也会在栈展开时自动释放许可
    if SomeErrorCondition then
      raise Exception.Create('测试异常');
      
    // 正常处理
  except
    on E: Exception do
      WriteLn('捕获异常: ', E.Message);
  end;
  // Guard 确保许可被释放
end;
```

## 📊 性能特性

### 实现细节

- **Windows**: 使用 `CreateSemaphore` 和 `WaitForSingleObject`
- **Unix/Linux**: 使用 `pthread_mutex` 和 `pthread_cond` 实现
- **内存占用**: 每个信号量对象约 32-64 字节
- **守卫开销**: 每个守卫对象约 16 字节

### 性能建议

1. **优先使用守卫**: RAII 模式几乎无性能开销
2. **批量操作**: 一次获取多个许可比多次单独获取更高效
3. **避免频繁创建**: 重用信号量对象
4. **合理设置超时**: 避免过短的超时值导致忙等待

## 🔗 与其他模块集成

### 通过主同步模块使用

```pascal
uses fafafa.core.sync;

var
  Sem: ISem;
begin
  Sem := MakeSem(1, 3);  // 通过主模块创建
  // 使用方式完全相同
end;
```

### 多态使用

```pascal
uses fafafa.core.sync;

procedure ProcessWithLock(Lock: ILock);
begin
  with Lock.LockGuard do
  begin
    // 通用锁处理逻辑
  end;
end;

var
  Sem: ISem;
begin
  Sem := MakeSem(1, 1);
  ProcessWithLock(Sem);  // 信号量可以作为锁使用
end;
```

## 🎯 最佳实践

1. **优先使用 RAII**: 使用守卫而不是手动 Acquire/Release
2. **合理设置容量**: 根据实际需求设置最大许可数
3. **避免死锁**: 注意获取顺序，使用超时机制
4. **异常处理**: 利用 RAII 确保异常安全
5. **性能优化**: 批量操作，重用对象

## 📚 相关文档

- [fafafa.core.sync.base](fafafa.core.sync.base.md) - 同步基础设施
- [fafafa.core.sync.guard_design](fafafa.core.sync.guard_design.md) - 守卫设计模式
- [fafafa.core.sync](fafafa.core.sync.md) - 主同步模块

## 🎉 总结

`fafafa.core.sync.sem` 提供了现代化、高性能的信号量实现，通过 RAII 守卫模式确保资源安全，支持丰富的操作模式，是构建并发应用的重要工具。

## 🔧 技术实现细节

### 平台特定优化

#### Unix/Linux 实现
- **超时机制**: 优先使用 `CLOCK_MONOTONIC` 单调时钟，避免系统时间调整影响
- **条件变量**: 使用 `pthread_cond_timedwait` 实现高效等待
- **原子操作**: 在互斥锁保护下进行计数操作

```pascal
// Unix 超时计算示例
{$IFDEF HAS_CLOCK_GETTIME}
if clock_gettime(CLOCK_MONOTONIC, @nowTs) <> 0 then
  // 错误处理
ts.tv_sec := nowTs.tv_sec + (ATimeoutMs div 1000);
ts.tv_nsec := nowTs.tv_nsec + Int64(ATimeoutMs mod 1000) * 1000000;
{$ELSE}
// 回退到 gettimeofday
{$ENDIF}
```

#### Windows 实现
- **系统信号量**: 直接使用 `CreateSemaphore` 和 `WaitForSingleObject`
- **安全回滚**: 批量操作失败时使用 `TryRelease` 进行安全回滚
- **高精度计时**: 使用 `GetTickCount64` 提供毫秒精度

```pascal
// Windows 安全回滚示例
if acquired > 0 then
begin
  try
    TryRelease(acquired);
  except
    // 忽略回滚异常，保持原始错误
  end;
end;
```

### 异常与失败语义
- Acquire/Release/批量接口：参数非法抛出异常（EInvalidArgument），系统调用失败抛出 ELockError；成功不抛异常。
- TryAcquire/TryAcquireGuard 系列：仅以返回值表示是否成功；失败时不抛异常（除参数非法），可配合超时参数使用。
- RAII 守卫：析构自动释放，异常安全；批量获取失败时保证强一致性（已得部分会回滚）。

### 性能特性

#### 内存效率
- 信号量对象：约 32-64 字节
- 守卫对象：约 16 字节
- 零动态内存分配

#### 时间复杂度
- 获取/释放：O(1)
- 批量操作：O(n)，其中 n 是许可数量
- 状态查询：O(1)

## 📝 示例代码

完整的使用示例请参考：
- `examples/fafafa.core.sync/example_sem.lpr` - 基础示例
- `examples/fafafa.core.sync/example_sem_complete.lpr` - 完整功能演示

## 🔍 版本历史

### v2.0 (2025-01-03) - 评审改进版
- **改进**: Unix 实现使用 CLOCK_MONOTONIC 提高超时精度
- **改进**: Windows 实现安全回滚机制
- **验证**: 跨平台行为一致性
- **新增**: 性能基准测试框架

### v1.0 (2025-01-02) - 重构完成版
- **重构**: 从 semaphore 重命名为 sem
- **清理**: 统一接口命名
- **完善**: 守卫机制改进
- **文档**: 完整的 API 文档
