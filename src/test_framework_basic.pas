program test_framework_basic;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.x86;

var
  eax, ebx, ecx, edx: DWord;
  vendor: string;

begin
  try
    WriteLn('=== 基础框架测试 ===');
    
    // 直接测试 x86 模块
    WriteLn('测试 HasCPUID: ', HasCPUID);
    
    if HasCPUID then
    begin
      // 测试 CPUID 函数
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
      
      // 测试特性检查
      WriteLn('');
      WriteLn('特性检查:');
      WriteLn('  HasSSE: ', HasSSE);
      WriteLn('  HasSSE2: ', HasSSE2);
      WriteLn('  HasAVX: ', HasAVX);
      WriteLn('  HasAVX2: ', HasAVX2);
      
      // 测试 CPU 信息获取
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
  WriteLn('按任意键退出...');
  ReadLn;
end.
