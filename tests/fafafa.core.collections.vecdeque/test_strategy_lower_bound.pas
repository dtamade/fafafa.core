program test_strategy_lower_bound;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

type
  // 故意返回小于 required 的值；基类应在 GetGrowSize 中保证下界 >= required
  TTooSmallGrowStrategy = class(TGrowthStrategy)
  protected
    function DoGetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt; override;
  end;

function TTooSmallGrowStrategy.DoGetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
begin
  if aRequiredSize > 5 then
    Result := aRequiredSize - 5
  else
    Result := 0;
end;

procedure AssertTrue(const aCond: Boolean; const aMsg: String);
begin
  if not aCond then
  begin
    WriteLn('Assertion failed: ', aMsg);
    Halt(1);
  end;
end;

function IsPowerOfTwo(v: QWord): Boolean;
begin
  Result := (v > 0) and ((v and (v - 1)) = 0);
end;

var
  D: specialize TVecDeque<Integer>;
  S: TGrowthStrategy;
  AfterCap: SizeUInt;
  i: Integer;
begin
  try
    S := TTooSmallGrowStrategy.Create;
    D := specialize TVecDeque<Integer>.Create(16, nil, S);

    // 触发扩容到大于 16 的需求：插入 20 个元素
    for i := 1 to 20 do
      D.PushBack(i);

    AfterCap := D.GetCapacity;
    AssertTrue(IsPowerOfTwo(AfterCap), 'Capacity should be power of two');
    AssertTrue(AfterCap >= 20, 'Capacity should be >= required');

    WriteLn('OK');
    Halt(0);
  except
    on E: Exception do
    begin
      WriteLn('Exception: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

