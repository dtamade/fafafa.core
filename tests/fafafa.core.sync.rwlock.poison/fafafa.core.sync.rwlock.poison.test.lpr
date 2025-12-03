program fafafa.core.sync.rwlock.poison.test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('[PASS] ', TestName);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('[FAIL] ', TestName);
  end;
end;

// Custom test exception
type
  ETestException = class(Exception);

// ==================== RWLock Poison Tests ====================

procedure Test_Poison_InitialStateNotPoisoned;
var
  RW: IRWLock;
begin
  // New lock should not be poisoned
  RW := MakeRWLock(DefaultRWLockOptions);
  Check(not RW.IsPoisoned, 'New lock is not poisoned');
  RW := nil;
end;

procedure Test_Poison_OnExceptionDuringWrite;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  ExceptionRaised: Boolean;
begin
  RW := MakeRWLock(DefaultRWLockOptions);
  Check(not RW.IsPoisoned, 'Initially not poisoned');
  
  // Simulate exception during write lock hold
  ExceptionRaised := False;
  try
    WG := RW.Write;
    try
      // Simulate critical section code that throws
      raise ETestException.Create('Simulated panic during write');
    finally
      // Guard destructor should detect the exception and poison the lock
      WG := nil;
    end;
  except
    on E: ETestException do
      ExceptionRaised := True;
  end;
  
  Check(ExceptionRaised, 'Exception was raised');
  Check(RW.IsPoisoned, 'Lock is poisoned after exception during write');
  
  RW := nil;
end;

procedure Test_Poison_OnExceptionDuringRead;
var
  RW: IRWLock;
  RG: IRWLockReadGuard;
  ExceptionRaised: Boolean;
begin
  RW := MakeRWLock(DefaultRWLockOptions);
  Check(not RW.IsPoisoned, 'Initially not poisoned');
  
  // Simulate exception during read lock hold
  ExceptionRaised := False;
  try
    RG := RW.Read;
    try
      raise ETestException.Create('Simulated panic during read');
    finally
      RG := nil;
    end;
  except
    on E: ETestException do
      ExceptionRaised := True;
  end;
  
  Check(ExceptionRaised, 'Exception was raised');
  Check(RW.IsPoisoned, 'Lock is poisoned after exception during read');
  
  RW := nil;
end;

procedure Test_Poison_SubsequentAcquireFails;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  PoisonErrorRaised: Boolean;
begin
  RW := MakeRWLock(DefaultRWLockOptions);
  
  // First, poison the lock
  try
    WG := RW.Write;
    try
      raise ETestException.Create('Poison the lock');
    finally
      WG := nil;
    end;
  except
    on E: ETestException do; // Ignore
  end;
  
  Check(RW.IsPoisoned, 'Lock is poisoned');
  
  // Now try to acquire again - should fail with ERWLockPoisonError
  PoisonErrorRaised := False;
  try
    WG := RW.Write;
    WG := nil;
  except
    on E: ERWLockPoisonError do
      PoisonErrorRaised := True;
  end;
  
  Check(PoisonErrorRaised, 'ERWLockPoisonError raised on acquire after poison');
  
  RW := nil;
end;

procedure Test_Poison_ClearPoison;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
begin
  RW := MakeRWLock(DefaultRWLockOptions);
  
  // Poison the lock
  try
    WG := RW.Write;
    try
      raise ETestException.Create('Poison the lock');
    finally
      WG := nil;
    end;
  except
    on E: ETestException do; // Ignore
  end;
  
  Check(RW.IsPoisoned, 'Lock is poisoned');
  
  // Clear poison
  RW.ClearPoison;
  Check(not RW.IsPoisoned, 'Lock is no longer poisoned after ClearPoison');
  
  // Should be able to acquire normally now
  WG := RW.Write;
  Check(WG <> nil, 'Can acquire write lock after ClearPoison');
  if WG <> nil then
  begin
    WG.Release;
    WG := nil;
  end;
  
  RW := nil;
end;

procedure Test_Poison_TryAcquireReturnsNilWhenPoisoned;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  RG: IRWLockReadGuard;
begin
  RW := MakeRWLock(DefaultRWLockOptions);
  
  // Poison the lock
  try
    WG := RW.Write;
    try
      raise ETestException.Create('Poison the lock');
    finally
      WG := nil;
    end;
  except
    on E: ETestException do; // Ignore
  end;
  
  Check(RW.IsPoisoned, 'Lock is poisoned');
  
  // TryWrite should return nil when poisoned (non-throwing variant)
  WG := RW.TryWrite(0);
  Check(WG = nil, 'TryWrite returns nil when poisoned');
  
  RG := RW.TryRead(0);
  Check(RG = nil, 'TryRead returns nil when poisoned');
  
  RW := nil;
end;

procedure Test_Poison_NormalReleaseDoesNotPoison;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
begin
  RW := MakeRWLock(DefaultRWLockOptions);
  
  // Normal usage - no exception
  WG := RW.Write;
  WG.Release;
  WG := nil;
  
  Check(not RW.IsPoisoned, 'Lock not poisoned after normal release');
  
  // Acquire again should work
  WG := RW.Write;
  Check(WG <> nil, 'Can acquire after normal release');
  if WG <> nil then
  begin
    WG.Release;
    WG := nil;
  end;
  
  RW := nil;
end;

procedure Test_Poison_DisabledByConfig;
var
  Options: TRWLockOptions;
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  ExceptionRaised: Boolean;
  NoErrorOnAcquire: Boolean;
begin
  // Create lock with poisoning disabled
  Options := DefaultRWLockOptions;
  Options.EnablePoisoning := False;
  RW := MakeRWLock(Options);
  
  Check(not RW.IsPoisoned, 'Lock starts not poisoned');
  
  // Simulate exception - should NOT poison when disabled
  ExceptionRaised := False;
  try
    WG := RW.Write;
    try
      raise ETestException.Create('This should not poison');
    finally
      WG := nil;
    end;
  except
    on E: ETestException do
      ExceptionRaised := True;
  end;
  
  Check(ExceptionRaised, 'Exception was raised');
  Check(not RW.IsPoisoned, 'Lock NOT poisoned when EnablePoisoning=False');
  
  // Should be able to acquire without ERWLockPoisonError
  NoErrorOnAcquire := False;
  try
    WG := RW.Write;
    if WG <> nil then
    begin
      NoErrorOnAcquire := True;
      WG.Release;
      WG := nil;
    end;
  except
    on E: Exception do
      ; // Ignore any error
  end;
  
  Check(NoErrorOnAcquire, 'Can acquire normally when poisoning disabled');
  
  RW := nil;
end;

// ==================== Main ====================

begin
  WriteLn('=== Phase 2.3: RWLock Poison Tests ===');
  WriteLn;
  
  Test_Poison_InitialStateNotPoisoned;
  Test_Poison_OnExceptionDuringWrite;
  Test_Poison_OnExceptionDuringRead;
  Test_Poison_SubsequentAcquireFails;
  Test_Poison_ClearPoison;
  Test_Poison_TryAcquireReturnsNilWhenPoisoned;
  Test_Poison_NormalReleaseDoesNotPoison;
  Test_Poison_DisabledByConfig;
  
  WriteLn;
  WriteLn('===========================================');
  WriteLn('Total: ', TestsPassed + TestsFailed, ' | Passed: ', TestsPassed, ' | Failed: ', TestsFailed);
  
  if TestsFailed > 0 then
    Halt(1);
end.
