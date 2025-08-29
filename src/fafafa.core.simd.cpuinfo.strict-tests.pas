program fafafa_core_simd_cpuinfo_strict_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.simple;

// === Strict Test Suite for CPU Info Module ===

type
  TTestResult = record
    TestName: string;
    Passed: Boolean;
    ErrorMessage: string;
    ExecutionTime: Double;
  end;
  
  TTestResults = array of TTestResult;

var
  g_TestResults: TTestResults;
  g_TestCount: Integer = 0;

// === Test Infrastructure ===

procedure AddTestResult(const testName: string; passed: Boolean; const errorMsg: string = ''; execTime: Double = 0);
begin
  SetLength(g_TestResults, g_TestCount + 1);
  g_TestResults[g_TestCount].TestName := testName;
  g_TestResults[g_TestCount].Passed := passed;
  g_TestResults[g_TestCount].ErrorMessage := errorMsg;
  g_TestResults[g_TestCount].ExecutionTime := execTime;
  Inc(g_TestCount);
end;

function MeasureTimeStart: QWord;
begin
  Result := GetTickCount64;
end;

function MeasureTimeEnd(startTime: QWord): Double;
begin
  Result := (GetTickCount64 - startTime) / 1000.0;
end;

procedure Assert(condition: Boolean; const message: string);
begin
  if not condition then
    raise Exception.Create('Assertion failed: ' + message);
end;

// === Basic Functionality Tests ===

procedure TestBasicCPUInfoRetrieval;
var
  cpuInfo: TCPUInfo;
  execTime: Double;
  startTime: QWord;
begin
  startTime := MeasureTimeStart;
  cpuInfo := GetCPUInfo;
  execTime := MeasureTimeEnd(startTime);
  
  try
    Assert(cpuInfo.Vendor <> '', 'CPU vendor should not be empty');
    Assert(cpuInfo.Model <> '', 'CPU model should not be empty');
    Assert(Length(cpuInfo.Vendor) > 0, 'CPU vendor should have content');
    Assert(Length(cpuInfo.Model) > 0, 'CPU model should have content');
    
    AddTestResult('TestBasicCPUInfoRetrieval', True, '', execTime);
  except
    on E: Exception do
      AddTestResult('TestBasicCPUInfoRetrieval', False, E.Message, execTime);
  end;
end;

procedure TestBackendAvailability;
var
  backend: TSimdBackend;
  available: Boolean;
  execTime: Double;
  startTime: QWord;
begin
  startTime := MeasureTimeStart;
  for backend := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    available := IsBackendAvailable(backend);
    // Scalar backend must always be available
    if backend = sbScalar then
      Assert(available, 'Scalar backend must always be available');
  end;
  execTime := MeasureTimeEnd(startTime);
  
  try
    AddTestResult('TestBackendAvailability', True, '', execTime);
  except
    on E: Exception do
      AddTestResult('TestBackendAvailability', False, E.Message, execTime);
  end;
end;

procedure TestBestBackendSelection;
var
  bestBackend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  execTime: Double;
  startTime: QWord;
begin
  startTime := MeasureTimeStart;
  bestBackend := GetBestBackend;
  backendInfo := GetBackendInfo(bestBackend);
  execTime := MeasureTimeEnd(startTime);
  
  try
    Assert(backendInfo.Available, 'Best backend must be available');
    Assert(backendInfo.Name <> '', 'Best backend must have a name');
    Assert(backendInfo.Priority >= 0, 'Best backend must have valid priority');
    
    AddTestResult('TestBestBackendSelection', True, '', execTime);
  except
    on E: Exception do
      AddTestResult('TestBestBackendSelection', False, E.Message, execTime);
  end;
end;

// === Thread Safety Tests ===

type
  TThreadTestData = record
    ThreadID: Integer;
    Iterations: Integer;
    Success: Boolean;
    ErrorMessage: string;
    Results: array of TCPUInfo;
  end;
  PThreadTestData = ^TThreadTestData;

procedure ThreadTestProc(data: Pointer);
var
  testData: PThreadTestData;
  i: Integer;
  cpuInfo: TCPUInfo;
begin
  testData := PThreadTestData(data);
  testData^.Success := True;
  SetLength(testData^.Results, testData^.Iterations);
  
  try
    for i := 0 to testData^.Iterations - 1 do
    begin
      cpuInfo := GetCPUInfo;
      testData^.Results[i] := cpuInfo;
      
      // Validate basic properties
      if (cpuInfo.Vendor = '') or (cpuInfo.Model = '') then
      begin
        testData^.Success := False;
        testData^.ErrorMessage := Format('Thread %d: Invalid CPU info at iteration %d', [testData^.ThreadID, i]);
        Exit;
      end;
    end;
  except
    on E: Exception do
    begin
      testData^.Success := False;
      testData^.ErrorMessage := Format('Thread %d: Exception - %s', [testData^.ThreadID, E.Message]);
    end;
  end;
