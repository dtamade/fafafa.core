unit fafafa.core.sync.rwlock.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.atomic;

type
  // ===== 类型定义 =====
  TThreadIDArray = array of TThreadID;

  // ===== 版本化原子计数器（防止 ABA 问题）=====
  TAtomicCounter = record
    Count: Integer;    // 实际计数值
    Version: Integer;  // 版本号，每次修改时递增
  end;

  PAtomicCounter = ^TAtomicCounter;

  // ===== 性能监控数据结构 =====
  TLockPerformanceStats = record
    // 基础计数器
    TotalAcquireAttempts: Int64;      // 总获取尝试次数
    SuccessfulAcquires: Int64;        // 成功获取次数
    FailedAcquires: Int64;            // 失败获取次数
    TotalReleases: Int64;             // 总释放次数

    // 读写分离统计
    ReadAcquireAttempts: Int64;       // 读锁获取尝试
    WriteAcquireAttempts: Int64;      // 写锁获取尝试
    ReadSuccesses: Int64;             // 读锁成功次数
    WriteSuccesses: Int64;            // 写锁成功次数

    // 时间统计（微秒）
    TotalWaitTime: Int64;             // 总等待时间
    MaxWaitTime: Int64;               // 最大等待时间
    MinWaitTime: Int64;               // 最小等待时间

    // 自旋统计
    TotalSpinCount: Int64;            // 总自旋次数
    SpinSuccesses: Int64;             // 自旋成功次数

    // 竞争统计
    ContentionEvents: Int64;          // 竞争事件次数
    DeadlockDetections: Int64;        // 死锁检测次数

    // 时间戳
    StartTime: QWord;                 // 统计开始时间
    LastResetTime: QWord;             // 上次重置时间
  end;

  // ===== 锁配置选项 =====
  TRWLockOptions = record
    AllowReentrancy: Boolean;   // 是否允许可重入（默认 True）
    FairMode: Boolean;          // 公平模式：FIFO 调度（默认 False）
    WriterPriority: Boolean;    // 写者优先模式（默认 False）
    MaxReaders: Integer;        // 最大读者数量（默认 1024）
    SpinCount: Integer;         // 初始自旋次数（默认 4000）
  end;

  // ===== 锁操作结果枚举 =====
  TLockResult = (
    lrSuccess,      // 成功获取锁
    lrTimeout,      // 超时
    lrWouldBlock,   // 会阻塞（非阻塞调用）
    lrError         // 错误
  );

  // ===== 异常类型定义 =====

  { 读写锁基础异常 }
  ERWLockError = class(Exception)
  private
    FLockResult: TLockResult;
    FThreadId: TThreadID;
    FTimestamp: TDateTime;
  public
    constructor Create(const AMessage: string; ALockResult: TLockResult = lrError); overload;
    constructor Create(const AMessage: string; ALockResult: TLockResult; AThreadId: TThreadID); overload;

    property LockResult: TLockResult read FLockResult;
    property ThreadId: TThreadID read FThreadId;
    property Timestamp: TDateTime read FTimestamp;
  end;

  { 锁获取超时异常 }
  ERWLockTimeoutError = class(ERWLockError)
  private
    FTimeoutMs: Cardinal;
  public
    constructor Create(ATimeoutMs: Cardinal; AThreadId: TThreadID = 0);
    property TimeoutMs: Cardinal read FTimeoutMs;
  end;

  { 锁状态异常 - 尝试释放未持有的锁 }
  ERWLockStateError = class(ERWLockError)
  private
    FExpectedState: string;
    FActualState: string;
  public
    constructor Create(const AExpectedState, AActualState: string; AThreadId: TThreadID = 0);
    property ExpectedState: string read FExpectedState;
    property ActualState: string read FActualState;
  end;

  { 死锁检测异常 }
  ERWLockDeadlockError = class(ERWLockError)
  private
    FOwnerThread: TThreadID;
    FWaitingThreads: array of TThreadID;
  public
    constructor Create(AOwnerThread: TThreadID; const AWaitingThreads: array of TThreadID);
    property OwnerThread: TThreadID read FOwnerThread;
    function GetWaitingThreads: TThreadIDArray;
  end;

  { 资源耗尽异常 - 读者数量超限 }
  ERWLockResourceError = class(ERWLockError)
  private
    FCurrentCount: Integer;
    FMaxCount: Integer;
  public
    constructor Create(ACurrentCount, AMaxCount: Integer; AThreadId: TThreadID = 0);
    property CurrentCount: Integer read FCurrentCount;
    property MaxCount: Integer read FMaxCount;
  end;

  { 系统错误异常 - 底层系统调用失败 }
  ERWLockSystemError = class(ERWLockError)
  private
    FSystemErrorCode: Integer;
    FSystemErrorMessage: string;
  public
    constructor Create(ASystemErrorCode: Integer; const ASystemErrorMessage: string; AThreadId: TThreadID = 0);
    property SystemErrorCode: Integer read FSystemErrorCode;
    property SystemErrorMessage: string read FSystemErrorMessage;
  end;

  // ===== 扩展异常类型（按照主流标准）=====

  { 操作被中断异常 - 类似 Java InterruptedException }
  ERWLockInterruptedException = class(ERWLockError)
  private
    FInterruptReason: string;
  public
    constructor Create(const AInterruptReason: string; AThreadId: TThreadID = 0);
    property InterruptReason: string read FInterruptReason;
  end;

  { 所有权错误异常 - 类似 Java IllegalMonitorStateException }
  ERWLockOwnershipException = class(ERWLockError)
  private
    FExpectedOwner: TThreadID;
    FActualOwner: TThreadID;
  public
    constructor Create(AExpectedOwner, AActualOwner: TThreadID);
    property ExpectedOwner: TThreadID read FExpectedOwner;
    property ActualOwner: TThreadID read FActualOwner;
  end;

  { 容量超限异常 - 类似 Java IllegalStateException }
  ERWLockCapacityException = class(ERWLockError)
  private
    FRequestedCount: Integer;
    FMaxCapacity: Integer;
  public
    constructor Create(ARequestedCount, AMaxCapacity: Integer; AThreadId: TThreadID = 0);
    property RequestedCount: Integer read FRequestedCount;
    property MaxCapacity: Integer read FMaxCapacity;
  end;

  { 配置错误异常 - 类似 Java IllegalArgumentException }
  ERWLockConfigurationException = class(ERWLockError)
  private
    FConfigParameter: string;
    FConfigValue: string;
  public
    constructor Create(const AConfigParameter, AConfigValue: string);
    property ConfigParameter: string read FConfigParameter;
    property ConfigValue: string read FConfigValue;
  end;

  { 版本不匹配异常 - ABA 问题检测 }
  ERWLockVersionException = class(ERWLockError)
  private
    FExpectedVersion: Integer;
    FActualVersion: Integer;
  public
    constructor Create(AExpectedVersion, AActualVersion: Integer; AThreadId: TThreadID = 0);
    property ExpectedVersion: Integer read FExpectedVersion;
    property ActualVersion: Integer read FActualVersion;
  end;

  { 数据损坏异常 - 内部状态不一致 }
  ERWLockCorruptionException = class(ERWLockError)
  private
    FCorruptionType: string;
    FCorruptionDetails: string;
  public
    constructor Create(const ACorruptionType, ACorruptionDetails: string; AThreadId: TThreadID = 0);
    property CorruptionType: string read FCorruptionType;
    property CorruptionDetails: string read FCorruptionDetails;
  end;

  // 兼容性异常类（保持向后兼容）
  ELockError = class(ERWLockError)
  public
    constructor Create(const AMessage: string);
  end;

  // ===== 前向声明 =====
  IRWLock = interface;

  // ===== 读锁守卫接口 =====
  IRWLockReadGuard = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // RAII 读锁守卫，析构时自动释放读锁
    function IsValid: Boolean;
    procedure Release; // 手动释放（可选）
  end;

  // ===== 写锁守卫接口 =====
  IRWLockWriteGuard = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    // RAII 写锁守卫，析构时自动释放写锁
    function IsValid: Boolean;
    procedure Release; // 手动释放（可选）
  end;

  // ===== RWLock 扩展接口 =====
  IRWLock = interface(IReadWriteLock)
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    // ===== 现代化 API（推荐使用）=====
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // ===== 扩展的传统 API =====
    // 继承自 IReadWriteLock 的基础方法：
    // - AcquireRead, ReleaseRead, AcquireWrite, ReleaseWrite
    // - TryAcquireRead, TryAcquireWrite (Boolean 版本)
    // - GetReaderCount, IsWriteLocked

    // 扩展方法：统一返回 TLockResult
    function TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
    function TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;

    // ===== 扩展状态查询 =====
    // 继承自 IReadWriteLock：GetReaderCount, IsWriteLocked
    function IsReadLocked: Boolean;
    function GetWriterThread: TThreadID;
    function GetMaxReaders: Integer;

    // ===== 性能统计 =====
    function GetContentionCount: Integer;
    function GetSpinCount: Integer;

    // ===== 错误信息 =====
    function GetLastLockResult: TLockResult;

    // ===== 状态验证和恢复 =====
    function ValidateState: Boolean;
    procedure RecoverState;
    function IsHealthy: Boolean;

    // ===== 性能监控接口 =====
    function GetPerformanceStats: TLockPerformanceStats; virtual; abstract;
    procedure ResetPerformanceStats; virtual; abstract;
    function GetContentionRate: Double; virtual; abstract;
    function GetAverageWaitTime: Double; virtual; abstract;
    function GetThroughput: Double; virtual; abstract;
    function GetSpinEfficiency: Double; virtual; abstract;
  end;

