program fafafa.core.sync.parker.test;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  Parker 测试套件

  测试 Rust 风格的线程暂停/唤醒机制：
  - Park(): 暂停当前线程
  - ParkTimeout(ms): 带超时的暂停
  - Unpark(): 唤醒线程或发放许可

  关键特性：
  - Unpark 可以在 Park 之前调用（permit 机制）
  - 每个 Parker 实例绑定一个线程
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.parker;

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
// 测试 1: Unpark 在 Park 之前调用（permit 机制）
// ============================================================================
procedure Test_Parker_UnparkBeforePark;
var
  P: IParker;
  StartTime: QWord;
  Elapsed: QWord;
begin
  WriteLn('Test: Parker Unpark Before Park');

  P := MakeParker;

  // 先 Unpark（发放许可）
  P.Unpark;

  // Park 应该立即返回（消费许可）
  StartTime := GetTickCount64;
  P.Park;
  Elapsed := GetTickCount64 - StartTime;

  Assert(Elapsed < 50, 'Park should return immediately after Unpark');
end;

// ============================================================================
// 测试 2: ParkTimeout 超时
// ============================================================================
procedure Test_Parker_ParkTimeout;
var
  P: IParker;
  StartTime: QWord;
  Elapsed: QWord;
  Res: Boolean;
begin
  WriteLn('Test: Parker ParkTimeout');

  P := MakeParker;

  StartTime := GetTickCount64;
  Res := P.ParkTimeout(100);  // 等待 100ms
  Elapsed := GetTickCount64 - StartTime;

  Assert(not Res, 'ParkTimeout should return False on timeout');
  Assert(Elapsed >= 90, 'Should have waited at least 90ms');
  Assert(Elapsed < 200, 'Should not have waited more than 200ms');
end;

// ============================================================================
// 测试 3: ParkTimeout 被 Unpark 唤醒
// ============================================================================
procedure Test_Parker_ParkTimeoutWithUnpark;
var
  P: IParker;
  Res: Boolean;
begin
  WriteLn('Test: Parker ParkTimeout With Unpark');

  P := MakeParker;

  // 先 Unpark
  P.Unpark;

  // ParkTimeout 应该立即返回 True
  Res := P.ParkTimeout(1000);
  Assert(Res, 'ParkTimeout should return True when permit is available');
end;

// ============================================================================
// 测试 4: 多次 Unpark 只存储一个许可
// ============================================================================
procedure Test_Parker_MultipleUnpark;
var
  P: IParker;
  StartTime: QWord;
  Elapsed: QWord;
begin
  WriteLn('Test: Parker Multiple Unpark');

  P := MakeParker;

  // 多次 Unpark
  P.Unpark;
  P.Unpark;
  P.Unpark;

  // 第一次 Park 立即返回
  P.Park;

  // 第二次 Park 应该阻塞（因为只有一个许可）
  StartTime := GetTickCount64;
  P.ParkTimeout(50);  // 应该超时
  Elapsed := GetTickCount64 - StartTime;

  Assert(Elapsed >= 40, 'Second Park should block (no more permits)');
end;

// ============================================================================
// 测试 5: 多线程场景 - 从另一个线程 Unpark
// ============================================================================
type
  TUnparkerThread = class(TThread)
  private
    FParker: IParker;
    FDelayMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker; ADelayMs: Integer);
  end;

constructor TUnparkerThread.Create(AParker: IParker; ADelayMs: Integer);
begin
  inherited Create(True);
  FParker := AParker;
  FDelayMs := ADelayMs;
  FreeOnTerminate := False;
end;

procedure TUnparkerThread.Execute;
begin
  Sleep(FDelayMs);
  FParker.Unpark;
end;

procedure Test_Parker_CrossThreadUnpark;
var
  P: IParker;
  T: TUnparkerThread;
  StartTime: QWord;
  Elapsed: QWord;
begin
  WriteLn('Test: Parker Cross-Thread Unpark');

  P := MakeParker;

  // 启动线程，50ms 后调用 Unpark
  T := TUnparkerThread.Create(P, 50);
  T.Start;

  StartTime := GetTickCount64;
  P.Park;  // 应该在约 50ms 后被唤醒
  Elapsed := GetTickCount64 - StartTime;

  T.WaitFor;
  T.Free;

  Assert(Elapsed >= 40, 'Should have waited at least 40ms');
  Assert(Elapsed < 150, 'Should have been woken up within 150ms');
end;

// ============================================================================
// 测试 6: Parker 用于生产者-消费者模式
// ============================================================================
type
  TProducerThread = class(TThread)
  private
    FParker: IParker;
    FData: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(AParker: IParker; AData: PInteger);
  end;

constructor TProducerThread.Create(AParker: IParker; AData: PInteger);
begin
  inherited Create(True);
  FParker := AParker;
  FData := AData;
  FreeOnTerminate := False;
end;

procedure TProducerThread.Execute;
begin
  Sleep(30);
  FData^ := 42;  // 生产数据
  FParker.Unpark;  // 通知消费者
end;

procedure Test_Parker_ProducerConsumer;
var
  P: IParker;
  Producer: TProducerThread;
  Data: Integer;
begin
  WriteLn('Test: Parker Producer-Consumer Pattern');

  P := MakeParker;
  Data := 0;

  Producer := TProducerThread.Create(P, @Data);
  Producer.Start;

  // 等待生产者
  P.Park;

  Producer.WaitFor;
  Producer.Free;

  Assert(Data = 42, 'Consumer should receive data from producer');
end;

// ============================================================================
// 测试 7: 重复使用 Parker
// ============================================================================
procedure Test_Parker_Reuse;
var
  P: IParker;
  i: Integer;
begin
  WriteLn('Test: Parker Reuse');

  P := MakeParker;

  for i := 1 to 3 do
  begin
    P.Unpark;
    P.Park;
  end;

  Assert(True, 'Parker can be reused multiple times');
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Parker Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_Parker_UnparkBeforePark;
    Test_Parker_ParkTimeout;
    Test_Parker_ParkTimeoutWithUnpark;
    Test_Parker_MultipleUnpark;
    Test_Parker_CrossThreadUnpark;
    Test_Parker_ProducerConsumer;
    Test_Parker_Reuse;
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
