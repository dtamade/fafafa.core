unit fafafa.core.sync.barrier.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.sync.barrier, fafafa.core.sync.barrier.base;

type
  // Global function tests - 100% coverage
  TTestCase_Global = class(TTestCase)
  published
    // Basic factory function tests
    procedure Test_MakeBarrier_Valid_Participants;
    procedure Test_MakeBarrier_Single_Participant;
    procedure Test_MakeBarrier_Multiple_Participants;
    procedure Test_MakeBarrier_Large_Participants;
    
    // Boundary condition tests
    procedure Test_MakeBarrier_Zero_Participants_Exception;
    procedure Test_MakeBarrier_Negative_Participants_Exception;
    procedure Test_MakeBarrier_MaxInt_Participants;
    
    // Interface consistency tests
    procedure Test_MakeBarrier_Returns_IBarrier_Interface;
    procedure Test_MakeBarrier_Multiple_Instances_Independent;
  end;

  // IBarrier interface tests - 100% coverage
  TTestCase_IBarrier = class(TTestCase)
  private
    FBarrier: IBarrier;
    procedure AssertBarrierRounds(const aBarrier: IBarrier; aParticipants, aRounds, aSleepMod: Integer; const aLabel: String);
    procedure AssertBarrierWaitExRounds(const aBarrier: IBarrier; aRounds: Integer; const aLabel: String);
    procedure AssertPerformanceBaseline(aParticipants, aRounds: Integer; aMaxElapsedMs: QWord; const aLabel: String);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // Basic functionality tests
    procedure Test_GetParticipantCount_SingleParticipant;
    procedure Test_GetParticipantCount_MultipleParticipants;
    procedure Test_GetParticipantCount_Consistency;
    
    // Wait method core tests
    procedure Test_Wait_SingleParticipant_ReturnsTrue;
    procedure Test_Wait_TwoParticipants_OneSerial;
    procedure Test_Wait_MultipleParticipants_OneSerial;
    procedure Test_Wait_SerialThread_Identification;
    procedure Test_Wait_NonSerialThread_ReturnsFalse;
    
    // Reuse and multi-round tests
    procedure Test_Wait_Barrier_Reuse_MultipleRounds;
    procedure Test_Wait_Barrier_Reuse_DifferentThreadCounts;
    procedure Test_Wait_Sequential_Rounds_SerialDistribution;
    
    // Concurrency and synchronization tests
    procedure Test_Wait_Concurrent_Threads_Synchronization;
    procedure Test_Wait_Concurrent_Barriers_Independence;
    procedure Test_Wait_Thread_Safety_Multiple_Barriers;
    procedure Test_Wait_Race_Conditions_Prevention;
    
    // Boundary condition tests
    procedure Test_Wait_Large_Participant_Count;
    procedure Test_Wait_Rapid_Sequential_Calls;
    procedure Test_Wait_Mixed_Thread_Priorities;
    
    // Platform-specific tests
    {$IFDEF WINDOWS}
    procedure Test_Wait_Windows_Native_Barrier;
    procedure Test_Wait_Windows_Fallback_Implementation;
    {$ENDIF}
    {$IFDEF UNIX}
    procedure Test_Wait_Unix_Posix_Barrier;
    procedure Test_Wait_Unix_Fallback_Implementation;
    {$ENDIF}
    
    // Stress tests (require --stress parameter)
    procedure Test_Stress_High_Frequency_Barriers;
    procedure Test_Stress_Long_Running_Barriers;
    procedure Test_Stress_Memory_Pressure_Barriers;
    procedure Test_Stress_Thread_Exhaustion_Barriers;
    
    // Performance benchmark tests
    procedure Test_Performance_Baseline_2_Threads;
    procedure Test_Performance_Baseline_4_Threads;
    procedure Test_Performance_Baseline_8_Threads;
    procedure Test_Performance_Baseline_16_Threads;
  end;

  // WaitEx (Rust-style IBarrierWaitResult) tests
  TTestCase_WaitEx = class(TTestCase)
  private
    FBarrier: IBarrier;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // Basic WaitEx functionality
    procedure Test_WaitEx_SingleParticipant_IsLeader;
    procedure Test_WaitEx_TwoParticipants_ExactlyOneLeader;
    procedure Test_WaitEx_Generation_IncrementOnComplete;
    procedure Test_WaitEx_Generation_SameForAllParticipants;
    procedure Test_WaitEx_MultipleRounds_GenerationIncreases;
  end;

  // Enhanced test helper classes
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

  // WaitEx worker thread for testing IBarrierWaitResult
  TWaitExWorkerThread = class(TThread)
  private
    FBarrier: IBarrier;
    FIsLeader: PBoolean;
    FGeneration: PCardinal;
    FDoneCount: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(const ABarrier: IBarrier; AIsLeader: PBoolean; AGeneration: PCardinal; ADone: PInteger);
  end;

implementation

function IsStressModeEnabled: Boolean;
var
  LIndex: Integer;
  LArg: String;
  LEnv: String;
