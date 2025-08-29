# fafafa.core.sync.spin - 自旋锁模块

## 📋 概述

`fafafa.core.sync.spin` 模块提供了高性能的自旋锁实现，适用于短时间临界区的同步。该模块采用策略驱动的架构设计，支持多种退避策略和性能统计，提供跨平台的统一接口。

## 🏗️ 架构设计

### 模块结构
```
fafafa.core.sync.spin/
├── fafafa.core.sync.spin.pas          # 主模块，平台无关接口
├── fafafa.core.sync.spin.base.pas     # 基础接口定义和策略类型
├── fafafa.core.sync.spin.windows.pas  # Windows 平台实现 (atomic_flag)
└── fafafa.core.sync.spin.unix.pas     # Unix/Linux 平台实现 (自定义自旋逻辑)
```

### 接口层次
```
ILock (基础锁接口)
  └── ISpinLock (自旋锁特有接口)
        ├── ISpinLockWithStats (统计接口)
        └── ISpinLockDebug (调试接口，仅 Debug 模式)
              └── TSpinLock (平台特定实现)
```

## 🔧 平台实现策略

### Unix/Linux 平台
- **底层技术**: pthread_spinlock_t + 自定义自旋逻辑
- **实现方式**:
  - 使用 `pthread_spin_trylock()` 进行非阻塞尝试
  - 实现自定义退避策略（线性、指数、自适应）
  - 支持可配置的自旋次数和退避时间
  - 三阶段自旋：纯自旋 → 短暂让步 → 策略退避
- **优势**: 策略可控，性能可调优

### Windows 平台
- **底层技术**: atomic_flag + 多阶段退避
- **实现方式**:
  - 使用 `atomic_flag_test_and_set()` 获取锁
  - 使用 `atomic_flag_clear()` 释放锁
  - 四阶段退避：pause指令 → SwitchToThread → Sleep(0) → 策略退避
  - 支持线性、指数、自适应退避策略
- **优势**: 用户态实现，无系统调用开销，精细化控制

## 📚 API 参考

### 策略配置

```pascal
TSpinBackoffStrategy = (
  sbsLinear,      // 线性退避：每次增加固定时间
  sbsExponential, // 指数退避：每次翻倍退避时间
  sbsAdaptive     // 自适应退避：前期指数，后期线性
);

TSpinLockPolicy = record
  MaxSpins: Integer;                    // 最大自旋次数（默认：64）
  BackoffStrategy: TSpinBackoffStrategy; // 退避策略（默认：自适应）
  MaxBackoffMs: Integer;                // 最大退避时间毫秒（默认：16）
  EnableStats: Boolean;                 // 是否启用统计（默认：False）
end;
```

### 接口定义

```pascal
ISpinLock = interface(ILock)
  // 继承自 ILock 的方法
  procedure Acquire;
  procedure Release;
  function TryAcquire: Boolean; overload;
  function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  function GetLastError: TWaitError;

  // 自旋锁特有方法
  function GetPolicy: TSpinLockPolicy;
  procedure UpdatePolicy(const APolicy: TSpinLockPolicy);
  function IsHeld: Boolean;
  function GetCurrentSpins: Integer;
  function GetSpinCount: Integer;
  procedure SetSpinCount(ASpinCount: Integer);
  function GetOwnerThread: TThreadID;
end;

ISpinLockWithStats = interface
  function GetStats: TSpinLockStats;
  procedure ResetStats;
  function GetContentionRate: Double;
end;
```

### 工厂函数

```pascal
function MakeSpinLock: ISpinLock; overload;
function MakeSpinLock(const APolicy: TSpinLockPolicy): ISpinLock; overload;
function DefaultSpinLockPolicy: TSpinLockPolicy;
```

## 💡 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  SpinLock: ISpinLock;
begin
  // 使用默认策略
  SpinLock := MakeSpinLock;

  SpinLock.Acquire;
  try
    // 短时间临界区代码
    // 适合 < 100 条指令的操作
  finally
    SpinLock.Release;
  end;
end;
```

### 自定义策略

```pascal
var
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
begin
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 128;
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 20;
  Policy.EnableStats := True;

  SpinLock := MakeSpinLock(Policy);

  SpinLock.Acquire;
  try
    // 临界区代码
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
  SpinLock := MakeSpinLock;

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
  SpinLock := MakeSpinLock;

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

### 动态策略调整

```pascal
var
  SpinLock: ISpinLock;
  Policy: TSpinLockPolicy;
begin
  SpinLock := MakeSpinLock;

  // 根据系统负载调整策略
  Policy := SpinLock.GetPolicy;
  if SystemIsUnderHighLoad then
  begin
    Policy.MaxSpins := 16;           // 减少自旋
    Policy.BackoffStrategy := sbsLinear; // 快速退避
    Policy.MaxBackoffMs := 4;
  end
  else
  begin
    Policy.MaxSpins := 128;          // 增加自旋
    Policy.BackoffStrategy := sbsAdaptive; // 自适应退避
    Policy.MaxBackoffMs := 16;
  end;
  SpinLock.UpdatePolicy(Policy);
end;
```

### 统计信息监控

```pascal
var
  SpinLock: ISpinLock;
  WithStats: ISpinLockWithStats;
  Stats: TSpinLockStats;
  Policy: TSpinLockPolicy;
begin
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := True;
  SpinLock := MakeSpinLock(Policy);

  // 执行一些操作
  SpinLock.Acquire;
  SpinLock.Release;

  // 查看统计信息
  if SpinLock.QueryInterface(ISpinLockWithStats, WithStats) = S_OK then
  begin
    Stats := WithStats.GetStats;
    WriteLn('总获取次数: ', Stats.AcquireCount);
    WriteLn('竞争次数: ', Stats.ContentionCount);
    WriteLn('竞争率: ', WithStats.GetContentionRate:0:2, '%');
    WriteLn('平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  end;
end;
```

