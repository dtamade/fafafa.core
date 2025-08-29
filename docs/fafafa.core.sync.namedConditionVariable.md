# fafafa.core.sync.namedConditionVariable

## 概述

`fafafa.core.sync.namedConditionVariable` 模块提供了跨进程的命名条件变量实现，支持进程间的条件同步。该模块严格遵循 `fafafa.core.sync.namedMutex` 的设计模式，并与现有的 `fafafa.core.sync.conditionVariable` 保持接口一致性。

## 核心特性

### ✨ 现代化设计
- **接口一致性**：继承自 `IConditionVariable`，与进程内条件变量完全兼容
- **RAII 模式**：自动资源管理，无需手动清理
- **类型安全**：强类型接口，编译时错误检查
- **配置驱动**：灵活的参数调整和性能优化

### 🌍 跨进程支持
- **Windows**：Event + Semaphore + 共享内存状态管理
- **Unix/Linux**：POSIX 共享条件变量 + 共享内存
- **完全隐藏平台差异**：统一的 API 接口
- **自动平台检测**：编译时选择最优实现

### 🎯 条件变量特性
- **Wait 操作**：原子释放互斥锁并等待条件
- **Signal 操作**：唤醒一个等待的进程
- **Broadcast 操作**：唤醒所有等待的进程
- **超时控制**：精确的时间控制机制
- **统计监控**：可选的详细性能统计

### 🔒 同步保证
- **原子性**：Wait 操作的释放锁和等待是原子的
- **无虚假唤醒**：通过广播代数防止虚假唤醒
- **线程安全**：所有操作都是线程安全的
- **进程安全**：支持多进程并发访问

## 架构设计

### 模块结构

```
fafafa.core.sync.namedConditionVariable/
├── fafafa.core.sync.namedConditionVariable.base.pas      # 基础接口定义
├── fafafa.core.sync.namedConditionVariable.windows.pas   # Windows 平台实现
├── fafafa.core.sync.namedConditionVariable.unix.pas      # Unix/Linux 平台实现
└── fafafa.core.sync.namedConditionVariable.pas           # 统一工厂门面层
```

### 设计模式

本模块完全遵循 `fafafa.core.sync.namedMutex` 的设计模式：

1. **三层架构**：接口层 → 实现层 → 门面层
2. **工厂模式**：隐藏实现细节，仅使用 `MakeXXX` 函数
3. **配置驱动**：灵活的参数调整
4. **统计监控**：可选的性能分析

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.namedConditionVariable, fafafa.core.sync.namedMutex;

var
  LMutex: INamedMutex;
  LCondVar: INamedConditionVariable;
  LGuard: INamedMutexGuard;
begin
  // 创建命名互斥锁和条件变量
  LMutex := MakeNamedMutex('MyAppMutex');
  LCondVar := MakeNamedConditionVariable('MyAppCondition');

  // 等待条件
  LGuard := LMutex.Lock;
  try
    while not SomeCondition do
    begin
      WriteLn('等待条件满足...');
      LCondVar.Wait(LMutex); // 原子释放锁并等待
    end;
    WriteLn('条件已满足，继续执行');
  finally
    LGuard := nil;
  end;
end;
```

### 生产者-消费者模式

```pascal
// 生产者进程
procedure Producer;
var
  LMutex: INamedMutex;
  LNotFull: INamedConditionVariable;
  LNotEmpty: INamedConditionVariable;
  LGuard: INamedMutexGuard;
begin
  LMutex := MakeNamedMutex('BufferMutex');
  LNotFull := MakeNamedConditionVariable('BufferNotFull');
  LNotEmpty := MakeNamedConditionVariable('BufferNotEmpty');

  LGuard := LMutex.Lock;
  try
    // 等待缓冲区不满
    while BufferIsFull do
      LNotFull.Wait(LMutex);
      
    // 生产项目
    ProduceItem;
    
    // 通知消费者
    LNotEmpty.Signal;
  finally
    LGuard := nil;
  end;
end;

