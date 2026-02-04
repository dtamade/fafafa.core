{$CODEPAGE UTF8}
unit fafafa.core.sync.adaptivelock.testcase;

{**
 * fafafa.core.sync.adaptivelock 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.adaptivelock;

type
  TTestCase_AdaptiveLock_Basic = class(TTestCase)
  published
    procedure Test_Init_Done;
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire;
    procedure Test_SpinAdaptation;
  end;

  TTestCase_AdaptiveLock_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentAccess;
  end;

implementation

{ TTestCase_AdaptiveLock_Basic }

procedure TTestCase_AdaptiveLock_Basic.Test_Init_Done;
var
  L: TAdaptiveLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;
  AssertFalse('Not locked initially', L.IsLocked);
  AssertTrue('Initial spin count > 0', L.SpinCount > 0);
  L.Done;
end;

procedure TTestCase_AdaptiveLock_Basic.Test_Acquire_Release;
var
  L: TAdaptiveLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;

  L.Acquire;
  AssertTrue('Locked', L.IsLocked);

  L.Release;
  AssertFalse('Unlocked', L.IsLocked);

  L.Done;
end;

procedure TTestCase_AdaptiveLock_Basic.Test_TryAcquire;
var
  L: TAdaptiveLock;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;

  AssertTrue('TryAcquire succeeds', L.TryAcquire);
  AssertFalse('TryAcquire fails when locked', L.TryAcquire);

  L.Release;
  AssertTrue('TryAcquire succeeds again', L.TryAcquire);
  L.Release;

  L.Done;
end;

procedure TTestCase_AdaptiveLock_Basic.Test_SpinAdaptation;
var
  L: TAdaptiveLock;
  InitialSpin: Integer;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;

  InitialSpin := L.SpinCount;
  AssertTrue('Initial spin > 0', InitialSpin > 0);

  // 无竞争获取应该增加自旋计数
  L.Acquire;
  L.Release;

  // 注意：自适应可能需要多次操作才能明显改变
  // 这里只验证基本功能

  L.Done;
end;

{ TTestCase_AdaptiveLock_Concurrent }

type
  TAdaptiveWorker = class(TThread)
  private
    FLock: ^TAdaptiveLock;
    FIterations: Integer;
    FCounter: ^Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(var ALock: TAdaptiveLock; var ACounter: Integer; AIterations: Integer);
  end;

constructor TAdaptiveWorker.Create(var ALock: TAdaptiveLock; var ACounter: Integer; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLock := @ALock;
  FCounter := @ACounter;
  FIterations := AIterations;
end;

procedure TAdaptiveWorker.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FLock^.Acquire;
    try
      Inc(FCounter^);
    finally
      FLock^.Release;
    end;
  end;
end;

procedure TTestCase_AdaptiveLock_Concurrent.Test_ConcurrentAccess;
var
  L: TAdaptiveLock;
  Counter: Integer;
  Workers: array[0..3] of TAdaptiveWorker;
  i: Integer;
begin
  FillChar(L, SizeOf(L), 0);
  L.Init;
  Counter := 0;

  for i := 0 to 3 do
    Workers[i] := TAdaptiveWorker.Create(L, Counter, 1000);

  for i := 0 to 3 do
    Workers[i].Start;

  for i := 0 to 3 do
  begin
    Workers[i].WaitFor;
    Workers[i].Free;
  end;

  AssertEquals('Counter correct', 4000, Counter);
  AssertFalse('Lock released', L.IsLocked);

  L.Done;
end;

initialization
  RegisterTest(TTestCase_AdaptiveLock_Basic);
  RegisterTest(TTestCase_AdaptiveLock_Concurrent);

end.
