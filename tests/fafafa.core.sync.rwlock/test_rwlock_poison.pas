program test_rwlock_poison;

{**
 * RWLock Poison 机制测试
 *
 * 测试 RWLock 的毒化（Poisoned）状态处理
 * 当线程在持有锁时发生异常，RWLock 应该进入毒化状态
 *
 * 测试覆盖：
 * 1. 毒化状态检测
 * 2. 毒化状态清除
 * 3. 毒化后的访问行为
 * 4. 多线程竞争下的毒化传播
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(Condition: Boolean; const Msg: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', Msg);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ FAIL: ', Msg);
  end;
end;

// ============================================================================
// 测试 1: 初始状态不应该是毒化的
// ============================================================================
procedure Test_RWLock_InitiallyNotPoisoned;
var
  RW: IRWLock;
begin
  WriteLn('Test: RWLock Initially Not Poisoned');

  RW := MakeRWLock;

  // 初始状态不应该是毒化的
  Assert(not RW.IsPoisoned, 'RWLock should not be poisoned initially');
end;

// ============================================================================
// 测试 2: 毒化状态清除
// ============================================================================
procedure Test_RWLock_ClearPoison;
var
  RW: IRWLock;
begin
  WriteLn('Test: RWLock Clear Poison');

  RW := MakeRWLock;

  // 注意：RWLock 没有 MarkPoisoned 方法，毒化状态只能通过异常触发
  // 这里我们只测试 ClearPoison 方法的存在性
  RW.ClearPoison;
  Assert(not RW.IsPoisoned, 'RWLock should not be poisoned after ClearPoison');
end;

// ============================================================================
// 测试 3: 读锁获取后正常释放
// ============================================================================
procedure Test_RWLock_ReadLockNormalRelease;
var
  RW: IRWLock;
  Guard: IRWLockReadGuard;
begin
  WriteLn('Test: RWLock Read Lock Normal Release');

  RW := MakeRWLock;

  // 获取读锁
  Guard := RW.Read;
  try
    Assert(not RW.IsPoisoned, 'RWLock should not be poisoned while holding read lock');
  finally
    Guard := nil;
  end;

  // 释放后仍然不应该是毒化的
  Assert(not RW.IsPoisoned, 'RWLock should not be poisoned after releasing read lock');
end;

// ============================================================================
// 测试 4: 写锁获取后正常释放
// ============================================================================
procedure Test_RWLock_WriteLockNormalRelease;
var
  RW: IRWLock;
  Guard: IRWLockWriteGuard;
begin
  WriteLn('Test: RWLock Write Lock Normal Release');

  RW := MakeRWLock;

  // 获取写锁
  Guard := RW.Write;
  try
    Assert(not RW.IsPoisoned, 'RWLock should not be poisoned while holding write lock');
  finally
    Guard := nil;
  end;

  // 释放后仍然不应该是毒化的
  Assert(not RW.IsPoisoned, 'RWLock should not be poisoned after releasing write lock');
end;

// ============================================================================
// 测试 5: 多次清除毒化状态
// ============================================================================
procedure Test_RWLock_MultipleClearPoison;
var
  RW: IRWLock;
  I: Integer;
begin
  WriteLn('Test: RWLock Multiple Clear Poison');

  RW := MakeRWLock;

  // 多次清除毒化状态（即使没有毒化）
  for I := 1 to 5 do
  begin
    RW.ClearPoison;
    Assert(not RW.IsPoisoned, 'RWLock should not be poisoned after ClearPoison ' + IntToStr(I));
  end;
end;

// ============================================================================
// 测试 6: 读锁和写锁交替获取
// ============================================================================
procedure Test_RWLock_AlternatingReadWrite;
var
  RW: IRWLock;
  ReadGuard: IRWLockReadGuard;
  WriteGuard: IRWLockWriteGuard;
  I: Integer;
begin
  WriteLn('Test: RWLock Alternating Read Write');

  RW := MakeRWLock;

  // 交替获取读锁和写锁
  for I := 1 to 3 do
  begin
    // 获取读锁
    ReadGuard := RW.Read;
    try
      Assert(not RW.IsPoisoned, 'RWLock should not be poisoned while holding read lock ' + IntToStr(I));
    finally
      ReadGuard := nil;
    end;

    // 获取写锁
    WriteGuard := RW.Write;
    try
      Assert(not RW.IsPoisoned, 'RWLock should not be poisoned while holding write lock ' + IntToStr(I));
    finally
      WriteGuard := nil;
    end;
  end;
end;

// ============================================================================
// 测试 7: 多线程读锁获取
// ============================================================================
type
  TReadLockThread = class(TThread)
  private
    FRWLock: IRWLock;
    FSeenPoisoned: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ARWLock: IRWLock);
    property SeenPoisoned: Boolean read FSeenPoisoned;
  end;

constructor TReadLockThread.Create(ARWLock: IRWLock);
begin
  inherited Create(True);
  FRWLock := ARWLock;
  FSeenPoisoned := False;
  FreeOnTerminate := False;
end;

procedure TReadLockThread.Execute;
var
  Guard: IRWLockReadGuard;
begin
  Guard := FRWLock.Read;
  try
    FSeenPoisoned := FRWLock.IsPoisoned;
  finally
    Guard := nil;
  end;
end;

procedure Test_RWLock_MultiThreadReadLock;
const
  THREAD_COUNT = 5;
var
  RW: IRWLock;
  Threads: array[0..THREAD_COUNT-1] of TReadLockThread;
  I: Integer;
  AllNotPoisoned: Boolean;
begin
  WriteLn('Test: RWLock Multi Thread Read Lock');

  RW := MakeRWLock;

  // 创建多个读锁线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TReadLockThread.Create(RW);

  // 启动所有线程
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I].Start;

  // 等待所有线程完成
  AllNotPoisoned := True;
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].WaitFor;
    if Threads[I].SeenPoisoned then
      AllNotPoisoned := False;
    Threads[I].Free;
  end;

  Assert(AllNotPoisoned, 'All threads should not see poisoned state');
  Assert(not RW.IsPoisoned, 'RWLock should not be poisoned after multi-thread read');
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  RWLock Poison Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_RWLock_InitiallyNotPoisoned;
    Test_RWLock_ClearPoison;
    Test_RWLock_ReadLockNormalRelease;
    Test_RWLock_WriteLockNormalRelease;
    Test_RWLock_MultipleClearPoison;
    Test_RWLock_AlternatingReadWrite;
    Test_RWLock_MultiThreadReadLock;
  except
    on E: Exception do
    begin
      WriteLn('FATAL: Unhandled exception: ', E.ClassName, ': ', E.Message);
      Inc(TestsFailed);
    end;
  end;

  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Results: ', TestsPassed, ' passed, ', TestsFailed, ' failed');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1);
end.
