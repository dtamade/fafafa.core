unit fafafa.core.sync;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  // Facade: only re-export public interfaces and platform implementations
  fafafa.core.base,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.spin,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.once,
  fafafa.core.sync.once.base,
  fafafa.core.sync.condvar,
  fafafa.core.sync.barrier,
  fafafa.core.sync.sem,
  fafafa.core.sync.event,
  fafafa.core.sync.recMutex,
  fafafa.core.sync.waitgroup,  // Phase 1.1: Go-style WaitGroup
  fafafa.core.sync.latch,      // Phase 1.2: CountDownLatch
  fafafa.core.sync.parker,     // Phase 1.3: Rust-style Parker
  fafafa.core.sync.builder,    // Phase 2: Builder pattern for sync primitives
  fafafa.core.sync.oncelock,   // Phase 3.1: Rust-style OnceLock<T>
  // Named synchronization primitives
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.namedEvent,
  fafafa.core.sync.namedSemaphore,
  fafafa.core.sync.namedBarrier,
  fafafa.core.sync.namedCondvar,
  fafafa.core.sync.namedRWLock,
  // Named cross-process primitives (Phase 4)
  fafafa.core.sync.namedOnce,
  fafafa.core.sync.namedLatch,
  fafafa.core.sync.namedWaitGroup,
  fafafa.core.sync.namedSharedCounter;

