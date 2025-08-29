program fafafa.core.simd.cpuinfo.test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

// === CPU Information Test Program ===
// This program tests and validates the CPU feature detection functionality

procedure PrintSeparator(const title: string);
begin
  WriteLn;
  WriteLn('=== ', title, ' ===');
  WriteLn;
end;

procedure PrintCPUInfo;
var
  cpuInfo: TCPUInfo;
begin
  PrintSeparator('CPU Information');
  
  cpuInfo := GetCPUInfo;
  
  WriteLn('Vendor: ', cpuInfo.Vendor);
  WriteLn('Model: ', cpuInfo.Model);
  WriteLn;
end;

procedure PrintX86Features;
{$IFDEF SIMD_X86_AVAILABLE}
var
  cpuInfo: TCPUInfo;
  features: TX86Features;
{$ENDIF}
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  PrintSeparator('x86 SIMD Features');
  
  cpuInfo := GetCPUInfo;
  features := cpuInfo.X86;
  
  WriteLn('SSE Support:');
  WriteLn('  SSE:     ', features.HasSSE);
  WriteLn('  SSE2:    ', features.HasSSE2);
  WriteLn('  SSE3:    ', features.HasSSE3);
  WriteLn('  SSSE3:   ', features.HasSSSE3);
  WriteLn('  SSE4.1:  ', features.HasSSE41);
  WriteLn('  SSE4.2:  ', features.HasSSE42);
  WriteLn;
  
  WriteLn('AVX Support:');
  WriteLn('  AVX:     ', features.HasAVX);
  WriteLn('  AVX2:    ', features.HasAVX2);
  WriteLn('  FMA:     ', features.HasFMA);
  WriteLn;
  
  WriteLn('AVX-512 Support:');
  WriteLn('  AVX512F: ', features.HasAVX512F);
  WriteLn('  AVX512DQ:', features.HasAVX512DQ);
  WriteLn('  AVX512BW:', features.HasAVX512BW);
  WriteLn;
  {$ELSE}
  PrintSeparator('x86 SIMD Features');
  WriteLn('x86 SIMD support not compiled in this build.');
  WriteLn;
  {$ENDIF}
end;

procedure PrintARMFeatures;
{$IFDEF SIMD_ARM_AVAILABLE}
var
  cpuInfo: TCPUInfo;
  features: TARMFeatures;
{$ENDIF}
begin
  {$IFDEF SIMD_ARM_AVAILABLE}
  PrintSeparator('ARM SIMD Features');
  
  cpuInfo := GetCPUInfo;
  features := cpuInfo.ARM;
  
  WriteLn('NEON Support:');
  WriteLn('  NEON:    ', features.HasNEON);
  WriteLn('  AdvSIMD: ', features.HasAdvSIMD);
  WriteLn('  FP:      ', features.HasFP);
  WriteLn;
  
  WriteLn('Advanced Features:');
  WriteLn('  SVE:     ', features.HasSVE);
  WriteLn;
  {$ELSE}
  PrintSeparator('ARM SIMD Features');
  WriteLn('ARM SIMD support not compiled in this build.');
  WriteLn;
  {$ENDIF}
end;

procedure PrintBackendAvailability;
var
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  backends: TSimdBackendArray;
  i: Integer;
begin
  PrintSeparator('SIMD Backend Availability');
  
  backends := GetAvailableBackends;
  
  WriteLn('Available Backends (', Length(backends), ' total):');
  for i := 0 to Length(backends) - 1 do
  begin
    backend := backends[i];
    backendInfo := GetBackendInfo(backend);
    WriteLn('  ', backendInfo.Name, ': ', backendInfo.Description);
    WriteLn('    Priority: ', backendInfo.Priority);
    WriteLn('    Available: ', backendInfo.Available);
  end;
  WriteLn;
  
  backend := GetBestBackend;
  backendInfo := GetBackendInfo(backend);
  WriteLn('Best Backend: ', backendInfo.Name);
  WriteLn;
end;

procedure TestThreadSafety;
const
  NUM_ITERATIONS = 1000;
var
  i: Integer;
  cpuInfo1, cpuInfo2: TCPUInfo;
  consistent: Boolean;
