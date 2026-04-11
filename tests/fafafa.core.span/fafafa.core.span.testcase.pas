{$CODEPAGE UTF8}
unit fafafa.core.span.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.span;

type
  TIntSpan = specialize TReadOnlySpan<Integer>;
  TIntSpan2 = specialize TReadOnlySpan2<Integer>;

  TTestCoreSpan = class(TTestCase)
  published
    procedure Test_FromPointer_EmptySpan_IsEmpty;
    procedure Test_Get_And_TryGet_ReadValues;
    procedure Test_GetPtr_ReturnsUnderlyingAddress;
    procedure Test_SubSpan_CreatesNestedView;
    procedure Test_Get_OutOfRange_Raises;
    procedure Test_GetPtr_OutOfRange_Raises;
    procedure Test_SubSpan_InvalidRange_Raises;
    procedure Test_SubSpan_ZeroLength_ReturnsEmpty;
    procedure Test_Span2_FromTwo_ReadsAcrossSegments;
    procedure Test_Span2_AOnly_ReadsSingleSegment;
    procedure Test_Span2_BOnly_ReadsSecondSegment;
    procedure Test_Span2_ExposesUnderlyingSegments;
    procedure Test_Span2_TryGet_And_GetPtr_WorkAcrossSegments;
    procedure Test_Span2_GetBlock_ReturnsCurrentContiguousBlock;
    procedure Test_Span2_SubSpan_CrossesSegments;
    procedure Test_Span2_SubSpan_InB;
    procedure Test_Span2_SubSpan_ZeroLength_ReturnsEmpty;
    procedure Test_Span2_SubSpan_InvalidRange_Raises;
    procedure Test_Span2_Get_OutOfRange_Raises;
    procedure Test_Span2_GetPtr_OutOfRange_Raises;
  end;

implementation

procedure TTestCoreSpan.Test_FromPointer_EmptySpan_IsEmpty;
var
  LSpan: TIntSpan;
begin
  LSpan := TIntSpan.FromPointer(nil, 0);
  AssertTrue(LSpan.IsEmpty);
  AssertEquals(SizeUInt(0), LSpan.Count);
end;

procedure TTestCoreSpan.Test_Get_And_TryGet_ReadValues;
var
  LData: array[0..3] of Integer;
  LSpan: TIntSpan;
  LValue: Integer;
begin
  LData[0] := 11;
  LData[1] := 22;
  LData[2] := 33;
  LData[3] := 44;

  LSpan := TIntSpan.FromPointer(@LData[0], Length(LData));

  AssertEquals(11, LSpan.Get(0));
  AssertEquals(44, LSpan.Get(3));
  AssertTrue(LSpan.TryGet(2, LValue));
  AssertEquals(33, LValue);
  AssertFalse(LSpan.TryGet(4, LValue));
end;

procedure TTestCoreSpan.Test_GetPtr_ReturnsUnderlyingAddress;
var
  LData: array[0..2] of Integer;
  LSpan: TIntSpan;
begin
  LData[0] := 5;
  LData[1] := 7;
  LData[2] := 9;

  LSpan := TIntSpan.FromPointer(@LData[0], Length(LData));

  AssertEquals(PtrUInt(@LData[1]), PtrUInt(LSpan.GetPtr(1)));
  AssertEquals(7, PInteger(LSpan.GetPtr(1))^);
end;

procedure TTestCoreSpan.Test_SubSpan_CreatesNestedView;
var
  LData: array[0..4] of Integer;
  LSpan: TIntSpan;
  LSub: TIntSpan;
begin
  LData[0] := 1;
  LData[1] := 2;
  LData[2] := 3;
  LData[3] := 4;
  LData[4] := 5;

  LSpan := TIntSpan.FromPointer(@LData[0], Length(LData));
  LSub := LSpan.SubSpan(1, 3);

  AssertEquals(SizeUInt(3), LSub.Count);
  AssertEquals(2, LSub.Get(0));
  AssertEquals(4, LSub.Get(2));
end;

procedure TTestCoreSpan.Test_Get_OutOfRange_Raises;
var
  LData: array[0..0] of Integer;
  LSpan: TIntSpan;
begin
  LData[0] := 42;
  LSpan := TIntSpan.FromPointer(@LData[0], 1);

  try
    LSpan.Get(1);
    Fail('Expected exception: Span.Get: index out of range');
  except
    on E: EOutOfRange do
      CheckEquals('Span.Get: index out of range', E.Message);
  end;
end;

procedure TTestCoreSpan.Test_GetPtr_OutOfRange_Raises;
var
  LData: array[0..0] of Integer;
  LSpan: TIntSpan;