type
  // Re-export core interfaces and enums for backward compatibility
  TWaitResult        = fafafa.core.sync.base.TWaitResult;
  TWaitError         = fafafa.core.sync.base.TWaitError;
  TLockResult        = fafafa.core.sync.rwlock.TLockResult;
  ISynchronizable    = fafafa.core.sync.base.ISynchronizable;
  ILock              = fafafa.core.sync.base.ILock;
  ILockGuard         = fafafa.core.sync.base.ILockGuard;
  IMutex             = fafafa.core.sync.mutex.IMutex;
  IRecMutex          = fafafa.core.sync.recMutex.IRecMutex;
  ISpin              = fafafa.core.sync.spin.ISpin;
  IOnce              = fafafa.core.sync.once.IOnce;
  IRWLock            = fafafa.core.sync.rwlock.IRWLock;
  IRWLockReadGuard   = fafafa.core.sync.rwlock.IRWLockReadGuard;
  IRWLockWriteGuard  = fafafa.core.sync.rwlock.IRWLockWriteGuard;
  ISem               = fafafa.core.sync.sem.ISem;
  ISemGuard          = fafafa.core.sync.sem.ISemGuard;
  IEvent             = fafafa.core.sync.event.IEvent;
  ICondVar = fafafa.core.sync.condvar.ICondVar;
  IBarrier           = fafafa.core.sync.barrier.IBarrier;
  IWaitGroup         = fafafa.core.sync.waitgroup.IWaitGroup;  // Phase 1.1
  ILatch             = fafafa.core.sync.latch.ILatch;          // Phase 1.2
  IParker            = fafafa.core.sync.parker.IParker;        // Phase 1.3

  // Named synchronization primitives interfaces
  INamedMutex             = fafafa.core.sync.namedMutex.INamedMutex;
  INamedMutexGuard        = fafafa.core.sync.namedMutex.INamedMutexGuard;
  INamedEvent             = fafafa.core.sync.namedEvent.INamedEvent;
  INamedEventGuard        = fafafa.core.sync.namedEvent.INamedEventGuard;
  INamedSemaphore         = fafafa.core.sync.namedSemaphore.INamedSemaphore;
  INamedSemaphoreGuard    = fafafa.core.sync.namedSemaphore.INamedSemaphoreGuard;
  INamedBarrier           = fafafa.core.sync.namedBarrier.INamedBarrier;
  INamedBarrierGuard      = fafafa.core.sync.namedBarrier.INamedBarrierGuard;
  INamedCondVar           = fafafa.core.sync.namedCondvar.INamedCondVar;
  INamedRWLock            = fafafa.core.sync.namedRWLock.INamedRWLock;
  INamedRWLockReadGuard   = fafafa.core.sync.namedRWLock.INamedRWLockReadGuard;
  INamedRWLockWriteGuard  = fafafa.core.sync.namedRWLock.INamedRWLockWriteGuard;

  // Named cross-process primitives (Phase 4)
  INamedOnce              = fafafa.core.sync.namedOnce.INamedOnce;
  TNamedOnceState         = fafafa.core.sync.namedOnce.TNamedOnceState;
  TNamedOnceConfig        = fafafa.core.sync.namedOnce.TNamedOnceConfig;
  INamedLatch             = fafafa.core.sync.namedLatch.INamedLatch;
  TNamedLatchConfig       = fafafa.core.sync.namedLatch.TNamedLatchConfig;
  INamedWaitGroup         = fafafa.core.sync.namedWaitGroup.INamedWaitGroup;
  TNamedWaitGroupConfig   = fafafa.core.sync.namedWaitGroup.TNamedWaitGroupConfig;
  INamedSharedCounter     = fafafa.core.sync.namedSharedCounter.INamedSharedCounter;
  TNamedSharedCounterConfig = fafafa.core.sync.namedSharedCounter.TNamedSharedCounterConfig;

  TLockGuard              = fafafa.core.sync.base.TLockGuard;

  // Builder pattern types (Phase 2)
  TMutexBuilder      = fafafa.core.sync.builder.TMutexBuilder;
  TSemBuilder        = fafafa.core.sync.builder.TSemBuilder;
  TRWLockBuilder     = fafafa.core.sync.builder.TRWLockBuilder;
  TCondVarBuilder    = fafafa.core.sync.builder.TCondVarBuilder;
  TBarrierBuilder    = fafafa.core.sync.builder.TBarrierBuilder;
  TOnceBuilder       = fafafa.core.sync.builder.TOnceBuilder;
  TEventBuilder      = fafafa.core.sync.builder.TEventBuilder;
  TWaitGroupBuilder  = fafafa.core.sync.builder.TWaitGroupBuilder;
  TLatchBuilder      = fafafa.core.sync.builder.TLatchBuilder;
  TSpinBuilder       = fafafa.core.sync.builder.TSpinBuilder;       // Phase 2.1
  TParkerBuilder     = fafafa.core.sync.builder.TParkerBuilder;     // Phase 2.1
  TRecMutexBuilder   = fafafa.core.sync.builder.TRecMutexBuilder;   // Phase 2.1

  TMutex             = fafafa.core.sync.mutex.TMutex;
  TRecMutex          = fafafa.core.sync.recMutex.TRecMutex;
  TOnce              = fafafa.core.sync.once.TOnce;
  TRWLock            = fafafa.core.sync.rwlock.TRWLock;
  TEvent             = fafafa.core.sync.event.TEvent;
  TCondVar = fafafa.core.sync.condvar.TCondVar;

  // Backward-compatible aliases (legacy names)
  // 这些别名为向后兼容保留，推荐使用新名称
  IReadWriteLock     = IRWLock     deprecated 'Use IRWLock instead';
  ISemaphore         = ISem        deprecated 'Use ISem instead';


  // Re-export Once callback types
  TOnceProc = fafafa.core.sync.once.base.TOnceProc;
  TOnceMethod = fafafa.core.sync.once.base.TOnceMethod;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TOnceAnonymousProc = fafafa.core.sync.once.base.TOnceAnonymousProc;
{$ENDIF}

  // OnceLock exceptions (Phase 3.1)
  EOnceLockError      = fafafa.core.sync.oncelock.EOnceLockError;
  EOnceLockEmpty      = fafafa.core.sync.oncelock.EOnceLockEmpty;
  EOnceLockAlreadySet = fafafa.core.sync.oncelock.EOnceLockAlreadySet;

  // Re-export exceptions
  ESyncError          = fafafa.core.sync.base.ESyncError;
  ELockError          = fafafa.core.sync.base.ELockError;
  ESyncTimeoutError   = fafafa.core.sync.base.ESyncTimeoutError;  // ✅ SYNC-002: 重命名避免与 base 模块冲突
  EDeadlockError      = fafafa.core.sync.base.EDeadlockError;
  // Back-compat exception alias
  EArgumentOutOfRange = fafafa.core.base.EOutOfRange;

