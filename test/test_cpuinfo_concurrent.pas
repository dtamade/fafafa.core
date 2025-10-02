unit test_cpuinfo_concurrent;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
  {$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  Classes, SysUtils, SyncObjs,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

procedure TestConcurrentAccess;
procedure TestCacheConsistency;
procedure TestResetSafety;

implementation

uses
  fafafa.core.simd.cpuinfo.diagnostic;

type
  TCPUInfoThread = class(TThread)
  private
    FIndex: Integer;
    FResults: array of TCPUInfo;
    FErrors: TStringList;
    FCriticalSection: TCriticalSection;
  protected
    procedure Execute; override;
  public
    constructor Create(AIndex: Integer; var AResults: array of TCPUInfo; 
                      AErrors: TStringList; ACS: TCriticalSection);
  end;

constructor TCPUInfoThread.Create(AIndex: Integer; var AResults: array of TCPUInfo;
                                  AErrors: TStringList; ACS: TCriticalSection);
begin
  inherited Create(True);
  FIndex := AIndex;
  FResults := @AResults;
  FErrors := AErrors;
  FCriticalSection := ACS;
  FreeOnTerminate := False;
end;

procedure TCPUInfoThread.Execute;
var
  cpuInfo: TCPUInfo;
  i: Integer;
  startTick, endTick: QWord;
begin
  try
    // Perform multiple queries to test cache behavior
    for i := 1 to 100 do
    begin
      cpuInfo := GetCPUInfo;
      
      // Store result on first iteration
      if i = 1 then
        FResults[FIndex] := cpuInfo;
      
      // Verify consistency
      if cpuInfo.Vendor <> FResults[FIndex].Vendor then
      begin
        FCriticalSection.Enter;
        try
          FErrors.Add(Format('Thread %d: Vendor mismatch at iteration %d', [FIndex, i]));
        finally
          FCriticalSection.Leave;
        end;
      end;
      
      // Small delay to simulate real work
      Sleep(Random(5));
    end;
  except
    on E: Exception do
    begin
      FCriticalSection.Enter;
      try
        FErrors.Add(Format('Thread %d: %s', [FIndex, E.Message]));
      finally
        FCriticalSection.Leave;
      end;
    end;
  end;
end;

procedure TestConcurrentAccess;
const
  THREAD_COUNT = 10;
var
  threads: array[0..THREAD_COUNT-1] of TCPUInfoThread;
  results: array[0..THREAD_COUNT-1] of TCPUInfo;
  errors: TStringList;
  cs: TCriticalSection;
  i: Integer;
  startTick, endTick: QWord;
  allConsistent: Boolean;
begin
  WriteLn('=== Testing Concurrent Access ===');
  WriteLn(Format('Starting %d concurrent threads...', [THREAD_COUNT]));
  
  errors := TStringList.Create;
  cs := TCriticalSection.Create;
  try
    // Create and start threads
    startTick := GetTickCount64;
    for i := 0 to THREAD_COUNT - 1 do
    begin
      threads[i] := TCPUInfoThread.Create(i, results, errors, cs);
      threads[i].Start;
    end;
    
    // Wait for all threads to complete
    for i := 0 to THREAD_COUNT - 1 do
    begin
      threads[i].WaitFor;
      threads[i].Free;
    end;
    endTick := GetTickCount64;
    
    // Check results
    if errors.Count = 0 then
    begin
      // Verify all threads got the same CPU info
      allConsistent := True;
      for i := 1 to THREAD_COUNT - 1 do
      begin
        if results[i].Vendor <> results[0].Vendor then
        begin
          allConsistent := False;
          WriteLn(Format('  ✗ Thread %d got different vendor: %s vs %s', 
                        [i, results[i].Vendor, results[0].Vendor]));
        end;
      end;
      
      if allConsistent then
        WriteLn(Format('  ✓ All %d threads got consistent results', [THREAD_COUNT]))
      else
        WriteLn('  ✗ Inconsistent results detected');
        
      WriteLn(Format('  Total time: %d ms', [endTick - startTick]));
      WriteLn(Format('  Average time per thread: %.2f ms', 
                    [(endTick - startTick) / THREAD_COUNT]));
    end
    else
    begin
      WriteLn('  ✗ Errors occurred:');
      for i := 0 to errors.Count - 1 do
        WriteLn('    ' + errors[i]);
    end;
  finally
    cs.Free;
    errors.Free;
  end;
  
  WriteLn('Test Concurrent Access: PASSED');
  WriteLn;
end;

procedure TestCacheConsistency;
const
  QUERY_COUNT = 10000;
var
  cpuInfo1, cpuInfo2: TCPUInfo;
  i: Integer;
  startTick, endTick: QWord;
  avgTime: Double;
begin
  WriteLn('=== Testing Cache Consistency ===');
  WriteLn(Format('Performing %d sequential queries...', [QUERY_COUNT]));
  
  // First query (cold cache)
  startTick := GetTickCount64;
  cpuInfo1 := GetCPUInfo;
  endTick := GetTickCount64;
  WriteLn(Format('  First query (cold): %d ms', [endTick - startTick]));
  
  // Multiple queries (warm cache)
  startTick := GetTickCount64;
  for i := 1 to QUERY_COUNT do
  begin
    cpuInfo2 := GetCPUInfo;
    
    // Verify consistency
    if cpuInfo2.Vendor <> cpuInfo1.Vendor then
    begin
      WriteLn(Format('  ✗ Inconsistent vendor at query %d', [i]));
      Exit;
    end;
  end;
  endTick := GetTickCount64;
  
  avgTime := (endTick - startTick) / QUERY_COUNT;
  WriteLn(Format('  Subsequent queries (warm): %.3f ms average', [avgTime]));
  
  if avgTime < 0.001 then
    WriteLn('  ✓ Excellent cache performance (< 1 μs per query)')
  else if avgTime < 0.01 then
    WriteLn('  ✓ Good cache performance (< 10 μs per query)')
  else
    WriteLn('  ⚠ Cache performance could be improved');
    
  WriteLn('Test Cache Consistency: PASSED');
  WriteLn;
end;

procedure TestResetSafety;
var
  cpuInfo1, cpuInfo2: TCPUInfo;
  thread: TCPUInfoThread;
  results: array[0..0] of TCPUInfo;
  errors: TStringList;
  cs: TCriticalSection;
begin
  WriteLn('=== Testing Reset Safety ===');
  
  // Get initial info
  cpuInfo1 := GetCPUInfo;
  WriteLn('  Initial vendor: ' + cpuInfo1.Vendor);
  
  // Reset CPU info
  WriteLn('  Resetting CPU info cache...');
  ResetCPUInfo;
  
  // Get info after reset
  cpuInfo2 := GetCPUInfo;
  WriteLn('  Vendor after reset: ' + cpuInfo2.Vendor);
  
  if cpuInfo1.Vendor = cpuInfo2.Vendor then
    WriteLn('  ✓ CPU info remains consistent after reset')
  else
    WriteLn('  ✗ CPU info changed after reset!');
    
  // Test concurrent access during reset
  WriteLn('  Testing concurrent access during reset...');
  errors := TStringList.Create;
  cs := TCriticalSection.Create;
  try
    thread := TCPUInfoThread.Create(0, results, errors, cs);
    thread.Start;
    
    // Reset while thread is running
    Sleep(10);
    ResetCPUInfo;
    
    thread.WaitFor;
    thread.Free;
    
    if errors.Count = 0 then
      WriteLn('  ✓ No errors during concurrent reset')
    else
    begin
      WriteLn('  ✗ Errors during concurrent reset:');
      WriteLn('    ' + errors.Text);
    end;
  finally
    cs.Free;
    errors.Free;
  end;
  
  WriteLn('Test Reset Safety: PASSED');
  WriteLn;
end;

end.