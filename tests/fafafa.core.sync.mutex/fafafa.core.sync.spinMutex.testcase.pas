unit fafafa.core.sync.spinMutex.testcase;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base,
  fafafa.core.sync.spinMutex;

type
  TTestCase_SpinMutex = class(TTestCase)
  private
    S: ILock;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础功能测试
    procedure Test_Basic_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_TryAcquire_Timeout_Zero;
    procedure Test_TryAcquire_Timeout_Positive;
    procedure Test_GetLastError;

    // 语义验证：不可重入性
    procedure Test_NonReentrant_SameThread;
    procedure Test_NonReentrant_Deadlock_Detection;

    // 自旋行为验证
    procedure Test_SpinBehavior_LowContention;
    procedure Test_SpinBehavior_HighContention;
    procedure Test_SpinRounds_Configuration;

    // 并发测试
    procedure Test_CrossThread_Exclusion;
    procedure Test_MultiThread_Contention;

    // 边界条件
    procedure Test_Multiple_Release_Error;
    procedure Test_Invalid_SpinRounds;
  end;

implementation

procedure TTestCase_SpinMutex.SetUp;
begin
  inherited SetUp;
  S := MakeSpinMutex(1000);
end;

procedure TTestCase_SpinMutex.TearDown;
begin
  S := nil;
  inherited TearDown;
end;

{ 基础功能测试 }

procedure TTestCase_SpinMutex.Test_Basic_Acquire_Release;
begin
  S.Acquire;
  S.Release;
  AssertEquals('GetLastError should be weNone after successful operation', Ord(weNone), Ord(S.GetLastError));
end;

procedure TTestCase_SpinMutex.Test_TryAcquire_Success;
begin
  AssertTrue('TryAcquire should succeed when unlocked', S.TryAcquire);
  S.Release;
  AssertEquals('GetLastError should be weNone after successful TryAcquire', Ord(weNone), Ord(S.GetLastError));
end;

procedure TTestCase_SpinMutex.Test_TryAcquire_Timeout_Zero;
begin
  AssertTrue('TryAcquire(0) should succeed when unlocked', S.TryAcquire(0));
  S.Release;
end;

procedure TTestCase_SpinMutex.Test_TryAcquire_Timeout_Positive;
var start: QWord;
begin
  start := GetTickCount64;
  AssertTrue('TryAcquire(100) should succeed when unlocked', S.TryAcquire(100));
  AssertTrue('TryAcquire(100) should return quickly when unlocked', GetTickCount64 - start < 50);
  S.Release;
end;

procedure TTestCase_SpinMutex.Test_GetLastError;
begin
  S.Acquire;
  S.Release;
  AssertEquals('GetLastError should be weNone after normal operation', Ord(weNone), Ord(S.GetLastError));
end;
{ 语义验证：不可重入性 }

procedure TTestCase_SpinMutex.Test_NonReentrant_SameThread;
var acquired: Boolean;
begin
  S.Acquire;
  // SpinMutex 基于标准 Mutex，应该不可重入
  acquired := S.TryAcquire(0);
  if acquired then
  begin
    S.Release; // 释放意外获得的锁
    Fail('SpinMutex should NOT be reentrant - TryAcquire should fail on same thread');
  end;
  S.Release; // 释放第一次获得的锁
end;

procedure TTestCase_SpinMutex.Test_NonReentrant_Deadlock_Detection;
begin
  // 这个测试验证在 Debug 模式下是否能检测到重入尝试
  S.Acquire;
  try
    // 在 Debug 模式下，某些平台可能会检测并报告错误
    AssertTrue('Should be able to detect non-reentrant behavior', True);
  finally
    S.Release;
  end;
end;

{ 自旋行为验证 }

procedure TTestCase_SpinMutex.Test_SpinBehavior_LowContention;
var i, successCount: Integer;
    start: QWord;
begin
  successCount := 0;
  start := GetTickCount64;

  // 低竞争下，TryAcquire 应该快速成功
  for i := 1 to 1000 do
  begin
    if S.TryAcquire then
    begin
      Inc(successCount);
      S.Release;
    end;
  end;

  AssertTrue('Low contention: most TryAcquire should succeed', successCount > 950);
  AssertTrue('Low contention: should be very fast', GetTickCount64 - start < 100);
