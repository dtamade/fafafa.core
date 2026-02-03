unit Test_fafafa_core_sync_seqlock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base,
  fafafa.core.sync.seqlock;

type
  TTestCase_SeqLock = class(TTestCase)
  private
    FSeqLock: ISeqLock;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Create;
    procedure Test_ReadBegin_ReturnsEvenSequence;
    procedure Test_WriteBegin_WriteEnd_SequenceChanges;
    procedure Test_ReadRetry_NoWrite_ReturnsFalse;
    procedure Test_ReadRetry_WithWrite_ReturnsTrue;
    procedure Test_TryWriteBegin_Success;
    procedure Test_TryWriteBegin_Failure_WhenLocked;
    procedure Test_WriteGuard_RAII;
    procedure Test_ConcurrentReads_NoBlocking;
    procedure Test_WriteBlocksOtherWrites;
  end;

  TTestCase_SeqLockData = class(TTestCase)
  published
    procedure Test_ReadWrite_Integer;
    procedure Test_ReadWrite_Record;
    procedure Test_ConcurrentReadWrite;
  end;

  TTestCase_SeqLock_Performance = class(TTestCase)
  published
    procedure Test_ReadPerformance_NoContention;
    procedure Test_WritePerformance_NoContention;
    procedure Test_ReadPerformance_WithConcurrentWrites;
  end;

implementation

{ Helper threads for concurrent tests - using class-based threads to avoid FPC anonymous procedure issues }

type
  TSeqLockWriterThread = class(TThread)
  private
    FSeqLock: ISeqLock;
    FIterations: Integer;
    FValue: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(ASeqLock: ISeqLock; AValue: PInteger; AIterations: Integer);
  end;

  TSeqLockReaderThread = class(TThread)
  private
    FSeqLock: ISeqLock;
    FIterations: Integer;
    FValue: PInteger;
    FReadCount: Integer;
    FRetryCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ASeqLock: ISeqLock; AValue: PInteger; AIterations: Integer);
    property ReadCount: Integer read FReadCount;
    property RetryCount: Integer read FRetryCount;
  end;

  // Counter record for data tests
  TCounter = record
    Value: Integer;
    Padding: array[0..60] of Byte; // Cache line padding
  end;
  PCounter = ^TCounter;

  // Specialized writer thread for SeqLockData tests
  TSeqLockDataWriterThread = class(TThread)
  private
    FData: specialize ISeqLockData<TCounter>;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AData: specialize ISeqLockData<TCounter>; AIterations: Integer);
  end;

{ TSeqLockWriterThread }

constructor TSeqLockWriterThread.Create(ASeqLock: ISeqLock; AValue: PInteger; AIterations: Integer);
begin
  FSeqLock := ASeqLock;
  FValue := AValue;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TSeqLockWriterThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FSeqLock.WriteBegin;
    try
      Inc(FValue^);
    finally
      FSeqLock.WriteEnd;
    end;
  end;
end;

{ TSeqLockReaderThread }

constructor TSeqLockReaderThread.Create(ASeqLock: ISeqLock; AValue: PInteger; AIterations: Integer);
begin
  FSeqLock := ASeqLock;
  FValue := AValue;
  FIterations := AIterations;
  FReadCount := 0;
  FRetryCount := 0;
  inherited Create(False);
end;

procedure TSeqLockReaderThread.Execute;
var
  i: Integer;
  Seq: UInt32;
  LocalValue: Integer;
begin
  for i := 1 to FIterations do
  begin
    repeat
      Seq := FSeqLock.ReadBegin;
      LocalValue := FValue^;
      if FSeqLock.ReadRetry(Seq) then
        Inc(FRetryCount);
    until not FSeqLock.ReadRetry(Seq);
    Inc(FReadCount);
  end;
end;

{ TSeqLockDataWriterThread }

constructor TSeqLockDataWriterThread.Create(AData: specialize ISeqLockData<TCounter>; AIterations: Integer);
begin
  FData := AData;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TSeqLockDataWriterThread.Execute;
var
  j: Integer;
  C: TCounter;
begin
  for j := 1 to FIterations do
  begin
    C := FData.Read;
    C.Value := j;
    FData.Write(C);
  end;
end;

{ TTestCase_SeqLock }

procedure TTestCase_SeqLock.SetUp;
begin
  inherited SetUp;
  FSeqLock := MakeSeqLock;
end;

procedure TTestCase_SeqLock.TearDown;
begin
  FSeqLock := nil;
  inherited TearDown;
end;

procedure TTestCase_SeqLock.Test_Create;
begin
  AssertNotNull('SeqLock should be created', FSeqLock);
  AssertEquals('Initial sequence should be 0', 0, FSeqLock.Sequence);
end;

procedure TTestCase_SeqLock.Test_ReadBegin_ReturnsEvenSequence;
var
  Seq: UInt32;
begin
  Seq := FSeqLock.ReadBegin;
  AssertEquals('ReadBegin should return even sequence', 0, Seq and 1);
end;

