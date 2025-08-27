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
  fafafa.core.sync.once,
  fafafa.core.sync.conditionVariable,
  fafafa.core.sync.barrier,
  fafafa.core.sync.semaphore,
  fafafa.core.sync.event
  {$IFDEF WINDOWS}, fafafa.core.sync.windows {$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.unix    {$ENDIF};

type
  // Re-export core interfaces and enums for backward compatibility
  TLockState = fafafa.core.sync.base.TLockState;
  TWaitResult = fafafa.core.sync.base.TWaitResult;
  ILock = fafafa.core.sync.base.ILock;
  IMutex = fafafa.core.sync.mutex.IMutex;
  ISpinLock = fafafa.core.sync.spin.ISpinLock;
  IOnce = fafafa.core.sync.once.IOnce;
  IReadWriteLock = fafafa.core.sync.base.IReadWriteLock;
  ISemaphore = fafafa.core.sync.semaphore.base.ISemaphore;
  IEvent = fafafa.core.sync.event.base.IEvent;
  IConditionVariable = fafafa.core.sync.conditionVariable.base.IConditionVariable;
  IBarrier = fafafa.core.sync.barrier.base.IBarrier;

  // Re-export exceptions
  ESyncError = fafafa.core.sync.base.ESyncError;
  ELockError = fafafa.core.sync.base.ELockError;
  ETimeoutError = fafafa.core.sync.base.ETimeoutError;
  EDeadlockError = fafafa.core.sync.base.EDeadlockError;

  // Re-export RAII helpers
  TAutoLock      = fafafa.core.sync.base.TAutoLock;
  TAutoReadLock  = fafafa.core.sync.base.TAutoReadLock;
  TAutoWriteLock = fafafa.core.sync.base.TAutoWriteLock;

  // Back-compat exception alias
  EArgumentOutOfRange = fafafa.core.base.EOutOfRange;

  // Re-export concrete classes by platform
  {$IFDEF UNIX}
  TSpinLock = fafafa.core.sync.unix.TSpinLock;
  TOnce = fafafa.core.sync.once.TOnce;
  TReadWriteLock = fafafa.core.sync.unix.TReadWriteLock;
  // Use new semaphore module facade for platform selection
  TSemaphore = fafafa.core.sync.semaphore.TSemaphore;
  TEvent = fafafa.core.sync.unix.TEvent;
  TConditionVariable = fafafa.core.sync.conditionVariable.unix.TConditionVariable;
  TBarrier = fafafa.core.sync.barrier.unix.TBarrier;
  {$ENDIF}
  {$IFDEF WINDOWS}
  TSpinLock = fafafa.core.sync.windows.TSpinLock;
  TOnce = fafafa.core.sync.once.TOnce;
  TReadWriteLock = fafafa.core.sync.windows.TReadWriteLock;
  // Use new semaphore module facade for platform selection
  TSemaphore = fafafa.core.sync.semaphore.TSemaphore;
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

// Re-export factory functions
function MakeMutex: IMutex; inline;
function MakeSpinLock: ISpinLock; inline;
function MakeConditionVariable: IConditionVariable; inline;
function MakeBarrier(AParticipantCount: Integer): IBarrier; inline;
function MakeSemaphore(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISemaphore; inline;
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

function MakeConditionVariable: IConditionVariable;
begin
  Result := fafafa.core.sync.conditionVariable.MakeConditionVariable;
end;

function MakeBarrier(AParticipantCount: Integer): IBarrier;
begin
  Result := fafafa.core.sync.barrier.MakeBarrier(AParticipantCount);
end;

function MakeSemaphore(AInitialCount: Integer; AMaxCount: Integer): ISemaphore;
begin
  Result := fafafa.core.sync.semaphore.MakeSemaphore(AInitialCount, AMaxCount);
end;

function MakeEvent(AManualReset: Boolean; AInitialState: Boolean): IEvent;
begin
  Result := fafafa.core.sync.event.MakeEvent(AManualReset, AInitialState);
end;

end.

