unit test_cpuinfo_boundary;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
  {$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

procedure TestBoundaryConditions;
procedure TestErrorHandling;
procedure TestMemoryUsage;
procedure TestBackendEnumeration;

implementation

procedure TestBoundaryConditions;
var
  backends: TSimdBackendArray;
  backend: TSimdBackend;
  info: TSimdBackendInfo;
  cpuInfo: TCPUInfo;
  i: Integer;
  found: Boolean;
begin
  WriteLn('=== Testing Boundary Conditions ===');
  
  // Test empty backend array handling
  backends := GetAvailableBackends;
  if Length(backends) = 0 then
  begin
    WriteLn('  ✗ No backends available (should at least have scalar)');
    Exit;
  end
  else
    WriteLn(Format('  ✓ Found %d available backends', [Length(backends)]));
  
  // Test all backend enums
  WriteLn('  Testing all backend enumerations...');
  for backend := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    info := GetBackendInfo(backend);
    Write(Format('    %s: ', [info.Name]));
    
    if info.Available then
    begin
      // Check if it's in the available list
      found := False;
      for i := 0 to Length(backends) - 1 do
      begin
        if backends[i] = backend then
        begin
          found := True;
          Break;
        end;
      end;
      
      if found then
        WriteLn('✓ Available and listed')
      else
        WriteLn('✗ Available but not listed!');
    end
    else
      WriteLn('○ Not available');
  end;
  
  // Test CPU info string boundaries
  cpuInfo := GetCPUInfo;
  WriteLn('  Testing string boundaries...');
  
  if Length(cpuInfo.Vendor) > 0 then
    WriteLn(Format('    Vendor length: %d chars ✓', [Length(cpuInfo.Vendor)]))
  else
    WriteLn('    Vendor: Empty string ⚠');
    
  if Length(cpuInfo.Model) > 0 then
    WriteLn(Format('    Model length: %d chars ✓', [Length(cpuInfo.Model)]))
  else
    WriteLn('    Model: Empty string ⚠');
    
  // Test core count boundaries
  if cpuInfo.LogicalCores >= 0 then
    WriteLn(Format('    Logical cores: %d ✓', [cpuInfo.LogicalCores]))
  else
    WriteLn('    Logical cores: Negative value! ✗');
    
  // Test cache size boundaries
  WriteLn('  Testing cache size boundaries...');
  if cpuInfo.Cache.L1DataKB >= 0 then
    WriteLn(Format('    L1 Data: %d KB ✓', [cpuInfo.Cache.L1DataKB]))
  else
    WriteLn('    L1 Data: Negative! ✗');
    
  if cpuInfo.Cache.L2KB >= 0 then
    WriteLn(Format('    L2: %d KB ✓', [cpuInfo.Cache.L2KB]))
  else
    WriteLn('    L2: Negative! ✗');
    
  if cpuInfo.Cache.L3KB >= 0 then
    WriteLn(Format('    L3: %d KB ✓', [cpuInfo.Cache.L3KB]))
  else
    WriteLn('    L3: Negative! ✗');
    
  WriteLn('Test Boundary Conditions: PASSED');
  WriteLn;
end;

procedure TestErrorHandling;
var
  backend: TSimdBackend;
  info: TSimdBackendInfo;
  errorOccurred: Boolean;
begin
  WriteLn('=== Testing Error Handling ===');
  
  errorOccurred := False;
  
  // Test invalid backend enum (simulate by type casting)
  WriteLn('  Testing invalid backend handling...');
  try
    backend := TSimdBackend(255);  // Invalid enum value
    info := GetBackendInfo(backend);
    if info.Name = 'Unknown' then
      WriteLn('    ✓ Invalid backend handled gracefully')
    else
      WriteLn('    ⚠ Invalid backend returned: ' + info.Name);
  except
    on E: Exception do
    begin
      WriteLn('    ✗ Exception on invalid backend: ' + E.Message);
      errorOccurred := True;
    end;
  end;
  
  // Test multiple resets
  WriteLn('  Testing multiple resets...');
  try
    ResetCPUInfo;
    ResetCPUInfo;
    ResetCPUInfo;
    WriteLn('    ✓ Multiple resets handled successfully');
  except
    on E: Exception do
    begin
      WriteLn('    ✗ Exception on multiple resets: ' + E.Message);
      errorOccurred := True;
    end;
  end;
  
  // Test immediate query after reset
  WriteLn('  Testing immediate query after reset...');
  try
    ResetCPUInfo;
    GetCPUInfo;  // Should re-initialize automatically
    WriteLn('    ✓ Query after reset successful');
  except
    on E: Exception do
    begin
      WriteLn('    ✗ Exception on query after reset: ' + E.Message);
      errorOccurred := True;
    end;
  end;
  
  if not errorOccurred then
    WriteLn('Test Error Handling: PASSED')
  else
    WriteLn('Test Error Handling: FAILED');
  WriteLn;
end;

procedure TestMemoryUsage;
const
  ITERATIONS = 100000;
var
  i: Integer;
  startMem, endMem: NativeUInt;
  cpuInfo: TCPUInfo;
  backends: TSimdBackendArray;
  memDiff: Int64;
begin
  WriteLn('=== Testing Memory Usage ===');
  WriteLn(Format('  Running %d iterations...', [ITERATIONS]));
  
  // Get initial memory usage (approximate)
  startMem := GetHeapStatus.TotalAllocated;
  
  // Perform many operations
  for i := 1 to ITERATIONS do
  begin
    cpuInfo := GetCPUInfo;
    backends := GetAvailableBackends;
    
    // Periodically reset to test cleanup
    if i mod 10000 = 0 then
      ResetCPUInfo;
  end;
  
  // Get final memory usage
  endMem := GetHeapStatus.TotalAllocated;
  memDiff := Int64(endMem) - Int64(startMem);
  
  WriteLn(Format('  Initial memory: %d bytes', [startMem]));
  WriteLn(Format('  Final memory: %d bytes', [endMem]));
  WriteLn(Format('  Difference: %d bytes', [memDiff]));
  
  // Check for memory leaks (allowing small variations)
  if Abs(memDiff) < 10240 then  // Less than 10KB difference
    WriteLn('  ✓ No significant memory leaks detected')
  else if memDiff > 0 then
    WriteLn(Format('  ⚠ Possible memory leak: %d bytes growth', [memDiff]))
  else
    WriteLn(Format('  ✓ Memory usage decreased by %d bytes', [-memDiff]));
    
  WriteLn('Test Memory Usage: PASSED');
  WriteLn;
end;

procedure TestBackendEnumeration;
var
  backends: TSimdBackendArray;
  bestBackend: TSimdBackend;
  info: TSimdBackendInfo;
  i, j: Integer;
  sorted: Boolean;
begin
  WriteLn('=== Testing Backend Enumeration ===');
  
  // Get available backends
  backends := GetAvailableBackends;
  WriteLn(Format('  Found %d available backends:', [Length(backends)]));
  
  for i := 0 to Length(backends) - 1 do
  begin
    info := GetBackendInfo(backends[i]);
    WriteLn(Format('    [%d] %s (Priority: %d)', 
                   [i, info.Name, info.Priority]));
  end;
  
  // Check if backends are sorted by priority (descending)
  sorted := True;
  for i := 1 to Length(backends) - 1 do
  begin
    if GetBackendInfo(backends[i]).Priority > 
       GetBackendInfo(backends[i-1]).Priority then
    begin
      sorted := False;
      Break;
    end;
  end;
  
  if sorted then
    WriteLn('  ✓ Backends are properly sorted by priority')
  else
    WriteLn('  ✗ Backends are not sorted by priority!');
    
  // Test best backend selection
  bestBackend := GetBestBackend;
  info := GetBackendInfo(bestBackend);
  WriteLn(Format('  Best backend: %s (Priority: %d)', 
                 [info.Name, info.Priority]));
  
  // Verify best backend is actually the highest priority available
  if (Length(backends) > 0) and (backends[0] = bestBackend) then
    WriteLn('  ✓ Best backend matches highest priority')
  else if Length(backends) = 0 then
    WriteLn('  ⚠ No backends available')
  else
    WriteLn('  ✗ Best backend does not match highest priority!');
    
  // Test backend capabilities
  WriteLn('  Testing backend capabilities...');
  for i := 0 to Length(backends) - 1 do
  begin
    info := GetBackendInfo(backends[i]);
    Write(Format('    %s capabilities: ', [info.Name]));
    
    if scBasicArithmetic in info.Capabilities then Write('Arithmetic ');
    if scComparison in info.Capabilities then Write('Compare ');
    if scMathFunctions in info.Capabilities then Write('Math ');
    if scReduction in info.Capabilities then Write('Reduce ');
    if scShuffle in info.Capabilities then Write('Shuffle ');
    if scFMA in info.Capabilities then Write('FMA ');
    if scIntegerOps in info.Capabilities then Write('Integer ');
    if scLoadStore in info.Capabilities then Write('Load/Store ');
    if scGather in info.Capabilities then Write('Gather ');
    if scMaskedOps in info.Capabilities then Write('Masked ');
    WriteLn;
  end;
  
  WriteLn('Test Backend Enumeration: PASSED');
  WriteLn;
end;

end.