// 消费者进程
procedure Consumer;
var
  LMutex: INamedMutex;
  LNotFull: INamedConditionVariable;
  LNotEmpty: INamedConditionVariable;
  LGuard: INamedMutexGuard;
begin
  LMutex := MakeNamedMutex('BufferMutex');
  LNotFull := MakeNamedConditionVariable('BufferNotFull');
  LNotEmpty := MakeNamedConditionVariable('BufferNotEmpty');

  LGuard := LMutex.Lock;
  try
    // 等待缓冲区非空
    while BufferIsEmpty do
      LNotEmpty.Wait(LMutex);
      
    // 消费项目
    ConsumeItem;
    
    // 通知生产者
    LNotFull.Signal;
  finally
    LGuard := nil;
  end;
end;
```

### 带超时的等待

```pascal
var
  LMutex: INamedMutex;
  LCondVar: INamedConditionVariable;
  LGuard: INamedMutexGuard;
  LResult: Boolean;
begin
  LMutex := MakeNamedMutex('MyMutex');
  LCondVar := MakeNamedConditionVariable('MyCondition');

  LGuard := LMutex.Lock;
  try
    // 等待最多5秒
    LResult := LCondVar.Wait(LMutex, 5000);
    if LResult then
      WriteLn('条件在超时内满足')
    else
      WriteLn('等待超时');
  finally
    LGuard := nil;
  end;
end;
```

## API 参考

### 核心接口

#### INamedConditionVariable

主要的命名条件变量接口，继承自 `IConditionVariable`。

```pascal
INamedConditionVariable = interface(IConditionVariable)
  // 继承自 IConditionVariable 的方法：
  procedure Wait(const ALock: ILock); overload;                    // 无限等待
  function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload; // 带超时等待
  procedure Signal;                                                // 唤醒一个等待者
  procedure Broadcast;                                             // 唤醒所有等待者
  
  // 继承自 ILock 的方法（条件变量内部锁）：
  procedure Acquire;                                               // 获取内部锁
  procedure Release;                                               // 释放内部锁
  function TryAcquire: Boolean; overload;                          // 尝试获取内部锁
  function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;    // 带超时尝试获取
  
  // 继承自 ISynchronizable 的方法：
  function GetLastError: TWaitError;                               // 获取最后错误
  
  // 命名条件变量特有的方法：
  function GetName: string;                                        // 获取名称
  function GetConfig: TNamedConditionVariableConfig;               // 获取配置
  procedure UpdateConfig(const AConfig: TNamedConditionVariableConfig); // 更新配置
  function GetStats: TNamedConditionVariableStats;                 // 获取统计
  procedure ResetStats;                                            // 重置统计
end;
```

### 配置结构

#### TNamedConditionVariableConfig

```pascal
TNamedConditionVariableConfig = record
  TimeoutMs: Cardinal;              // 默认超时时间（毫秒）
  UseGlobalNamespace: Boolean;      // 是否使用全局命名空间
  MaxWaiters: Cardinal;             // 最大等待者数量
  EnableStats: Boolean;             // 是否启用统计信息
end;
```

#### TNamedConditionVariableStats

```pascal
TNamedConditionVariableStats = record
  WaitCount: QWord;                 // 总等待次数
  SignalCount: QWord;               // 总信号次数
  BroadcastCount: QWord;            // 总广播次数
  TimeoutCount: QWord;              // 超时次数
  CurrentWaiters: Integer;          // 当前等待者数量
  MaxWaiters: Integer;              // 历史最大等待者数量
  TotalWaitTimeUs: QWord;           // 总等待时间（微秒）
  MaxWaitTimeUs: QWord;             // 最大单次等待时间（微秒）
end;
```

### 工厂函数

#### 主要工厂函数

```pascal
// 基本工厂函数
function MakeNamedConditionVariable(const AName: string): INamedConditionVariable; overload;
function MakeNamedConditionVariable(const AName: string; const AConfig: TNamedConditionVariableConfig): INamedConditionVariable; overload;

// 便利工厂函数
function MakeGlobalNamedConditionVariable(const AName: string): INamedConditionVariable;
function MakeNamedConditionVariableWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedConditionVariable;
function MakeNamedConditionVariableWithStats(const AName: string): INamedConditionVariable;

