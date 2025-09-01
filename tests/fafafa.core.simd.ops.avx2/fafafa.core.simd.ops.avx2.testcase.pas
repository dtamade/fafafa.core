unit fafafa.core.simd.ops.avx2.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.simd.types,
  fafafa.core.simd.ops;

type
  TTestCase_VecF32x8 = class(TTestCase)
  published
    procedure Test_SetAll_Zero;
    procedure Test_Add_Mul_LoadStoreUnaligned;
  end;

  TTestCase_VecI32x8 = class(TTestCase)
  published
    procedure Test_SetAll_Zero;
    procedure Test_Add_Sub_Mul_LoadStoreUnaligned;
  end;

implementation

{ TTestCase_VecF32x8 }

procedure TTestCase_VecF32x8.Test_SetAll_Zero;
var
  v, z: TVecF32x8;
  i: Integer;
begin
  v := VecF32x8_SetAll(3.5);
  for i := 0 to 7 do
    AssertTrue(Format('SetAll mismatch at %d', [i]), Abs(v.f[i] - 3.5) < 1e-6);

  z := VecF32x8_Zero;
  for i := 0 to 7 do
    AssertTrue(Format('Zero mismatch at %d', [i]), Abs(z.f[i]) < 1e-30);
end;

procedure TTestCase_VecF32x8.Test_Add_Mul_LoadStoreUnaligned;
var
  a, b, c, loaded: TVecF32x8;
  buf: array[0..7] of Single;
  i: Integer;
begin
  for i := 0 to 7 do begin a.f[i] := i + 1; b.f[i] := (i + 1) * 10; end;

  // 加法
  c := VecF32x8_Add(a, b);
  for i := 0 to 7 do
    AssertTrue(Format('Add mismatch at %d', [i]), Abs(c.f[i] - (a.f[i] + b.f[i])) < 1e-6);

  // 乘法
  c := VecF32x8_Mul(a, b);
  for i := 0 to 7 do
    AssertTrue(Format('Mul mismatch at %d', [i]), Abs(c.f[i] - (a.f[i] * b.f[i])) < 1e-5);

  // 非对齐 Load/Store
  for i := 0 to 7 do buf[i] := i * 1.25;
  loaded := VecF32x8_LoadUnaligned(@buf[0]);
  for i := 0 to 7 do
    AssertTrue(Format('LoadUnaligned mismatch at %d', [i]), Abs(loaded.f[i] - buf[i]) < 1e-6);

  // StoreUnaligned 再读回校验
  FillChar(buf, SizeOf(buf), 0);
  VecF32x8_StoreUnaligned(loaded, @buf[0]);
  for i := 0 to 7 do
    AssertTrue(Format('StoreUnaligned mismatch at %d', [i]), Abs(buf[i] - loaded.f[i]) < 1e-6);
end;

{ TTestCase_VecI32x8 }

procedure TTestCase_VecI32x8.Test_SetAll_Zero;
var
  v, z: TVecI32x8;
  i: Integer;
begin
  v := VecI32x8_SetAll(7);
  for i := 0 to 7 do
    AssertEquals(Format('SetAll mismatch at %d', [i]), 7, v.i[i]);

  z := VecI32x8_Zero;
  for i := 0 to 7 do
    AssertEquals(Format('Zero mismatch at %d', [i]), 0, z.i[i]);
end;

procedure TTestCase_VecI32x8.Test_Add_Sub_Mul_LoadStoreUnaligned;
var
  a, b, c, loaded: TVecI32x8;
  buf: array[0..7] of Int32;
  i: Integer;
begin
  for i := 0 to 7 do begin a.i[i] := i + 2; b.i[i] := (i + 1) * 3; end;

  // 加法
  c := VecI32x8_Add(a, b);
  for i := 0 to 7 do
    AssertEquals(Format('Add mismatch at %d', [i]), a.i[i] + b.i[i], c.i[i]);

  // 减法
  c := VecI32x8_Sub(a, b);
  for i := 0 to 7 do
    AssertEquals(Format('Sub mismatch at %d', [i]), a.i[i] - b.i[i], c.i[i]);

  // 乘法
  c := VecI32x8_Mul(a, b);
  for i := 0 to 7 do
    AssertEquals(Format('Mul mismatch at %d', [i]), a.i[i] * b.i[i], c.i[i]);

  // 非对齐 Load/Store
  for i := 0 to 7 do buf[i] := (i + 5) * 11;
  loaded := VecI32x8_LoadUnaligned(@buf[0]);
  for i := 0 to 7 do
    AssertEquals(Format('LoadUnaligned mismatch at %d', [i]), buf[i], loaded.i[i]);

  FillChar(buf, SizeOf(buf), 0);
  VecI32x8_StoreUnaligned(loaded, @buf[0]);
  for i := 0 to 7 do
    AssertEquals(Format('StoreUnaligned mismatch at %d', [i]), loaded.i[i], buf[i]);
end;

initialization
  RegisterTest(TTestCase_VecF32x8);
  RegisterTest(TTestCase_VecI32x8);

end.
