# 时钟抽象改进方案

## 当前时钟架构分析

### 现有接口
- `IMonotonicClock` - 单调时钟（用于测量）
- `ISystemClock` - 系统时钟（真实时间）
- `IClock` - 综合时钟接口
- `IFixedClock` - 测试用固定时钟

### 发现的问题
1. **错误处理不一致**：某些操作可能失败但没有返回 Result
2. **缺少时钟精度信息**：用户无法知道时钟的实际精度
3. **测试支持不足**：FixedClock 功能有限

## 改进建议

### 1. 增强时钟精度信息

```pascal
type
  TClockPrecision = (
    cpNanosecond,   // 纳秒级精度
    cpMicrosecond,  // 微秒级精度
    cpMillisecond,  // 毫秒级精度
    cpSecond        // 秒级精度
  );

  TClockCapabilities = set of (
    ccMonotonic,     // 保证单调递增
    ccHighResolution,// 高精度
    ccSystemTime,    // 可获取系统时间
    ccAdjustable     // 可调整（用于测试）
  );

  IClockInfo = interface
    ['{...}']
    function GetPrecision: TClockPrecision;
    function GetResolution: TDuration;  // 实际分辨率
    function GetCapabilities: TClockCapabilities;
    function GetImplementation: string; // 例如 "QueryPerformanceCounter"
  end;

  IMonotonicClock = interface
    // ... 现有方法 ...
    
    // 新增：时钟信息
    function GetClockInfo: IClockInfo;
    
    // 新增：安全版本
    function TryNowInstant: TResult<TInstant, TClockError>;
  end;
```

### 2. 改进睡眠机制

```pascal
type
  TSleepPrecision = (
    spBestEffort,   // 尽力而为（默认）
    spHighPrecision,// 高精度（可能消耗更多CPU）
    spPowerSaving   // 节能模式
  );

  TSleepResult = record
    Requested: TDuration;
    Actual: TDuration;
    Overslept: TDuration; // 实际睡眠时间超出请求的部分
    Precision: TSleepPrecision;
  end;

  IMonotonicClock = interface
    // ... 现有方法 ...
    
    // 增强的睡眠方法
    function SleepForEx(const D: TDuration; 
                        Precision: TSleepPrecision = spBestEffort): TSleepResult;
    
    // 可中断睡眠
    function InterruptibleSleep(const D: TDuration; 
                                const Token: ICancellationToken): Boolean;
  end;
```

### 3. 增强测试时钟

```pascal
type
  ITestClock = interface(IFixedClock)
    ['{...}']
    // 时间控制
    procedure Freeze;  // 冻结时间
    procedure Unfreeze; // 解冻时间
    procedure SetSpeed(Factor: Double); // 设置时间流速（2.0 = 2倍速）
    
    // 自动前进
    procedure EnableAutoAdvance(const Step: TDuration);
    procedure DisableAutoAdvance;
    
    // 等待触发器
    procedure WaitForTimers; // 等待所有定时器触发
    function GetPendingTimers: TArray<TInstant>; // 获取待触发的时间点
    
    // 记录和回放
    procedure StartRecording;
    procedure StopRecording;
    function GetRecording: TArray<TInstant>;
    procedure Replay(const Recording: TArray<TInstant>);
  end;

// 使用示例
procedure TestTimeoutBehavior;
var
  Clock: ITestClock;
  Timeout: ITimeout;
begin
  Clock := CreateTestClock;
  Clock.SetSpeed(10); // 10倍速测试
  
  Timeout := CreateTimeout(TDuration.FromSec(60), Clock);
  
  // 快速前进到超时
  Clock.AdvanceBy(TDuration.FromSec(6)); // 实际等待6秒 = 60秒
  
  Assert(Timeout.IsExpired);
end;
```

### 4. 时钟源抽象

