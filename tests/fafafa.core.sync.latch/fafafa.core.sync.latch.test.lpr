program fafafa.core.sync.latch.test;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  CountDownLatch 测试套件

  测试 Java 风格的一次性倒计数同步原语：
  - CountDown(): 减少计数
  - Await(): 阻塞直到计数为 0
  - AwaitTimeout(ms): 带超时等待
  - GetCount(): 获取当前计数

  与 WaitGroup 的区别：
  - Latch 是一次性的，计数只能减少不能增加
  - 没有 Add 方法，构造时指定初始计数
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.latch;

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
// 测试 1: 基本使用
// ============================================================================
procedure Test_Latch_BasicUsage;
var
  L: ILatch;
begin
  WriteLn('Test: Latch Basic Usage');

  L := MakeLatch(3);
  Assert(L.GetCount = 3, 'Initial count should be 3');

  L.CountDown;
  Assert(L.GetCount = 2, 'Count should be 2 after first CountDown');

  L.CountDown;
  Assert(L.GetCount = 1, 'Count should be 1 after second CountDown');

  L.CountDown;
  Assert(L.GetCount = 0, 'Count should be 0 after third CountDown');

  // Await 应该立即返回
  L.Await;
  Assert(True, 'Await returned immediately when count is 0');
end;

// ============================================================================
// 测试 2: CountDown 超过计数（应该保持在 0）
// ============================================================================
procedure Test_Latch_CountDownBelowZero;
var
  L: ILatch;
begin
  WriteLn('Test: Latch CountDown Below Zero');

  L := MakeLatch(1);
  Assert(L.GetCount = 1, 'Initial count should be 1');

  L.CountDown;
  Assert(L.GetCount = 0, 'Count should be 0 after CountDown');

  // 再次 CountDown 不应该出错，计数保持为 0
  L.CountDown;
  Assert(L.GetCount = 0, 'Count should remain 0 after extra CountDown');
end;

// ============================================================================
// 测试 3: 初始计数为 0
// ============================================================================
procedure Test_Latch_ZeroInitialCount;
var
  L: ILatch;
begin
  WriteLn('Test: Latch Zero Initial Count');

  L := MakeLatch(0);
  Assert(L.GetCount = 0, 'Initial count should be 0');

  // Await 应该立即返回
  L.Await;
  Assert(True, 'Await returned immediately when initial count is 0');
end;

// ============================================================================
// 测试 4: AwaitTimeout 超时
// ============================================================================
procedure Test_Latch_AwaitTimeout;
var
  L: ILatch;
  StartTime: QWord;
  Elapsed: QWord;
  Res: Boolean;
begin
  WriteLn('Test: Latch AwaitTimeout');

  L := MakeLatch(1);  // 没有人会调用 CountDown

  StartTime := GetTickCount64;
  Res := L.AwaitTimeout(100);  // 等待 100ms
  Elapsed := GetTickCount64 - StartTime;

  Assert(not Res, 'AwaitTimeout should return False on timeout');
  Assert(Elapsed >= 90, 'Should have waited at least 90ms');
  Assert(Elapsed < 200, 'Should not have waited more than 200ms');
end;

// ============================================================================
// 测试 5: AwaitTimeout 成功
// ============================================================================
procedure Test_Latch_AwaitTimeoutSuccess;
var
  L: ILatch;
  Res: Boolean;
begin
  WriteLn('Test: Latch AwaitTimeout Success');

  L := MakeLatch(0);  // 计数为 0

  Res := L.AwaitTimeout(1000);
  Assert(Res, 'AwaitTimeout should return True when count is 0');
end;

// ============================================================================
// 测试 6: 多线程场景 - 门控启动
// ============================================================================
type
  TStartGateThread = class(TThread)
  private
    FLatch: ILatch;
    FStarted: Boolean;
    FValue: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ALatch: ILatch; AValue: Integer);
    property Started: Boolean read FStarted;
    property Value: Integer read FValue;
  end;

constructor TStartGateThread.Create(ALatch: ILatch; AValue: Integer);
begin
  inherited Create(True);
  FLatch := ALatch;
  FStarted := False;
  FValue := AValue;
  FreeOnTerminate := False;
end;

procedure TStartGateThread.Execute;
begin
  // 等待启动信号
  FLatch.Await;
  FStarted := True;
  // 模拟工作
  FValue := FValue * 2;
end;

procedure Test_Latch_StartGate;
var
  StartGate: ILatch;
  Threads: array[0..2] of TStartGateThread;
  i: Integer;
  AllStartedAfterCountDown: Boolean;
begin
  WriteLn('Test: Latch Start Gate Pattern');

  StartGate := MakeLatch(1);

  // 创建线程，它们都等待启动信号
  for i := 0 to 2 do
  begin
    Threads[i] := TStartGateThread.Create(StartGate, i + 1);
    Threads[i].Start;
  end;

  // 短暂等待确保线程都在等待
  Sleep(50);

  // 此时所有线程应该还没开始
  Assert(not Threads[0].Started and not Threads[1].Started and not Threads[2].Started,
    'Threads should not have started yet');

  // 发出启动信号
  StartGate.CountDown;

  // 等待所有线程完成
  for i := 0 to 2 do
    Threads[i].WaitFor;

  // 验证所有线程都完成了
  AllStartedAfterCountDown := True;
  for i := 0 to 2 do
  begin
    AllStartedAfterCountDown := AllStartedAfterCountDown and Threads[i].Started;
    Assert(Threads[i].Value = (i + 1) * 2,
      Format('Thread %d should have computed value %d', [i, (i + 1) * 2]));
    Threads[i].Free;
  end;

  Assert(AllStartedAfterCountDown, 'All threads should have started after CountDown');
end;

// ============================================================================
// 测试 7: 多线程场景 - 完成门控
// ============================================================================
type
  TWorkerWithLatch = class(TThread)
  private
    FDoneLatch: ILatch;
    FWorkDone: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ADoneLatch: ILatch);
    property WorkDone: Boolean read FWorkDone;
  end;

constructor TWorkerWithLatch.Create(ADoneLatch: ILatch);
begin
  inherited Create(True);
  FDoneLatch := ADoneLatch;
  FWorkDone := False;
  FreeOnTerminate := False;
end;

procedure TWorkerWithLatch.Execute;
begin
  Sleep(30);  // 模拟工作
  FWorkDone := True;
  FDoneLatch.CountDown;
end;

procedure Test_Latch_DoneGate;
var
  DoneLatch: ILatch;
  Threads: array[0..2] of TWorkerWithLatch;
  i: Integer;
  AllDone: Boolean;
begin
  WriteLn('Test: Latch Done Gate Pattern');

  DoneLatch := MakeLatch(3);  // 等待 3 个工作线程

  // 创建并启动工作线程
  for i := 0 to 2 do
  begin
    Threads[i] := TWorkerWithLatch.Create(DoneLatch);
    Threads[i].Start;
  end;

  // 等待所有工作完成
  DoneLatch.Await;

  // 验证所有线程都完成了工作
  AllDone := True;
  for i := 0 to 2 do
  begin
    AllDone := AllDone and Threads[i].WorkDone;
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  Assert(AllDone, 'All worker threads should have completed');
  Assert(DoneLatch.GetCount = 0, 'Latch count should be 0');
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  CountDownLatch Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Latch_BasicUsage;
    Test_Latch_CountDownBelowZero;
    Test_Latch_ZeroInitialCount;
    Test_Latch_AwaitTimeout;
    Test_Latch_AwaitTimeoutSuccess;
    Test_Latch_StartGate;
    Test_Latch_DoneGate;
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
