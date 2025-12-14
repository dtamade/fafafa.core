unit fafafa.core.sync.rwlock.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.atomic;

type
  // ===== 类型定义 =====
  TThreadIDArray = array of TThreadID;

  // ===== 版本化原子计数器（防止 ABA 问题）=====
  // 使用 64 位打包：高 32 位 = Version，低 32 位 = Count
  // 这样在 32/64 位平台都能使用 Int64 原子 CAS
  TAtomicCounter = Int64;

  PAtomicCounter = ^TAtomicCounter;

  // ===== 性能监控数据结构 =====
  TLockPerformanceStats = record
    // 基础计数�?
    TotalAcquireAttempts: Int64;      // 总获取尝试次�?
    SuccessfulAcquires: Int64;        // 成功获取次数
    FailedAcquires: Int64;            // 失败获取次数
    TotalReleases: Int64;             // 总释放次�?

    // 读写分离统计
    ReadAcquireAttempts: Int64;       // 读锁获取尝试
    WriteAcquireAttempts: Int64;      // 写锁获取尝试
    ReadSuccesses: Int64;             // 读锁成功次数
    WriteSuccesses: Int64;            // 写锁成功次数

    // 时间统计（微秒）
    TotalWaitTime: Int64;             // 总等待时�?
    MaxWaitTime: Int64;               // 最大等待时�?
    MinWaitTime: Int64;               // 最小等待时�?

    // 自旋统计
    TotalSpinCount: Int64;            // 总自旋次�?
    SpinSuccesses: Int64;             // 自旋成功次数

    // 竞争统计
    ContentionEvents: Int64;          // 竞争事件次数
    DeadlockDetections: Int64;        // 死锁检测次�?

    // 时间�?
    StartTime: QWord;                 // 统计开始时�?
    LastResetTime: QWord;             // 上次重置时间
  end;

  // ===== 锁配置选项 =====
  TRWLockOptions = record
    AllowReentrancy: Boolean;   // 是否允许可重入（默认 True）
    FairMode: Boolean;          // 公平模式：FIFO 调度（默认 False）
    WriterPriority: Boolean;    // 写者优先模式（默认 False）
    MaxReaders: Integer;        // 最大读者数量（默认 1024）
    SpinCount: Integer;         // 初始自旋次数（默认 4000）
    EnablePoisoning: Boolean;   // 是否启用毒化检测（默认 True，类似 Rust）
    ReaderBiasEnabled: Boolean; // 读偏向优化（默认 True，适合读多写少场景）
  end;

  // ===== 锁操作结果枚�?=====
  TLockResult = (
    lrSuccess,      // 成功获取�?
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
  // 以下异常已标记为 deprecated，建议使用核心异常：ERWLockError, ERWLockTimeoutError, ERWLockPoisonError, ERWLockSystemError

  { 锁毒化异常 - 类似 Rust PoisonError }
  ERWLockPoisonError = class(ERWLockError)
  private
    FPoisoningThreadId: TThreadID;
    FPoisoningException: string;
  public
    constructor Create(APoisoningThreadId: TThreadID; const APoisoningException: string);
    property PoisoningThreadId: TThreadID read FPoisoningThreadId;
    property PoisoningException: string read FPoisoningException;
  end;

  // 兼容性异常类（保持向后兼容）
  ELockError = class(ERWLockError)
  public
    constructor Create(const AMessage: string);
  end;

  // ===== 前向声明 =====
  IRWLock = interface;

  // ===== 读锁守卫接口 =====
  IRWLockReadGuard = interface(IGuard)
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // RAII 读锁守卫，析构时自动释放读锁
    // 继承 IGuard 的 IsLocked 和 Release
  end;

  // ===== 写锁守卫接口 =====
  IRWLockWriteGuard = interface(IGuard)
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    // RAII 写锁守卫，析构时自动释放写锁
    // 继承 IGuard 的 IsLocked 和 Release

    {**
     * Downgrade - 写锁降级为读锁
     *
     * @return 新的读锁守卫
     *
     * @desc
     *   原子地将写锁降级为读锁。降级后原来的写锁守卫失效，
     *   返回一个新的读锁守卫。降级过程中不会完全释放锁，
     *   因此其他写者无法在此期间获取写锁。
     *
     * @postcondition
     *   - 原写锁守卫失效 (IsValid = False)
     *   - 返回的读锁守卫有效
     *   - 锁从写模式转换为读模式
     *
     * @thread_safety
     *   线程安全，原子操作。
     *}
    function Downgrade: IRWLockReadGuard;
  end;


  // ===== 传统的读写锁基础接口（为兼容而保留）=====
  IReadWriteLock = interface
    ['{9E8D7C6B-5A4F-3E2D-1C0B-A9F8E7D6C5B4}']
    // 阻塞式获�?释放
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    // 非阻�?带超时尝�?
    function TryAcquireRead(ATimeoutMs: Cardinal = 0): Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal = 0): Boolean; overload;
    // 状态查�?
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
  end;

  // ===== RWLock 扩展接口 =====
  IRWLock = interface(IReadWriteLock)
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    // ===== 现代�?API（推荐使用）=====
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // ===== 扩展的传�?API =====
    // 继承�?IReadWriteLock 的基础方法�?
    // - AcquireRead, ReleaseRead, AcquireWrite, ReleaseWrite
    // - TryAcquireRead, TryAcquireWrite (Boolean 版本)
    // - GetReaderCount, IsWriteLocked

    // 扩展方法：统一返回 TLockResult
    function TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
    function TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;

    // ===== 扩展状态查�?=====
    // 继承�?IReadWriteLock：GetReaderCount, IsWriteLocked
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

    // ===== 毒化支持 (Rust-style Poisoning) =====
    function IsPoisoned: Boolean;
    procedure ClearPoison;
  end;

  { IRWLockDiagnostics - 性能诊断接口（从 IRWLock 分离）
    
    此接口包含用于调试和性能分析的方法，与核心锁功能分离。
    生产代码通常不需要此接口，仅在需要性能监控时使用。
    
    获取方式：
      var Diagnostics: IRWLockDiagnostics;
      if Supports(MyRWLock, IRWLockDiagnostics, Diagnostics) then
        WriteLn('Contention rate: ', Diagnostics.GetContentionRate:0:2);
    
    @experimental 此接口可能在未来版本中更改
  }
  IRWLockDiagnostics = interface
    ['{E7F8A9B0-C1D2-E3F4-A5B6-789012345678}']
    { 获取详细性能统计信息 }
    function GetPerformanceStats: TLockPerformanceStats;
    { 重置性能统计计数器 }
    procedure ResetPerformanceStats;
    { 获取竞争率（竞争次数/总获取次数）}
    function GetContentionRate: Double;
    { 获取平均等待时间（毫秒）}
    function GetAverageWaitTime: Double;
    { 获取吞吐量（每秒获取/释放次数）}
    function GetThroughput: Double;
    { 获取自旋效率（自旋成功次数/总自旋次数）}
    function GetSpinEfficiency: Double;
  end;

