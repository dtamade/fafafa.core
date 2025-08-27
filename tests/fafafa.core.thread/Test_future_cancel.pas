unit Test_future_cancel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_FutureCancel = class(TTestCase)
  published
    procedure Test_FutureWaitOrCancel_CancelWins;
    procedure Test_Spawn_WithToken_CancelBefore;
    procedure Test_SpawnBlocking_WithToken_CancelBefore;
  end;

implementation

function Work(Data: Pointer): Boolean;
begin
  SysUtils.Sleep(NativeUInt(Data));
  Result := True;
end;

procedure TTestCase_FutureCancel.Test_FutureWaitOrCancel_CancelWins;
var F: IFuture; Cts: ICancellationTokenSource; Ok: Boolean;
begin
  Cts := CreateCancellationTokenSource;
  F := Spawn(@Work, Pointer(100));
  Cts.Cancel;
  Ok := FutureWaitOrCancel(F, Cts.Token, 1000);
  AssertFalse(Ok);
end;

procedure TTestCase_FutureCancel.Test_Spawn_WithToken_CancelBefore;
var F: IFuture; Cts: ICancellationTokenSource;
begin
  Cts := CreateCancellationTokenSource;
  Cts.Cancel;
  F := Spawn(@Work, Pointer(10), Cts.Token);
  AssertTrue(F = nil);
end;

procedure TTestCase_FutureCancel.Test_SpawnBlocking_WithToken_CancelBefore;
var F: IFuture; Cts: ICancellationTokenSource;
begin
  Cts := CreateCancellationTokenSource;
  Cts.Cancel;
  F := SpawnBlocking(@Work, Pointer(10), Cts.Token);
  AssertTrue(F = nil);
end;

initialization
  RegisterTest(TTestCase_FutureCancel);

end.

