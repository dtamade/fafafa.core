program test_final_cpuid;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.cpuinfo.x86.asm;

var
  result: array[0..3] of DWord;
  vendor: string;

begin
  try
    WriteLn('=== 最终 CPUID 测试 ===');
    
    // 直接测试外部汇编函数
    WriteLn('测试外部汇编函数...');
    result := ExecuteRealCPUID(0);
    
    WriteLn('CPUID(0) 结果:');
    WriteLn('  EAX: $', IntToHex(result[0], 8));
    WriteLn('  EBX: $', IntToHex(result[1], 8));
    WriteLn('  ECX: $', IntToHex(result[2], 8));
    WriteLn('  EDX: $', IntToHex(result[3], 8));
    
    // 构造厂商字符串
    SetLength(vendor, 12);
    Move(result[1], vendor[1], 4);  // EBX
    Move(result[3], vendor[5], 4);  // EDX
    Move(result[2], vendor[9], 4);  // ECX
    WriteLn('厂商: "', vendor, '"');
    
    // 测试特性
    result := ExecuteRealCPUID(1);
    WriteLn('');
    WriteLn('CPUID(1) 特性:');
    WriteLn('  SSE: ', (result[3] and (1 shl 25)) <> 0);
    WriteLn('  SSE2: ', (result[3] and (1 shl 26)) <> 0);
    WriteLn('  SSE3: ', (result[2] and (1 shl 0)) <> 0);
    WriteLn('  AVX: ', (result[2] and (1 shl 28)) <> 0);
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('测试完成');
  WriteLn('按任意键退出...');
  ReadLn;
end.
