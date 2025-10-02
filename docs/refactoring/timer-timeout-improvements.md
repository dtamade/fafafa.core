# 定时器和超时管理改进方案

## 1. 定时器模块改进

### 当前问题
- `ITimer` 接口的错误处理不明确（返回 nil 还是抛异常？）
- 缺少定时器创建失败的错误反馈
- 回调异常处理依赖全局变量

### 改进建议

#### 1.1 增强错误处理

```pascal
type
  TTimerError = (
    teInvalidDelay,      // 无效的延迟时间
    teSchedulerShutdown, // 调度器已关闭
    teResourceExhausted, // 资源耗尽
    teCallbackError      // 回调执行错误
  );

  TTimerResult = specialize TResult<ITimer, TTimerError>;

  ITimerScheduler = interface
    // 保留原有接口
    function ScheduleOnce(const Delay: TDuration; const Callback: TProc): ITimer;
    
    // 新增安全版本
    function TryScheduleOnce(const Delay: TDuration; const Callback: TProc): TTimerResult;
    function TryScheduleAt(const Deadline: TInstant; const Callback: TProc): TTimerResult;
  end;
```

#### 1.2 改进回调异常处理

```pascal
type
  // 回调执行结果
  TCallbackResult = record
    Success: Boolean;
    ExecutionTime: TDuration;
    Error: Exception; // nil if Success
  end;

  // 增强的回调类型
  TTimerCallbackEx = function: TCallbackResult;
  
  ITimer = interface
    // ... 现有方法 ...
    
    // 新增：获取最后一次执行结果
    function GetLastResult: TOption<TCallbackResult>;
    
    // 新增：设置错误处理策略
    procedure SetErrorStrategy(Strategy: TErrorStrategy);
  end;

  TErrorStrategy = (
    esIgnore,      // 忽略错误，继续执行
    esLog,         // 记录错误，继续执行
    esStop,        // 停止定时器
    esRetry        // 重试执行
  );
```

#### 1.3 实现示例

```pascal
function TTimerSchedulerImpl.TryScheduleOnce(
  const Delay: TDuration; 
  const Callback: TProc
): TTimerResult;
begin
  // 验证参数
  if Delay.IsNegative then
    Exit(TTimerResult.Err(teInvalidDelay));
    
  if FShuttingDown then
    Exit(TTimerResult.Err(teSchedulerShutdown));
    
  // 尝试创建定时器
  try
    var Timer := InternalScheduleOnce(Delay, Callback);
    Result := TTimerResult.Ok(Timer);
  except
    on E: EOutOfMemory do
      Result := TTimerResult.Err(teResourceExhausted);
    on E: Exception do
      Result := TTimerResult.Err(teCallbackError);
  end;
end;
```

## 2. 超时管理改进

### 当前设计评审
- `TDeadline` 设计良好，但缺少 Option 支持
- 超时管理器接口过于复杂

### 改进建议

#### 2.1 使用 Option 优化 TDeadline

```pascal
type
  TDeadline = record
  private
    FInstant: TOption<TInstant>; // None 表示永不超时
  public
    class function Never: TDeadline; static; inline;
    class function Now: TDeadline; static; inline;
    class function After(const D: TDuration): TDeadline; static; inline;
    
    // 返回 Option，更清晰地表达"可能没有截止时间"
    function GetInstant: TOption<TInstant>; inline;
    function Remaining: TOption<TDuration>; inline;
    
    // 新增：安全比较
    function SafeCompare(const Other: TDeadline): TOption<Integer>;
  end;

implementation

class function TDeadline.Never: TDeadline;
begin
  Result.FInstant := TOption<TInstant>.None;
end;

function TDeadline.Remaining: TOption<TDuration>;
begin
  if FInstant.IsNone then
    Exit(TOption<TDuration>.None); // 永不超时
    
  var Now := DefaultMonotonicClock.NowInstant;
  var Deadline := FInstant.Unwrap;
  
  if Now.GreaterThan(Deadline) then
    Exit(TOption<TDuration>.Some(TDuration.Zero))
  else
    Exit(TOption<TDuration>.Some(Deadline.Sub(Now)));
end;
```

#### 2.2 简化超时管理器

