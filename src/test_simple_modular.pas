program test_simple_modular;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

var
  cpuInfo: TCPUInfo;
  bestBackend: TSimdBackend;
begin
  try
    WriteLn('=== 简单模块化测试 ===');

    // 测试 CPU 信息
    cpuInfo := GetCPUInfo;
    WriteLn('CPU 厂商: ', cpuInfo.Vendor);
    WriteLn('CPU 型号: ', cpuInfo.Model);

    // 测试后端可用性
    WriteLn('标量后端可用: ', IsBackendAvailable(sbScalar));
    WriteLn('SSE2 后端可用: ', IsBackendAvailable(sbSSE2));
    WriteLn('AVX2 后端可用: ', IsBackendAvailable(sbAVX2));
    WriteLn('NEON 后端可用: ', IsBackendAvailable(sbNEON));
    WriteLn('RISC-V 后端可用: ', IsBackendAvailable(sbRISCVV));

    // 测试最佳后端
    bestBackend := GetBestBackend;
    WriteLn('最佳后端: ', GetBackendName(bestBackend));
    
    WriteLn('✅ 简单模块化测试通过');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      WriteLn('异常类型: ', E.ClassName);
    end;
  end;
  
  WriteLn('按任意键继续...');
  ReadLn;
end.
