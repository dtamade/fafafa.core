unit fafafa.core.time.scheduler;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.scheduler - 任务调度器

📖 概述：
  提供任务调度功能，支持定时执行、周期执行、延迟执行等。
  包含 Cron 表达式支持和灵活的调度策略。

🔧 特性：
  • 多种调度策略
  • Cron 表达式支持
  • 任务优先级管理
  • 异常处理和重试
  • 线程池支持

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Classes,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.timeofday,
  fafafa.core.collections.priorityqueue;

type
  // 任务状态
  TTaskState = (
    tsIdle,       // 空闲
    tsScheduled,  // 已调度
    tsRunning,    // 运行中
    tsCompleted,  // 已完成
    tsFailed,     // 失败
    tsCancelled   // 已取消
  );

  // 调度策略
  TScheduleStrategy = (
    ssOnce,       // 一次性执行
    ssFixed,      // 固定间隔
    ssDelay,      // 延迟间隔（上次执行完成后开始计时）
    ssCron        // Cron 表达式
  );

  // 任务优先级
  TTaskPriority = (
    tpLow = 1,
    tpNormal = 5,
    tpHigh = 10,
    tpCritical = 15
  );

  // 重试策略
  TRetryStrategy = record
    MaxRetries: Integer;
    InitialDelay: TDuration;
    MaxDelay: TDuration;
    BackoffMultiplier: Double;
    
    class function None: TRetryStrategy; static;
    class function Simple(AMaxRetries: Integer): TRetryStrategy; static;
    class function Exponential(AMaxRetries: Integer; const AInitialDelay: TDuration): TRetryStrategy; static;
  end;

  // 前向声明
  IScheduledTask = interface;
  ITaskScheduler = interface;

  // 任务回调类型
  TTaskCallback = procedure(const ATask: IScheduledTask) of object;
  TTaskCallbackProc = procedure(const ATask: IScheduledTask);
  TTaskCallbackFunc = function(const ATask: IScheduledTask): Boolean; // 返回 True 表示成功

  {**
   * IScheduledTask - 调度任务接口
   *
   * @desc
   *   表示一个可调度的任务，包含执行逻辑和调度信息。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  IScheduledTask = interface
    ['{E6F5D4C3-B2A1-0F9E-8D7C-6B5A4F3E2D1C}']
    
    // 基本信息
    function GetId: string;
    function GetName: string;
    function GetDescription: string;
    function GetState: TTaskState;
    function GetPriority: TTaskPriority;
    function GetStrategy: TScheduleStrategy;
    
    // 调度信息
    function GetNextRunTime: TInstant;
    function GetLastRunTime: TInstant;
    function GetRunCount: Int64;
    function GetFailureCount: Int64;
    function GetCreatedTime: TInstant;
    
    // 控制操作
    procedure Start;
    procedure Stop;
    procedure Cancel;
    procedure Reset;
    
    // 状态查询
    function IsActive: Boolean;
    function IsRunning: Boolean;
    function IsCancelled: Boolean;
    function IsCompleted: Boolean;
    function HasFailed: Boolean;
    
    // 配置
    procedure SetPriority(APriority: TTaskPriority);
    procedure SetRetryStrategy(const AStrategy: TRetryStrategy);
    procedure SetCallback(const ACallback: TTaskCallback); overload;
    procedure SetCallback(const ACallback: TTaskCallbackProc); overload;
    procedure SetCallback(const ACallback: TTaskCallbackFunc); overload;
    
    // 执行控制
    function Execute: Boolean; // 手动执行
    procedure Skip; // 跳过下次执行
    
    // 统计信息
    function GetAverageExecutionTime: TDuration;
    function GetTotalExecutionTime: TDuration;
    function GetLastExecutionTime: TDuration;
    function GetLastError: string;
  end;

  {**
   * ITaskScheduler - 任务调度器接口
   *
   * @desc
   *   管理和调度多个任务的执行。
   *   提供线程池支持和优先级调度。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ITaskScheduler = interface
    ['{D5E4F3C2-B1A0-9F8E-7D6C-5B4A3F2E1D0C}']
    
    // 任务创建
    function CreateTask(const AName: string; const ACallback: TTaskCallback): IScheduledTask; overload;
    function CreateTask(const AName: string; const ACallback: TTaskCallbackProc): IScheduledTask; overload;
    function CreateTask(const AName: string; const ACallback: TTaskCallbackFunc): IScheduledTask; overload;
    
    // 调度方法
    function ScheduleOnce(const ATask: IScheduledTask; const ADelay: TDuration): Boolean; overload;
    function ScheduleOnce(const ATask: IScheduledTask; const ARunTime: TInstant): Boolean; overload;
    function ScheduleFixed(const ATask: IScheduledTask; const AInterval: TDuration; const AInitialDelay: TDuration): Boolean;
    function ScheduleDelay(const ATask: IScheduledTask; const ADelay: TDuration): Boolean;
    function ScheduleCron(const ATask: IScheduledTask; const ACronExpression: string): Boolean;
    
    // 便捷调度方法
    function ScheduleDaily(const ATask: IScheduledTask; const ATime: TTimeOfDay): Boolean;
    function ScheduleWeekly(const ATask: IScheduledTask; ADayOfWeek: Integer; const ATime: TTimeOfDay): Boolean;
    function ScheduleMonthly(const ATask: IScheduledTask; ADay: Integer; const ATime: TTimeOfDay): Boolean;
    
    // 任务管理
    procedure AddTask(const ATask: IScheduledTask);
    procedure RemoveTask(const ATask: IScheduledTask); overload;
    procedure RemoveTask(const ATaskId: string); overload;
    function GetTask(const ATaskId: string): IScheduledTask;
    function GetTasks: specialize TArray<IScheduledTask>; overload;
    function GetTasks(AState: TTaskState): specialize TArray<IScheduledTask>; overload;
    function GetTaskCount: Integer; overload;
    function GetTaskCount(AState: TTaskState): Integer; overload;
    
    // 调度器控制
    procedure Start;
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure Shutdown(const ATimeout: TDuration);
    function IsRunning: Boolean;
    function IsPaused: Boolean;
    
    // 配置
    procedure SetClock(const AClock: IMonotonicClock);
    function GetClock: IMonotonicClock;
    procedure SetMaxThreads(AMaxThreads: Integer);
    function GetMaxThreads: Integer;
    procedure SetDefaultRetryStrategy(const AStrategy: TRetryStrategy);
    function GetDefaultRetryStrategy: TRetryStrategy;
    
    // 统计信息
    function GetTotalTasksExecuted: Int64;
    function GetTotalTasksFailed: Int64;
    function GetAverageTaskExecutionTime: TDuration;
    function GetUptime: TDuration;
  end;

  {**
   * ICronExpression - Cron 表达式接口
   *
   * @desc
   *   解析和计算 Cron 表达式的下次执行时间。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ICronExpression = interface
    ['{C4D3E2F1-A0B9-8F7E-6D5C-4B3A2F1E0D9C}']
    
    // 基本信息
    function GetExpression: string;
    function IsValid: Boolean;
    function GetDescription: string;
    
    // 时间计算
    function GetNextTime(const AFromTime: TInstant): TInstant; overload;
    function GetNextTime: TInstant; overload; // 从当前时间开始
    function GetPreviousTime(const AFromTime: TInstant): TInstant; overload;
    function GetPreviousTime: TInstant; overload;
    
    // 匹配检查
    function Matches(const ATime: TInstant): Boolean;
    
    // 时间序列
    function GetNextTimes(const AFromTime: TInstant; ACount: Integer): specialize TArray<TInstant>; overload;
    function GetNextTimes(ACount: Integer): specialize TArray<TInstant>; overload;
  end;

// 工厂函数
function CreateTaskScheduler: ITaskScheduler; overload;
function CreateTaskScheduler(const AClock: IMonotonicClock): ITaskScheduler; overload;
function CreateTaskScheduler(AMaxThreads: Integer): ITaskScheduler; overload;
function CreateTaskScheduler(const AClock: IMonotonicClock; AMaxThreads: Integer): ITaskScheduler; overload;

function CreateCronExpression(const AExpression: string): ICronExpression;
function ParseCronExpression(const AExpression: string; out ACron: ICronExpression): Boolean;

// 默认调度器
function DefaultTaskScheduler: ITaskScheduler;

// 便捷调度函数
procedure ScheduleOnce(const ADelay: TDuration; const ACallback: TTaskCallback); overload;
procedure ScheduleOnce(const ADelay: TDuration; const ACallback: TTaskCallbackProc); overload;
procedure ScheduleOnce(const ARunTime: TInstant; const ACallback: TTaskCallback); overload;
procedure ScheduleOnce(const ARunTime: TInstant; const ACallback: TTaskCallbackProc); overload;

procedure ScheduleFixed(const AInterval: TDuration; const ACallback: TTaskCallback; const AInitialDelay: TDuration); overload;
procedure ScheduleFixed(const AInterval: TDuration; const ACallback: TTaskCallbackProc; const AInitialDelay: TDuration); overload;

procedure ScheduleDaily(const ATime: TTimeOfDay; const ACallback: TTaskCallback); overload;
procedure ScheduleDaily(const ATime: TTimeOfDay; const ACallback: TTaskCallbackProc); overload;

procedure ScheduleCron(const ACronExpression: string; const ACallback: TTaskCallback); overload;
procedure ScheduleCron(const ACronExpression: string; const ACallback: TTaskCallbackProc); overload;

// Cron 表达式验证
function IsValidCronExpression(const AExpression: string): Boolean;
function GetCronDescription(const AExpression: string): string;
function GetNextCronTime(const AExpression: string; const AFromTime: TInstant): TInstant; overload;
function GetNextCronTime(const AExpression: string): TInstant; overload;

// 常用 Cron 表达式
const
  CRON_EVERY_MINUTE = '* * * * *';
  CRON_EVERY_HOUR = '0 * * * *';
  CRON_EVERY_DAY = '0 0 * * *';
  CRON_EVERY_WEEK = '0 0 * * 0';
  CRON_EVERY_MONTH = '0 0 1 * *';
  CRON_EVERY_YEAR = '0 0 1 1 *';
  
  CRON_WORKDAYS = '0 9 * * 1-5';
  CRON_WEEKENDS = '0 9 * * 0,6';
  CRON_MIDNIGHT = '0 0 * * *';
  CRON_NOON = '0 12 * * *';

implementation

uses
  DateUtils;

type
  // 任务优先队列：按执行时间排序（最小堆）
  TTaskPriorityQueue = specialize TPriorityQueue<IScheduledTask>;

// 任务比较函数：按 NextRunTime 升序，相同时 Priority 降序
function CompareTasksByTime(const A, B: IScheduledTask): Integer;
var
  timeA, timeB: TInstant;
begin
  timeA := A.GetNextRunTime;
  timeB := B.GetNextRunTime;
  
  // 时间早的优先
  if timeA < timeB then Exit(-1);
  if timeA > timeB then Exit(1);
  
  // 时间相同，优先级高的优先
  if A.GetPriority > B.GetPriority then Exit(-1);
  if A.GetPriority < B.GetPriority then Exit(1);
  
  Result := 0;
end;

type
  // Cron 字段类型
  TCronFieldType = (
    cftAny,        // * - 任意值
    cftSingle,     // 单个值 (如 5)
    cftRange,      // 范围 (如 1-5)
    cftList,       // 列表 (如 1,3,5)
    cftStep        // 步长 (如 */5 或 1-10/2)
  );
  
  // Cron 字段
  TCronField = record
    FieldType: TCronFieldType;
    Values: array of Integer;  // 存储所有可能的值
    
    procedure SetAny(AMin, AMax: Integer);
    procedure SetSingle(AValue: Integer);
    procedure SetRange(AStart, AEnd: Integer);
    procedure SetList(const AValues: array of Integer);
    procedure SetStep(AMin, AMax, AStep: Integer);
    procedure SetRangeWithStep(AStart, AEnd, AStep: Integer);
    function Matches(AValue: Integer): Boolean;
    function GetNext(AValue: Integer): Integer; // 返回 >= AValue 的下一个匹配值，-1 表示没有
  end;
  
  // Cron 表达式实现
  TCronExpression = class(TInterfacedObject, ICronExpression)
  private
    FExpression: string;
    FIsValid: Boolean;
    FMinute: TCronField;    // 0-59
    FHour: TCronField;      // 0-23
    FDay: TCronField;       // 1-31
    FMonth: TCronField;     // 1-12
    FDayOfWeek: TCronField; // 0-6 (0=周日)
    FParseError: string;
    
    function ParseField(const AFieldStr: string; AMin, AMax: Integer; out AField: TCronField): Boolean;
    function ValidateField(AValue, AMin, AMax: Integer): Boolean;
    procedure Parse;
  public
    constructor Create(const AExpression: string);
    
    // ICronExpression 实现
    function GetExpression: string;
    function IsValid: Boolean;
    function GetDescription: string;
    
    function GetNextTime(const AFromTime: TInstant): TInstant; overload;
    function GetNextTime: TInstant; overload;
    function GetPreviousTime(const AFromTime: TInstant): TInstant; overload;
    function GetPreviousTime: TInstant; overload;
    
    function Matches(const ATime: TInstant): Boolean;
    
    function GetNextTimes(const AFromTime: TInstant; ACount: Integer): specialize TArray<TInstant>; overload;
    function GetNextTimes(ACount: Integer): specialize TArray<TInstant>; overload;
  end;

  // 调度任务实现
  TScheduledTask = class(TInterfacedObject, IScheduledTask)
  private
    FId: string;
    FName: string;
    FDescription: string;
    FState: TTaskState;
    FPriority: TTaskPriority;
    FStrategy: TScheduleStrategy;
    FNextRunTime: TInstant;
    FLastRunTime: TInstant;
    FRunCount: Int64;
    FFailureCount: Int64;
    FCreatedTime: TInstant;
    FRetryStrategy: TRetryStrategy;
    FCallback: TTaskCallback;
    FCallbackProc: TTaskCallbackProc;
    FCallbackFunc: TTaskCallbackFunc;
    FLock: TRTLCriticalSection;
    FTotalExecutionTime: TDuration;
    FLastExecutionTime: TDuration;
    FLastError: string;
    FRetryCount: Integer;
    FSkipNext: Boolean;
    FInterval: TDuration; // 用于 Fixed 和 Delay 策略的间隔
    FCronExpression: string; // 存储 Cron 表达式
    
    procedure InternalExecute;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    
    // IScheduledTask 实现
    function GetId: string;
    function GetName: string;
    function GetDescription: string;
    function GetState: TTaskState;
    function GetPriority: TTaskPriority;
    function GetStrategy: TScheduleStrategy;
    
    function GetNextRunTime: TInstant;
    function GetLastRunTime: TInstant;
    function GetRunCount: Int64;
    function GetFailureCount: Int64;
    function GetCreatedTime: TInstant;
    
    procedure Start;
    procedure Stop;
    procedure Cancel;
    procedure Reset;
    
    function IsActive: Boolean;
    function IsRunning: Boolean;
    function IsCancelled: Boolean;
    function IsCompleted: Boolean;
    function HasFailed: Boolean;
    
    procedure SetPriority(APriority: TTaskPriority);
    procedure SetRetryStrategy(const AStrategy: TRetryStrategy);
    procedure SetCallback(const ACallback: TTaskCallback); overload;
    procedure SetCallback(const ACallback: TTaskCallbackProc); overload;
    procedure SetCallback(const ACallback: TTaskCallbackFunc); overload;
    
    function Execute: Boolean;
    procedure Skip;
    
    function GetAverageExecutionTime: TDuration;
    function GetTotalExecutionTime: TDuration;
    function GetLastExecutionTime: TDuration;
    function GetLastError: string;
  end;

  // 工作线程
  TSchedulerWorkerThread = class(TThread)
  private
    FScheduler: Pointer; // TTaskScheduler
  protected
    procedure Execute; override;
  public
    constructor Create(AScheduler: Pointer);
  end;

  // 任务调度器实现
  TTaskScheduler = class(TInterfacedObject, ITaskScheduler)
  private
    FClock: IMonotonicClock;
    FTasks: TList; // list of IScheduledTask
    FTaskQueue: TTaskPriorityQueue; // 优先队列：按执行时间排序，用于 GetNextTask 优化
    
    FMaxThreads: Integer;
    FIsRunning: Boolean;
    FIsPaused: Boolean;
    FDefaultRetryStrategy: TRetryStrategy;
    FLock: TRTLCriticalSection;
    FWorkerThread: TSchedulerWorkerThread;
    FStartTime: TInstant;
    FTotalTasksExecuted: Int64;
    FTotalTasksFailed: Int64;
    FShuttingDown: Boolean;
    
    procedure WorkerThreadProc;
    procedure ProcessTasks;
    function GetNextTask: IScheduledTask;
  public
    constructor Create; overload;
    constructor Create(const AClock: IMonotonicClock); overload;
    constructor Create(AMaxThreads: Integer); overload;
    constructor Create(const AClock: IMonotonicClock; AMaxThreads: Integer); overload;
    destructor Destroy; override;
    
    // ITaskScheduler 实现
    function CreateTask(const AName: string; const ACallback: TTaskCallback): IScheduledTask; overload;
    function CreateTask(const AName: string; const ACallback: TTaskCallbackProc): IScheduledTask; overload;
    function CreateTask(const AName: string; const ACallback: TTaskCallbackFunc): IScheduledTask; overload;
    
    function ScheduleOnce(const ATask: IScheduledTask; const ADelay: TDuration): Boolean; overload;
    function ScheduleOnce(const ATask: IScheduledTask; const ARunTime: TInstant): Boolean; overload;
    function ScheduleFixed(const ATask: IScheduledTask; const AInterval: TDuration; const AInitialDelay: TDuration): Boolean;
    function ScheduleDelay(const ATask: IScheduledTask; const ADelay: TDuration): Boolean;
    function ScheduleCron(const ATask: IScheduledTask; const ACronExpression: string): Boolean;
    
    function ScheduleDaily(const ATask: IScheduledTask; const ATime: TTimeOfDay): Boolean;
    function ScheduleWeekly(const ATask: IScheduledTask; ADayOfWeek: Integer; const ATime: TTimeOfDay): Boolean;
    function ScheduleMonthly(const ATask: IScheduledTask; ADay: Integer; const ATime: TTimeOfDay): Boolean;
    
    procedure AddTask(const ATask: IScheduledTask);
    procedure RemoveTask(const ATask: IScheduledTask); overload;
    procedure RemoveTask(const ATaskId: string); overload;
    function GetTask(const ATaskId: string): IScheduledTask;
    function GetTasks: specialize TArray<IScheduledTask>; overload;
    function GetTasks(AState: TTaskState): specialize TArray<IScheduledTask>; overload;
    function GetTaskCount: Integer; overload;
    function GetTaskCount(AState: TTaskState): Integer; overload;
    
    procedure Start;
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure Shutdown(const ATimeout: TDuration);
    function IsRunning: Boolean;
    function IsPaused: Boolean;
    
    procedure SetClock(const AClock: IMonotonicClock);
    function GetClock: IMonotonicClock;
    procedure SetMaxThreads(AMaxThreads: Integer);
    function GetMaxThreads: Integer;
    procedure SetDefaultRetryStrategy(const AStrategy: TRetryStrategy);
    function GetDefaultRetryStrategy: TRetryStrategy;
    
    function GetTotalTasksExecuted: Int64;
    function GetTotalTasksFailed: Int64;
    function GetAverageTaskExecutionTime: TDuration;
    function GetUptime: TDuration;
  end;

var
  GDefaultScheduler: ITaskScheduler = nil;

{ TRetryStrategy }

class function TRetryStrategy.None: TRetryStrategy;
begin
  Result.MaxRetries := 0;
  Result.InitialDelay := TDuration.Zero;
  Result.MaxDelay := TDuration.Zero;
  Result.BackoffMultiplier := 1.0;
end;

class function TRetryStrategy.Simple(AMaxRetries: Integer): TRetryStrategy;
begin
  Result.MaxRetries := AMaxRetries;
  Result.InitialDelay := TDuration.FromSec(1);
  Result.MaxDelay := TDuration.FromSec(60);
  Result.BackoffMultiplier := 1.0;
end;

class function TRetryStrategy.Exponential(AMaxRetries: Integer; const AInitialDelay: TDuration): TRetryStrategy;
begin
  Result.MaxRetries := AMaxRetries;
  Result.InitialDelay := AInitialDelay;
  Result.MaxDelay := TDuration.FromSec(300);
  Result.BackoffMultiplier := 2.0;
end;

// 工厂函数实现

function CreateTaskScheduler: ITaskScheduler;
begin
  Result := TTaskScheduler.Create;
end;

function CreateTaskScheduler(const AClock: IMonotonicClock): ITaskScheduler;
begin
  Result := TTaskScheduler.Create(AClock);
end;

function CreateTaskScheduler(AMaxThreads: Integer): ITaskScheduler;
begin
  Result := TTaskScheduler.Create(AMaxThreads);
end;

function CreateTaskScheduler(const AClock: IMonotonicClock; AMaxThreads: Integer): ITaskScheduler;
begin
  Result := TTaskScheduler.Create(AClock, AMaxThreads);
end;

function DefaultTaskScheduler: ITaskScheduler;
begin
  if GDefaultScheduler = nil then
    GDefaultScheduler := CreateTaskScheduler;
  Result := GDefaultScheduler;
end;

// 便捷函数

procedure ScheduleOnce(const ADelay: TDuration; const ACallback: TTaskCallback);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('OnceTask', ACallback);
  DefaultTaskScheduler.ScheduleOnce(task, ADelay);
end;

procedure ScheduleFixed(const AInterval: TDuration; const ACallback: TTaskCallback; const AInitialDelay: TDuration);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('FixedTask', ACallback);
  DefaultTaskScheduler.ScheduleFixed(task, AInterval, AInitialDelay);
end;

procedure ScheduleDaily(const ATime: TTimeOfDay; const ACallback: TTaskCallback);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('DailyTask', ACallback);
  DefaultTaskScheduler.ScheduleDaily(task, ATime);
end;

{ TScheduledTask }

constructor TScheduledTask.Create(const AName: string);
begin
  inherited Create;
  InitCriticalSection(FLock);
  
  FId := TGuid.NewGuid.ToString;
  FName := AName;
  FDescription := '';
  FState := tsIdle;
  FPriority := tpNormal;
  FStrategy := ssOnce;
  FNextRunTime := TInstant.Zero;
  FLastRunTime := TInstant.Zero;
  FRunCount := 0;
  FFailureCount := 0;
  // Convert system clock time to TInstant
  FCreatedTime := TInstant.FromNsSinceEpoch(DefaultSystemClock.NowUnixNs);
  FRetryStrategy := TRetryStrategy.None;
  FCallback := nil;
  FCallbackProc := nil;
  FCallbackFunc := nil;
  FTotalExecutionTime := TDuration.Zero;
  FLastExecutionTime := TDuration.Zero;
  FLastError := '';
  FRetryCount := 0;
  FSkipNext := False;
  FInterval := TDuration.Zero;
  FCronExpression := '';
end;

destructor TScheduledTask.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited;
end;

function TScheduledTask.GetId: string;
begin
  Result := FId;
end;

function TScheduledTask.GetName: string;
begin
  Result := FName;
end;

function TScheduledTask.GetDescription: string;
begin
  Result := FDescription;
end;

function TScheduledTask.GetState: TTaskState;
begin
  EnterCriticalSection(FLock);
  try
    Result := FState;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetPriority: TTaskPriority;
begin
  Result := FPriority;
end;

function TScheduledTask.GetStrategy: TScheduleStrategy;
begin
  Result := FStrategy;
end;

function TScheduledTask.GetNextRunTime: TInstant;
begin
  EnterCriticalSection(FLock);
  try
    Result := FNextRunTime;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetLastRunTime: TInstant;
begin
  EnterCriticalSection(FLock);
  try
    Result := FLastRunTime;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetRunCount: Int64;
begin
  EnterCriticalSection(FLock);
  try
    Result := FRunCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetFailureCount: Int64;
begin
  EnterCriticalSection(FLock);
  try
    Result := FFailureCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetCreatedTime: TInstant;
begin
  Result := FCreatedTime;
end;

procedure TScheduledTask.Start;
begin
  EnterCriticalSection(FLock);
  try
    if FState = tsIdle then
      FState := tsScheduled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.Stop;
begin
  EnterCriticalSection(FLock);
  try
    if FState in [tsScheduled, tsRunning] then
      FState := tsIdle;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.Cancel;
begin
  EnterCriticalSection(FLock);
  try
    FState := tsCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.Reset;
begin
  EnterCriticalSection(FLock);
  try
    FState := tsIdle;
    FRunCount := 0;
    FFailureCount := 0;
    FRetryCount := 0;
    FTotalExecutionTime := TDuration.Zero;
    FLastExecutionTime := TDuration.Zero;
    FLastError := '';
    FSkipNext := False;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.IsActive: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FState in [tsScheduled, tsRunning];
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.IsRunning: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FState = tsRunning;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.IsCancelled: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FState = tsCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.IsCompleted: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FState = tsCompleted;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.HasFailed: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FState = tsFailed;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.SetPriority(APriority: TTaskPriority);
begin
  EnterCriticalSection(FLock);
  try
    FPriority := APriority;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.SetRetryStrategy(const AStrategy: TRetryStrategy);
begin
  EnterCriticalSection(FLock);
  try
    FRetryStrategy := AStrategy;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.SetCallback(const ACallback: TTaskCallback);
begin
  EnterCriticalSection(FLock);
  try
    FCallback := ACallback;
    FCallbackProc := nil;
    FCallbackFunc := nil;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.SetCallback(const ACallback: TTaskCallbackProc);
begin
  EnterCriticalSection(FLock);
  try
    FCallback := nil;
    FCallbackProc := ACallback;
    FCallbackFunc := nil;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.SetCallback(const ACallback: TTaskCallbackFunc);
begin
  EnterCriticalSection(FLock);
  try
    FCallback := nil;
    FCallbackProc := nil;
    FCallbackFunc := ACallback;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TScheduledTask.InternalExecute;
var
  startTime, endTime: TInstant;
  success: Boolean;
  sysClock: ISystemClock;
begin
  sysClock := DefaultSystemClock;
  startTime := TInstant.FromNsSinceEpoch(UInt64(sysClock.NowUnixNs));
  success := True;
  
  try
    // 执行回调
    if Assigned(FCallbackFunc) then
      success := FCallbackFunc(Self)
    else if Assigned(FCallback) then
      FCallback(Self)
    else if Assigned(FCallbackProc) then
      FCallbackProc(Self);
      
    EnterCriticalSection(FLock);
    try
      if success then
      begin
        // 重复任务（Fixed, Delay, Cron）不设置为 Completed，保持 Scheduled 状态
        if FStrategy = ssOnce then
          FState := tsCompleted
        else
          FState := tsScheduled;
        FRetryCount := 0;
      end
      else
      begin
        Inc(FFailureCount);
        FState := tsFailed;
      end;
    finally
      LeaveCriticalSection(FLock);
    end;
  except
    on E: Exception do
    begin
      EnterCriticalSection(FLock);
      try
        Inc(FFailureCount);
        FState := tsFailed;
        FLastError := E.Message;
      finally
        LeaveCriticalSection(FLock);
      end;
    end;
  end;
  
  endTime := TInstant.FromNsSinceEpoch(UInt64(sysClock.NowUnixNs));
  
  EnterCriticalSection(FLock);
  try
    FLastExecutionTime := endTime.Diff(startTime);
    FTotalExecutionTime := FTotalExecutionTime + FLastExecutionTime;
    Inc(FRunCount);
    FLastRunTime := endTime;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.Execute: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    if FState = tsCancelled then
    begin
      Result := False;
      Exit;
    end;
    
    if FSkipNext then
    begin
      FSkipNext := False;
      Result := False;
      Exit;
    end;
    
    FState := tsRunning;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  InternalExecute;
  Result := True;
end;

procedure TScheduledTask.Skip;
begin
  EnterCriticalSection(FLock);
  try
    FSkipNext := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetAverageExecutionTime: TDuration;
begin
  EnterCriticalSection(FLock);
  try
    if FRunCount > 0 then
      Result := FTotalExecutionTime.DivI(FRunCount)
    else
      Result := TDuration.Zero;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetTotalExecutionTime: TDuration;
begin
  EnterCriticalSection(FLock);
  try
    Result := FTotalExecutionTime;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetLastExecutionTime: TDuration;
begin
  EnterCriticalSection(FLock);
  try
    Result := FLastExecutionTime;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TScheduledTask.GetLastError: string;
begin
  EnterCriticalSection(FLock);
  try
    Result := FLastError;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

{ TSchedulerWorkerThread }

constructor TSchedulerWorkerThread.Create(AScheduler: Pointer);
begin
  inherited Create(False); // 不暂停创建
  FreeOnTerminate := False;
  FScheduler := AScheduler;
end;

procedure TSchedulerWorkerThread.Execute;
begin
  TTaskScheduler(FScheduler).WorkerThreadProc;
end;

{ TTaskScheduler }

constructor TTaskScheduler.Create;
begin
  Create(DefaultMonotonicClock, 1);
end;

constructor TTaskScheduler.Create(const AClock: IMonotonicClock);
begin
  Create(AClock, 1);
end;

constructor TTaskScheduler.Create(AMaxThreads: Integer);
begin
  Create(DefaultMonotonicClock, AMaxThreads);
end;

constructor TTaskScheduler.Create(const AClock: IMonotonicClock; AMaxThreads: Integer);
begin
  inherited Create;
  InitCriticalSection(FLock);
  
  FClock := AClock;
  FTasks := TList.Create; // 保留旧结构用于过渡
  
  // 初始化优先队列（指定比较函数和初始容量）
  FTaskQueue.Initialize(@CompareTasksByTime, 32);
  
  FMaxThreads := AMaxThreads;
  FIsRunning := False;
  FIsPaused := False;
  FDefaultRetryStrategy := TRetryStrategy.Simple(3);
  FWorkerThread := nil;
  FStartTime := TInstant.Zero;
  FTotalTasksExecuted := 0;
  FTotalTasksFailed := 0;
  FShuttingDown := False;
end;

destructor TTaskScheduler.Destroy;
begin
  if FIsRunning then
    Shutdown(TDuration.FromSec(5));
    
  EnterCriticalSection(FLock);
  try
    FTasks.Free;
    FTaskQueue.Clear;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  DoneCriticalSection(FLock);
  inherited;
end;

function TTaskScheduler.CreateTask(const AName: string; const ACallback: TTaskCallback): IScheduledTask;
begin
  Result := TScheduledTask.Create(AName);
  Result.SetCallback(ACallback);
end;

function TTaskScheduler.CreateTask(const AName: string; const ACallback: TTaskCallbackProc): IScheduledTask;
begin
  Result := TScheduledTask.Create(AName);
  Result.SetCallback(ACallback);
end;

function TTaskScheduler.CreateTask(const AName: string; const ACallback: TTaskCallbackFunc): IScheduledTask;
begin
  Result := TScheduledTask.Create(AName);
  Result.SetCallback(ACallback);
end;

procedure TTaskScheduler.AddTask(const ATask: IScheduledTask);
begin
  EnterCriticalSection(FLock);
  try
    // 检查任务是否已存在
    if FTasks.IndexOf(Pointer(ATask)) >= 0 then
      Exit;
    
    // 添加到列表
    FTasks.Add(Pointer(ATask));
    
    // 添加到优先队列用于 GetNextTask 优化
    FTaskQueue.Enqueue(ATask);
    
    // 增加引用计数
    ATask._AddRef;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.RemoveTask(const ATask: IScheduledTask);
var
  idx: Integer;
begin
  EnterCriticalSection(FLock);
  try
    idx := FTasks.IndexOf(Pointer(ATask));
    if idx < 0 then
      Exit; // 不存在
    
    FTasks.Delete(idx);
    FTaskQueue.Remove(ATask);
    ATask._Release;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.RemoveTask(const ATaskId: string);
var
  task: IScheduledTask;
begin
  task := GetTask(ATaskId);
  if Assigned(task) then
    RemoveTask(task);
end;

function TTaskScheduler.GetTask(const ATaskId: string): IScheduledTask;
var
  i: Integer;
  task: IScheduledTask;
begin
  Result := nil;
  EnterCriticalSection(FLock);
  try
    for i := 0 to FTasks.Count - 1 do
    begin
      task := IScheduledTask(FTasks[i]);
      if task.GetId = ATaskId then
      begin
        Result := task;
        Exit;
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTasks: specialize TArray<IScheduledTask>;
var
  i: Integer;
begin
  Result := nil;
  EnterCriticalSection(FLock);
  try
    SetLength(Result, FTasks.Count);
    for i := 0 to FTasks.Count - 1 do
      Result[i] := IScheduledTask(FTasks[i]);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTasks(AState: TTaskState): specialize TArray<IScheduledTask>;
var
  i, count: Integer;
  task: IScheduledTask;
begin
  Result := nil;
  EnterCriticalSection(FLock);
  try
    count := 0;
    SetLength(Result, FTasks.Count);
    for i := 0 to FTasks.Count - 1 do
    begin
      task := IScheduledTask(FTasks[i]);
      if task.GetState = AState then
      begin
        Result[count] := task;
        Inc(count);
      end;
    end;
    SetLength(Result, count);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTaskCount: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FTasks.Count;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTaskCount(AState: TTaskState): Integer;
var
  i: Integer;
  task: IScheduledTask;
begin
  Result := 0;
  EnterCriticalSection(FLock);
  try
    for i := 0 to FTasks.Count - 1 do
    begin
      task := IScheduledTask(FTasks[i]);
      if task.GetState = AState then
        Inc(Result);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.Start;
begin
  EnterCriticalSection(FLock);
  try
    if FIsRunning then
      Exit;
      
    FIsRunning := True;
    FIsPaused := False;
    FShuttingDown := False;
    FStartTime := FClock.NowInstant;
    FWorkerThread := TSchedulerWorkerThread.Create(Self);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.Stop;
begin
  EnterCriticalSection(FLock);
  try
    if not FIsRunning then
      Exit;
      
    FIsRunning := False;
    FIsPaused := False;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  if FWorkerThread <> nil then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FWorkerThread.Free;
    FWorkerThread := nil;
  end;
end;

procedure TTaskScheduler.Pause;
begin
  EnterCriticalSection(FLock);
  try
    if FIsRunning then
      FIsPaused := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.Resume;
begin
  EnterCriticalSection(FLock);
  try
    FIsPaused := False;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.Shutdown(const ATimeout: TDuration);
var
  deadline: TInstant;
begin
  EnterCriticalSection(FLock);
  try
    FShuttingDown := True;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  Stop;
  
  // 等待所有任务完成
  deadline := FClock.NowInstant.Add(ATimeout);
  while (GetTaskCount(tsRunning) > 0) and (FClock.NowInstant < deadline) do
    Sleep(10);
end;

function TTaskScheduler.IsRunning: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FIsRunning;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.IsPaused: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FIsPaused;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.SetClock(const AClock: IMonotonicClock);
begin
  EnterCriticalSection(FLock);
  try
    FClock := AClock;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetClock: IMonotonicClock;
begin
  Result := FClock;
end;

procedure TTaskScheduler.SetMaxThreads(AMaxThreads: Integer);
begin
  EnterCriticalSection(FLock);
  try
    FMaxThreads := AMaxThreads;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetMaxThreads: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FMaxThreads;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.SetDefaultRetryStrategy(const AStrategy: TRetryStrategy);
begin
  EnterCriticalSection(FLock);
  try
    FDefaultRetryStrategy := AStrategy;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetDefaultRetryStrategy: TRetryStrategy;
begin
  EnterCriticalSection(FLock);
  try
    Result := FDefaultRetryStrategy;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTotalTasksExecuted: Int64;
begin
  EnterCriticalSection(FLock);
  try
    Result := FTotalTasksExecuted;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetTotalTasksFailed: Int64;
begin
  EnterCriticalSection(FLock);
  try
    Result := FTotalTasksFailed;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.GetAverageTaskExecutionTime: TDuration;
var
  i: Integer;
  task: IScheduledTask;
  total: TDuration;
  count: Int64;
begin
  total := TDuration.Zero;
  count := 0;
  
  EnterCriticalSection(FLock);
  try
    for i := 0 to FTasks.Count - 1 do
    begin
      task := IScheduledTask(FTasks[i]);
      total := total + task.GetTotalExecutionTime;
      count := count + task.GetRunCount;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  if count > 0 then
    Result := total.DivI(count)
  else
    Result := TDuration.Zero;
end;

function TTaskScheduler.GetUptime: TDuration;
begin
  EnterCriticalSection(FLock);
  try
    if FIsRunning then
      Result := FClock.NowInstant.Diff(FStartTime)
    else
      Result := TDuration.Zero;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TTaskScheduler.WorkerThreadProc;
var
  workerThread: TSchedulerWorkerThread;
begin
  workerThread := FWorkerThread;
  while not workerThread.Terminated do
  begin
    if not FIsRunning or FShuttingDown then
      Break;
      
    if FIsPaused then
    begin
      Sleep(100);
      Continue;
    end;
    
    ProcessTasks;
    Sleep(10); // 避免 CPU 空转
  end;
end;

procedure TTaskScheduler.ProcessTasks;
var
  task: IScheduledTask;
  now: TInstant;
begin
  now := FClock.NowInstant;
  
  while True do
  begin
    task := GetNextTask;
    if task = nil then
      Break;
      
    // 检查是否到达执行时间
    if task.GetNextRunTime <= now then
    begin
      // 执行任务
      if task.Execute then
      begin
        EnterCriticalSection(FLock);
        try
          Inc(FTotalTasksExecuted);
        finally
          LeaveCriticalSection(FLock);
        end;
        
        if task.HasFailed then
        begin
          EnterCriticalSection(FLock);
          try
            Inc(FTotalTasksFailed);
          finally
            LeaveCriticalSection(FLock);
          end;
        end;
      end;
      
      // 处理任务调度策略
      case task.GetStrategy of
        ssOnce:
          begin
            // 一次性任务：完成或取消后移除
            if task.IsCompleted or task.IsCancelled then
              RemoveTask(task);
          end;
        ssFixed:
          begin
            // 固定间隔：立即安排下次执行（忽略执行时间）
            if not task.IsCancelled then
            begin
              (task as TScheduledTask).FNextRunTime := 
                (task as TScheduledTask).FNextRunTime.Add((task as TScheduledTask).FInterval);
            end;
          end;
        ssDelay:
          begin
            // 延迟间隔：从执行完成时间开始计算下次执行
            if not task.IsCancelled then
            begin
              (task as TScheduledTask).FNextRunTime := 
                FClock.NowInstant.Add((task as TScheduledTask).FInterval);
            end;
          end;
        ssCron:
          begin
            // Cron 策略：使用 Cron 表达式计算下次执行时间
            if not task.IsCancelled then
            begin
              if (task as TScheduledTask).FCronExpression <> '' then
              begin
                // 真正的 Cron 任务：使用 Cron 表达式计算
                (task as TScheduledTask).FNextRunTime := 
                  GetNextCronTime((task as TScheduledTask).FCronExpression, FClock.NowInstant);
              end
              else
              begin
                // Daily/Weekly/Monthly 任务：使用间隔
                (task as TScheduledTask).FNextRunTime := 
                  (task as TScheduledTask).FNextRunTime.Add((task as TScheduledTask).FInterval);
              end;
            end;
          end;
      end;
    end
    else
      Break; // 下一个任务时间未到
  end;
end;

function TTaskScheduler.GetNextTask: IScheduledTask;
var
  task: IScheduledTask;
begin
  Result := nil;
  
  EnterCriticalSection(FLock);
  try
    // 从队列中取出最早的任务（O(1) Peek）
    while not FTaskQueue.IsEmpty do
    begin
      if not FTaskQueue.TryPeek(task) then
        Break;
      
      // 检查任务是否仍然有效
      if task.IsActive then
      begin
        Result := task;
        Exit;
      end
      else
      begin
        // 无效任务，移除
        FTaskQueue.Dequeue;
        FTasks.Remove(Pointer(task));
        task._Release;
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleOnce(const ATask: IScheduledTask; const ADelay: TDuration): Boolean;
var
  runTime: TInstant;
begin
  runTime := FClock.NowInstant.Add(ADelay);
  Result := ScheduleOnce(ATask, runTime);
end;

function TTaskScheduler.ScheduleOnce(const ATask: IScheduledTask; const ARunTime: TInstant): Boolean;
var
  task: TScheduledTask;
begin
  Result := False;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
      
    task := ATask as TScheduledTask;
    task.FStrategy := ssOnce;
    task.FNextRunTime := ARunTime;
    task.Start;
    
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleFixed(const ATask: IScheduledTask; const AInterval: TDuration; const AInitialDelay: TDuration): Boolean;
var
  task: TScheduledTask;
begin
  Result := False;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
      
    task := ATask as TScheduledTask;
    task.FStrategy := ssFixed;
    task.FInterval := AInterval; // 存储间隔以便重复执行
    task.FNextRunTime := FClock.NowInstant.Add(AInitialDelay);
    task.Start;
    
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleDelay(const ATask: IScheduledTask; const ADelay: TDuration): Boolean;
var
  task: TScheduledTask;
begin
  Result := False;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
      
    task := ATask as TScheduledTask;
    task.FStrategy := ssDelay;
    task.FInterval := ADelay; // 存储延迟以便重复执行
    task.FNextRunTime := FClock.NowInstant.Add(ADelay);
    task.Start;
    
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleCron(const ATask: IScheduledTask; const ACronExpression: string): Boolean;
var
  task: TScheduledTask;
  cron: ICronExpression;
  nextTime: TInstant;
begin
  Result := False;
  
  // 解析 Cron 表达式
  cron := CreateCronExpression(ACronExpression);
  if not cron.IsValid then
  begin
    Exit;
  end;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
    
    task := ATask as TScheduledTask;
    task.FStrategy := ssCron;
    
    // 计算下次执行时间
    nextTime := cron.GetNextTime;
    if nextTime = TInstant.Zero then
      Exit;
    
    task.FNextRunTime := nextTime;
    // 将 Cron 表达式存储到任务
    task.FCronExpression := ACronExpression;
    task.FDescription := 'Cron: ' + ACronExpression;
    
    task.Start;
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleDaily(const ATask: IScheduledTask; const ATime: TTimeOfDay): Boolean;
var
  task: TScheduledTask;
  now, nextRun: TInstant;
  sysClock: ISystemClock;
  nowDT, nextDT: TDateTime;
  nowHour, nowMin, nowSec, nowMSec: Word;
  targetHour, targetMin, targetSec: Word;
begin
  Result := False;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
      
    task := ATask as TScheduledTask;
    task.FStrategy := ssCron; // 使用 Cron 策略表示复杂调度
    
    // 计算下次执行时间
    sysClock := DefaultSystemClock;
    nowDT := sysClock.NowLocal;
    DecodeTime(nowDT, nowHour, nowMin, nowSec, nowMSec);
    
    targetHour := ATime.GetHour;
    targetMin := ATime.GetMinute;
    targetSec := ATime.GetSecond;
    
    // 设置今天的目标时间
    nextDT := Trunc(nowDT) + EncodeTime(targetHour, targetMin, targetSec, 0);
    
    // 如果目标时间已过，则设置为明天
    if nextDT <= nowDT then
      nextDT := nextDT + 1.0; // 加一天
    
    // 转换为 TInstant
    nextRun := TInstant.FromNsSinceEpoch(UInt64(DateUtils.DateTimeToUnix(nextDT, False) * 1000000000));
    task.FNextRunTime := nextRun;
    task.FInterval := TDuration.FromHours(24); // 24小时间隔
    
    task.Start;
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleWeekly(const ATask: IScheduledTask; ADayOfWeek: Integer; const ATime: TTimeOfDay): Boolean;
var
  task: TScheduledTask;
  now, nextRun: TInstant;
  sysClock: ISystemClock;
  nowDT, nextDT: TDateTime;
  nowDayOfWeek: Integer;
  daysToAdd: Integer;
  targetHour, targetMin, targetSec: Word;
begin
  Result := False;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
      
    task := ATask as TScheduledTask;
    task.FStrategy := ssCron;
    
    // 计算下次执行时间
    sysClock := DefaultSystemClock;
    nowDT := sysClock.NowLocal;
    nowDayOfWeek := DayOfWeek(nowDT); // 1=周日, 2=周一, ..., 7=周六
    
    targetHour := ATime.GetHour;
    targetMin := ATime.GetMinute;
    targetSec := ATime.GetSecond;
    
    // 计算到目标星期几的天数
    // ADayOfWeek: 0=周日, 1=周一, ..., 6=周六
    // nowDayOfWeek: 1=周日, 2=周一, ..., 7=周六
    daysToAdd := (ADayOfWeek + 1 - nowDayOfWeek + 7) mod 7;
    
    // 设置目标日期和时间
    nextDT := Trunc(nowDT) + daysToAdd + EncodeTime(targetHour, targetMin, targetSec, 0);
    
    // 如果时间已过，则加七天
    if nextDT <= nowDT then
      nextDT := nextDT + 7.0;
    
    // 转换为 TInstant
    nextRun := TInstant.FromNsSinceEpoch(UInt64(DateUtils.DateTimeToUnix(nextDT, False) * 1000000000));
    task.FNextRunTime := nextRun;
    task.FInterval := TDuration.FromHours(24 * 7); // 7天间隔
    
    task.Start;
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TTaskScheduler.ScheduleMonthly(const ATask: IScheduledTask; ADay: Integer; const ATime: TTimeOfDay): Boolean;
var
  task: TScheduledTask;
  now, nextRun: TInstant;
  sysClock: ISystemClock;
  nowDT, nextDT: TDateTime;
  nowYear, nowMonth, nowDay: Word;
  targetHour, targetMin, targetSec: Word;
  targetDay: Integer;
  daysInMonth: Integer;
begin
  Result := False;
  
  EnterCriticalSection(FLock);
  try
    if FShuttingDown then
      Exit;
      
    task := ATask as TScheduledTask;
    task.FStrategy := ssCron;
    
    // 计算下次执行时间
    sysClock := DefaultSystemClock;
    nowDT := sysClock.NowLocal;
    DecodeDate(nowDT, nowYear, nowMonth, nowDay);
    
    targetHour := ATime.GetHour;
    targetMin := ATime.GetMinute;
    targetSec := ATime.GetSecond;
    
    // 处理月末特殊情况：如果 ADay 超过该月天数，使用月末
    daysInMonth := DaysInAMonth(nowYear, nowMonth);
    if ADay > daysInMonth then
      targetDay := daysInMonth
    else if ADay < 1 then
      targetDay := 1
    else
      targetDay := ADay;
    
    // 设置目标日期和时间
    nextDT := EncodeDate(nowYear, nowMonth, targetDay) + EncodeTime(targetHour, targetMin, targetSec, 0);
    
    // 如果时间已过，则设置为下个月
    if nextDT <= nowDT then
    begin
      if nowMonth = 12 then
      begin
        nowYear := nowYear + 1;
        nowMonth := 1;
      end
      else
        nowMonth := nowMonth + 1;
      
      // 重新检查日期有效性
      daysInMonth := DaysInAMonth(nowYear, nowMonth);
      if ADay > daysInMonth then
        targetDay := daysInMonth
      else
        targetDay := ADay;
      
      nextDT := EncodeDate(nowYear, nowMonth, targetDay) + EncodeTime(targetHour, targetMin, targetSec, 0);
    end;
    
    // 转换为 TInstant
    nextRun := TInstant.FromNsSinceEpoch(UInt64(DateUtils.DateTimeToUnix(nextDT, False) * 1000000000));
    task.FNextRunTime := nextRun;
    task.FInterval := TDuration.FromHours(24 * 30); // 约30天间隔（近似值）
    
    task.Start;
    AddTask(ATask);
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

{ TCronField }

procedure TCronField.SetAny(AMin, AMax: Integer);
var
  i: Integer;
begin
  FieldType := cftAny;
  SetLength(Values, AMax - AMin + 1);
  for i := AMin to AMax do
    Values[i - AMin] := i;
end;

procedure TCronField.SetSingle(AValue: Integer);
begin
  FieldType := cftSingle;
  SetLength(Values, 1);
  Values[0] := AValue;
end;

procedure TCronField.SetRange(AStart, AEnd: Integer);
var
  i, idx: Integer;
begin
  FieldType := cftRange;
  SetLength(Values, AEnd - AStart + 1);
  idx := 0;
  for i := AStart to AEnd do
  begin
    Values[idx] := i;
    Inc(idx);
  end;
end;

procedure TCronField.SetList(const AValues: array of Integer);
var
  i: Integer;
begin
  FieldType := cftList;
  SetLength(Values, Length(AValues));
  for i := 0 to High(AValues) do
    Values[i] := AValues[i];
end;

procedure TCronField.SetStep(AMin, AMax, AStep: Integer);
var
  i, count, idx: Integer;
begin
  FieldType := cftStep;
  count := 0;
  i := AMin;
  while i <= AMax do
  begin
    Inc(count);
    i := i + AStep;
  end;
  
  SetLength(Values, count);
  idx := 0;
  i := AMin;
  while i <= AMax do
  begin
    Values[idx] := i;
    Inc(idx);
    i := i + AStep;
  end;
end;

procedure TCronField.SetRangeWithStep(AStart, AEnd, AStep: Integer);
var
  i, count, idx: Integer;
begin
  FieldType := cftStep;
  count := 0;
  i := AStart;
  while i <= AEnd do
  begin
    Inc(count);
    i := i + AStep;
  end;
  
  SetLength(Values, count);
  idx := 0;
  i := AStart;
  while i <= AEnd do
  begin
    Values[idx] := i;
    Inc(idx);
    i := i + AStep;
  end;
end;

function TCronField.Matches(AValue: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(Values) do
  begin
    if Values[i] = AValue then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TCronField.GetNext(AValue: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(Values) do
  begin
    if Values[i] >= AValue then
    begin
      Result := Values[i];
      Exit;
    end;
  end;
end;

{ TCronExpression }

constructor TCronExpression.Create(const AExpression: string);
begin
  inherited Create;
  FExpression := Trim(AExpression);
  FIsValid := False;
  FParseError := '';
  Parse;
end;

function TCronExpression.ValidateField(AValue, AMin, AMax: Integer): Boolean;
begin
  Result := (AValue >= AMin) and (AValue <= AMax);
end;

function TCronExpression.ParseField(const AFieldStr: string; AMin, AMax: Integer; out AField: TCronField): Boolean;
var
  s: string;
  parts, rangeParts: TStringArray;
  i, val, rangeStart, rangeEnd, step: Integer;
  valueList: array of Integer;
  stepPos, rangePos: Integer;
begin
  Result := False;
  s := Trim(AFieldStr);
  
  if s = '' then
  begin
    FParseError := 'Empty field';
    Exit;
  end;
  
  // 处理步长 (*/5 或 1-10/2)
  stepPos := Pos('/', s);
  if stepPos > 0 then
  begin
    // 解析步长值
    if not TryStrToInt(Copy(s, stepPos + 1, Length(s)), step) then
    begin
      FParseError := 'Invalid step value: ' + Copy(s, stepPos + 1, Length(s));
      Exit;
    end;
    
    if step <= 0 then
    begin
      FParseError := 'Step must be positive';
      Exit;
    end;
    
    s := Copy(s, 1, stepPos - 1);
    
    // */5 格式
    if s = '*' then
    begin
      AField.SetStep(AMin, AMax, step);
      Result := True;
      Exit;
    end;
    
    // 1-10/2 格式
    rangePos := Pos('-', s);
    if rangePos > 0 then
    begin
      if not TryStrToInt(Copy(s, 1, rangePos - 1), rangeStart) then
      begin
        FParseError := 'Invalid range start: ' + Copy(s, 1, rangePos - 1);
        Exit;
      end;
      if not TryStrToInt(Copy(s, rangePos + 1, Length(s)), rangeEnd) then
      begin
        FParseError := 'Invalid range end: ' + Copy(s, rangePos + 1, Length(s));
        Exit;
      end;
      
      if not ValidateField(rangeStart, AMin, AMax) or not ValidateField(rangeEnd, AMin, AMax) then
      begin
        FParseError := Format('Range values out of bounds (%d-%d)', [AMin, AMax]);
        Exit;
      end;
      
      if rangeStart > rangeEnd then
      begin
        FParseError := 'Invalid range: start > end';
        Exit;
      end;
      
      AField.SetRangeWithStep(rangeStart, rangeEnd, step);
      Result := True;
      Exit;
    end;
    
    FParseError := 'Invalid step format';
    Exit;
  end;
  
  // 处理 * (任意值)
  if s = '*' then
  begin
    AField.SetAny(AMin, AMax);
    Result := True;
    Exit;
  end;
  
  // 处理范围 (1-5)
  rangePos := Pos('-', s);
  if rangePos > 0 then
  begin
    if not TryStrToInt(Copy(s, 1, rangePos - 1), rangeStart) then
    begin
      FParseError := 'Invalid range start: ' + Copy(s, 1, rangePos - 1);
      Exit;
    end;
    if not TryStrToInt(Copy(s, rangePos + 1, Length(s)), rangeEnd) then
    begin
      FParseError := 'Invalid range end: ' + Copy(s, rangePos + 1, Length(s));
      Exit;
    end;
    
    if not ValidateField(rangeStart, AMin, AMax) or not ValidateField(rangeEnd, AMin, AMax) then
    begin
      FParseError := Format('Range values out of bounds (%d-%d)', [AMin, AMax]);
      Exit;
    end;
    
    if rangeStart > rangeEnd then
    begin
      FParseError := 'Invalid range: start > end';
      Exit;
    end;
    
    AField.SetRange(rangeStart, rangeEnd);
    Result := True;
    Exit;
  end;
  
  // 处理列表 (1,3,5)
  if Pos(',', s) > 0 then
  begin
    parts := s.Split(',');
    SetLength(valueList, Length(parts));
    for i := 0 to High(parts) do
    begin
      if not TryStrToInt(Trim(parts[i]), val) then
      begin
        FParseError := 'Invalid value in list: ' + Trim(parts[i]);
        Exit;
      end;
      
      if not ValidateField(val, AMin, AMax) then
      begin
        FParseError := Format('Value %d out of bounds (%d-%d)', [val, AMin, AMax]);
        Exit;
      end;
      
      valueList[i] := val;
    end;
    AField.SetList(valueList);
    Result := True;
    Exit;
  end;
  
  // 处理单个值
  if TryStrToInt(s, val) then
  begin
    if not ValidateField(val, AMin, AMax) then
    begin
      FParseError := Format('Value %d out of bounds (%d-%d)', [val, AMin, AMax]);
      Exit;
    end;
    AField.SetSingle(val);
    Result := True;
    Exit;
  end;
  
  FParseError := 'Invalid field format: ' + s;
end;

procedure TCronExpression.Parse;
var
  parts: TStringArray;
  expr: string;
begin
  FIsValid := False;
  
  if FExpression = '' then
  begin
    FParseError := 'Empty cron expression';
    Exit;
  end;
  
  expr := FExpression;
  
  // 处理宏
  if (Length(expr) > 0) and (expr[1] = '@') then
  begin
    // 转换宏为标准 Cron 表达式
    if (expr = '@yearly') or (expr = '@annually') then
      expr := '0 0 1 1 *'  // 每年1月1日午夜
    else if expr = '@monthly' then
      expr := '0 0 1 * *'  // 每月1日午夜
    else if expr = '@weekly' then
      expr := '0 0 * * 0'  // 每周日午夜
    else if (expr = '@daily') or (expr = '@midnight') then
      expr := '0 0 * * *'  // 每天午夜
    else if expr = '@hourly' then
      expr := '0 * * * *'  // 每小时
    else
    begin
      FParseError := 'Unknown macro: ' + expr;
      Exit;
    end;
  end;
  
  parts := expr.Split(' ');
  
  // 标准 Cron: 分钟 小时 日 月 星期
  if Length(parts) <> 5 then
  begin
    FParseError := Format('Invalid cron expression: expected 5 fields, got %d', [Length(parts)]);
    Exit;
  end;
  
  // 解析每个字段
  if not ParseField(parts[0], 0, 59, FMinute) then Exit;     // 分钟 0-59
  if not ParseField(parts[1], 0, 23, FHour) then Exit;       // 小时 0-23
  if not ParseField(parts[2], 1, 31, FDay) then Exit;        // 日 1-31
  if not ParseField(parts[3], 1, 12, FMonth) then Exit;      // 月 1-12
  if not ParseField(parts[4], 0, 6, FDayOfWeek) then Exit;   // 星期 0-6
  
  FIsValid := True;
  FParseError := '';
end;

function TCronExpression.GetExpression: string;
begin
  Result := FExpression;
end;

function TCronExpression.IsValid: Boolean;
begin
  Result := FIsValid;
end;

function TCronExpression.GetDescription: string;
begin
  if not FIsValid then
  begin
    Result := 'Invalid cron expression: ' + FParseError;
    Exit;
  end;
  
  // 简单描述
  Result := 'Cron: ' + FExpression;
end;

function TCronExpression.GetNextTime(const AFromTime: TInstant): TInstant;
var
  sysClock: ISystemClock;
  fromDT, nextDT: TDateTime;
  year, month, day, hour, minute, second, msec: Word;
  nextMinute, nextHour, nextDay, nextMonth: Integer;
  maxAttempts, attempts: Integer;
  dow: Integer;
  daysInMonth: Integer;
  found: Boolean;
begin
  Result := TInstant.Zero;
  
  if not FIsValid then
    Exit;
  
  sysClock := DefaultSystemClock;
  
  // 将 TInstant 转换为 TDateTime
  fromDT := UnixToDateTime(AFromTime.AsNsSinceEpoch div 1000000000, False);
  // 加一分钟，确保下次时间是在未来
  fromDT := IncMinute(fromDT, 1);
  
  DecodeDateTime(fromDT, year, month, day, hour, minute, second, msec);
  
  // 设置秒和毫秒为 0
  second := 0;
  msec := 0;
  
  // 最多尝试 2 年
  maxAttempts := 365 * 2 * 24 * 60;
  attempts := 0;
  
  while attempts < maxAttempts do
  begin
    Inc(attempts);
    
    // 1. 查找下一个匹配的月份
    nextMonth := FMonth.GetNext(month);
    if nextMonth < 0 then
    begin
      // 今年没有匹配的月份，转到明年
      Inc(year);
      month := FMonth.Values[0];
      day := 1;
      hour := 0;
      minute := 0;
      Continue;
    end
    else if nextMonth > month then
    begin
      // 跳到下一个匹配的月份
      month := nextMonth;
      day := 1;
      hour := 0;
      minute := 0;
    end;
    
    // 2. 查找下一个匹配的日期
    daysInMonth := DaysInAMonth(year, month);
    found := False;
    
    while day <= daysInMonth do
    begin
      // 检查日期和星期是否匹配
      nextDT := EncodeDate(year, month, day) + EncodeTime(hour, minute, 0, 0);
      dow := DayOfWeek(nextDT) - 1; // 0=周日, 1=周一, ..., 6=周六
      
      if FDay.Matches(day) and FDayOfWeek.Matches(dow) then
      begin
        found := True;
        break;
      end;
      
      // 尝试下一天
      Inc(day);
      hour := 0;
      minute := 0;
    end;
    
    if not found then
    begin
      // 本月没有匹配的日期，转到下个月
      if month = 12 then
      begin
        Inc(year);
        month := 1;
      end
      else
        Inc(month);
      day := 1;
      hour := 0;
      minute := 0;
      Continue;
    end;
    
    // 3. 查找下一个匹配的小时
    nextHour := FHour.GetNext(hour);
    if nextHour < 0 then
    begin
      // 今天没有匹配的小时，转到明天
      Inc(day);
      hour := 0;
      minute := 0;
      Continue;
    end
    else if nextHour > hour then
    begin
      hour := nextHour;
      minute := 0;
    end;
    
    // 4. 查找下一个匹配的分钟
    nextMinute := FMinute.GetNext(minute);
    if nextMinute < 0 then
    begin
      // 这个小时没有匹配的分钟，转到下一小时
      Inc(hour);
      minute := 0;
      Continue;
    end;
    
    minute := nextMinute;
    
    // 找到匹配的时间
    nextDT := EncodeDate(year, month, day) + EncodeTime(hour, minute, 0, 0);
    Result := TInstant.FromNsSinceEpoch(UInt64(DateTimeToUnix(nextDT, False) * 1000000000));
    Exit;
  end;
  
  // 超过最大尝试次数
  Result := TInstant.Zero;
end;

function TCronExpression.GetNextTime: TInstant;
var
  sysClock: ISystemClock;
begin
  sysClock := DefaultSystemClock;
  Result := GetNextTime(TInstant.FromNsSinceEpoch(sysClock.NowUnixNs));
end;

function TCronExpression.GetPreviousTime(const AFromTime: TInstant): TInstant;
begin
  // TODO: 实现反向查找
  Result := TInstant.Zero;
end;

function TCronExpression.GetPreviousTime: TInstant;
begin
  Result := GetPreviousTime(TInstant.FromNsSinceEpoch(DefaultSystemClock.NowUnixNs));
end;

function TCronExpression.Matches(const ATime: TInstant): Boolean;
var
  dt: TDateTime;
  year, month, day, hour, minute, second, msec: Word;
  dow: Integer;
begin
  Result := False;
  
  if not FIsValid then
    Exit;
  
  // 将 TInstant 转换为 TDateTime
  dt := UnixToDateTime(ATime.AsNsSinceEpoch div 1000000000, False);
  DecodeDateTime(dt, year, month, day, hour, minute, second, msec);
  
  // 检查所有字段是否匹配
  if not FMinute.Matches(minute) then Exit;
  if not FHour.Matches(hour) then Exit;
  if not FDay.Matches(day) then Exit;
  if not FMonth.Matches(month) then Exit;
  
  dow := DayOfWeek(dt) - 1;
  if not FDayOfWeek.Matches(dow) then Exit;
  
  Result := True;
end;

function TCronExpression.GetNextTimes(const AFromTime: TInstant; ACount: Integer): specialize TArray<TInstant>;
var
  i: Integer;
  current: TInstant;
begin
  SetLength(Result, ACount);
  current := AFromTime;
  
  for i := 0 to ACount - 1 do
  begin
    current := GetNextTime(current);
    if current = TInstant.Zero then
      break;
    Result[i] := current;
  end;
end;

function TCronExpression.GetNextTimes(ACount: Integer): specialize TArray<TInstant>;
begin
  Result := GetNextTimes(TInstant.FromNsSinceEpoch(DefaultSystemClock.NowUnixNs), ACount);
end;

// Cron 工厂函数实现

function CreateCronExpression(const AExpression: string): ICronExpression;
begin
  Result := TCronExpression.Create(AExpression);
end;

function ParseCronExpression(const AExpression: string; out ACron: ICronExpression): Boolean;
begin
  ACron := TCronExpression.Create(AExpression);
  Result := ACron.IsValid;
  if not Result then
    ACron := nil;
end;

function IsValidCronExpression(const AExpression: string): Boolean;
var
  cron: ICronExpression;
begin
  cron := TCronExpression.Create(AExpression);
  Result := cron.IsValid;
end;

function GetCronDescription(const AExpression: string): string;
var
  cron: ICronExpression;
begin
  cron := TCronExpression.Create(AExpression);
  Result := cron.GetDescription;
end;

function GetNextCronTime(const AExpression: string; const AFromTime: TInstant): TInstant;
var
  cron: ICronExpression;
begin
  cron := TCronExpression.Create(AExpression);
  if cron.IsValid then
    Result := cron.GetNextTime(AFromTime)
  else
    Result := TInstant.Zero;
end;

function GetNextCronTime(const AExpression: string): TInstant;
var
  sysClock: ISystemClock;
begin
  sysClock := DefaultSystemClock;
  Result := GetNextCronTime(AExpression, TInstant.FromNsSinceEpoch(UInt64(sysClock.NowUnixNs)));
end;

// 便捷函数实现

procedure ScheduleOnce(const ADelay: TDuration; const ACallback: TTaskCallbackProc);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('OnceTask', ACallback);
  DefaultTaskScheduler.ScheduleOnce(task, ADelay);
end;

procedure ScheduleOnce(const ARunTime: TInstant; const ACallback: TTaskCallback);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('OnceTask', ACallback);
  DefaultTaskScheduler.ScheduleOnce(task, ARunTime);
end;

procedure ScheduleOnce(const ARunTime: TInstant; const ACallback: TTaskCallbackProc);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('OnceTask', ACallback);
  DefaultTaskScheduler.ScheduleOnce(task, ARunTime);
end;

procedure ScheduleFixed(const AInterval: TDuration; const ACallback: TTaskCallbackProc; const AInitialDelay: TDuration);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('FixedTask', ACallback);
  DefaultTaskScheduler.ScheduleFixed(task, AInterval, AInitialDelay);
end;

procedure ScheduleDaily(const ATime: TTimeOfDay; const ACallback: TTaskCallbackProc);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('DailyTask', ACallback);
  DefaultTaskScheduler.ScheduleDaily(task, ATime);
end;

procedure ScheduleCron(const ACronExpression: string; const ACallback: TTaskCallback);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('CronTask', ACallback);
  DefaultTaskScheduler.ScheduleCron(task, ACronExpression);
end;

procedure ScheduleCron(const ACronExpression: string; const ACallback: TTaskCallbackProc);
var
  task: IScheduledTask;
begin
  task := DefaultTaskScheduler.CreateTask('CronTask', ACallback);
  DefaultTaskScheduler.ScheduleCron(task, ACronExpression);
end;

end.
