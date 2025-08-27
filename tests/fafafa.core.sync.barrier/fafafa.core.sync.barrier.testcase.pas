unit fafafa.core.sync.barrier.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.barrier, fafafa.core.sync;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeBarrier;
  end;

  // IBarrier 接口测试
  TTestCase_IBarrier = class(TTestCase)
  private
    FBarrier: IBarrier;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wait_WithPeers_SerialThread;
    procedure Test_Getters;
    procedure Test_InvalidParticipantCount;
    procedure Test_ReUseBarrier;
  end;

  TBarrierWorkerThread = class(TThread)
  private
    FBarrier: IBarrier;
    FDoneCount: PInteger;
    FSleepMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ABarrier: IBarrier; ADone: PInteger; ASleepMs: Integer);
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeBarrier;
var
  B: IBarrier;
begin
  B := MakeBarrier(2);
  AssertNotNull('MakeBarrier should return non-nil interface', B);
  AssertEquals('Participant count should match', 2, B.GetParticipantCount);
end;

{ TBarrierWorkerThread }

constructor TBarrierWorkerThread.Create(const ABarrier: IBarrier; ADone: PInteger; ASleepMs: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FDoneCount := ADone;
  FSleepMs := ASleepMs;
end;

procedure TBarrierWorkerThread.Execute;
begin
  if FSleepMs > 0 then Sleep(FSleepMs);
  FBarrier.Wait;
  InterlockedIncrement(FDoneCount^);
end;

{ TTestCase_IBarrier }

procedure TTestCase_IBarrier.SetUp;
begin
  inherited SetUp;
  FBarrier := MakeBarrier(3);
end;

procedure TTestCase_IBarrier.TearDown;
begin
  FBarrier := nil;
  inherited TearDown;
end;

procedure TTestCase_IBarrier.Test_Wait_WithPeers_SerialThread;
var
  serialFlags: array[0..2] of Boolean;
  done: Integer;
  t1, t2: TBarrierWorkerThread;
  r0: Boolean;
begin
  FillChar(serialFlags, SizeOf(serialFlags), 0);
  done := 0;
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, 50);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, 100);
  try
    r0 := FBarrier.Wait; // 主线程作为第三个参与者
    // 记录串行线程标记
    serialFlags[0] := r0;

    t1.WaitFor; t2.WaitFor;

    AssertEquals('All peers should have passed the barrier', 2, done);
    // 断言：恰有一个线程获得串行标记
    AssertTrue('Exactly one serial thread per phase', serialFlags[0] xor serialFlags[1] xor serialFlags[2]);
  finally
    t1.Free; t2.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_WithPeers;
var
  done: Integer;
  t1, t2: TBarrierWorkerThread;
begin
  done := 0;
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, 50);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, 100);
  try
    // 主线程作为第三个参与者
    AssertTrue('Barrier should pass when 3 participants arrive', FBarrier.Wait(3000));

    // 等待两个线程结束
    t1.WaitFor;
    t2.WaitFor;

    AssertEquals('All peers should have passed the barrier', 2, done);
    AssertEquals('Waiting count resets to 0 after release', 0, FBarrier.GetWaitingCount);
  finally
    t1.Free;
    t2.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Getters;
begin
  AssertEquals('Participant count should be 3', 3, FBarrier.GetParticipantCount);
end;

procedure TTestCase_IBarrier.Test_InvalidParticipantCount;
begin
  try
    MakeBarrier(0);
    Fail('Zero participants should raise');
  except
    on E: EArgumentOutOfRange do; // Back-compat alias via sync facade
    on E: EInvalidArgument do;    // Direct exception from platform/unit
  end;
  try
    MakeBarrier(-1);
    Fail('Negative participants should raise');
  except
    on E: EArgumentOutOfRange do;
    on E: EInvalidArgument do;
  end;
end;

procedure TTestCase_IBarrier.Test_ReUseBarrier;
var
  s1, s2: Boolean;
  done: Integer;
  t1, t2: TBarrierWorkerThread;
begin
  // 第一轮
  done := 0;
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, 0);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, 0);
  try
    s1 := FBarrier.Wait; // 返回是否为串行线程
    t1.WaitFor; t2.WaitFor;
    AssertEquals(2, done);
  finally
    t1.Free; t2.Free;
  end;

  // 第二轮（复用同一个 barrier）
  done := 0;
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, 0);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, 0);
  try
    s2 := FBarrier.Wait;
    t1.WaitFor; t2.WaitFor;
    AssertEquals(2, done);
    // 两轮结束即可
  finally
    t1.Free; t2.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IBarrier);

end.

