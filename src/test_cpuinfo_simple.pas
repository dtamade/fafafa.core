program test_cpuinfo_simple;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.simple;

var
  cpuInfo: TCPUInfo;
  backend: TSimdBackend;

begin
  WriteLn('Simple CPU Info Test');
  WriteLn('====================');
  
  try
    // Test basic CPU info
    cpuInfo := GetCPUInfo;
    WriteLn('CPU Vendor: ', cpuInfo.Vendor);
    WriteLn('CPU Model: ', cpuInfo.Model);
    
    // Test backend availability
    WriteLn('Scalar backend available: ', IsBackendAvailable(sbScalar));
    WriteLn('SSE2 backend available: ', IsBackendAvailable(sbSSE2));
    WriteLn('AVX2 backend available: ', IsBackendAvailable(sbAVX2));
    
    // Test best backend
    backend := GetBestBackend;
    WriteLn('Best backend: ', GetBackendName(backend));
    
    WriteLn('Test completed successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
