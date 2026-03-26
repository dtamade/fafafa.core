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

initialization
  RegisterTest(TTestCoreSpan);

end.
