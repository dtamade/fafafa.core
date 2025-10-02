unit fafafa.core.sync;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  // Facade: only re-export public interfaces and platform implementations
  fafafa.core.base,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.once,
  fafafa.core.sync.once.base,
  fafafa.core.sync.condvar,
  fafafa.core.sync.barrier,
  fafafa.core.sync.sem,
  fafafa.core.sync.event,
  // fafafa.core.sync.recMutex, // Temporarily disabled due to compilation issues
  // Named synchronization primitives
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.namedEvent,
  fafafa.core.sync.namedSemaphore,
  fafafa.core.sync.namedBarrier,
  // fafafa.core.sync.namedCondvar, // Temporarily disabled due to implementation issues
  fafafa.core.sync.namedRWLock;

type
  // Re-export core interfaces and enums for backward compatibility
  TWaitResult        = fafafa.core.sync.base.TWaitResult;
  TWaitError         = fafafa.core.sync.base.TWaitError;
  TLockResult        = fafafa.core.sync.rwlock.TLockResult;
  ISynchronizable    = fafafa.core.sync.base.ISynchronizable;
  ILock              = fafafa.core.sync.base.ILock;
  ILockGuard         = fafafa.core.sync.base.ILockGuard;
  IMutex             = fafafa.core.sync.mutex.IMutex;
  // IRecMutex          = fafafa.core.sync.recMutex.IRecMutex; // Temporarily disabled
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

  // Named synchronization primitives interfaces
  INamedMutex             = fafafa.core.sync.namedMutex.INamedMutex;
  INamedMutexGuard        = fafafa.core.sync.namedMutex.INamedMutexGuard;
  INamedEvent             = fafafa.core.sync.namedEvent.INamedEvent;
  INamedEventGuard        = fafafa.core.sync.namedEvent.INamedEventGuard;
  INamedSemaphore         = fafafa.core.sync.namedSemaphore.INamedSemaphore;
  INamedSemaphoreGuard    = fafafa.core.sync.namedSemaphore.INamedSemaphoreGuard;
  INamedBarrier           = fafafa.core.sync.namedBarrier.INamedBarrier;
  INamedBarrierGuard      = fafafa.core.sync.namedBarrier.INamedBarrierGuard;
  // INamedCondVar = fafafa.core.sync.namedCondvar.INamedCondVar; // Temporarily disabled
  INamedRWLock            = fafafa.core.sync.namedRWLock.INamedRWLock;
  INamedRWLockReadGuard   = fafafa.core.sync.namedRWLock.INamedRWLockReadGuard;
  INamedRWLockWriteGuard  = fafafa.core.sync.namedRWLock.INamedRWLockWriteGuard;

  TLockGuard              = fafafa.core.sync.base.TLockGuard;

  TMutex             = fafafa.core.sync.mutex.TMutex;
  // TRecMutex          = fafafa.core.sync.recMutex.TRecMutex; // Temporarily disabled
  TOnce              = fafafa.core.sync.once.TOnce;
  TRWLock            = fafafa.core.sync.rwlock.TRWLock;
  TEvent             = fafafa.core.sync.event.TEvent;
  TCondVar = fafafa.core.sync.condvar.TCondVar;

  // Backward-compatible aliases (legacy names)
  IReadWriteLock     = IRWLock;
  ISemaphore         = ISem;


  // Re-export Once callback types
  TOnceProc = fafafa.core.sync.once.base.TOnceProc;
  TOnceMethod = fafafa.core.sync.once.base.TOnceMethod;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TOnceAnonymousProc = fafafa.core.sync.once.base.TOnceAnonymousProc;
{$ENDIF}

  // Re-export exceptions
  ESyncError          = fafafa.core.sync.base.ESyncError;
  ELockError          = fafafa.core.sync.base.ELockError;
  ETimeoutError       = fafafa.core.sync.base.ETimeoutError;
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

// function MakeRecMutex(ASpinCount: DWORD): IRecMutex; overload; inline;
// function MakeRecMutex: IRecMutex; overload;

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

// Named synchronization primitives factory functions
function MakeNamedMutex(const AName: string): INamedMutex; overload;
function MakeNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex; overload;
function MakeNamedEvent(const AName: string): INamedEvent; overload;
function MakeNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent; overload;
function MakeNamedSemaphore(const AName: string): INamedSemaphore; overload;
function MakeNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore; overload;
function MakeNamedBarrier(const AName: string; AParticipantCount: Integer): INamedBarrier;
// function MakeNamedCondVar(const AName: string): INamedCondVar; // Temporarily disabled
function MakeNamedRWLock(const AName: string): INamedRWLock;

implementation

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

// function MakeRecMutex: IRecMutex;
// begin
//   Result := fafafa.core.sync.recMutex.MakeRecMutex;
// end;

// function MakeRecMutex(ASpinCount: DWORD): IRecMutex;
// begin
//   Result := fafafa.core.sync.recMutex.MakeRecMutex(ASpinCount);
// end;

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

// Named synchronization primitives implementations
function MakeNamedMutex(const AName: string): INamedMutex;
begin
  Result := fafafa.core.sync.namedMutex.MakeNamedMutex(AName);
end;

function MakeNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex;
begin
  Result := fafafa.core.sync.namedMutex.MakeNamedMutex(AName, AInitialOwner);
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
  Result := fafafa.core.sync.namedSemaphore.MakeNamedSemaphore(AName);
end;

function MakeNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore;
begin
  Result := fafafa.core.sync.namedSemaphore.MakeNamedSemaphore(AName, AInitialCount, AMaxCount);
end;

function MakeNamedBarrier(const AName: string; AParticipantCount: Integer): INamedBarrier;
begin
  Result := fafafa.core.sync.namedBarrier.MakeNamedBarrier(AName, AParticipantCount);
end;

// function MakeNamedCondVar(const AName: string): INamedCondVar;
// begin
//   Result := fafafa.core.sync.namedCondvar.MakeNamedCondVar(AName);
// end;

function MakeNamedRWLock(const AName: string): INamedRWLock;
begin
  Result := fafafa.core.sync.namedRWLock.MakeNamedRWLock(AName);
end;

end.


