unit fafafa.core.simd.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.types;

type
  // 新SIMD模块测试：测试核心已实现的功能
  TTestCase_Global = class(TTestCase)
  published
    // 算术运算测试
    procedure Test_Arithmetic_Add_F32x4;
    procedure Test_Arithmetic_Sub_F32x4;
    procedure Test_Arithmetic_Mul_F32x4;
    procedure Test_Arithmetic_Div_F32x4;

    // 比较运算测试
    procedure Test_Compare_Eq_F32x4;
    procedure Test_Compare_Lt_F32x4;

    // 数学函数测试
    procedure Test_Math_Abs_F32x4;
    procedure Test_Math_Sqrt_F32x4;
    procedure Test_Math_Min_Max_F32x4;

    // 聚合运算测试
    procedure Test_Reduce_Add_F32x4;
    procedure Test_Reduce_Min_Max_F32x4;

    // 整数运算测试
    procedure Test_Arithmetic_Add_I32x4;
    procedure Test_Compare_Eq_I32x4;
    procedure Test_Math_Abs_I32x4;
    procedure Test_Reduce_Add_I32x4;
  end;

implementation

// === 算术运算测试 ===

procedure TTestCase_Global.Test_Arithmetic_Add_F32x4;
var
  a, b, result: TSimdF32x4;
  i: Integer;
begin
  // 初始化测试数据
  for i := 0 to 3 do
  begin
    a[i] := i + 1.0;  // [1.0, 2.0, 3.0, 4.0]
    b[i] := i * 2.0;  // [0.0, 2.0, 4.0, 6.0]
  end;

  // 执行加法运算
  result := simd_add_f32x4(a, b);

  // 验证结果
  AssertEquals('Add[0]', 1.0, result[0], 0.001);
  AssertEquals('Add[1]', 4.0, result[1], 0.001);
  AssertEquals('Add[2]', 7.0, result[2], 0.001);
  AssertEquals('Add[3]', 10.0, result[3], 0.001);
end;

procedure TTestCase_Global.Test_Arithmetic_Sub_F32x4;
var
  a, b, result: TSimdF32x4;
  i: Integer;
begin
  // 初始化测试数据
  for i := 0 to 3 do
  begin
    a[i] := (i + 1) * 3.0;  // [3.0, 6.0, 9.0, 12.0]
    b[i] := i + 1.0;        // [1.0, 2.0, 3.0, 4.0]
  end;

  // 执行减法运算
  result := simd_sub_f32x4(a, b);

  // 验证结果
  AssertEquals('Sub[0]', 2.0, result[0], 0.001);
  AssertEquals('Sub[1]', 4.0, result[1], 0.001);
  AssertEquals('Sub[2]', 6.0, result[2], 0.001);
  AssertEquals('Sub[3]', 8.0, result[3], 0.001);
end;

procedure TTestCase_Global.Test_Arithmetic_Mul_F32x4;
var
  a, b, result: TSimdF32x4;
  i: Integer;
begin
  // 初始化测试数据
  for i := 0 to 3 do
  begin
    a[i] := i + 2.0;  // [2.0, 3.0, 4.0, 5.0]
    b[i] := 2.0;      // [2.0, 2.0, 2.0, 2.0]
  end;

  // 执行乘法运算
  result := simd_mul_f32x4(a, b);

  // 验证结果
  AssertEquals('Mul[0]', 4.0, result[0], 0.001);
  AssertEquals('Mul[1]', 6.0, result[1], 0.001);
  AssertEquals('Mul[2]', 8.0, result[2], 0.001);
  AssertEquals('Mul[3]', 10.0, result[3], 0.001);
end;

procedure TTestCase_Global.Test_Arithmetic_Div_F32x4;
var
  a, b, result: TSimdF32x4;
  i: Integer;
