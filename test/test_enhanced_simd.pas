program test_enhanced_simd;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.x86;

procedure TestEnhancedSIMDFeatures;
var
  features: TX86Features;
  eax, ebx, ecx, edx: DWord;
  vendor: string;
begin
  WriteLn('=== 增强的 SIMD 特性检测测试 ===');
  
  try
    // 测试基础 CPUID
    WriteLn('基础 CPUID 测试:');
    WriteLn('  HasCPUID: ', HasCPUID);
    
    if HasCPUID then
    begin
      // 获取厂商信息
      CPUID(0, eax, ebx, ecx, edx);
      SetLength(vendor, 12);
      Move(ebx, vendor[1], 4);
      Move(edx, vendor[5], 4);
      Move(ecx, vendor[9], 4);
      WriteLn('  厂商: "', vendor, '"');
      WriteLn('  最大叶子: $', IntToHex(eax, 8));
      
      // 检测所有 x86 特性
      features := DetectX86Features;
      
      WriteLn('');
      WriteLn('基础 SIMD 特性:');
      WriteLn('  MMX: ', features.HasMMX);
      WriteLn('  SSE: ', features.HasSSE);
      WriteLn('  SSE2: ', features.HasSSE2);
      WriteLn('  SSE3: ', features.HasSSE3);
      WriteLn('  SSSE3: ', features.HasSSSE3);
      WriteLn('  SSE4.1: ', features.HasSSE41);
      WriteLn('  SSE4.2: ', features.HasSSE42);
      
      WriteLn('');
      WriteLn('高级向量扩展:');
      WriteLn('  AVX: ', features.HasAVX);
      WriteLn('  AVX2: ', features.HasAVX2);
      WriteLn('  AVX-512F: ', features.HasAVX512F);
      WriteLn('  AVX-512DQ: ', features.HasAVX512DQ);
      WriteLn('  AVX-512BW: ', features.HasAVX512BW);
      WriteLn('  AVX-512VL: ', features.HasAVX512VL);
      WriteLn('  AVX-512VBMI: ', features.HasAVX512VBMI);
      
      WriteLn('');
      WriteLn('数学和算术:');
      WriteLn('  FMA: ', features.HasFMA);
      WriteLn('  FMA4: ', features.HasFMA4);
      WriteLn('  F16C: ', features.HasF16C);
      
      WriteLn('');
      WriteLn('位操作指令:');
      WriteLn('  BMI1: ', features.HasBMI1);
      WriteLn('  BMI2: ', features.HasBMI2);
      
      WriteLn('');
      WriteLn('加密特性:');
      WriteLn('  AES: ', features.HasAES);
      WriteLn('  PCLMULQDQ: ', features.HasPCLMULQDQ);
      WriteLn('  SHA: ', features.HasSHA);
      
      WriteLn('');
      WriteLn('其他特性:');
      WriteLn('  RDRAND: ', features.HasRDRAND);
      WriteLn('  RDSEED: ', features.HasRDSEED);
      
      // 测试 OS 支持
      WriteLn('');
      WriteLn('操作系统支持:');
      WriteLn('  AVX OS Support: ', IsAVXSupportedByOS);
      
      // 测试便利函数
      WriteLn('');
      WriteLn('便利函数测试:');
      WriteLn('  HasSSE (func): ', HasSSE);
      WriteLn('  HasAVX (func): ', HasAVX);
      WriteLn('  HasAVX2 (func): ', HasAVX2);
      
      WriteLn('');
      WriteLn('CPU 信息:');
      WriteLn('  厂商字符串: "', GetVendorString, '"');
      WriteLn('  品牌字符串: "', GetBrandString, '"');
    end
    else
      WriteLn('CPUID 不可用');
      
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('=== 测试完成 ===');
end;

begin
  try
    TestEnhancedSIMDFeatures;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('按任意键退出...');
  ReadLn;
end.