const

  wrSignaled    = fafafa.core.sync.base.wrSignaled;
  wrTimeout     = fafafa.core.sync.base.wrTimeout;
  wrAbandoned   = fafafa.core.sync.base.wrAbandoned;
  wrError       = fafafa.core.sync.base.wrError;
  wrInterrupted = fafafa.core.sync.base.wrInterrupted;

  // TWaitError constants
  weNone              = fafafa.core.sync.base.weNone;
  weInvalidHandle     = fafafa.core.sync.base.weInvalidHandle;
  weResourceExhausted = fafafa.core.sync.base.weResourceExhausted;
  weAccessDenied      = fafafa.core.sync.base.weAccessDenied;
  weDeadlock          = fafafa.core.sync.base.weDeadlock;
  weSystemError       = fafafa.core.sync.base.weSystemError;

function MakeMutex: IMutex; inline;
function MakeSpin: ISpin; inline;
function MakeRWLock: IRWLock; inline;
function MakeCondVar: ICondVar; inline;
function MakeBarrier(AParticipantCount: Integer): IBarrier; inline;
function MakeSem(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISem; inline;
function MakeEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent; inline;
function MakeWaitGroup: IWaitGroup; inline;  // Phase 1.1: Go-style WaitGroup
function MakeLatch(ACount: Integer): ILatch; inline;  // Phase 1.2: CountDownLatch
function MakeParker: IParker; inline;                  // Phase 1.3: Rust-style Parker

// Builder pattern factory functions (Phase 2)
function MutexBuilder: TMutexBuilder; inline;
function SemBuilder: TSemBuilder; inline;
function RWLockBuilder: TRWLockBuilder; inline;
function CondVarBuilder: TCondVarBuilder; inline;
function BarrierBuilder: TBarrierBuilder; inline;
function OnceBuilder: TOnceBuilder; inline;
function EventBuilder: TEventBuilder; inline;
function WaitGroupBuilder: TWaitGroupBuilder; inline;
function LatchBuilder: TLatchBuilder; inline;
function SpinBuilder: TSpinBuilder; inline;           // Phase 2.1
function ParkerBuilder: TParkerBuilder; inline;       // Phase 2.1
function RecMutexBuilder: TRecMutexBuilder; inline;   // Phase 2.1

function MakeRecMutex: IRecMutex; overload; inline;
{$IFDEF WINDOWS}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex; overload; inline;
{$ENDIF}

// Once factory functions
function MakeOnce: IOnce; overload; inline;
function MakeOnce(const AProc: TOnceProc): IOnce; overload; inline;
function MakeOnce(const AMethod: TOnceMethod): IOnce; overload; inline;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce; overload; inline;
{$ENDIF}

// Guard 工厂函数
function MakeLockGuard(ALock: ILock): ILockGuard;
function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard; inline;

// 便捷范式：WithLock/TryWithLock
type
  TLockProc = reference to procedure;

{**
 * WithLock - 在持有锁的情况下执行过程
 *
 * @param ALock 要获取的锁
 * @param AProc 要执行的过程
 *
 * @desc
 *   阻塞获取锁，执行过程，然后自动释放锁。
 *   即使过程抛出异常，锁也会被释放。
 *
 * @usage
 *   WithLock(Mutex, procedure
 *   begin
 *     // 临界区代码
 *   end);
 *}
procedure WithLock(const ALock: ILock; const AProc: TLockProc);

{**
 * TryWithLock - 尝试在持有锁的情况下执行过程
 *
 * @param ALock 要获取的锁（必须支持 ITryLock）
 * @param AProc 要执行的过程
 * @return True 如果成功获取锁并执行过程，False 如果无法立即获取锁
 *
 * @desc
 *   非阻塞尝试获取锁。如果成功，执行过程并释放锁。
 *   如果无法立即获取锁，立即返回 False，不执行过程。
 *
 * @usage
 *   if TryWithLock(Mutex, procedure
 *   begin
 *     // 临界区代码
 *   end) then
 *     // 成功执行
 *   else
 *     // 锁不可用
 *}
function TryWithLock(const ALock: ITryLock; const AProc: TLockProc): Boolean;

{**
 * WithReadLock - 在持有读锁的情况下执行过程
 *
 * @param ARWLock 读写锁
 * @param AProc 要执行的过程
 *
 * @desc
 *   阻塞获取读锁，执行过程，然后自动释放读锁。
 *   即使过程抛出异常，锁也会被释放。
 *   适合只读访问共享数据的场景。
 *
 * @usage
 *   WithReadLock(RWLock, procedure
 *   begin
 *     // 只读访问共享数据
 *   end);
 *}
procedure WithReadLock(const ARWLock: IRWLock; const AProc: TLockProc);

{**
 * WithWriteLock - 在持有写锁的情况下执行过程
 *
 * @param ARWLock 读写锁
 * @param AProc 要执行的过程
 *
 * @desc
 *   阻塞获取写锁，执行过程，然后自动释放写锁。
 *   即使过程抛出异常，锁也会被释放。
 *   适合需要修改共享数据的场景。
 *
 * @usage
 *   WithWriteLock(RWLock, procedure
 *   begin
 *     // 修改共享数据
 *   end);
 *}
procedure WithWriteLock(const ARWLock: IRWLock; const AProc: TLockProc);

{**
 * TryWithReadLock - 尝试在持有读锁的情况下执行过程
 *
 * @param ARWLock 读写锁
 * @param AProc 要执行的过程
 * @param ATimeoutMs 超时时间（毫秒），默认 0 表示不等待
 * @return True 如果成功获取锁并执行过程，False 如果无法获取锁
 *
 * @usage
 *   if TryWithReadLock(RWLock, procedure
 *   begin
 *     // 只读访问
 *   end) then
 *     // 成功
 *}
function TryWithReadLock(const ARWLock: IRWLock; const AProc: TLockProc;
  ATimeoutMs: Cardinal = 0): Boolean;

{**
 * TryWithWriteLock - 尝试在持有写锁的情况下执行过程
 *
 * @param ARWLock 读写锁
 * @param AProc 要执行的过程
 * @param ATimeoutMs 超时时间（毫秒），默认 0 表示不等待
 * @return True 如果成功获取锁并执行过程，False 如果无法获取锁
 *
 * @usage
 *   if TryWithWriteLock(RWLock, procedure
 *   begin
 *     // 修改数据
 *   end) then
 *     // 成功
 *}
function TryWithWriteLock(const ARWLock: IRWLock; const AProc: TLockProc;
  ATimeoutMs: Cardinal = 0): Boolean;

// Named synchronization primitives factory functions
function MakeNamedMutex(const AName: string): INamedMutex; overload;
function MakeNamedMutex(const AName: string; ATimeoutMs: Cardinal): INamedMutex; overload;
function MakeNamedMutex(const AName: string; const AConfig: TNamedMutexConfig): INamedMutex; overload;
function MakeGlobalNamedMutex(const AName: string): INamedMutex;
function MakeNamedSemaphore(const AName: string): INamedSemaphore; overload;
function MakeNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore; overload;
function MakeGlobalNamedSemaphore(const AName: string): INamedSemaphore; overload;
function MakeGlobalNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore; overload;
function MakeNamedBarrier(const AName: string; AParticipantCount: Integer): INamedBarrier;
function MakeNamedCondVar(const AName: string): INamedCondVar;
function MakeNamedRWLock(const AName: string): INamedRWLock;

// Named cross-process primitives factory functions (Phase 4)
function MakeNamedOnce(const AName: string): INamedOnce; overload;
function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce; overload;
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch; overload;
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal; const AConfig: TNamedLatchConfig): INamedLatch; overload;
function MakeNamedWaitGroup(const AName: string): INamedWaitGroup; overload;
function MakeNamedWaitGroup(const AName: string; const AConfig: TNamedWaitGroupConfig): INamedWaitGroup; overload;
function MakeNamedSharedCounter(const AName: string): INamedSharedCounter; overload;
function MakeNamedSharedCounter(const AName: string; const AConfig: TNamedSharedCounterConfig): INamedSharedCounter; overload;

