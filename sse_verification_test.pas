program sse_verification_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse;

var
  a, b, result: TM128;
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

function FloatEqual(a, b: Single; epsilon: Single = 0.0001): Boolean;
begin
  Result := Abs(a - b) < epsilon;
end;

begin
  WriteLn('SSE 指令集验证测试');
  WriteLn('==================');
  WriteLn;
  
  testsPassed := 0;
  testsTotal := 0;
  
  try
    // 测试 1: sse_setzero_ps
    result := sse_setzero_ps;
    TestResult('sse_setzero_ps', 
               (result.m128_f32[0] = 0.0) and (result.m128_f32[3] = 0.0));
    
    // 测试 2: sse_set1_ps
    result := sse_set1_ps(3.14);
    TestResult('sse_set1_ps(3.14)', 
               FloatEqual(result.m128_f32[0], 3.14) and FloatEqual(result.m128_f32[3], 3.14));
    
    // 测试 3: sse_set_ps
    result := sse_set_ps(4.0, 3.0, 2.0, 1.0);
    TestResult('sse_set_ps(4,3,2,1)', 
               FloatEqual(result.m128_f32[0], 1.0) and FloatEqual(result.m128_f32[3], 4.0));
    
    // 测试 4: sse_set_ss
    result := sse_set_ss(5.5);
    TestResult('sse_set_ss(5.5)', 
               FloatEqual(result.m128_f32[0], 5.5) and (result.m128_f32[1] = 0.0));
    
    // 测试 5: sse_add_ps
    a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
    b := sse_set_ps(1.0, 2.0, 3.0, 4.0);
    result := sse_add_ps(a, b);
    TestResult('sse_add_ps', 
               FloatEqual(result.m128_f32[0], 5.0) and FloatEqual(result.m128_f32[3], 5.0));
    
    // 测试 6: sse_sub_ps
    result := sse_sub_ps(a, b);
    TestResult('sse_sub_ps', 
               FloatEqual(result.m128_f32[0], -3.0) and FloatEqual(result.m128_f32[3], 3.0));
    
    // 测试 7: sse_mul_ps
    a := sse_set_ps(2.0, 2.0, 2.0, 2.0);
    b := sse_set_ps(3.0, 4.0, 5.0, 6.0);
    result := sse_mul_ps(a, b);
    TestResult('sse_mul_ps', 
               FloatEqual(result.m128_f32[0], 12.0) and FloatEqual(result.m128_f32[3], 6.0));
    
    // 测试 8: sse_div_ps
    a := sse_set_ps(8.0, 6.0, 4.0, 2.0);
    b := sse_set_ps(2.0, 2.0, 2.0, 2.0);
    result := sse_div_ps(a, b);
    TestResult('sse_div_ps', 
               FloatEqual(result.m128_f32[0], 1.0) and FloatEqual(result.m128_f32[3], 4.0));
    
    // 测试 9: sse_sqrt_ps
    a := sse_set_ps(16.0, 9.0, 4.0, 1.0);
    result := sse_sqrt_ps(a);
    TestResult('sse_sqrt_ps', 
               FloatEqual(result.m128_f32[0], 1.0) and FloatEqual(result.m128_f32[3], 4.0));
    
    // 测试 10: sse_min_ps
    a := sse_set_ps(5.0, 2.0, 8.0, 3.0);
    b := sse_set_ps(3.0, 4.0, 6.0, 7.0);
    result := sse_min_ps(a, b);
    TestResult('sse_min_ps', 
               FloatEqual(result.m128_f32[0], 3.0) and FloatEqual(result.m128_f32[3], 3.0));
    
    // 测试 11: sse_max_ps
    result := sse_max_ps(a, b);
    TestResult('sse_max_ps', 
               FloatEqual(result.m128_f32[0], 7.0) and FloatEqual(result.m128_f32[3], 5.0));
    
    // 测试 12: sse_and_ps
    a.m128i_u32[0] := $FFFFFFFF;
    a.m128i_u32[1] := $00000000;
    a.m128i_u32[2] := $FFFFFFFF;
    a.m128i_u32[3] := $00000000;
    b.m128i_u32[0] := $FFFFFFFF;
    b.m128i_u32[1] := $FFFFFFFF;
    b.m128i_u32[2] := $00000000;
    b.m128i_u32[3] := $00000000;
    result := sse_and_ps(a, b);
    TestResult('sse_and_ps', 
               (result.m128i_u32[0] = $FFFFFFFF) and (result.m128i_u32[1] = $00000000) and
               (result.m128i_u32[2] = $00000000) and (result.m128i_u32[3] = $00000000));
    
    // 测试 13: sse_or_ps
    result := sse_or_ps(a, b);
    TestResult('sse_or_ps', 
               (result.m128i_u32[0] = $FFFFFFFF) and (result.m128i_u32[1] = $FFFFFFFF) and
               (result.m128i_u32[2] = $FFFFFFFF) and (result.m128i_u32[3] = $00000000));
    
    // 测试 14: sse_xor_ps
    result := sse_xor_ps(a, b);
    TestResult('sse_xor_ps', 
               (result.m128i_u32[0] = $00000000) and (result.m128i_u32[1] = $FFFFFFFF) and
               (result.m128i_u32[2] = $FFFFFFFF) and (result.m128i_u32[3] = $00000000));
    
    // 测试 15: sse_cmpeq_ps
    a := sse_set_ps(1.0, 2.0, 3.0, 4.0);
    b := sse_set_ps(1.0, 5.0, 3.0, 6.0);
    result := sse_cmpeq_ps(a, b);
    TestResult('sse_cmpeq_ps', 
               (result.m128i_u32[0] = $FFFFFFFF) and (result.m128i_u32[1] = $00000000) and
               (result.m128i_u32[2] = $FFFFFFFF) and (result.m128i_u32[3] = $FFFFFFFF));
    
    // 测试 16: sse_cmplt_ps
    a := sse_set_ps(1.0, 6.0, 3.0, 2.0);
    b := sse_set_ps(2.0, 5.0, 3.0, 4.0);
    result := sse_cmplt_ps(a, b);
    TestResult('sse_cmplt_ps', 
               (result.m128i_u32[0] = $FFFFFFFF) and (result.m128i_u32[1] = $00000000) and
               (result.m128i_u32[2] = $00000000) and (result.m128i_u32[3] = $FFFFFFFF));
    
    // 测试 17: sse_unpacklo_ps
    a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
    b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
    result := sse_unpacklo_ps(a, b);
    TestResult('sse_unpacklo_ps', 
               FloatEqual(result.m128_f32[0], 1.0) and FloatEqual(result.m128_f32[1], 5.0) and
               FloatEqual(result.m128_f32[2], 2.0) and FloatEqual(result.m128_f32[3], 6.0));
    
    // 测试 18: sse_unpackhi_ps
    result := sse_unpackhi_ps(a, b);
    TestResult('sse_unpackhi_ps', 
               FloatEqual(result.m128_f32[0], 3.0) and FloatEqual(result.m128_f32[1], 7.0) and
               FloatEqual(result.m128_f32[2], 4.0) and FloatEqual(result.m128_f32[3], 8.0));
    
    // 测试 19: sse_movemask_ps
    a.m128i_u32[0] := $80000000;  // 负数
    a.m128i_u32[1] := $00000000;  // 正数
    a.m128i_u32[2] := $80000000;  // 负数
    a.m128i_u32[3] := $00000000;  // 正数
    TestResult('sse_movemask_ps', sse_movemask_ps(a) = 5);  // 二进制: 0101
    
    // 测试 20: sse_cvtsi2ss
    a := sse_setzero_ps;
    result := sse_cvtsi2ss(a, 42);
    TestResult('sse_cvtsi2ss', FloatEqual(result.m128_f32[0], 42.0));
    
    WriteLn;
    WriteLn('==================');
    WriteLn('测试结果汇总:');
    WriteLn('通过: ', testsPassed, '/', testsTotal);
    WriteLn('失败: ', testsTotal - testsPassed, '/', testsTotal);
    WriteLn('成功率: ', (testsPassed * 100) div testsTotal, '%');
    
    if testsPassed = testsTotal then
    begin
      WriteLn;
      WriteLn('🎉 所有测试通过！SSE指令集工作正常！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn;
      WriteLn('❌ 有测试失败，请检查SSE实现！');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('❌ 测试过程中发生异常: ', E.Message);
      WriteLn('这可能表示SSE指令实现有严重问题！');
      ExitCode := 2;
    end;
  end;
  
  WriteLn;
  WriteLn('测试完成。');
end.
