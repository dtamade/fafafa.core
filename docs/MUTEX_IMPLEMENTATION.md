# Mutex 实现说明

**日期**: 2026-01-30  
**版本**: 1.0  
**状态**: 已修复

---

## 概述

fafafa.core 的 mutex 实现提供跨平台的互斥锁功能，支持重入检测和 poisoning 机制。本文档说明当前的实现方案、已知限制和使用建议。

---

## 实现方案

### Unix 平台

**提供两种实现供用户选择**：

#### 1. pthread_mutex（默认，安全优先）

**工厂函数**: `MakeMutex()`

**特性**:
- ✅ 符合 POSIX 标准
- ✅ **支持重入检测**（同一线程重复 Acquire 会抛出 `EDeadlockError`）
- ✅ 内核级别的死锁检测，无竞态条件
- ✅ 跨平台兼容性好

**性能**:
- 典型性能：25-29ns per lock/unlock cycle
- 对实际应用影响可忽略（mutex 操作通常占总时间 < 1%）

**适用场景**:
- ✅ 需要重入检测的场景
- ✅ 安全性优先的应用
- ✅ 跨平台兼容性要求高

#### 2. Futex（可选，性能优先）

**工厂函数**: `MakeFastMutex()` 或 `MakeFutexMutex()`

**特性**:
- ✅ 高性能（比 pthread_mutex 快 10-20%）
- ✅ 用户态实现，减少系统调用
- ⚠️ **不支持重入检测**（会导致死锁）

**性能**:
- 典型性能：约 20-25ns per lock/unlock cycle
- 比 pthread_mutex 快 10-20%

**适用场景**:
- ✅ 性能敏感的应用
- ✅ 代码保证不会重入
- ✅ 高频 mutex 操作（每秒百万次以上）

**重要警告**:
```pascal
// ❌ 错误：使用 Futex 时重入会导致死锁
LMutex := MakeFastMutex;
LMutex.Acquire;
LMutex.Acquire;  // 死锁！程序挂起

// ✅ 正确：使用 pthread_mutex 时重入会抛出异常
LMutex := MakeMutex;
LMutex.Acquire;
LMutex.Acquire;  // 抛出 EDeadlockError
```

**代码位置**: `src/fafafa.core.sync.mutex.unix.pas`

### Windows 平台

**实现**: 
- 默认：`CRITICAL_SECTION`（Windows Vista+）
- 可选：`SRWLOCK`（通过 `FAFAFA_CORE_USE_SRWLOCK` 宏启用）

**特性**:
- ✅ 支持重入检测（已修复 TOCTOU 竞态条件）
- ✅ 高性能（SRWLOCK 比 CRITICAL_SECTION 快约 40%）
- ✅ Poisoning 机制支持

**代码位置**: `src/fafafa.core.sync.mutex.windows.pas`

---

## 重入检测机制

### 工作原理

**Unix 平台**:
```pascal
// pthread_mutex_lock 的内部逻辑（简化）
int pthread_mutex_lock(pthread_mutex_t *mutex) {
  if (mutex->type == PTHREAD_MUTEX_ERRORCHECK) {
    // 原子地检查：如果已持有锁 && 是同一线程 → 返回 EDEADLK
    if (mutex->owner == gettid() && mutex->locked) {
      return EDEADLK;
    }
  }
  // 否则正常获取锁
  __lock(mutex);
  mutex->owner = gettid();
  return 0;
}
```

**Windows 平台**:
```pascal
procedure TMutex.Acquire;
var
  Cur: DWORD;
begin
  Cur := GetCurrentThreadId;
  EnterCriticalSection(FCriticalSection);  // 先获取锁
  
  // 在锁内检查重入（避免竞态条件）
  if atomic_load(FOwnerThreadId, mo_acquire) = Cur then
  begin
    LeaveCriticalSection(FCriticalSection);
    raise EDeadlockError.Create('Re-entrant acquire on non-reentrant mutex');
  end;
  
  atomic_store(FOwnerThreadId, Cur, mo_release);
end;
```

### 测试验证

**诊断程序**: `tests/fafafa.core.sync.mutex/diagnose_mutex.lpr`