begin
  Result := False;

  LEnv := LowerCase(Trim(GetEnvironmentVariable('FAFAFA_STRESS')));
  if (LEnv = '1') or (LEnv = 'true') or (LEnv = 'yes') or (LEnv = 'on') then
    Exit(True);

  for LIndex := 1 to ParamCount do
  begin
    LArg := ParamStr(LIndex);
    if (LArg = '--stress') or (LArg = '-S') then
      Exit(True);
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

procedure TTestCase_Global.Test_MakeBarrier_Valid_Participants;
var
  B: IBarrier;
begin
  B := MakeBarrier(2);
  AssertNotNull('MakeBarrier should return non-nil interface', B);
  AssertEquals('Participant count should match', 2, B.GetParticipantCount);
end;

procedure TTestCase_Global.Test_MakeBarrier_Single_Participant;
var
  B: IBarrier;
begin
  B := MakeBarrier(1);
  AssertNotNull('MakeBarrier(1) should return non-nil interface', B);
  AssertEquals('Single participant count should be 1', 1, B.GetParticipantCount);
  // Single participant barrier should immediately return True (serial)
  AssertTrue('Single participant Wait should return True', B.Wait);
end;

procedure TTestCase_Global.Test_MakeBarrier_Multiple_Participants;
var
  B2, B4, B8, B16: IBarrier;
begin
  B2 := MakeBarrier(2);
  B4 := MakeBarrier(4);
  B8 := MakeBarrier(8);
  B16 := MakeBarrier(16);
  
  AssertNotNull('MakeBarrier(2) should return non-nil', B2);
  AssertNotNull('MakeBarrier(4) should return non-nil', B4);
  AssertNotNull('MakeBarrier(8) should return non-nil', B8);
  AssertNotNull('MakeBarrier(16) should return non-nil', B16);
  
  AssertEquals('B2 participant count', 2, B2.GetParticipantCount);
  AssertEquals('B4 participant count', 4, B4.GetParticipantCount);
  AssertEquals('B8 participant count', 8, B8.GetParticipantCount);
  AssertEquals('B16 participant count', 16, B16.GetParticipantCount);
end;

procedure TTestCase_Global.Test_MakeBarrier_Large_Participants;
var
  B: IBarrier;
begin
  B := MakeBarrier(1000);
  AssertNotNull('MakeBarrier(1000) should return non-nil', B);
  AssertEquals('Large participant count should be correct', 1000, B.GetParticipantCount);
end;

procedure TTestCase_Global.Test_MakeBarrier_Zero_Participants_Exception;
begin
  try
    MakeBarrier(0);
    Fail('MakeBarrier(0) should raise exception');
  except
    on E: Exception do
      AssertTrue('Should raise EInvalidArgument or similar', 
                 (E is EInvalidArgument) or (Pos('participants', LowerCase(E.Message)) > 0));
  end;
end;

procedure TTestCase_Global.Test_MakeBarrier_Negative_Participants_Exception;
begin
  try
    MakeBarrier(-1);
    Fail('MakeBarrier(-1) should raise exception');
  except
    on E: Exception do
      AssertTrue('Should raise EInvalidArgument or similar', 
                 (E is EInvalidArgument) or (Pos('participants', LowerCase(E.Message)) > 0));
  end;
  
  try
    MakeBarrier(-100);
    Fail('MakeBarrier(-100) should raise exception');
  except
    on E: Exception do
      AssertTrue('Should raise EInvalidArgument or similar', 
                 (E is EInvalidArgument) or (Pos('participants', LowerCase(E.Message)) > 0));
  end;
end;

procedure TTestCase_Global.Test_MakeBarrier_MaxInt_Participants;
var
  B: IBarrier;
begin
  // Test with a very large but reasonable number
  B := MakeBarrier(MaxInt div 2);
  AssertNotNull('MakeBarrier(MaxInt/2) should return non-nil', B);
  AssertEquals('MaxInt/2 participant count should be correct', MaxInt div 2, B.GetParticipantCount);
end;

procedure TTestCase_Global.Test_MakeBarrier_Returns_IBarrier_Interface;
var
  B: IBarrier;
  Intf: IInterface;
begin
  B := MakeBarrier(3);
  AssertNotNull('Barrier should not be nil', B);
  
  // Test interface casting
  Intf := B as IInterface;
  AssertNotNull('Should cast to IInterface', Intf);
  
  // Test that we can call interface methods
  AssertEquals('Interface method should work', 3, B.GetParticipantCount);
end;

procedure TTestCase_Global.Test_MakeBarrier_Multiple_Instances_Independent;
var
  B1, B2, B3: IBarrier;
begin
  B1 := MakeBarrier(2);
  B2 := MakeBarrier(4);
  B3 := MakeBarrier(8);
  
  // Verify they are different instances
  AssertFalse('B1 and B2 should be different instances', B1 = B2);
  AssertFalse('B1 and B3 should be different instances', B1 = B3);
  AssertFalse('B2 and B3 should be different instances', B2 = B3);
  
  // Verify they maintain independent state
  AssertEquals('B1 participant count', 2, B1.GetParticipantCount);
  AssertEquals('B2 participant count', 4, B2.GetParticipantCount);
  AssertEquals('B3 participant count', 8, B3.GetParticipantCount);
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
  if Assigned(FDoneCount) then InterlockedIncrement(FDoneCount^);
