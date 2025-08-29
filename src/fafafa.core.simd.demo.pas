program fafafa.core.simd.demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd;

// === SIMD Framework Demo ===
// This program demonstrates the basic usage of the modern SIMD framework

procedure PrintBackendInfo;
var
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  cpuInfo: TCPUInfo;
  backends: array of TSimdBackend;
  i: Integer;
begin
  WriteLn('=== SIMD Framework Information ===');
  WriteLn;
  
  // Show CPU information
  cpuInfo := GetCPUInformation;
  WriteLn('CPU Information:');
  WriteLn('  Vendor: ', cpuInfo.Vendor);
  WriteLn('  Model: ', cpuInfo.Model);
  WriteLn;
  
  // Show available backends
  backends := GetAvailableBackendList;
  WriteLn('Available Backends:');
  for i := 0 to Length(backends) - 1 do
  begin
    backendInfo := GetBackendInfo(backends[i]);
    WriteLn('  ', backendInfo.Name, ': ', backendInfo.Description);
    WriteLn('    Available: ', backendInfo.Available);
    WriteLn('    Priority: ', backendInfo.Priority);
  end;
  WriteLn;
  
  // Show current backend
  backend := GetCurrentBackend;
  backendInfo := GetCurrentBackendInfo;
  WriteLn('Current Active Backend:');
  WriteLn('  ', backendInfo.Name, ': ', backendInfo.Description);
  WriteLn;
end;

procedure DemoBasicOperations;
var
  a, b, result: TVecF32x4;
  mask: TMask4;
  sum: Single;
  i: Integer;
begin
  WriteLn('=== Basic Vector Operations Demo ===');
  WriteLn;
  
  // Create test vectors
  a := VecF32x4Splat(2.0);
  b := VecF32x4Splat(3.0);
  
  WriteLn('Vector A: [2.0, 2.0, 2.0, 2.0]');
  WriteLn('Vector B: [3.0, 3.0, 3.0, 3.0]');
  WriteLn;
  
  // Test arithmetic operations
  result := VecF32x4Add(a, b);
  Write('A + B = [');
  for i := 0 to 3 do
  begin
    Write(VecF32x4Extract(result, i):0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  result := VecF32x4Mul(a, b);
  Write('A * B = [');
  for i := 0 to 3 do
  begin
    Write(VecF32x4Extract(result, i):0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  // Test comparison
  mask := VecF32x4CmpLt(a, b);
  WriteLn('A < B mask: $', IntToHex(mask, 2));
  
  // Test reduction
  sum := VecF32x4ReduceAdd(a);
  WriteLn('Sum of A: ', sum:0:1);
  
  // Test math functions
  result := VecF32x4Sqrt(VecF32x4Splat(16.0));
  WriteLn('Sqrt([16, 16, 16, 16]) = [', VecF32x4Extract(result, 0):0:1, ', ...]');
  
  WriteLn;
end;

procedure DemoMemoryOperations;
var
  data: array[0..7] of Single;
  vec: TVecF32x4;
  i: Integer;
begin
  WriteLn('=== Memory Operations Demo ===');
  WriteLn;
  
  // Initialize test data
  for i := 0 to 7 do
    data[i] := i + 1.0;
    
  Write('Source data: [');
  for i := 0 to 7 do
  begin
    Write(data[i]:0:1);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  // Load vector from memory
  vec := VecF32x4Load(@data[0]);
  Write('Loaded vector: [');
  for i := 0 to 3 do
  begin
    Write(VecF32x4Extract(vec, i):0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  // Modify vector and store back
  vec := VecF32x4Mul(vec, VecF32x4Splat(2.0));
  VecF32x4Store(@data[4], vec);
  
  Write('Modified data: [');
  for i := 0 to 7 do
  begin
    Write(data[i]:0:1);
    if i < 7 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn;
end;

procedure DemoMaskOperations;
var
  a, b, result: TVecF32x4;
  mask: TMask4;
  i: Integer;
begin
  WriteLn('=== Mask Operations Demo ===');
  WriteLn;
  
  // Create test vectors
  a := VecF32x4Splat(10.0);
  b := VecF32x4Splat(20.0);
  
  // Create a custom mask (select first and third elements from a, others from b)
  mask := $05; // Binary: 0101 (bits 0 and 2 set)
  
  WriteLn('Vector A: [10.0, 10.0, 10.0, 10.0]');
  WriteLn('Vector B: [20.0, 20.0, 20.0, 20.0]');
  WriteLn('Mask: $', IntToHex(mask, 2), ' (binary: ', 
          IntToBin(mask, 4), ')');
  
  result := VecF32x4Select(mask, a, b);
  Write('Select result: [');
  for i := 0 to 3 do
  begin
    Write(VecF32x4Extract(result, i):0:1);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
  
  WriteLn;
end;

procedure DemoPerformanceComparison;
const
  ITERATIONS = 1000000;
var
  a, b, result: TVecF32x4;
  startTime, endTime: QWord;
  i: Integer;
  scalarTime, vectorTime: Double;
  scalarData: array[0..3] of Single;
begin
  WriteLn('=== Performance Comparison Demo ===');
  WriteLn;
  
  // Initialize test data
  a := VecF32x4Splat(1.5);
  b := VecF32x4Splat(2.5);
  for i := 0 to 3 do
    scalarData[i] := 1.5;
  
  WriteLn('Performing ', ITERATIONS, ' iterations of vector addition...');
  
  // Test scalar performance (simulated)
  startTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    // Simulate scalar addition
    scalarData[0] := scalarData[0] + 2.5;
    scalarData[1] := scalarData[1] + 2.5;
    scalarData[2] := scalarData[2] + 2.5;
    scalarData[3] := scalarData[3] + 2.5;
  end;
  endTime := GetTickCount64;
  scalarTime := (endTime - startTime) / 1000.0;
  
  // Test vector performance
  startTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    result := VecF32x4Add(a, b);
    a := result; // Prevent optimization
  end;
  endTime := GetTickCount64;
  vectorTime := (endTime - startTime) / 1000.0;
  
  WriteLn('Scalar time: ', scalarTime:0:3, ' seconds');
  WriteLn('Vector time: ', vectorTime:0:3, ' seconds');
  if vectorTime > 0 then
    WriteLn('Speedup: ', (scalarTime / vectorTime):0:2, 'x');
  
  WriteLn;
end;

begin
  WriteLn('Modern FreePascal SIMD Framework Demo');
  WriteLn('=====================================');
  WriteLn;
  
  try
    // Show framework information
    PrintBackendInfo;
    
    // Demonstrate basic operations
    DemoBasicOperations;
    
    // Demonstrate memory operations
    DemoMemoryOperations;
    
    // Demonstrate mask operations
    DemoMaskOperations;
    
    // Performance comparison
    DemoPerformanceComparison;
    
    WriteLn('Demo completed successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