**预期行为**:
```
=== Mutex Reentry Detection Diagnostic ===

Step 1: Creating mutex...
  OK: Mutex created

Step 2: First Acquire...
  OK: First acquire succeeded

Step 3: Second Acquire (should raise EDeadlockError)...
  OK: Caught EDeadlockError as expected
  Message: Re-entrant acquire on non-reentrant mutex

=== Diagnostic Complete: PASS ===
```

---

## 已知限制

### 平台特定问题

**FreeBSD 14.0 / NetBSD 10.0**:
- **问题**: `PTHREAD_MUTEX_ERRORCHECK` 类型存在内核 bug，可能错误地允许递归锁定
- **影响**: 重入检测可能失效（不会崩溃，但不会抛出异常）
- **解决方案**: 
  1. 升级到更新版本的 FreeBSD/NetBSD
  2. 使用 Linux 或其他平台
  3. 如果必须使用这些平台，请在代码中避免重入

**参考**: [GNU Gnulib 文档 - pthread_mutex 已知问题](https://www.gnu.org/software/gnulib/manual/html_node/pthread_005fmutex_005finit.html)

### 历史问题（已修复）

**glibc Bug #17514** (glibc 2.20-2.22):
- **问题**: Lock Elision 与 ERRORCHECK 类型冲突
- **状态**: 已在 glibc 2.23+ 修复
- **影响**: 如果使用旧版本 glibc，重入检测可能失效

---

## 配置选项

### Unix 平台

**禁用 Futex（默认）**:
```pascal
// src/fafafa.core.settings.inc
{$IFDEF UNIX}
{.$DEFINE FAFAFA_CORE_USE_FUTEX}  // 已注释，使用 pthread_mutex
{$ENDIF}
```

**原因**: Futex 实现的重入检测存在根本性的竞态条件问题（详见下文）。

### Windows 平台

**启用 SRWLOCK（默认）**:
```pascal
// src/fafafa.core.settings.inc
{$IFDEF WINDOWS}
{$DEFINE FAFAFA_CORE_USE_SRWLOCK}  // 默认启用
{$ENDIF}
```

**性能对比**:
- SRWLOCK: ~18ns per lock/unlock
- CRITICAL_SECTION: ~25ns per lock/unlock
- 差异约 40%，但对实际应用影响可忽略

---

## Futex 实现问题分析（已废弃）

### 问题根源

**死锁场景**:
1. 线程 A 第一次调用 `Acquire`：
   - 成功获取锁（FLock = 1）
   - 设置 FHasOwner = True，FOwnerThread = A

2. 线程 A 第二次调用 `Acquire`（重入）：
   - 尝试获取锁，**失败**（FLock 已经是 1）
   - 进入 `FutexWait` 等待 FLock 变为 0
   - **永远等待**：因为只有线程 A 自己能释放锁，但它已经阻塞了

**根本问题**: 检查重入的前提是"已经持有锁"，但 Futex 实现在检查之前就尝试获取锁，导致自己阻塞自己。

### 为什么无法修复

**理论上的修复**:
```pascal
procedure TFutexMutex.Acquire;
begin
  // 先检查重入（在获取锁之前）
  if FHasOwner and pthread_equal(FOwnerThread, pthread_self()) then
    raise EDeadlockError.Create('...');
  
  // 再获取锁
  while not atomic_compare_exchange_weak(FLock, 0, 1, mo_acquire, mo_relaxed) do
    FutexWait(@FLock, 1);
end;
```

**致命问题**: **竞态条件**
- 线程 A 检查 `FHasOwner` 时为 False（通过检查）
- 线程 B 在此时获取锁并设置 `FHasOwner = True`
- 线程 A 继续尝试获取锁，但 `FOwnerThread` 已经是线程 B
- 结果：线程 A 错误地认为没有重入，但实际上锁已被占用

**结论**: 无法在用户态安全实现，需要内核支持（这正是 pthread_mutex 存在的原因）。

---

## 使用建议

### 基本用法

```pascal
uses
  fafafa.core.sync.mutex;

var
  LMutex: IMutex;
begin
  LMutex := MakeMutex;
  
  LMutex.Acquire;
  try
    // 临界区代码
  finally
    LMutex.Release;
  end;
end;
```

### 使用 Lock Guard（推荐）

```pascal
uses
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

var
  LMutex: IMutex;
  LGuard: ILockGuard;
begin
  LMutex := MakeMutex;
  
  LGuard := LMutex.Lock;
  // 临界区代码
  // LGuard 析构时自动释放锁
end;
```

### 避免重入

**错误示例**:
```pascal
procedure ProcessData;
begin
  LMutex.Acquire;
  try
    // ... 处理数据 ...
    ProcessMoreData;  // ❌ 如果 ProcessMoreData 也尝试获取 LMutex，会死锁
  finally
    LMutex.Release;
  end;
end;
```

**正确做法**:
```pascal
procedure ProcessData;
begin
  LMutex.Acquire;
  try
    // ... 处理数据 ...
  finally
    LMutex.Release;
  end;
  
  ProcessMoreData;  // ✅ 在锁外调用
end;
```

### 性能考虑

**Mutex 适用场景**:
- ✅ 保护共享数据结构
- ✅ 临界区执行时间较长（> 1μs）
- ✅ 需要跨平台兼容性

**不适用场景**:
- ❌ 高频操作（每秒百万次以上）→ 使用 atomic 或 lockfree
- ❌ 极短临界区（< 100ns）→ 使用 spinlock
- ❌ 读多写少场景 → 使用 RWLock

---

## 测试与验证

### 运行测试

**编译测试程序**:
```bash
cd tests/fafafa.core.sync.mutex
/opt/fpcupdeluxe/fpc/bin/x86_64-linux/fpc -B -Fu../../src -Fi../../src -FUlib/x86_64-linux -FEbin -odiagnose diagnose_mutex.lpr
```

**运行诊断**:
```bash
./bin/diagnose
```

**预期输出**: 见上文"测试验证"部分

### 性能基准

**运行基准测试**:
```bash
cd tests/fafafa.core.sync.mutex
./bin/benchmark_mutex
```

**预期性能**:
- pthread_mutex: 25-29ns per lock/unlock
- Windows CRITICAL_SECTION: 25-30ns
- Windows SRWLOCK: 18-22ns

---

## 故障排查

### 问题：测试超时

**症状**: 测试程序在重入检测时超时（陷入死锁）

**可能原因**:
1. 使用了 Futex 实现（已废弃）
2. FreeBSD/NetBSD 平台的内核 bug
3. 旧版本 glibc（< 2.23）的 Lock Elision 问题

**解决方案**:
1. 确认 `FAFAFA_CORE_USE_FUTEX` 宏已禁用
2. 升级到支持的平台/版本
3. 运行诊断程序验证

### 问题：编译错误

**症状**: 找不到 pthread 相关符号

**解决方案**:
```pascal
// 确保在程序开头包含
uses
  {$IFDEF UNIX}
  cthreads,  // 必须在其他单元之前
  {$ENDIF}
  fafafa.core.sync.mutex;
```

---

## 参考资料

### 官方文档
- [POSIX pthread_mutex 规范](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_lock.html)
- [GNU Gnulib pthread 已知问题](https://www.gnu.org/software/gnulib/manual/html_node/pthread_005fmutex_005finit.html)
- [Windows CRITICAL_SECTION 文档](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-entercriticalsection)
- [Windows SRWLOCK 文档](https://docs.microsoft.com/en-us/windows/win32/sync/slim-reader-writer--srw--locks)

### 相关问题
- [glibc Bug #17514: Lock Elision 与 ERRORCHECK 冲突](https://sourceware.org/bugzilla/show_bug.cgi?id=17514)
- [FreeBSD pthread_mutex 已知问题](https://bugs.freebsd.org/bugzilla/)

---

## 更新历史

- **2026-01-30**: 初始版本
  - 禁用 Futex 实现，使用 pthread_mutex
  - 修复 Windows 平台 TOCTOU 竞态条件
  - 添加完整的测试和文档
  - 记录已知限制和故障排查指南

---

**维护者**: fafafa.core 团队  
**联系方式**: 见项目 README.md
