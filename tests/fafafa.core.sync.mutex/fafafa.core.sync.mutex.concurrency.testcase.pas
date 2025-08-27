unit fafafa.core.sync.mutex.concurrency.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.mutex, fafafa.core.sync.base;

type
  // 高强度并发测试
  TTestCase_Concurrency = class(TTestCase)
  private
    FMutex: IMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Contention_50Threads;
    procedure Test_Contention_100Threads;
    procedure Test_ProducerConsumer;
    procedure Test_ThreadChurn_CreateDestroy;
    procedure Test_FairnessWithPriorities;
    procedure Test_ReaderWriterPattern;
  end;

  TIncThread = class(TThread)
  private
    FMutex: IMutex;
    FCounter: PInteger;
    FIterations: Integer;
  public
    constructor Create(AMutex: IMutex; ACounter: PInteger; AIterations: Integer);
    procedure Execute; override;
  end;

  TPCThread = class(TThread)
  private
    FMutex: IMutex;
    FQueue: TList;
    FIsProducer: Boolean;
    FStopFlag: PBoolean;
    FProduced, FConsumed: PInteger;
  public
    constructor Create(AMutex: IMutex; AQueue: TList; AIsProducer: Boolean;
                       AStopFlag: PBoolean; AProduced, AConsumed: PInteger);
    procedure Execute; override;
  end;

implementation

{ TIncThread }

constructor TIncThread.Create(AMutex: IMutex; ACounter: PInteger; AIterations: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FMutex := AMutex;
  FCounter := ACounter;
  FIterations := AIterations;
end;

procedure TIncThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FMutex.Acquire;
    try
      Inc(FCounter^);
    finally
      FMutex.Release;
    end;
    if (i and $FF) = 0 then
      Sleep(0);
  end;
end;

{ TPCThread }

constructor TPCThread.Create(AMutex: IMutex; AQueue: TList; AIsProducer: Boolean;
  AStopFlag: PBoolean; AProduced, AConsumed: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FMutex := AMutex;
  FQueue := AQueue;
  FIsProducer := AIsProducer;
  FStopFlag := AStopFlag;
  FProduced := AProduced;
  FConsumed := AConsumed;
end;

procedure TPCThread.Execute;
var
  item: Pointer;
begin
  while not Terminated and not FStopFlag^ do
  begin
    if FIsProducer then
    begin
      FMutex.Acquire;
      try
        item := Pointer(Random(MaxInt));
        FQueue.Add(item);
        Inc(FProduced^);
      finally
        FMutex.Release;
      end;
    end
    else
    begin
      FMutex.Acquire;
      try
        if FQueue.Count > 0 then
        begin
          item := FQueue[FQueue.Count-1];
          FQueue.Delete(FQueue.Count-1);
          Inc(FConsumed^);
        end;
      finally
        FMutex.Release;
      end;
    end;
    Sleep(0);
  end;
end;

{ TTestCase_Concurrency }

procedure TTestCase_Concurrency.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
end;

procedure TTestCase_Concurrency.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_Concurrency.Test_Contention_50Threads;
var
  threads: array of TIncThread;
  i, counter: Integer;
begin
  counter := 0;
  SetLength(threads, 50);
  for i := 0 to High(threads) do
    threads[i] := TIncThread.Create(FMutex, @counter, 2000);
  for i := 0 to High(threads) do threads[i].WaitFor;
  for i := 0 to High(threads) do threads[i].Free;
  AssertEquals('Counter should match iterations', 50*2000, counter);
end;

procedure TTestCase_Concurrency.Test_Contention_100Threads;
var
  threads: array of TIncThread;
  i, counter: Integer;
begin
  counter := 0;
  SetLength(threads, 100);
  for i := 0 to High(threads) do
    threads[i] := TIncThread.Create(FMutex, @counter, 1000);
  for i := 0 to High(threads) do threads[i].WaitFor;
  for i := 0 to High(threads) do threads[i].Free;
  AssertEquals('Counter should match iterations', 100*1000, counter);
end;

procedure TTestCase_Concurrency.Test_ProducerConsumer;
var
  queue: TList;
  producers, consumers: array of TPCThread;
  i: Integer;
  stopFlag: Boolean;
  produced, consumed: Integer;
begin
  queue := TList.Create;
  try
    Randomize;
    stopFlag := False;
    produced := 0; consumed := 0;
    SetLength(producers, 5);
    SetLength(consumers, 5);
    for i := 0 to 4 do
      producers[i] := TPCThread.Create(FMutex, queue, True, @stopFlag, @produced, @consumed);
    for i := 0 to 4 do
      consumers[i] := TPCThread.Create(FMutex, queue, False, @stopFlag, @produced, @consumed);
    // 运行 500ms
    Sleep(500);
    stopFlag := True;
    for i := 0 to 4 do begin producers[i].WaitFor; producers[i].Free; end;
    for i := 0 to 4 do begin consumers[i].WaitFor; consumers[i].Free; end;
    AssertTrue('Produced should be >= Consumed', produced >= consumed);
  finally
    queue.Free;
  end;
end;

procedure TTestCase_Concurrency.Test_ThreadChurn_CreateDestroy;
var
  i, counter: Integer;
  th: TIncThread;
begin
  counter := 0;
  for i := 1 to 1000 do
  begin
    th := TIncThread.Create(FMutex, @counter, 1);
    th.WaitFor;
    th.Free;
  end;
  AssertEquals('Counter should be 1000', 1000, counter);
end;

procedure TTestCase_Concurrency.Test_FairnessWithPriorities;
var
  lowT, normT, highT: TIncThread;
  cLow, cNorm, cHigh: Integer;
begin
  cLow := 0; cNorm := 0; cHigh := 0;
  lowT := TIncThread.Create(FMutex, @cLow, 2000); lowT.Priority := tpLower;
  normT := TIncThread.Create(FMutex, @cNorm, 2000); normT.Priority := tpNormal;
  highT := TIncThread.Create(FMutex, @cHigh, 2000); highT.Priority := tpHigher;
  lowT.WaitFor; normT.WaitFor; highT.WaitFor;
  lowT.Free; normT.Free; highT.Free;
  // 不要求完全公平，但应无饥饿
  AssertTrue('No starvation for low priority', cLow > 0);
  AssertTrue('No starvation for high priority', cHigh > 0);
end;

procedure TTestCase_Concurrency.Test_ReaderWriterPattern;
var
  readers: array[0..19] of TIncThread;
  writer: TIncThread;
  i: Integer;
  rc, wc: Integer;
begin
  // 使用同一互斥锁模拟：写者独占、读者串行（用于验证无死锁与基本公平）
  rc := 0; wc := 0;
  for i := 0 to High(readers) do
    readers[i] := TIncThread.Create(FMutex, @rc, 200);
  writer := TIncThread.Create(FMutex, @wc, 1000);
  for i := 0 to High(readers) do readers[i].WaitFor;
  writer.WaitFor;
  for i := 0 to High(readers) do readers[i].Free;
  writer.Free;
  AssertTrue('Writer and readers both progressed', (rc > 0) and (wc > 0));
end;

initialization
  RegisterTest(TTestCase_Concurrency);

end.