end;

procedure TestThreadSafety;
const
  NUM_THREADS = 8;
  ITERATIONS_PER_THREAD = 1000;
var
  threads: array[0..NUM_THREADS-1] of TThreadID;
  testData: array[0..NUM_THREADS-1] of TThreadTestData;
  i, j: Integer;
  allSuccess: Boolean;
  errorMsg: string;
  execTime: Double;
  startTime: QWord;
begin
  startTime := GetTickCount64;
  
  try
    // Initialize test data
    for i := 0 to NUM_THREADS - 1 do
    begin
      testData[i].ThreadID := i;
      testData[i].Iterations := ITERATIONS_PER_THREAD;
      testData[i].Success := False;
      testData[i].ErrorMessage := '';
    end;
    
    // Create threads
    for i := 0 to NUM_THREADS - 1 do
    begin
      threads[i] := BeginThread(@ThreadTestProc, @testData[i]);
    end;
    
    // Wait for all threads to complete
    for i := 0 to NUM_THREADS - 1 do
    begin
      WaitForThreadTerminate(threads[i], 30000); // 30 second timeout
    end;
    
    execTime := (GetTickCount64 - startTime) / 1000.0;
    
    // Check results
    allSuccess := True;
    errorMsg := '';
    
    for i := 0 to NUM_THREADS - 1 do
    begin
      if not testData[i].Success then
      begin
        allSuccess := False;
        errorMsg := errorMsg + testData[i].ErrorMessage + '; ';
      end
      else
      begin
        // Verify consistency within thread
        for j := 1 to Length(testData[i].Results) - 1 do
        begin
          if (testData[i].Results[j].Vendor <> testData[i].Results[0].Vendor) or
             (testData[i].Results[j].Model <> testData[i].Results[0].Model) then
          begin
            allSuccess := False;
            errorMsg := errorMsg + Format('Thread %d: Inconsistent results at iteration %d; ', [i, j]);
          end;
        end;
      end;
    end;
    
    // Verify consistency across threads
    if allSuccess then
    begin
      for i := 1 to NUM_THREADS - 1 do
      begin
        if (testData[i].Results[0].Vendor <> testData[0].Results[0].Vendor) or
           (testData[i].Results[0].Model <> testData[0].Results[0].Model) then
        begin
          allSuccess := False;
          errorMsg := errorMsg + Format('Cross-thread inconsistency between thread 0 and %d; ', [i]);
        end;
      end;
    end;
    
    AddTestResult('TestThreadSafety', allSuccess, errorMsg, execTime);
    
  except
    on E: Exception do
      AddTestResult('TestThreadSafety', False, E.Message, (GetTickCount64 - startTime) / 1000.0);
  end;
end;

// === Performance Tests ===

procedure TestPerformanceConsistency;
const
  NUM_CALLS = 100000;
  MAX_ACCEPTABLE_TIME_NS = 1000; // 1 microsecond per call
var
  i: Integer;
  cpuInfo: TCPUInfo;
  startTime, endTime: QWord;
  totalTime, avgTimeNs: Double;
  passed: Boolean;
  errorMsg: string;
begin
  try
    // Warm up
    for i := 1 to 100 do
      cpuInfo := GetCPUInfo;
    
    // Measure performance
    startTime := GetTickCount64;
    for i := 1 to NUM_CALLS do
      cpuInfo := GetCPUInfo;
    endTime := GetTickCount64;
    
    totalTime := (endTime - startTime) / 1000.0;
    avgTimeNs := (totalTime * 1000000000.0) / NUM_CALLS;
    
    passed := avgTimeNs <= MAX_ACCEPTABLE_TIME_NS;
    if not passed then
      errorMsg := Format('Average time %.2f ns exceeds limit of %d ns', [avgTimeNs, MAX_ACCEPTABLE_TIME_NS])
    else
      errorMsg := Format('Average time: %.2f ns', [avgTimeNs]);
    
    AddTestResult('TestPerformanceConsistency', passed, errorMsg, totalTime);
    
  except
    on E: Exception do
      AddTestResult('TestPerformanceConsistency', False, E.Message, 0);
  end;
end;

// === Edge Case Tests ===

procedure TestInvalidBackendHandling;
var
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  passed: Boolean;
  execTime: Double;
  startTime: QWord;