begin
  // 初始化测试数据
  for i := 0 to 3 do
  begin
    a[i] := (i + 1) * 4.0;  // [4.0, 8.0, 12.0, 16.0]
    b[i] := 2.0;            // [2.0, 2.0, 2.0, 2.0]
  end;

  // 执行除法运算
  result := simd_div_f32x4(a, b);

  // 验证结果
  AssertEquals('Div[0]', 2.0, result[0], 0.001);
  AssertEquals('Div[1]', 4.0, result[1], 0.001);
  AssertEquals('Div[2]', 6.0, result[2], 0.001);
  AssertEquals('Div[3]', 8.0, result[3], 0.001);
end;

// === 比较运算测试 ===

procedure TTestCase_Global.Test_Compare_Eq_F32x4;
var
  a, b: TSimdF32x4;
  mask: TSimdMask4;
begin
  // 初始化测试数据
  a[0] := 1.0; a[1] := 2.0; a[2] := 3.0; a[3] := 4.0;
  b[0] := 1.0; b[1] := 5.0; b[2] := 3.0; b[3] := 7.0;

  // 执行相等比较
  mask := simd_eq_f32x4(a, b);

  // 验证结果
  AssertTrue('Eq[0]', mask[0]);   // 1.0 == 1.0
  AssertFalse('Eq[1]', mask[1]); // 2.0 != 5.0
  AssertTrue('Eq[2]', mask[2]);   // 3.0 == 3.0
  AssertFalse('Eq[3]', mask[3]); // 4.0 != 7.0
end;

procedure TTestCase_Global.Test_Compare_Lt_F32x4;
var
  a, b: TSimdF32x4;
  mask: TSimdMask4;
begin
  // 初始化测试数据
  a[0] := 1.0; a[1] := 5.0; a[2] := 3.0; a[3] := 8.0;
  b[0] := 2.0; b[1] := 4.0; b[2] := 3.0; b[3] := 7.0;

  // 执行小于比较
  mask := simd_lt_f32x4(a, b);

  // 验证结果
  AssertTrue('Lt[0]', mask[0]);   // 1.0 < 2.0
  AssertFalse('Lt[1]', mask[1]); // 5.0 >= 4.0
  AssertFalse('Lt[2]', mask[2]); // 3.0 >= 3.0
  AssertFalse('Lt[3]', mask[3]); // 8.0 >= 7.0
end;

// === 数学函数测试 ===

procedure TTestCase_Global.Test_Math_Abs_F32x4;
var
  a, result: TSimdF32x4;
begin
  // 初始化测试数据（包含正数、负数、零）
  a[0] := -3.5; a[1] := 2.0; a[2] := 0.0; a[3] := -7.2;

  // 执行绝对值运算
  result := simd_abs_f32x4(a);

  // 验证结果
  AssertEquals('Abs[0]', 3.5, result[0], 0.001);
  AssertEquals('Abs[1]', 2.0, result[1], 0.001);
  AssertEquals('Abs[2]', 0.0, result[2], 0.001);
  AssertEquals('Abs[3]', 7.2, result[3], 0.001);
end;

procedure TTestCase_Global.Test_Math_Sqrt_F32x4;
var
  a, result: TSimdF32x4;
begin
  // 初始化测试数据
  a[0] := 4.0; a[1] := 9.0; a[2] := 16.0; a[3] := 25.0;

  // 执行平方根运算
  result := simd_sqrt_f32x4(a);

  // 验证结果
  AssertEquals('Sqrt[0]', 2.0, result[0], 0.001);
  AssertEquals('Sqrt[1]', 3.0, result[1], 0.001);
  AssertEquals('Sqrt[2]', 4.0, result[2], 0.001);
  AssertEquals('Sqrt[3]', 5.0, result[3], 0.001);
end;

procedure TTestCase_Global.Test_Math_Min_Max_F32x4;
var
  a, b, min_result, max_result: TSimdF32x4;
