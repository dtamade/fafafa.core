{$CODEPAGE UTF8}
program quick_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.base,
  fafafa.core.simd.intrinsics.mmx;

procedure TestBasicOperations;
var
  a, b, result: TM64;
  i: Integer;
begin
  WriteLn('=== MMX 基本操作测试 ===');
  
  // 测试 setzero
  result := mmx_setzero_si64;
  Write('mmx_setzero_si64: ');
  if result.mm_u64 = 0 then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 set1_pi8
  result := mmx_set1_pi8(42);
  Write('mmx_set1_pi8(42): ');
  if (result.mm_i8[0] = 42) and (result.mm_i8[7] = 42) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 set_pi8
  result := mmx_set_pi8(7, 6, 5, 4, 3, 2, 1, 0);
  Write('mmx_set_pi8(7,6,5,4,3,2,1,0): ');
  if (result.mm_i8[0] = 0) and (result.mm_i8[7] = 7) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 paddb
  for i := 0 to 7 do
  begin
    a.mm_u8[i] := i + 1;
    b.mm_u8[i] := i + 10;
  end;
  result := mmx_paddb(a, b);
  Write('mmx_paddb: ');
  if (result.mm_u8[0] = 11) and (result.mm_u8[7] = 18) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 pand
  a.mm_u64 := $F0F0F0F0F0F0F0F0;
  b.mm_u64 := $0F0F0F0F0F0F0F0F;
  result := mmx_pand(a, b);
  Write('mmx_pand: ');
  if result.mm_u64 = 0 then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 por
  a.mm_u64 := $F0F0F0F0F0F0F0F0;
  b.mm_u64 := $0F0F0F0F0F0F0F0F;
  result := mmx_por(a, b);
  Write('mmx_por: ');
  if result.mm_u64 = $FFFFFFFFFFFFFFFF then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 psllw_imm
  a.mm_u16[0] := $0001;
  a.mm_u16[1] := $0002;
  result := mmx_psllw_imm(a, 2);
  Write('mmx_psllw_imm: ');
  if (result.mm_u16[0] = $0004) and (result.mm_u16[1] = $0008) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 emms
  mmx_emms;
  WriteLn('mmx_emms: ✓ 通过 (无异常)');
end;

procedure TestLoadStore;
var
  data32: LongWord;
  data64: QWord;
  mmx_val: TM64;
begin
  WriteLn('=== MMX Load/Store 测试 ===');
  
  // 测试 movd_mm
  data32 := $12345678;
  mmx_val := mmx_movd_mm(@data32);
  Write('mmx_movd_mm: ');
  if mmx_val.mm_u32[0] = $12345678 then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 movq_mm
  data64 := $123456789ABCDEF0;
  mmx_val := mmx_movq_mm(@data64);
  Write('mmx_movq_mm: ');
  if mmx_val.mm_u64 = $123456789ABCDEF0 then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 movd_r32
  mmx_val.mm_u64 := 0;
  mmx_val.mm_u32[0] := $87654321;
  data32 := mmx_movd_r32(mmx_val);
  Write('mmx_movd_r32: ');
  if data32 = $87654321 then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
end;

procedure TestArithmetic;
var
  a, b, result: TM64;
begin
  WriteLn('=== MMX 算术运算测试 ===');
  
  // 测试 paddw
  a.mm_u16[0] := 100;
  a.mm_u16[1] := 200;
  b.mm_u16[0] := 50;
  b.mm_u16[1] := 100;
  result := mmx_paddw(a, b);
  Write('mmx_paddw: ');
  if (result.mm_u16[0] = 150) and (result.mm_u16[1] = 300) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 psubw
  result := mmx_psubw(a, b);
  Write('mmx_psubw: ');
  if (result.mm_u16[0] = 50) and (result.mm_u16[1] = 100) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 pmullw
  a.mm_u16[0] := 10;
  a.mm_u16[1] := 20;
  b.mm_u16[0] := 3;
  b.mm_u16[1] := 4;
  result := mmx_pmullw(a, b);
  Write('mmx_pmullw: ');
  if (result.mm_u16[0] = 30) and (result.mm_u16[1] = 80) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