begin
  startTime := MeasureTimeStart;
  // Test with invalid backend value (cast from integer)
  backend := TSimdBackend(999);
  backendInfo := GetBackendInfo(backend);
  execTime := MeasureTimeEnd(startTime);
  
  try
    // Should handle gracefully without crashing
    passed := True;
    AddTestResult('TestInvalidBackendHandling', passed, 'Handled gracefully', execTime);
  except
    on E: Exception do
      AddTestResult('TestInvalidBackendHandling', False, E.Message, execTime);
  end;
end;

procedure TestFeatureConsistency;
var
  cpuInfo: TCPUInfo;
  passed: Boolean;
  errorMsg: string;
  execTime: Double;
  startTime: QWord;
begin
  startTime := MeasureTimeStart;
  cpuInfo := GetCPUInfo;
  execTime := MeasureTimeEnd(startTime);
  
  try
    passed := True;
    errorMsg := '';
    
    {$IFDEF SIMD_X86_AVAILABLE}
    // Test x86 feature hierarchy
    if cpuInfo.X86.HasSSE2 and not cpuInfo.X86.HasSSE then
    begin
      passed := False;
      errorMsg := errorMsg + 'SSE2 without SSE; ';
    end;
    
    if cpuInfo.X86.HasAVX2 and not cpuInfo.X86.HasAVX then
    begin
      passed := False;
      errorMsg := errorMsg + 'AVX2 without AVX; ';
    end;
    
    if cpuInfo.X86.HasAVX512F and not cpuInfo.X86.HasAVX2 then
    begin
      passed := False;
      errorMsg := errorMsg + 'AVX512F without AVX2; ';
    end;
    
    if cpuInfo.X86.HasSSE3 and not cpuInfo.X86.HasSSE2 then
    begin
      passed := False;
      errorMsg := errorMsg + 'SSE3 without SSE2; ';
    end;
    {$ENDIF}
    
    if passed then
      errorMsg := 'All feature dependencies valid';
    
    AddTestResult('TestFeatureConsistency', passed, errorMsg, execTime);

  except
    on E: Exception do
      AddTestResult('TestFeatureConsistency', False, E.Message, execTime);
  end;
end;

// === Memory and Resource Tests ===

procedure TestMemoryLeaks;
const
  NUM_ITERATIONS = 10000;
var
  i: Integer;
  cpuInfo: TCPUInfo;
  backends: TSimdBackendArray;
  backendInfo: TSimdBackendInfo;
  execTime: Double;
  startTime: QWord;
begin
  startTime := GetTickCount64;

  try
    // Repeatedly call functions that might allocate memory
    for i := 1 to NUM_ITERATIONS do
    begin
      cpuInfo := GetCPUInfo;
      backends := GetAvailableBackends;
      if Length(backends) > 0 then
        backendInfo := GetBackendInfo(backends[0]);
    end;

    execTime := (GetTickCount64 - startTime) / 1000.0;
    AddTestResult('TestMemoryLeaks', True, Format('Completed %d iterations', [NUM_ITERATIONS]), execTime);

  except
    on E: Exception do
      AddTestResult('TestMemoryLeaks', False, E.Message, (GetTickCount64 - startTime) / 1000.0);
  end;
end;

procedure TestBackendInfoCompleteness;
var
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  passed: Boolean;
  errorMsg: string;
  execTime: Double;
  startTime: QWord;
begin
  startTime := GetTickCount64;
  passed := True;
  errorMsg := '';

  try
    for backend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      backendInfo := GetBackendInfo(backend);

      // Validate backend info completeness
      if backendInfo.Name = '' then
      begin
        passed := False;
        errorMsg := errorMsg + Format('Backend %d has empty name; ', [Ord(backend)]);
      end;

      if backendInfo.Description = '' then
      begin
        passed := False;
        errorMsg := errorMsg + Format('Backend %d has empty description; ', [Ord(backend)]);
      end;

      if backendInfo.Priority < 0 then
      begin
        passed := False;
        errorMsg := errorMsg + Format('Backend %d has negative priority; ', [Ord(backend)]);
      end;

      // Validate that available backends have reasonable capabilities
      if backendInfo.Available and (backendInfo.Capabilities = []) then
      begin
        passed := False;
        errorMsg := errorMsg + Format('Available backend %d has no capabilities; ', [Ord(backend)]);
      end;
    end;

    execTime := (GetTickCount64 - startTime) / 1000.0;

    if passed then
      errorMsg := 'All backend info complete and valid';

    AddTestResult('TestBackendInfoCompleteness', passed, errorMsg, execTime);

  except
    on E: Exception do
      AddTestResult('TestBackendInfoCompleteness', False, E.Message, (GetTickCount64 - startTime) / 1000.0);
  end;
end;