// ===== 原子计数器操作函数 =====

{ 原子地读取计数器值 }
function AtomicLoadCounter(var Counter: TAtomicCounter): Integer;

{ 原子地增加计数器 }
function AtomicIncrementCounter(var Counter: TAtomicCounter): Integer;

{ 原子地减少计数器 }
function AtomicDecrementCounter(var Counter: TAtomicCounter): Integer;

{ 原子地设置计数器值 }
procedure AtomicStoreCounter(var Counter: TAtomicCounter; Value: Integer);

{ 原子地比较并交换计数器（CAS 操作）}
function AtomicCompareExchangeCounter(var Counter: TAtomicCounter;
  NewCount: Integer; ExpectedCount: Integer): Boolean;

// ===== 内存屏障操作函数 =====

{ 完整内存屏障 - 确保所有内存操作的顺序 }
procedure MemoryBarrierFull; inline;

{ 读内存屏障 - 确保读操作的顺序 }
procedure MemoryBarrierRead; inline;

{ 写内存屏障 - 确保写操作的顺序 }
procedure MemoryBarrierWrite; inline;

{ 获取屏障 - 防止后续操作重排到屏障之前 }
procedure MemoryBarrierAcquire; inline;

{ 释放屏障 - 防止前面操作重排到屏障之后 }
procedure MemoryBarrierRelease; inline;