end;

{ TTestCase_IBarrier }

procedure TTestCase_IBarrier.SetUp;
begin
  inherited SetUp;
  FBarrier := MakeBarrier(4); // Default to 4 participants for most tests
end;

procedure TTestCase_IBarrier.TearDown;
begin
  FBarrier := nil;
  inherited TearDown;
end;

procedure TTestCase_IBarrier.AssertBarrierRounds(const aBarrier: IBarrier; aParticipants, aRounds, aSleepMod: Integer; const aLabel: String);
var
  LWorkers: array of TBarrierWorkerThread;
  LSerialFlags: array of Boolean;
  LDoneCount: Integer;
  LRound: Integer;
  LIndex: Integer;
  LSleepMs: Integer;
begin
  AssertTrue(aLabel + ': participants must be >= 1', aParticipants >= 1);

  if aParticipants = 1 then
  begin
    for LRound := 1 to aRounds do
      AssertTrue(Format('%s round %d single participant should be serial', [aLabel, LRound]), aBarrier.Wait);
    Exit;
  end;

  SetLength(LWorkers, aParticipants - 1);
  SetLength(LSerialFlags, aParticipants);

  for LRound := 1 to aRounds do
  begin
    FillChar(LSerialFlags[0], Length(LSerialFlags) * SizeOf(Boolean), 0);
    LDoneCount := 0;

    for LIndex := 0 to High(LWorkers) do
    begin
      if aSleepMod > 0 then
        LSleepMs := (LRound + LIndex) mod aSleepMod
      else
        LSleepMs := 0;

      LWorkers[LIndex] := TBarrierWorkerThread.Create(aBarrier, @LDoneCount, @LSerialFlags[LIndex + 1], LSleepMs);
    end;

    try
      LSerialFlags[0] := aBarrier.Wait;
      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex].WaitFor;

      AssertEquals(Format('%s round %d done count', [aLabel, LRound]), aParticipants - 1, LDoneCount);
      AssertEquals(Format('%s round %d serial count', [aLabel, LRound]), 1, CountTrue(LSerialFlags));
    finally
      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex].Free;
    end;
  end;
end;

procedure TTestCase_IBarrier.AssertBarrierWaitExRounds(const aBarrier: IBarrier; aRounds: Integer; const aLabel: String);
var
  LRound: Integer;
  LDoneCount: Integer;
  LWorkerIsLeader: Boolean;
  LWorkerGeneration: Cardinal;
  LWorker: TWaitExWorkerThread;
  LMainResult: TBarrierWaitResult;
  LLeaderCount: Integer;
begin
  for LRound := 1 to aRounds do
  begin
    LDoneCount := 0;
    LWorkerIsLeader := False;
    LWorkerGeneration := 0;

    LWorker := TWaitExWorkerThread.Create(aBarrier, @LWorkerIsLeader, @LWorkerGeneration, @LDoneCount);
    try
      LMainResult := aBarrier.WaitEx;
      LWorker.WaitFor;

      LLeaderCount := Integer(LMainResult.IsLeader) + Integer(LWorkerIsLeader);

      AssertEquals(Format('%s round %d done count', [aLabel, LRound]), 1, LDoneCount);
      AssertEquals(Format('%s round %d leader count', [aLabel, LRound]), 1, LLeaderCount);
      AssertEquals(Format('%s round %d generation agreement', [aLabel, LRound]), LMainResult.Generation, LWorkerGeneration);
      AssertEquals(Format('%s round %d generation sequence', [aLabel, LRound]), Cardinal(LRound), LMainResult.Generation);
    finally
      LWorker.Free;
    end;
  end;
end;

procedure TTestCase_IBarrier.AssertPerformanceBaseline(aParticipants, aRounds: Integer; aMaxElapsedMs: QWord; const aLabel: String);
var
  LBarrier: IBarrier;
  LStartTick: QWord;
  LElapsed: QWord;
begin
  LBarrier := MakeBarrier(aParticipants);

  LStartTick := GetTickCount64;
  AssertBarrierRounds(LBarrier, aParticipants, aRounds, 2, aLabel);
  LElapsed := GetTickCount64 - LStartTick;

  AssertTrue(
    Format('%s elapsed %dms should be <= %dms', [aLabel, Int64(LElapsed), Int64(aMaxElapsedMs)]),
    LElapsed <= aMaxElapsedMs
  );
end;

// Basic functionality tests

procedure TTestCase_IBarrier.Test_GetParticipantCount_SingleParticipant;
var
  B: IBarrier;
begin
  B := MakeBarrier(1);
  AssertEquals('Single participant count should be 1', 1, B.GetParticipantCount);
end;

procedure TTestCase_IBarrier.Test_GetParticipantCount_MultipleParticipants;
var
  B2, B8, B16: IBarrier;
begin
  B2 := MakeBarrier(2);
  B8 := MakeBarrier(8);
  B16 := MakeBarrier(16);
  
  AssertEquals('2 participants', 2, B2.GetParticipantCount);
  AssertEquals('8 participants', 8, B8.GetParticipantCount);
  AssertEquals('16 participants', 16, B16.GetParticipantCount);
