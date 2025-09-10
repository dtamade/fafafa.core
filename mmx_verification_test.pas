program mmx_verification_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.intrinsics.mmx;

var
  result: TM64;
  a, b: TM64;
  i: Integer;
  testsPassed: Integer;
  testsTotal: Integer;

procedure TestResult(testName: string; condition: Boolean);
begin
  Inc(testsTotal);
  Write(testName, ': ');
  if condition then
  begin
    WriteLn('✓ PASS');
    Inc(testsPassed);
  end
  else
    WriteLn('✗ FAIL');
end;

begin
  WriteLn('MMX 指令集验证测试');
  WriteLn('==================');
  WriteLn;
  
  testsPassed := 0;
  testsTotal := 0;
  
  try
    // 测试 1: mmx_setzero_si64
    result := mmx_setzero_si64;
    TestResult('mmx_setzero_si64', result.mm_u64 = 0);
    
    // 测试 2: mmx_set1_pi8
    result := mmx_set1_pi8(42);
    TestResult('mmx_set1_pi8(42)', (result.mm_i8[0] = 42) and (result.mm_i8[7] = 42));
    
    // 测试 3: mmx_set1_pi16
    result := mmx_set1_pi16(1234);
    TestResult('mmx_set1_pi16(1234)', (result.mm_i16[0] = 1234) and (result.mm_i16[3] = 1234));
    
    // 测试 4: mmx_set1_pi32
    result := mmx_set1_pi32(123456);
    TestResult('mmx_set1_pi32(123456)', (result.mm_i32[0] = 123456) and (result.mm_i32[1] = 123456));
    
    // 测试 5: mmx_set_pi8
    result := mmx_set_pi8(7, 6, 5, 4, 3, 2, 1, 0);
    TestResult('mmx_set_pi8(7,6,5,4,3,2,1,0)', 
               (result.mm_i8[0] = 0) and (result.mm_i8[7] = 7));
    
    // 测试 6: mmx_set_pi16
    result := mmx_set_pi16(3, 2, 1, 0);
    TestResult('mmx_set_pi16(3,2,1,0)', 
               (result.mm_i16[0] = 0) and (result.mm_i16[3] = 3));
    
    // 测试 7: mmx_set_pi32
    result := mmx_set_pi32(1, 0);
    TestResult('mmx_set_pi32(1,0)', 
               (result.mm_i32[0] = 0) and (result.mm_i32[1] = 1));
    
    // 测试 8: mmx_paddb
    for i := 0 to 7 do
    begin
      a.mm_u8[i] := i + 1;
      b.mm_u8[i] := i + 10;
    end;
    result := mmx_paddb(a, b);
    TestResult('mmx_paddb', (result.mm_u8[0] = 11) and (result.mm_u8[7] = 18));
    
    // 测试 9: mmx_paddw
    a.mm_u16[0] := 100;
    a.mm_u16[1] := 200;
    b.mm_u16[0] := 50;
    b.mm_u16[1] := 100;
    result := mmx_paddw(a, b);
    TestResult('mmx_paddw', (result.mm_u16[0] = 150) and (result.mm_u16[1] = 300));
    
    // 测试 10: mmx_psubb
    for i := 0 to 7 do
    begin
      a.mm_u8[i] := (i + 1) * 20;
      b.mm_u8[i] := (i + 1) * 10;
    end;
    result := mmx_psubb(a, b);
    TestResult('mmx_psubb', (result.mm_u8[0] = 10) and (result.mm_u8[7] = 80));
    
    // 测试 11: mmx_pand
    a.mm_u64 := $F0F0F0F0F0F0F0F0;
    b.mm_u64 := $0F0F0F0F0F0F0F0F;
    result := mmx_pand(a, b);
    TestResult('mmx_pand', result.mm_u64 = 0);
    
    // 测试 12: mmx_por
    a.mm_u64 := $F0F0F0F0F0F0F0F0;
    b.mm_u64 := $0F0F0F0F0F0F0F0F;
    result := mmx_por(a, b);
    TestResult('mmx_por', result.mm_u64 = $FFFFFFFFFFFFFFFF);
    
    // 测试 13: mmx_pxor
    a.mm_u64 := $F0F0F0F0F0F0F0F0;
    b.mm_u64 := $0F0F0F0F0F0F0F0F;
    result := mmx_pxor(a, b);
    TestResult('mmx_pxor', result.mm_u64 = $FFFFFFFFFFFFFFFF);
    
    // 测试 14: mmx_pcmpeqb
    a.mm_u8[0] := 10;
    a.mm_u8[1] := 20;
    b.mm_u8[0] := 10;
    b.mm_u8[1] := 30;
    result := mmx_pcmpeqb(a, b);
    TestResult('mmx_pcmpeqb', (result.mm_u8[0] = $FF) and (result.mm_u8[1] = $00));
    
    // 测试 15: mmx_psllw_imm
    a.mm_u16[0] := $0001;
    a.mm_u16[1] := $0002;
    result := mmx_psllw_imm(a, 2);
    TestResult('mmx_psllw_imm', (result.mm_u16[0] = $0004) and (result.mm_u16[1] = $0008));
    
    // 测试 16: mmx_psrlw_imm
    a.mm_u16[0] := $0010;
    a.mm_u16[1] := $0020;
    result := mmx_psrlw_imm(a, 2);
    TestResult('mmx_psrlw_imm', (result.mm_u16[0] = $0004) and (result.mm_u16[1] = $0008));
    
    // 测试 17: mmx_movd_r32_to_mm
    result := mmx_movd_r32_to_mm($12345678);
    TestResult('mmx_movd_r32_to_mm', result.mm_u32[0] = $12345678);
    
    // 测试 18: mmx_movd_r32
    a.mm_u64 := 0;
    a.mm_u32[0] := $87654321;
    TestResult('mmx_movd_r32', mmx_movd_r32(a) = $87654321);
    
    // 测试 19: mmx_emms (应该不会崩溃)
    mmx_emms;
    TestResult('mmx_emms', True);
    
    WriteLn;
    WriteLn('==================');
    WriteLn('测试结果汇总:');
    WriteLn('通过: ', testsPassed, '/', testsTotal);
    WriteLn('失败: ', testsTotal - testsPassed, '/', testsTotal);
    WriteLn('成功率: ', (testsPassed * 100) div testsTotal, '%');
    
    if testsPassed = testsTotal then
    begin
      WriteLn;
      WriteLn('🎉 所有测试通过！MMX指令集工作正常！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn;
      WriteLn('❌ 有测试失败，请检查MMX实现！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('❌ 测试过程中发生异常: ', E.Message);
      WriteLn('这可能表示MMX指令实现有严重问题！');
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('测试完成。');
end.