begin
  // 初始化测试数据
  a[0] := 1.0; a[1] := 5.0; a[2] := 3.0; a[3] := 8.0;
  b[0] := 2.0; b[1] := 4.0; b[2] := 6.0; b[3] := 7.0;

  // 执行最小值和最大值运算
  min_result := simd_min_f32x4(a, b);
  max_result := simd_max_f32x4(a, b);

  // 验证最小值结果
  AssertEquals('Min[0]', 1.0, min_result[0], 0.001);
  AssertEquals('Min[1]', 4.0, min_result[1], 0.001);
  AssertEquals('Min[2]', 3.0, min_result[2], 0.001);
  AssertEquals('Min[3]', 7.0, min_result[3], 0.001);

  // 验证最大值结果
  AssertEquals('Max[0]', 2.0, max_result[0], 0.001);
  AssertEquals('Max[1]', 5.0, max_result[1], 0.001);
  AssertEquals('Max[2]', 6.0, max_result[2], 0.001);
  AssertEquals('Max[3]', 8.0, max_result[3], 0.001);
end;

// === 聚合运算测试 ===

procedure TTestCase_Global.Test_Reduce_Add_F32x4;
var
  a: TSimdF32x4;
  result: Single;
begin
  // 初始化测试数据
  a[0] := 1.0; a[1] := 2.0; a[2] := 3.0; a[3] := 4.0;

  // 执行求和聚合运算
  result := simd_reduce_add_f32x4(a);

  // 验证结果 (1.0 + 2.0 + 3.0 + 4.0 = 10.0)
  AssertEquals('ReduceAdd', 10.0, result, 0.001);
end;

procedure TTestCase_Global.Test_Reduce_Min_Max_F32x4;
var
  a: TSimdF32x4;
  min_result, max_result: Single;
begin
  // 初始化测试数据
  a[0] := 3.5; a[1] := 1.2; a[2] := 7.8; a[3] := 2.1;

  // 执行最小值和最大值聚合运算
  min_result := simd_reduce_min_f32x4(a);
  max_result := simd_reduce_max_f32x4(a);

  // 验证结果
  AssertEquals('ReduceMin', 1.2, min_result, 0.001);
  AssertEquals('ReduceMax', 7.8, max_result, 0.001);
end;

// === 整数运算测试 ===

procedure TTestCase_Global.Test_Arithmetic_Add_I32x4;
var
  a, b, result: TSimdI32x4;
  i: Integer;
begin
  // 初始化测试数据
  for i := 0 to 3 do
  begin
    a[i] := (i + 1) * 10;  // [10, 20, 30, 40]
    b[i] := i * 5;         // [0, 5, 10, 15]
  end;

  // 执行加法运算
  result := simd_add_i32x4(a, b);

  // 验证结果
  AssertEquals('AddI32[0]', 10, result[0]);
  AssertEquals('AddI32[1]', 25, result[1]);
  AssertEquals('AddI32[2]', 40, result[2]);
  AssertEquals('AddI32[3]', 55, result[3]);
end;

procedure TTestCase_Global.Test_Compare_Eq_I32x4;
var
  a, b: TSimdI32x4;
  mask: TSimdMask4;
begin
  // 初始化测试数据
  a[0] := 10; a[1] := 20; a[2] := 30; a[3] := 40;
  b[0] := 10; b[1] := 25; b[2] := 30; b[3] := 50;

  // 执行相等比较
  mask := simd_eq_i32x4(a, b);

  // 验证结果
  AssertTrue('EqI32[0]', mask[0]);   // 10 == 10
  AssertFalse('EqI32[1]', mask[1]); // 20 != 25
  AssertTrue('EqI32[2]', mask[2]);   // 30 == 30
  AssertFalse('EqI32[3]', mask[3]); // 40 != 50
end;

procedure TTestCase_Global.Test_Math_Abs_I32x4;
var
  a, result: TSimdI32x4;
begin
  // 初始化测试数据（包含正数、负数、零）
  a[0] := -15; a[1] := 25; a[2] := 0; a[3] := -100;

  // 执行绝对值运算
  result := simd_abs_i32x4(a);

  // 验证结果
  AssertEquals('AbsI32[0]', 15, result[0]);
  AssertEquals('AbsI32[1]', 25, result[1]);
  AssertEquals('AbsI32[2]', 0, result[2]);
  AssertEquals('AbsI32[3]', 100, result[3]);
end;

procedure TTestCase_Global.Test_Reduce_Add_I32x4;
var
  a: TSimdI32x4;
  result: Int32;
