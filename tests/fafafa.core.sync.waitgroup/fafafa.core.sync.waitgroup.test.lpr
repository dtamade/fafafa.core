program fafafa.core.sync.waitgroup.test;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  WaitGroup 测试套件

  测试 Go 风格的 WaitGroup 同步原语：
  - Add(delta): 增加/减少计数
  - Done(): 等同于 Add(-1)
  - Wait(): 阻塞直到计数为 0
  - WaitTimeout(ms): 带超时等待
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.waitgroup;

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
// 测试 1: 基本使用 - 单线程
// ============================================================================
procedure Test_WaitGroup_BasicUsage;
var
  WG: IWaitGroup;
begin
  WriteLn('Test: WaitGroup Basic Usage');

  WG := MakeWaitGroup;

  // 添加计数
  WG.Add(1);
  Assert(WG.GetCount = 1, 'Count should be 1 after Add(1)');

  // Done 减少计数
  WG.Done;
  Assert(WG.GetCount = 0, 'Count should be 0 after Done()');

  // Wait 应该立即返回（计数已为 0）
  WG.Wait;
  Assert(True, 'Wait() returned immediately when count is 0');
end;

// ============================================================================
// 测试 2: 多次 Add 和 Done
// ============================================================================
procedure Test_WaitGroup_MultipleAddDone;
var
  WG: IWaitGroup;
begin
  WriteLn('Test: WaitGroup Multiple Add/Done');

  WG := MakeWaitGroup;

  WG.Add(3);
  Assert(WG.GetCount = 3, 'Count should be 3 after Add(3)');

  WG.Done;
  Assert(WG.GetCount = 2, 'Count should be 2 after first Done()');

  WG.Done;
  Assert(WG.GetCount = 1, 'Count should be 1 after second Done()');

  WG.Done;
  Assert(WG.GetCount = 0, 'Count should be 0 after third Done()');
end;

// ============================================================================
// 测试 3: Add 负数 (等同于 Done)
// ============================================================================
procedure Test_WaitGroup_AddNegative;
var
  WG: IWaitGroup;
begin
  WriteLn('Test: WaitGroup Add Negative');

  WG := MakeWaitGroup;

  WG.Add(5);
  Assert(WG.GetCount = 5, 'Count should be 5 after Add(5)');

  WG.Add(-2);
  Assert(WG.GetCount = 3, 'Count should be 3 after Add(-2)');
end;

// ============================================================================
// 测试 4: 计数不能为负 - 应该抛出异常
// ============================================================================
procedure Test_WaitGroup_NegativeCountThrows;
var
  WG: IWaitGroup;
  ExceptionCaught: Boolean;
begin
  WriteLn('Test: WaitGroup Negative Count Throws');

  WG := MakeWaitGroup;
  ExceptionCaught := False;

  try
    WG.Add(-1);  // 计数为 0 时减 1，应该抛出异常
  except
    on E: Exception do
    begin
      ExceptionCaught := True;
      Assert(True, 'Exception caught when count goes negative: ' + E.Message);
    end;
  end;

  if not ExceptionCaught then
    Assert(False, 'Expected exception when count goes negative');
end;

// ============================================================================
// 测试 5: WaitTimeout 超时
// ============================================================================
procedure Test_WaitGroup_WaitTimeout;
var
  WG: IWaitGroup;
  StartTime: QWord;
  Elapsed: QWord;
  Result: Boolean;
begin
  WriteLn('Test: WaitGroup WaitTimeout');

  WG := MakeWaitGroup;
  WG.Add(1);  // 计数为 1，没有人会调用 Done

  StartTime := GetTickCount64;
  Result := WG.WaitTimeout(100);  // 等待 100ms
  Elapsed := GetTickCount64 - StartTime;

  Assert(not Result, 'WaitTimeout should return False on timeout');
  Assert(Elapsed >= 90, 'Should have waited at least 90ms');
  Assert(Elapsed < 200, 'Should not have waited more than 200ms');
end;

// ============================================================================
// 测试 6: WaitTimeout 成功（计数已为 0）
// ============================================================================
procedure Test_WaitGroup_WaitTimeoutSuccess;
var
  WG: IWaitGroup;
  Result: Boolean;
begin
  WriteLn('Test: WaitGroup WaitTimeout Success');

  WG := MakeWaitGroup;
  // 计数为 0，WaitTimeout 应该立即返回 True

  Result := WG.WaitTimeout(1000);
  Assert(Result, 'WaitTimeout should return True when count is 0');
end;

// ============================================================================
// 测试 7: 多线程场景
// ============================================================================
type
  TWorkerThread = class(TThread)
  private
    FWaitGroup: IWaitGroup;
    FWorkDone: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AWG: IWaitGroup);
    property WorkDone: Boolean read FWorkDone;
  end;

constructor TWorkerThread.Create(AWG: IWaitGroup);
begin
  inherited Create(True);  // 创建挂起
  FWaitGroup := AWG;
  FWorkDone := False;
  FreeOnTerminate := False;
end;

procedure TWorkerThread.Execute;
begin
  Sleep(50);  // 模拟工作
  FWorkDone := True;
  FWaitGroup.Done;
end;

procedure Test_WaitGroup_MultiThreaded;
var
  WG: IWaitGroup;
  Threads: array[0..2] of TWorkerThread;
  i: Integer;
  AllDone: Boolean;
begin
  WriteLn('Test: WaitGroup Multi-Threaded');

  WG := MakeWaitGroup;
  WG.Add(3);  // 3 个工作线程

  // 创建并启动工作线程
  for i := 0 to 2 do
  begin
    Threads[i] := TWorkerThread.Create(WG);
    Threads[i].Start;
  end;

  // 等待所有线程完成
  WG.Wait;

  // 验证所有线程都完成了工作
  AllDone := True;
  for i := 0 to 2 do
  begin
    AllDone := AllDone and Threads[i].WorkDone;
    Threads[i].Free;
  end;

  Assert(AllDone, 'All worker threads should have completed');
  Assert(WG.GetCount = 0, 'Count should be 0 after all threads done');
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  WaitGroup Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_WaitGroup_BasicUsage;
    Test_WaitGroup_MultipleAddDone;
    Test_WaitGroup_AddNegative;
    Test_WaitGroup_NegativeCountThrows;
    Test_WaitGroup_WaitTimeout;
    Test_WaitGroup_WaitTimeoutSuccess;
    Test_WaitGroup_MultiThreaded;
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