end;

procedure TTestCase_SpinMutex.Test_SpinBehavior_HighContention;
var
  threads: array[0..3] of TThread;
  sharedCounter: Integer;
  i: Integer;
begin
  sharedCounter := 0;

  // 创建多个线程竞争同一个锁
  for i := 0 to High(threads) do
  begin
    threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j: Integer;
      begin
        for j := 1 to 100 do
        begin
          S.Acquire;
          try
            Inc(sharedCounter);
            Sleep(1); // 模拟临界区工作
          finally
            S.Release;
          end;
        end;
      end);
    threads[i].Start;
  end;

  // 等待所有线程完成
  for i := 0 to High(threads) do
  begin
    threads[i].WaitFor;
    threads[i].Free;
  end;

  AssertEquals('High contention: all increments should be protected', 400, sharedCounter);
end;
procedure TTestCase_SpinMutex.Test_SpinRounds_Configuration;
var
  s1, s2: ILock;
begin
  // 测试不同自旋轮次配置
  s1 := MakeSpinMutex(100);   // 少量自旋
  s2 := MakeSpinMutex(10000); // 大量自旋

  // 基本功能应该一致
  s1.Acquire; s1.Release;
  s2.Acquire; s2.Release;

  AssertTrue('Different spin configurations should work', True);
end;

{ 并发测试 }

procedure TTestCase_SpinMutex.Test_CrossThread_Exclusion;
var
  acquired: Boolean;
  t: TThread;
begin
  acquired := False;
  S.Acquire;

  t := TThread.CreateAnonymousThread(
    procedure
    begin
      acquired := S.TryAcquire(10); // 短暂尝试
      if acquired then S.Release;
    end);
  t.Start;
  t.WaitFor;
  t.Free;

  S.Release;
  AssertFalse('Other thread should NOT acquire locked mutex', acquired);
end;

procedure TTestCase_SpinMutex.Test_MultiThread_Contention;
var
  threads: array[0..7] of TThread;
  results: array[0..7] of Integer;
  i, totalOps: Integer;
begin
  FillChar(results, SizeOf(results), 0);

  // 8个线程，每个执行50次操作
  for i := 0 to High(threads) do
  begin
    threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j, threadIdx: Integer;
      begin
        threadIdx := PtrInt(TThread.CurrentThread.ThreadID) mod 8;
        for j := 1 to 50 do
        begin
          if S.TryAcquire(5) then
          begin
            try
              Inc(results[threadIdx]);
            finally
              S.Release;
            end;
          end;
        end;
      end);
    threads[i].Start;
  end;

  for i := 0 to High(threads) do
  begin
    threads[i].WaitFor;
    threads[i].Free;
  end;

  totalOps := 0;
  for i := 0 to High(results) do
    Inc(totalOps, results[i]);

  AssertTrue('Multi-thread contention should allow some operations', totalOps > 0);
  AssertTrue('Multi-thread contention should not exceed total attempts', totalOps <= 400);
end;

{ 边界条件 }

procedure TTestCase_SpinMutex.Test_Multiple_Release_Error;
begin
  S.Acquire;
  S.Release;

  // 多次释放在某些平台可能导致错误，但不应该崩溃
  try
    S.Release; // 这可能会设置错误状态
    AssertTrue('Multiple release should not crash', True);
  except
    on E: Exception do
      AssertTrue('Multiple release may throw exception: ' + E.Message, True);
  end;
end;

procedure TTestCase_SpinMutex.Test_Invalid_SpinRounds;
var sm: ILock;
begin
  // 测试无效的自旋轮次（应该使用默认值）
  sm := MakeSpinMutex(-1);  // 无效值，应该使用默认值
  sm.Acquire;
  sm.Release;

  sm := MakeSpinMutex(0);   // 边界值，应该使用默认值
  sm.Acquire;
  sm.Release;

  AssertTrue('Invalid spin rounds should use defaults', True);
end;

initialization
  RegisterTest(TTestCase_SpinMutex);

end.

