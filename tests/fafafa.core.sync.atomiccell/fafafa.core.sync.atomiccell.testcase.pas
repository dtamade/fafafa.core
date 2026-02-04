{$CODEPAGE UTF8}
unit fafafa.core.sync.atomiccell.testcase;

{**
 * fafafa.core.sync.atomiccell 测试套件
 *
 * 测试 TAtomicCell<T> 的：
 * - 基础操作（Load、Store、Swap、CompareExchange）
 * - 不同类型支持（Int32、Int64、Pointer）
 * - 并发安全性
 * - 性能基准
 *
 * @author fafafaStudio
 * @version 1.0
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.atomiccell,
  TestHelpers_Sync;

type
  // ===== 基础功能测试 =====
  TTestCase_AtomicCell_Basic = class(TTestCase)
  published
    procedure Test_Int32_Init;
    procedure Test_Int32_LoadStore;
    procedure Test_Int32_Swap;
    procedure Test_Int32_CompareExchange_Success;
    procedure Test_Int32_CompareExchange_Fail;
    procedure Test_Int64_LoadStore;
    procedure Test_Int64_Swap;
    procedure Test_Pointer_LoadStore;
  end;

  // ===== 并发测试 =====
  TTestCase_AtomicCell_Concurrent = class(TTestCase)
  published
    procedure Test_Int32_ConcurrentIncrement;
    procedure Test_Int64_ConcurrentIncrement;
    procedure Test_Int32_ConcurrentSwap;
  end;

  // ===== 压力测试 =====
  TTestCase_AtomicCell_Stress = class(TTestCase)
  published
    procedure Test_RapidLoadStore;
    procedure Test_RapidSwap;
    procedure Test_RapidCAS;
  end;

implementation

{ TTestCase_AtomicCell_Basic }

procedure TTestCase_AtomicCell_Basic.Test_Int32_Init;
var
  Cell: TAtomicCellInt32;
begin
  Cell.Init(42);
  AssertEquals('Init should set value', 42, Cell.Load);
end;

procedure TTestCase_AtomicCell_Basic.Test_Int32_LoadStore;
var
  Cell: TAtomicCellInt32;
begin
  Cell.Init(0);
  AssertEquals('Initial value', 0, Cell.Load);

  Cell.Store(100);
  AssertEquals('After Store(100)', 100, Cell.Load);

  Cell.Store(-50);
  AssertEquals('After Store(-50)', -50, Cell.Load);
end;

procedure TTestCase_AtomicCell_Basic.Test_Int32_Swap;
var
  Cell: TAtomicCellInt32;
  OldVal: Int32;
begin
  Cell.Init(10);

  OldVal := Cell.Swap(20);
  AssertEquals('Swap should return old value', 10, OldVal);
  AssertEquals('Swap should set new value', 20, Cell.Load);

  OldVal := Cell.Swap(30);
  AssertEquals('Second swap old value', 20, OldVal);
  AssertEquals('Second swap new value', 30, Cell.Load);
end;

procedure TTestCase_AtomicCell_Basic.Test_Int32_CompareExchange_Success;
var
  Cell: TAtomicCellInt32;
  Expected: Int32;
  Success: Boolean;
begin
  Cell.Init(100);
  Expected := 100;

  Success := Cell.CompareExchange(Expected, 200);

  AssertTrue('CAS should succeed', Success);
  AssertEquals('Value should be updated', 200, Cell.Load);
  AssertEquals('Expected should be unchanged on success', 100, Expected);
end;

procedure TTestCase_AtomicCell_Basic.Test_Int32_CompareExchange_Fail;
var
  Cell: TAtomicCellInt32;
  Expected: Int32;
  Success: Boolean;
begin
  Cell.Init(100);
  Expected := 50;  // Wrong expected value

  Success := Cell.CompareExchange(Expected, 200);

  AssertFalse('CAS should fail', Success);
  AssertEquals('Value should be unchanged', 100, Cell.Load);
  AssertEquals('Expected should be updated to actual', 100, Expected);
end;

procedure TTestCase_AtomicCell_Basic.Test_Int64_LoadStore;
var
  Cell: TAtomicCellInt64;
begin
  Cell.Init(0);
  AssertEquals('Initial value', Int64(0), Cell.Load);

  Cell.Store(Int64(1234567890123));
  AssertEquals('After Store large value', Int64(1234567890123), Cell.Load);

  Cell.Store(Int64(-9876543210987));
  AssertEquals('After Store negative', Int64(-9876543210987), Cell.Load);
end;

procedure TTestCase_AtomicCell_Basic.Test_Int64_Swap;
var
  Cell: TAtomicCellInt64;
  OldVal: Int64;
begin
  Cell.Init(Int64(1000000000000));

  OldVal := Cell.Swap(Int64(2000000000000));
  AssertEquals('Swap should return old value', Int64(1000000000000), OldVal);
  AssertEquals('Swap should set new value', Int64(2000000000000), Cell.Load);
end;

procedure TTestCase_AtomicCell_Basic.Test_Pointer_LoadStore;
var
  Cell: TAtomicCellPointer;
  P1, P2: Pointer;
begin
  P1 := Pointer($12345678);
  P2 := Pointer($87654321);

  Cell.Init(nil);
  AssertTrue('Initial value should be nil', Cell.Load = nil);

  Cell.Store(P1);
  AssertTrue('After Store P1', Cell.Load = P1);

  Cell.Store(P2);
  AssertTrue('After Store P2', Cell.Load = P2);
end;

{ TTestCase_AtomicCell_Concurrent }

type
  TAtomicCellInt32Ptr = ^TAtomicCellInt32;
  TAtomicCellInt64Ptr = ^TAtomicCellInt64;

  TAtomicIncThread32 = class(TThread)
  private
    FCell: TAtomicCellInt32Ptr;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACell: TAtomicCellInt32Ptr; AIterations: Integer);
  end;

  TAtomicIncThread64 = class(TThread)
  private
    FCell: TAtomicCellInt64Ptr;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACell: TAtomicCellInt64Ptr; AIterations: Integer);
  end;

