program test_findlastif_wraparound_simple;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

procedure AssertEqualInt(const msg: string; got, expected: SizeInt);
begin
  if got <> expected then
  begin
    Writeln('FAIL: ', msg, ' got=', got, ' expected=', expected);
    Halt(1);
  end;
end;

var
  D: specialize TVecDeque<Integer>;
  idx: SizeInt;
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    // wraparound data
    for i := 1 to 10 do D.PushBack(i);
    for i := 1 to 5 do D.PopFront;
    for i := 11 to 15 do D.PushBack(i);
    // last even -> 14 at index 8
    idx := D.FindLastIF(
      function (const v: Integer; data: Pointer): Boolean
      begin Result := (v and 1) = 0; end,
      nil);
    AssertEqualInt('FindLastIF even idx', idx, 8);

    // last not divisible by 3 -> 14 at index 8
    idx := D.FindLastIFNot(
      function (const v: Integer; data: Pointer): Boolean
      begin Result := (v mod 3) = 0; end,
      nil);
    AssertEqualInt('FindLastIFNot idx', idx, 8);
  finally
    D.Free;
  end;
  Writeln('OK');
end.