begin
  LData[0] := 42;
  LSpan := TIntSpan.FromPointer(@LData[0], 1);

  try
    LSpan.GetPtr(1);
    Fail('Expected exception: Span.GetPtr: index out of range');
  except
    on E: EOutOfRange do
      CheckEquals('Span.GetPtr: index out of range', E.Message);
  end;
end;

procedure TTestCoreSpan.Test_SubSpan_InvalidRange_Raises;
var
  LData: array[0..1] of Integer;
  LSpan: TIntSpan;
begin
  LData[0] := 10;
  LData[1] := 20;
  LSpan := TIntSpan.FromPointer(@LData[0], 2);

  try
    LSpan.SubSpan(1, 2);
    Fail('Expected exception: Span.SubSpan: range out of bounds');
  except
    on E: EOutOfRange do
      CheckEquals('Span.SubSpan: range out of bounds', E.Message);
  end;
end;

procedure TTestCoreSpan.Test_SubSpan_ZeroLength_ReturnsEmpty;
var
  LData: array[0..2] of Integer;
  LSpan: TIntSpan;
  LSub: TIntSpan;
begin
  LData[0] := 1;
  LData[1] := 2;
  LData[2] := 3;

  LSpan := TIntSpan.FromPointer(@LData[0], 3);
  LSub := LSpan.SubSpan(1, 0);

  AssertTrue(LSub.IsEmpty);
  AssertEquals(SizeUInt(0), LSub.Count);
end;

procedure TTestCoreSpan.Test_Span2_FromTwo_ReadsAcrossSegments;
var
  LAData: array[0..1] of Integer;
  LBData: array[0..2] of Integer;
  LSpan2: TIntSpan2;
begin
  LAData[0] := 10;
  LAData[1] := 20;
  LBData[0] := 30;
  LBData[1] := 40;
  LBData[2] := 50;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );

  AssertFalse(LSpan2.IsEmpty);
  AssertEquals(SizeUInt(5), LSpan2.Count);
  AssertEquals(10, LSpan2.Get(0));
  AssertEquals(20, LSpan2.Get(1));
  AssertEquals(30, LSpan2.Get(2));
  AssertEquals(50, LSpan2.Get(4));
end;

procedure TTestCoreSpan.Test_Span2_AOnly_ReadsSingleSegment;
var
  LAData: array[0..2] of Integer;
  LSpan2: TIntSpan2;
begin
  LAData[0] := 3;
  LAData[1] := 4;
  LAData[2] := 5;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(nil, 0)
  );

  AssertEquals(SizeUInt(3), LSpan2.Count);
  AssertEquals(3, LSpan2.Get(0));
  AssertEquals(5, LSpan2.Get(2));
end;

procedure TTestCoreSpan.Test_Span2_BOnly_ReadsSecondSegment;
var
  LBData: array[0..1] of Integer;
  LSpan2: TIntSpan2;
begin
  LBData[0] := 13;
  LBData[1] := 21;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(nil, 0),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );

  AssertEquals(SizeUInt(2), LSpan2.Count);
  AssertEquals(13, LSpan2.Get(0));
  AssertEquals(21, LSpan2.Get(1));
end;

procedure TTestCoreSpan.Test_Span2_ExposesUnderlyingSegments;
var
  LAData: array[0..1] of Integer;
  LBData: array[0..0] of Integer;
  LSpan2: TIntSpan2;
begin
  LAData[0] := 1;
  LAData[1] := 2;
  LBData[0] := 3;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );

  AssertEquals(SizeUInt(2), LSpan2.ASpan.Count);
  AssertEquals(SizeUInt(1), LSpan2.BSpan.Count);
  AssertEquals(2, LSpan2.ASpan.Get(1));
  AssertEquals(3, LSpan2.BSpan.Get(0));
end;

procedure TTestCoreSpan.Test_Span2_TryGet_And_GetPtr_WorkAcrossSegments;
var
  LAData: array[0..0] of Integer;
  LBData: array[0..1] of Integer;
  LSpan2: TIntSpan2;
  LValue: Integer;
begin
  LAData[0] := 7;
  LBData[0] := 8;
  LBData[1] := 9;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );

  AssertTrue(LSpan2.TryGet(2, LValue));
  AssertEquals(9, LValue);
  AssertFalse(LSpan2.TryGet(3, LValue));
  AssertEquals(PtrUInt(@LBData[1]), PtrUInt(LSpan2.GetPtr(2)));
  AssertEquals(9, PInteger(LSpan2.GetPtr(2))^);
end;

procedure TTestCoreSpan.Test_Span2_GetBlock_ReturnsCurrentContiguousBlock;
var
  LAData: array[0..1] of Integer;
  LBData: array[0..2] of Integer;
  LSpan2: TIntSpan2;
  LPtr: Pointer;
  LLen: SizeUInt;