constructor TAtomicIncThread32.Create(ACell: TAtomicCellInt32Ptr; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCell := ACell;
  FIterations := AIterations;
end;

procedure TAtomicIncThread32.Execute;
var
  i: Integer;
  Expected, Desired: Int32;
begin
  for i := 1 to FIterations do
  begin
    repeat
      Expected := FCell^.Load;
      Desired := Expected + 1;
    until FCell^.CompareExchange(Expected, Desired);
  end;
end;

constructor TAtomicIncThread64.Create(ACell: TAtomicCellInt64Ptr; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCell := ACell;
  FIterations := AIterations;
end;

procedure TAtomicIncThread64.Execute;
var
  i: Integer;
  Expected, Desired: Int64;
begin
  for i := 1 to FIterations do
  begin
    repeat
      Expected := FCell^.Load;
      Desired := Expected + 1;
    until FCell^.CompareExchange(Expected, Desired);
  end;
end;

procedure TTestCase_AtomicCell_Concurrent.Test_Int32_ConcurrentIncrement;
var
  Cell: TAtomicCellInt32;
  Threads: array[0..3] of TAtomicIncThread32;
  i, Iterations: Integer;
begin
  Iterations := 10000;
  Cell.Init(0);

  for i := 0 to 3 do
    Threads[i] := TAtomicIncThread32.Create(@Cell, Iterations);

  for i := 0 to 3 do
    Threads[i].Start;

  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('Concurrent increment result', 4 * Iterations, Cell.Load);
end;

procedure TTestCase_AtomicCell_Concurrent.Test_Int64_ConcurrentIncrement;
var
  Cell: TAtomicCellInt64;
  Threads: array[0..3] of TAtomicIncThread64;
  i, Iterations: Integer;
begin
  Iterations := 10000;
  Cell.Init(0);

  for i := 0 to 3 do
    Threads[i] := TAtomicIncThread64.Create(@Cell, Iterations);

  for i := 0 to 3 do
    Threads[i].Start;

  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  AssertEquals('Concurrent increment result', Int64(4 * Iterations), Cell.Load);
end;

type
  TAtomicSwapThread = class(TThread)
  private
    FCell: TAtomicCellInt32Ptr;
    FIterations: Integer;
    FId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACell: TAtomicCellInt32Ptr; AId, AIterations: Integer);
  end;

constructor TAtomicSwapThread.Create(ACell: TAtomicCellInt32Ptr; AId, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCell := ACell;
  FId := AId;
  FIterations := AIterations;
end;

procedure TAtomicSwapThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
    FCell^.Swap(FId);
end;

procedure TTestCase_AtomicCell_Concurrent.Test_Int32_ConcurrentSwap;
var
  Cell: TAtomicCellInt32;
  Threads: array[0..3] of TAtomicSwapThread;
  i, Iterations: Integer;
  FinalValue: Int32;
begin
  Iterations := 10000;
  Cell.Init(-1);

  for i := 0 to 3 do
    Threads[i] := TAtomicSwapThread.Create(@Cell, i, Iterations);

  for i := 0 to 3 do
    Threads[i].Start;

  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  FinalValue := Cell.Load;
  AssertTrue('Final value should be 0-3', (FinalValue >= 0) and (FinalValue <= 3));
end;

{ TTestCase_AtomicCell_Stress }

procedure TTestCase_AtomicCell_Stress.Test_RapidLoadStore;
var
  Cell: TAtomicCellInt32;
  i, Iterations: Integer;
  StartTime, ElapsedMs: QWord;
begin
  Iterations := 1000000;
  Cell.Init(0);

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    Cell.Store(i);
    Cell.Load;
  end;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('Rapid Load/Store: %d iterations in %d ms', [Iterations, ElapsedMs]));
  AssertTrue('Should complete quickly', ElapsedMs < 1000);
end;

procedure TTestCase_AtomicCell_Stress.Test_RapidSwap;
var
  Cell: TAtomicCellInt32;
  i, Iterations: Integer;
  StartTime, ElapsedMs: QWord;
begin
  Iterations := 1000000;
  Cell.Init(0);

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
    Cell.Swap(i);
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('Rapid Swap: %d iterations in %d ms', [Iterations, ElapsedMs]));
  AssertTrue('Should complete quickly', ElapsedMs < 1000);
end;

procedure TTestCase_AtomicCell_Stress.Test_RapidCAS;
var
  Cell: TAtomicCellInt32;
  i, Iterations: Integer;
  Expected: Int32;
  StartTime, ElapsedMs: QWord;
begin
  Iterations := 1000000;
  Cell.Init(0);

  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    Expected := i - 1;
    Cell.CompareExchange(Expected, i);
  end;
  ElapsedMs := GetCurrentTimeMs - StartTime;

  WriteLn(Format('Rapid CAS: %d iterations in %d ms', [Iterations, ElapsedMs]));
  AssertTrue('Should complete quickly', ElapsedMs < 2000);
  AssertEquals('Final value', Iterations, Cell.Load);
end;

initialization
  RegisterTest(TTestCase_AtomicCell_Basic);
  RegisterTest(TTestCase_AtomicCell_Concurrent);
  RegisterTest(TTestCase_AtomicCell_Stress);

end.