```pascal
type
  // 时钟源接口，允许切换不同的底层实现
  IClockSource = interface
    ['{...}']
    function GetTicks: UInt64;
    function GetFrequency: UInt64;
    function GetPrecision: TClockPrecision;
    function IsMonotonic: Boolean;
  end;

  // 不同平台的时钟源
  TWindowsQPCSource = class(TInterfacedObject, IClockSource)
    // 使用 QueryPerformanceCounter
  end;

  TLinuxClockSource = class(TInterfacedObject, IClockSource)
    // 使用 clock_gettime(CLOCK_MONOTONIC)
  end;

  TMacOSClockSource = class(TInterfacedObject, IClockSource)
    // 使用 mach_absolute_time
  end;

  // 时钟工厂
  TClockFactory = class
  public
    class function CreateBestClock: IMonotonicClock;
    class function CreateWithSource(const Source: IClockSource): IMonotonicClock;
    class function GetAvailableSources: TArray<IClockSource>;
  end;
```

### 5. 时间同步支持

```pascal
type
  INetworkTimeSyncClient = interface
    ['{...}']
    function GetServerTime: TResult<TSystemTime, TNetworkError>;
    function GetClockOffset: TDuration; // 本地时钟与服务器的偏差
    procedure Sync; // 执行时间同步
  end;

  ISynchronizedClock = interface(ISystemClock)
    ['{...}']
    procedure SetSyncClient(const Client: INetworkTimeSyncClient);
    function GetLastSyncTime: TOption<TInstant>;
    function GetSyncAccuracy: TOption<TDuration>;
    function IsSynchronized: Boolean;
  end;
```

## 实施优先级

### 🔴 高优先级
1. **时钟信息接口** - 让用户了解时钟能力
2. **安全的 TryNowInstant** - 处理时钟获取失败
3. **增强测试时钟** - 改进单元测试

### 🟡 中优先级
1. **改进睡眠机制** - 提供更精确的睡眠控制
2. **时钟源抽象** - 更灵活的实现切换

### 🟢 低优先级
1. **网络时间同步** - 高级功能
2. **时钟记录回放** - 调试功能

## 性能考虑

### 优化建议

```pascal
type
  // 缓存时钟，减少系统调用
  TCachedClock = class(TInterfacedObject, IMonotonicClock)
  private
    FSource: IMonotonicClock;
    FCache: TInstant;
    FCacheValid: Boolean;
    FCacheDuration: TDuration;
    FLastUpdate: TInstant;
  public
    constructor Create(const Source: IMonotonicClock; 
                      CacheDuration: TDuration = TDuration.FromMs(1));
    
    function NowInstant: TInstant;
    // 实现：如果缓存有效则返回缓存值，否则更新缓存
  end;

  // 批量时间获取
  IBatchClock = interface
    ['{...}']
    function GetBatchTimes(Count: Integer): TArray<TInstant>;
    // 一次系统调用获取多个时间点，减少开销
  end;
```

## 兼容性保证

所有改进都是增量式的：
- ✅ 保留现有接口
- ✅ 新增方法使用默认参数
- ✅ 通过新接口扩展功能

## 测试策略

```pascal
procedure TestClockPrecision;
var
  Clock: IMonotonicClock;
  Info: IClockInfo;
  T1, T2: TInstant;
  MinDiff: TDuration;
  I: Integer;
begin
  Clock := CreateBestClock;
  Info := Clock.GetClockInfo;
  
  // 测试实际精度
  MinDiff := TDuration.FromSec(1);
  for I := 1 to 1000 do
  begin
    T1 := Clock.NowInstant;
    T2 := Clock.NowInstant;
    if not T2.Equal(T1) then
      MinDiff := TDuration.Min(MinDiff, T2.Diff(T1));
  end;
  
  WriteLn('Claimed precision: ', Info.GetResolution.AsNs, ' ns');
  WriteLn('Measured precision: ', MinDiff.AsNs, ' ns');
end;
```

## 预期收益

1. **透明度**：用户清楚了解时钟能力和限制
2. **可测试性**：强大的测试时钟支持
3. **可靠性**：明确的错误处理
4. **性能**：缓存和批量操作优化
5. **灵活性**：可切换时钟源