// ===== 原子计数器辅助函数 =====

{ 打包 Count 和 Version 为 TAtomicCounter }
function PackCounter(Count, Version: Integer): TAtomicCounter; inline;

{ 从 TAtomicCounter 解包 Count }
function UnpackCount(Counter: TAtomicCounter): Integer; inline;

{ 从 TAtomicCounter 解包 Version }
function UnpackVersion(Counter: TAtomicCounter): Integer; inline;

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

{ 读内存屏�?- 确保读操作的顺序 }
procedure MemoryBarrierRead; inline;

{ 写内存屏�?- 确保写操作的顺序 }
procedure MemoryBarrierWrite; inline;

{ 获取屏障 - 防止后续操作重排到屏障之�?}
procedure MemoryBarrierAcquire; inline;

{ 释放屏障 - 防止前面操作重排到屏障之�?}
procedure MemoryBarrierRelease; inline;

implementation

// ===== 原子计数器辅助函数实现 =====

function PackCounter(Count, Version: Integer): TAtomicCounter; inline;
begin
  // 高 32 位 = Version，低 32 位 = Count
  Result := (Int64(Cardinal(Version)) shl 32) or Int64(Cardinal(Count));
end;

function UnpackCount(Counter: TAtomicCounter): Integer; inline;
begin
  Result := Integer(Counter and $FFFFFFFF);