implementation

uses
  fafafa.core.sync.rwlock.base;

function MakeMutex: IMutex;
begin
  Result := fafafa.core.sync.mutex.MakeMutex;
end;

function MakeSpin: ISpin;
begin
  Result := fafafa.core.sync.spin.MakeSpin;
end;

function MakeRWLock: IRWLock;
begin
  Result := fafafa.core.sync.rwlock.MakeRWLock;
end;



function MakeCondVar: ICondVar;
begin
  Result := fafafa.core.sync.condvar.MakeCondVar;
end;

function MakeBarrier(AParticipantCount: Integer): IBarrier;
begin
  Result := fafafa.core.sync.barrier.MakeBarrier(AParticipantCount);
end;

function MakeSem(AInitialCount: Integer; AMaxCount: Integer): ISem;
begin
  Result := fafafa.core.sync.sem.MakeSem(AInitialCount, AMaxCount);
end;

function MakeEvent(AManualReset: Boolean; AInitialState: Boolean): IEvent;
begin
  Result := fafafa.core.sync.event.MakeEvent(AManualReset, AInitialState);
end;

function MakeWaitGroup: IWaitGroup;
begin
  Result := fafafa.core.sync.waitgroup.MakeWaitGroup;
end;

function MakeLatch(ACount: Integer): ILatch;
begin
  Result := fafafa.core.sync.latch.MakeLatch(ACount);
