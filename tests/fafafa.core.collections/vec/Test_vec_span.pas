unit Test_vec_span;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.slice,
  fafafa.core.mem.allocator;

type
  TTestCase_Vec_Span = class(TTestCase)
  published
    procedure Test_SliceView_Empty;
    procedure Test_SliceView_TailSingle;
    procedure Test_SliceView_SubSpan;
  end;

implementation

procedure TTestCase_Vec_Span.Test_SliceView_Empty;
var
  V: specialize TVec<Integer>;
  S: specialize TReadOnlySpan<Integer>;
begin
  V := specialize TVec<Integer>.Create([7,8,9]);
  try
    S := V.SliceView(0, 0);
    AssertTrue(S.IsEmpty);
    AssertEquals(SizeUInt(0), S.Count);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_Span.Test_SliceView_TailSingle;
var
  V: specialize TVec<Integer>;
  S: specialize TReadOnlySpan<Integer>;
begin
  V := specialize TVec<Integer>.Create([7,8,9]);
  try
    S := V.SliceView(2, 1);
    AssertEquals(SizeUInt(1), S.Count);
    AssertEquals(9, S.Get(0));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Vec_Span.Test_SliceView_SubSpan;
var
  V: specialize TVec<Integer>;
  S: specialize TReadOnlySpan<Integer>;
begin
  V := specialize TVec<Integer>.Create([7,8,9]);
  try
    S := V.SliceView(0, 3).SubSpan(1, 2);
    AssertEquals(SizeUInt(2), S.Count);
    AssertEquals(8, S.Get(0));
    AssertEquals(9, S.Get(1));
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_Span);

end.
