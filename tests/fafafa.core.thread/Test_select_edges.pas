unit Test_select_edges;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

Type
  TTestCase_Select_Edges = class(TTestCase)
  published
    procedure Test_Select_EmptyArray_ReturnsMinus1;
    procedure Test_Select_AllNil_Timeout_ReturnsMinus1;
    procedure Test_Select_MixedNilAndDone_ReturnsDoneIndex;
    procedure Test_Select_ZeroTimeout_AlreadyDone_ReturnsIndex;
    procedure Test_Select_ZeroTimeout_NoneDone_ReturnsMinus1;
  end;

implementation

function Nop(Data: Pointer): Boolean; begin Result := True; end;

function WaitOnLatch(Data: Pointer): Boolean;
var L: ICountDownLatch;
begin
  L := ICountDownLatch(Data);
  L.Await(1000);
  Result := True;
end;

procedure TTestCase_Select_Edges.Test_Select_EmptyArray_ReturnsMinus1;
var Fs: array of IFuture; idx: Integer;
begin
  SetLength(Fs, 0);
  idx := Select(Fs, 10);
  AssertTrue(idx = -1);
end;

procedure TTestCase_Select_Edges.Test_Select_AllNil_Timeout_ReturnsMinus1;
var Fs: array[0..2] of IFuture; idx: Integer;
begin
  // 默认均为 nil
  idx := Select(Fs, 50);
  AssertTrue(idx = -1);
end;

procedure TTestCase_Select_Edges.Test_Select_MixedNilAndDone_ReturnsDoneIndex;
var Fs: array[0..2] of IFuture; idx: Integer;
begin
  Fs[0] := nil;
  Fs[1] := Spawn(@Nop, nil);
  // 确保已完成
  AssertTrue(Join([Fs[1]], 500));
  Fs[2] := nil;
  idx := Select(Fs, 1000);
  AssertTrue(idx = 1);
end;

procedure TTestCase_Select_Edges.Test_Select_ZeroTimeout_AlreadyDone_ReturnsIndex;
var Fs: array[0..1] of IFuture; idx: Integer;
begin
  Fs[0] := Spawn(@Nop, nil);
  AssertTrue(Join([Fs[0]], 500));
  Fs[1] := nil;
  idx := Select(Fs, 0);
  AssertTrue(idx = 0);
end;

procedure TTestCase_Select_Edges.Test_Select_ZeroTimeout_NoneDone_ReturnsMinus1;
var Latch: ICountDownLatch; Fs: array[0..1] of IFuture; idx: Integer;
begin
  Latch := CreateCountDownLatch(1);
  Fs[0] := Spawn(@WaitOnLatch, Pointer(Latch));
  Fs[1] := nil;
  idx := Select(Fs, 0);
  AssertTrue(idx = -1);
  // 收尾，避免悬挂
  Latch.CountDown;
  AssertTrue(Join([Fs[0]], 1000));
  Latch := nil;
end;

initialization
  RegisterTest(TTestCase_Select_Edges);

end.

