unit fafafa.core.mem.pool.fixed.tl.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry, Classes, SyncObjs,
  fafafa.core.mem.pool.base,
  fafafa.core.mem.pool.fixed.tl;

procedure RegisterTests;

implementation

type
  PRTLCriticalSection = ^TRTLCriticalSection;

  TWorker = class(TThread)
  private
    FPool: IPool;
    FDone: PInteger;
    FCS: PRTLCriticalSection;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(APool: IPool; ACS: PRTLCriticalSection; ADone: PInteger; AIters: Integer);
  end;

  TTestCase_TL = class(TTestCase)
  published
    procedure Test_TL_CrossThread_Release_Reacquire_OK;
  end;

procedure RegisterTests;
begin
  RegisterTest('TFixedPoolTL', TTestCase_TL.Suite);
end;


{ TWorker }

constructor TWorker.Create(APool: IPool; ACS: PRTLCriticalSection; ADone: PInteger; AIters: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := APool;
  FCS := ACS;
  FDone := ADone;
  FIterations := AIters;
end;

procedure TWorker.Execute;
var
  i: Integer;
  tmp: Pointer;
  ok: Boolean;
begin
  for i := 1 to FIterations do
  begin
    ok := FPool.Acquire(tmp);
    if ok and (tmp <> nil) then Sleep(1);
    if ok then FPool.Release(tmp);
  end;
  EnterCriticalSection(FCS^);
  try Inc(FDone^); finally LeaveCriticalSection(FCS^); end;
end;

{ TTestCase_TL }

procedure TTestCase_TL.Test_TL_CrossThread_Release_Reacquire_OK;
const
  Capacity = 16;
  Iters    = 2000;
var
  pool: IPool;
  p: Pointer;
  done: Integer;
  cs: TRTLCriticalSection;
  worker: TWorker;

var i: Integer;
begin
  InitCriticalSection(cs);
  try
    done := 0;
    pool := TFixedPoolTL.Create(32, Capacity, 32);
    // 主线程先拿一个指针，然后交给子线程释放
    CheckTrue(pool.Acquire(p));
    worker := TWorker.Create(pool, @cs, @done, Iters);
    try
      worker.Start;
      // 主线程把指针交还（模拟跨线程），子线程循环中会回收
      pool.Release(p);
      worker.WaitFor;
      worker.Free;
      CheckEquals(1, done);
    finally
      pool := nil;
    end;
  finally
    DoneCriticalsection(cs);
  end;
end;

end.

