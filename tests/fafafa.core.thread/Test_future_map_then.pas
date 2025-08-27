unit Test_future_map_then;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

Type
  TTestCase_FutureMapThen = class(TTestCase)
  published
    procedure Test_FutureMap;
    procedure Test_FutureThen;
  end;

implementation

function Nop(Data: Pointer): Boolean; begin Result := True; end;

function SleepRet(Data: Pointer): Boolean;
begin
  SysUtils.Sleep(NativeUInt(Data));
  Result := True;
end;

procedure TTestCase_FutureMapThen.Test_FutureMap;
var F1,F2: IFuture;
begin
  F1 := Spawn(@SleepRet, Pointer(10));
  F2 := FutureMap(F1, @Nop, nil);
  AssertTrue(Assigned(F2));
  AssertTrue(FutureAll([F1,F2], 1000));
end;

procedure TTestCase_FutureMapThen.Test_FutureThen;
var F1,F2: IFuture;
begin
  F1 := Spawn(@SleepRet, Pointer(10));
  F2 := FutureThen(F1, @Nop, nil);
  AssertTrue(Assigned(F2));
  AssertTrue(FutureAll([F1,F2], 1000));
end;

initialization
  RegisterTest(TTestCase_FutureMapThen);

end.