begin
  PrintSeparator('Thread Safety Test');
  
  WriteLn('Testing consistency across ', NUM_ITERATIONS, ' calls...');
  
  cpuInfo1 := GetCPUInfo;
  consistent := True;
  
  for i := 1 to NUM_ITERATIONS do
  begin
    cpuInfo2 := GetCPUInfo;
    
    // Check if results are consistent
    if (cpuInfo1.Vendor <> cpuInfo2.Vendor) or 
       (cpuInfo1.Model <> cpuInfo2.Model) then
    begin
      consistent := False;
      Break;
    end;
    
    {$IFDEF SIMD_X86_AVAILABLE}
    if (cpuInfo1.X86.HasSSE <> cpuInfo2.X86.HasSSE) or
       (cpuInfo1.X86.HasSSE2 <> cpuInfo2.X86.HasSSE2) or
       (cpuInfo1.X86.HasAVX <> cpuInfo2.X86.HasAVX) or
       (cpuInfo1.X86.HasAVX2 <> cpuInfo2.X86.HasAVX2) then
    begin
      consistent := False;
      Break;
    end;
    {$ENDIF}
    
    {$IFDEF SIMD_ARM_AVAILABLE}
    if (cpuInfo1.ARM.HasNEON <> cpuInfo2.ARM.HasNEON) or
       (cpuInfo1.ARM.HasAdvSIMD <> cpuInfo2.ARM.HasAdvSIMD) then
    begin
      consistent := False;
      Break;
    end;
    {$ENDIF}
  end;
  
  if consistent then
    WriteLn('✓ All calls returned consistent results')
  else
    WriteLn('✗ Inconsistent results detected at iteration ', i);
    
  WriteLn;
end;

procedure TestPerformance;
const
  NUM_CALLS = 100000;
var
  i: Integer;
  startTime, endTime: QWord;
  cpuInfo: TCPUInfo;
  avgTimeNs: Double;
begin
  PrintSeparator('Performance Test');
  
  WriteLn('Measuring performance of ', NUM_CALLS, ' GetCPUInfo calls...');
  
  // Warm up
  for i := 1 to 10 do
    cpuInfo := GetCPUInfo;
    
  // Measure
  startTime := GetTickCount64;
  for i := 1 to NUM_CALLS do
    cpuInfo := GetCPUInfo;
  endTime := GetTickCount64;
  
  avgTimeNs := ((endTime - startTime) * 1000000.0) / NUM_CALLS;
  
  WriteLn('Total time: ', endTime - startTime, ' ms');
  WriteLn('Average time per call: ', avgTimeNs:0:2, ' ns');
  
  if avgTimeNs < 100 then
    WriteLn('✓ Performance is excellent (< 100ns per call)')
  else if avgTimeNs < 1000 then
    WriteLn('✓ Performance is good (< 1μs per call)')
  else
    WriteLn('⚠ Performance could be improved (', avgTimeNs:0:0, 'ns per call)');
    
  WriteLn;
end;

procedure ValidateFeatureHierarchy;
var
  cpuInfo: TCPUInfo;
  valid: Boolean;
begin
  PrintSeparator('Feature Hierarchy Validation');
  
  cpuInfo := GetCPUInfo;
  valid := True;
  
  {$IFDEF SIMD_X86_AVAILABLE}
  // Validate x86 feature dependencies
  if cpuInfo.X86.HasSSE2 and not cpuInfo.X86.HasSSE then
  begin
    WriteLn('✗ Invalid: SSE2 without SSE');
    valid := False;
  end;
  
  if cpuInfo.X86.HasAVX2 and not cpuInfo.X86.HasAVX then
  begin
    WriteLn('✗ Invalid: AVX2 without AVX');
    valid := False;
  end;
  
  if cpuInfo.X86.HasAVX512F and not cpuInfo.X86.HasAVX2 then
  begin
    WriteLn('✗ Invalid: AVX-512 without AVX2');
    valid := False;
  end;
  
  if cpuInfo.X86.HasSSE3 and not cpuInfo.X86.HasSSE2 then
  begin
    WriteLn('✗ Invalid: SSE3 without SSE2');
    valid := False;
  end;
  {$ENDIF}
  
  if valid then
    WriteLn('✓ All feature dependencies are valid')
  else
    WriteLn('✗ Feature hierarchy validation failed');
    
  WriteLn;
end;

begin
  WriteLn('fafafa.core.simd.cpuinfo Test Suite');
  WriteLn('===================================');
  
  try
    // Basic information
    PrintCPUInfo;
    PrintX86Features;
    PrintARMFeatures;
    PrintBackendAvailability;
    
    // Advanced tests
    TestThreadSafety;
    TestPerformance;
    ValidateFeatureHierarchy;
    
    WriteLn('All tests completed successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('Error during testing: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
