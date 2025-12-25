unit fafafa.core.time.timer.base;

{$modeswitch advancedrecords}
{$mode objfpc}
{$I fafafa.core.settings.inc}

// ✅ Phase 2.1: 从 timer.pas 拆分出的基础类型定义
// 包含：回调类型、枚举、接口、常量、Options/Result 类型

interface

uses
  Classes, SysUtils,
  fafafa.core.result,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.thread.threadpool,
  fafafa.core.thread.cancel;

type
  // Callback procedure types
  TProc = procedure;                            // 无参数过程（向后兼容）
  TTimerProc = procedure;                       // 别名
  TTimerProcData = procedure(Data: Pointer);    // 带用户数据
  TTimerMethod = procedure of object;           // 对象方法
  TTimerProcNested = procedure is nested;       // 嵌套过程

  // ✅ v2.0: 统一回调类型系统
  TTimerCallbackKind = (
    tckProc,        // procedure
    tckProcData,    // procedure(Data: Pointer)
    tckMethod,      // procedure of object
    tckNested       // procedure is nested
  );

  TTimerCallback = record
    case Kind: TTimerCallbackKind of
      tckProc: (Proc: TTimerProc);
      tckProcData: (ProcData: TTimerProcData; Data: Pointer);
      tckMethod: (Method: TTimerMethod);
      tckNested: (Nested: TTimerProcNested);
  end;

  // ✅ v2.0: 定时器类型枚举
  TTimerKind = (
    tkOnce,       // 一次性定时器
    tkFixedRate,  // 固定频率周期定时器
    tkFixedDelay  // 固定延迟周期定时器
  );

  ITimer = interface
    ['{D9A1B6C6-0C1D-4A6E-9F2B-0AF4B7A3ED1B}']
    // 取消定时器
    procedure Cancel;
    function IsCancelled: Boolean;

    // Reset/Reschedule（仅支持一次性定时器；周期定时器返回 False）
    function ResetAt(const Deadline: TInstant): Boolean;
    function ResetAfter(const Delay: TDuration): Boolean;

    // ✅ v2.0: 状态查询
    function GetNextDeadline: TInstant;       // 下次触发时间
    function GetExecutionCount: QWord;        // 已执行次数
    function GetKind: TTimerKind;             // 定时器类型
    function IsFired: Boolean;                // 是否已触发（Once 定时器）

    // ✅ v2.0: 周期定时器控制（仅对 FixedRate/FixedDelay 有效）
    function Pause: Boolean;                  // 暂停定时器
    function Resume: Boolean;                 // 恢复定时器
    function IsPaused: Boolean;               // 是否已暂停

    // ✅ v2.0: 执行次数限制（仅对周期定时器有效）
    function SetMaxExecutions(Max: QWord): Boolean;  // 设置最大执行次数（0=无限制）
    function GetMaxExecutions: QWord;                // 获取最大执行次数
  end;

  ITimerScheduler = interface
    ['{2B7B9D2C-8F9B-4C4D-9C8E-7E83F7C994A4}']
    // 一次性（TProc 版本 - 向后兼容，建议迁移到 TTimerCallback 版本）
    function ScheduleOnce(const Delay: TDuration; const Callback: TProc): ITimer; deprecated 'Use Schedule(Delay, TimerCallback(Callback)) instead';
    function ScheduleAt(const Deadline: TInstant; const Callback: TProc): ITimer; deprecated 'Use ScheduleAtCb(Deadline, TimerCallback(Callback)) instead';
    // 周期（TProc 版本 - 向后兼容，建议迁移到 TTimerCallback 版本）
    function ScheduleAtFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): ITimer; deprecated 'Use ScheduleFixedRate(InitialDelay, Period, TimerCallback(Callback)) instead';
    function ScheduleWithFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): ITimer; deprecated 'Use ScheduleFixedDelay(InitialDelay, Delay, TimerCallback(Callback)) instead';

    // ✅ v2.0: TTimerCallback 版本（推荐使用）
    function Schedule(const Delay: TDuration; const Callback: TTimerCallback): ITimer;
    function ScheduleAtCb(const Deadline: TInstant; const Callback: TTimerCallback): ITimer;
    function ScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback): ITimer;
    function ScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback): ITimer;

    // ✅ v2.0: 带取消令牌的版本
    function ScheduleWithToken(const Delay: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
    function ScheduleFixedRateWithToken(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;
    function ScheduleFixedDelayWithToken(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback; const Token: ICancellationToken): ITimer;

    // 控制
    procedure Shutdown;

    // 异步回调执行支持
    procedure SetCallbackExecutor(const Pool: IThreadPool);
    function GetCallbackExecutor: IThreadPool;
  end;

  ITicker = interface
    ['{7F9E3C3A-0D6E-4C0E-9B7F-2F58E4E8F1C2}']
    procedure Stop;
    function IsStopped: Boolean;
  end;

  // Phase 1: Options / Result-style APIs
  TTimerSchedulerOptions = record
    Clock: IMonotonicClock;
    CallbackExecutor: IThreadPool;

    class function Default: TTimerSchedulerOptions; static; inline;
    function WithClock(const AClock: IMonotonicClock): TTimerSchedulerOptions; inline;
    function WithCallbackExecutor(const Pool: IThreadPool): TTimerSchedulerOptions; inline;
  end;

  TTimerResult = specialize TResult<ITimer, TTimeErrorKind>;

  ITimerSchedulerTry = interface(ITimerScheduler)
    ['{8C1A5A0B-6BB7-4C1E-9F7E-7B20E8F4AA10}']
    function TrySchedule(const Delay: TDuration; const Callback: TTimerCallback): TTimerResult; overload;
    function TrySchedule(const Delay: TDuration; const Callback: TProc): TTimerResult; overload; deprecated 'Use TrySchedule(Delay, TimerCallback(Callback)) instead';

    function TryScheduleAt(const Deadline: TInstant; const Callback: TProc): TTimerResult; deprecated 'Use TryScheduleAtCb(Deadline, TimerCallback(Callback)) instead';
    function TryScheduleAtCb(const Deadline: TInstant; const Callback: TTimerCallback): TTimerResult;

    function TryScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TTimerCallback): TTimerResult; overload;
    function TryScheduleFixedRate(const InitialDelay: TDuration; const Period: TDuration; const Callback: TProc): TTimerResult; overload; deprecated 'Use TryScheduleFixedRate(InitialDelay, Period, TimerCallback(Callback)) instead';

    function TryScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TTimerCallback): TTimerResult; overload;
    function TryScheduleFixedDelay(const InitialDelay: TDuration; const Delay: TDuration; const Callback: TProc): TTimerResult; overload; deprecated 'Use TryScheduleFixedDelay(InitialDelay, Delay, TimerCallback(Callback)) instead';
  end;

  // 异常处理器类型
  TTimerExceptionHandler = procedure(const E: Exception);

  // 指标记录
  TTimerMetrics = record
    ScheduledTotal: QWord;
    FiredTotal: QWord;
    CancelledTotal: QWord;
    ExceptionTotal: QWord;
  end;

const
  // ✅ ISSUE-REVIEW-P2-3: 定时器堆最大容量限制（防止 DoS 攻击）
  // 默认 100 万个定时器，约 40MB 内存占用（按 40 字节/条目估算）
  TIMER_HEAP_MAX_CAPACITY = 1000000;

implementation

{ TTimerSchedulerOptions }
class function TTimerSchedulerOptions.Default: TTimerSchedulerOptions;
begin
  Result.Clock := nil;
  Result.CallbackExecutor := nil;
end;

function TTimerSchedulerOptions.WithClock(const AClock: IMonotonicClock): TTimerSchedulerOptions;
begin
  Result := Self;
  Result.Clock := AClock;
end;

function TTimerSchedulerOptions.WithCallbackExecutor(const Pool: IThreadPool): TTimerSchedulerOptions;
begin
  Result := Self;
  Result.CallbackExecutor := Pool;
end;

end.
