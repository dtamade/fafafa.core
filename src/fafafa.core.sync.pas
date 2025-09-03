unit fafafa.core.sync;

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
  fafafa.core.sync.conditionVariable,
  fafafa.core.sync.barrier,
  fafafa.core.sync.sem,
  fafafa.core.sync.event;

type
  // Re-export core interfaces and enums for backward compatibility
  TLockState = fafafa.core.sync.base.TLockState;
  TWaitResult = fafafa.core.sync.base.TWaitResult;
  TWaitError = fafafa.core.sync.base.TWaitError;
  TLockResult = fafafa.core.sync.rwlock.TLockResult;
  ISynchronizable = fafafa.core.sync.base.ISynchronizable;
  ILock = fafafa.core.sync.base.ILock;
  IMutex = fafafa.core.sync.mutex.IMutex;
  ISpinLock = fafafa.core.sync.spin.ISpinLock;
  TSpinBackoffStrategy = fafafa.core.sync.spin.base.TSpinBackoffStrategy;
  TSpinLockPolicy = fafafa.core.sync.spin.base.TSpinLockPolicy;
  IOnce = fafafa.core.sync.once.IOnce;
  IReadWriteLock = fafafa.core.sync.base.IReadWriteLock;
  IRWLock = fafafa.core.sync.rwlock.IRWLock;
  IRWLockReadGuard = fafafa.core.sync.rwlock.IRWLockReadGuard;
  IRWLockWriteGuard = fafafa.core.sync.rwlock.IRWLockWriteGuard;
  ISem = fafafa.core.sync.sem.base.ISem;
  ISemGuard = fafafa.core.sync.sem.base.ISemGuard;
  IEvent = fafafa.core.sync.event.base.IEvent;
  IConditionVariable = fafafa.core.sync.conditionVariable.base.IConditionVariable;
  IBarrier = fafafa.core.sync.barrier.base.IBarrier;

  // Re-export exceptions
  ESyncError = fafafa.core.sync.base.ESyncError;
  ELockError = fafafa.core.sync.base.ELockError;
  ETimeoutError = fafafa.core.sync.base.ETimeoutError;
  EDeadlockError = fafafa.core.sync.base.EDeadlockError;

  // Back-compat exception alias
  EArgumentOutOfRange = fafafa.core.base.EOutOfRange;

  // Re-export concrete classes by platform
  {$IFDEF UNIX}
  TSpinLock = fafafa.core.sync.unix.TSpinLock;
  TOnce = fafafa.core.sync.once.TOnce;
  TReadWriteLock = fafafa.core.sync.unix.TReadWriteLock;
  // Use new sem module facade for platform selection
  TSemaphore = fafafa.core.sync.sem.TSemaphore;
  TEvent = fafafa.core.sync.unix.TEvent;
  TConditionVariable = fafafa.core.sync.conditionVariable.unix.TConditionVariable;
  TBarrier = fafafa.core.sync.barrier.unix.TBarrier;
  {$ENDIF}
  {$IFDEF WINDOWS}
  TSpinLock = fafafa.core.sync.windows.TSpinLock;
  TOnce = fafafa.core.sync.once.TOnce;
  TReadWriteLock = fafafa.core.sync.windows.TReadWriteLock;
  // Use new sem module facade for platform selection
  TSemaphore = fafafa.core.sync.sem.TSemaphore;
  TEvent = fafafa.core.sync.windows.TEvent;
  TConditionVariable = fafafa.core.sync.conditionVariable.windows.TConditionVariable;
  TBarrier = fafafa.core.sync.barrier.windows.TBarrier;
  {$ENDIF}



const
  // Re-export enum values for backward compatibility
  lsUnlocked = fafafa.core.sync.base.lsUnlocked;
  lsLocked = fafafa.core.sync.base.lsLocked;
  lsAbandoned = fafafa.core.sync.base.lsAbandoned;

  wrSignaled = fafafa.core.sync.base.wrSignaled;
  wrTimeout = fafafa.core.sync.base.wrTimeout;
  wrAbandoned = fafafa.core.sync.base.wrAbandoned;
  wrError = fafafa.core.sync.base.wrError;
  wrInterrupted = fafafa.core.sync.base.wrInterrupted;

  // TWaitError constants
  weNone = fafafa.core.sync.base.weNone;
  weInvalidHandle = fafafa.core.sync.base.weInvalidHandle;
  weResourceExhausted = fafafa.core.sync.base.weResourceExhausted;
  weAccessDenied = fafafa.core.sync.base.weAccessDenied;
  weDeadlock = fafafa.core.sync.base.weDeadlock;
  weSystemError = fafafa.core.sync.base.weSystemError;

  // TSpinBackoffStrategy constants
  sbsLinear = fafafa.core.sync.spin.base.sbsLinear;
  sbsExponential = fafafa.core.sync.spin.base.sbsExponential;
  sbsAdaptive = fafafa.core.sync.spin.base.sbsAdaptive;

// Re-export factory functions
function MakeMutex: IMutex; inline;
function MakeSpinLock: ISpinLock; overload; inline;
function MakeSpinLock(const APolicy: TSpinLockPolicy): ISpinLock; overload; inline;
function DefaultSpinLockPolicy: TSpinLockPolicy; inline;
function MakeRWLock: IRWLock; inline;
function CreateRWLock: IRWLock; inline;  // Alias for compatibility
function MakeConditionVariable: IConditionVariable; inline;
function MakeBarrier(AParticipantCount: Integer): IBarrier; inline;
function MakeSem(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISem; inline;
function MakeEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent; inline;

implementation

function MakeMutex: IMutex;
begin
  Result := fafafa.core.sync.mutex.MakeMutex;
end;

function MakeSpinLock: ISpinLock;
begin
  Result := fafafa.core.sync.spin.MakeSpinLock;
end;

function MakeSpinLock(const APolicy: TSpinLockPolicy): ISpinLock;
begin
  Result := fafafa.core.sync.spin.MakeSpinLock(APolicy);
end;

function DefaultSpinLockPolicy: TSpinLockPolicy;
begin
  Result := fafafa.core.sync.spin.base.DefaultSpinLockPolicy;
end;

function MakeRWLock: IRWLock;
begin
  Result := fafafa.core.sync.rwlock.MakeRWLock;
end;

function CreateRWLock: IRWLock;
begin
  Result := fafafa.core.sync.rwlock.MakeRWLock;
end;

function MakeConditionVariable: IConditionVariable;
begin
  Result := fafafa.core.sync.conditionVariable.MakeConditionVariable;
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

end.