end;

function MakeParker: IParker;
begin
  Result := fafafa.core.sync.parker.MakeParker;
end;

// Builder pattern implementations
function MutexBuilder: TMutexBuilder;
begin
  Result := fafafa.core.sync.builder.MutexBuilder;
end;

function SemBuilder: TSemBuilder;
begin
  Result := fafafa.core.sync.builder.SemBuilder;
end;

function RWLockBuilder: TRWLockBuilder;
begin
  Result := fafafa.core.sync.builder.RWLockBuilder;
end;

function CondVarBuilder: TCondVarBuilder;
begin
  Result := fafafa.core.sync.builder.CondVarBuilder;
end;

function BarrierBuilder: TBarrierBuilder;
begin
  Result := fafafa.core.sync.builder.BarrierBuilder;
end;

function OnceBuilder: TOnceBuilder;
begin
  Result := fafafa.core.sync.builder.OnceBuilder;
end;

function EventBuilder: TEventBuilder;
begin
  Result := fafafa.core.sync.builder.EventBuilder;
end;

function WaitGroupBuilder: TWaitGroupBuilder;
begin
  Result := fafafa.core.sync.builder.WaitGroupBuilder;
end;

function LatchBuilder: TLatchBuilder;
begin
  Result := fafafa.core.sync.builder.LatchBuilder;
end;

function SpinBuilder: TSpinBuilder;
begin
  Result := fafafa.core.sync.builder.SpinBuilder;
end;

function ParkerBuilder: TParkerBuilder;
begin
  Result := fafafa.core.sync.builder.ParkerBuilder;
end;

function RecMutexBuilder: TRecMutexBuilder;
begin
  Result := fafafa.core.sync.builder.RecMutexBuilder;
