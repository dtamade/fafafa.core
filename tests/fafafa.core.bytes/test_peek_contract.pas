unit test_peek_contract;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testutils, testregistry, Classes, SysUtils,
  fafafa.core.bytes;

type
  TTestCase_PeekContract = class(TTestCase)
  published
    procedure NoGrow_PointerStable;
    procedure Grow_PointerMayChange;
  end;

implementation

procedure TTestCase_PeekContract.NoGrow_PointerStable;
var bb: TBytesBuilder; P1,P2: Pointer; N1,N2: SizeInt;
begin
  bb.Init(8);
  bb.AppendHex('AABB');
  bb.Peek(P1, N1);
  AssertEquals(2, N1);
  bb.AppendHex('CCDD');
  bb.Peek(P2, N2);
  AssertEquals(4, N2);
  AssertEquals(NativeUInt(P1), NativeUInt(P2));
end;

procedure TTestCase_PeekContract.Grow_PointerMayChange;
var bb: TBytesBuilder; P1,P2: Pointer; N1,N2: SizeInt; cap1, cap2: SizeInt;
begin
  bb.Init(2);
  bb.AppendHex('AABB');
  cap1 := bb.Capacity;
  bb.Peek(P1, N1);
  AssertEquals(2, N1);
  bb.AppendHex('CCDD');
  cap2 := bb.Capacity;
  bb.Peek(P2, N2);
  AssertEquals(4, N2);
  // 测试容量确实增长了，指针可能改变（但不强制要求改变）
  AssertTrue('capacity should grow', cap2 > cap1);
  // 数据完整性检查：无论指针是否改变，数据都应该正确
  AssertEquals(Byte($AA), PByte(P2)^);
  AssertEquals(Byte($BB), PByte(PByte(P2)+1)^);
  AssertEquals(Byte($CC), PByte(PByte(P2)+2)^);
  AssertEquals(Byte($DD), PByte(PByte(P2)+3)^);
end;

initialization
  RegisterTest(TTestCase_PeekContract);

end.

