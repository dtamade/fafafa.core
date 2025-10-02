program test_cpuid_debug;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}
{$ASMMODE INTEL}

uses
  SysUtils,
  fafafa.core.simd.cpuinfo.x86;

procedure TestCPUID;
var
  eax, ebx, ecx, edx: DWord;
  vendor: string;
  i: Integer;
begin
  WriteLn('=== CPUID 调试测试 ===');
  
  // 测试 HasCPUID
  WriteLn('HasCPUID: ', HasCPUID);
  
  // 测试 CPUID 叶子 0 (厂商信息)
  WriteLn('');
  WriteLn('测试 CPUID 叶子 0 (厂商信息):');
  try
    CPUID(0, eax, ebx, ecx, edx);
    WriteLn('  EAX (最大叶子): $', IntToHex(eax, 8));
    WriteLn('  EBX: $', IntToHex(ebx, 8));
    WriteLn('  ECX: $', IntToHex(ecx, 8));
    WriteLn('  EDX: $', IntToHex(edx, 8));
    
    // 构造厂商字符串
    SetLength(vendor, 12);
    Move(ebx, vendor[1], 4);
    Move(edx, vendor[5], 4);
    Move(ecx, vendor[9], 4);
    WriteLn('  厂商字符串: "', vendor, '"');
  except
    on E: Exception do
      WriteLn('  错误: ', E.Message);
  end;
  
  // 测试 CPUID 叶子 1 (特性标志)
  WriteLn('');
  WriteLn('测试 CPUID 叶子 1 (特性标志):');
  try
    CPUID(1, eax, ebx, ecx, edx);
    WriteLn('  EAX (Family/Model): $', IntToHex(eax, 8));
    WriteLn('  EBX (Brand/Cache): $', IntToHex(ebx, 8));
    WriteLn('  ECX (特性标志): $', IntToHex(ecx, 8));
    WriteLn('  EDX (特性标志): $', IntToHex(edx, 8));
    
    // 检查关键特性
    WriteLn('  特性检查:');
    WriteLn('    SSE: ', (edx and (1 shl 25)) <> 0);
    WriteLn('    SSE2: ', (edx and (1 shl 26)) <> 0);
    WriteLn('    SSE3: ', (ecx and (1 shl 0)) <> 0);
    WriteLn('    SSSE3: ', (ecx and (1 shl 9)) <> 0);
    WriteLn('    SSE4.1: ', (ecx and (1 shl 19)) <> 0);
    WriteLn('    SSE4.2: ', (ecx and (1 shl 20)) <> 0);
    WriteLn('    AVX: ', (ecx and (1 shl 28)) <> 0);
  except
    on E: Exception do
      WriteLn('  错误: ', E.Message);
  end;
  
  // 测试 CPUID 叶子 7 (扩展特性)
  WriteLn('');
  WriteLn('测试 CPUID 叶子 7 (扩展特性):');
  try
    CPUIDEX(7, 0, eax, ebx, ecx, edx);
    WriteLn('  EAX: $', IntToHex(eax, 8));
    WriteLn('  EBX: $', IntToHex(ebx, 8));
    WriteLn('  ECX: $', IntToHex(ecx, 8));
    WriteLn('  EDX: $', IntToHex(edx, 8));
    
    WriteLn('  扩展特性检查:');
    WriteLn('    AVX2: ', (ebx and (1 shl 5)) <> 0);
    WriteLn('    AVX512F: ', (ebx and (1 shl 16)) <> 0);
  except
    on E: Exception do
      WriteLn('  错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('=== 测试完成 ===');
end;

begin
  try
    TestCPUID;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('按任意键退出...');
  ReadLn;
end.