end;

function MakeRecMutex: IRecMutex;
begin
  Result := fafafa.core.sync.recMutex.MakeRecMutex;
end;

{$IFDEF WINDOWS}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex;
begin
  Result := fafafa.core.sync.recMutex.MakeRecMutex(ASpinCount);
end;
{$ENDIF}

function MakeOnce: IOnce;
begin
  Result := fafafa.core.sync.once.MakeOnce;
end;

function MakeOnce(const AProc: TOnceProc): IOnce;
begin
  Result := fafafa.core.sync.once.MakeOnce(AProc);
end;

function MakeOnce(const AMethod: TOnceMethod): IOnce;
begin
  Result := fafafa.core.sync.once.MakeOnce(AMethod);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce;
begin
  Result := fafafa.core.sync.once.MakeOnce(AAnonymousProc);
end;
{$ENDIF}

function MakeLockGuard(ALock: ILock): ILockGuard;
begin
  Result := fafafa.core.sync.base.MakeLockGuard(ALock);
end;

function MakeLockGuardFromAcquired(ALock: ILock): ILockGuard;
begin
  Result := fafafa.core.sync.base.MakeLockGuardFromAcquired(ALock);
end;

procedure WithLock(const ALock: ILock; const AProc: TLockProc);
{$PUSH}{$WARN 5027 OFF}  // Guard is used for RAII, not its value
var
  Guard: ILockGuard;
begin
  Guard := ALock.Lock;
  try
    AProc();
  finally
    Guard := nil;  // 触发释放
  end;
end;
{$POP}

function TryWithLock(const ALock: ITryLock; const AProc: TLockProc): Boolean;
var
  Guard: ILockGuard;
begin
  Guard := ALock.TryLock;
  if Assigned(Guard) then
  begin
    try
      AProc();
      Result := True;
    finally
      Guard := nil;
    end;
  end
  else
    Result := False;
end;

procedure WithReadLock(const ARWLock: IRWLock; const AProc: TLockProc);
{$PUSH}{$WARN 5027 OFF}  // Guard is used for RAII, not its value
var
  Guard: IRWLockReadGuard;
begin
  Guard := ARWLock.Read;
  try
    AProc();
  finally
    Guard := nil;  // 触发释放
  end;
end;
{$POP}

procedure WithWriteLock(const ARWLock: IRWLock; const AProc: TLockProc);
{$PUSH}{$WARN 5027 OFF}  // Guard is used for RAII, not its value
var
  Guard: IRWLockWriteGuard;
begin
  Guard := ARWLock.Write;
  try
    AProc();
  finally
    Guard := nil;  // 触发释放
  end;
end;
{$POP}

function TryWithReadLock(const ARWLock: IRWLock; const AProc: TLockProc;
  ATimeoutMs: Cardinal): Boolean;
var
  Guard: IRWLockReadGuard;
begin
  Guard := ARWLock.TryRead(ATimeoutMs);
  if Assigned(Guard) and Guard.IsLocked then
  begin
    try
      AProc();
      Result := True;
    finally
      Guard := nil;
    end;
  end
  else
  begin
    // 如果启用了毒化语义且锁已被标记为 Poisoned，则显式抛出异常
    if ARWLock.IsPoisoned then
      raise ERWLockPoisonError.Create(0, 'Lock is poisoned');
    Result := False;
  end;
end;

function TryWithWriteLock(const ARWLock: IRWLock; const AProc: TLockProc;
  ATimeoutMs: Cardinal): Boolean;
var
  Guard: IRWLockWriteGuard;
begin
  Guard := ARWLock.TryWrite(ATimeoutMs);
  if Assigned(Guard) and Guard.IsLocked then
  begin
    try
      AProc();
      Result := True;
    finally
      Guard := nil;
    end;
  end
  else
  begin
    if ARWLock.IsPoisoned then
      raise ERWLockPoisonError.Create(0, 'Lock is poisoned');
    Result := False;
  end;
