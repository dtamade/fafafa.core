program test_strategy_pow2_rounding;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  fafafa.core.mem.allocator.rtlAllocator,
  fafafa.core.collections.vecdeque;

// 一个返回“非 2 的幂”的策略：current=16, required=17 -> 返回 17+3=20（非 2 的幂）
type
  TBadGrowStrategy = class(TGrowthStrategy)
  protected
    function DoGetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt; override;
  end;

function TBadGrowStrategy.DoGetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
begin
  // 故意返回非 2 的幂，测试 VecDeque 是否会在最终归一化
  Result := aRequiredSize + 3;
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
  Deque: specialize TVecDeque<Integer>;
  Strategy: TGrowthStrategy;
  InitialCap, AfterGrowCap: SizeUInt;
  i: Integer;
begin
  try
    Strategy := TBadGrowStrategy.Create;
    // 显式传入 RTL 分配器，避免传入 nil
    Deque := specialize TVecDeque<Integer>.Create(16, GetRtlAllocator(), Strategy);
    InitialCap := Deque.GetCapacity;
    AssertTrue(IsPowerOfTwo(InitialCap), 'Initial capacity should be power of two');

    // 触发扩容：插入 17 个元素，策略会建议 20，但应被统一到 32
    for i := 1 to 17 do
      Deque.PushBack(i);

    AfterGrowCap := Deque.GetCapacity;
    AssertTrue(IsPowerOfTwo(AfterGrowCap), 'After grow capacity should be power of two');
    AssertTrue(AfterGrowCap >= 17, 'After grow capacity >= required');

    // 若以下断言失败，说明没有进行 2 的幂归一
    AssertTrue(AfterGrowCap <> 20, 'After grow capacity should not equal non-power-of-two (20)');

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