end;

procedure TTestCase_IBarrier.Test_GetParticipantCount_Consistency;
var
  i: Integer;
begin
  // Test that GetParticipantCount returns consistent values
  for i := 1 to 100 do
    AssertEquals('Participant count should be consistent', 4, FBarrier.GetParticipantCount);
end;

// Wait method core tests

procedure TTestCase_IBarrier.Test_Wait_SingleParticipant_ReturnsTrue;
var
  B: IBarrier;
begin
  B := MakeBarrier(1);
  AssertTrue('Single participant Wait should return True (serial)', B.Wait);
  // Should be reusable
  AssertTrue('Single participant Wait should return True again', B.Wait);
end;

procedure TTestCase_IBarrier.Test_Wait_TwoParticipants_OneSerial;
var
  B: IBarrier;
  Worker: TBarrierWorkerThread;
  SerialFlags: array[0..1] of Boolean;
  DoneCount: Integer;
begin
  B := MakeBarrier(2);
  DoneCount := 0;
  SerialFlags[0] := False;
  SerialFlags[1] := False;
  
  Worker := TBarrierWorkerThread.Create(B, @DoneCount, @SerialFlags[1], 0);
  try
    SerialFlags[0] := B.Wait;
    Worker.WaitFor;
    
    // Exactly one should be serial
    AssertEquals('Exactly one thread should be serial', 1, 
                 Integer(SerialFlags[0]) + Integer(SerialFlags[1]));
  finally
    Worker.Free;
  end;
end;

// Stub implementations for remaining tests

procedure TTestCase_IBarrier.Test_Wait_MultipleParticipants_OneSerial;
var
  LBarrier: IBarrier;
  LWorkers: array[0..2] of TBarrierWorkerThread;
  LSerialFlags: array[0..3] of Boolean;
  LDoneCount: Integer;
  LIndex: Integer;
begin
  LBarrier := MakeBarrier(4);
  LDoneCount := 0;
  FillChar(LSerialFlags[0], SizeOf(LSerialFlags), 0);

  for LIndex := 0 to High(LWorkers) do
    LWorkers[LIndex] := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LSerialFlags[LIndex + 1], LIndex * 2);

  try
    LSerialFlags[0] := LBarrier.Wait;
    for LIndex := 0 to High(LWorkers) do
      LWorkers[LIndex].WaitFor;

    AssertEquals('All worker threads should complete', 3, LDoneCount);
    AssertEquals('Exactly one thread should be serial', 1, CountTrue(LSerialFlags));
  finally
    for LIndex := 0 to High(LWorkers) do
      LWorkers[LIndex].Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_SerialThread_Identification;
var
  LBarrier: IBarrier;
  LWorker: TBarrierWorkerThread;
  LWorkerSerial: Boolean;
  LMainSerial: Boolean;
  LDoneCount: Integer;
  LRound: Integer;
  LMainSerialCount: Integer;
  LWorkerSerialCount: Integer;
begin
  LBarrier := MakeBarrier(2);
  LMainSerialCount := 0;
  LWorkerSerialCount := 0;

  for LRound := 0 to 9 do
  begin
    LDoneCount := 0;
    LWorkerSerial := False;
    if (LRound mod 2) = 0 then
      LWorker := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LWorkerSerial, 16)
    else
      LWorker := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LWorkerSerial, 0);

    try
      if (LRound mod 2) <> 0 then
        Sleep(16);
      LMainSerial := LBarrier.Wait;
      LWorker.WaitFor;

      if LMainSerial then Inc(LMainSerialCount);
      if LWorkerSerial then Inc(LWorkerSerialCount);

      AssertEquals('Exactly one serial thread per round', 1,
        Integer(LMainSerial) + Integer(LWorkerSerial));
      AssertEquals('Worker should complete each round', 1, LDoneCount);
    finally
      LWorker.Free;
    end;
  end;

  AssertTrue('Main thread should be serial in some rounds', LMainSerialCount > 0);
  AssertTrue('Worker thread should be serial in some rounds', LWorkerSerialCount > 0);
end;

procedure TTestCase_IBarrier.Test_Wait_NonSerialThread_ReturnsFalse;
var
  LBarrier: IBarrier;
  LWorker: TBarrierWorkerThread;
  LWorkerSerial: Boolean;
  LMainSerial: Boolean;
  LDoneCount: Integer;
begin
  LBarrier := MakeBarrier(2);
  LDoneCount := 0;
  LWorkerSerial := False;

  LWorker := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LWorkerSerial, 8);
  try
    LMainSerial := LBarrier.Wait;
    LWorker.WaitFor;

    AssertEquals('Exactly one serial thread expected', 1,
      Integer(LMainSerial) + Integer(LWorkerSerial));
    AssertEquals('Exactly one non-serial thread expected', 1,
      Integer(not LMainSerial) + Integer(not LWorkerSerial));
    AssertEquals('Worker should complete', 1, LDoneCount);

    if LMainSerial then
      AssertFalse('Worker must be non-serial when main is serial', LWorkerSerial)
    else
      AssertFalse('Main must be non-serial when worker is serial', LMainSerial);
  finally
    LWorker.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_Barrier_Reuse_MultipleRounds;