procedure TTestCase_SeqLock.Test_WriteBegin_WriteEnd_SequenceChanges;
var
  SeqBefore, SeqDuring, SeqAfter: UInt32;
begin
  SeqBefore := FSeqLock.Sequence;
  AssertEquals('Before write, sequence should be 0', 0, SeqBefore);

  FSeqLock.WriteBegin;
  SeqDuring := FSeqLock.Sequence;
  AssertEquals('During write, sequence should be odd', 1, SeqDuring and 1);

  FSeqLock.WriteEnd;
  SeqAfter := FSeqLock.Sequence;
  AssertEquals('After write, sequence should be even', 0, SeqAfter and 1);
  AssertEquals('After write, sequence should be 2', 2, SeqAfter);
end;

procedure TTestCase_SeqLock.Test_ReadRetry_NoWrite_ReturnsFalse;
var
  Seq: UInt32;
begin
  Seq := FSeqLock.ReadBegin;
  // No write happened
  AssertFalse('ReadRetry should return False when no write', FSeqLock.ReadRetry(Seq));
end;

procedure TTestCase_SeqLock.Test_ReadRetry_WithWrite_ReturnsTrue;
var
  Seq: UInt32;
begin
  Seq := FSeqLock.ReadBegin;

  // Simulate a write
  FSeqLock.WriteBegin;
  FSeqLock.WriteEnd;

  AssertTrue('ReadRetry should return True after write', FSeqLock.ReadRetry(Seq));
end;

procedure TTestCase_SeqLock.Test_TryWriteBegin_Success;
begin
  AssertTrue('TryWriteBegin should succeed when unlocked', FSeqLock.TryWriteBegin);
  FSeqLock.WriteEnd;
end;

procedure TTestCase_SeqLock.Test_TryWriteBegin_Failure_WhenLocked;
var
  SeqLock2: ISeqLock;
begin
  // First lock
  FSeqLock.WriteBegin;

  // Create another reference and try to lock
  SeqLock2 := FSeqLock;
  AssertFalse('TryWriteBegin should fail when locked', SeqLock2.TryWriteBegin);

  FSeqLock.WriteEnd;
end;

procedure TTestCase_SeqLock.Test_WriteGuard_RAII;
var
  SeqBefore, SeqAfter: UInt32;
  Guard: ILockGuard;
begin
  SeqBefore := FSeqLock.Sequence;

  // Use guard
  Guard := FSeqLock.WriteGuard;
  try
    AssertTrue('Guard should be locked', Guard.IsLocked);
    AssertEquals('During guard, sequence should be odd', 1, FSeqLock.Sequence and 1);
  finally
    Guard.Release;
  end;

  SeqAfter := FSeqLock.Sequence;
  AssertEquals('After guard scope, sequence should be even', 0, SeqAfter and 1);
  AssertTrue('Sequence should have increased', SeqAfter > SeqBefore);
end;

procedure TTestCase_SeqLock.Test_ConcurrentReads_NoBlocking;
var
  Value: Integer;
  Readers: array[0..3] of TSeqLockReaderThread;
  i: Integer;
  TotalReads: Integer;
begin
  Value := 42;

  // Create multiple readers
  for i := 0 to 3 do
    Readers[i] := TSeqLockReaderThread.Create(FSeqLock, @Value, 1000);

  // Wait for all readers
  TotalReads := 0;
  for i := 0 to 3 do
  begin
    Readers[i].WaitFor;
    TotalReads := TotalReads + Readers[i].ReadCount;
    Readers[i].Free;
  end;

  AssertEquals('All reads should complete', 4000, TotalReads);
end;

procedure TTestCase_SeqLock.Test_WriteBlocksOtherWrites;
var
  Value: Integer;
  Writers: array[0..1] of TSeqLockWriterThread;
  i: Integer;
begin
  Value := 0;

  // Create multiple writers
  for i := 0 to 1 do
    Writers[i] := TSeqLockWriterThread.Create(FSeqLock, @Value, 1000);

  // Wait for all writers
  for i := 0 to 1 do
  begin
    Writers[i].WaitFor;
    Writers[i].Free;
  end;

  AssertEquals('Value should be sum of all increments', 2000, Value);
end;

{ TTestCase_SeqLockData }

procedure TTestCase_SeqLockData.Test_ReadWrite_Integer;
var
  Data: specialize ISeqLockData<Integer>;
begin
  Data := specialize MakeSeqLockData<Integer>(42);

  AssertEquals('Initial value', 42, Data.Read);

  Data.Write(100);
  AssertEquals('After write', 100, Data.Read);
end;

procedure TTestCase_SeqLockData.Test_ReadWrite_Record;
type
  TPoint = record
    X, Y: Integer;
  end;
var
  Data: specialize ISeqLockData<TPoint>;
  P: TPoint;
