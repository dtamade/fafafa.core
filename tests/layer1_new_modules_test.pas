{$CODEPAGE UTF8}
program layer1_new_modules_test;

{**
 * Layer 1 新模块综合测试
 * 测试所有 8 个新同步原语
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.notify,
  fafafa.core.sync.notify.base,
  fafafa.core.sync.atomiccell,
  fafafa.core.sync.shardedlock,
  fafafa.core.sync.stampedlock,
  fafafa.core.sync.stampedlock.base,
  fafafa.core.sync.phaser,
  fafafa.core.sync.exchanger,
  fafafa.core.sync.atomicoption,
  fafafa.core.sync.reentrantrwlock;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Check(const AName: string; ACondition: Boolean);
begin
  if ACondition then
  begin
    Inc(TestsPassed);
    WriteLn('  [PASS] ', AName);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  [FAIL] ', AName);
  end;
end;

procedure TestNotify;
var
  N: INotify;
begin
  WriteLn('Testing INotify...');
  N := MakeNotify;
  Check('Create', N <> nil);
  Check('Initial waiter count', N.GetWaiterCount = 0);
  N.NotifyOne;  // Should not crash with no waiters
  Check('NotifyOne with no waiters', True);
end;

procedure TestAtomicCell;
var
  Cell: TAtomicCellInt32;
begin
  WriteLn('Testing TAtomicCell...');
  Cell.Init(42);
  Check('Init value', Cell.Load = 42);
  Cell.Store(100);
  Check('Store/Load', Cell.Load = 100);
  Check('Swap', Cell.Swap(200) = 100);
  Check('After Swap', Cell.Load = 200);
end;

procedure TestShardedLock;
var
  Cache: specialize TShardedLock<Integer, Integer>;
begin
  WriteLn('Testing TShardedLock...');
  Cache.Init(4);
  try
    Cache.Write(1, 100);
    Cache.Write(2, 200);
    Check('ShardCount', Cache.ShardCount = 4);
    Check('Contains', Cache.Contains(1));
    Check('Read', Cache.Read(1, -1) = 100);
    Check('Remove', Cache.Remove(1));
    Check('After Remove', not Cache.Contains(1));
  finally
    Cache.Done;
  end;
end;

procedure TestStampedLock;
var
  L: IStampedLock;
  Stamp, OptStamp: Int64;
begin
  WriteLn('Testing IStampedLock...');
  L := MakeStampedLock;
  Check('Create', L <> nil);
  Check('Not write locked', not L.IsWriteLocked);

  OptStamp := L.TryOptimisticRead;
  Check('Optimistic read', OptStamp <> 0);
  Check('Validate', L.Validate(OptStamp));

  Stamp := L.WriteLock;
  Check('Write lock', Stamp <> 0);
  Check('Is write locked', L.IsWriteLocked);
  L.UnlockWrite(Stamp);
  Check('After unlock', not L.IsWriteLocked);
end;

procedure TestPhaser;
var
  P: IPhaser;
begin
  WriteLn('Testing IPhaser...');
  P := MakePhaser(1);
  Check('Create', P <> nil);
  Check('Initial phase', P.GetPhase = 0);
  Check('Registered parties', P.GetRegisteredParties = 1);

  P.ArriveAndAwaitAdvance;
  Check('After advance', P.GetPhase = 1);
end;

procedure TestExchanger;
var
  Ex: TExchangerInt;
  R: Integer;
begin
  WriteLn('Testing TExchanger...');
  Ex.Init;
  try
    // 超时测试（无对手时应超时）
    Check('TryExchange timeout', not Ex.TryExchange(100, 10, R));
  finally
    Ex.Done;
  end;
end;

procedure TestAtomicOption;
var
  Opt: TAtomicOptionInt32;
  Val: Int32;
begin
  WriteLn('Testing TAtomicOption...');
  Opt.Init;
  Check('Initial IsNone', Opt.IsNone);
  Check('Initial IsSome', not Opt.IsSome);

  Opt.Store(42);
  Check('After Store IsSome', Opt.IsSome);
  Check('Load', Opt.Load(Val) and (Val = 42));

  Check('Take', Opt.Take(Val) and (Val = 42));
  Check('After Take IsNone', Opt.IsNone);
end;

procedure TestReentrantRWLock;
var
  L: IReentrantRWLock;
begin
  WriteLn('Testing IReentrantRWLock...');
  L := MakeReentrantRWLock;
  Check('Create', L <> nil);

  L.ReadLock;
  Check('Read lock acquired', True);
  L.ReadUnlock;

  L.WriteLock;
  Check('Write lock acquired', L.IsWriteLockHeld);
  L.WriteLock;  // Reentrant
  Check('Reentrant write lock', L.GetWriteHoldCount = 2);
  L.WriteUnlock;
  L.WriteUnlock;
  Check('After unlock', not L.IsWriteLockHeld);
end;

begin
  WriteLn('================================================');
  WriteLn('Layer 1 New Modules - Comprehensive Test');
  WriteLn('================================================');
  WriteLn;

  TestNotify;
  TestAtomicCell;
  TestShardedLock;
  TestStampedLock;
  TestPhaser;
  TestExchanger;
  TestAtomicOption;
  TestReentrantRWLock;

  WriteLn;
  WriteLn('================================================');
  WriteLn(Format('Results: %d passed, %d failed', [TestsPassed, TestsFailed]));
  WriteLn('================================================');

  if TestsFailed > 0 then
    Halt(1);
end.