begin
  // 初始化测试数据
  a[0] := 5; a[1] := 10; a[2] := 15; a[3] := 20;

  // 执行求和聚合运算
  result := simd_reduce_add_i32x4(a);

  // 验证结果 (5 + 10 + 15 + 20 = 50)
  AssertEquals('ReduceAddI32', 50, result);
end;

// 测试完成，所有新SIMD模块的核心功能都已测试

initialization
  RegisterTest(TTestCase_Global);

end.

procedure TTestCase_Global.Test_Utf8Validate_Ascii_Valid;
var
  s: AnsiString;
  bytes: TBytes;
  ok: Boolean;
buf: array[0..7] of Byte;
begin
  s := 'HELLO world 1234';
  SetLength(bytes, Length(s));
  Move(PAnsiChar(s)^, bytes[0], Length(s));
  ok := Utf8Validate(@bytes[0], Length(bytes));
  AssertTrue('ASCII is valid UTF-8', ok);
  // 非法续字节
  FillChar(buf, SizeOf(buf), 0);
  buf[0] := $E2; buf[1] := $28; buf[2] := $A1; // 错序样例（应判 False）
  ok := Utf8Validate(@buf[0], 3);
  AssertTrue('invalid sequence rejected', not ok);
end;

procedure TTestCase_Global.Test_AsciiCase_ToLower_ToUpper;
var
  s: AnsiString;
  bytes, ref: TBytes;
  i: Integer;
begin
  s := 'AbC-xyz_09';
  SetLength(bytes, Length(s));
  Move(PAnsiChar(s)^, bytes[0], Length(s));
  ref := Copy(bytes, 0, Length(bytes));
  // Lower
  ToLowerAscii(@bytes[0], Length(bytes));
  for i:=0 to High(ref) do
    if (ref[i] >= Ord('A')) and (ref[i] <= Ord('Z')) then ref[i] := ref[i] + 32;
  AssertTrue('tolower matches ref', CompareMem(@bytes[0], @ref[0], Length(bytes)));
  // Upper
  ToUpperAscii(@bytes[0], Length(bytes));
  for i:=0 to High(ref) do
    if (ref[i] >= Ord('a')) and (ref[i] <= Ord('z')) then ref[i] := ref[i] - 32;
  AssertTrue('toupper matches ref', CompareMem(@bytes[0], @ref[0], Length(bytes)));
end;

procedure TTestCase_Global.Test_AsciiIEqual_Basic;
var
  a, b: AnsiString;
  ba, bb: TBytes;
  ok: Boolean;
begin
  a := 'Hello'; b := 'hELLo';
  SetLength(ba, Length(a)); Move(PAnsiChar(a)^, ba[0], Length(a));
  SetLength(bb, Length(b)); Move(PAnsiChar(b)^, bb[0], Length(b));
  ok := AsciiIEqual(@ba[0], @bb[0], Length(ba));
  AssertTrue('case-insensitive equal', ok);
  if Length(ba) > 0 then ba[0] := Ord('X');
  ok := AsciiIEqual(@ba[0], @bb[0], Length(ba));
  AssertTrue('detect difference', not ok);
end;

procedure TTestCase_Global.Test_BitsetPopCount_Basic;
var
  bytes: array[0..3] of Byte;
  c: SizeUInt;
begin
  // 0xFF,0x0F,0x55,0x80 -> popcnt = 8 + 4 + 4 + 1 = 17
  bytes[0] := $FF; bytes[1] := $0F; bytes[2] := $55; bytes[3] := $80;
  c := BitsetPopCount(@bytes[0], 32);
  AssertTrue('popcount expected 17', c = 17);
end;

procedure TTestCase_Global.Test_BytesIndexOf_Basic_And_Edges;
var
  hay, ned: TBytes;
  idx: PtrInt;
  s: AnsiString;
