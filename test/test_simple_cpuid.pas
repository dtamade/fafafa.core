program test_simple_cpuid;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  fafafa.core.simd.cpuinfo.x86;

var
  eax, ebx, ecx, edx: DWord;
  vendor: string;

begin
  try
    WriteLn('开始简单 CPUID 测试...');
    
    // 测试 HasCPUID
    WriteLn('HasCPUID: ', HasCPUID);
    
    if HasCPUID then
    begin
      // 测试 CPUID 叶子 0
      WriteLn('调用 CPUID(0)...');
      CPUID(0, eax, ebx, ecx, edx);
      
      WriteLn('CPUID(0) 结果:');
      WriteLn('  EAX: $', IntToHex(eax, 8));
      WriteLn('  EBX: $', IntToHex(ebx, 8));
      WriteLn('  ECX: $', IntToHex(ecx, 8));
      WriteLn('  EDX: $', IntToHex(edx, 8));
      
      // 构造厂商字符串
      SetLength(vendor, 12);
      Move(ebx, vendor[1], 4);
      Move(edx, vendor[5], 4);
      Move(ecx, vendor[9], 4);
      WriteLn('厂商: "', vendor, '"');
      
      // 测试 CPUID 叶子 1
      WriteLn('调用 CPUID(1)...');
      CPUID(1, eax, ebx, ecx, edx);
      
      WriteLn('CPUID(1) 结果:');
      WriteLn('  SSE: ', (edx and (1 shl 25)) <> 0);
      WriteLn('  SSE2: ', (edx and (1 shl 26)) <> 0);
      WriteLn('  AVX: ', (ecx and (1 shl 28)) <> 0);
    end
    else
      WriteLn('CPUID 不可用');
      
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('测试完成');
  WriteLn('按任意键退出...');
  ReadLn;
end.