begin
  LAData[0] := 11;
  LAData[1] := 22;
  LBData[0] := 33;
  LBData[1] := 44;
  LBData[2] := 55;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );

  AssertTrue(LSpan2.GetBlock(1, LPtr, LLen));
  AssertEquals(PtrUInt(@LAData[1]), PtrUInt(LPtr));
  AssertEquals(SizeUInt(1), LLen);

  AssertTrue(LSpan2.GetBlock(2, LPtr, LLen));
  AssertEquals(PtrUInt(@LBData[0]), PtrUInt(LPtr));
  AssertEquals(SizeUInt(3), LLen);

  AssertFalse(LSpan2.GetBlock(5, LPtr, LLen));
  AssertEquals(PtrUInt(nil), PtrUInt(LPtr));
  AssertEquals(SizeUInt(0), LLen);
end;

procedure TTestCoreSpan.Test_Span2_SubSpan_CrossesSegments;
var
  LAData: array[0..2] of Integer;
  LBData: array[0..1] of Integer;
  LSpan2: TIntSpan2;
  LSub: TIntSpan2;
begin
  LAData[0] := 1;
  LAData[1] := 2;
  LAData[2] := 3;
  LBData[0] := 4;
  LBData[1] := 5;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );
  LSub := LSpan2.SubSpan(1, 3);

  AssertEquals(SizeUInt(3), LSub.Count);
  AssertEquals(2, LSub.Get(0));
  AssertEquals(3, LSub.Get(1));
  AssertEquals(4, LSub.Get(2));
  AssertEquals(SizeUInt(2), LSub.ASpan.Count);
  AssertEquals(SizeUInt(1), LSub.BSpan.Count);
end;

procedure TTestCoreSpan.Test_Span2_SubSpan_InB;
var
  LAData: array[0..0] of Integer;
  LBData: array[0..2] of Integer;
  LSpan2: TIntSpan2;
  LSub: TIntSpan2;
begin
  LAData[0] := 1;
  LBData[0] := 2;
  LBData[1] := 3;
  LBData[2] := 4;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(@LBData[0], Length(LBData))
  );
  LSub := LSpan2.SubSpan(2, 2);

  AssertEquals(SizeUInt(2), LSub.Count);
  AssertEquals(SizeUInt(0), LSub.ASpan.Count);
  AssertEquals(SizeUInt(2), LSub.BSpan.Count);
  AssertEquals(3, LSub.Get(0));
  AssertEquals(4, LSub.Get(1));
end;

procedure TTestCoreSpan.Test_Span2_SubSpan_ZeroLength_ReturnsEmpty;
var
  LAData: array[0..1] of Integer;
  LSpan2: TIntSpan2;
  LSub: TIntSpan2;
begin
  LAData[0] := 5;
  LAData[1] := 6;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(nil, 0)
  );
  LSub := LSpan2.SubSpan(1, 0);

  AssertTrue(LSub.IsEmpty);
  AssertEquals(SizeUInt(0), LSub.Count);
  AssertEquals(SizeUInt(0), LSub.ASpan.Count);
  AssertEquals(SizeUInt(0), LSub.BSpan.Count);
end;

procedure TTestCoreSpan.Test_Span2_SubSpan_InvalidRange_Raises;
var
  LAData: array[0..1] of Integer;
  LSpan2: TIntSpan2;
begin
  LAData[0] := 5;
  LAData[1] := 6;

  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(nil, 0)
  );

  try
    LSpan2.SubSpan(1, 2);
    Fail('Expected exception: Span2.SubSpan: range out of bounds');
  except
    on E: EOutOfRange do
      CheckEquals('Span2.SubSpan: range out of bounds', E.Message);
  end;
end;

procedure TTestCoreSpan.Test_Span2_Get_OutOfRange_Raises;
var
  LAData: array[0..0] of Integer;
  LSpan2: TIntSpan2;
begin
  LAData[0] := 42;
  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(nil, 0)
  );

  try
    LSpan2.Get(1);
    Fail('Expected exception: Span2.Get: index out of range');
  except
    on E: EOutOfRange do
      CheckEquals('Span2.Get: index out of range', E.Message);
  end;
end;

procedure TTestCoreSpan.Test_Span2_GetPtr_OutOfRange_Raises;
var
  LAData: array[0..0] of Integer;
  LSpan2: TIntSpan2;
begin
  LAData[0] := 42;
  LSpan2 := TIntSpan2.FromTwo(
    TIntSpan.FromPointer(@LAData[0], Length(LAData)),
    TIntSpan.FromPointer(nil, 0)
  );

  try
    LSpan2.GetPtr(1);
    Fail('Expected exception: Span2.GetPtr: index out of range');
  except
    on E: EOutOfRange do
      CheckEquals('Span2.GetPtr: index out of range', E.Message);
  end;
end;

initialization
  RegisterTest(TTestCoreSpan);

end.