```pascal
type
  // 简化的超时构建器
  TTimeoutBuilder = record
  private
    FDuration: TOption<TDuration>;
    FDeadline: TOption<TDeadline>;
    FStrategy: TTimeoutStrategy;
    FCallback: TOption<TTimeoutCallback>;
  public
    class function New: TTimeoutBuilder; static;
    
    function WithDuration(const D: TDuration): TTimeoutBuilder;
    function WithDeadline(const D: TDeadline): TTimeoutBuilder;
    function WithStrategy(S: TTimeoutStrategy): TTimeoutBuilder;
    function WithCallback(const C: TTimeoutCallback): TTimeoutBuilder;
    
    function Build: TResult<ITimeout, TTimeoutError>;
  end;

// 使用示例
var
  Timeout: ITimeout;
  Result: TResult<ITimeout, TTimeoutError>;
begin
  Result := TTimeoutBuilder.New
    .WithDuration(TDuration.FromSec(30))
    .WithStrategy(tsAdaptive)
    .WithCallback(@HandleTimeout)
    .Build;
    
  if Result.IsOk then
    Timeout := Result.Unwrap
  else
    // 处理创建失败
    ShowMessage('Failed to create timeout: ' + 
      GetEnumName(TypeInfo(TTimeoutError), Ord(Result.UnwrapErr)));
end;
```

## 3. 统一的等待机制

### 建议新增统一的等待接口

```pascal
type
  TWaitResult = (
    wrCompleted,  // 正常完成
    wrTimeout,    // 超时
    wrCancelled,  // 被取消
    wrError       // 发生错误
  );

  IWaitable = interface
    ['{...}']
    // 基础等待
    function Wait: TWaitResult;
    
    // 带超时的等待
    function WaitFor(const Timeout: TDuration): TWaitResult;
    
    // 带取消令牌的等待
    function WaitWithCancel(const Token: ICancellationToken): TWaitResult;
    
    // 组合等待
    function WaitWithOptions(
      const Timeout: TOption<TDuration>;
      const Token: TOption<ICancellationToken>
    ): TWaitResult;
  end;

  // 让 ITimer 和 ITimeout 都实现 IWaitable
  ITimer = interface(IWaitable)
    // ... 现有方法 ...
  end;

  ITimeout = interface(IWaitable)
    // ... 现有方法 ...
  end;
```

## 4. 性能监控增强

### 改进指标收集

```pascal
type
  TTimerMetricsEx = record
    // 基础统计
    ScheduledTotal: UInt64;
    FiredTotal: UInt64;
    CancelledTotal: UInt64;
    ExceptionTotal: UInt64;
    
    // 新增：性能指标
    MinExecutionTime: TDuration;
    MaxExecutionTime: TDuration;
    AvgExecutionTime: TDuration;
    TotalExecutionTime: TDuration;
    
    // 新增：延迟指标
    MinSchedulingDelay: TDuration;  // 实际触发时间 vs 计划时间
    MaxSchedulingDelay: TDuration;
    AvgSchedulingDelay: TDuration;
    
    // 新增：资源使用
    ActiveTimers: UInt32;
    PeakActiveTimers: UInt32;
    HeapSize: UInt32;
    
    // 时间戳
    CollectionStartTime: TInstant;
    LastUpdateTime: TInstant;
  end;

  ITimerScheduler = interface
    // ... 现有方法 ...
    
    // 新增：详细指标
    function GetMetricsEx: TTimerMetricsEx;
    procedure ResetMetrics;
    
    // 新增：实时监控
    function GetActiveTimerCount: UInt32;
    function GetPendingTimers: TArray<ITimer>;
  end;
```

## 5. 实施计划

### 第一阶段：核心改进（1周）
- [ ] 添加 TTimerResult 类型
- [ ] 实现 TryScheduleOnce/TryScheduleAt
- [ ] 改进 TDeadline 使用 Option

### 第二阶段：增强功能（1周）
- [ ] 实现 TTimeoutBuilder
- [ ] 添加 IWaitable 接口
- [ ] 统一等待机制

### 第三阶段：监控和优化（3天）
- [ ] 实现 TTimerMetricsEx
- [ ] 添加性能监控
- [ ] 优化内存使用

## 预期收益

1. **更安全**：明确的错误处理路径
2. **更灵活**：多种错误处理策略可选
3. **更清晰**：使用 Option/Result 表达可选值和错误
4. **更高效**：详细的性能监控帮助优化
5. **更统一**：统一的等待机制简化使用
