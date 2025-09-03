program standalone_mmx_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils;

type
  // MMX 64-bit 向量类型
  TM64 = record
    case Integer of
      0: (mm_u64: UInt64);
      1: (mm_i64: Int64);
      2: (mm_u32: array[0..1] of UInt32);
      3: (mm_i32: array[0..1] of LongInt);
      4: (mm_u16: array[0..3] of UInt16);
      5: (mm_i16: array[0..3] of SmallInt);
      6: (mm_u8: array[0..7] of UInt8);
      7: (mm_i8: array[0..7] of ShortInt);
  end;

// 简单的 MMX 函数实现
function mmx_setzero_si64: TM64;
begin
  Result.mm_u64 := 0;
end;

function mmx_set1_pi32(Value: LongInt): TM64;
begin
  Result.mm_i32[0] := Value;
  Result.mm_i32[1] := Value;
end;

function mmx_set_pi32(a1, a0: LongInt): TM64;
begin
  Result.mm_i32[0] := a0;
  Result.mm_i32[1] := a1;
end;

function mmx_paddd(a, b: TM64): TM64;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.mm_i32[i] := a.mm_i32[i] + b.mm_i32[i];
end;

function mmx_psubd(a, b: TM64): TM64;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.mm_i32[i] := a.mm_i32[i] - b.mm_i32[i];
end;

function mmx_pand(a, b: TM64): TM64;
begin
  Result.mm_u64 := a.mm_u64 and b.mm_u64;
end;

function mmx_por(a, b: TM64): TM64;
begin
  Result.mm_u64 := a.mm_u64 or b.mm_u64;
end;

function mmx_pxor(a, b: TM64): TM64;
begin
  Result.mm_u64 := a.mm_u64 xor b.mm_u64;
end;

procedure mmx_emms;
begin
  // 空操作
end;

// 测试程序
var
  a, b, result: TM64;

begin
  WriteLn('独立 MMX 测试程序');
  WriteLn('==================');
  
  // 测试基本的 set 函数
  WriteLn('测试 Set 函数...');
  a := mmx_set1_pi32(42);
  WriteLn('mmx_set1_pi32(42): [', a.mm_i32[0], ', ', a.mm_i32[1], ']');
  
  b := mmx_set_pi32(100, 200);
  WriteLn('mmx_set_pi32(100, 200): [', b.mm_i32[0], ', ', b.mm_i32[1], ']');
  
  // 测试加法
  WriteLn('');
  WriteLn('测试加法...');
  result := mmx_paddd(a, b);
  WriteLn('paddd 结果: [', result.mm_i32[0], ', ', result.mm_i32[1], ']');
  WriteLn('预期: [242, 142]');
  
  // 测试减法
  WriteLn('');
  WriteLn('测试减法...');
  result := mmx_psubd(b, a);
  WriteLn('psubd 结果: [', result.mm_i32[0], ', ', result.mm_i32[1], ']');
  WriteLn('预期: [158, 58]');
  
  // 测试逻辑运算
  WriteLn('');
  WriteLn('测试逻辑运算...');
  a.mm_u64 := $F0F0F0F0F0F0F0F0;
  b.mm_u64 := $AAAAAAAAAAAAAAAA;
  
  WriteLn('a: $', IntToHex(a.mm_u64, 16));
  WriteLn('b: $', IntToHex(b.mm_u64, 16));
  
  result := mmx_pand(a, b);
  WriteLn('AND: $', IntToHex(result.mm_u64, 16));
  WriteLn('预期: $A0A0A0A0A0A0A0A0');
  
  result := mmx_por(a, b);
  WriteLn('OR:  $', IntToHex(result.mm_u64, 16));
  WriteLn('预期: $FAFAFAFAFAFAFAFAFA');
  
  result := mmx_pxor(a, b);
  WriteLn('XOR: $', IntToHex(result.mm_u64, 16));
  WriteLn('预期: $5A5A5A5A5A5A5A5A');
  
  // 调用 EMMS
  mmx_emms;
  
  WriteLn('');
  WriteLn('测试完成！');
  WriteLn('注意：这是 Pascal 模拟实现，实际 MMX 指令会更快。');
  
  ReadLn;
end.
