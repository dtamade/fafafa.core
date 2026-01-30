unit fafafa.core.thread;

{**
 * fafafa.core.thread - 现代化线程库主模块
 *
 * @desc 提供高性能、类型安全的并发编程支持
 *       借鉴 Rust、Go、Java 等现代语言的线程模型设计
 *       支持 Future/Promise、线程池、通道通信、线程本地存储等
 *
 *       本模块采用门面模式（Facade Pattern），统一导出所有子模块的公共接口：
 *       - fafafa.core.thread.future - Future/Promise 异步结果
 *       - fafafa.core.thread.threadpool - 线程池管理
 *       - fafafa.core.thread.threadlocal - 线程本地存储
 *       - fafafa.core.thread.sync - 同步原语
 *       - fafafa.core.thread.channel - 通道通信
 *       - fafafa.core.thread.scheduler - 任务调度器
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
  // 导入所有子模块
  fafafa.core.thread.future,
  fafafa.core.thread.threadlocal,
  fafafa.core.thread.sync,
  fafafa.core.thread.channel,
  fafafa.core.thread.scheduler,
  fafafa.core.thread.threadpool,
  fafafa.core.thread.cancel,
  fafafa.core.thread.constants;

  {**
   * 使用说明（重要）
   *
   * - 线程池工厂（CreateThreadPool/Fixed/Cached/Single）参数范围与异常契约：
   *   - CorePoolSize: >=0（Cached 可为 0 表示按需创建，不保活核心线程；其他建议 >=1）
   *   - MaxPoolSize: =0 表示默认/不限制；否则须 >= max(1, CorePoolSize)
   *   - KeepAliveTimeMs: >=0（0 表示空闲线程不保活）
   *   - QueueCapacity: >=-1（-1 为无界；0 仅允许立即提交/拒绝）
   *   - RejectPolicy: 见 TRejectPolicy（Abort/CallerRuns/Discard/DiscardOldest）
   *   - 当参数非法时，统一抛出 EInvalidArgument
   *
   * - 线程安全：
   *   - 本门面函数为线程安全；返回的接口对象（IThreadPool/IFuture 等）为引用计数管理
   *   - Shutdown/ShutdownNow：关闭后不再接受新任务；ShutdownNow 返回未执行任务列表
   *
   * - 资源管理：
   *   - 线程池在 Shutdown 后会“排空队列”，对未领取任务调用 Fail 并释放，避免泄漏
   *   - 测试 Runner 建议在退出前显式 Shutdown + AwaitTermination，保证干净收尾
   *
   * - Future.OnComplete：
   *   - 未完成：注册一次性回调；完成：注册后立即回调一次；始终最多一次触发
   *
   * - 兼容性：
   *   - 门面导出类型保持稳定；内部实现细节可能演进，不影响对外 API
   *}

  {**
   * API 快速索引（Quick Index）
   *
   * - 线程池（ThreadPool）
   *   - CreateThreadPool / CreateFixedThreadPool / CreateCachedThreadPool / CreateSingleThreadPool
   *   - 参数：Core/Max/KeepAliveMs/QueueCapacity/RejectPolicy；错误抛 EInvalidArgument
   *   - 指标：GetThreadPoolMetrics -> IThreadPoolMetrics（Active/Pool/Queue/Submitted/Completed/Rejected）
   * - 任务（Task）
   *   - Spawn / SpawnBlocking（函数、方法、匿名函数）
   *   - Join（等待全部）/ Select（等待任一）
   * - 通道（Channel）
   *   - CreateChannel(capacity=0 无缓冲；>0 有缓冲)
   * - 调度器（TaskScheduler）
   *   - CreateTaskScheduler / ITaskSchedulerMetrics
   * - 线程工具（Thread utils）
   *   - GetCPUCount / CreateThreadLocal / CreateCountDownLatch
   *
   * 推荐先阅读 docs/fafafa.core.thread.md 的“拒绝策略语义”“限制与建议”两节。
   *}


  {**
   * 最佳实践 Best Practices
   *
   * - API 入口与安全性
   *   - 优先使用本单元提供的全局函数（如 CreateThreadPool/Spawn/Join/Select），其包含参数校验与一致性约定。
   *   - TThreads.* 静态方法是对等便捷封装，但未重复做参数校验；保持向后兼容。
   *
   * - 线程池选型 Pool selection
   *   - Fixed: 稳定且可预测的 CPU 密集型工作，线程数≈CPU 核心数。
   *   - Cached: 突发/短任务或 I/O 密集型，Core=0 按需创建，注意拒绝策略与背压。
   *   - Single: 需要顺序性与串行访问的场景（如顺序写日志、状态机）。
   *
   * - 队列容量 Queue capacity
   *   - -1 无界：吞吐友好但需防御内存膨胀（上游限流/超时）。
   *   - 0 直通：无队列，强背压；结合 CallerRuns 获得自然限速。
   *   - 有界：建议经验值≈1–2×Core，视任务耗时与生产速率调优。
   *
   * - 拒绝策略 Reject policy
   *   - Abort：强一致，配置缺陷早暴露；调用者捕获 EThreadPoolError。
   *   - CallerRuns：在提交线程执行，产生自然背压，适合负载保护。
   *   - Discard/DiscardOldest：仅用于“可丢弃、幂等”的任务；确保任务自身资源安全释放。
   *
   * - Spawn vs SpawnBlocking
   *   - Spawn：CPU 计算/短 I/O，提交至默认池。
   *   - SpawnBlocking：长阻塞 I/O/同步调用，提交至独立阻塞池，避免饿死默认池。
   *
   * - Future 回调与链式
   *   - OnComplete/ContinueWith 至多一次回调；已完成时注册立即回调；回调应短小，重活请再次提交到线程池。
   *   - Fail(AException) 会接管异常对象所有权；外部传入后不要再次释放该异常对象。
   *
   * - 关停与资源管理
   *   - 退出前显式 Shutdown + AwaitTermination；Shutdown 后队列将被排空并 Fail 未执行任务。
   *   - 确保任务函数对外部资源的所有权清晰（创建者负责/任务内负责），避免泄漏。
   *
   * - Join/Select 等待策略
   *   - Join 等待全部完成；Select 返回最先完成下标（超时 -1）。
   *   - 有超时时按剩余时间分片等待，避免忙等；无超时会让权循环等待。
   *
   * - 监控与调优
   *   - 使用 GetThreadPoolMetrics 观察活动/排队/完成数与扩容情况，按需调整 Core/Max/Queue/Policy。
   *   - CPU 数可用 GetCPUCount 获取；默认池大小策略为 min(max(2, CPU), 32)。
   *
   * - 调试与日志
   *   - 设定环境变量 FAFAFA_THREAD_LOG=1 可启用关键日志；定义 FAFAFA_THREAD_DEBUG 获得更详细内部日志（发布版应关闭）。
   *}



type

  {**
   * 重新导出所有公共接口类型
   * 确保向后兼容性，现有代码无需修改
   *}

  // Future 相关类型
  IFuture = fafafa.core.thread.future.IFuture;
  IFutureInternal = fafafa.core.thread.future.IFutureInternal;
  TFuture = fafafa.core.thread.future.TFuture;
  TFutureState = fafafa.core.thread.future.TFutureState;

  // 线程池相关类型
  IThreadPool = fafafa.core.thread.threadpool.IThreadPool;
  TThreadPool = fafafa.core.thread.threadpool.TThreadPool;
  TWorkerThread = fafafa.core.thread.threadpool.TWorkerThread;
  TTaskType = fafafa.core.thread.threadpool.TTaskType;
  PTaskItem = fafafa.core.thread.threadpool.PTaskItem;
  TTaskItem = fafafa.core.thread.threadpool.TTaskItem;
  TRejectPolicy = fafafa.core.thread.threadpool.TRejectPolicy;

  // 线程本地存储相关类型
  IThreadLocal = fafafa.core.thread.threadlocal.IThreadLocal;
  TThreadLocal = fafafa.core.thread.threadlocal.TThreadLocal;
  TThreadLocalValue = fafafa.core.thread.threadlocal.TThreadLocalValue;

  // 同步原语相关类型
  ICountDownLatch = fafafa.core.thread.sync.ICountDownLatch;
  TCountDownLatch = fafafa.core.thread.sync.TCountDownLatch;

  // 通道相关类型
  IChannel = fafafa.core.thread.channel.IChannel;
  TChannel = fafafa.core.thread.channel.TChannel;

  // 任务调度器相关类型
  ITaskScheduler = fafafa.core.thread.scheduler.ITaskScheduler;
  ITaskSchedulerMetrics = fafafa.core.thread.scheduler.ITaskSchedulerMetrics;
  TTaskScheduler = fafafa.core.thread.scheduler.TTaskScheduler;

  // 取消相关类型（门面导出）
  ICancellationToken = fafafa.core.thread.cancel.ICancellationToken;
  ICancellationTokenSource = fafafa.core.thread.cancel.ICancellationTokenSource;


  // 线程池指标只读接口（门面导出）
  IThreadPoolMetrics = fafafa.core.thread.threadpool.IThreadPoolMetrics;

  // 任务函数类型
  TTaskFunc = function(aData: Pointer): Boolean;
  TTaskMethod = function(aData: Pointer): Boolean of Object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TTaskRefFunc = reference to function(): Boolean;
  {$ENDIF}

  // 异常类型（统一为子模块类型的别名，避免跨单元类型不一致）
  EThreadError = fafafa.core.thread.threadpool.EThreadError;
  EThreadPoolError = fafafa.core.thread.threadpool.EThreadPoolError;
  EFutureError = fafafa.core.thread.future.EFutureError;
  EFutureTimeoutError = fafafa.core.thread.future.EFutureTimeoutError;
  EFutureCancelledError = fafafa.core.thread.future.EFutureCancelledError;
  ETaskSchedulerError = fafafa.core.thread.scheduler.ETaskSchedulerError;

  {**
   * TThreads
   *
   * @desc 线程工具类
   *       提供静态方法用于创建和管理线程相关对象
   * @note 建议作为首选门面使用；全局函数仅作为兼容别名保留。
   *}
  TThreads = class
  private


    class function GetDefaultThreadPool: IThreadPool; static;
    class function GetBlockingThreadPool: IThreadPool; static;

  public
    {**
     * CreateThreadPool
     *
     * @desc 创建线程池
     *
     * @params
     *    ACorePoolSize: Integer 核心线程数量
     *    AMaxPoolSize: Integer 最大线程数量（可选，默认等于核心线程数）
     *    AKeepAliveTimeMs: Cardinal 空闲线程存活时间（毫秒，可选，默认60秒）
     *
     * @return 返回线程池接口
     *}
    class function CreateThreadPool(ACorePoolSize: Integer;
                                   AMaxPoolSize: Integer = 0;
                                   AKeepAliveTimeMs: Cardinal = 60000): IThreadPool; overload; static;
    class function CreateThreadPool(ACorePoolSize: Integer;
                                   AMaxPoolSize: Integer;
                                   AKeepAliveTimeMs: Cardinal;
                                   AQueueCapacity: Integer;
                                   ARejectPolicy: TRejectPolicy): IThreadPool; overload; static;

    {**
     * CreateFixedThreadPool
     *
     * @desc 创建固定大小的线程池
     *
     * @params
     *    AThreadCount: Integer 线程数量
     *
     * @return 返回线程池接口
     *}
    class function CreateFixedThreadPool(AThreadCount: Integer): IThreadPool; overload; static;
    class function CreateFixedThreadPool(AThreadCount: Integer; AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool; overload; static;

    {**
     * CreateCachedThreadPool
     *
     * @desc 创建缓存线程池（根据需要创建新线程）
     *
     * @return 返回线程池接口
     *}
    class function CreateCachedThreadPool: IThreadPool; overload; static;
    class function CreateCachedThreadPool(AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool; overload; static;

    {**
     * CreateSingleThreadPool
     *
     * @desc 创建单线程池
     *
     * @return 返回线程池接口
     *}
    class function CreateSingleThreadPool: IThreadPool; overload; static;
    class function CreateSingleThreadPool(AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool; overload; static;

    {**
     * CreateThreadLocal
     *
     * @desc 创建线程本地存储
     *
     * @return 返回线程本地存储接口
     *}
    class function CreateThreadLocal: IThreadLocal; static;

    {**
     * CreateCountDownLatch
     *
     * @desc 创建倒计数门闩
     *
     * @params
     *    ACount: Integer 初始计数值
     *
     * @return 返回倒计数门闩接口
     *}
    class function CreateCountDownLatch(ACount: Integer): ICountDownLatch; static;

    {**
     * CreateTaskScheduler
     *
     * @desc 创建任务调度器
     *
     * @return 返回任务调度器接口
     *}
    class function CreateTaskScheduler: ITaskScheduler; static;

    {**
     * Spawn - Rust 启发的简洁任务提交 API
     *
     * @desc 在默认线程池中生成一个新任务（类似 Rust 的 tokio::spawn）
     *
     * @params
     *    ATask: TTaskFunc 要执行的函数
     *    AData: Pointer 传递给函数的数据
     *
     * @return 返回 Future 对象用于跟踪任务状态
     *}
    class function Spawn(ATask: TTaskFunc; AData: Pointer = nil): IFuture; static;
    class function Spawn(ATask: TTaskMethod; AData: Pointer = nil): IFuture; static;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function Spawn(const ATask: TTaskRefFunc): IFuture; static;
    {$ENDIF}

    {**
     * SpawnBlocking - 阻塞任务生成
     *
     * @desc 生成一个可能阻塞的任务（类似 Rust 的 spawn_blocking）。
     *       该任务会提交到独立的阻塞线程池，避免阻塞默认线程池。
     *
     * @params
     *    ATask: TTaskFunc 要执行的函数
     *    AData: Pointer 传递给函数的数据
     *
     * @return 返回 Future 对象用于跟踪任务状态
     *}
    class function SpawnBlocking(ATask: TTaskFunc; AData: Pointer = nil): IFuture; static;
    class function SpawnBlocking(ATask: TTaskMethod; AData: Pointer = nil): IFuture; static;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function SpawnBlocking(const ATask: TTaskRefFunc): IFuture; static;
    {$ENDIF}

    // 协作式取消：TThreads 也提供 Token 友好重载（与全局函数语义对等，但不重复参数校验）
    class function Spawn(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; static;
    class function Spawn(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; static;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function Spawn(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture; overload; static;
    {$ENDIF}
    class function SpawnBlocking(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; static;
    class function SpawnBlocking(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; static;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function SpawnBlocking(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture; overload; static;
    {$ENDIF}

    {**
     * CreateChannel - 创建通道
     *
     * @desc 创建一个用于线程间通信的通道（类似 Rust 的 mpsc::channel）
     *
     * @params
     *    ACapacity: Integer 通道容量，0 表示无缓冲通道，>0 表示有缓冲通道
     *
     * @return 返回通道接口
     *}
    class function CreateChannel(ACapacity: Integer = 0): IChannel; static;

    {**
     * Join - 等待多个 Future 完成
     *
     * @desc 等待所有给定的 Future 完成（类似 Rust 的 join!）
     *
     * @params
     *    AFutures: array of IFuture 要等待的 Future 数组
     *    ATimeoutMs: Cardinal 总超时时间（毫秒）
     *
     * @return 所有 Future 都完成返回 True，否则返回 False
     *}
    class function Join(const AFutures: array of IFuture; ATimeoutMs: Cardinal = INFINITE): Boolean; static;

    {**
     * GetCPUCount
     *
     * @desc 获取 CPU 核心数量
     *
     * @return 返回 CPU 核心数量
     *}
    class function GetCPUCount: Integer; static;

    {**
     * Sleep
     *
     * @desc 线程休眠
     *
     * @params
     *    AMilliseconds: Cardinal 休眠时间（毫秒）
     *}
    class procedure Sleep(AMilliseconds: Cardinal); static;

    {**
     * Yield
     *
     * @desc 让出当前线程的执行权
     *}
    class procedure Yield; static;

    {** 指标：从线程池获取只读指标接口 **}
    class function GetMetrics(const APool: IThreadPool): IThreadPoolMetrics; static;
  end;

// 全局线程函数（兼容保留）。建议优先使用 TThreads 静态类门面；后续将为这些全局函数添加 @deprecated 标注，引导迁移。
function GetDefaultThreadPool: IThreadPool; // @deprecated 建议改用 TThreads.GetDefaultThreadPool
function GetBlockingThreadPool: IThreadPool; // @deprecated 建议改用 TThreads.GetBlockingThreadPool
function CreateThreadPool(ACorePoolSize: Integer; AMaxPoolSize: Integer = 0; AKeepAliveTimeMs: Cardinal = 60000): IThreadPool; overload; // @deprecated 建议改用 TThreads.CreateThreadPool
function CreateThreadPool(ACorePoolSize: Integer; AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal; AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool; overload; // @deprecated 建议改用 TThreads.CreateThreadPool
function CreateCancellationTokenSource: ICancellationTokenSource;

function CreateFixedThreadPool(AThreadCount: Integer): IThreadPool; // @deprecated 建议改用 TThreads.CreateFixedThreadPool
function CreateCachedThreadPool: IThreadPool; // @deprecated 建议改用 TThreads.CreateCachedThreadPool
function CreateSingleThreadPool: IThreadPool; // @deprecated 建议改用 TThreads.CreateSingleThreadPool
function CreateThreadLocal: IThreadLocal; // @deprecated 建议改用 TThreads.CreateThreadLocal
function CreateCountDownLatch(ACount: Integer): ICountDownLatch; // @deprecated 建议改用 TThreads.CreateCountDownLatch
function CreateTaskScheduler: ITaskScheduler; // @deprecated 建议改用 TThreads.CreateTaskScheduler
// Spawn 便捷重载
function Spawn(ATask: TTaskFunc; AData: Pointer = nil): IFuture; overload; // @deprecated 建议改用 TThreads.Spawn
function Spawn(ATask: TTaskMethod; AData: Pointer = nil): IFuture; overload; // @deprecated 建议改用 TThreads.Spawn
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function Spawn(const ATask: TTaskRefFunc): IFuture; overload; // @deprecated 建议改用 TThreads.Spawn
{$ENDIF}
function SpawnBlocking(ATask: TTaskFunc; AData: Pointer = nil): IFuture; overload; // @deprecated 建议改用 TThreads.SpawnBlocking
function SpawnBlocking(ATask: TTaskMethod; AData: Pointer = nil): IFuture; overload; // @deprecated 建议改用 TThreads.SpawnBlocking
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function SpawnBlocking(const ATask: TTaskRefFunc): IFuture; overload; // @deprecated 建议改用 TThreads.SpawnBlocking
{$ENDIF}
// Token 友好重载（协作式取消）
function Spawn(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; // @deprecated 建议改用 TThreads.Spawn
function Spawn(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; // @deprecated 建议改用 TThreads.Spawn
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function Spawn(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture; overload; // @deprecated 建议改用 TThreads.Spawn
{$ENDIF}
function SpawnBlocking(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; // @deprecated 建议改用 TThreads.SpawnBlocking
function SpawnBlocking(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture; overload; // @deprecated 建议改用 TThreads.SpawnBlocking
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function SpawnBlocking(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture; overload; // @deprecated 建议改用 TThreads.SpawnBlocking
{$ENDIF}
function CreateChannel(ACapacity: Integer = 0): IChannel; // @deprecated 建议改用 TThreads.CreateChannel
function Join(const AFutures: array of IFuture; ATimeoutMs: Cardinal = INFINITE): Boolean; // @deprecated 建议改用 TThreads.Join
function Select(const AFutures: array of IFuture; ATimeoutMs: Cardinal = INFINITE): Integer; // @deprecated 建议改用 TThreads.Select
// 指标便捷函数
function GetThreadPoolMetrics(const APool: IThreadPool): IThreadPoolMetrics; // @deprecated 建议改用 TThreads.GetMetrics
// 取消辅助
function IsCancelled(const AToken: ICancellationToken): Boolean; inline;
// Future 组合助手
function FutureAll(const AFutures: array of IFuture; ATimeoutMs: Cardinal = INFINITE): Boolean;
function FutureAny(const AFutures: array of IFuture; ATimeoutMs: Cardinal = INFINITE): Integer;
function FutureTimeout(const AFuture: IFuture; ATimeoutMs: Cardinal): Boolean;
function FutureWaitOrCancel(const AFuture: IFuture; const AToken: ICancellationToken; ATimeoutMs: Cardinal = INFINITE): Boolean;
function FutureMap(const AFuture: IFuture; AMapper: TTaskFunc; AData: Pointer = nil): IFuture;
function FutureThen(const AFuture: IFuture; ANext: TTaskFunc; AData: Pointer = nil): IFuture;
// Future 便捷方法
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure OnComplete(const AFuture: IFuture; const ACallback: TTaskRefFunc);
function ContinueWith(const AFuture: IFuture; const ACallback: TTaskRefFunc): IFuture;
{$ENDIF}

function GetCPUCount: Integer;
procedure Sleep(AMilliseconds: Cardinal);
procedure Yield;

implementation


// 内部单例与线程安全初始化，避免门面递归/遮蔽
var
  GInitLock: ILock = nil;
  GDefaultPool: IThreadPool = nil;
  GBlockingPool: IThreadPool = nil;

function InternalGetCPUCount: Integer;
begin
  Result := System.CPUCount;
  if Result <= 0 then
    Result := 1;
end;

procedure EnsureInitLock;
begin
  if GInitLock = nil then
    GInitLock := TMutex.Create;
end;

function InternalGetDefaultThreadPool: IThreadPool;
var
  LCPU: Integer;
  LCore: Integer;
begin
  if Assigned(GDefaultPool) then
  begin
    Result := GDefaultPool;
    Exit;
  end;
  EnsureInitLock;
  GInitLock.Acquire;
  try
    if not Assigned(GDefaultPool) then
    begin
      // 默认池：min(max(2, CPUCount), 32)，KeepAlive=60s
      LCPU := InternalGetCPUCount;
      if LCPU < 2 then LCore := 2 else LCore := LCPU;
      if LCore > 32 then LCore := 32;
      GDefaultPool := TThreadPool.Create(LCore, LCore, 60000);
    end;
    Result := GDefaultPool;
  finally
    GInitLock.Release;
  end;
end;

// 阻塞任务线程池（SpawnBlocking 使用）：
// 尺寸策略 = min(4, max(2, CPUCount))，避免阻塞任务饿死默认线程池

function InternalGetBlockingThreadPool: IThreadPool;
var
  LCPU: Integer;
  LSize: Integer;
begin
  if Assigned(GBlockingPool) then
  begin
    Result := GBlockingPool;
    Exit;
  end;
  EnsureInitLock;
  GInitLock.Acquire;
  try
    if not Assigned(GBlockingPool) then
    begin
      // 阻塞池：min(4, max(2, CPUCount))
      LCPU := InternalGetCPUCount;
      if LCPU < 2 then LSize := 2 else LSize := LCPU;
      if LSize > 4 then LSize := 4;
      GBlockingPool := TThreadPool.Create(LSize, LSize, 60000);
    end;
    Result := GBlockingPool;
  finally
    GInitLock.Release;
  end;
end;


// 全局函数实现（委托内部单例，避免递归）
function GetDefaultThreadPool: IThreadPool;
begin
  Result := InternalGetDefaultThreadPool;
end;

function GetBlockingThreadPool: IThreadPool;
begin
  Result := InternalGetBlockingThreadPool;
end;

var
  LMinMax: Integer;
  LMinMax2: Integer;

function CreateThreadPool(ACorePoolSize: Integer; AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal): IThreadPool;
begin
  // 参数校验（统一抛 EInvalidArgument）
  // 允许 CachedThreadPool 的 Core=0；因此检查 >= 0
  if ACorePoolSize < 0 then
    raise EInvalidArgument.Create('CorePoolSize must be >= 0');
  // 约束 Max：当提供非 0 的 Max 时，要求 Max >= max(1, Core)
  // （Core=0 时至少允许创建 1 个线程）
  if (AMaxPoolSize <> 0) then
  begin
    // 旧版 FPC 对局部 var 的 inline 定义支持不稳定，改为分离声明
    // var LMinMax: Integer;（已移除）
    // 计算 LMinMax = max(1, Core)
    // 注意：保留可读性，不做奇技淫巧
    //
    // 先按 Core 初始化
    // 再按 1 进行下界收敛
    //
    // 这样写在老编译器也更稳
    //
    // 声明提升到函数顶部会污染作用域，这里保守写法：拆解为两行赋值
    //（Pascal 不允许在 begin...end 中再写 var）
    //
    // 实际代码：
    //   LMinMax := ACorePoolSize;
    //   if LMinMax < 1 then LMinMax := 1;
    LMinMax := ACorePoolSize;
    if LMinMax < 1 then LMinMax := 1;
    if AMaxPoolSize < LMinMax then
      raise EInvalidArgument.Create('MaxPoolSize must be 0 or >= max(1, CorePoolSize)');
  end;
  // AKeepAliveTimeMs 允许为 0（立即回收空闲线程）
  Result := TThreadPool.Create(ACorePoolSize, AMaxPoolSize, AKeepAliveTimeMs);
end;

function CreateThreadPool(ACorePoolSize: Integer; AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal; AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool;
begin
  // 参数校验
  if ACorePoolSize < 0 then
    raise EInvalidArgument.Create('CorePoolSize must be >= 0');
  if (AMaxPoolSize <> 0) then
  begin
    LMinMax2 := ACorePoolSize;
    if LMinMax2 < 1 then LMinMax2 := 1;
    if AMaxPoolSize < LMinMax2 then
      raise EInvalidArgument.Create('MaxPoolSize must be 0 or >= max(1, CorePoolSize)');
  end;
  if AQueueCapacity < -1 then
    raise EInvalidArgument.Create('QueueCapacity must be >= -1');
  Result := TThreadPool.Create(ACorePoolSize, AMaxPoolSize, AKeepAliveTimeMs, AQueueCapacity, ARejectPolicy);
end;

function CreateFixedThreadPool(AThreadCount: Integer): IThreadPool;
begin
  if AThreadCount < 1 then
    raise EInvalidArgument.Create('ThreadCount must be >= 1');
  Result := CreateThreadPool(AThreadCount, AThreadCount);
end;

function CreateCachedThreadPool: IThreadPool;
var
  LCPU, LMax: Integer;
begin
  // Cached: Core=0（按需创建），Max 采用保守上限：min(64, 4×CPU)，且不少于 8
  LCPU := GetCPUCount;
  if LCPU < 1 then LCPU := 1;
  LMax := LCPU * 4;
  if LMax < 8 then LMax := 8;
  if LMax > 64 then LMax := 64;
  Result := CreateThreadPool(0, LMax, 60000);
end;

function CreateSingleThreadPool: IThreadPool;
begin
  Result := CreateThreadPool(1, 1);
end;

function CreateThreadLocal: IThreadLocal;
begin
  Result := TThreadLocal.Create;
end;

function CreateCancellationTokenSource: ICancellationTokenSource;
begin
  Result := fafafa.core.thread.cancel.CreateCancellationTokenSource;
end;

function CreateCountDownLatch(ACount: Integer): ICountDownLatch;
begin
  Result := TCountDownLatch.Create(ACount);
end;

function CreateTaskScheduler: ITaskScheduler;
begin
  Result := TTaskScheduler.Create;
end;



function Spawn(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  // 统一透传 Token 到线程池，便于队列内取消与指标统计
  Result := GetDefaultThreadPool.Submit(ATask, AToken, AData);
end;

function Spawn(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetDefaultThreadPool.Submit(ATask, AToken, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function Spawn(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetDefaultThreadPool.Submit(ATask, AToken);
end;
{$ENDIF}

function SpawnBlocking(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetBlockingThreadPool.Submit(ATask, AToken, AData);
end;

function SpawnBlocking(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetBlockingThreadPool.Submit(ATask, AToken, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function SpawnBlocking(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetBlockingThreadPool.Submit(ATask, AToken);
end;
{$ENDIF}

function Spawn(ATask: TTaskFunc; AData: Pointer): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetDefaultThreadPool.Submit(ATask, AData);
end;

function Spawn(ATask: TTaskMethod; AData: Pointer): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetDefaultThreadPool.Submit(ATask, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function Spawn(const ATask: TTaskRefFunc): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetDefaultThreadPool.Submit(ATask);
end;
{$ENDIF}

function SpawnBlocking(ATask: TTaskFunc; AData: Pointer): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetBlockingThreadPool.Submit(ATask, AData);
end;

function SpawnBlocking(ATask: TTaskMethod; AData: Pointer): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetBlockingThreadPool.Submit(ATask, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function SpawnBlocking(const ATask: TTaskRefFunc): IFuture;
begin
  if not Assigned(ATask) then Exit(nil);
  Result := GetBlockingThreadPool.Submit(ATask);
end;
{$ENDIF}

function CreateChannel(ACapacity: Integer): IChannel;
begin
  Result := TChannel.Create(ACapacity);
end;

function Join(const AFutures: array of IFuture; ATimeoutMs: Cardinal): Boolean;
var
  I: Integer;
  LStartTime, LNow: QWord;
  LRem: Cardinal;
begin
  Result := True;
  LStartTime := GetTickCount64;

  // 快路径：无超时，直接阻塞等待每个 Future 完成
  if ATimeoutMs = INFINITE then
  begin
    for I := Low(AFutures) to High(AFutures) do
      if Assigned(AFutures[I]) and (not AFutures[I].WaitFor(INFINITE)) then
        Exit(False);
    Exit(True);
  end;

  // 有超时：逐个按剩余时间等待，期间避免重复调用 GetTickCount64
  for I := Low(AFutures) to High(AFutures) do
  begin
    if not Assigned(AFutures[I]) then
      Continue;

    LNow := GetTickCount64;
    if LNow - LStartTime >= ATimeoutMs then
      Exit(False);

    LRem := ATimeoutMs - (LNow - LStartTime);
    if not AFutures[I].WaitFor(LRem) then
      Exit(False);
  end;

  Result := True;
end;

function Select(const AFutures: array of IFuture; ATimeoutMs: Cardinal): Integer;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{$IFDEF FAFAFA_THREAD_SELECT_NONPOLLING}
var
  I: Integer;
  LEvent: IEvent;
  LLock: ILock;
  LFirstIdx: Integer;
  LTriggered: Boolean;
  LTimeout: Cardinal;
  LCallbacks: array of TTaskRefFunc;

  function MakeCallback(const Idx: Integer): TTaskRefFunc;
  begin
    Result := function(): Boolean
    begin
      LLock.Acquire;
      try
        if not LTriggered then
        begin
          LTriggered := True;
          LFirstIdx := Idx;
          LEvent.SetEvent;
        end;
      finally
        LLock.Release;
      end;
      Result := True;
    end;
  end;
{$ELSE}
var
  I: Integer;
  LStart, LNow: QWord;
  LSlice: Cardinal;
{$ENDIF}
{$ELSE}
var
  I: Integer;
  LStart, LNow: QWord;
  LSlice: Cardinal;
{$ENDIF}
begin
  // 返回第一个完成的下标；超时返回 -1
  Result := -1;
  if Length(AFutures) = 0 then Exit(-1);

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{$IFDEF FAFAFA_THREAD_SELECT_NONPOLLING}
  // 非轮询路径：利用 OnComplete 注册一次性回调，捕获首个完成索引
  LEvent := TEvent.Create(True, False); // ManualReset
  LLock := TMutex.Create;
  LFirstIdx := -1; LTriggered := False;
  SetLength(LCallbacks, Length(AFutures));

  // 已完成的快速路径：直接返回最小下标
  for I := Low(AFutures) to High(AFutures) do
    if Assigned(AFutures[I]) and AFutures[I].IsDone then
      Exit(I);

  // 注册回调：谁先完成谁设置结果并唤醒事件（只触发一次）
  for I := Low(AFutures) to High(AFutures) do
  begin
    if not Assigned(AFutures[I]) then Continue;
    LCallbacks[I] := MakeCallback(I);
    AFutures[I].OnComplete(LCallbacks[I]);
  end;

  // 等待事件或超时
  if ATimeoutMs = INFINITE then LTimeout := INFINITE else LTimeout := ATimeoutMs;
  if LEvent.WaitFor(LTimeout) = wrSignaled then
  begin
    // 双检，确保返回值
    LLock.Acquire; try Result := LFirstIdx; finally LLock.Release; end;
  end
  else
    Result := -1;
  Exit;
{$ENDIF}
{$ENDIF}

{$IFNDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 轮询路径：跨平台稳定
  // 无超时：轮询 IsDone + 让权，直到任一完成
  if ATimeoutMs = INFINITE then
  begin
    while True do
    begin
      for I := Low(AFutures) to High(AFutures) do
      begin
        if Assigned(AFutures[I]) and AFutures[I].IsDone then
          Exit(I);
      end;
      // 轻量让权，避免忙等
      Yield;
    end;
  end
  else
  begin
    // 有总超时：逐步缩短剩余时间
    LStart := GetTickCount64;
    while True do
    begin
      // 检查是否超时
      LNow := GetTickCount64;
      if LNow - LStart >= ATimeoutMs then Exit(-1);

      // 快速扫描是否已完成
      for I := Low(AFutures) to High(AFutures) do
      begin
        if Assigned(AFutures[I]) and AFutures[I].IsDone then
          Exit(I);
      end;

      // 短暂等待，避免忙等；也给 Future 完成机会
      LSlice := ATimeoutMs - (LNow - LStart);
      if LSlice > 50 then LSlice := 50;
      // 选择一个代表性的 Future 等待一个很短的时间片
      for I := Low(AFutures) to High(AFutures) do
      begin
        if Assigned(AFutures[I]) then
        begin
          if AFutures[I].WaitFor(LSlice) then
            Exit(I);
          Break;
        end;
      end;
    end;
  end;
{$ELSE}
{$IFNDEF FAFAFA_THREAD_SELECT_NONPOLLING}
  // 轮询路径：跨平台稳定
  // 无超时：轮询 IsDone + 让权，直到任一完成
  if ATimeoutMs = INFINITE then
  begin
    while True do
    begin
      for I := Low(AFutures) to High(AFutures) do
      begin
        if Assigned(AFutures[I]) and AFutures[I].IsDone then
          Exit(I);
      end;
      // 轻量让权，避免忙等
      Yield;
    end;
  end
  else
  begin
    // 有总超时：逐步缩短剩余时间
    LStart := GetTickCount64;
    while True do
    begin
      // 检查是否超时
      LNow := GetTickCount64;
      if LNow - LStart >= ATimeoutMs then Exit(-1);

      // 快速扫描是否已完成
      for I := Low(AFutures) to High(AFutures) do
      begin
        if Assigned(AFutures[I]) and AFutures[I].IsDone then
          Exit(I);
      end;

      // 短暂等待，避免忙等；也给 Future 完成机会
      LSlice := ATimeoutMs - (LNow - LStart);
      if LSlice > 50 then LSlice := 50;
      // 选择一个代表性的 Future 等待一个很短的时间片
      for I := Low(AFutures) to High(AFutures) do
      begin
        if Assigned(AFutures[I]) then
        begin
          if AFutures[I].WaitFor(LSlice) then
            Exit(I);
          Break;
        end;
      end;
    end;
  end;
{$ENDIF}
{$ENDIF}
end;


function GetCPUCount: Integer;
begin
  Result := System.CPUCount;
  if Result <= 0 then
    Result := 1;
end;

procedure Sleep(AMilliseconds: Cardinal);
var
  LStart, LNow, LDeadline: QWord;
  LSlice: Cardinal;
begin
  // 更稳健的跨平台睡眠：避免单次长睡导致明显超时
  if AMilliseconds = 0 then
  begin
    SysUtils.Sleep(0);
    Exit;
  end;

  LStart := GetTickCount64;
  LDeadline := LStart + QWord(AMilliseconds);
  while True do
  begin
    LNow := GetTickCount64;
    if LNow >= LDeadline then
      Break;
    // 根据剩余时间选择合适的切片，减少过度超时概率
    LSlice := LDeadline - LNow;
    if LSlice > 20 then
      SysUtils.Sleep(10)
    else if LSlice > 5 then
      SysUtils.Sleep(1)
    else
      // 最后几毫秒采用让权自旋，兼顾精度（时间短，CPU 开销可接受）
      SysUtils.Sleep(0);
  end;
end;

procedure Yield;
begin
  // 让出时间片（不强制 1ms 睡眠，以减少不必要的延迟）
  SysUtils.Sleep(0);
end;


// 暂时简化实现，避免平台特定的依赖

{ TThreads }

class function TThreads.GetDefaultThreadPool: IThreadPool;
begin
  Result := InternalGetDefaultThreadPool;
end;

class function TThreads.GetBlockingThreadPool: IThreadPool;
begin
  Result := InternalGetBlockingThreadPool;
end;

class function TThreads.CreateThreadPool(ACorePoolSize: Integer; AMaxPoolSize: Integer = 0; AKeepAliveTimeMs: Cardinal = 60000): IThreadPool;
begin
  // 统一走全局校验逻辑，避免直连实现类绕过参数检查
  Result := fafafa.core.thread.CreateThreadPool(ACorePoolSize, AMaxPoolSize, AKeepAliveTimeMs);
end;

class function TThreads.CreateThreadPool(ACorePoolSize: Integer; AMaxPoolSize: Integer; AKeepAliveTimeMs: Cardinal; AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool;
begin
  // 统一走全局校验逻辑，避免直连实现类绕过参数检查
  Result := fafafa.core.thread.CreateThreadPool(ACorePoolSize, AMaxPoolSize, AKeepAliveTimeMs, AQueueCapacity, ARejectPolicy);
end;

class function TThreads.CreateFixedThreadPool(AThreadCount: Integer): IThreadPool;
begin
  Result := CreateThreadPool(AThreadCount, AThreadCount);
end;

class function TThreads.CreateFixedThreadPool(AThreadCount: Integer; AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool;
begin
  Result := CreateThreadPool(AThreadCount, AThreadCount, 60000, AQueueCapacity, ARejectPolicy);
end;


class function TThreads.CreateCachedThreadPool: IThreadPool;
var
  LCPU, LMax: Integer;
begin
  // 与全局 CreateCachedThreadPool 保持一致的安全默认上限
  LCPU := GetCPUCount;
  if LCPU < 1 then LCPU := 1;
  LMax := LCPU * 4;
  if LMax < 8 then LMax := 8;
  if LMax > 64 then LMax := 64;
  Result := CreateThreadPool(0, LMax, 60000);
end;
class function TThreads.CreateCachedThreadPool(AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool;
var
  LCPU, LMax: Integer;
begin
  // 在可配置队列与拒绝策略的同时，沿用安全的默认最大线程上限
  LCPU := GetCPUCount;
  if LCPU < 1 then LCPU := 1;
  LMax := LCPU * 4;
  if LMax < 8 then LMax := 8;
  if LMax > 64 then LMax := 64;
  Result := CreateThreadPool(0, LMax, 60000, AQueueCapacity, ARejectPolicy);
end;



class function TThreads.CreateSingleThreadPool: IThreadPool;
begin
  Result := CreateThreadPool(1, 1);
end;

class function TThreads.CreateSingleThreadPool(AQueueCapacity: Integer; ARejectPolicy: TRejectPolicy): IThreadPool;
begin
  Result := CreateThreadPool(1, 1, 60000, AQueueCapacity, ARejectPolicy);
end;

class function TThreads.CreateThreadLocal: IThreadLocal;
begin
  Result := TThreadLocal.Create;
end;

class function TThreads.CreateCountDownLatch(ACount: Integer): ICountDownLatch;
begin
  Result := TCountDownLatch.Create(ACount);
end;

class function TThreads.CreateTaskScheduler: ITaskScheduler;
begin
  Result := TTaskScheduler.Create;
end;

class function TThreads.Spawn(ATask: TTaskFunc; AData: Pointer = nil): IFuture;
begin
  Result := InternalGetDefaultThreadPool.Submit(ATask, AData);
end;

class function TThreads.Spawn(ATask: TTaskMethod; AData: Pointer = nil): IFuture;
begin
  Result := InternalGetDefaultThreadPool.Submit(ATask, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function TThreads.Spawn(const ATask: TTaskRefFunc): IFuture;
begin
  Result := InternalGetDefaultThreadPool.Submit(ATask);
end;
{$ENDIF}

// Token 友好重载（保持与全局函数语义对等，不重复参数校验）
class function TThreads.Spawn(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  Result := InternalGetDefaultThreadPool.Submit(ATask, AToken, AData);
end;

class function TThreads.Spawn(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  Result := InternalGetDefaultThreadPool.Submit(ATask, AToken, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function TThreads.Spawn(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture;
begin
  Result := InternalGetDefaultThreadPool.Submit(ATask, AToken);
end;
{$ENDIF}

class function TThreads.SpawnBlocking(ATask: TTaskFunc; AData: Pointer = nil): IFuture;
begin
  Result := InternalGetBlockingThreadPool.Submit(ATask, AData);
end;

class function TThreads.SpawnBlocking(ATask: TTaskMethod; AData: Pointer = nil): IFuture;
begin
  Result := InternalGetBlockingThreadPool.Submit(ATask, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function TThreads.SpawnBlocking(const ATask: TTaskRefFunc): IFuture;
begin
  Result := InternalGetBlockingThreadPool.Submit(ATask);
end;
{$ENDIF}

class function TThreads.SpawnBlocking(ATask: TTaskFunc; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  Result := InternalGetBlockingThreadPool.Submit(ATask, AToken, AData);
end;

class function TThreads.SpawnBlocking(ATask: TTaskMethod; AData: Pointer; const AToken: ICancellationToken): IFuture;
begin
  Result := InternalGetBlockingThreadPool.Submit(ATask, AToken, AData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function TThreads.SpawnBlocking(const ATask: TTaskRefFunc; const AToken: ICancellationToken): IFuture;
begin
  Result := InternalGetBlockingThreadPool.Submit(ATask, AToken);
end;
{$ENDIF}

class function TThreads.CreateChannel(ACapacity: Integer = 0): IChannel;
begin
  Result := TChannel.Create(ACapacity);
end;

class function TThreads.Join(const AFutures: array of IFuture; ATimeoutMs: Cardinal = INFINITE): Boolean;
begin
  // 显式调用本单元的全局 Join，避免与自身方法同名导致的递归
  Result := fafafa.core.thread.Join(AFutures, ATimeoutMs);
end;

class function TThreads.GetCPUCount: Integer;
begin
  Result := InternalGetCPUCount;
end;

class procedure TThreads.Sleep(AMilliseconds: Cardinal);
begin
  // 委派到本单元的全局 Sleep，保持一致的“分片睡眠 + 让权”策略
  fafafa.core.thread.Sleep(AMilliseconds);
end;

class procedure TThreads.Yield;
begin
  // 委派到本单元的全局 Yield，保持统一语义（Sleep(0) 让权）
  fafafa.core.thread.Yield;
end;

class function TThreads.GetMetrics(const APool: IThreadPool): IThreadPoolMetrics;
begin
  Result := GetThreadPoolMetrics(APool);
end;

// 指标便捷函数
function GetThreadPoolMetrics(const APool: IThreadPool): IThreadPoolMetrics;
begin
  if Assigned(APool) then
    Result := APool.GetMetrics
  else
    Result := nil;
end;

// Future 便捷方法
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure OnComplete(const AFuture: IFuture; const ACallback: TTaskRefFunc);
begin
  if Assigned(AFuture) then
    AFuture.OnComplete(ACallback);
end;

function ContinueWith(const AFuture: IFuture; const ACallback: TTaskRefFunc): IFuture;
begin
  if Assigned(AFuture) then
    Result := AFuture.ContinueWith(ACallback)
  else
    Result := nil;
end;
{$ENDIF}

// Future 组合助手实现（纯函数，保持与门面其余 API 一致）
function FutureAll(const AFutures: array of IFuture; ATimeoutMs: Cardinal): Boolean;
begin
  Result := Join(AFutures, ATimeoutMs);
end;

function FutureAny(const AFutures: array of IFuture; ATimeoutMs: Cardinal): Integer;
begin
  Result := Select(AFutures, ATimeoutMs);
end;



function FutureWaitOrCancel(const AFuture: IFuture; const AToken: ICancellationToken; ATimeoutMs: Cardinal): Boolean;
var deadline, now: QWord; interval: Cardinal;
begin
  if not Assigned(AFuture) then Exit(False);
  if (ATimeoutMs = INFINITE) and not Assigned(AToken) then
    Exit(AFuture.WaitFor(INFINITE));

  deadline := GetTickCount64 + QWord(ATimeoutMs);
  repeat
    if AFuture.IsDone then Exit(True);
    if Assigned(AToken) and AToken.IsCancellationRequested then Exit(False);

    if ATimeoutMs = INFINITE then
      interval := WaitSliceMs
    else begin
      now := GetTickCount64;
      if now >= deadline then Exit(False);
      if (deadline - now) < WaitSliceMs then interval := deadline - now else interval := WaitSliceMs;
    end;
  until AFuture.WaitFor(interval);
  Result := True;
end;

function FutureTimeout(const AFuture: IFuture; ATimeoutMs: Cardinal): Boolean;
begin
  if not Assigned(AFuture) then Exit(False);
  Result := AFuture.WaitFor(ATimeoutMs);
end;

function IsCancelled(const AToken: ICancellationToken): Boolean; inline;
begin
  Result := Assigned(AToken) and AToken.IsCancellationRequested;
end;



function FutureMap(const AFuture: IFuture; AMapper: TTaskFunc; AData: Pointer): IFuture;
begin
  if Assigned(AFuture) then
    Result := AFuture.Map(AMapper, AData)
  else
    Result := nil;
end;

function FutureThen(const AFuture: IFuture; ANext: TTaskFunc; AData: Pointer): IFuture;
begin
  if Assigned(AFuture) then
    Result := AFuture.AndThen(ANext, AData)
  else
    Result := nil;
end;


finalization
  // 优雅收尾：关闭并等待全局线程池退出
  try
    if Assigned(GDefaultPool) then
    begin
      GDefaultPool.Shutdown;
      GDefaultPool.AwaitTermination(3000);
      GDefaultPool := nil;
    end;
    if Assigned(GBlockingPool) then
    begin
      GBlockingPool.Shutdown;
      GBlockingPool.AwaitTermination(3000);
      GBlockingPool := nil;
    end;
  except
    // 防御：忽略收尾中的异常，避免影响进程退出
  end;

end.
