program test_strategy_pow2_rounding;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure FailWithMessage(const aMessage: string);
begin
  WriteLn('[FAIL] ', aMessage);
  Halt(1);
end;

procedure AssertEqualCapacity(const aName: string; aExpected, aActual: SizeUInt);
begin
  if aExpected <> aActual then
    FailWithMessage(aName + ' expected=' + IntToStr(aExpected) + ' actual=' + IntToStr(aActual));
end;

procedure AssertTrue(const aName: string; aCondition: Boolean);
begin
  if not aCondition then
    FailWithMessage(aName);
end;

function IsPowerOfTwoValue(aValue: SizeUInt): Boolean;
begin
  Result := (aValue > 0) and ((aValue and (aValue - 1)) = 0);
end;

procedure ValidateCapacity(aInput, aExpected: SizeUInt);
var
  LDeque: specialize TVecDeque<Integer>;
  LCapacity: SizeUInt;
begin
  LDeque := specialize TVecDeque<Integer>.Create(aInput);
  try
    LCapacity := LDeque.GetCapacity;
    AssertEqualCapacity('Create(' + IntToStr(aInput) + ')', aExpected, LCapacity);
    AssertTrue('Create(' + IntToStr(aInput) + ') must be power-of-two capacity', IsPowerOfTwoValue(LCapacity));
    WriteLn('[PASS] Create(', aInput, ') => Capacity=', LCapacity);
  finally
    LDeque.Free;
  end;
end;

begin
  ValidateCapacity(0, 1);
  ValidateCapacity(10, 16);
  ValidateCapacity(16, 16);
  ValidateCapacity(17, 32);
  WriteLn('[PASS] test_strategy_pow2_rounding all checks passed');
  ExitCode := 0;
end.
