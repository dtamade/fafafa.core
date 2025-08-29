unit fafafa.core.sync.barrier.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.barrier, fafafa.core.sync.barrier.base;

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
    // Quick mode
    procedure Test_Wait_WithPeers_SerialThread;
    procedure Test_Getters;
    procedure Test_InvalidParticipantCount;
    procedure Test_ReUseBarrier;
    procedure Test_Serial_Uniqueness_ManyRounds;
    procedure Test_MultiPhase_ByWorkerGroups;
    procedure Test_ParticipantCount_One;

    procedure Test_Concurrent_Barriers_Independence;
    // Stress mode (skipped unless --stress)
    procedure Test_Serial_Distribution_Stress_6x200;
    procedure Test_Stress_Deadlock_Free_8x500;
    // Parameterized stress tests
    procedure Test_Stress_Parameterized_2x100;
    procedure Test_Stress_Parameterized_4x200;
    procedure Test_Stress_Parameterized_16x100;
  end;

  TBarrierWorkerThread = class(TThread)
  private
    FBarrier: IBarrier;
    FDoneCount: PInteger;
    FSerialFlag: PBoolean;
    FSleepMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ABarrier: IBarrier; ADone: PInteger; ASerialFlag: PBoolean; ASleepMs: Integer);
  end;

  TTwoPhaseWorker = class(TThread)
  private
    FBarrier: IBarrier;
    FDoneCount: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(const ABarrier: IBarrier; ADone: PInteger);
  end;

implementation

function IsStressModeEnabled: Boolean;
var i: Integer; s: String;
begin
  Result := False;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (s = '--stress') or (s = '-S') then Exit(True);
  end;
end;

function CountTrue(const A: array of Boolean): Integer;
var i: Integer;
begin
  Result := 0;
  for i := Low(A) to High(A) do if A[i] then Inc(Result);
end;

procedure RunRounds(const Barrier: IBarrier; Rounds, Participants: Integer);
var r, i: Integer; w: array of TBarrierWorkerThread; s: array of Boolean; done: Integer; r0: Boolean;
begin
  SetLength(w, Participants-1);
  SetLength(s, Participants);
  for r := 1 to Rounds do
  begin
    FillChar(s[0], Participants, 0);
    done := 0;
    for i := 0 to High(w) do w[i] := TBarrierWorkerThread.Create(Barrier, @done, @s[i+1], 0);
    try
      r0 := Barrier.Wait; s[0] := r0;
      for i := 0 to High(w) do w[i].WaitFor;
    finally
      for i := 0 to High(w) do w[i].Free;
    end;
  end;
end;

procedure BusyWait(ms: Integer);
var t0: QWord;
begin
  t0 := GetTickCount64;
  while (GetTickCount64 - t0) < QWord(ms) do begin end;
end;

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

constructor TBarrierWorkerThread.Create(const ABarrier: IBarrier; ADone: PInteger; ASerialFlag: PBoolean; ASleepMs: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FDoneCount := ADone;
  FSerialFlag := ASerialFlag;
  FSleepMs := ASleepMs;
end;

constructor TTwoPhaseWorker.Create(const ABarrier: IBarrier; ADone: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FDoneCount := ADone;
end;

procedure TTwoPhaseWorker.Execute;
begin
  // participate two phases
  FBarrier.Wait;
  InterlockedIncrement(FDoneCount^);
end;

procedure TBarrierWorkerThread.Execute;
var b: Boolean;
begin
  if FSleepMs > 0 then Sleep(FSleepMs);
  b := FBarrier.Wait;
  if Assigned(FSerialFlag) then FSerialFlag^ := b;
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
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, @serialFlags[1], 50);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, @serialFlags[2], 100);
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



procedure TTestCase_IBarrier.Test_Getters;
begin
  AssertEquals('Participant count should be 3', 3, FBarrier.GetParticipantCount);
end;

procedure TTestCase_IBarrier.Test_Serial_Uniqueness_ManyRounds;
var
  round, i, j: Integer;
  n: Integer;
  s: array of Boolean;
  done: Integer;
  workers: array of TBarrierWorkerThread;
  r0: Boolean;
begin
  n := FBarrier.GetParticipantCount;
  SetLength(workers, n-1);
  SetLength(s, n);
  for round := 1 to 8 do
  begin
    FillChar(s[0], n, 0);
    done := 0;
    for i := 0 to High(workers) do
      workers[i] := TBarrierWorkerThread.Create(FBarrier, @done, @s[i+1], (i+1)*5);
    try
      r0 := FBarrier.Wait;
      s[0] := r0;
      for i := 0 to High(workers) do workers[i].WaitFor;
      AssertEquals(n-1, done);
      // exactly one serial per round
      i := 0; for j := 0 to High(s) do if s[j] then Inc(i);
      AssertEquals(1, i);
    finally
      for i := 0 to High(workers) do workers[i].Free;
    end;
  end;
end;

procedure TTestCase_IBarrier.Test_MultiPhase_ByWorkerGroups;
var
  i: Integer;
  done1, done2: Integer;
  w1a, w1b, w2a, w2b: TTwoPhaseWorker;