end;

procedure TestComparison;
var
  a, b, result: TM64;
begin
  WriteLn('=== MMX 比较操作测试 ===');
  
  // 测试 pcmpeqb
  a.mm_u8[0] := 10;
  a.mm_u8[1] := 20;
  b.mm_u8[0] := 10;
  b.mm_u8[1] := 30;
  result := mmx_pcmpeqb(a, b);
  Write('mmx_pcmpeqb: ');
  if (result.mm_u8[0] = $FF) and (result.mm_u8[1] = $00) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 pcmpgtb
  a.mm_i8[0] := 20;
  a.mm_i8[1] := 10;
  b.mm_i8[0] := 10;
  b.mm_i8[1] := 20;
  result := mmx_pcmpgtb(a, b);
  Write('mmx_pcmpgtb: ');
  if (result.mm_u8[0] = $FF) and (result.mm_u8[1] = $00) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
end;

procedure TestShift;
var
  a, count, result: TM64;
begin
  WriteLn('=== MMX 移位操作测试 ===');
  
  // 测试 psllw
  a.mm_u16[0] := $0001;
  a.mm_u16[1] := $0002;
  count.mm_u64 := 2;
  result := mmx_psllw(a, count);
  Write('mmx_psllw: ');
  if (result.mm_u16[0] = $0004) and (result.mm_u16[1] = $0008) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 psrlw
  a.mm_u16[0] := $0010;
  a.mm_u16[1] := $0020;
  result := mmx_psrlw(a, count);
  Write('mmx_psrlw: ');
  if (result.mm_u16[0] = $0004) and (result.mm_u16[1] = $0008) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 psraw
  a.mm_i16[0] := -16;
  a.mm_i16[1] := 16;
  result := mmx_psraw(a, count);
  Write('mmx_psraw: ');
  if (result.mm_i16[0] = -4) and (result.mm_i16[1] = 4) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
end;

procedure TestPackUnpack;
var
  a, b, result: TM64;
begin
  WriteLn('=== MMX 打包/解包测试 ===');
  
  // 测试 packsswb
  a.mm_i16[0] := 100;
  a.mm_i16[1] := 200;
  b.mm_i16[0] := 50;
  b.mm_i16[1] := 150;
  result := mmx_packsswb(a, b);
  Write('mmx_packsswb: ');
  if (result.mm_i8[0] = 100) and (result.mm_i8[1] = 200) and 
     (result.mm_i8[4] = 50) and (result.mm_i8[5] = 150) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
  
  // 测试 punpcklbw
  a.mm_u8[0] := 1;
  a.mm_u8[1] := 2;
  a.mm_u8[2] := 3;
  a.mm_u8[3] := 4;
  b.mm_u8[0] := 10;
  b.mm_u8[1] := 20;
  b.mm_u8[2] := 30;
  b.mm_u8[3] := 40;
  result := mmx_punpcklbw(a, b);
  Write('mmx_punpcklbw: ');
  if (result.mm_u8[0] = 1) and (result.mm_u8[1] = 10) and
     (result.mm_u8[2] = 2) and (result.mm_u8[3] = 20) then
    WriteLn('✓ 通过')
  else
    WriteLn('✗ 失败');
end;

begin
  WriteLn('MMX 指令集快速验证测试');
  WriteLn('========================');
  WriteLn;
  
  try
    TestBasicOperations;
    WriteLn;
    TestLoadStore;
    WriteLn;
    TestArithmetic;
    WriteLn;
    TestComparison;
    WriteLn;
    TestShift;
    WriteLn;
    TestPackUnpack;
    WriteLn;
    
    WriteLn('========================');
    WriteLn('所有测试完成！');
    WriteLn('如果看到 ✓ 表示测试通过');
    WriteLn('如果看到 ✗ 表示测试失败');
    
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按任意键退出...');
  ReadLn;
end.
