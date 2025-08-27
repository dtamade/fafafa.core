program test_shrink_convergence;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure AssertEqualsI(const msg: string; const expected, actual: SizeInt);
begin
  if expected <> actual then
  begin
    WriteLn('Assertion failed: ', msg, ' expected=', expected, ' actual=', actual);
    Halt(1);
  end;
end;

var
  D: specialize TVecDeque<Integer>;
  i: Integer;
  capBefore, cap1, cap2: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    // 扩到较大容量
    for i := 1 to 200 do D.PushBack(i);
    capBefore := D.GetCapacity;
    // 降低到较小 Count 并收缩
    D.Truncate(10);
    D.ShrinkToFit;
    cap1 := D.GetCapacity;
    D.ShrinkToFit;
    cap2 := D.GetCapacity;

    if not (cap1 <= capBefore) then Halt(1);
    AssertEqualsI('Capacity must be >= Count after shrink', 10, cap1);
    AssertEqualsI('ShrinkToFit converges on second call', cap1, cap2);

    WriteLn('OK');
  finally
    D.Free;
  end;
  Halt(0);
end.