begin
  P.X := 10;
  P.Y := 20;
  Data := specialize MakeSeqLockData<TPoint>(P);

  P := Data.Read;
  AssertEquals('Initial X', 10, P.X);
  AssertEquals('Initial Y', 20, P.Y);

  P.X := 100;
  P.Y := 200;
  Data.Write(P);

  P := Data.Read;
  AssertEquals('After write X', 100, P.X);
  AssertEquals('After write Y', 200, P.Y);
end;

procedure TTestCase_SeqLockData.Test_ConcurrentReadWrite;
var
  Data: specialize ISeqLockData<TCounter>;
  Counter: TCounter;
  WriterThread: TSeqLockDataWriterThread;
  i: Integer;
  ReadValue: TCounter;
  Iterations: Integer;
begin
  Counter.Value := 0;
  Data := specialize MakeSeqLockData<TCounter>(Counter);
  Iterations := 10000;

  // Writer thread using class-based thread
  WriterThread := TSeqLockDataWriterThread.Create(Data, Iterations);

  // Reader in main thread
  for i := 1 to Iterations do
  begin
    ReadValue := Data.Read;
    // Value should be consistent (not torn)
    AssertTrue('Value should be >= 0', ReadValue.Value >= 0);
    AssertTrue('Value should be <= Iterations', ReadValue.Value <= Iterations);
  end;

  WriterThread.WaitFor;
  WriterThread.Free;

  // Final value should be the last written
  ReadValue := Data.Read;
  AssertEquals('Final value', Iterations, ReadValue.Value);
end;

{ TTestCase_SeqLock_Performance }

procedure TTestCase_SeqLock_Performance.Test_ReadPerformance_NoContention;
var
  SeqLock: ISeqLock;
  StartTime, EndTime: QWord;
  i: Integer;
  Seq: UInt32;
  Value: Integer;
const
  ITERATIONS = 1000000;
begin
  SeqLock := MakeSeqLock;
  Value := 42;

  StartTime := GetTickCount64;

  for i := 1 to ITERATIONS do
  begin
    repeat
      Seq := SeqLock.ReadBegin;
      // Simulate reading data
      if Value <> 42 then ;
    until not SeqLock.ReadRetry(Seq);
  end;

  EndTime := GetTickCount64;

  WriteLn(Format('SeqLock Read (no contention): %d ms for %d ops (%.2f ns/op)',
    [EndTime - StartTime, ITERATIONS, (EndTime - StartTime) * 1000000.0 / ITERATIONS]));

  AssertTrue('Read performance should be reasonable', EndTime - StartTime < 5000);
end;

procedure TTestCase_SeqLock_Performance.Test_WritePerformance_NoContention;
var
  SeqLock: ISeqLock;
  StartTime, EndTime: QWord;
  i: Integer;
  Value: Integer;
const
  ITERATIONS = 1000000;
begin
  SeqLock := MakeSeqLock;
  Value := 0;

  StartTime := GetTickCount64;

  for i := 1 to ITERATIONS do
  begin
    SeqLock.WriteBegin;
    Inc(Value);
    SeqLock.WriteEnd;
  end;

  EndTime := GetTickCount64;

  WriteLn(Format('SeqLock Write (no contention): %d ms for %d ops (%.2f ns/op)',
    [EndTime - StartTime, ITERATIONS, (EndTime - StartTime) * 1000000.0 / ITERATIONS]));

  AssertEquals('Value should match iterations', ITERATIONS, Value);
  AssertTrue('Write performance should be reasonable', EndTime - StartTime < 5000);
end;

procedure TTestCase_SeqLock_Performance.Test_ReadPerformance_WithConcurrentWrites;
var
  SeqLock: ISeqLock;
  Value: Integer;
  Writer: TSeqLockWriterThread;
  StartTime, EndTime: QWord;
  i: Integer;
  Seq: UInt32;
  RetryCount: Integer;
const
  ITERATIONS = 100000;
begin
  SeqLock := MakeSeqLock;
  Value := 0;
  RetryCount := 0;

  // Start writer
  Writer := TSeqLockWriterThread.Create(SeqLock, @Value, ITERATIONS);

  StartTime := GetTickCount64;

  // Read concurrently
  for i := 1 to ITERATIONS do
  begin
    repeat
      Seq := SeqLock.ReadBegin;
      if Value < 0 then ; // Read
      if SeqLock.ReadRetry(Seq) then
        Inc(RetryCount);
    until not SeqLock.ReadRetry(Seq);
  end;

  EndTime := GetTickCount64;

  Writer.WaitFor;
  Writer.Free;

  WriteLn(Format('SeqLock Read (with contention): %d ms, %d retries (%.1f%% retry rate)',
    [EndTime - StartTime, RetryCount, RetryCount * 100.0 / ITERATIONS]));

  AssertTrue('Read performance should be reasonable', EndTime - StartTime < 10000);
end;

initialization
  RegisterTest('fafafa.core.sync.seqlock', TTestCase_SeqLock);
  RegisterTest('fafafa.core.sync.seqlock', TTestCase_SeqLockData);
  RegisterTest('fafafa.core.sync.seqlock', TTestCase_SeqLock_Performance);

end.
