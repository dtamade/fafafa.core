unit fafafa.core.simd.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.types;

type
  // 全局函数测试：覆盖门面对外全部可见接口（含重载/变量函数）
  TTestCase_Global = class(TTestCase)
  published
    // 基本信息与强制配置
    procedure Test_SimdInfo_And_ForceProfile;

    // Mem
    procedure Test_MemEqual_Basic;
    procedure Test_MemFindByte_Basic;
    procedure Test_MemDiffRange_Basic;

    // Text
    procedure Test_Utf8Validate_Ascii_Valid;
    procedure Test_AsciiCase_ToLower_ToUpper;
    procedure Test_AsciiIEqual_Basic;

    // Bitset
    procedure Test_BitsetPopCount_Basic;

    // Search
    procedure Test_BytesIndexOf_Basic_And_Edges;

    // === 新增 SIMD 接口测试 ===

    // 内存操作
    procedure Test_MemCopy_Basic;
    procedure Test_MemSet_Basic;
    procedure Test_MemReverse_Basic;

    // 数值计算
    procedure Test_SumBytes_Basic;
    procedure Test_MinMaxBytes_Basic;
    procedure Test_CountByte_Basic;
  end;

implementation

procedure TTestCase_Global.Test_SimdInfo_And_ForceProfile;
var s: string;
buf: array[0..15] of Byte;
buf2: array[0..15] of Byte;
b: Boolean;
prevForced: string;
begin
  // 记录当前状态，并做一次轻量调用以确保已初始化
  FillChar(buf, SizeOf(buf), 0);
  FillChar(buf2, SizeOf(buf2), 0);
  prevForced := SimdGetForcedProfile;
  b := MemEqual(@buf[0], @buf2[0], SizeOf(buf));

  // 强制 SCALAR（不校验精确前缀，只校验包含关键字）
  SimdSetForcedProfile('SCALAR');
  s := UpperCase(SimdInfo);
  AssertTrue(Pos('SCALAR', s) > 0);
  // 恢复到之前的强制 Profile（若无则保持空）
  // 避免在测试中频繁切换，保持当前环境
  // if prevForced <> '' then
  //   SimdSetForcedProfile(prevForced);

  // 轻度断言：调用仍可用
  b := MemEqual(@buf[0], @buf2[0], SizeOf(buf));
  AssertTrue(b);
end;

procedure TTestCase_Global.Test_MemEqual_Basic;
var
  a, b: array[0..63] of Byte;
  boolEq: Boolean;
  i: Integer;
begin
  for i:=0 to High(a) do begin a[i] := i; b[i] := i; end;
  boolEq := MemEqual(@a[0], @b[0], Length(a));
  AssertTrue('MemEqual should be True for identical buffers', boolEq);
  b[7] := b[7] xor $FF;
  boolEq := MemEqual(@a[0], @b[0], Length(a));
  AssertTrue('MemEqual should detect difference', not boolEq);
end;

procedure TTestCase_Global.Test_MemFindByte_Basic;
var
  a: array[0..31] of Byte;
  idx: PtrInt;
  i: Integer;
begin
  for i:=0 to High(a) do a[i] := i;
  idx := MemFindByte(@a[0], Length(a), 7);
  AssertTrue('found byte 7', idx = 7);
  idx := MemFindByte(@a[0], Length(a), 255);
  AssertTrue('not found returns -1', idx = -1);
end;

procedure TTestCase_Global.Test_MemDiffRange_Basic;
var
  a, b: array[0..31] of Byte;
  r: TDiffRange;
begin
  FillChar(a, SizeOf(a), 0);
  FillChar(b, SizeOf(b), 0);
  r := MemDiffRange(@a[0], @b[0], Length(a));
  AssertTrue('equal => (-1,-1)', (r.First = -1) and (r.Last = -1));
  a[3] := 1; a[4] := 2; a[5] := 3;
  b[3] := 9; b[5] := 7;
  r := MemDiffRange(@a[0], @b[0], Length(a));
  AssertTrue('diff range starts at 3', r.First = 3);
  AssertTrue('diff range ends at 5', r.Last = 5);
end;

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