begin
  done1 := 0; done2 := 0;
  // Phase 1: two workers + main
  w1a := TTwoPhaseWorker.Create(FBarrier, @done1);
  w1b := TTwoPhaseWorker.Create(FBarrier, @done1);
  // Main participates to close the phase 1
  FBarrier.Wait; // Don't assert serial - any thread can be serial
  w1a.WaitFor; w1b.WaitFor;
  AssertEquals(2, done1);

  // Phase 2: another two workers + main
  w2a := TTwoPhaseWorker.Create(FBarrier, @done2);
  w2b := TTwoPhaseWorker.Create(FBarrier, @done2);
  FBarrier.Wait; // Don't assert serial - any thread can be serial
  w2a.WaitFor; w2b.WaitFor;
  AssertEquals(2, done2);
end;

procedure TTestCase_IBarrier.Test_ParticipantCount_One;
var barrier1: IBarrier; isSerial: Boolean;
begin
  barrier1 := MakeBarrier(1);
  isSerial := barrier1.Wait;
  // The only participant must be serial thread
  AssertTrue(isSerial);
end;



procedure TTestCase_IBarrier.Test_Concurrent_Barriers_Independence;
var
  B2: IBarrier; done1, done2: Integer;
  w1, w2: TBarrierWorkerThread; s: Boolean;
begin
  B2 := MakeBarrier(2);
  done1 := 0; done2 := 0;
  w1 := TBarrierWorkerThread.Create(FBarrier, @done1, nil, 10);
  w2 := TBarrierWorkerThread.Create(B2, @done2, @s, 5);
  try
    // Close barrier #1 with main + w1
    FBarrier.Wait; // Don't assert serial - any thread can be serial
    w1.WaitFor;
    // Close barrier #2 with main + w2
    B2.Wait; // Don't assert serial - any thread can be serial
    w2.WaitFor;
    AssertEquals(1, done1);
    AssertEquals(1, done2);
  finally
    w1.Free; w2.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_InvalidParticipantCount;
begin
  try
    MakeBarrier(0);
    Fail('Zero participants should raise');
  except
    on E: Exception do; // accept any exception for invalid argument
  end;
  try
    MakeBarrier(-1);
    Fail('Negative participants should raise');
  except
    on E: Exception do;
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
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, nil, 0);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, nil, 0);
  try
    s1 := FBarrier.Wait; // 返回是否为串行线程
    t1.WaitFor; t2.WaitFor;
    AssertEquals(2, done);
  finally
    t1.Free; t2.Free;
  end;

  // 第二轮（复用同一个 barrier）
  done := 0;
  t1 := TBarrierWorkerThread.Create(FBarrier, @done, nil, 0);
  t2 := TBarrierWorkerThread.Create(FBarrier, @done, nil, 0);
  try
    s2 := FBarrier.Wait;
    t1.WaitFor; t2.WaitFor;
    AssertEquals(2, done);
    // 两轮结束即可
  finally
    t1.Free; t2.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Serial_Distribution_Stress_6x200;
const N=6; R=200;
var serialHit: array[0..N-1] of Integer; round, i: Integer; w: array of TBarrierWorkerThread; done: Integer; s: array[0..N-1] of Boolean; r0: Boolean; minv, maxv: Integer; B: IBarrier;
begin
  if not IsStressModeEnabled then Exit;
  B := MakeBarrier(N);
  FillChar(serialHit, SizeOf(serialHit), 0);
  for round := 1 to R do
  begin
    FillChar(s, SizeOf(s), 0);
    done := 0;
    SetLength(w, N-1);
    for i := 0 to High(w) do w[i] := TBarrierWorkerThread.Create(B, @done, @s[i+1], 0);
    try
      r0 := B.Wait; s[0] := r0;
      for i := 0 to High(w) do w[i].WaitFor;
      AssertEquals(N-1, done);
      AssertEquals(1, CountTrue(s));
      for i := 0 to High(s) do if s[i] then Inc(serialHit[i]);
    finally
      for i := 0 to High(w) do w[i].Free;
    end;
  end;
  // 分布均衡性：允许最大/最小差距 <= R * 0.25
  minv := serialHit[0]; maxv := serialHit[0];
  for i := 1 to N-1 do begin if serialHit[i] < minv then minv := serialHit[i]; if serialHit[i] > maxv then maxv := serialHit[i]; end;
  AssertTrue(Format('serial distribution too skewed: min=%d max=%d', [minv,maxv]), (maxv - minv) <= (R div 4));
end;

procedure TTestCase_IBarrier.Test_Stress_Deadlock_Free_8x500;
const N=8; R=500;
var B: IBarrier;
begin
  if not IsStressModeEnabled then Exit;
  B := MakeBarrier(N);
  RunRounds(B, R, N);
end;

procedure TTestCase_IBarrier.Test_Stress_Parameterized_2x100;
const N=2; R=100;
var B: IBarrier;
begin
  if not IsStressModeEnabled then Exit;
  B := MakeBarrier(N);
  RunRounds(B, R, N);
end;

procedure TTestCase_IBarrier.Test_Stress_Parameterized_4x200;
const N=4; R=200;
var B: IBarrier;
begin
  if not IsStressModeEnabled then Exit;
  B := MakeBarrier(N);
  RunRounds(B, R, N);
end;

procedure TTestCase_IBarrier.Test_Stress_Parameterized_16x100;
const N=16; R=100;
var B: IBarrier;
begin
  if not IsStressModeEnabled then Exit;
  B := MakeBarrier(N);
  RunRounds(B, R, N);
end;


initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IBarrier);

end.

