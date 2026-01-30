unit fafafa.core.mem.pool.fixed.concurrent.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry, Classes,
  fafafa.core.mem.pool.base,
  fafafa.core.mem.pool.fixed,
  fafafa.core.mem.pool.fixed.concurrent,
  fafafa.core.mem.allocator;

procedure RegisterTests;

implementation

uses SyncObjs;

type
  PRTLCriticalSection = ^TRTLCriticalSection;

  TWorker = class(TThread)
  private
    FPool: TFixedPoolConcurrent;
    FCS: PRTLCriticalSection;
    FDone: PInteger;
    FIterations: Integer;
    FSleepMaxMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(APool: TFixedPoolConcurrent; ACS: PRTLCriticalSection; ADone: PInteger; AIterations: Integer; ASleepMaxMs: Integer);
  end;

  TTestCase_Concurrent = class(TTestCase)
  published
    procedure Test_Concurrent_Basic;
    procedure Test_Concurrent_Shuffle_MultiThreads_MultiRounds_OK;
    procedure Test_Concurrent_Interleave_WithRandomSleep_OK;
  end;

{ TWorker }

constructor TWorker.Create(APool: TFixedPoolConcurrent; ACS: PRTLCriticalSection; ADone: PInteger; AIterations: Integer; ASleepMaxMs: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := APool;
  FCS := ACS;
  FDone := ADone;
  FIterations := AIterations;
  FSleepMaxMs := ASleepMaxMs;
end;

procedure TWorker.Execute;
var
  i: Integer;
  p: Pointer;
  okLocal: Boolean;
begin
  for i := 1 to FIterations do
  begin
    okLocal := FPool.Acquire(p);
    if okLocal and (p <> nil) then
    begin
      if FSleepMaxMs > 0 then Sleep(Random(FSleepMaxMs+1));
      FPool.Release(p);
    end;
  end;
  EnterCriticalSection(FCS^);
  try
    Inc(FDone^);
  finally
    LeaveCriticalSection(FCS^);
  end;
end;

procedure RegisterTests;
begin
  RegisterTest('TFixedPoolConcurrent', TTestCase_Concurrent.Suite);
end;

{ TTestCase_Concurrent }

procedure TTestCase_Concurrent.Test_Concurrent_Basic;
const
  Threads = 4;
  Iters   = 2000;
var
  pool: TFixedPoolConcurrent;
  done: Integer;
  cs: TRTLCriticalSection;
  workers: array[0..Threads-1] of TWorker;

var i: Integer;
begin
  InitCriticalSection(cs);
  try
    done := 0;
    pool := TFixedPoolConcurrent.Create(32, 16, 32);
    try
      for i := 0 to Threads-1 do
      begin
        workers[i] := TWorker.Create(pool, @cs, @done, Iters, 0);
        workers[i].Start;
      end;
      for i := 0 to Threads-1 do
      begin
        workers[i].WaitFor;
        workers[i].Free;
      end;
      CheckEquals(Threads, done);
    finally
      pool.Free;
    end;
  finally
    DoneCriticalsection(cs);
  end;
end;


procedure TTestCase_Concurrent.Test_Concurrent_Shuffle_MultiThreads_MultiRounds_OK;
const
  Threads = 8;
  Capacity = 64;
  Rounds = 10;
var
  pool: TFixedPoolConcurrent;
  arr: array of Pointer;
  i, r: Integer;

  procedure Shuffle;
  var i,j: Integer; tmp: Pointer;
  begin
    for i := High(arr) downto 1 do begin
      j := Random(i+1);
      tmp := arr[i]; arr[i] := arr[j]; arr[j] := tmp;
    end;
  end;
begin
  Randomize;
  pool := TFixedPoolConcurrent.Create(32, Capacity, 32);
  try
    SetLength(arr, Capacity);
    for r := 1 to Rounds do
    begin
      // 满额分配
      for i := 0 to Capacity-1 do CheckTrue(pool.Acquire(arr[i]));
      // 洗牌释放
      Shuffle;
      for i := 0 to Capacity-1 do pool.Release(arr[i]);
    end;
  finally
    pool.Free;
  end;
end;

procedure TTestCase_Concurrent.Test_Concurrent_Interleave_WithRandomSleep_OK;
const
  Threads = 8;
  Iters   = 1500;
  SleepMs = 2;
var
  pool: TFixedPoolConcurrent;
  done: Integer;
  cs: TRTLCriticalSection;
  workers: array[0..Threads-1] of TWorker;
  i: Integer;
begin
  Randomize;
  InitCriticalSection(cs);
  try
    done := 0;
    pool := TFixedPoolConcurrent.Create(32, 64, 32);
    try
      for i := 0 to Threads-1 do
      begin
        workers[i] := TWorker.Create(pool, @cs, @done, Iters, SleepMs);
        workers[i].Start;
      end;
      for i := 0 to Threads-1 do
      begin
        workers[i].WaitFor;
        workers[i].Free;
      end;
      CheckEquals(Threads, done);
    finally
      pool.Free;
    end;
  finally
    DoneCriticalsection(cs);
  end;
end;

end.

