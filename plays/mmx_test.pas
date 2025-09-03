program mmx_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

procedure TestMMXBasics;
var
  a, b, result: TM64;
  i: Integer;
begin
  WriteLn('=== MMX 基础测试 ===');
  
  // 测试 Set 函数
  WriteLn('测试 Set 函数...');
  a := mmx_set1_pi32(42);
  WriteLn('mmx_set1_pi32(42): [', a.mm_i32[0], ', ', a.mm_i32[1], ']');
  
  b := mmx_set_pi32(100, 200);
  WriteLn('mmx_set_pi32(100, 200): [', b.mm_i32[0], ', ', b.mm_i32[1], ']');
  
  // 测试加法
  WriteLn('测试加法...');
  result := mmx_paddd(a, b);
  WriteLn('paddd 结果: [', result.mm_i32[0], ', ', result.mm_i32[1], ']');
  
  // 测试 16 位运算
  WriteLn('测试 16 位运算...');
  a := mmx_set_pi16(1, 2, 3, 4);
  b := mmx_set_pi16(10, 20, 30, 40);
  WriteLn('a: [', a.mm_i16[0], ', ', a.mm_i16[1], ', ', a.mm_i16[2], ', ', a.mm_i16[3], ']');
  WriteLn('b: [', b.mm_i16[0], ', ', b.mm_i16[1], ', ', b.mm_i16[2], ', ', b.mm_i16[3], ']');
  
  result := mmx_paddw(a, b);
  WriteLn('paddw 结果: [', result.mm_i16[0], ', ', result.mm_i16[1], ', ', result.mm_i16[2], ', ', result.mm_i16[3], ']');
  
  // 测试 8 位运算
  WriteLn('测试 8 位运算...');
  a := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  Write('a: [');
  for i := 0 to 7 do
  begin
    Write(a.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b: [');
  for i := 0 to 7 do
  begin
    Write(b.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  result := mmx_paddb(a, b);
  Write('paddb 结果: [');
  for i := 0 to 7 do
  begin
    Write(result.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
end;

procedure TestMMXSaturated;
var
  a, b, result: TM64;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== MMX 饱和运算测试 ===');
  
  // 测试有符号饱和加法
  WriteLn('测试有符号 8 位饱和加法...');
  a := mmx_set_pi8(120, 120, -120, -120, 100, 100, -100, -100);
  b := mmx_set_pi8(20, 50, -20, -50, 10, 50, -10, -50);
  
  Write('a: [');
  for i := 0 to 7 do
  begin
    Write(a.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  Write('b: [');
  for i := 0 to 7 do
  begin
    Write(b.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  result := mmx_paddsb(a, b);
  Write('paddsb 结果: [');
  for i := 0 to 7 do
  begin
    Write(result.mm_i8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  WriteLn('(应该看到饱和到 127 和 -128)');
  
  // 测试无符号饱和加法
  WriteLn('');
  WriteLn('测试无符号 8 位饱和加法...');
  a := mmx_set1_pi8(200);  // 作为无符号数是 200
  b := mmx_set1_pi8(100);  // 作为无符号数是 100
  
  result := mmx_paddusb(a, b);
  Write('paddusb 结果: [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  WriteLn('(应该看到饱和到 255)');
end;

procedure TestMMXLogical;
var
  a, b, result: TM64;
begin
  WriteLn('');
  WriteLn('=== MMX 逻辑运算测试 ===');
  
  a.mm_u64 := $F0F0F0F0F0F0F0F0;
  b.mm_u64 := $AAAAAAAAAAAAAAAA;
  
  WriteLn('a: $', IntToHex(a.mm_u64, 16));
  WriteLn('b: $', IntToHex(b.mm_u64, 16));
  
  result := mmx_pand(a, b);
  WriteLn('AND: $', IntToHex(result.mm_u64, 16));
  
  result := mmx_por(a, b);
  WriteLn('OR:  $', IntToHex(result.mm_u64, 16));
  
  result := mmx_pxor(a, b);
  WriteLn('XOR: $', IntToHex(result.mm_u64, 16));
  
  result := mmx_pandn(a, b);
  WriteLn('ANDN: $', IntToHex(result.mm_u64, 16));
end;

procedure TestMMXCompare;
var
  a, b, result: TM64;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== MMX 比较运算测试 ===');
  
  a := mmx_set_pi16(10, 20, 30, 40);
  b := mmx_set_pi16(10, 15, 35, 40);
  
  WriteLn('a: [', a.mm_i16[0], ', ', a.mm_i16[1], ', ', a.mm_i16[2], ', ', a.mm_i16[3], ']');
  WriteLn('b: [', b.mm_i16[0], ', ', b.mm_i16[1], ', ', b.mm_i16[2], ', ', b.mm_i16[3], ']');
  
  result := mmx_pcmpeqw(a, b);
  Write('相等比较: [');
  for i := 0 to 3 do
  begin
    Write('$', IntToHex(result.mm_u16[i], 4));
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := mmx_pcmpgtw(a, b);
  Write('大于比较: [');
  for i := 0 to 3 do
  begin
    Write('$', IntToHex(result.mm_u16[i], 4));
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
end;

procedure TestMMXShift;
var
  a, result: TM64;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== MMX 移位运算测试 ===');
  
  a := mmx_set_pi16(1, 2, 4, 8);
  WriteLn('原始值: [', a.mm_i16[0], ', ', a.mm_i16[1], ', ', a.mm_i16[2], ', ', a.mm_i16[3], ']');
  
  result := mmx_psllw_imm(a, 2);
  WriteLn('左移 2 位: [', result.mm_i16[0], ', ', result.mm_i16[1], ', ', result.mm_i16[2], ', ', result.mm_i16[3], ']');
  
  result := mmx_psrlw_imm(a, 1);
  WriteLn('逻辑右移 1 位: [', result.mm_i16[0], ', ', result.mm_i16[1], ', ', result.mm_i16[2], ', ', result.mm_i16[3], ']');
  
  // 测试算术右移
  a := mmx_set_pi16(-8, -4, -2, -1);
  WriteLn('负数原始值: [', a.mm_i16[0], ', ', a.mm_i16[1], ', ', a.mm_i16[2], ', ', a.mm_i16[3], ']');
  
  result := mmx_psraw_imm(a, 1);
  WriteLn('算术右移 1 位: [', result.mm_i16[0], ', ', result.mm_i16[1], ', ', result.mm_i16[2], ', ', result.mm_i16[3], ']');
end;

procedure TestMMXPackUnpack;
var
  a, b, result: TM64;
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== MMX 打包/解包测试 ===');
  
  // 测试打包
  a := mmx_set_pi16(300, 200, 100, 50);   // 超出 8 位范围的值
  b := mmx_set_pi16(400, 150, 75, 25);
  
  WriteLn('a (16位): [', a.mm_i16[0], ', ', a.mm_i16[1], ', ', a.mm_i16[2], ', ', a.mm_i16[3], ']');
  WriteLn('b (16位): [', b.mm_i16[0], ', ', b.mm_i16[1], ', ', b.mm_i16[2], ', ', b.mm_i16[3], ']');
  
  result := mmx_packuswb(a, b);
  Write('无符号饱和打包到 8 位: [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  // 测试解包
  a := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  
  result := mmx_punpcklbw(a, b);
  Write('低位解包交织: [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  result := mmx_punpckhbw(a, b);
  Write('高位解包交织: [');
  for i := 0 to 7 do
  begin
    Write(result.mm_u8[i]);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
end;

begin
  WriteLn('MMX 指令集测试程序');
  WriteLn('==================');
  
  TestMMXBasics;
  TestMMXSaturated;
  TestMMXLogical;
  TestMMXCompare;
  TestMMXShift;
  TestMMXPackUnpack;
  
  WriteLn('');
  WriteLn('测试完成！');
  WriteLn('注意：这是 Pascal 模拟实现，实际 MMX 指令会更快。');
  
  // 调用 EMMS（虽然在我们的实现中是空操作）
  mmx_emms;
  
  ReadLn;
end.