implementation

// ===== 原子计数器操作实现 =====

function AtomicLoadCounter(var Counter: TAtomicCounter): Integer;
begin
  // 使用框架的原子操作确保读取的一致性
  Result := atomic_load(Counter.Count, memory_order_acquire);
end;

function AtomicIncrementCounter(var Counter: TAtomicCounter): Integer;
var
  OldCounter, NewCounter: TAtomicCounter;
begin
  repeat
    OldCounter.Count := atomic_load(Counter.Count, memory_order_relaxed);
    OldCounter.Version := atomic_load(Counter.Version, memory_order_relaxed);

    NewCounter.Count := OldCounter.Count + 1;
    NewCounter.Version := OldCounter.Version + 1;

    // 尝试原子地更新整个结构
    if atomic_compare_exchange_strong_64(PInt64(@Counter)^, PInt64(@OldCounter)^, PInt64(@NewCounter)^, memory_order_acq_rel) then
    begin
      Result := NewCounter.Count;
      Exit;
    end;
    // 如果失败，重试
  until False;
end;

function AtomicDecrementCounter(var Counter: TAtomicCounter): Integer;
var
  OldCounter, NewCounter: TAtomicCounter;
begin
  repeat
    OldCounter.Count := atomic_load(Counter.Count, memory_order_relaxed);
    OldCounter.Version := atomic_load(Counter.Version, memory_order_relaxed);

    NewCounter.Count := OldCounter.Count - 1;
    NewCounter.Version := OldCounter.Version + 1;

    // 尝试原子地更新整个结构
    if atomic_compare_exchange_strong_64(PInt64(@Counter)^, PInt64(@OldCounter)^, PInt64(@NewCounter)^, memory_order_acq_rel) then
    begin
      Result := NewCounter.Count;
      Exit;
    end;
    // 如果失败，重试
  until False;
end;

procedure AtomicStoreCounter(var Counter: TAtomicCounter; Value: Integer);
var
  OldCounter, NewCounter: TAtomicCounter;
