# fafafa.core.sync.spin - 自旋锁模块

## 📋 概述

`fafafa.core.sync.spin` 模块提供了高性能的自旋锁实现，适用于短时间临界区的同步。该模块遵循与 `fafafa.core.sync.mutex` 相同的架构模式，提供跨平台的统一接口。

## 🏗️ 架构设计

### 模块结构
```
fafafa.core.sync.spin/
├── fafafa.core.sync.spin.pas          # 主模块，平台无关接口
├── fafafa.core.sync.spin.base.pas     # 基础接口定义
├── fafafa.core.sync.spin.windows.pas  # Windows 平台实现
└── fafafa.core.sync.spin.unix.pas     # Unix/Linux 平台实现
```

### 接口层次
```
ILock (基础锁接口)
  └── ISpinLock (自旋锁特有接口)
        └── TSpinLock (平台特定实现)
```

## 🔧 平台实现策略

### Unix/Linux 平台
- **底层技术**: pthread_spinlock_t
- **API 使用**: 
  - `pthread_spin_init()` - 初始化自旋锁
  - `pthread_spin_lock()` - 获取自旋锁
  - `pthread_spin_trylock()` - 尝试获取自旋锁
  - `pthread_spin_unlock()` - 释放自旋锁
  - `pthread_spin_destroy()` - 销毁自旋锁
- **优势**: 内核级优化，硬件支持

### Windows 平台
- **底层技术**: fafafa.core.atomic.atomic_flag
- **实现方式**: 
  - 使用 `atomic_flag_test_and_set()` 获取锁
  - 使用 `atomic_flag_clear()` 释放锁
  - 支持可配置的自旋次数
  - 自旋失败后降级为 Sleep(0) 让出 CPU
- **优势**: 用户态实现，无系统调用开销

## 📚 API 参考

### 接口定义

```pascal
ISpinLock = interface(ILock)
  // 继承自 ILock 的方法
  procedure Acquire;
  procedure Release;
  function TryAcquire: Boolean; overload;
  function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  function GetState: TLockState;
  function IsLocked: Boolean;
  
  // 自旋锁特有方法
  function GetSpinCount: Integer;
  procedure SetSpinCount(ASpinCount: Integer);
  function GetOwnerThread: TThreadID;
end;
```

### 工厂函数

```pascal
function CreateSpinLock(ASpinCount: Integer = 4000): ISpinLock;
```

## 💡 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.spin;

var
  SpinLock: ISpinLock;
begin
  SpinLock := CreateSpinLock(1000);
  
  SpinLock.Acquire;
  try
    // 短时间临界区代码
    // 适合 < 100 条指令的操作
  finally
    SpinLock.Release;
  end;
end;
```

### 非阻塞尝试

```pascal
var
  SpinLock: ISpinLock;
begin
  SpinLock := CreateSpinLock(500);
  
  if SpinLock.TryAcquire then
  begin
    try
      // 临界区代码
    finally
      SpinLock.Release;
    end;
  end
  else
    WriteLn('无法获取锁，跳过操作');
end;
```

### 带超时的获取

```pascal
var
  SpinLock: ISpinLock;
begin
  SpinLock := CreateSpinLock(2000);
  
  if SpinLock.TryAcquire(100) then // 100ms 超时
  begin
    try
      // 临界区代码
    finally
      SpinLock.Release;
    end;
  end
  else
    WriteLn('获取锁超时');
end;
```

### 动态调整自旋次数

```pascal
var
  SpinLock: ISpinLock;
begin
  SpinLock := CreateSpinLock(1000);
  
  // 根据系统负载调整自旋次数
  if SystemIsUnderHighLoad then
    SpinLock.SetSpinCount(100)  // 减少自旋，快速让出 CPU
  else
    SpinLock.SetSpinCount(5000); // 增加自旋，减少上下文切换
end;
```

## ⚡ 性能特征

### 适用场景
- **短临界区**: < 100 条指令的操作
- **低竞争**: 锁持有时间很短
- **高频访问**: 需要最小化同步开销
- **实时系统**: 需要确定性的延迟

### 性能对比

| 场景 | 自旋锁 | 互斥锁 | 说明 |
|------|--------|--------|------|
| 短临界区 (< 10μs) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 自旋锁避免上下文切换 |
| 中等临界区 (10-100μs) | ⭐⭐⭐ | ⭐⭐⭐⭐ | 取决于竞争程度 |
| 长临界区 (> 100μs) | ⭐ | ⭐⭐⭐⭐⭐ | 自旋锁浪费 CPU |
| 高竞争 | ⭐⭐ | ⭐⭐⭐⭐ | 自旋锁可能导致活锁 |
| 低竞争 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 自旋锁开销最小 |

## 🚨 注意事项

### 重要限制
1. **不支持重入**: 同一线程不能重复获取自旋锁
2. **短时间持有**: 不适合长时间持有的场景
3. **CPU 密集**: 自旋会消耗 CPU 资源
4. **优先级反转**: 可能导致优先级反转问题

### 最佳实践

#### ✅ 推荐做法
```pascal
// 短时间操作
SpinLock.Acquire;
try
  Counter := Counter + 1;  // 简单操作
finally
  SpinLock.Release;
end;
```

#### ❌ 避免做法
```pascal
// 长时间操作
SpinLock.Acquire;
try
  Sleep(100);              // 不要在自旋锁中休眠
  FileOperation();         // 不要进行 I/O 操作
  ComplexCalculation();    // 不要进行复杂计算
finally
  SpinLock.Release;
end;
```

### 调优建议

1. **自旋次数调优**:
   - 单核系统: 设置较小值 (100-500)
   - 多核系统: 设置较大值 (1000-5000)
   - 高负载系统: 动态调整

2. **竞争检测**:
   ```pascal
   if SpinLock.TryAcquire then
   begin
     // 低竞争路径
   end
   else
   begin
     // 高竞争，考虑使用互斥锁
   end;
   ```

## 🧪 测试覆盖

### 基础功能测试
- ✅ 创建和销毁
- ✅ 基本获取/释放
- ✅ TryAcquire 操作
- ✅ 超时获取
- ✅ 重入检测
- ✅ 错误处理
- ✅ 状态查询

### 并发测试
- ✅ 多线程计数器
- ✅ 并发 TryAcquire
- ✅ 性能基准测试

### 平台测试
- ✅ Windows (atomic_flag)
- ✅ Unix/Linux (pthread_spinlock_t)

## 🔄 与其他模块的关系

### 依赖关系
```
fafafa.core.sync.spin
├── fafafa.core.sync.base (基础接口)
├── fafafa.core.atomic (Windows 平台)
└── pthreads (Unix 平台)
```

### 集成使用
```pascal
uses
  fafafa.core.sync.spin,
  fafafa.core.sync.mutex;

// 根据场景选择合适的同步原语
function CreateLock(IsShortCriticalSection: Boolean): ILock;
begin
  if IsShortCriticalSection then
    Result := CreateSpinLock(2000)
  else
    Result := CreateMutex;
end;
```

## 📈 未来扩展

### 计划功能
- [ ] 自适应自旋次数
- [ ] 竞争统计信息
- [ ] NUMA 感知优化
- [ ] 硬件事务内存支持

### 性能优化
- [ ] CPU 缓存行对齐
- [ ] 分层自旋策略
- [ ] 退避算法优化
