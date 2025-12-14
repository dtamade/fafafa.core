unit Test_vec_hysteresis;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

type
  TTestCase_Vec_GrowthShrink_Hysteresis = class(TTestCase)
  published
    procedure Test_ShrinkToFit_Hysteresis_NoChange_When_AtThreshold;
    procedure Test_ShrinkToFit_Hysteresis_Shrinks_When_WellAboveThreshold;
    procedure Test_ShrinkToFit_Hysteresis_MinThreshold_128_Respected;
  end;

implementation

procedure TTestCase_Vec_GrowthShrink_Hysteresis.Test_ShrinkToFit_Hysteresis_NoChange_When_AtThreshold;
var
  V: specialize TVec<Integer>;
  CapBefore, CapAfter: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    // 新规则：阈值 = max(2×UsedBytes, 64 KiB)。令 CapacityBytes = 64 KiB 恰好等于阈值。
    V.ResizeExact(0);
    V.ReserveExact(16384); // 16384 elements * 4 bytes = 65536 bytes
    V.ResizeExact(10);     // UsedBytes = 40 bytes, 阈值=64 KiB

    CapBefore := V.GetCapacity;
    V.ShrinkToFit;  // 由于 CapacityBytes == 阈值，不应收缩
    CapAfter  := V.GetCapacity;

    AssertEquals('Capacity elements should be at 64KiB threshold (no shrink)', Int64(16384), Int64(CapBefore));
    AssertEquals('ShrinkToFit should not change capacity at threshold', Int64(CapBefore), Int64(CapAfter));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_GrowthShrink_Hysteresis.Test_ShrinkToFit_Hysteresis_Shrinks_When_WellAboveThreshold;
var
  V: specialize TVec<Integer>;
  CapBefore, CapAfter: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    // 设定较大的容量，再将 Count 调小，触发 ShrinkToFit
    V.ResizeExact(0);
    V.ReserveExact(5000); // Capacity = 5000
    V.ResizeExact(1000);  // Count = 1000，阈值 = 2000

    CapBefore := V.GetCapacity;
    V.ShrinkToFit;  // 由于 5000 > 阈值(2000)，应收缩到 Count=1000
    CapAfter  := V.GetCapacity;

    AssertEquals('Precondition: capacity should be 5000 before shrink', Int64(5000), Int64(CapBefore));
    AssertEquals('ShrinkToFit should shrink down to Count', Int64(1000), Int64(CapAfter));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_GrowthShrink_Hysteresis.Test_ShrinkToFit_Hysteresis_MinThreshold_128_Respected;
var
  V: specialize TVec<Integer>;
  CapBefore, CapAfter: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    // 新规则的“字节下界”：对小 Count，若 CapacityBytes 超过 64 KiB 也应收缩
    // 令元素为 4 字节，构造 CapacityBytes=256*4=1024 bytes（<64KiB），因此主要由 2×UsedBytes 主导
    V.ResizeExact(0);
    V.ReserveExact(256); // Capacity=256
    V.ResizeExact(10);

    CapBefore := V.GetCapacity; // 256
    V.ShrinkToFit;              // 256*4=1024 bytes > max(2*10*4=80, 64KiB)? 否 -> 不由 64KiB 触发；但旧用例语义：256>128 元素阈值，现更新为 Count=10 后应收缩至 10
    CapAfter  := V.GetCapacity;

    AssertEquals('Precondition: capacity should be 256', Int64(256), Int64(CapBefore));
    AssertEquals('ShrinkToFit should shrink down to small Count under ratio threshold', Int64(10), Int64(CapAfter));
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_GrowthShrink_Hysteresis);
end.

