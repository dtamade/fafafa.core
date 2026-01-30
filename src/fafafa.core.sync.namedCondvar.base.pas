unit fafafa.core.sync.namedCondvar.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.condvar.base;

type
  // ===== Configuration Structure =====
  TNamedCondVarConfig = record
    TimeoutMs: Cardinal;              // Default timeout in milliseconds
    UseGlobalNamespace: Boolean;      // Whether to use global namespace
    MaxWaiters: Cardinal;             // Maximum number of waiters (for resource preallocation)
    EnableStats: Boolean;             // Whether to enable statistics
  end;

// Configuration helper functions
function DefaultNamedCondVarConfig: TNamedCondVarConfig;
function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
function GlobalNamedCondVarConfig: TNamedCondVarConfig;

type
  // ===== Statistics Structure =====
  TNamedCondVarStats = record
    WaitCount: QWord;                 // Total wait count
    SignalCount: QWord;               // Total signal count
    BroadcastCount: QWord;            // Total broadcast count
    TimeoutCount: QWord;              // Timeout count
    SuccessfulWaits: QWord;           // Successful wait count
    WakeupCount: QWord;               // Wake up count
    CurrentWaiters: Integer;          // Current number of waiters
    MaxWaiters: Integer;              // Historical maximum waiters
    TotalWaitTimeUs: QWord;           // Total wait time (microseconds)
    MaxWaitTimeUs: QWord;             // Maximum single wait time (microseconds)
  end;

// Empty statistics constant
function EmptyNamedCondVarStats: TNamedCondVarStats;

type
  {**
   * INamedCondVar - 跨进程条件变量接口（实验性）
   *
   * @desc 提供跨进程条件变量功能，支持多进程间的等待/通知机制
   *
   * @experimental
   * 此接口标记为实验性，原因如下：
   *
   * 1. **实现复杂性**：
   *    - 跨进程条件变量需要复杂的同步机制
   *    - Windows 平台需要使用命名事件模拟（无原生支持）
   *    - Unix 平台需要使用 POSIX 共享内存 + pthread_cond_t
   *    - Broadcast 语义在极端竞争场景下有理论风险
   *
   * 2. **平台差异**：
   *    - Windows: 使用命名事件 + 命名互斥锁模拟实现
   *    - Unix: 使用 POSIX pthread_cond_t + PTHREAD_PROCESS_SHARED
   *    - 行为可能存在细微差异（特别是 Broadcast 语义）
   *    - 性能特性在不同平台上有所不同
   *
   * 3. **测试覆盖**：
   *    - 需要更多跨进程测试验证稳定性
   *    - 需要压力测试验证高并发场景
   *    - 需要边界情况测试（超时、竞态条件等）
   *    - 需要长时间运行测试验证内存泄漏
   *
   * 4. **使用建议**：
   *    - 仅在必要时使用跨进程条件变量
   *    - 优先考虑其他跨进程同步原语：
   *      * INamedEvent: 简单的事件通知
   *      * INamedMutex + INamedEvent: 组合实现类似功能
   *      * INamedSemaphore: 计数信号量
   *    - 在生产环境使用前进行充分测试
   *    - 避免在极端竞争场景下使用 Broadcast
   *
   * @stability_plan
   * 稳定化计划：
   * 1. 完成跨进程测试套件（预计 1-2 周）
   * 2. 完成压力测试和边界测试（预计 1 周）
   * 3. 收集实际使用反馈（预计 1-2 个月）
   * 4. 根据反馈调整实现和文档
   * 5. 移除实验性标记（预计 3 个月后）
   *
   * @usage
   *   // 创建命名条件变量
   *   var condvar := MakeNamedCondVar('my_condvar');
   *   var mutex := MakeNamedMutex('my_mutex');
   *
   *   // 等待条件（进程 A）
   *   var guard := mutex.Lock();
   *   try
   *     while not condition do
   *       condvar.Wait(guard);
   *     // 条件满足，执行操作
   *   finally
   *     guard := nil;
   *   end;
   *
   *   // 通知等待者（进程 B）
   *   condvar.Signal();     // 通知一个等待者
   *   condvar.Broadcast();  // 通知所有等待者
   *
   * @alternatives
   * 如果不需要跨进程条件变量的完整语义，考虑使用：
   * - INamedEvent: 简单的事件通知（推荐用于简单场景）
   * - INamedMutex + INamedEvent: 组合实现（更稳定）
   * - ICondVar: 线程内条件变量（如果只需要线程间同步）
   *
   * @thread_safety 线程安全
   * @process_safety 进程安全
   * @posix_equivalent pthread_cond_t with PTHREAD_PROCESS_SHARED
   * @windows_equivalent Named Event + Named Mutex (模拟实现)
   *}
  INamedCondVar = interface(ICondVar)
    ['{D4E5F6A7-8B9C-1DEF-2345-6789ABCDEF01}']

    // Inherited from ICondVar:
    // procedure Wait(const ALock: ILock); overload;
    // function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    // procedure Signal;
    // procedure Broadcast;
    // procedure Lock; (from ILock, protects condition variable internal state)
    // procedure Unlock;
    // function TryLock: Boolean; overload;
    // function TryLockFor(ATimeoutMs: Cardinal): Boolean; overload;
    // function GetLastError: TWaitError; (from ISynchronizable)

    // Named condition variable specific methods
    function GetName: string;                                         // Get condition variable name
    function GetConfig: TNamedCondVarConfig;                          // Get current configuration
    procedure UpdateConfig(const AConfig: TNamedCondVarConfig);       // Update configuration

    // Statistics (if enabled)
    function GetStats: TNamedCondVarStats;                            // Get statistics
    procedure ResetStats;                                             // Reset statistics
  end;

implementation

function DefaultNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result.TimeoutMs := 30000;          // 30 second default timeout
  Result.UseGlobalNamespace := False; // Don't use global namespace by default
  Result.MaxWaiters := 64;            // Default max 64 waiters
  Result.EnableStats := False;        // Don't enable statistics by default
end;

function NamedCondVarConfigWithTimeout(ATimeoutMs: Cardinal): TNamedCondVarConfig;
begin
  Result := DefaultNamedCondVarConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedCondVarConfig: TNamedCondVarConfig;
begin
  Result := DefaultNamedCondVarConfig;
  Result.UseGlobalNamespace := True;
end;

function EmptyNamedCondVarStats: TNamedCondVarStats;
begin
  Result := Default(TNamedCondVarStats);
end;

end.