end;

// Named synchronization primitives implementations
// === 统一命名 API (推荐使用) ===

function MakeNamedMutex(const AName: string): INamedMutex;
begin
  Result := fafafa.core.sync.namedMutex.CreateNamedMutex(AName);
end;

function MakeNamedMutex(const AName: string; ATimeoutMs: Cardinal): INamedMutex;
begin
  Result := fafafa.core.sync.namedMutex.CreateNamedMutex(AName, ATimeoutMs);
end;

function MakeNamedMutex(const AName: string; const AConfig: TNamedMutexConfig): INamedMutex;
begin
  Result := fafafa.core.sync.namedMutex.CreateNamedMutex(AName, AConfig);
end;

function MakeGlobalNamedMutex(const AName: string): INamedMutex;
begin
  Result := fafafa.core.sync.namedMutex.CreateGlobalNamedMutex(AName);
end;

function MakeNamedEvent(const AName: string): INamedEvent;
begin
  Result := fafafa.core.sync.namedEvent.CreateNamedEvent(AName);
end;

function MakeNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent;
begin
  Result := fafafa.core.sync.namedEvent.CreateNamedEvent(AName, AManualReset, AInitialState);
end;

function MakeNamedSemaphore(const AName: string): INamedSemaphore;
begin
  Result := fafafa.core.sync.namedSemaphore.CreateNamedSemaphore(AName);
end;

function MakeNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore;
begin
  Result := fafafa.core.sync.namedSemaphore.CreateNamedSemaphore(AName, AInitialCount, AMaxCount);
end;

function MakeGlobalNamedSemaphore(const AName: string): INamedSemaphore;
begin
  Result := fafafa.core.sync.namedSemaphore.CreateGlobalNamedSemaphore(AName);
end;

function MakeGlobalNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore;
begin
  Result := fafafa.core.sync.namedSemaphore.CreateGlobalNamedSemaphore(AName, AInitialCount, AMaxCount);
end;

function MakeNamedBarrier(const AName: string; AParticipantCount: Integer): INamedBarrier;
begin
  Result := fafafa.core.sync.namedBarrier.MakeNamedBarrier(AName, AParticipantCount);
end;

function MakeNamedCondVar(const AName: string): INamedCondVar;
begin
  Result := fafafa.core.sync.namedCondvar.MakeNamedCondVar(AName);
end;

function MakeNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := fafafa.core.sync.namedRWLock.MakeNamedRWLock(AName);
end;

// Named cross-process primitives implementations (Phase 4)
function MakeNamedOnce(const AName: string): INamedOnce;
begin
  Result := fafafa.core.sync.namedOnce.MakeNamedOnce(AName);
end;

function MakeNamedOnce(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;
begin
  Result := fafafa.core.sync.namedOnce.MakeNamedOnce(AName, AConfig);
end;

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
begin
  Result := fafafa.core.sync.namedLatch.MakeNamedLatch(AName, AInitialCount);
end;

function MakeNamedLatch(const AName: string; AInitialCount: Cardinal; const AConfig: TNamedLatchConfig): INamedLatch;
begin
  Result := fafafa.core.sync.namedLatch.MakeNamedLatch(AName, AInitialCount, AConfig);
end;

function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
begin
  Result := fafafa.core.sync.namedWaitGroup.MakeNamedWaitGroup(AName);
end;

function MakeNamedWaitGroup(const AName: string; const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;
begin
  Result := fafafa.core.sync.namedWaitGroup.MakeNamedWaitGroup(AName, AConfig);
end;

function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
begin
  Result := fafafa.core.sync.namedSharedCounter.MakeNamedSharedCounter(AName);
end;

function MakeNamedSharedCounter(const AName: string; const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;
begin
  Result := fafafa.core.sync.namedSharedCounter.MakeNamedSharedCounter(AName, AConfig);
end;

end.