begin
  repeat
    OldCounter.Count := atomic_load(Counter.Count, memory_order_relaxed);
    OldCounter.Version := atomic_load(Counter.Version, memory_order_relaxed);

    NewCounter.Count := Value;
    NewCounter.Version := OldCounter.Version + 1;

    // 尝试原子地更新整个结构
    if atomic_compare_exchange_strong_64(PInt64(@Counter)^, PInt64(@OldCounter)^, PInt64(@NewCounter)^, memory_order_release) then
      Exit;
    // 如果失败，重试
  until False;
end;

function AtomicCompareExchangeCounter(var Counter: TAtomicCounter;
  NewCount: Integer; ExpectedCount: Integer): Boolean;
var
  OldCounter, NewCounter: TAtomicCounter;
begin
  OldCounter.Count := atomic_load(Counter.Count, memory_order_relaxed);
  OldCounter.Version := atomic_load(Counter.Version, memory_order_relaxed);

  // 只有当前计数值匹配时才进行交换
  if OldCounter.Count <> ExpectedCount then
  begin
    Result := False;
    Exit;
  end;

  NewCounter.Count := NewCount;
  NewCounter.Version := OldCounter.Version + 1;

  // 尝试原子地更新整个结构
  Result := atomic_compare_exchange_strong_64(PInt64(@Counter)^, PInt64(@OldCounter)^, PInt64(@NewCounter)^, memory_order_acq_rel);
end;

// ===== 内存屏障操作实现 =====

procedure MemoryBarrierFull; inline;
begin
  {$IFDEF CPUX86_64}
  asm
    mfence;
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  asm
    dmb sy;
  end;
  {$ELSE}
  // 对于其他架构，使用编译器屏障
  ReadBarrier;
  WriteBarrier;
  {$ENDIF}
end;

procedure MemoryBarrierRead; inline;
begin
  {$IFDEF CPUX86_64}
  asm
    lfence;
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  asm
    dmb ld;
  end;
  {$ELSE}
  ReadBarrier;
  {$ENDIF}
end;

procedure MemoryBarrierWrite; inline;
begin
  {$IFDEF CPUX86_64}
  asm
    sfence;
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  asm
    dmb st;
  end;
  {$ELSE}
  WriteBarrier;
  {$ENDIF}
end;

procedure MemoryBarrierAcquire; inline;
begin
  {$IFDEF CPUX86_64}
  // x86_64 有强内存模型，读操作天然有 acquire 语义
  asm
    // 编译器屏障，防止指令重排
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  asm
    dmb ld;
  end;
  {$ELSE}
  ReadBarrier;
  {$ENDIF}
end;

procedure MemoryBarrierRelease; inline;
begin
  {$IFDEF CPUX86_64}
  // x86_64 有强内存模型，写操作天然有 release 语义
  asm
    // 编译器屏障，防止指令重排
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  asm
    dmb st;
  end;
  {$ELSE}
  WriteBarrier;
  {$ENDIF}
end;

// ===== 异常类实现 =====

{ ERWLockError }

constructor ERWLockError.Create(const AMessage: string; ALockResult: TLockResult);
begin
  inherited Create(AMessage);
  FLockResult := ALockResult;
  FThreadId := GetCurrentThreadId;
  FTimestamp := Now;
end;

constructor ERWLockError.Create(const AMessage: string; ALockResult: TLockResult; AThreadId: TThreadID);
begin
  inherited Create(AMessage);
  FLockResult := ALockResult;
  FThreadId := AThreadId;
  FTimestamp := Now;
end;

{ ERWLockTimeoutError }

constructor ERWLockTimeoutError.Create(ATimeoutMs: Cardinal; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Lock acquisition timed out after %d ms (Thread: %d)', [ATimeoutMs, AThreadId]),
    lrTimeout,
    AThreadId
  );
  FTimeoutMs := ATimeoutMs;
end;

{ ERWLockStateError }

constructor ERWLockStateError.Create(const AExpectedState, AActualState: string; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Invalid lock state: expected "%s", actual "%s" (Thread: %d)',
           [AExpectedState, AActualState, AThreadId]),
    lrError,
    AThreadId
  );
  FExpectedState := AExpectedState;
  FActualState := AActualState;
end;

{ ERWLockDeadlockError }

constructor ERWLockDeadlockError.Create(AOwnerThread: TThreadID; const AWaitingThreads: array of TThreadID);
var
  i: Integer;
  WaitingList: string;
