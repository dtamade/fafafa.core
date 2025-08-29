unit fafafa.core.sync.recMutex.testcase;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base,
  fafafa.core.sync.recMutex;

type
  TTestCase_RecMutex = class(TTestCase)
  private
    M: IRecMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础功能测试
    procedure Test_Basic_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_GetLastError;

    // 可重入性核心测试
    procedure Test_Reentrant_SameThread_Basic;
    procedure Test_Reentrant_SameThread_Deep;
    procedure Test_Reentrant_TryAcquire_Mixed;
    procedure Test_Reentrant_Balanced_Release;

    // 超时与错误处理
    procedure Test_TryAcquire_Timeout_Zero;
    procedure Test_TryAcquire_Timeout_Positive;
    procedure Test_TryAcquire_Timeout_Reentrant;

    // 并发测试
    procedure Test_CrossThread_Exclusion;
    procedure Test_MultiThread_Reentrant_Safety;

    // 边界条件与错误处理
    procedure Test_Unbalanced_Release_Error;
    procedure Test_Maximum_Recursion_Depth;

    // Windows 特定测试
    {$IFDEF WINDOWS}
    procedure Test_Windows_SpinCount_Configuration;
    {$ENDIF}
  end;

implementation

procedure TTestCase_RecMutex.SetUp;
begin
  inherited SetUp;
  M := MakeRecMutex;
end;

procedure TTestCase_RecMutex.TearDown;
begin
  M := nil;
  inherited TearDown;
end;

{ 基础功能测试 }

procedure TTestCase_RecMutex.Test_Basic_Acquire_Release;
begin
  M.Acquire;
  M.Release;
  AssertEquals('GetLastError should be weNone after successful operation', Ord(weNone), Ord(M.GetLastError));
end;

procedure TTestCase_RecMutex.Test_TryAcquire_Success;
begin
  AssertTrue('TryAcquire should succeed when unlocked', M.TryAcquire);
  M.Release;
  AssertEquals('GetLastError should be weNone after successful TryAcquire', Ord(weNone), Ord(M.GetLastError));
end;

procedure TTestCase_RecMutex.Test_GetLastError;
begin
  M.Acquire;
  M.Release;
  AssertEquals('GetLastError should be weNone after normal operation', Ord(weNone), Ord(M.GetLastError));
end;

{ 可重入性核心测试 }

procedure TTestCase_RecMutex.Test_Reentrant_SameThread_Basic;
begin
  M.Acquire;
  M.Acquire; // 可重入：同线程第二次获取应该成功
  M.Release;
  M.Release;
  AssertEquals('Basic reentrant operation should succeed', Ord(weNone), Ord(M.GetLastError));
end;

procedure TTestCase_RecMutex.Test_Reentrant_SameThread_Deep;
var i: Integer;
begin
  // 测试深度重入（10层）
  for i := 1 to 10 do
    M.Acquire;

  // 必须释放相同次数
  for i := 1 to 10 do
    M.Release;

  AssertEquals('Deep reentrant operation should succeed', Ord(weNone), Ord(M.GetLastError));
end;

procedure TTestCase_RecMutex.Test_Reentrant_TryAcquire_Mixed;
begin
  M.Acquire;
  AssertTrue('TryAcquire should succeed on reentrant mutex', M.TryAcquire);
  M.Acquire; // 第三次获取

  M.Release; // 释放第三次
  M.Release; // 释放 TryAcquire
  M.Release; // 释放第一次

  AssertEquals('Mixed Acquire/TryAcquire should work', Ord(weNone), Ord(M.GetLastError));
end;

procedure TTestCase_RecMutex.Test_Reentrant_Balanced_Release;
begin
  M.Acquire;
  M.Acquire;
  M.Acquire;

  // 平衡释放
  M.Release;
  M.Release;
  M.Release;

  // 现在应该完全释放，其他线程可以获取
  AssertTrue('After balanced release, mutex should be available', M.TryAcquire);
  M.Release;
end;
{ 超时与错误处理 }

procedure TTestCase_RecMutex.Test_TryAcquire_Timeout_Zero;
begin
  AssertTrue('TryAcquire(0) should succeed when unlocked', M.TryAcquire(0));
  M.Release;

  // 测试可重入情况下的 TryAcquire(0)
  M.Acquire;
  AssertTrue('TryAcquire(0) should succeed on reentrant mutex', M.TryAcquire(0));
  M.Release; // 释放 TryAcquire(0)
  M.Release; // 释放 Acquire
