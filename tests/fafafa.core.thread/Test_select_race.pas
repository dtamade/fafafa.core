unit Test_select_race;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

Type
  TTestCase_Select_Race = class(TTestCase)
  published
    procedure Test_Select_Race_FirstWins;
    procedure Test_Select_AlreadyDone_Array;
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

procedure TTestCase_Select_Race.Test_Select_Race_FirstWins;
var Latch: ICountDownLatch; Fs: array[0..3] of IFuture; idx: Integer; i: Integer;
begin
  Latch := CreateCountDownLatch(1);
  for i := 0 to High(Fs) do
  begin
    Fs[i] := Spawn(@WaitOnLatch, Pointer(Latch));
  end;
  // 同刻释放，让多个任务几乎同时完成
  Latch.CountDown;
  idx := Select(Fs, 2000);
  AssertTrue(idx >= 0);
  // 确认所有任务都完成并释放引用，避免接口/同步原语在测试结束时仍存活
  AssertTrue(Join(Fs, 1000));
  Latch := nil;
end;

procedure TTestCase_Select_Race.Test_Select_AlreadyDone_Array;
var Fs: array[0..2] of IFuture; idx: Integer;
begin
  Fs[0] := Spawn(@Nop, nil);
  Fs[1] := Spawn(@Nop, nil);
  Fs[2] := Spawn(@Nop, nil);
  // 等待全部完成
  AssertTrue(Join(Fs, 1000));
  // 已完成数组的快速路径：应返回最小下标
  idx := Select(Fs, 1000);
  AssertTrue(idx = 0);
end;

initialization
  RegisterTest(TTestCase_Select_Race);

end.