begin
  s := 'hello world';
  SetLength(hay, Length(s)); Move(PAnsiChar(s)^, hay[0], Length(s));
  SetLength(ned, 5); Move(PAnsiChar(AnsiString('world'))^, ned[0], 5);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('IndexOf basic', idx = 6);
  // 边界：空 needle => 0
  idx := BytesIndexOf(@hay[0], Length(hay), nil, 0);
  AssertTrue('empty needle => 0', idx = 0);
  // needle 长于 hay => -1
  idx := BytesIndexOf(@hay[0], Length(hay), @hay[0], Length(hay)+1);
  AssertTrue('nlen>len => -1', idx = -1);
end;

// === 新增 SIMD 接口测试实现 ===

procedure TTestCase_Global.Test_MemCopy_Basic;
var
  src, dest: array[0..15] of Byte;
  i: Integer;
begin
  // 初始化源数据
  for i := 0 to 15 do
    src[i] := i;

  // 清空目标数据
  FillChar(dest, SizeOf(dest), 0);

  // 测试复制
  MemCopy(@dest[0], @src[0], 16);

  // 验证结果
  for i := 0 to 15 do
    AssertEquals('MemCopy byte ' + IntToStr(i), src[i], dest[i]);
end;

procedure TTestCase_Global.Test_MemSet_Basic;
var
  data: array[0..15] of Byte;
  i: Integer;
begin
  // 测试填充
  MemSet(@data[0], $AA, 16);

  // 验证结果
  for i := 0 to 15 do
    AssertEquals('MemSet byte ' + IntToStr(i), $AA, data[i]);

  // 测试零长度
  MemSet(@data[0], $BB, 0);
  AssertEquals('MemSet zero length should not change', $AA, data[0]);
end;

procedure TTestCase_Global.Test_MemReverse_Basic;
var
  data: array[0..7] of Byte;
  i: Integer;
begin
  // 初始化数据
  for i := 0 to 7 do
    data[i] := i;

  // 测试反转
  MemReverse(@data[0], 8);

  // 验证结果
  for i := 0 to 7 do
    AssertEquals('MemReverse byte ' + IntToStr(i), 7 - i, data[i]);
end;

procedure TTestCase_Global.Test_SumBytes_Basic;
var
  data: array[0..3] of Byte;
  sum: QWord;
begin
  // 测试数据：1, 2, 3, 4
  data[0] := 1;
  data[1] := 2;
  data[2] := 3;
  data[3] := 4;

  sum := SumBytes(@data[0], 4);
  AssertEquals('SumBytes 1+2+3+4', QWord(10), sum);

  // 测试零长度
  sum := SumBytes(@data[0], 0);
  AssertEquals('SumBytes zero length', QWord(0), sum);
end;

procedure TTestCase_Global.Test_MinMaxBytes_Basic;
var
  data: array[0..4] of Byte;
  minVal, maxVal: Byte;
begin
  // 测试数据：5, 1, 9, 3, 7
  data[0] := 5;
  data[1] := 1;
  data[2] := 9;
  data[3] := 3;
  data[4] := 7;

  MinMaxBytes(@data[0], 5, minVal, maxVal);
  AssertEquals('MinMaxBytes min', 1, minVal);
  AssertEquals('MinMaxBytes max', 9, maxVal);

  // 测试单个元素
  MinMaxBytes(@data[0], 1, minVal, maxVal);
  AssertEquals('MinMaxBytes single min', 5, minVal);
  AssertEquals('MinMaxBytes single max', 5, maxVal);
end;

procedure TTestCase_Global.Test_CountByte_Basic;
var
  data: array[0..7] of Byte;
  count: SizeUInt;
begin
  // 测试数据：1, 2, 1, 3, 1, 4, 1, 5
  data[0] := 1; data[1] := 2; data[2] := 1; data[3] := 3;
  data[4] := 1; data[5] := 4; data[6] := 1; data[7] := 5;

  count := CountByte(@data[0], 8, 1);
  AssertEquals('CountByte count of 1', SizeUInt(4), count);

  count := CountByte(@data[0], 8, 9);
  AssertEquals('CountByte count of 9 (not found)', SizeUInt(0), count);

  // 测试零长度
  count := CountByte(@data[0], 0, 1);
  AssertEquals('CountByte zero length', SizeUInt(0), count);
end;

initialization
  RegisterTest(TTestCase_Global);

end.