// 兼容性函数
function TryOpenNamedConditionVariable(const AName: string): INamedConditionVariable;
```

### 配置辅助函数

```pascal
function DefaultNamedConditionVariableConfig: TNamedConditionVariableConfig;
function NamedConditionVariableConfigWithTimeout(ATimeoutMs: Cardinal): TNamedConditionVariableConfig;
function GlobalNamedConditionVariableConfig: TNamedConditionVariableConfig;
function EmptyNamedConditionVariableStats: TNamedConditionVariableStats;

## 配置类型详解

### 默认配置 (DefaultNamedConditionVariableConfig)
- **适用场景**：通用场景
- **超时时间**：30秒
- **最大等待者**：64个
- **全局命名空间**：关闭
- **统计信息**：关闭

### 全局配置 (GlobalNamedConditionVariableConfig)
- **适用场景**：跨会话同步
- **全局命名空间**：开启
- **其他参数**：同默认配置

### 带统计配置 (MakeNamedConditionVariableWithStats)
- **适用场景**：性能分析和调优
- **统计信息**：开启
- **其他参数**：同默认配置

## 最佳实践

### 1. 正确的使用模式

```pascal
// ✅ 推荐：标准的条件变量使用模式
LGuard := LMutex.Lock;
try
  while not Condition do
    LCondVar.Wait(LMutex);
  // 条件满足，执行操作
finally
  LGuard := nil;
end;

// ❌ 错误：不检查条件就等待
LGuard := LMutex.Lock;
try
  LCondVar.Wait(LMutex); // 可能虚假唤醒
  // 直接执行操作 - 危险！
finally
  LGuard := nil;
end;
```

### 2. 避免死锁

```pascal
// ✅ 正确：使用相同的锁顺序
LMutex1.Acquire;
try
  LMutex2.Acquire;
  try
    // 操作
  finally
    LMutex2.Release;
  end;
finally
  LMutex1.Release;
end;

// ❌ 错误：不同的锁顺序可能导致死锁
```

### 3. 合理使用 Signal vs Broadcast

```pascal
// 使用 Signal：只有一个等待者需要被唤醒
if ItemAvailable then
  LCondVar.Signal; // 只唤醒一个消费者

// 使用 Broadcast：所有等待者都需要重新检查条件
if ShutdownRequested then
  LCondVar.Broadcast; // 唤醒所有工作线程
```

### 4. 超时处理

```pascal
LGuard := LMutex.Lock;
try
  LStartTime := GetTickCount64;
  while not Condition and (GetTickCount64 - LStartTime < TimeoutMs) do
  begin
    LRemainingTime := TimeoutMs - (GetTickCount64 - LStartTime);
    if not LCondVar.Wait(LMutex, LRemainingTime) then
      Break; // 超时
  end;

  if Condition then
    WriteLn('条件满足')
  else
    WriteLn('等待超时');
finally
  LGuard := nil;
end;
```

## 跨进程使用

### 基本跨进程同步

```pascal
// 进程 A
var
  LMutex: INamedMutex;
  LCondVar: INamedConditionVariable;
  LGuard: INamedMutexGuard;
begin
  LMutex := MakeNamedMutex('SharedMutex');
  LCondVar := MakeNamedConditionVariable('SharedCondition');

  LGuard := LMutex.Lock;
  try
    // 修改共享状态
    UpdateSharedState;
    // 通知其他进程
    LCondVar.Broadcast;
  finally
    LGuard := nil;
  end;
end;

// 进程 B (使用相同名称)
var
  LMutex: INamedMutex;
  LCondVar: INamedConditionVariable;
  LGuard: INamedMutexGuard;
begin
  LMutex := MakeNamedMutex('SharedMutex'); // 同名
  LCondVar := MakeNamedConditionVariable('SharedCondition'); // 同名

  LGuard := LMutex.Lock;
  try
    while not CheckSharedState do
      LCondVar.Wait(LMutex);
    // 处理共享状态
    ProcessSharedState;
  finally
    LGuard := nil;
  end;
end;
```

