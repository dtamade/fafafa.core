unit test_peek_contract;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testutils, testregistry, Classes, SysUtils,
  fafafa.core.bytes, fafafa.core.io.adapters;

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
var bb: TBytesBuilder; P1,P2: Pointer; N1,N2: SizeInt;
begin
  bb.Init(2);
  bb.AppendHex('AABB');
  bb.Peek(P1, N1);
  AssertEquals(2, N1);
  bb.AppendHex('CCDD');
  bb.Peek(P2, N2);
  AssertEquals(4, N2);
  AssertTrue(NativeUInt(P1) <> NativeUInt(P2));
end;

initialization
  RegisterTest(TTestCase_PeekContract);

end.

