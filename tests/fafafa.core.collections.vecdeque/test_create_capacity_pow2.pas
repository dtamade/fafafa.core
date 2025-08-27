program test_create_capacity_pow2;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

function IsPowerOfTwo(v: QWord): Boolean;
begin
  Result := (v > 0) and ((v and (v - 1)) = 0);
end;

procedure AssertTrue(const aCond: Boolean; const aMsg: String);
begin
  if not aCond then
  begin
    WriteLn('Assertion failed: ', aMsg);
    Halt(1);
  end;
end;

var
  D: specialize TVecDeque<Integer>;
  Cap: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create(20);
  try
    Cap := D.GetCapacity;
    AssertTrue(IsPowerOfTwo(Cap), 'Capacity should be power of two');
    AssertTrue(Cap >= 20, 'Capacity should be >= requested');
    WriteLn('OK');
  finally
    D.Free;
  end;
  Halt(0);
end.

