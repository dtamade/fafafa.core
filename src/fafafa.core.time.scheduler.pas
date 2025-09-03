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
  fafafa.core.time.base,
  fafafa.core.time.clock,
  fafafa.core.thread.cancel;

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
    function GetTasks: TArray<IScheduledTask>; overload;
    function GetTasks(AState: TTaskState): TArray<IScheduledTask>; overload;
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
    function GetNextTimes(const AFromTime: TInstant; ACount: Integer): TArray<TInstant>; overload;
    function GetNextTimes(ACount: Integer): TArray<TInstant>; overload;
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
  fafafa.core.time.timeofday;

type
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

  // 任务调度器实现
  TTaskScheduler = class(TInterfacedObject, ITaskScheduler)
  private
    FClock: IMonotonicClock;
    FTasks: TList;
    FMaxThreads: Integer;
    FIsRunning: Boolean;
    FIsPaused: Boolean;
    FDefaultRetryStrategy: TRetryStrategy;
    FLock: TRTLCriticalSection;
    FWorkerThread: TThread;
    
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
    function GetTasks: TArray<IScheduledTask>; overload;
    function GetTasks(AState: TTaskState): TArray<IScheduledTask>; overload;
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

// 实现细节将在后续添加...

end.
