program test_cpuinfo_debug;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.simple;

var
  cpuInfo: TCPUInfo;
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  backends: TSimdBackendArray;
  i: Integer;

begin
  WriteLn('=== CPU Info Debug Test ===');
  
  try
    WriteLn('1. Testing GetCPUInfo...');
    cpuInfo := GetCPUInfo;
    WriteLn('   Vendor: "', cpuInfo.Vendor, '"');
    WriteLn('   Model: "', cpuInfo.Model, '"');
    
    WriteLn('2. Testing backend availability...');
    WriteLn('   Scalar: ', IsBackendAvailable(sbScalar));
    WriteLn('   SSE2: ', IsBackendAvailable(sbSSE2));
    WriteLn('   AVX2: ', IsBackendAvailable(sbAVX2));
    WriteLn('   NEON: ', IsBackendAvailable(sbNEON));
    
    WriteLn('3. Testing GetBestBackend...');
    backend := GetBestBackend;
    WriteLn('   Best backend: ', GetBackendName(backend));
    
    WriteLn('4. Testing GetAvailableBackends...');
    backends := GetAvailableBackends;
    WriteLn('   Available backends count: ', Length(backends));
    for i := 0 to Length(backends) - 1 do
    begin
      backendInfo := GetBackendInfo(backends[i]);
      WriteLn('   - ', backendInfo.Name, ' (Priority: ', backendInfo.Priority, ')');
    end;
    
    WriteLn('5. Testing x86 features...');
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLn('   SSE: ', cpuInfo.X86.HasSSE);
    WriteLn('   SSE2: ', cpuInfo.X86.HasSSE2);
    WriteLn('   AVX: ', cpuInfo.X86.HasAVX);
    WriteLn('   AVX2: ', cpuInfo.X86.HasAVX2);
    {$ELSE}
    WriteLn('   x86 features not available in this build');
    {$ENDIF}
    
    WriteLn('6. Testing ARM features...');
    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLn('   NEON: ', cpuInfo.ARM.HasNEON);
    WriteLn('   AdvSIMD: ', cpuInfo.ARM.HasAdvSIMD);
    {$ELSE}
    WriteLn('   ARM features not available in this build');
    {$ENDIF}
    
    WriteLn;
    WriteLn('All tests completed successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