end;

function UnpackVersion(Counter: TAtomicCounter): Integer; inline;
begin
  Result := Integer(Counter shr 32);
end;

// ===== 原子计数器操作实现 =====

function AtomicLoadCounter(var Counter: TAtomicCounter): Integer;
var
  Value: Int64;
begin
  // 原子读取整个 64 位值，然后解包 Count
  Value := atomic_load(Counter, mo_acquire);
  Result := UnpackCount(Value);
end;

function AtomicIncrementCounter(var Counter: TAtomicCounter): Integer;
var
  OldValue, NewValue: Int64;
  OldCount, OldVersion: Integer;
begin
  repeat
    OldValue := atomic_load(Counter, mo_relaxed);
    OldCount := UnpackCount(OldValue);
    OldVersion := UnpackVersion(OldValue);

    NewValue := PackCounter(OldCount + 1, OldVersion + 1);

    // 使用 Int64 CAS，32/64 位平台统一
    if atomic_compare_exchange_strong(Counter, OldValue, NewValue) then
    begin
      Result := OldCount + 1;
      Exit;
    end;
  until False;
end;

function AtomicDecrementCounter(var Counter: TAtomicCounter): Integer;
var
  OldValue, NewValue: Int64;
  OldCount, OldVersion: Integer;
begin
  repeat
    OldValue := atomic_load(Counter, mo_relaxed);
    OldCount := UnpackCount(OldValue);
    OldVersion := UnpackVersion(OldValue);

    NewValue := PackCounter(OldCount - 1, OldVersion + 1);

    // 使用 Int64 CAS，32/64 位平台统一
    if atomic_compare_exchange_strong(Counter, OldValue, NewValue) then
    begin
      Result := OldCount - 1;
      Exit;
    end;
  until False;
end;

procedure AtomicStoreCounter(var Counter: TAtomicCounter; Value: Integer);
var
  OldValue, NewValue: Int64;
  OldVersion: Integer;
begin
  repeat
    OldValue := atomic_load(Counter, mo_relaxed);
    OldVersion := UnpackVersion(OldValue);

    NewValue := PackCounter(Value, OldVersion + 1);

    // 使用 Int64 CAS，32/64 位平台统一
    if atomic_compare_exchange_strong(Counter, OldValue, NewValue) then
      Exit;
  until False;
end;

function AtomicCompareExchangeCounter(var Counter: TAtomicCounter;
  NewCount: Integer; ExpectedCount: Integer): Boolean;
var
  OldValue, NewValue: Int64;
  OldCount, OldVersion: Integer;
begin
  OldValue := atomic_load(Counter, mo_relaxed);
  OldCount := UnpackCount(OldValue);
  OldVersion := UnpackVersion(OldValue);

  // 只有当前计数值匹配时才进行交换
  if OldCount <> ExpectedCount then
  begin
    Result := False;
    Exit;
  end;

  NewValue := PackCounter(NewCount, OldVersion + 1);

  // 使用 Int64 CAS，32/64 位平台统一
  Result := atomic_compare_exchange_strong(Counter, OldValue, NewValue);
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
  // x86_64 有强内存模型，读操作天然�?acquire 语义
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
  // x86_64 有强内存模型，写操作天然�?release 语义
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

// ===== 异常类实�?=====

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

{ ERWLockPoisonError }
{ ERWLockPoisonError }

constructor ERWLockPoisonError.Create(APoisoningThreadId: TThreadID; const APoisoningException: string);
begin
  inherited Create(
    Format('Lock is poisoned: thread %d panicked with "%s"',
           [APoisoningThreadId, APoisoningException]),
    lrError,
    GetCurrentThreadId
  );
  FPoisoningThreadId := APoisoningThreadId;
  FPoisoningException := APoisoningException;
end;

{ ELockError }

constructor ELockError.Create(const AMessage: string);
begin
  inherited Create(AMessage, lrError, GetCurrentThreadId);
end;

end.