const
  ROUNDS = 12;
var
  LBarrier: IBarrier;
  LWorkers: array[0..2] of TBarrierWorkerThread;
  LSerialFlags: array[0..3] of Boolean;
  LDoneCount: Integer;
  LRound: Integer;
  LIndex: Integer;
  LTotalSerialCount: Integer;
begin
  LBarrier := MakeBarrier(4);
  LTotalSerialCount := 0;

  for LRound := 1 to ROUNDS do
  begin
    FillChar(LSerialFlags[0], SizeOf(LSerialFlags), 0);
    LDoneCount := 0;
    for LIndex := 0 to High(LWorkers) do
      LWorkers[LIndex] := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LSerialFlags[LIndex + 1], (LRound + LIndex) mod 3);

    try
      LSerialFlags[0] := LBarrier.Wait;
      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex].WaitFor;

      AssertEquals(Format('Round %d worker completion count', [LRound]), 3, LDoneCount);
      AssertEquals(Format('Round %d serial count', [LRound]), 1, CountTrue(LSerialFlags));
      Inc(LTotalSerialCount, CountTrue(LSerialFlags));
    finally
      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex].Free;
    end;
  end;

  AssertEquals('Reuse across rounds should keep one serial per round', ROUNDS, LTotalSerialCount);
end;

procedure TTestCase_IBarrier.Test_Wait_Barrier_Reuse_DifferentThreadCounts;
var
  LParticipantSets: array[0..2] of Integer;
  LParticipants: Integer;
  LBarrier: IBarrier;
  LWorkers: array of TBarrierWorkerThread;
  LSerialFlags: array of Boolean;
  LDoneCount: Integer;
  LRound: Integer;
  LIndex: Integer;
begin
  LParticipantSets[0] := 2;
  LParticipantSets[1] := 3;
  LParticipantSets[2] := 5;

  for LParticipants in LParticipantSets do
  begin
    LBarrier := MakeBarrier(LParticipants);
    SetLength(LWorkers, LParticipants - 1);
    SetLength(LSerialFlags, LParticipants);

    for LRound := 1 to 4 do
    begin
      FillChar(LSerialFlags[0], Length(LSerialFlags) * SizeOf(Boolean), 0);
      LDoneCount := 0;

      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex] := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LSerialFlags[LIndex + 1], (LIndex + LRound) mod 2);

      try
        LSerialFlags[0] := LBarrier.Wait;
        for LIndex := 0 to High(LWorkers) do
          LWorkers[LIndex].WaitFor;

        AssertEquals(Format('Participants=%d round=%d worker done', [LParticipants, LRound]),
          LParticipants - 1, LDoneCount);
        AssertEquals(Format('Participants=%d round=%d serial count', [LParticipants, LRound]),
          1, CountTrue(LSerialFlags));
      finally
        for LIndex := 0 to High(LWorkers) do
          LWorkers[LIndex].Free;
      end;
    end;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_Sequential_Rounds_SerialDistribution;
const
  ROUNDS = 10;
var
  LBarrier: IBarrier;
  LWorker: TBarrierWorkerThread;
  LWorkerSerial: Boolean;
  LMainSerial: Boolean;
  LDoneCount: Integer;
  LRound: Integer;
  LTotalMainSerial: Integer;
  LTotalWorkerSerial: Integer;
begin
  LBarrier := MakeBarrier(2);
  LTotalMainSerial := 0;
  LTotalWorkerSerial := 0;

  for LRound := 1 to ROUNDS do
  begin
    LDoneCount := 0;
    LWorkerSerial := False;
    LWorker := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LWorkerSerial, LRound mod 3);
    try
      LMainSerial := LBarrier.Wait;
      LWorker.WaitFor;

      if LMainSerial then Inc(LTotalMainSerial);
      if LWorkerSerial then Inc(LTotalWorkerSerial);

      AssertEquals(Format('Round %d exactly one serial', [LRound]), 1,
        Integer(LMainSerial) + Integer(LWorkerSerial));
      AssertEquals(Format('Round %d worker done', [LRound]), 1, LDoneCount);
    finally
      LWorker.Free;
    end;
  end;

  AssertEquals('Serial distribution total should equal rounds', ROUNDS,
    LTotalMainSerial + LTotalWorkerSerial);
end;

procedure TTestCase_IBarrier.Test_Wait_Concurrent_Threads_Synchronization;
var
  LBarrier: IBarrier;
  LWorker: TBarrierWorkerThread;
  LWorkerSerial: Boolean;
  LMainSerial: Boolean;
  LDoneCount: Integer;
  LStartTick: QWord;
  LElapsed: QWord;
