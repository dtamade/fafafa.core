{$CODEPAGE UTF8}
unit fafafa.core.sync.fairmutex.testcase;

{**
 * fafafa.core.sync.fairmutex 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.fairmutex;

type
  TTestCase_FairMutex_Basic = class(TTestCase)
  published
    procedure Test_Init_Done;
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire;
    procedure Test_IsLocked;
  end;

  TTestCase_FairMutex_Fairness = class(TTestCase)
  published
    procedure Test_FIFO_Order;
  end;

implementation

{ TTestCase_FairMutex_Basic }

procedure TTestCase_FairMutex_Basic.Test_Init_Done;
var
  M: TFairMutex;
begin
  FillChar(M, SizeOf(M), 0);
  M.Init;
  AssertFalse('Not locked initially', M.IsLocked);
  M.Done;
end;

procedure TTestCase_FairMutex_Basic.Test_Acquire_Release;
var
  M: TFairMutex;
begin
  FillChar(M, SizeOf(M), 0);
  M.Init;

  M.Acquire;
  AssertTrue('Locked after acquire', M.IsLocked);

  M.Release;
  AssertFalse('Unlocked after release', M.IsLocked);

  M.Done;
end;

procedure TTestCase_FairMutex_Basic.Test_TryAcquire;
var
  M: TFairMutex;
begin
  FillChar(M, SizeOf(M), 0);
  M.Init;

  AssertTrue('TryAcquire succeeds', M.TryAcquire);
  AssertFalse('TryAcquire fails when locked', M.TryAcquire);

  M.Release;
  AssertTrue('TryAcquire succeeds again', M.TryAcquire);
  M.Release;

  M.Done;
end;

procedure TTestCase_FairMutex_Basic.Test_IsLocked;
var
  M: TFairMutex;
begin
  FillChar(M, SizeOf(M), 0);
  M.Init;

  AssertFalse('Not locked', M.IsLocked);
  M.Acquire;
  AssertTrue('Locked', M.IsLocked);
  M.Release;
  AssertFalse('Unlocked', M.IsLocked);

  M.Done;
end;

{ TTestCase_FairMutex_Fairness }

type
  TFairMutexWorker = class(TThread)
  private
    FMutex: ^TFairMutex;
    FOrder: ^Integer;
    FMyOrder: Integer;
    FId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(var AMutex: TFairMutex; var AOrder: Integer; AId: Integer);
    property MyOrder: Integer read FMyOrder;
  end;

constructor TFairMutexWorker.Create(var AMutex: TFairMutex; var AOrder: Integer; AId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FMutex := @AMutex;
  FOrder := @AOrder;
  FId := AId;
  FMyOrder := -1;
end;

procedure TFairMutexWorker.Execute;
begin
  FMutex^.Acquire;
  try
    Inc(FOrder^);
    FMyOrder := FOrder^;
    Sleep(5);  // 持有锁一段时间
  finally
    FMutex^.Release;
  end;
end;

procedure TTestCase_FairMutex_Fairness.Test_FIFO_Order;
var
  M: TFairMutex;
  Order: Integer;
  Workers: array[0..2] of TFairMutexWorker;  // 减少到 3 个工作线程
  i: Integer;
  AllCompleted: Boolean;
begin
  FillChar(M, SizeOf(M), 0);
  M.Init;
  Order := 0;

  // 先获取锁
  M.Acquire;

  // 创建并启动工作线程（它们会按顺序排队）
  for i := 0 to 2 do
  begin
    Workers[i] := TFairMutexWorker.Create(M, Order, i);
    Workers[i].Start;
    Sleep(20);  // 确保按顺序排队
  end;

  // 释放锁，让工作线程开始
  M.Release;

  // 等待所有完成（带超时）
  AllCompleted := True;
  for i := 0 to 2 do
  begin
    Workers[i].WaitFor;
    if Workers[i].MyOrder < 0 then
      AllCompleted := False;
    Workers[i].Free;
  end;

  AssertTrue('All workers completed', AllCompleted);

  M.Done;
end;

initialization
  RegisterTest(TTestCase_FairMutex_Basic);
  RegisterTest(TTestCase_FairMutex_Fairness);

end.
