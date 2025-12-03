program fafafa.core.sync.rwlock.downgrade.test;

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

// ==================== RWLock Downgrade Tests ====================

procedure Test_Downgrade_FromWriteGuard_ReturnsReadGuard;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  RG: IRWLockReadGuard;
begin
  WriteLn('  Creating RWLock...');
  RW := MakeRWLock(FairRWLockOptions);
  WriteLn('  Acquiring write lock...');
  WG := RW.Write;
  Check(WG.IsValid, 'Write guard is valid');
  Check(RW.IsWriteLocked, 'RWLock is write locked');
  
  // Downgrade: write -> read
  WriteLn('  Downgrading...');
  RG := WG.Downgrade;
  
  Check(RG.IsValid, 'Downgrade returns valid read guard');
  Check(not WG.IsValid, 'Original write guard is invalidated');
  Check(not RW.IsWriteLocked, 'RWLock is no longer write locked');
  Check(RW.GetReaderCount >= 1, 'RWLock has at least one reader');
  
  // Explicitly release
  WriteLn('  Releasing read guard...');
  RG.Release;
  WriteLn('  Setting RG to nil...');
  RG := nil;
  WriteLn('  Setting WG to nil...');
  WG := nil;
  WriteLn('  Setting RW to nil...');
  RW := nil;
  WriteLn('  Test complete.');
end;

procedure Test_Downgrade_AllowsOtherReaders;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  RG1, RG2: IRWLockReadGuard;
begin
  WriteLn('  Creating RWLock...');
  RW := MakeRWLock(FairRWLockOptions);
  
  // Acquire write lock
  WriteLn('  Acquiring write lock...');
  WG := RW.Write;
  Check(RW.IsWriteLocked, 'RWLock is write locked');
  
  // Downgrade to read
  WriteLn('  Downgrading...');
  RG1 := WG.Downgrade;
  Check(RG1.IsValid, 'First read guard valid after downgrade');
  
  // Now another reader should be able to acquire
  WriteLn('  Acquiring second reader...');
  RG2 := RW.TryRead(100);
  Check(RG2.IsValid, 'Second reader can acquire after downgrade');
  Check(RW.GetReaderCount >= 2, 'RWLock has multiple readers');
  
  // Explicit cleanup
  WriteLn('  Releasing RG2...');
  RG2.Release;
  RG2 := nil;
  WriteLn('  Releasing RG1...');
  RG1.Release;
  RG1 := nil;
  WriteLn('  Setting WG to nil...');
  WG := nil;
  WriteLn('  Setting RW to nil...');
  RW := nil;
  WriteLn('  Test complete.');
end;

procedure Test_Downgrade_Atomic_NoWriterCanInterrupt;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  RG: IRWLockReadGuard;
  WG2: IRWLockWriteGuard;
begin
  RW := MakeRWLock(FairRWLockOptions);
  
  // First, acquire write lock
  WG := RW.Write;
  
  // Downgrade to read - should be atomic
  RG := WG.Downgrade;
  Check(RG.IsValid, 'Read guard valid after downgrade');
  
  // Another writer should NOT be able to acquire immediately
  // Note: TryWrite returns nil when it cannot acquire the lock
  WG2 := RW.TryWrite(0);
  Check(WG2 = nil, 'Writer cannot acquire while read held (returns nil)');
  
  // Release read lock
  RG.Release;
  RG := nil;
  
  // Now writer should be able to acquire
  WG2 := RW.TryWrite(100);
  Check((WG2 <> nil) and WG2.IsValid, 'Writer can acquire after read released');
  
  // Cleanup
  if WG2 <> nil then
  begin
    WG2.Release;
    WG2 := nil;
  end;
  WG := nil;
  RW := nil;
end;

procedure Test_Downgrade_PreservesLockContinuity;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  RG: IRWLockReadGuard;
begin
  RW := MakeRWLock(FairRWLockOptions);
  
  // Get write lock
  WG := RW.Write;
  Check(RW.IsWriteLocked, 'Initially write locked');
  Check(not RW.IsReadLocked, 'No read lock initially');
  
  // Downgrade
  RG := WG.Downgrade;
  
  // Should transition atomically: never unlocked between
  Check(RW.IsReadLocked, 'Now read locked');
  Check(RG.IsValid, 'Read guard is valid');
  
  // Explicit cleanup
  RG.Release;
  RG := nil;
  WG := nil;
  RW := nil;
end;

procedure Test_Downgrade_InvalidatedWriteGuard_CannotRelease;
var
  RW: IRWLock;
  WG: IRWLockWriteGuard;
  RG: IRWLockReadGuard;
begin
  RW := MakeRWLock(FairRWLockOptions);
  
  WG := RW.Write;
  RG := WG.Downgrade;
  
  // Write guard should be invalidated
  Check(not WG.IsValid, 'Write guard invalidated after downgrade');
  
  // Calling Release on invalidated guard should be safe (no-op)
  WG.Release;  // Should not crash or double-release
  
  Check(RG.IsValid, 'Read guard still valid');
  Check(RW.GetReaderCount >= 1, 'Reader count still positive');
  
  // Explicit cleanup
  RG.Release;
  RG := nil;
  WG := nil;
  RW := nil;
end;

// ==================== Main ====================

begin
  WriteLn('=== Phase 2.2: RWLock Downgrade Tests ===');
  WriteLn;
  
  Test_Downgrade_FromWriteGuard_ReturnsReadGuard;
  Test_Downgrade_AllowsOtherReaders;
  Test_Downgrade_Atomic_NoWriterCanInterrupt;
  Test_Downgrade_PreservesLockContinuity;
  Test_Downgrade_InvalidatedWriteGuard_CannotRelease;
  
  WriteLn;
  WriteLn('===========================================');
  WriteLn('Total: ', TestsPassed + TestsFailed, ' | Passed: ', TestsPassed, ' | Failed: ', TestsFailed);
  
  if TestsFailed > 0 then
    Halt(1);
end.