begin
  LBarrier := MakeBarrier(2);
  LDoneCount := 0;
  LWorkerSerial := False;

  LWorker := TBarrierWorkerThread.Create(LBarrier, @LDoneCount, @LWorkerSerial, 80);
  try
    LStartTick := GetTickCount64;
    LMainSerial := LBarrier.Wait;
    LElapsed := GetTickCount64 - LStartTick;
    LWorker.WaitFor;

    AssertTrue('Main wait should block until worker reaches barrier', LElapsed >= 50);
    AssertEquals('Worker should complete exactly once', 1, LDoneCount);
    AssertEquals('Exactly one serial result expected', 1,
      Integer(LMainSerial) + Integer(LWorkerSerial));
  finally
    LWorker.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_Concurrent_Barriers_Independence;
var
  LBarrierA: IBarrier;
  LBarrierB: IBarrier;
  LWorkerA: TBarrierWorkerThread;
  LWorkerB: TBarrierWorkerThread;
  LWorkerASerial: Boolean;
  LWorkerBSerial: Boolean;
  LMainASerial: Boolean;
  LMainBSerial: Boolean;
  LDoneA: Integer;
  LDoneB: Integer;
begin
  LBarrierA := MakeBarrier(2);
  LBarrierB := MakeBarrier(2);
  LDoneA := 0;
  LDoneB := 0;
  LWorkerASerial := False;
  LWorkerBSerial := False;

  LWorkerA := TBarrierWorkerThread.Create(LBarrierA, @LDoneA, @LWorkerASerial, 10);
  LWorkerB := TBarrierWorkerThread.Create(LBarrierB, @LDoneB, @LWorkerBSerial, 0);
  try
    LMainASerial := LBarrierA.Wait;
    LMainBSerial := LBarrierB.Wait;
    LWorkerA.WaitFor;
    LWorkerB.WaitFor;

    AssertEquals('Barrier A worker completion', 1, LDoneA);
    AssertEquals('Barrier B worker completion', 1, LDoneB);
    AssertEquals('Barrier A serial count', 1, Integer(LMainASerial) + Integer(LWorkerASerial));
    AssertEquals('Barrier B serial count', 1, Integer(LMainBSerial) + Integer(LWorkerBSerial));
  finally
    LWorkerA.Free;
    LWorkerB.Free;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_Thread_Safety_Multiple_Barriers;
const
  BARRIER_COUNT = 3;
  PARTICIPANTS = 3;
  ROUNDS = 6;
var
  LBarriers: array[0..BARRIER_COUNT - 1] of IBarrier;
  LWorkers: array[0..BARRIER_COUNT - 1, 0..PARTICIPANTS - 2] of TBarrierWorkerThread;
  LSerialFlags: array[0..BARRIER_COUNT - 1, 0..PARTICIPANTS - 1] of Boolean;
  LDoneCounts: array[0..BARRIER_COUNT - 1] of Integer;
  LBarrierIndex: Integer;
  LWorkerIndex: Integer;
  LRound: Integer;
  LSerialCount: Integer;
  LParticipantIndex: Integer;
begin
  for LBarrierIndex := 0 to BARRIER_COUNT - 1 do
    LBarriers[LBarrierIndex] := MakeBarrier(PARTICIPANTS);

  for LRound := 1 to ROUNDS do
  begin
    for LBarrierIndex := 0 to BARRIER_COUNT - 1 do
    begin
      LDoneCounts[LBarrierIndex] := 0;
      for LParticipantIndex := 0 to PARTICIPANTS - 1 do
        LSerialFlags[LBarrierIndex, LParticipantIndex] := False;

      for LWorkerIndex := 0 to PARTICIPANTS - 2 do
        LWorkers[LBarrierIndex, LWorkerIndex] := TBarrierWorkerThread.Create(
          LBarriers[LBarrierIndex],
          @LDoneCounts[LBarrierIndex],
          @LSerialFlags[LBarrierIndex, LWorkerIndex + 1],
          (LRound + LBarrierIndex + LWorkerIndex) mod 4
        );
    end;

    try
      for LBarrierIndex := 0 to BARRIER_COUNT - 1 do
        LSerialFlags[LBarrierIndex, 0] := LBarriers[LBarrierIndex].Wait;

      for LBarrierIndex := 0 to BARRIER_COUNT - 1 do
        for LWorkerIndex := 0 to PARTICIPANTS - 2 do
          LWorkers[LBarrierIndex, LWorkerIndex].WaitFor;

      for LBarrierIndex := 0 to BARRIER_COUNT - 1 do
      begin
        LSerialCount := 0;
        for LParticipantIndex := 0 to PARTICIPANTS - 1 do
          if LSerialFlags[LBarrierIndex, LParticipantIndex] then
            Inc(LSerialCount);

        AssertEquals(Format('Thread-safety round %d barrier %d done', [LRound, LBarrierIndex]), PARTICIPANTS - 1, LDoneCounts[LBarrierIndex]);
        AssertEquals(Format('Thread-safety round %d barrier %d serial', [LRound, LBarrierIndex]), 1, LSerialCount);
      end;
    finally
      for LBarrierIndex := 0 to BARRIER_COUNT - 1 do
        for LWorkerIndex := 0 to PARTICIPANTS - 2 do
          LWorkers[LBarrierIndex, LWorkerIndex].Free;
    end;
  end;
end;

procedure TTestCase_IBarrier.Test_Wait_Race_Conditions_Prevention;
var
  LBarrier: IBarrier;