## ⚡ 性能特征

### 适用场景
- **短临界区**: < 100 条指令的操作
- **低竞争**: 锁持有时间很短
- **高频访问**: 需要最小化同步开销
- **实时系统**: 需要确定性的延迟

### 基准测试数据

#### 单线程性能
- **操作数**: 1,000,000 次 acquire/release
- **执行时间**: ~20ms
- **吞吐量**: ~50,000,000 ops/sec
- **每次操作**: ~0.020μs

#### 多线程性能 (4线程)
- **操作数**: 400,000 次 (每线程 100,000)
- **执行时间**: ~100ms
- **吞吐量**: ~4,000,000 ops/sec
- **竞争率**: ~0.20%
- **平均自旋次数**: ~4.76

#### 退避策略对比 (8线程高竞争)

| 策略 | 执行时间 | 吞吐量 | 竞争率 | 平均自旋次数 |
|------|----------|--------|--------|--------------|
| 线性退避 | 101ms | 3.96M ops/sec | 0.26% | 3.15 |
| 指数退避 | 100ms | 4.00M ops/sec | 0.00% | 9.92 |
| 自适应退避 | 100ms | 4.00M ops/sec | 0.16% | 3.33 |

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
   - 单核系统: 设置较小值 (8-16)
   - 多核系统: 设置中等值 (32-128)
   - 高负载系统: 动态调整 (16-64)

2. **退避策略选择**:
   - **线性退避**: 适合低竞争场景，快速让出CPU
   - **指数退避**: 适合中等竞争，平衡性能和公平性
   - **自适应退避**: 适合变化的负载，自动调整策略

3. **竞争检测**:
   ```pascal
   var Stats: TSpinLockStats;
   begin
     Stats := WithStats.GetStats;
     if WithStats.GetContentionRate > 10.0 then
     begin
       // 高竞争，考虑使用互斥锁或调整策略
       Policy := SpinLock.GetPolicy;
       Policy.MaxSpins := Policy.MaxSpins div 2; // 减少自旋
       SpinLock.UpdatePolicy(Policy);
     end;
   end;
   ```

4. **内存布局优化**:
   - 避免伪共享：将锁与其他频繁访问的数据分离
   - 缓存行对齐：确保锁结构不跨越缓存行边界

## 🧪 测试覆盖

### 基础功能测试
- ✅ 创建和销毁
- ✅ 基本获取/释放
- ✅ TryAcquire 操作
- ✅ 超时获取
- ✅ 重入检测 (Debug模式)
- ✅ 错误处理
- ✅ 状态查询

### 新接口测试
- ✅ GetPolicy/UpdatePolicy
- ✅ GetSpinCount/SetSpinCount
- ✅ IsHeld 状态检测
- ✅ GetCurrentSpins 计数
- ✅ GetOwnerThread 所有者

### 边界测试
- ✅ 最小/最大自旋次数
- ✅ 零超时处理
- ✅ 最大超时处理

### 退避策略测试
- ✅ 线性退避验证
- ✅ 指数退避验证
- ✅ 自适应退避验证

### 并发测试
- ✅ 多线程计数器 (8线程 x 1000次)
- ✅ 高竞争场景 (短持锁时间)
- ✅ 中等竞争场景 (长持锁时间)
- ✅ 极高竞争场景 (16线程)
- ✅ 并发 TryAcquire
- ✅ 性能基准测试

### 平台测试
- ✅ Windows (atomic_flag + 多阶段退避)
- ✅ Unix/Linux (自定义自旋逻辑)

### 统计功能测试
- ✅ 获取次数统计
- ✅ 竞争次数统计
- ✅ 自旋次数统计
- ✅ 竞争率计算

## 🔄 与其他模块的关系

### 依赖关系
```
fafafa.core.sync.spin
├── fafafa.core.sync.base (基础接口)
├── fafafa.core.sync.spin.base (策略和类型定义)
├── fafafa.core.atomic (Windows 平台)
└── pthreads (Unix 平台)
```

### 集成使用
```pascal
uses
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin,
  fafafa.core.sync.mutex;

// 根据场景选择合适的同步原语
function CreateLock(IsShortCriticalSection: Boolean): ILock;
var
  Policy: TSpinLockPolicy;
begin
  if IsShortCriticalSection then
  begin
    Policy := DefaultSpinLockPolicy;
    Policy.MaxSpins := 64;
    Policy.BackoffStrategy := sbsAdaptive;
    Result := MakeSpinLock(Policy);
  end
  else
    Result := CreateMutex;
end;
```

## 📁 示例和基准

### 示例程序
- `examples/fafafa.core.sync.spin/example_basic_usage` - 基本使用示例
- `examples/fafafa.core.sync.spin/example_use_cases` - 实际使用场景
- `examples/fafafa.core.sync.spin/benchmark_performance` - 性能基准测试

### 运行示例
```bash
cd examples/fafafa.core.sync.spin
./build.sh
./bin/example_basic_usage
./bin/benchmark_performance
./bin/example_use_cases
```

## 📈 未来扩展

### 已完成功能
- ✅ 多种退避策略 (线性、指数、自适应)
- ✅ 性能统计信息
- ✅ 跨平台一致性
- ✅ 策略驱动架构
- ✅ 内存布局优化

### 计划功能
- [ ] 自适应自旋次数 (基于运行时负载)
- [ ] NUMA 感知优化
- [ ] 硬件事务内存支持
- [ ] 更精细的统计信息

### 性能优化
- [ ] 更好的缓存行对齐
- [ ] 分层自旋策略
- [ ] CPU 特定优化 (pause 指令变体)
