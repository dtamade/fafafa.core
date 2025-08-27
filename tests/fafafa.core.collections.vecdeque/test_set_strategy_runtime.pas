program test_set_strategy_runtime;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator.rtlAllocator,
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
  S1: TGrowthStrategy;
  S2: TGrowthStrategy;
  i: Integer;
begin
  try
    // 初始使用黄金比例策略
    S1 := TGoldenRatioGrowStrategy.GetGlobal;
    D := specialize TVecDeque<Integer>.Create(0, GetRtlAllocator(), S1, nil);

    // 轻度填充，观察一次扩容
    for i := 1 to 100 do
      D.PushBack(i);
    Cap1 := D.GetCapacity;
    AssertTrue(IsPowerOfTwo(Cap1), 'Cap1 should be power of two');

    // 运行时切换为 64 字节对齐包装策略
    S2 := TAlignedWrapperStrategy.Create(TGoldenRatioGrowStrategy.GetGlobal, 64);
    D.SetGrowStrategy(S2);

    // 再次触发扩容
    for i := 101 to 5000 do
      D.PushBack(i);
    Cap2 := D.GetCapacity;

    AssertTrue(IsPowerOfTwo(Cap2), 'Cap2 should be power of two after strategy switch');
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