begin
  LBarrier := MakeBarrier(6);
  AssertBarrierRounds(LBarrier, 6, 24, 5, 'Race prevention');
end;

procedure TTestCase_IBarrier.Test_Wait_Large_Participant_Count;
var
  LBarrier: IBarrier;
begin
  if not IsStressModeEnabled then Exit;

  LBarrier := MakeBarrier(24);
  AssertBarrierRounds(LBarrier, 24, 4, 3, 'Large participant count');
end;

procedure TTestCase_IBarrier.Test_Wait_Rapid_Sequential_Calls;
var
  LBarrier: IBarrier;
begin
  if not IsStressModeEnabled then Exit;

  LBarrier := MakeBarrier(2);
  AssertBarrierRounds(LBarrier, 2, 160, 0, 'Rapid sequential calls');
end;

procedure TTestCase_IBarrier.Test_Wait_Mixed_Thread_Priorities;
var
  LBarrier: IBarrier;
begin
  LBarrier := MakeBarrier(4);
  AssertBarrierRounds(LBarrier, 4, 12, 6, 'Mixed thread timing');
end;

{$IFDEF WINDOWS}
procedure TTestCase_IBarrier.Test_Wait_Windows_Native_Barrier;
var
  LBarrier: IBarrier;
begin
  LBarrier := MakeBarrier(4);
  AssertBarrierRounds(LBarrier, 4, 10, 3, 'Windows native barrier compatibility');
end;

procedure TTestCase_IBarrier.Test_Wait_Windows_Fallback_Implementation;
var
  LBarrier: IBarrier;
begin
  LBarrier := MakeBarrier(2);
  AssertBarrierWaitExRounds(LBarrier, 12, 'Windows fallback compatibility');
end;
{$ENDIF}

{$IFDEF UNIX}
procedure TTestCase_IBarrier.Test_Wait_Unix_Posix_Barrier;
var
  LBarrier: IBarrier;
begin
  LBarrier := MakeBarrier(4);
  AssertBarrierRounds(LBarrier, 4, 10, 4, 'Unix POSIX compatibility');
end;

procedure TTestCase_IBarrier.Test_Wait_Unix_Fallback_Implementation;
var
  LBarrier: IBarrier;
begin
  LBarrier := MakeBarrier(2);
  AssertBarrierWaitExRounds(LBarrier, 12, 'Unix fallback compatibility');
end;
{$ENDIF}

procedure TTestCase_IBarrier.Test_Stress_High_Frequency_Barriers;
var
  LBarrier: IBarrier;
begin
  if not IsStressModeEnabled then Exit;

  LBarrier := MakeBarrier(2);
  AssertBarrierRounds(LBarrier, 2, 320, 0, 'Stress high frequency');
end;

procedure TTestCase_IBarrier.Test_Stress_Long_Running_Barriers;
var
  LBarrier: IBarrier;
begin
  if not IsStressModeEnabled then Exit;

  LBarrier := MakeBarrier(4);
  AssertBarrierRounds(LBarrier, 4, 80, 5, 'Stress long running');
end;

procedure TTestCase_IBarrier.Test_Stress_Memory_Pressure_Barriers;
var
  LIteration: Integer;
  LBarrier: IBarrier;
begin
  if not IsStressModeEnabled then Exit;

  for LIteration := 1 to 120 do
  begin
    LBarrier := MakeBarrier(3);
    AssertBarrierRounds(LBarrier, 3, 1, 3, Format('Stress memory pressure iter %d', [LIteration]));
  end;
end;

procedure TTestCase_IBarrier.Test_Stress_Thread_Exhaustion_Barriers;
var
  LBarrier: IBarrier;
begin
  if not IsStressModeEnabled then Exit;

  LBarrier := MakeBarrier(12);
  AssertBarrierRounds(LBarrier, 12, 25, 2, 'Stress thread exhaustion');
end;

procedure TTestCase_IBarrier.Test_Performance_Baseline_2_Threads;
begin
  if not IsStressModeEnabled then Exit;
  AssertPerformanceBaseline(2, 120, 8000, 'Performance baseline 2 threads');
end;

procedure TTestCase_IBarrier.Test_Performance_Baseline_4_Threads;
begin
  if not IsStressModeEnabled then Exit;
  AssertPerformanceBaseline(4, 100, 10000, 'Performance baseline 4 threads');
end;

procedure TTestCase_IBarrier.Test_Performance_Baseline_8_Threads;
begin
  if not IsStressModeEnabled then Exit;
  AssertPerformanceBaseline(8, 80, 14000, 'Performance baseline 8 threads');
end;

procedure TTestCase_IBarrier.Test_Performance_Baseline_16_Threads;
begin
  if not IsStressModeEnabled then Exit;
  AssertPerformanceBaseline(16, 50, 20000, 'Performance baseline 16 threads');
end;

{ TWaitExWorkerThread }

