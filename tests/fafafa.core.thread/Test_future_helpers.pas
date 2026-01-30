unit Test_future_helpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

Type
  TTestCase_FutureHelpers = class(TTestCase)
  published
    procedure Test_FutureAll;
    procedure Test_FutureAny;
    procedure Test_FutureTimeout;
  end;

implementation

function TaskSleepAndReturn(Data: Pointer): Boolean;
begin
  SysUtils.Sleep(NativeUInt(Data));
  Result := True;
end;

procedure TTestCase_FutureHelpers.Test_FutureAll;
var F1,F2: IFuture;
begin
  F1 := Spawn(@TaskSleepAndReturn, Pointer(10));
  F2 := Spawn(@TaskSleepAndReturn, Pointer(20));
  AssertTrue(FutureAll([F1, F2], 1000));
end;

procedure TTestCase_FutureHelpers.Test_FutureAny;
var F1,F2: IFuture; Idx: Integer;
begin
  F1 := Spawn(@TaskSleepAndReturn, Pointer(50));
  F2 := Spawn(@TaskSleepAndReturn, Pointer(10));
  Idx := FutureAny([F1, F2], 1000);
  AssertTrue((Idx = 0) or (Idx = 1));
end;

procedure TTestCase_FutureHelpers.Test_FutureTimeout;
var F: IFuture;
begin
  F := Spawn(@TaskSleepAndReturn, Pointer(50));
  AssertTrue(FutureTimeout(F, 1000));
end;

initialization
  RegisterTest(TTestCase_FutureHelpers);

end.

