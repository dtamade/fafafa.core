program test_set_strategy_interface;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
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
  Cap1, Cap2: SizeUInt;
  SBase: TGrowthStrategy;
  SWrap: TAlignedWrapperStrategy;
  SIntf: IGrowthStrategy;
  i: Integer;
begin
  try
    // 初始使用黄金比例策略（类实例），随后切换为接口策略
    SBase := TGoldenRatioGrowStrategy.GetGlobal;
    D := specialize TVecDeque<Integer>.Create(0, nil, SBase, nil);

    for i := 1 to 128 do
      D.PushBack(i);
    Cap1 := D.GetCapacity;
    AssertTrue(IsPowerOfTwo(Cap1), 'Cap1 should be power of two');

    // 用类策略包装 -> 接口视图，再通过 SetGrowStrategyI 注入
    SWrap := TAlignedWrapperStrategy.Create(TGoldenRatioGrowStrategy.GetGlobal, 64);
    SIntf := TGrowthStrategyInterfaceView.Create(SWrap);
    D.SetGrowStrategyI(SIntf);

    for i := 129 to 8000 do
      D.PushBack(i);
    Cap2 := D.GetCapacity;

    AssertTrue(IsPowerOfTwo(Cap2), 'Cap2 should be power of two after SetGrowStrategyI');
    AssertTrue(Cap2 >= D.GetCount, 'Cap2 should be >= Count');

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