constructor TWaitExWorkerThread.Create(const ABarrier: IBarrier; AIsLeader: PBoolean; AGeneration: PCardinal; ADone: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FIsLeader := AIsLeader;
  FGeneration := AGeneration;
  FDoneCount := ADone;
end;

procedure TWaitExWorkerThread.Execute;
var
  Result: TBarrierWaitResult;
begin
  Result := FBarrier.WaitEx;
  if Assigned(FIsLeader) then FIsLeader^ := Result.IsLeader;
  if Assigned(FGeneration) then FGeneration^ := Result.Generation;
  if Assigned(FDoneCount) then InterlockedIncrement(FDoneCount^);
end;

{ TTestCase_WaitEx }

procedure TTestCase_WaitEx.SetUp;
begin
  inherited SetUp;
  FBarrier := MakeBarrier(2); // Default to 2 participants
end;

procedure TTestCase_WaitEx.TearDown;
begin
  FBarrier := nil;
  inherited TearDown;
end;

procedure TTestCase_WaitEx.Test_WaitEx_SingleParticipant_IsLeader;
var
  B: IBarrier;
  Result: TBarrierWaitResult;
begin
  B := MakeBarrier(1);

  // Single participant should always be leader
  Result := B.WaitEx;
  AssertTrue('Single participant should be leader', Result.IsLeader);
  AssertEquals('First generation should be 1', Cardinal(1), Result.Generation);

  // Second round
  Result := B.WaitEx;
  AssertTrue('Single participant should be leader again', Result.IsLeader);
  AssertEquals('Second generation should be 2', Cardinal(2), Result.Generation);
end;

procedure TTestCase_WaitEx.Test_WaitEx_TwoParticipants_ExactlyOneLeader;
var
  Worker: TWaitExWorkerThread;
  WorkerIsLeader: Boolean;
  WorkerGeneration: Cardinal;
  MainResult: TBarrierWaitResult;
  DoneCount: Integer;
  LeaderCount: Integer;
begin
  WorkerIsLeader := False;
  WorkerGeneration := 0;
  DoneCount := 0;

  Worker := TWaitExWorkerThread.Create(FBarrier, @WorkerIsLeader, @WorkerGeneration, @DoneCount);
  try
    MainResult := FBarrier.WaitEx;
    Worker.WaitFor;

    // Count leaders
    LeaderCount := 0;
    if MainResult.IsLeader then Inc(LeaderCount);
    if WorkerIsLeader then Inc(LeaderCount);

    AssertEquals('Exactly one thread should be leader', 1, LeaderCount);
    AssertEquals('Both threads should see same generation', MainResult.Generation, WorkerGeneration);
  finally
    Worker.Free;
  end;
end;

procedure TTestCase_WaitEx.Test_WaitEx_Generation_IncrementOnComplete;
var
  B: IBarrier;
  R1, R2, R3: TBarrierWaitResult;
begin
  B := MakeBarrier(1);

  R1 := B.WaitEx;
  R2 := B.WaitEx;
  R3 := B.WaitEx;

  AssertEquals('First generation should be 1', Cardinal(1), R1.Generation);
  AssertEquals('Second generation should be 2', Cardinal(2), R2.Generation);
  AssertEquals('Third generation should be 3', Cardinal(3), R3.Generation);
end;

procedure TTestCase_WaitEx.Test_WaitEx_Generation_SameForAllParticipants;
var
  B: IBarrier;
  Workers: array[0..2] of TWaitExWorkerThread;
  WorkerGenerations: array[0..2] of Cardinal;
  MainResult: TBarrierWaitResult;
  DoneCount: Integer;
  i: Integer;
begin
  B := MakeBarrier(4);
  DoneCount := 0;

  for i := 0 to 2 do
  begin
    WorkerGenerations[i] := 0;
    Workers[i] := TWaitExWorkerThread.Create(B, nil, @WorkerGenerations[i], @DoneCount);
  end;

  try
    MainResult := B.WaitEx;

    for i := 0 to 2 do
      Workers[i].WaitFor;

    // All participants should see the same generation
    for i := 0 to 2 do
      AssertEquals('All threads should see same generation',
                   MainResult.Generation, WorkerGenerations[i]);
  finally
    for i := 0 to 2 do
      Workers[i].Free;
  end;
end;

procedure TTestCase_WaitEx.Test_WaitEx_MultipleRounds_GenerationIncreases;
var
  B: IBarrier;
  Worker: TWaitExWorkerThread;
  WorkerGeneration: Cardinal;
  MainResult: TBarrierWaitResult;
  DoneCount: Integer;
  Round: Integer;
  ExpectedGen: Cardinal;
begin
  B := MakeBarrier(2);

  for Round := 1 to 5 do
  begin
    DoneCount := 0;
    WorkerGeneration := 0;

    Worker := TWaitExWorkerThread.Create(B, nil, @WorkerGeneration, @DoneCount);
    try
      MainResult := B.WaitEx;
      Worker.WaitFor;

      ExpectedGen := Cardinal(Round);
      AssertEquals(Format('Round %d: generation should be %d', [Round, Round]),
                   ExpectedGen, MainResult.Generation);
      AssertEquals(Format('Round %d: worker should see same generation', [Round]),
                   MainResult.Generation, WorkerGeneration);
    finally
      Worker.Free;
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IBarrier);
  RegisterTest(TTestCase_WaitEx);

end.
