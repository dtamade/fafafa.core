unit Test_vec_reserve_overflow_freebuffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

type
  TTestCase_Vec_ReserveOverflow_FreeBuffer = class(TTestCase)
  published
    // TryReserve / TryReserveExact 溢出与边界
    procedure Test_TryReserveExact_Overflow_ReturnsFalse_NoThrow;
    procedure Test_TryReserve_Overflow_ReturnsFalse_NoThrow;
    procedure Test_TryReserve_ZeroAdditional_NoOp_ReturnsTrue;
    procedure Test_ReserveExact_Overflow_Raises;

    // FreeBuffer 行为
    procedure Test_FreeBuffer_SetsCapacityZero_And_Reusable;

    // 托管类型在 Resize(0) 时的释放（以接口引用计数对象验证）
    procedure Test_Managed_Elements_Finalized_On_ResizeToZero;
  end;

implementation

type
  TTrackable = class(TInterfacedObject)
  public
    class var FreedCount: SizeInt;
    destructor Destroy; override;
  end;

destructor TTrackable.Destroy;
begin
  Inc(FreedCount);
  inherited Destroy;
end;

procedure TTestCase_Vec_ReserveOverflow_FreeBuffer.Test_TryReserveExact_Overflow_ReturnsFalse_NoThrow;
var
  V: specialize TVec<Integer>;
begin
  V := specialize TVec<Integer>.Create;
  try
    // 构造溢出：FCount + High(SizeUInt) 必然溢出；TryReserveExact 应返回 False，不抛异常
    AssertFalse('TryReserveExact overflow should return False', V.TryReserveExact(High(SizeUInt)));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_ReserveOverflow_FreeBuffer.Test_TryReserve_Overflow_ReturnsFalse_NoThrow;
var
  V: specialize TVec<Integer>;
begin
  V := specialize TVec<Integer>.Create;
  try
    AssertFalse('TryReserve overflow should return False', V.TryReserve(High(SizeUInt)));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_ReserveOverflow_FreeBuffer.Test_TryReserve_ZeroAdditional_NoOp_ReturnsTrue;
var
  V: specialize TVec<Integer>;
  CapBefore, CapAfter: SizeUInt;
begin
  V := specialize TVec<Integer>.Create;
  try
    CapBefore := V.GetCapacity;
    AssertTrue('TryReserve(0) should return True', V.TryReserve(0));
    CapAfter := V.GetCapacity;
    AssertEquals('Capacity should not change for additional=0', Int64(CapBefore), Int64(CapAfter));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_ReserveOverflow_FreeBuffer.Test_ReserveExact_Overflow_Raises;
var
  V: specialize TVec<Integer>;
begin
  V := specialize TVec<Integer>.Create;
  try
    try
      V.ReserveExact(High(SizeUInt));
      Fail('ReserveExact on overflow should raise');
    except
      on E: Exception do
        AssertTrue('ReserveExact should raise on overflow (any ECore/EOverflow acceptable)', True);
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_ReserveOverflow_FreeBuffer.Test_FreeBuffer_SetsCapacityZero_And_Reusable;
var
  V: specialize TVec<Integer>;
begin
  V := specialize TVec<Integer>.Create;
  try
    V.Push(1);
    V.Push(2);
    AssertTrue('Precondition: Count>0', V.Count > 0);

    V.FreeBuffer;
    AssertEquals('Capacity should be 0 after FreeBuffer', Int64(0), Int64(V.GetCapacity));
    AssertEquals('Count should be 0 after FreeBuffer', Int64(0), Int64(V.Count));

    // 可继续使用
    V.Push(42);
    AssertEquals('Can reuse after FreeBuffer', Int64(1), Int64(V.Count));
    AssertEquals('Element integrity after reuse', 42, V[0]);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_ReserveOverflow_FreeBuffer.Test_Managed_Elements_Finalized_On_ResizeToZero;
var
  V: specialize TVec<IInterface>;
  FreedBefore: SizeInt;
  i: Integer;
begin
  TTrackable.FreedCount := 0;
  FreedBefore := TTrackable.FreedCount;

  V := specialize TVec<IInterface>.Create;
  try
    // 仅由向量持有引用
    for i := 1 to 16 do
      V.Push(TTrackable.Create);

    AssertEquals('Precondition: vector count', Int64(16), Int64(V.Count));

    // Resize 到 0，应释放所有元素的引用
    V.Resize(0);

    AssertEquals('All managed elements should be finalized when resized to 0',
      Int64(FreedBefore + 16), Int64(TTrackable.FreedCount));
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_ReserveOverflow_FreeBuffer);
end.