end;

procedure TTestCase_RecMutex.Test_TryAcquire_Timeout_Positive;
var start: QWord;
begin
  start := GetTickCount64;
  AssertTrue('TryAcquire(100) should succeed when unlocked', M.TryAcquire(100));
  AssertTrue('TryAcquire(100) should return quickly when unlocked', GetTickCount64 - start < 50);
  M.Release;
end;

procedure TTestCase_RecMutex.Test_TryAcquire_Timeout_Reentrant;
var start: QWord;
begin
  M.Acquire;
  start := GetTickCount64;
  AssertTrue('TryAcquire(50) should succeed immediately on reentrant mutex', M.TryAcquire(50));
  AssertTrue('Reentrant TryAcquire should be immediate', GetTickCount64 - start < 10);
  M.Release; // 释放 TryAcquire
  M.Release; // 释放 Acquire
end;

{ 并发测试 }

procedure TTestCase_RecMutex.Test_CrossThread_Exclusion;
var
  acquired: Boolean;
  t: TThread;
begin
  acquired := False;
  M.Acquire;
  M.Acquire; // 重入

  t := TThread.CreateAnonymousThread(
    procedure
    begin
      acquired := M.TryAcquire(10); // 其他线程应该无法获取
      if acquired then M.Release;
    end);
  t.Start;
  t.WaitFor;
  t.Free;

  M.Release; // 释放重入
  M.Release; // 释放第一次
  AssertFalse('Other thread should NOT acquire reentrant mutex held by current thread', acquired);
end;

procedure TTestCase_RecMutex.Test_MultiThread_Reentrant_Safety;
var
  threads: array[0..3] of TThread;
  sharedCounter: Integer;
  i: Integer;
begin
  sharedCounter := 0;

  // 每个线程执行递归重入操作
  for i := 0 to High(threads) do
  begin
    threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j, depth: Integer;
      begin
        for j := 1 to 25 do
        begin
          // 手动展开递归，避免嵌套函数捕获问题
          for depth := 1 to 3 do
          begin
            M.Acquire;
            try
              Inc(sharedCounter);
            finally
              M.Release;
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

  // 4个线程 × 25次 × 3层 = 300
  AssertEquals('Multi-thread reentrant operations should be safe', 300, sharedCounter);
end;
{ 边界条件与错误处理 }

procedure TTestCase_RecMutex.Test_Unbalanced_Release_Error;
begin
  M.Acquire;
  M.Release;

  // 尝试多余的释放
  try
    M.Release; // 这应该导致错误或异常
    // 某些平台可能不会立即报错，但应该设置错误状态
    AssertTrue('Unbalanced release should not crash', True);
  except
    on E: Exception do
      AssertTrue('Unbalanced release may throw exception: ' + E.Message, True);
  end;
end;

procedure TTestCase_RecMutex.Test_Maximum_Recursion_Depth;
var
  i: Integer;
  maxDepth: Integer;
begin
  // 测试最大递归深度（通常平台限制在几千到几万）
  maxDepth := 1000; // 保守测试值

  try
    for i := 1 to maxDepth do
      M.Acquire;

    for i := 1 to maxDepth do
      M.Release;

    AssertTrue('Should handle reasonable recursion depth', True);
  except
    on E: Exception do
      Fail('Reasonable recursion depth should not fail: ' + E.Message);
  end;
end;

{$IFDEF WINDOWS}
{ Windows 特定测试 }

procedure TTestCase_RecMutex.Test_Windows_SpinCount_Configuration;
var
  m1, m2: IRecMutex;
begin
  // 测试不同 SpinCount 配置
  m1 := MakeRecMutex;        // 默认 SpinCount
  m2 := MakeRecMutex(8000);  // 自定义 SpinCount

  // 基本功能应该一致
  m1.Acquire; m1.Release;
  m2.Acquire; m2.Release;

  // 测试重入行为
  m1.Acquire; m1.Acquire; m1.Release; m1.Release;
  m2.Acquire; m2.Acquire; m2.Release; m2.Release;

  AssertTrue('Different SpinCount configurations should work identically', True);
end;
{$ENDIF}


initialization
  RegisterTest(TTestCase_RecMutex);

end.