begin
  // 构建等待线程列表字符串
  WaitingList := '';
  for i := 0 to High(AWaitingThreads) do
  begin
    if i > 0 then
      WaitingList := WaitingList + ', ';
    WaitingList := WaitingList + IntToStr(AWaitingThreads[i]);
  end;

  inherited Create(
    Format('Potential deadlock detected: Owner=%d, Waiting=[%s]', [AOwnerThread, WaitingList]),
    lrError,
    GetCurrentThreadId
  );

  FOwnerThread := AOwnerThread;
  SetLength(FWaitingThreads, Length(AWaitingThreads));
  for i := 0 to High(AWaitingThreads) do
    FWaitingThreads[i] := AWaitingThreads[i];
end;

function ERWLockDeadlockError.GetWaitingThreads: TThreadIDArray;
var
  i: Integer;
begin
  SetLength(Result, Length(FWaitingThreads));
  for i := 0 to High(FWaitingThreads) do
    Result[i] := FWaitingThreads[i];
end;

{ ERWLockResourceError }

constructor ERWLockResourceError.Create(ACurrentCount, AMaxCount: Integer; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Resource limit exceeded: current=%d, max=%d (Thread: %d)',
           [ACurrentCount, AMaxCount, AThreadId]),
    lrError,
    AThreadId
  );
  FCurrentCount := ACurrentCount;
  FMaxCount := AMaxCount;
end;

{ ERWLockSystemError }

constructor ERWLockSystemError.Create(ASystemErrorCode: Integer; const ASystemErrorMessage: string; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('System error: %s (Code: %d, Thread: %d)',
           [ASystemErrorMessage, ASystemErrorCode, AThreadId]),
    lrError,
    AThreadId
  );
  FSystemErrorCode := ASystemErrorCode;
  FSystemErrorMessage := ASystemErrorMessage;
end;

// ===== 扩展异常类实现 =====

{ ERWLockInterruptedException }

constructor ERWLockInterruptedException.Create(const AInterruptReason: string; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Operation interrupted: %s (Thread: %d)', [AInterruptReason, AThreadId]),
    lrError,
    AThreadId
  );
  FInterruptReason := AInterruptReason;
end;

{ ERWLockOwnershipException }

constructor ERWLockOwnershipException.Create(AExpectedOwner, AActualOwner: TThreadID);
begin
  inherited Create(
    Format('Lock ownership violation: expected owner %d, actual owner %d',
           [AExpectedOwner, AActualOwner]),
    lrError,
    AActualOwner
  );
  FExpectedOwner := AExpectedOwner;
  FActualOwner := AActualOwner;
end;

{ ERWLockCapacityException }

constructor ERWLockCapacityException.Create(ARequestedCount, AMaxCapacity: Integer; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Capacity exceeded: requested %d, maximum %d (Thread: %d)',
           [ARequestedCount, AMaxCapacity, AThreadId]),
    lrError,
    AThreadId
  );
  FRequestedCount := ARequestedCount;
  FMaxCapacity := AMaxCapacity;
end;

{ ERWLockConfigurationException }

constructor ERWLockConfigurationException.Create(const AConfigParameter, AConfigValue: string);
begin
  inherited Create(
    Format('Invalid configuration: parameter "%s" = "%s"', [AConfigParameter, AConfigValue]),
    lrError,
    GetCurrentThreadId
  );
  FConfigParameter := AConfigParameter;
  FConfigValue := AConfigValue;
end;

{ ERWLockVersionException }

constructor ERWLockVersionException.Create(AExpectedVersion, AActualVersion: Integer; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Version mismatch detected: expected %d, actual %d (Thread: %d)',
           [AExpectedVersion, AActualVersion, AThreadId]),
    lrError,
    AThreadId
  );
  FExpectedVersion := AExpectedVersion;
  FActualVersion := AActualVersion;
end;

{ ERWLockCorruptionException }

constructor ERWLockCorruptionException.Create(const ACorruptionType, ACorruptionDetails: string; AThreadId: TThreadID);
begin
  if AThreadId = 0 then
    AThreadId := GetCurrentThreadId;

  inherited Create(
    Format('Data corruption detected: %s - %s (Thread: %d)',
           [ACorruptionType, ACorruptionDetails, AThreadId]),
    lrError,
    AThreadId
  );
  FCorruptionType := ACorruptionType;
  FCorruptionDetails := ACorruptionDetails;
end;

{ ELockError }

constructor ELockError.Create(const AMessage: string);
begin
  inherited Create(AMessage, lrError, GetCurrentThreadId);
end;

end.