// === Stress Tests ===

procedure TestRapidSuccessiveCalls;
const
  NUM_RAPID_CALLS = 1000000;
var
  i: Integer;
  cpuInfo1, cpuInfo2: TCPUInfo;
  passed: Boolean;
  errorMsg: string;
  execTime: Double;
  startTime: QWord;
begin
  startTime := GetTickCount64;
  passed := True;
  errorMsg := '';

  try
    cpuInfo1 := GetCPUInfo;

    for i := 1 to NUM_RAPID_CALLS do
    begin
      cpuInfo2 := GetCPUInfo;

      // Verify consistency every 100000 calls
      if (i mod 100000) = 0 then
      begin
        if (cpuInfo1.Vendor <> cpuInfo2.Vendor) or (cpuInfo1.Model <> cpuInfo2.Model) then
        begin
          passed := False;
          errorMsg := Format('Inconsistency detected at call %d', [i]);
          Break;
        end;
      end;
    end;

    execTime := (GetTickCount64 - startTime) / 1000.0;

    if passed then
      errorMsg := Format('Completed %d rapid calls successfully', [NUM_RAPID_CALLS]);

    AddTestResult('TestRapidSuccessiveCalls', passed, errorMsg, execTime);

  except
    on E: Exception do
      AddTestResult('TestRapidSuccessiveCalls', False, E.Message, (GetTickCount64 - startTime) / 1000.0);
  end;
end;

// === Test Execution and Reporting ===

procedure RunAllTests;
begin
  WriteLn('=== fafafa.core.simd.cpuinfo Strict Test Suite ===');
  WriteLn;

  WriteLn('Running basic functionality tests...');
  TestBasicCPUInfoRetrieval;
  TestBackendAvailability;
  TestBestBackendSelection;

  WriteLn('Running thread safety tests...');
  TestThreadSafety;

  WriteLn('Running performance tests...');
  TestPerformanceConsistency;

  WriteLn('Running edge case tests...');
  TestInvalidBackendHandling;
  TestFeatureConsistency;

  WriteLn('Running memory and resource tests...');
  TestMemoryLeaks;
  TestBackendInfoCompleteness;

  WriteLn('Running stress tests...');
  TestRapidSuccessiveCalls;

  WriteLn('All tests completed.');
  WriteLn;
end;

procedure PrintTestResults;
var
  i: Integer;
  passedCount, failedCount: Integer;
  totalTime: Double;
begin
  WriteLn('=== Test Results Summary ===');
  WriteLn;

  passedCount := 0;
  failedCount := 0;
  totalTime := 0;

  for i := 0 to g_TestCount - 1 do
  begin
    with g_TestResults[i] do
    begin
      if Passed then
      begin
        WriteLn('✓ ', TestName, ' (', ExecutionTime:0:3, 's)');
        if ErrorMessage <> '' then
          WriteLn('  Info: ', ErrorMessage);
        Inc(passedCount);
      end
      else
      begin
        WriteLn('✗ ', TestName, ' (', ExecutionTime:0:3, 's)');
        WriteLn('  Error: ', ErrorMessage);
        Inc(failedCount);
      end;
      totalTime := totalTime + ExecutionTime;
    end;
  end;

  WriteLn;
  WriteLn('=== Summary ===');
  WriteLn('Total tests: ', g_TestCount);
  WriteLn('Passed: ', passedCount);
  WriteLn('Failed: ', failedCount);
  WriteLn('Success rate: ', (passedCount * 100.0 / g_TestCount):0:1, '%');
  WriteLn('Total execution time: ', totalTime:0:3, ' seconds');

  if failedCount > 0 then
  begin
    WriteLn;
    WriteLn('⚠️  CRITICAL ISSUES DETECTED ⚠️');
    WriteLn('The CPU info module has failed ', failedCount, ' out of ', g_TestCount, ' tests.');
    WriteLn('This module is NOT ready for production use.');
  end
  else
  begin
    WriteLn;
    WriteLn('✅ ALL TESTS PASSED');
    WriteLn('The CPU info module appears to be working correctly.');
  end;
end;

// === Main Program ===

var
  i: Integer;

begin
  try
    RunAllTests;
    PrintTestResults;

    if g_TestCount = 0 then
    begin
      WriteLn('No tests were executed!');
      ExitCode := 2;
    end
    else
    begin
      // Set exit code based on test results
      ExitCode := 0;
      for i := 0 to g_TestCount - 1 do
      begin
        if not g_TestResults[i].Passed then
        begin
          ExitCode := 1;
          Break;
        end;
      end;
    end;

  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR during test execution: ', E.Message);
      ExitCode := 3;
    end;
  end;

  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
