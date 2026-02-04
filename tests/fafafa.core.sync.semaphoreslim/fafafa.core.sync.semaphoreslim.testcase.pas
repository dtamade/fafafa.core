{$CODEPAGE UTF8}
unit fafafa.core.sync.semaphoreslim.testcase;

{**
 * fafafa.core.sync.semaphoreslim 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.semaphoreslim;

type
  TTestCase_SemaphoreSlim_Basic = class(TTestCase)
  published
    procedure Test_Init_Done;
    procedure Test_Wait_Release;
    procedure Test_TryWait;
    procedure Test_ReleaseMany;
    procedure Test_MaxCount;
    procedure Test_WaitTimeout;
  end;

  TTestCase_SemaphoreSlim_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentAccess;
  end;

implementation

{ TTestCase_SemaphoreSlim_Basic }

procedure TTestCase_SemaphoreSlim_Basic.Test_Init_Done;
var
  Sem: TSemaphoreSlim;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(5, 10);
  AssertEquals('Initial count', 5, Sem.CurrentCount);
  AssertEquals('Max count', 10, Sem.MaxCount);
  Sem.Done;
end;

procedure TTestCase_SemaphoreSlim_Basic.Test_Wait_Release;
var
  Sem: TSemaphoreSlim;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(2);

  AssertTrue('Wait 1', Sem.Wait);
  AssertEquals('Count after 1', 1, Sem.CurrentCount);

  AssertTrue('Wait 2', Sem.Wait);
  AssertEquals('Count after 2', 0, Sem.CurrentCount);

  Sem.Release;
  AssertEquals('Count after release', 1, Sem.CurrentCount);

  Sem.Done;
end;

procedure TTestCase_SemaphoreSlim_Basic.Test_TryWait;
var
  Sem: TSemaphoreSlim;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(1);

  AssertTrue('TryWait succeeds', Sem.TryWait);
  AssertFalse('TryWait fails when empty', Sem.TryWait);

  Sem.Release;
  AssertTrue('TryWait succeeds again', Sem.TryWait);

  Sem.Done;
end;

procedure TTestCase_SemaphoreSlim_Basic.Test_ReleaseMany;
var
  Sem: TSemaphoreSlim;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(0, 10);

  AssertEquals('Release 3', 3, Sem.ReleaseMany(3));
  AssertEquals('Count', 3, Sem.CurrentCount);

  AssertEquals('Release 2 more', 5, Sem.ReleaseMany(2));
  AssertEquals('Count', 5, Sem.CurrentCount);

  Sem.Done;
end;

procedure TTestCase_SemaphoreSlim_Basic.Test_MaxCount;
var
  Sem: TSemaphoreSlim;
  ExceptionRaised: Boolean;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(5, 5);

  ExceptionRaised := False;
  try
    Sem.Release;  // 超过最大值
  except
    ExceptionRaised := True;
  end;
  AssertTrue('Should raise on exceed max', ExceptionRaised);

  Sem.Done;
end;

procedure TTestCase_SemaphoreSlim_Basic.Test_WaitTimeout;
var
  Sem: TSemaphoreSlim;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(0, 1);  // 初始 0，最大 1

  AssertFalse('Timeout on empty', Sem.WaitTimeout(50));

  Sem.Release;  // 释放到 1
  AssertTrue('Succeeds with permit', Sem.WaitTimeout(50));

  Sem.Done;
end;

{ TTestCase_SemaphoreSlim_Concurrent }

type
  TSemWorker = class(TThread)
  private
    FSem: ^TSemaphoreSlim;
    FIterations: Integer;
    FCompleted: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(var ASem: TSemaphoreSlim; AIterations: Integer);
    property Completed: Boolean read FCompleted;
  end;

constructor TSemWorker.Create(var ASem: TSemaphoreSlim; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSem := @ASem;
  FIterations := AIterations;
  FCompleted := False;
end;

procedure TSemWorker.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FSem^.Wait;
    // 模拟工作
    Sleep(0);
    FSem^.Release;
  end;
  FCompleted := True;
end;

procedure TTestCase_SemaphoreSlim_Concurrent.Test_ConcurrentAccess;
var
  Sem: TSemaphoreSlim;
  Workers: array[0..3] of TSemWorker;
  i, Completed: Integer;
begin
  FillChar(Sem, SizeOf(Sem), 0);
  Sem.Init(2);  // 只允许 2 个并发

  for i := 0 to 3 do
    Workers[i] := TSemWorker.Create(Sem, 50);

  for i := 0 to 3 do
    Workers[i].Start;

  Completed := 0;
  for i := 0 to 3 do
  begin
    Workers[i].WaitFor;
    if Workers[i].Completed then
      Inc(Completed);
    Workers[i].Free;
  end;

  AssertEquals('All completed', 4, Completed);
  AssertEquals('Count restored', 2, Sem.CurrentCount);

  Sem.Done;
end;

initialization
  RegisterTest(TTestCase_SemaphoreSlim_Basic);
  RegisterTest(TTestCase_SemaphoreSlim_Concurrent);

end.
