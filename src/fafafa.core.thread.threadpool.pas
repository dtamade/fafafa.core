unit fafafa.core.thread.threadpool;

{**
 * fafafa.core.thread.threadpool - 线程池模块
 *
 * @desc 提供高性能的线程池实现，包括：
 *       - IThreadPool 接口：线程池的标准接口
 *       - TThreadPool 类：高性能的线程池实现
 *       - TWorkerThread 类：工作线程实现
 *       - 支持多种任务类型（全局函数、对象方法、匿名函数）
 *       - 动态线程管理和任务调度
 *
 * @author fafafa.core 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.sync,
  fafafa.core.thread.debuglog,
  fafafa.core.thread.future,
  fafafa.core.thread.cancel,
  fafafa.core.collections.vecdeque;

type

  {**
   * 线程池相关异常类型
   *}

  {**
   * EThreadError
   *
   * @desc 线程操作的基础异常类
   *}
  EThreadError = class(ECore);

  {**
   * EThreadPoolError
   *
   * @desc 线程池异常类
   *}
  EThreadPoolError = class(EThreadError);

  {**
   * 任务回调函数类型定义
   *}
  TTaskFunc = function(aData: Pointer): Boolean;
  TTaskMethod = function(aData: Pointer): Boolean of Object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TTaskRefFunc = reference to function(): Boolean;
  {$ENDIF}

  {**
   * 任务类型枚举
   *}
  TTaskType = (ttFunc, ttMethod{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}, ttRefFunc{$ENDIF});

  {**
   * 任务记录
   *}
  PTaskItem = ^TTaskItem;
  TTaskItem = record
    TaskType: TTaskType;
    TaskFunc: TTaskFunc;
    TaskMethod: TTaskMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    TaskRefFunc: TTaskRefFunc;
    {$ENDIF}
    TaskData: Pointer; // 传递给任务的用户数据
    Future: IFutureInternal; // 关联的 Future 对象
    Token: ICancellationToken; // 协作式取消令牌（可选）
    EnqueueTick: QWord; // 入队时间戳（用于观测队列驻留时间）
  end;

  {**
   * 前向声明
   *}


  {**
   * IThreadPool
   *
   * @desc 线程池接口
   *       提供高性能的线程池实现，支持任务提交、执行和管理
   *}
  TRejectPolicy = (rpAbort, rpCallerRuns, rpDiscard, rpDiscardOldest);

  // 线程池指标接口：提供只读视图
  IThreadPoolMetrics = interface
    ['{2F69A2D4-2D0A-4E2E-9E9B-4B1B7B5E3F11}']
    function ActiveCount: Integer;
    function PoolSize: Integer;
    function QueueSize: Integer;
    function QueuePeak: Integer;
    function TotalSubmitted: Int64;
    function TotalCompleted: Int64;
    function TotalRejected: Int64;
    // 分桶的拒绝/回退计数
    function RejectedAbort: Int64;
    function RejectedCallerRuns: Int64;
    function RejectedDiscard: Int64;
    function RejectedDiscardOldest: Int64;
    // 任务对象池指标
    function TaskItemPoolHit: Int64;
    function TaskItemPoolMiss: Int64;
    function TaskItemPoolReturn: Int64;
    function TaskItemPoolDrop: Int64;
    // CallerRuns 分桶
    function CallerRunsAtMax: Int64;
    // KeepAlive 收缩指标
    function KeepAliveShrinkAttempts: Int64;
    function KeepAliveShrinkImmediate: Int64;
    function KeepAliveShrinkTimeout: Int64;
    // 轻量观测：队列驻留时间平均值（开启观测时才有意义）
    function QueueObservedAverageMs: Double;
  end;

  // 轻量实现：直接暴露 TThreadPool 内部计数（已在锁保护下读取）
  TThreadPool = class; // 前向声明供指标类持有
  TThreadPoolMetrics = class(TInterfacedObject, IThreadPoolMetrics)
  private
    FOwner: TThreadPool;
  public
    constructor Create(AOwner: TThreadPool);
    function ActiveCount: Integer;
    function PoolSize: Integer;
    function QueueSize: Integer;
    function QueuePeak: Integer; // 运行期观测到的队列峰值
    function TotalSubmitted: Int64;
    function TotalCompleted: Int64;
    function TotalRejected: Int64;
    // 分桶的拒绝/回退计数（CallerRuns 不计入 TotalRejected）
    function RejectedAbort: Int64;
    function RejectedCallerRuns: Int64;
    function RejectedDiscard: Int64;
    function RejectedDiscardOldest: Int64;
    // 任务对象池指标
    function TaskItemPoolHit: Int64;
    function TaskItemPoolMiss: Int64;
    function TaskItemPoolReturn: Int64;
    function TaskItemPoolDrop: Int64;
    // CallerRuns 分桶
    function CallerRunsAtMax: Int64;
    // KeepAlive 收缩指标
    function KeepAliveShrinkAttempts: Int64;
    function KeepAliveShrinkImmediate: Int64;
    function KeepAliveShrinkTimeout: Int64;
    function QueueObservedAverageMs: Double;
  end;

  // 轻量观测开关（线程池级）
  // 注意：实现段声明全局变量 GPoolObsMetricsEnabled

  IThreadPool = interface
    ['{A1B2C3D4-E5F6-7A8B-9C0D-E1F2A3B4C5D6}']

    {**
     * Submit - 提交任务（全局函数）
     *
     * @desc 提交一个全局函数任务到线程池执行
     *
     * @params
     *    ATask: TTaskFunc 要执行的函数
     *    AData: Pointer 传递给函数的用户数据
     *
     * @return 返回 Future 对象用于跟踪任务状态
     *}
    function Submit(ATask: TTaskFunc; AData: Pointer = nil): IFuture; overload;

    {** 协作式取消：若预取消则直接返回 nil，不入队 **}
    function Submit(ATask: TTaskFunc; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;

    {**
     * Submit - 提交任务（对象方法）
     *
     * @desc 提交一个对象方法任务到线程池执行
     *
     * @params
     *    ATask: TTaskMethod 要执行的方法
     *    AData: Pointer 传递给方法的用户数据
     *
     * @return 返回 Future 对象用于跟踪任务状态
     *}
    function Submit(ATask: TTaskMethod; AData: Pointer = nil): IFuture; overload;

    {** 协作式取消：若预取消则直接返回 nil，不入队 **}
    function Submit(ATask: TTaskMethod; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    {** 协作式取消：匿名引用任务 **}
    function Submit(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture; overload;
    {$ENDIF}

    {**
     * Submit - 提交任务（匿名函数）
     *
     * @desc 提交一个匿名函数任务到线程池执行
     *
     * @params
     *    ATask: TTaskRefFunc 要执行的匿名函数
     *
     * @return 返回 Future 对象用于跟踪任务状态
     *}
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Submit(const ATask: TTaskRefFunc): IFuture; overload;
    {$ENDIF}

    {**
     * GetActiveCount
     *
     * @desc 获取当前活跃的线程数量
     *
     * @return 返回正在执行任务的线程数量
     *}
    function GetActiveCount: Integer;

    {**
     * GetPoolSize
     *
     * @desc 获取线程池大小
     *
     * @return 返回线程池中的总线程数量
     *}
    function GetPoolSize: Integer;

    {**
     * GetQueueSize
     *
     * @desc 获取等待队列大小
     *
     * @return 返回等待执行的任务数量
     *}
    function GetQueueSize: Integer;

    {**
     * Shutdown
     *
     * @desc 关闭线程池（不接受新任务，等待现有任务完成）
     *}
    procedure Shutdown;

    {**
     * ShutdownNow
     *
     * @desc 立即关闭线程池（尝试停止所有正在执行的任务）
     *
     * @return 返回未执行的任务列表
     *}
    function ShutdownNow: TList;

    {**
     * IsShutdown
     *
     * @desc 检查线程池是否已关闭
     *
     * @return 已关闭返回 True，否则返回 False
     *}
    function IsShutdown: Boolean;

    {**
     * IsTerminated
     *
     * @desc 检查线程池是否已终止（所有任务都已完成）
     *
     * @return 已终止返回 True，否则返回 False
     *}
    function IsTerminated: Boolean;

    {**
     * AwaitTermination
     *
     * @desc 等待线程池终止
     *
     * @params
     *    ATimeoutMs: Cardinal 超时时间（毫秒），INFINITE 表示无限等待
     *
     * @return 在超时前终止返回 True，否则返回 False
     *}
    function AwaitTermination(ATimeoutMs: Cardinal = INFINITE): Boolean;

    // 指标视图（只读）
    function GetMetrics: IThreadPoolMetrics;

    // 属性访问器
    property ActiveCount: Integer read GetActiveCount;
    property PoolSize: Integer read GetPoolSize;
    property QueueSize: Integer read GetQueueSize;
    property IsShutdownProperty: Boolean read IsShutdown;
    property Terminated: Boolean read IsTerminated;
  end;

  {**
   * TWorkerThread
   *
   * @desc 工作线程类
   *       负责从任务队列中获取并执行任务
   *}
  TWorkerThread = class(TThread)
  private
    FTaskQueue: specialize TVecDeque<PTaskItem>; // 使用高性能双端队列，由外部锁保护
    FQueueLock: ILock; // 保护任务队列的锁
    FShutdown: Boolean;
    FShutdownEvent: IEvent;
    FTaskAvailableEvent: IEvent;
    FLock: ILock; // 保护线程状态的锁
    FThreadPool: Pointer; // 避免循环引用，使用 Pointer
    {$IFDEF FAFAFA_THREAD_DEBUG}
    FWorkerId: Cardinal;      // 可选：工作线程编号（仅调试）
    FWorkerName: string;      // 可选：工作线程名称（仅调试）
    {$ENDIF}

    function GetNextTask: PTaskItem;
    procedure ExecuteTask(ATask: PTaskItem);
    procedure NotifyTaskCompletion;

  public
    constructor Create(ATaskQueue: specialize TVecDeque<PTaskItem>; ATaskAvailableEvent: IEvent; AQueueLock: ILock; AThreadPool: Pointer);
    constructor CreateSuspended(ATaskQueue: specialize TVecDeque<PTaskItem>; ATaskAvailableEvent: IEvent; AQueueLock: ILock; AThreadPool: Pointer);
    destructor Destroy; override;
    procedure Execute; override;

    procedure Shutdown;
    function IsShutdown: Boolean;

    {$IFDEF FAFAFA_THREAD_DEBUG}
    property WorkerId: Cardinal read FWorkerId;
    property WorkerName: string read FWorkerName;
    {$ENDIF}
  end;

  {**
   * TThreadPool
   *
   * @desc 线程池实现类
   *       提供高性能的线程池管理和任务调度
   *}
  TThreadPool = class(TInterfacedObject, IThreadPool)
  private
    FCorePoolSize: Integer;
    FMaxPoolSize: Integer;
    FKeepAliveTimeMs: Cardinal;

    FWorkerThreads: TList;
    FTaskQueue: specialize TVecDeque<PTaskItem>;
    FTaskAvailableEvent: IEvent;
    FQueueLock: ILock; // 保护任务队列的锁

    // 任务对象池（减少 New/Dispose 开销）
    FTaskItemPool: TList;
    FTaskItemPoolMax: Integer;
    FTaskPoolLock: ILock;

    FActiveCount: Integer;
    FShutdown: Boolean;
    FTerminated: Boolean;
    FConstructionComplete: Boolean; // 标记构造是否完成

    // Phase 1: 容量与拒绝策略（默认无限制 + Abort）
    FQueueCapacity: Integer;
    FRejectPolicy: TRejectPolicy;

    FLock: ILock;
    FTerminationEvent: IEvent;

    // 指标计数
    FTotalSubmitted: Int64;
    FTotalCompleted: Int64;
    FTotalRejected: Int64;
    // 分桶的拒绝/回退计数
    FRejectedAbort: Int64;
    FRejectedCaller: Int64;
    FRejectedDiscard: Int64;
    FRejectedDiscardOldest: Int64;
    // 队列峰值（在队列锁内更新）
    FQueuePeak: Integer;
    // 任务对象池指标
    FTaskItemPoolHit: Int64;
    FTaskItemPoolMiss: Int64;
    FTaskItemPoolReturn: Int64;
    FTaskItemPoolDrop: Int64;

    // 存活线程计数：仅在工作线程真正销毁（Destroy）时递减，用于 AwaitTermination 精准等待
    FAliveThreads: Integer;
    // 收缩预留：防止并发收缩超过 Core（表示已获准退出但尚未从列表移除的线程数量）
    FShrinkReservations: Integer;
    // 额外指标
    FCallerRunsAtMax: Int64;
    FShrinkAttempts: Int64;
    FShrinkSuccessImmediate: Int64;
    FShrinkSuccessTimeout: Int64;
    FLastShrinkTick: QWord; // 最近一次成功收缩的时间戳，用于限频

    procedure CreateWorkerThread;
    procedure CreateWorkerThreadUnlocked; // 无锁版本，假设调用者已持有 FLock
    procedure CreateCoreThreadsSafely; // 安全地创建核心线程
    procedure EnsureCoreThreads; // 确保核心线程已创建
    procedure RemoveWorkerThread(AThread: TWorkerThread);
    function CreateTaskItem(ATaskType: TTaskType; AFuture: IFutureInternal; AData: Pointer = nil;
                           ATaskFunc: TTaskFunc = nil; ATaskMethod: TTaskMethod = nil
                           {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}; const ATaskRefFunc: TTaskRefFunc = nil{$ENDIF}): PTaskItem;
    function AcquireTaskItem: PTaskItem; inline;
    procedure ReleaseTaskItem(var AItem: PTaskItem); inline;
    procedure SubmitTaskItem(ATaskItem: PTaskItem; AFuture: IFuture);
    procedure UpdateActiveCount(ADelta: Integer);


  public
    constructor Create(ACorePoolSize, AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal); overload;


    constructor Create(ACorePoolSize, AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal;
      AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy); overload;
    destructor Destroy; override;

    function Submit(ATask: TTaskFunc; AData: Pointer = nil): IFuture; overload;
    function Submit(ATask: TTaskFunc; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;
    function Submit(ATask: TTaskMethod; AData: Pointer = nil): IFuture; overload;
    function Submit(ATask: TTaskMethod; const AToken: ICancellationToken; AData: Pointer = nil): IFuture; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Submit(const ATask: TTaskRefFunc): IFuture; overload;
    function Submit(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture; overload;
    {$ENDIF}
    function GetActiveCount: Integer;
    function GetPoolSize: Integer;
    function GetQueueSize: Integer;
    procedure Shutdown;
    function ShutdownNow: TList;
    function IsShutdown: Boolean;
    function IsTerminated: Boolean;
  class procedure SetObservedMetricsEnabled(AEnabled: Boolean); static;
  private
    // 轻量观测（默认关闭）：队列驻留时间
    FQueueObsTotalMs: QWord;
    FQueueObsCount: QWord;
    procedure AddQueueObserved(ADelta: QWord); inline;
  public
    function AwaitTermination(ATimeoutMs: Cardinal = INFINITE): Boolean;

    // 指标
    function GetMetrics: IThreadPoolMetrics;
  end;

implementation

{$IFDEF UNIX}
uses dynlibs;
{$ENDIF}
var GPoolObsMetricsEnabled: Boolean = False;



{$IFDEF DEBUG}
procedure __set_thread_name_debug_portable(const S: AnsiString);
{$IFDEF WINDOWS}
  type TSetThreadDescription = function(hThread: THandle; lpThreadDescription: PWideChar): HRESULT; stdcall;
var h: HMODULE; p: TSetThreadDescription; ws: UnicodeString;
begin
  try
    h := GetModuleHandleW('kernel32.dll');
    if h <> 0 then
    begin
      Pointer(p) := GetProcAddress(h, 'SetThreadDescription');
      if Assigned(p) then
      begin
        ws := UnicodeString(S);
        p(GetCurrentThread, PWideChar(ws));
      end;
    end;
  except
  end;

{$IFDEF DEBUG}
__set_thread_name_debug_portable('fafafa-pool-worker');
{$ENDIF}

end;
{$ELSE}
  {$IFDEF UNIX}
  {$IFDEF FPC}
  uses BaseUnix;
  {$ENDIF}
  {$ENDIF}
procedure __set_thread_name_debug_portable(const S: AnsiString);
{$IFDEF UNIX}
  type TPthreadSetName = function(name: PChar): cint; cdecl; // pthread_setname_np(name)
var h: TLibHandle; p: Pointer; namebuf: AnsiString;
{$ENDIF}
begin
  try
    {$IFDEF UNIX}
    // 动态查找 pthread_setname_np，避免硬依赖；最长16字节（含\0）
    h := LoadLibrary('libpthread.so.0');
    if h <> 0 then
    begin
      p := GetProcedureAddress(h, 'pthread_setname_np');
      if Assigned(p) then
      begin
        namebuf := Copy(S, 1, 15);
        TPthreadSetName(p)(PChar(namebuf));
      end;
      FreeLibrary(h);
    end;
    {$ENDIF}
  except
  end;
end;
{$ENDIF}
{$ENDIF}


{ TWorkerThread }

constructor TWorkerThread.Create(ATaskQueue: specialize TVecDeque<PTaskItem>; ATaskAvailableEvent: IEvent; AQueueLock: ILock; AThreadPool: Pointer);
begin
  // 创建立即启动的线程
  inherited Create(False);
  // 确保线程结束时自动释放，避免泄漏
  FreeOnTerminate := True;
  FTaskQueue := ATaskQueue;
  FQueueLock := AQueueLock; // 保存队列锁的引用
  FTaskAvailableEvent := ATaskAvailableEvent;
  FThreadPool := AThreadPool;
  FShutdown := False;
  FShutdownEvent := TEvent.Create(True, False); // ManualReset=True, InitialState=False
  FLock := TMutex.Create;
  {$IFDEF FAFAFA_THREAD_DEBUG}
  // 分配一个可读的编号/名称（仅调试，用于日志排障）
  FWorkerId := Cardinal(PtrUInt(Self) and $FFFF);
  FWorkerName := Format('Worker-%4.4x', [FWorkerId]);
  {$ENDIF}
  {$IFDEF DEBUG}
  __set_thread_name_debug('fafafa-pool-worker');
  {$ENDIF}

end;

{$IFDEF DEBUG}
procedure __set_thread_name_debug(const S: AnsiString);
begin
  try
    {$IFDEF WINDOWS}
      // Windows 10+ SetThreadDescription via JwaWindows would be ideal; fallback: no-op to avoid dependency
    {$ELSE}
      // POSIX pthread_setname_np could be used; keeping no-op for portability
    {$ENDIF}
  except
  end;
end;
{$ENDIF}


constructor TWorkerThread.CreateSuspended(ATaskQueue: specialize TVecDeque<PTaskItem>; ATaskAvailableEvent: IEvent; AQueueLock: ILock; AThreadPool: Pointer);
begin
  // 创建挂起的线程
  inherited Create(True);
  FTaskQueue := ATaskQueue;
  FQueueLock := AQueueLock; // 保存队列锁的引用
  FTaskAvailableEvent := ATaskAvailableEvent;
  FThreadPool := AThreadPool;
  FShutdown := False;
  FShutdownEvent := TEvent.Create(True, False); // ManualReset=True, InitialState=False
  FLock := TMutex.Create;
end;


destructor TWorkerThread.Destroy;
begin
  {$IFDEF FAFAFA_THREAD_DEBUG}
  DebugLog(Format('Worker %p destroy name=%s', [Pointer(Self), {$IFDEF FAFAFA_THREAD_DEBUG}FWorkerName{$ELSE}''{$ENDIF}]));
  {$ENDIF}
  // 不在 Destroy 中移除，避免在线程池析构后访问已释放的锁
  // 线程结束时会在 NotifyTaskCompletion 中通知线程池移除

  // 清理接口引用（自动释放）
  FShutdownEvent := nil;
  FLock := nil;
  FQueueLock := nil;
  FTaskAvailableEvent := nil;

  inherited Destroy;
end;

procedure TWorkerThread.Execute;
var
  LTask: PTaskItem;
  LLastActive: QWord;
  LIdleMs: QWord;
  LPool: TThreadPool;
  LWaitMs: Cardinal;
  LCount, LCore: Integer;
  LCanShrink: Boolean;
  LReserveOK: Boolean;
begin
  // 短暂延迟，确保线程池完全初始化
  Sleep(1);
  LLastActive := GetTickCount64;
  DebugLog(Format('Worker %p start', [Pointer(Self)]));

  while not FShutdown do
  begin
    // 尝试获取任务
    LTask := GetNextTask;
    if Assigned(LTask) then
    begin
      DebugLog(Format('Worker %p got task kind=%d', [Pointer(Self), Ord(LTask^.TaskType)]));
      try
        ExecuteTask(LTask);
      finally
        // 在释放任务前，释放记录中持有的接口引用，避免泄漏
        if Assigned(LTask) then
          LTask^.Future := nil;
        // 归还任务对象
        TThreadPool(FThreadPool).ReleaseTaskItem(LTask);
        LLastActive := GetTickCount64; // 刚执行过任务，刷新活跃时间
        DebugLog(Format('Worker %p task done; active refreshed', [Pointer(Self)]));
      end;
    end
    else
    begin
      // 优先做一次 keepAlive 检查（即使事件被触发但没有任务，也能及时收缩）
      if Assigned(FThreadPool) then
      begin
        LPool := TThreadPool(FThreadPool);
        LIdleMs := GetTickCount64 - LLastActive;
        // 在池锁内读取 Count/Core，避免竞态导致收缩条件误判
        LCount := 0; LCore := 0; LCanShrink := False;
        LPool.FLock.Acquire;
        try
          if (LPool.FWorkerThreads <> nil) then
          begin
            LCount := LPool.FWorkerThreads.Count;
            LCore := LPool.FCorePoolSize;
          // 限频：仅在接近 Core 时（剩余可收缩<=1）做防抖，避免来回抖动
          // 放宽限频：允许连续收缩，避免长时间停留在 Core+1
          //（仍保留 LLastShrinkTick 作为轻量观测用途，不阻断收缩）

            LCanShrink := (LPool.FKeepAliveTimeMs > 0) and (LIdleMs >= LPool.FKeepAliveTimeMs) and (LCount > LCore);
          end;
        finally
          LPool.FLock.Release;
        end;
        // 额外收缩路径：当完全空闲（Active=0 且 队列=0）且线程数>Core 时，允许提前收缩
        if (not LCanShrink) and Assigned(LPool) then
        begin
          if (LPool.GetActiveCount = 0) and (LPool.GetQueueSize = 0) then
          begin
            // 允许一个线程在完全空闲时先行退出，逐步回落到 Core
            LCanShrink := (LCount > LCore);
          end;
        end;
        if LCanShrink then
        begin
          // 指标：收缩尝试（立即路径）
          LPool.FLock.Acquire; try Inc(LPool.FShrinkAttempts); finally LPool.FLock.Release; end;

          // 二次确认：在队列锁下检查是否仍无待执行任务，避免竞态导致丢任务
          if Assigned(LPool) then
          begin
            LPool.FQueueLock.Acquire;
            try
              if (LPool.FTaskQueue <> nil) and (LPool.FTaskQueue.GetCount > 0) then
              begin
                // 有任务，放弃本次收缩
                Continue;
              end;
            finally
              LPool.FQueueLock.Release;
            end;
          end;

          // 预留收缩名额，防止并发过度收缩到低于 Core
          // 预留收缩名额，防止并发过度收缩到低于 Core
          LReserveOK := False;
          LPool.FLock.Acquire;
          try
            if (LCount - LCore - LPool.FShrinkReservations) > 0 then
            begin
              Inc(LPool.FShrinkReservations);
            // 记录成功收缩时间（限频依据）
            LPool.FLastShrinkTick := GetTickCount64;

              LReserveOK := True;
            end;
          finally
            LPool.FLock.Release;
          end;
          if not LReserveOK then
            Continue;

          // 指标：收缩成功（立即路径）
          LPool.FLock.Acquire; try Inc(LPool.FShrinkSuccessImmediate); finally LPool.FLock.Release; end;

          DebugLog(Format('Worker %p keepAlive shrink (idle=%d, size=%d>core=%d)',
            [Pointer(Self), LIdleMs, LCount, LCore]));
          // 安全下线：标记退出，并发一个唤醒信号给其他线程/等待者
          FShutdown := True;
          // 立即从线程池列表移除，避免回落滞后（幂等，有锁保护）
          if Assigned(FThreadPool) then TThreadPool(FThreadPool).RemoveWorkerThread(Self);
          if Assigned(FTaskAvailableEvent) then FTaskAvailableEvent.SetEvent;
          Break;
        end;
      end;

      // 动态等待：基于 KeepAlive/4 调整等待时间，加速收敛（原始策略，稳定）
      LWaitMs := 100;
      if Assigned(FThreadPool) then
      begin
        LPool := TThreadPool(FThreadPool);
        if (LPool.FKeepAliveTimeMs > 0) then
        begin
          // 提高判定频率，加速收缩
          LWaitMs := LPool.FKeepAliveTimeMs div 6;
          if LWaitMs < 5 then LWaitMs := 5;
          if LWaitMs > 80 then LWaitMs := 80;
        end;
      end;

      // 没有任务，等待新任务或关闭信号（短超时，便于 keepAlive 判定）
      case FTaskAvailableEvent.WaitFor(LWaitMs) of
        wrSignaled:
          begin
            DebugLog(Format('Worker %p signaled for tasks', [Pointer(Self)]));
            Continue; // 有新任务，继续循环
          end;
        wrTimeout:
          begin
            // 超时后再次进行 keepAlive 检查
            if Assigned(FThreadPool) then
            begin
              LPool := TThreadPool(FThreadPool);
              LIdleMs := GetTickCount64 - LLastActive;
              LCount := 0; LCore := 0; LCanShrink := False;
              LPool.FLock.Acquire;
              try
                if (LPool.FWorkerThreads <> nil) then
                begin
                  LCount := LPool.FWorkerThreads.Count;
                  LCore := LPool.FCorePoolSize;
                  LCanShrink := (LPool.FKeepAliveTimeMs > 0) and (LIdleMs >= LPool.FKeepAliveTimeMs) and (LCount > LCore);
                end;
              finally
                LPool.FLock.Release;
              end;
              if LCanShrink then
              begin
                // 二次确认：在队列锁下检查是否仍无待执行任务，避免竞态导致丢任务
                LPool.FQueueLock.Acquire;
                try
                  if (LPool.FTaskQueue <> nil) and (LPool.FTaskQueue.GetCount > 0) then
                  begin
                    // 有任务，放弃本次收缩
                    Continue;
                  end;
                finally
                  LPool.FQueueLock.Release;
                end;

                // 指标：收缩尝试（超时路径）
                LPool.FLock.Acquire; try Inc(LPool.FShrinkAttempts); finally LPool.FLock.Release; end;
                DebugLog(Format('Worker %p keepAlive shrink after timeout (idle=%d, size=%d>core=%d)', [Pointer(Self), LIdleMs, LCount, LCore]));

                // 预留收缩名额，防止并发过度收缩到低于 Core（与立即路径一致）
                LReserveOK := False;
                LPool.FLock.Acquire;
                try
                  if (LCount - LCore - LPool.FShrinkReservations) > 0 then
                  begin
                    Inc(LPool.FShrinkReservations);
                    // 记录成功收缩时间（限频依据）
                    LPool.FLastShrinkTick := GetTickCount64;
                    LReserveOK := True;
                  end;
                finally
                  LPool.FLock.Release;
                end;
                if not LReserveOK then
                  Continue;

                // 指标：收缩成功（超时路径）
                LPool.FLock.Acquire; try Inc(LPool.FShrinkSuccessTimeout); finally LPool.FLock.Release; end;
                // 标记退出并立即从池中移除，加速 PoolSize 回落（幂等，有锁保护）
                FShutdown := True;
                if Assigned(FThreadPool) then TThreadPool(FThreadPool).RemoveWorkerThread(Self);
                Break;
              end;
            end;
            Continue;
          end;
      else
        DebugLog(Format('Worker %p wait error -> exit', [Pointer(Self)]));
        Break; // 错误，退出
      end;
    end;
  end;

  DebugLog(Format('Worker %p exit', [Pointer(Self)]));
  NotifyTaskCompletion;
end;

function TWorkerThread.GetNextTask: PTaskItem;
var
  LItem: PTaskItem;
begin
  Result := nil;
  if FShutdown then Exit;
  // 使用队列锁保护任务队列访问
  FQueueLock.Acquire;
  try
    if FTaskQueue.GetCount > 0 then
    begin
      if FTaskQueue.Front(LItem) then
        Result := LItem
      else
        Result := nil;
      // 轻量观测：记录队列驻留时间（仅在开关启用时）
      if GPoolObsMetricsEnabled and Assigned(Result) and (Result^.EnqueueTick<>0) then
      begin
        try
          TThreadPool(FThreadPool).AddQueueObserved(GetTickCount64 - Result^.EnqueueTick);
        except
        end;
      end;
      FTaskQueue.PopFront;
    end;
  finally
    FQueueLock.Release;
  end;
end;

procedure TWorkerThread.ExecuteTask(ATask: PTaskItem);
var
  LResult: Boolean;
  LException: Exception;
begin
  if not Assigned(ATask) then
    Exit;

  // 执行前检查协作式取消
  if Assigned(ATask^.Token) and ATask^.Token.IsCancellationRequested then
  begin
    if Assigned(ATask^.Future) then
    try
      ATask^.Future.Cancel;
    except
    end;
    Exit;
  end;

  LResult := False;
  LException := nil;

  try
    // 通知线程池任务开始执行
    if Assigned(FThreadPool) then
      TThreadPool(FThreadPool).UpdateActiveCount(1);

    // 根据任务类型执行相应的函数
    case ATask^.TaskType of
      ttFunc:
        if Assigned(ATask^.TaskFunc) then
          LResult := ATask^.TaskFunc(ATask^.TaskData);

      ttMethod:
        if Assigned(ATask^.TaskMethod) then
          LResult := ATask^.TaskMethod(ATask^.TaskData);

      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      ttRefFunc:
        if Assigned(ATask^.TaskRefFunc) then
          LResult := ATask^.TaskRefFunc();
      {$ENDIF}
    end;

    // 标记 Future 状态
    if Assigned(ATask^.Future) then
    begin
      if LResult then
        ATask^.Future.Complete
      else
        ATask^.Future.Fail(Exception.Create('Task returned False'));
    end;

  except
    on E: Exception do
    begin
      LException := E;
      // 标记 Future 为失败（仅失败，不再 Complete）
      // 注意：不能直接传递 E（由RTL管理），避免双重释放；复制消息构造新异常
      if Assigned(ATask^.Future) then
        ATask^.Future.Fail(Exception.Create(E.Message));
    end;
  end;

  // 通知线程池任务执行完成
  if Assigned(FThreadPool) then
    TThreadPool(FThreadPool).UpdateActiveCount(-1);


end;

procedure TWorkerThread.NotifyTaskCompletion;
begin
  // 在线程退出点通知线程池移除，避免在线程池析构后访问已释放资源
  if Assigned(FThreadPool) then
    TThreadPool(FThreadPool).RemoveWorkerThread(Self);
  // 保持 FreeOnTerminate=True，让线程自身生命周期结束时进入 Destroy
  FreeOnTerminate := True;
end;

procedure TWorkerThread.Shutdown;
begin
  FLock.Acquire;
  try
    FShutdown := True;
    FShutdownEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

function TWorkerThread.IsShutdown: Boolean;
begin
  FLock.Acquire;
  try
    Result := FShutdown;
  finally
    FLock.Release;
  end;
end;

{ TThreadPool }

constructor TThreadPool.Create(ACorePoolSize, AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal);
var
  I: Integer;
  S: string;
  V: Integer;
begin
  inherited Create;

  // 首先初始化关键字段，确保析构函数安全
  FShutdown := False;
  FTerminated := False;
  FActiveCount := 0;
  FAliveThreads := 0;
  FShrinkReservations := 0;
  FConstructionComplete := False;
  FWorkerThreads := nil;
  FTaskQueue := nil;
  FTaskAvailableEvent := nil;
  FQueueLock := nil;
  FLock := nil;
  FTerminationEvent := nil;

  if ACorePoolSize < 0 then
    raise EInvalidArgument.Create('核心线程数不能为负数');

  if AMaxPoolSize <= 0 then
    AMaxPoolSize := ACorePoolSize;

  if AMaxPoolSize < ACorePoolSize then
    raise EInvalidArgument.Create('最大线程数不能小于核心线程数');

  FCorePoolSize := ACorePoolSize;
  FMaxPoolSize := AMaxPoolSize;
  FKeepAliveTimeMs := AKeepAliveTimeMs;
  // Test-time overrides for faster suites (no effect unless env set)
  try
    s := GetEnvironmentVariable('FAF_TEST_KEEPALIVE_MS');
    if s <> '' then
      FKeepAliveTimeMs := StrToIntDef(s, FKeepAliveTimeMs);
  except
  end;
  begin
    s := GetEnvironmentVariable('FAF_TEST_FAST');
    if (s = '1') or (s = 'true') or (s = 'TRUE') then
    begin
      if FKeepAliveTimeMs > 250 then FKeepAliveTimeMs := 200;
    end;
  end;

  FWorkerThreads := TList.Create;
  FTaskQueue := specialize TVecDeque<PTaskItem>.Create;
  FTaskAvailableEvent := TEvent.Create(False, False); // AutoReset=True, InitialState=False
  FQueueLock := TMutex.Create;

  // 初始化任务对象池（默认上限 = 4 * Core，至少 64；可被环境变量覆盖）
  FTaskItemPool := TList.Create;
  FTaskItemPoolMax := FCorePoolSize * 4;
  if FTaskItemPoolMax < 64 then FTaskItemPoolMax := 64;
  // 环境变量 FAFAFA_THREAD_TASKITEMPOOL_MAX 覆盖（>=1 生效）
  try
    s := GetEnvironmentVariable('FAFAFA_THREAD_TASKITEMPOOL_MAX');
    if (s <> '') then
    begin
      v := StrToIntDef(s, FTaskItemPoolMax);
      if v >= 1 then FTaskItemPoolMax := v;
    end;
  except
  end;
  FTaskPoolLock := TMutex.Create;

  // 默认：无限队列（-1）+ Abort 策略
  FQueueCapacity := -1;
  FRejectPolicy := rpAbort;

  // 初始化指标
  FTotalSubmitted := 0;
  FTotalCompleted := 0;
  FTotalRejected := 0;
  // 分桶拒绝/回退计数
  FRejectedAbort := 0;
  FRejectedCaller := 0;
  FRejectedDiscard := 0;
  FRejectedDiscardOldest := 0;
  // 队列峰值
  FQueuePeak := 0;
  // 初始化对象池指标
  FTaskItemPoolHit := 0;
  FTaskItemPoolMiss := 0;
  FTaskItemPoolReturn := 0;
  FTaskItemPoolDrop := 0;
  // 额外指标
  FCallerRunsAtMax := 0;
  FShrinkAttempts := 0;
  FShrinkSuccessImmediate := 0;
  FShrinkSuccessTimeout := 0;
  FLastShrinkTick := 0;

  FActiveCount := 0;
  FShutdown := False;
  FTerminated := False;
  FConstructionComplete := True; // 构造完成，但延迟创建线程

  FLock := TMutex.Create;
  FTerminationEvent := TEvent.Create(True, False); // ManualReset=True, InitialState=False

  // 立即创建核心线程，但使用安全的方法
  CreateCoreThreadsSafely;
  // 运行时轻量观测开关（环境变量），默认 False
  s := GetEnvironmentVariable('FAFAFA_POOL_METRICS');
  if (s = '1') or (s = 'true') or (s = 'TRUE') then
    GPoolObsMetricsEnabled := True;

end;

constructor TThreadPool.Create(ACorePoolSize, AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal;
  AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy);
var
  I: Integer;
  s: string;
  v: Integer;
begin
  inherited Create;

  // 首先初始化关键字段，确保析构函数安全
  FShutdown := False;
  FTerminated := False;
  FActiveCount := 0;
  FAliveThreads := 0;
  FShrinkReservations := 0;
  FConstructionComplete := False;
  FWorkerThreads := nil;
  FTaskQueue := nil;
  FTaskAvailableEvent := nil;
  FQueueLock := nil;
  FLock := nil;
  FTerminationEvent := nil;

  if ACorePoolSize < 0 then
    raise EInvalidArgument.Create('核心线程数不能为负数');

  if AMaxPoolSize <= 0 then
    AMaxPoolSize := ACorePoolSize;

  if AMaxPoolSize < ACorePoolSize then
    raise EInvalidArgument.Create('最大线程数不能小于核心线程数');

  FCorePoolSize := ACorePoolSize;
  FMaxPoolSize := AMaxPoolSize;
  FKeepAliveTimeMs := AKeepAliveTimeMs;
  // Test-time overrides for faster suites (no effect unless env set)
  try
    s := GetEnvironmentVariable('FAF_TEST_KEEPALIVE_MS');
    if s <> '' then
      FKeepAliveTimeMs := StrToIntDef(s, FKeepAliveTimeMs);
  except
  end;
  begin
    s := GetEnvironmentVariable('FAF_TEST_FAST');
    if (s = '1') or (s = 'true') or (s = 'TRUE') then
    begin
      if FKeepAliveTimeMs > 250 then FKeepAliveTimeMs := 200;
    end;
  end;

  FWorkerThreads := TList.Create;
  FTaskQueue := specialize TVecDeque<PTaskItem>.Create;
  FTaskAvailableEvent := TEvent.Create(False, False); // AutoReset=True, InitialState=False
  FQueueLock := TMutex.Create;

  // 初始化任务对象池（默认上限 = 4 * Core，至少 64；可被环境变量覆盖）
  FTaskItemPool := TList.Create;
  FTaskItemPoolMax := FCorePoolSize * 4;
  if FTaskItemPoolMax < 64 then FTaskItemPoolMax := 64;
  // 环境变量 FAFAFA_THREAD_TASKITEMPOOL_MAX 覆盖（>=1 生效）
  try
    s := GetEnvironmentVariable('FAFAFA_THREAD_TASKITEMPOOL_MAX');
    if (s <> '') then
    begin
      v := StrToIntDef(s, FTaskItemPoolMax);
      if v >= 1 then FTaskItemPoolMax := v;
    end;
  except
  end;
  FTaskPoolLock := TMutex.Create;

  // 默认：无限队列（-1）+ Abort 策略（若传入参数有效则覆盖）
  FQueueCapacity := -1;
  FRejectPolicy := rpAbort;
  if AQueueCapacity >= -1 then
    FQueueCapacity := AQueueCapacity;
  FRejectPolicy := ARejectPolicy;

  // 初始化指标
  FTotalSubmitted := 0;
  FTotalCompleted := 0;
  FTotalRejected := 0;
  // 分桶拒绝/回退计数
  FRejectedAbort := 0;
  FRejectedCaller := 0;
  FRejectedDiscard := 0;
  FRejectedDiscardOldest := 0;
  // 队列峰值
  FQueuePeak := 0;
  // 初始化对象池指标
  FTaskItemPoolHit := 0;
  FTaskItemPoolMiss := 0;
  FTaskItemPoolReturn := 0;
  FTaskItemPoolDrop := 0;
  // 额外指标
  FCallerRunsAtMax := 0;
  FShrinkAttempts := 0;
  FShrinkSuccessImmediate := 0;
  FShrinkSuccessTimeout := 0;
  FLastShrinkTick := 0;

  FActiveCount := 0;
  FShutdown := False;
  FTerminated := False;
  FConstructionComplete := True; // 构造完成，但延迟创建线程

  FLock := TMutex.Create;
  FTerminationEvent := TEvent.Create(True, False); // ManualReset=True, InitialState=False

  // 立即创建核心线程，但使用安全的方法
  CreateCoreThreadsSafely;
end;

destructor TThreadPool.Destroy;
begin
  try
    // 确保线程池已关闭（只有在构造完成后才调用 Shutdown）
    if FConstructionComplete and not FShutdown then
      Shutdown;

    // 等待所有线程结束（通过 AwaitTermination）
    if FConstructionComplete then
      AwaitTermination(5000); // 等待最多5秒

    // 清理资源
    // 先回收任务对象池
    if Assigned(FTaskItemPool) then
    begin
      FTaskPoolLock.Acquire;
      try
        while FTaskItemPool.Count > 0 do
        begin
          Dispose(PTaskItem(FTaskItemPool.Last));
          FTaskItemPool.Delete(FTaskItemPool.Count - 1);
        end;
      finally
        FTaskPoolLock.Release;
      end;
    end;
    FreeAndNil(FTaskItemPool);
    FTaskPoolLock := nil;

  {$IFDEF FAFAFA_THREAD_DEBUG}
  DebugLog(Format('ThreadPool CreateWorkerThread begin (alive=%d,size=%d/core=%d)',
    [FAliveThreads, FWorkerThreads.Count, FCorePoolSize]));
  {$ENDIF}

    FreeAndNil(FWorkerThreads);
    FreeAndNil(FTaskQueue);
    FTaskAvailableEvent := nil;
    FQueueLock := nil;
    FLock := nil;
    FTerminationEvent := nil;
  except
    // 忽略析构函数中的异常，避免二次异常
  end;

  inherited Destroy;
end;

// 内部无锁版本 - 假设调用者已持有 FLock
procedure TThreadPool.CreateWorkerThreadUnlocked;
var
  LWorkerThread: TWorkerThread;
begin
  // 增强的安全检查
  if FShutdown or not Assigned(FWorkerThreads) then
    Exit;

  if FWorkerThreads.Count >= FMaxPoolSize then
    Exit;

  // 创建立即启动的线程
  LWorkerThread := TWorkerThread.Create(FTaskQueue, FTaskAvailableEvent, FQueueLock, Self);
  if Assigned(LWorkerThread) and Assigned(FWorkerThreads) then
  begin
    try
      FWorkerThreads.Add(LWorkerThread);
      Inc(FAliveThreads);
      {$IFDEF FAFAFA_THREAD_DEBUG}
      DebugLog(Format('ThreadPool worker added: alive=%d total=%d %s',
        [FAliveThreads, FWorkerThreads.Count,
         {$IFDEF FAFAFA_THREAD_DEBUG}LWorkerThread.FWorkerName{$ELSE}''{$ENDIF}]));
      {$ENDIF}
    except
      // 如果添加失败，清理线程
      LWorkerThread.Free;
      raise;
    end;
  end;
end;

procedure TThreadPool.CreateWorkerThread;
begin
  FLock.Acquire;
  try
    CreateWorkerThreadUnlocked;
  finally
    FLock.Release;
  end;
end;

procedure TThreadPool.CreateCoreThreadsSafely;
begin
  // 使用 EnsureCoreThreads 来安全地创建线程
  EnsureCoreThreads;
end;

procedure TThreadPool.EnsureCoreThreads;
var
  I, LCurrentCount, LNeededThreads: Integer;
begin
  FLock.Acquire;
  try
    if FShutdown then
      Exit;

    // 安全地计算需要创建的线程数
    LCurrentCount := FWorkerThreads.Count;
    LNeededThreads := FCorePoolSize - LCurrentCount;

    // 确保需要创建的线程数是正数
    if LNeededThreads <= 0 then
      Exit;

    // 逐个创建缺少的核心线程，在锁保护下
    // 使用无锁版本，因为我们已经持有锁
    for I := 1 to LNeededThreads do
    begin
      // 双重检查，确保不超过核心线程数
      if FWorkerThreads.Count < FCorePoolSize then
      begin
        CreateWorkerThreadUnlocked;  // 使用无锁版本！
        // 短暂延迟，让线程完全初始化
        Sleep(1);
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TThreadPool.RemoveWorkerThread(AThread: TWorkerThread);
var
  LIdx: Integer;
  LRemoved: Boolean;
begin
  if not Assigned(AThread) then
    Exit;

  FLock.Acquire;
  try
    LRemoved := False;
    // 安全地从列表中移除线程
    if Assigned(FWorkerThreads) then
    begin
      LIdx := FWorkerThreads.IndexOf(AThread);
      if LIdx >= 0 then
      begin
        FWorkerThreads.Delete(LIdx);
        LRemoved := True;
      end;
    end;

    // 仅在首次移除时递减存活计数
    if LRemoved then
    begin
      if FAliveThreads > 0 then
        Dec(FAliveThreads);
      if FShrinkReservations > 0 then
        Dec(FShrinkReservations);
    end;

    // 检查是否所有线程都已结束
    // 终止信号基于 FAliveThreads，在所有工作线程真正销毁后发出
    if FShutdown and (FAliveThreads = 0) then
    begin
      FTerminated := True;
      if Assigned(FTerminationEvent) then
        FTerminationEvent.SetEvent;
    end;
  finally
    FLock.Release;
  end;
end;


function TThreadPool.AcquireTaskItem: PTaskItem;
begin
  Result := nil;
  // 从池中借用
  if Assigned(FTaskItemPool) then
  begin
    FTaskPoolLock.Acquire;
    try
      if FTaskItemPool.Count > 0 then
      begin
        Result := PTaskItem(FTaskItemPool.Last);
        FTaskItemPool.Delete(FTaskItemPool.Count - 1);
        Inc(FTaskItemPoolHit);
      end;
    finally
      FTaskPoolLock.Release;
    end;
  end;
  // 不足则新建
  if Result = nil then
  begin
    New(Result);
    Inc(FTaskItemPoolMiss);
  end;
end;

procedure TThreadPool.ReleaseTaskItem(var AItem: PTaskItem);
begin
  if AItem = nil then Exit;
  // 清理敏感字段，避免悬挂引用
  AItem^.Future := nil;
  AItem^.TaskFunc := nil;
  AItem^.TaskMethod := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AItem^.TaskRefFunc := nil;
  {$ENDIF}
  AItem^.TaskData := nil;

  if Assigned(FTaskItemPool) then
  begin
    FTaskPoolLock.Acquire;
    try
      if FTaskItemPool.Count < FTaskItemPoolMax then
      begin
        FTaskItemPool.Add(AItem);
        AItem := nil;
        Inc(FTaskItemPoolReturn);
        Exit;
      end;
    finally
      FTaskPoolLock.Release;
    end;
  end;
  // 超出容量则直接释放
  Dispose(AItem);
  AItem := nil;
  Inc(FTaskItemPoolDrop);
end;

function TThreadPool.CreateTaskItem(ATaskType: TTaskType; AFuture: IFutureInternal; AData: Pointer = nil;
                                   ATaskFunc: TTaskFunc = nil; ATaskMethod: TTaskMethod = nil
                                   {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}; const ATaskRefFunc: TTaskRefFunc = nil{$ENDIF}): PTaskItem;
begin
  Result := AcquireTaskItem;
  {$IFDEF FAFAFA_THREAD_DEBUG}
  DebugLog(Format('taskitem.get %p type=%d', [Pointer(Result), Ord(ATaskType)]));
  {$ENDIF}
  Result^.TaskType := ATaskType;
  Result^.TaskFunc := ATaskFunc;
  Result^.TaskMethod := ATaskMethod;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  Result^.TaskRefFunc := ATaskRefFunc;
  {$ENDIF}
  Result^.TaskData := AData;
  Result^.Future := AFuture;
  Result^.Token := nil;
  Result^.EnqueueTick := 0;
end;

procedure TThreadPool.SubmitTaskItem(ATaskItem: PTaskItem; AFuture: IFuture);
var
  LResult: Boolean;
  LExecInCaller: Boolean;
  LExecTask: PTaskItem;
  LOldest: PTaskItem;
  LActiveSnap, LWorkersSnap, LMaxSnap: Integer;
  LQueueLen: Integer;
  LIdleWorkers: Integer;
  LEffectiveQueue: Integer;
  LEffectiveQueueAfterEnqueue: Integer;
  LShouldScaleUp: Boolean;
begin
  if FShutdown then
  begin
    if Assigned(ATaskItem) then ATaskItem^.Future := nil;
    {$IFDEF FAFAFA_THREAD_DEBUG}
    DebugLog(Format('taskitem.free (shutdown) %p', [Pointer(ATaskItem)]));
    {$ENDIF}
    ReleaseTaskItem(ATaskItem);
    raise EThreadPoolError.Create('线程池已关闭，无法提交新任务');
  end;



  EnsureCoreThreads;

  LExecInCaller := False;
  LExecTask := nil;
  LShouldScaleUp := False;

  // 始终遵循锁顺序：FLock -> FQueueLock，避免死锁
  FLock.Acquire;
  try
    LActiveSnap := FActiveCount;
    LWorkersSnap := FWorkerThreads.Count;
    LMaxSnap := FMaxPoolSize;
    LQueueLen := FTaskQueue.GetCount;

    FQueueLock.Acquire;
    try

      // 计算“有效队列长度”：允许空闲工作线程即时领取一个任务，避免竞争导致误判为满
      // 有效长度 = 当前队列长度 - 空闲线程数（不小于0）
      // 说明：
      // - LQueueLen 为 Integer 快照，避免与其它路径中的 QWord 计数混算导致的整数溢出
      // - 有并发窗口：采样活跃线程数与队列长度时，工作线程可能已领取任务，故需对 Idle 做下限截断
      LIdleWorkers := LWorkersSnap - LActiveSnap;
      if LIdleWorkers < 0 then LIdleWorkers := 0;
      LEffectiveQueue := LQueueLen - LIdleWorkers;
      if LEffectiveQueue < 0 then LEffectiveQueue := 0;

      // NOTE:
      // Queue 容量语义为“最多允许多少个排队任务”。判满应基于“入队后的有效长度”。
      // - capacity=0 表示不允许排队，但允许空闲线程即时领取任务（避免所有 Submit 都被拒绝）
      // - capacity=N 允许排队 N 个任务；只有在入队后有效长度 > N 时才拒绝
      LEffectiveQueueAfterEnqueue := (LQueueLen + 1) - LIdleWorkers;
      if LEffectiveQueueAfterEnqueue < 0 then LEffectiveQueueAfterEnqueue := 0;

      // “队列已满”判定改用有效长度
      if (FQueueCapacity >= 0) and (LEffectiveQueueAfterEnqueue > FQueueCapacity) then
      begin
        case FRejectPolicy of
          rpAbort:
            begin
              // 清理任务记录持有的接口引用，避免在 Dispose 时释放一次导致双重释放
              if Assigned(ATaskItem) then
                ATaskItem^.Future := nil;
              {$IFDEF FAFAFA_THREAD_DEBUG}
              DebugLog(Format('taskitem.free (rpAbort) %p', [Pointer(ATaskItem)]));
              {$ENDIF}
              ReleaseTaskItem(ATaskItem);
              Inc(FTotalRejected);
              Inc(FRejectedAbort);
              raise EThreadPoolError.Create('任务队列已满，提交被拒绝');
            end;
          rpCallerRuns:
            begin
              // 决策：在调用线程执行，避免入队导致的竞态（只执行一次，不丢不重）
              LExecInCaller := True;
              Inc(FRejectedCaller);
              Inc(FTotalSubmitted);
              LExecTask := ATaskItem;
              ATaskItem := nil; // 转移所有权，防止后续路径误用/双重释放
            end;
          rpDiscard:
            begin
              if Assigned(ATaskItem^.Future) then
              begin
                ATaskItem^.Future.Fail(EThreadPoolError.Create('任务已被丢弃'));
                ATaskItem^.Future := nil;
              end;
              {$IFDEF FAFAFA_THREAD_DEBUG}
              DebugLog(Format('taskitem.free (rpDiscard) %p', [Pointer(ATaskItem)]));
              {$ENDIF}
              ReleaseTaskItem(ATaskItem);
              Inc(FTotalRejected);
              Inc(FRejectedDiscard);
              Exit;
            end;
          rpDiscardOldest:
            begin
              if FTaskQueue.GetCount > 0 then
              begin
                LOldest := PTaskItem(FTaskQueue.PopFront);
                if Assigned(LOldest) then
                begin
                  if Assigned(LOldest^.Future) then
                  begin
                    LOldest^.Future.Fail(EThreadPoolError.Create('队列已满，最旧任务被丢弃'));
                    LOldest^.Future := nil;
                  end;
                  {$IFDEF FAFAFA_THREAD_DEBUG}
                  DebugLog(Format('taskitem.free (rpDiscardOldest) %p', [Pointer(LOldest)]));
                  {$ENDIF}
                  ReleaseTaskItem(LOldest);
                  Inc(FTotalRejected);
                  Inc(FRejectedDiscardOldest);
                end;
              end;
              // 记录入队时间戳（用于观测队列驻留时间）
              if Assigned(ATaskItem) then ATaskItem^.EnqueueTick := GetTickCount64;
              FTaskQueue.PushBack(ATaskItem);
              ATaskItem := nil;
              Inc(FTotalSubmitted);
              // 入队后更新队列峰值（在队列锁内）
              if FTaskQueue.GetCount > FQueuePeak then FQueuePeak := FTaskQueue.GetCount;
              // 入队后触发扩容（若可扩）：依据 Active+Queue 是否超过 Workers
              LQueueLen := FTaskQueue.GetCount;
              if (LWorkersSnap < LMaxSnap) and ((LActiveSnap + LQueueLen) > LWorkersSnap) then
                LShouldScaleUp := True;
              if Assigned(FTaskAvailableEvent) then FTaskAvailableEvent.SetEvent;
            end;
        end;
      end
      else
      begin
        // CallerRuns：只要已达到最大线程数，则在调用线程执行（避免竞态造成重复/丢执行）
        if (FRejectPolicy = rpCallerRuns) and (LWorkersSnap >= LMaxSnap) then
        begin
          {$IFDEF DEBUG}
          DebugLog(Format('CallerRuns(trigger @max): Max=%d Active=%d Workers=%d Queue=%d',
            [LMaxSnap, LActiveSnap, LWorkersSnap, FTaskQueue.GetCount]));
          {$ENDIF}
          Inc(FCallerRunsAtMax);
          // 达到最大线程数：调用线程直接执行，避免入队后被并发工作线程重复领取
          LExecInCaller := True;
          Inc(FRejectedCaller);
          LExecTask := ATaskItem;
          ATaskItem := nil; // 转移所有权，确保只在 CallerRuns 路径释放
          Inc(FTotalSubmitted);
        end
        else
        begin
          {$IFDEF DEBUG}
          DebugLog(Format('Enqueue (below max): Max=%d Active=%d Workers=%d Queue=%d',
            [LMaxSnap, LActiveSnap, LWorkersSnap, FTaskQueue.GetCount]));
          {$ENDIF}
          // 记录入队时间戳（用于观测队列驻留时间）
          if Assigned(ATaskItem) then ATaskItem^.EnqueueTick := GetTickCount64;
          FTaskQueue.PushBack(ATaskItem);
          ATaskItem := nil;
          Inc(FTotalSubmitted);
          // 入队后若 Active+Queue 超过 Workers 且未达上限，触发扩容
          LQueueLen := FTaskQueue.GetCount;
          if (LWorkersSnap < LMaxSnap) and ((LActiveSnap + LQueueLen) > LWorkersSnap) then
            LShouldScaleUp := True;
          if Assigned(FTaskAvailableEvent) then FTaskAvailableEvent.SetEvent;
        end;
      end;
    finally
      FQueueLock.Release;
    end;
  finally
    FLock.Release;
  end;

  if LExecInCaller and Assigned(LExecTask) then
  begin
    UpdateActiveCount(1);
    try
      try
        case LExecTask^.TaskType of
          ttFunc:
            if Assigned(LExecTask^.TaskFunc) then
              LResult := LExecTask^.TaskFunc(LExecTask^.TaskData)
            else
              LResult := True;
          ttMethod:
            if Assigned(LExecTask^.TaskMethod) then
              LResult := LExecTask^.TaskMethod(LExecTask^.TaskData)
            else
              LResult := True;
          {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
          ttRefFunc:
            if Assigned(LExecTask^.TaskRefFunc) then
              LResult := LExecTask^.TaskRefFunc()
            else
              LResult := True;
          {$ENDIF}
        end;

        if LResult then
          LExecTask^.Future.Complete
        else
          LExecTask^.Future.Fail(Exception.Create('Task returned False'));
      except
        on E: Exception do
          // 复制异常消息，避免将RTL管理的异常对象传递出去导致双重释放
          LExecTask^.Future.Fail(Exception.Create(E.Message));
      end;
    finally
      UpdateActiveCount(-1);
      // 在释放任务前，释放记录中持有的接口引用，并释放任务记录，避免泄漏
      if Assigned(LExecTask) then
      begin
        LExecTask^.Future := nil;
        {$IFDEF FAFAFA_THREAD_DEBUG}
        DebugLog(Format('taskitem.free (callerRuns) %p', [Pointer(LExecTask)]));
        {$ENDIF}
        ReleaseTaskItem(LExecTask);
      end;
    end;
  end;

  // 若需要扩容（在锁外执行以避免自锁)
  if LShouldScaleUp then
    CreateWorkerThread;

end; // SubmitTaskItem

procedure TThreadPool.AddQueueObserved(ADelta: QWord);
begin
  if not GPoolObsMetricsEnabled then Exit;
  FLock.Acquire;
  try
    Inc(FQueueObsTotalMs, ADelta);
    Inc(FQueueObsCount);
  finally
    FLock.Release;
  end;
end;

function TThreadPoolMetrics.QueuePeak: Integer;
begin
  FOwner.FQueueLock.Acquire;
  try
    Result := FOwner.FQueuePeak;
  finally
    FOwner.FQueueLock.Release;
  end;
end;

function TThreadPoolMetrics.RejectedAbort: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FRejectedAbort;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.RejectedCallerRuns: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FRejectedCaller;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.RejectedDiscard: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FRejectedDiscard;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.RejectedDiscardOldest: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FRejectedDiscardOldest;
  finally
    FOwner.FLock.Release;
  end;
end;




{ TThreadPoolMetrics }

constructor TThreadPoolMetrics.Create(AOwner: TThreadPool);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TThreadPoolMetrics.ActiveCount: Integer;
begin
  Result := FOwner.GetActiveCount;
end;

function TThreadPoolMetrics.PoolSize: Integer;
begin
  Result := FOwner.GetPoolSize;
end;

function TThreadPoolMetrics.QueueSize: Integer;
begin
  Result := FOwner.GetQueueSize;
end;

function TThreadPoolMetrics.TotalSubmitted: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTotalSubmitted;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.TotalCompleted: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTotalCompleted;
  finally
    FOwner.FLock.Release;
  end;
end;

class procedure TThreadPool.SetObservedMetricsEnabled(AEnabled: Boolean);
begin
  GPoolObsMetricsEnabled := AEnabled;
end;

function TThreadPool.GetMetrics: IThreadPoolMetrics;
begin
  Result := TThreadPoolMetrics.Create(Self);
end;

function TThreadPoolMetrics.TotalRejected: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTotalRejected;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.TaskItemPoolHit: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTaskItemPoolHit;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.QueueObservedAverageMs: Double;
begin
  FOwner.FLock.Acquire;
  try
    if FOwner.FQueueObsCount = 0 then Exit(0.0);
    Result := FOwner.FQueueObsTotalMs / FOwner.FQueueObsCount;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.TaskItemPoolMiss: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTaskItemPoolMiss;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.TaskItemPoolReturn: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTaskItemPoolReturn;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.TaskItemPoolDrop: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FTaskItemPoolDrop;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.CallerRunsAtMax: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FCallerRunsAtMax;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.KeepAliveShrinkAttempts: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FShrinkAttempts;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.KeepAliveShrinkImmediate: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FShrinkSuccessImmediate;
  finally
    FOwner.FLock.Release;
  end;
end;

function TThreadPoolMetrics.KeepAliveShrinkTimeout: Int64;
begin
  FOwner.FLock.Acquire;
  try
    Result := FOwner.FShrinkSuccessTimeout;
  finally
    FOwner.FLock.Release;
  end;
end;


procedure TThreadPool.UpdateActiveCount(ADelta: Integer);
begin
  FLock.Acquire;
  try
    Inc(FActiveCount, ADelta);
    if FActiveCount < 0 then FActiveCount := 0;
  finally
    FLock.Release;
  end;
end;

function TThreadPool.Submit(ATask: TTaskFunc; AData: Pointer = nil): IFuture;
var
  LFutureObj: TFuture;
  LFutureInt: IFutureInternal;
  LTaskItem: PTaskItem;
begin
  Result := nil;

  LFutureObj := TFuture.Create;
  LFutureInt := LFutureObj; // 以接口持有，确保异常路径正确释放
  LTaskItem := CreateTaskItem(ttFunc, LFutureInt, AData, ATask);
  try
    SubmitTaskItem(LTaskItem, Result);
    LTaskItem := nil;
    Result := LFutureObj; // 返回给调用方的 IFuture 引用
  except
    // 异常路径：先释放接口引用以触发引用计数销毁；
    // 注意：TInterfacedObject 在接口引用归零时会自毁，此后不可再 Free 对象指针
    LFutureInt := nil;
    LFutureObj := nil; // 防悬空，避免二次 Free
    // SubmitTaskItem 持有并负责释放 LTaskItem；此处仅释放 Future 接口
    LFutureInt := nil;
    LFutureObj := nil;
    raise;
  end;
end;

function TThreadPool.Submit(ATask: TTaskFunc; const AToken: ICancellationToken; AData: Pointer = nil): IFuture;
var
  LFutureObj: TFuture;
  LFutureInt: IFutureInternal;
  LTaskItem: PTaskItem;
begin
  if Assigned(AToken) and AToken.IsCancellationRequested then Exit(nil);
  Result := nil;
  LFutureObj := TFuture.Create;
  LFutureInt := LFutureObj;
  LTaskItem := CreateTaskItem(ttFunc, LFutureInt, AData, ATask);
  try
    // 记录 Token；若后续取消且仍在队列，将被剔除/取消
    LTaskItem^.Token := AToken;
    SubmitTaskItem(LTaskItem, Result);
    LTaskItem := nil;
    Result := LFutureObj;
  except
    LFutureInt := nil;
    LFutureObj := nil;
    raise;
  end;
end;

function TThreadPool.Submit(ATask: TTaskMethod; const AToken: ICancellationToken; AData: Pointer = nil): IFuture;
var
  LFutureObj: TFuture;
  LFutureInt: IFutureInternal;
  LTaskItem: PTaskItem;
begin
  if Assigned(AToken) and AToken.IsCancellationRequested then Exit(nil);
  Result := nil;
  LFutureObj := TFuture.Create;
  LFutureInt := LFutureObj;
  LTaskItem := CreateTaskItem(ttMethod, LFutureInt, AData, nil, ATask);
  try
    LTaskItem^.Token := AToken;
    SubmitTaskItem(LTaskItem, Result);
    LTaskItem := nil;
    Result := LFutureObj;
  except
    LFutureInt := nil;
    LFutureObj := nil;
    raise;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TThreadPool.Submit(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture;
var
  LFutureObj: TFuture;
  LFutureInt: IFutureInternal;
  LTaskItem: PTaskItem;
begin
  if Assigned(AToken) and AToken.IsCancellationRequested then Exit(nil);
  Result := nil;
  LFutureObj := TFuture.Create;
  LFutureInt := LFutureObj;
  LTaskItem := CreateTaskItem(ttRefFunc, LFutureInt, nil, nil, nil, ATask);
  try
    LTaskItem^.Token := AToken;
    SubmitTaskItem(LTaskItem, Result);
    LTaskItem := nil;
    Result := LFutureObj;
  except
    LFutureInt := nil;
    LFutureObj := nil;
    raise;
  end;
end;
{$ENDIF}


function TThreadPool.Submit(ATask: TTaskMethod; AData: Pointer = nil): IFuture;
var
  LFutureObj: TFuture;
  LFutureInt: IFutureInternal;
  LTaskItem: PTaskItem;
begin
  Result := nil;
  LFutureObj := TFuture.Create;
  LFutureInt := LFutureObj;
  LTaskItem := CreateTaskItem(ttMethod, LFutureInt, AData, nil, ATask);
  try
    SubmitTaskItem(LTaskItem, Result);
    LTaskItem := nil;
    Result := LFutureObj;
  except
    // 异常路径：先释放接口引用以触发引用计数销毁；
    // 注意：TInterfacedObject 在接口引用归零时会自毁，此后不可再 Free 对象指针
    LFutureInt := nil;
    LFutureObj := nil; // 防悬空，避免二次 Free
    // SubmitTaskItem 持有并负责释放 LTaskItem；此处仅释放 Future 接口
    LFutureInt := nil;
    LFutureObj := nil;
    raise;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TThreadPool.Submit(const ATask: TTaskRefFunc): IFuture;
var
  LFutureObj: TFuture;
  LFutureInt: IFutureInternal;
  LTaskItem: PTaskItem;
begin
  Result := nil;

  LFutureObj := TFuture.Create;
  LFutureInt := LFutureObj;
  LTaskItem := CreateTaskItem(ttRefFunc, LFutureInt, nil, nil, nil, ATask);
  try
    SubmitTaskItem(LTaskItem, Result);
    LTaskItem := nil;
    Result := LFutureObj;
  except
    // 异常路径：先释放接口引用以触发引用计数销毁；
    // 注意：TInterfacedObject 在接口引用归零时会自毁，此后不可再 Free 对象指针
    LFutureInt := nil;
    LFutureObj := nil; // 防悬空，避免二次 Free
    // SubmitTaskItem 持有并负责释放 LTaskItem；此处仅释放 Future 接口
    LFutureInt := nil;
    LFutureObj := nil;
    raise;
  end;
end;
{$ENDIF}

function TThreadPool.GetActiveCount: Integer;
begin
  FLock.Acquire;
  try
    Result := FActiveCount;
  finally
    FLock.Release;
  end;
end;

function TThreadPool.GetPoolSize: Integer;
begin
  FLock.Acquire;
  try
    if Assigned(FWorkerThreads) then
      Result := FWorkerThreads.Count
    else
      Result := 0;
  finally
    FLock.Release;
  end;
end;

function TThreadPool.GetQueueSize: Integer;
begin
  FQueueLock.Acquire;
  try
    Result := FTaskQueue.GetCount;
  finally
    FQueueLock.Release;
  end;
end;

procedure TThreadPool.Shutdown;
var
  I: Integer;
  LWorkerThread: TWorkerThread;
  LThreadList: TList;
  LTaskItem: PTaskItem;
  tmp: PTaskItem;
begin
  FLock.Acquire;
  try
    if FShutdown then
      Exit;

    FShutdown := True;

    // 创建线程列表的副本，完全在锁保护下
    LThreadList := TList.Create;
    // 安全地复制所有线程引用
    for I := FWorkerThreads.Count - 1 downto 0 do
    begin
      if I < FWorkerThreads.Count then
        LThreadList.Add(FWorkerThreads[I]);
    end;

    // 在锁保护下通知所有工作线程关闭
    for I := 0 to LThreadList.Count - 1 do
    begin
      LWorkerThread := TWorkerThread(LThreadList[I]);
      if Assigned(LWorkerThread) then
        LWorkerThread.Shutdown;
    end;

    LThreadList.Free;
  finally
    FLock.Release;
  end;

  // 唤醒等待任务的线程
  if Assigned(FTaskAvailableEvent) then FTaskAvailableEvent.SetEvent;

  // 等待线程自然退出，避免资源残留
  AwaitTermination(5000);

  // 优雅关闭后，仍可能有未被领取的排队任务；为防内存泄漏，这里统一失败并释放
  if Assigned(FTaskQueue) then
  begin
    FQueueLock.Acquire;
    try
      for I := 0 to FTaskQueue.GetCount - 1 do
      begin
        tmp := nil;
        if FTaskQueue.TryGet(I, tmp) then
        begin
          LTaskItem := tmp;
          if Assigned(LTaskItem) then
          begin
            if Assigned(LTaskItem^.Future) then
            begin
              LTaskItem^.Future.Fail(EThreadPoolError.Create('线程池已关闭，任务未执行'));
              LTaskItem^.Future := nil;
            end;
            {$IFDEF FAFAFA_THREAD_DEBUG}
            DebugLog(Format('taskitem.free (shutdown-drain) %p', [Pointer(LTaskItem)]));
            {$ENDIF}
            ReleaseTaskItem(LTaskItem);
          end;
        end;
      end;
      FTaskQueue.Clear;
    finally
      FQueueLock.Release;
    end;
  end;
end;

function TThreadPool.ShutdownNow: TList;
var
  I: Integer;
  LWorkerThread: TWorkerThread;
  LTaskItem: PTaskItem;
  LThreadList: TList;
  tmp: PTaskItem;
begin
  Result := TList.Create;

  FLock.Acquire;
  try
    if FShutdown then
      Exit;

    FShutdown := True;

    // 创建线程列表的副本，完全在锁保护下
    LThreadList := TList.Create;
    // 安全地复制所有线程引用
    for I := FWorkerThreads.Count - 1 downto 0 do
    begin
      if I < FWorkerThreads.Count then
        LThreadList.Add(FWorkerThreads[I]);
    end;

    // 在锁保护下立即终止所有工作线程
    for I := 0 to LThreadList.Count - 1 do
    begin
      LWorkerThread := TWorkerThread(LThreadList[I]);
      if Assigned(LWorkerThread) then
      begin
        LWorkerThread.Shutdown;
        LWorkerThread.Terminate;
      end;
    end;

    LThreadList.Free;
  finally
    FLock.Release;
  end;

  // 获取未执行的任务
  FQueueLock.Acquire;
  try
    for I := 0 to FTaskQueue.GetCount - 1 do
    begin
      tmp := nil;
      if FTaskQueue.TryGet(I, tmp) then
        Result.Add(tmp);
    end;
    FTaskQueue.Clear;
  finally
    FQueueLock.Release;
  end;

  // 唤醒等待任务的线程
  if Assigned(FTaskAvailableEvent) then FTaskAvailableEvent.SetEvent;

  // 等待线程尽快退出
  AwaitTermination(5000);
end;

function TThreadPool.IsShutdown: Boolean;
begin
  FLock.Acquire;
  try
    Result := FShutdown;
  finally
    FLock.Release;
  end;
end;

function TThreadPool.IsTerminated: Boolean;
begin
  FLock.Acquire;
  try
    Result := FTerminated;
  finally
    FLock.Release;
  end;
end;

function TThreadPool.AwaitTermination(ATimeoutMs: Cardinal = INFINITE): Boolean;
begin
  if not FShutdown then
  begin
    Result := False;
    Exit;
  end;

  if FTerminated then
  begin
    Result := True;
    Exit;
  end;

  Result := FTerminationEvent.WaitFor(ATimeoutMs) = wrSignaled;
end;

end.
