program test_real_cpuid;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

var
  outputFile: TextFile;
  cpuInfo: TCPUInfo;

procedure WriteLog(const msg: string);
begin
  WriteLn(outputFile, msg);
  Flush(outputFile);
end;

begin
  AssignFile(outputFile, 'real_cpuid_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('Real CPUID Test Results');
    WriteLog('=======================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    try
      WriteLog('Testing real CPUID implementation...');
      cpuInfo := GetCPUInfo;
      
      WriteLog('CPU Information:');
      WriteLog('  Vendor: "' + cpuInfo.Vendor + '"');
      WriteLog('  Model: "' + cpuInfo.Model + '"');
      WriteLog('');
      
      WriteLog('x86 Features:');
      {$IFDEF SIMD_X86_AVAILABLE}
      WriteLog('  SSE: ' + BoolToStr(cpuInfo.X86.HasSSE, True));
      WriteLog('  SSE2: ' + BoolToStr(cpuInfo.X86.HasSSE2, True));
      WriteLog('  SSE3: ' + BoolToStr(cpuInfo.X86.HasSSE3, True));
      WriteLog('  SSSE3: ' + BoolToStr(cpuInfo.X86.HasSSSE3, True));
      WriteLog('  SSE4.1: ' + BoolToStr(cpuInfo.X86.HasSSE41, True));
      WriteLog('  SSE4.2: ' + BoolToStr(cpuInfo.X86.HasSSE42, True));
      WriteLog('  AVX: ' + BoolToStr(cpuInfo.X86.HasAVX, True));
      WriteLog('  AVX2: ' + BoolToStr(cpuInfo.X86.HasAVX2, True));
      WriteLog('  FMA: ' + BoolToStr(cpuInfo.X86.HasFMA, True));
      WriteLog('  AVX512F: ' + BoolToStr(cpuInfo.X86.HasAVX512F, True));
      WriteLog('  AVX512DQ: ' + BoolToStr(cpuInfo.X86.HasAVX512DQ, True));
      WriteLog('  AVX512BW: ' + BoolToStr(cpuInfo.X86.HasAVX512BW, True));
      {$ELSE}
      WriteLog('  x86 features not available in this build');
      {$ENDIF}
      WriteLog('');
      
      WriteLog('ARM Features:');
      {$IFDEF SIMD_ARM_AVAILABLE}
      WriteLog('  NEON: ' + BoolToStr(cpuInfo.ARM.HasNEON, True));
      WriteLog('  AdvSIMD: ' + BoolToStr(cpuInfo.ARM.HasAdvSIMD, True));
      WriteLog('  FP: ' + BoolToStr(cpuInfo.ARM.HasFP, True));
      WriteLog('  SVE: ' + BoolToStr(cpuInfo.ARM.HasSVE, True));
      {$ELSE}
      WriteLog('  ARM features not available in this build');
      {$ENDIF}
      WriteLog('');
      
      WriteLog('Backend Information:');
      WriteLog('  Scalar available: ' + BoolToStr(IsBackendAvailable(sbScalar), True));
      WriteLog('  SSE2 available: ' + BoolToStr(IsBackendAvailable(sbSSE2), True));
      WriteLog('  AVX2 available: ' + BoolToStr(IsBackendAvailable(sbAVX2), True));
      WriteLog('  AVX512 available: ' + BoolToStr(IsBackendAvailable(sbAVX512), True));
      WriteLog('  NEON available: ' + BoolToStr(IsBackendAvailable(sbNEON), True));
      WriteLog('');
      
      WriteLog('Best backend: ' + GetBackendName(GetBestBackend));
      WriteLog('');
      
      WriteLog('✅ Real CPUID test completed successfully');
      
    except
      on E: Exception do
      begin
        WriteLog('❌ Real CPUID test failed: ' + E.Message);
      end;
    end;
    
    WriteLog('');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('Real CPUID test completed. Check real_cpuid_results.txt for results.');
end.