### 全局条件变量

```pascal
var
  LCondVar: INamedConditionVariable;
begin
  // 创建跨会话的全局条件变量
  LCondVar := MakeGlobalNamedConditionVariable('GlobalAppCondition');

  // 使用方式与普通条件变量相同
  LCondVar.Signal;
end;
```

## 命名规则

### Windows 平台

- 名称长度限制：260 字符 (MAX_PATH)
- 支持 `Global\` 前缀：跨会话共享
- 支持 `Local\` 前缀：当前会话内共享
- 不能包含反斜杠（除前缀外）

### Unix/Linux 平台

- 名称长度限制：255 字符 (NAME_MAX)
- 自动添加 `/` 前缀符合 POSIX 规范
- 不能包含额外的 `/` 字符
- 区分大小写

## 错误处理

### 异常类型

- `EInvalidArgument`: 无效的条件变量名称或参数
- `ELockError`: 条件变量操作失败
- `ETimeoutError`: 等待超时

### 常见错误

```pascal
try
  LCondVar := MakeNamedConditionVariable('');
except
  on E: EInvalidArgument do
    WriteLn('错误：条件变量名称不能为空');
end;

try
  LResult := LCondVar.Wait(nil, 1000);
except
  on E: EInvalidArgument do
    WriteLn('错误：互斥锁不能为空');
end;
```

## 性能特征

### 典型性能数据

在典型的多核系统上：

- **无竞争等待**：< 1 微秒
- **轻度竞争**：< 10 微秒
- **中度竞争**：10-100 微秒
- **重度竞争**：100 微秒 - 1 毫秒

### 性能优化建议

1. **减少等待者数量**：避免大量进程同时等待同一个条件
2. **合理使用超时**：避免无限等待导致的资源浪费
3. **启用统计监控**：在开发阶段启用统计以分析性能瓶颈
4. **选择合适的信号策略**：Signal vs Broadcast

## 线程安全

### 安全保证

- **接口线程安全**：所有 `INamedConditionVariable` 方法都是线程安全的
- **跨进程安全**：支持多进程并发访问
- **原子性保证**：Wait 操作的释放锁和等待是原子的

### 注意事项

```pascal
// ✅ 安全：在不同线程/进程中使用同一个条件变量
var GlobalCondVar: INamedConditionVariable;

procedure Thread1;
begin
  GlobalCondVar.Signal;
end;

procedure Thread2;
var LGuard: INamedMutexGuard;
begin
  LGuard := GlobalMutex.Lock;
  try
    GlobalCondVar.Wait(GlobalMutex);
  finally
    LGuard := nil;
  end;
end;
```

## 调试和诊断

### 启用统计信息

```pascal
var
  LCondVar: INamedConditionVariable;
  LStats: TNamedConditionVariableStats;
begin
  LCondVar := MakeNamedConditionVariableWithStats('DebugCondVar');

  // 执行一些操作...

  LStats := LCondVar.GetStats;
  WriteLn('诊断信息:');
  WriteLn('  等待次数: ', LStats.WaitCount);
  WriteLn('  信号次数: ', LStats.SignalCount);
  WriteLn('  广播次数: ', LStats.BroadcastCount);
  WriteLn('  当前等待者: ', LStats.CurrentWaiters);
  WriteLn('  超时次数: ', LStats.TimeoutCount);
end;
```

## 示例代码

完整的示例代码位于 `examples/fafafa.core.sync.namedConditionVariable/` 目录：

- `example_producer_consumer.pas`: 生产者-消费者模式示例
- `example_work_queue.pas`: 工作队列模式示例

## 版本历史

### v1.0.0 (当前版本)
- 初始发布
- 完整的 Windows 和 Unix/Linux 支持
- 继承自 IConditionVariable 的一致接口
- 跨进程条件同步功能
- 统计监控和性能分析

## 许可证

本模块遵循与 fafafa.core 项目相同的许可证。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进本模块。

---

*最后更新：2025-08-28*
```
