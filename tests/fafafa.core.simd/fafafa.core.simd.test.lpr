program fafafa.core.simd.test;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.testcase,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.types,
  fafafa.core.simd.api,
  fafafa.core.simd.scalar,
  fafafa.core.simd.sse2,
  fafafa.core.simd.avx2;

var
  testResult: TTestResult;
  testSuite: TTestSuite;
  i: Integer;
  failure: TTestFailure;

procedure RunBenchmarks;
const
  ITERATIONS = 1000000;
  ARRAY_SIZE = 4096;
var
  buf1, buf2: array[0..ARRAY_SIZE-1] of Byte;
  i, j: Integer;
  startTime, endTime: Int64;
  scalarTime, sse2Time, avx2Time: Double;
  dummy: LongBool;
  dummyIdx: PtrInt;
  dummySum: UInt64;
  dummyCount: SizeUInt;
  dummyMin, dummyMax: Byte;
  dummyBool: Boolean;
begin
  // Initialize test data
  for i := 0 to ARRAY_SIZE - 1 do
  begin
    buf1[i] := Byte(i mod 256);
    buf2[i] := Byte(i mod 256);
  end;

  WriteLn('=== Performance Benchmarks ===');
  WriteLn('Testing with ', ARRAY_SIZE, ' bytes, ', ITERATIONS, ' iterations');
  WriteLn;

  // Test MemEqual
  WriteLn('MemEqual:');
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummy := MemEqual_Scalar(@buf1[0], @buf2[0], ARRAY_SIZE);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummy := MemEqual_SSE2(@buf1[0], @buf2[0], ARRAY_SIZE);
  sse2Time := GetTickCount64 - startTime;
  WriteLn('  SSE2:   ', sse2Time:0:0, ' ms (', (scalarTime/sse2Time):0:2, 'x)');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummy := MemEqual_AVX2(@buf1[0], @buf2[0], ARRAY_SIZE);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test MemFindByte
  WriteLn('MemFindByte:');
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyIdx := MemFindByte_Scalar(@buf1[0], ARRAY_SIZE, 255);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyIdx := MemFindByte_SSE2(@buf1[0], ARRAY_SIZE, 255);
  sse2Time := GetTickCount64 - startTime;
  WriteLn('  SSE2:   ', sse2Time:0:0, ' ms (', (scalarTime/sse2Time):0:2, 'x)');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummyIdx := MemFindByte_AVX2(@buf1[0], ARRAY_SIZE, 255);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test SumBytes
  WriteLn('SumBytes:');
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummySum := SumBytes_Scalar(@buf1[0], ARRAY_SIZE);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummySum := SumBytes_SSE2(@buf1[0], ARRAY_SIZE);
  sse2Time := GetTickCount64 - startTime;
  WriteLn('  SSE2:   ', sse2Time:0:0, ' ms (', (scalarTime/sse2Time):0:2, 'x)');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummySum := SumBytes_AVX2(@buf1[0], ARRAY_SIZE);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test CountByte
  WriteLn('CountByte:');
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyCount := CountByte_Scalar(@buf1[0], ARRAY_SIZE, $AA);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyCount := CountByte_SSE2(@buf1[0], ARRAY_SIZE, $AA);
  sse2Time := GetTickCount64 - startTime;
  WriteLn('  SSE2:   ', sse2Time:0:0, ' ms (', (scalarTime/sse2Time):0:2, 'x)');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummyCount := CountByte_AVX2(@buf1[0], ARRAY_SIZE, $AA);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test MinMaxBytes
  WriteLn('MinMaxBytes:');
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do MinMaxBytes_Scalar(@buf1[0], ARRAY_SIZE, dummyMin, dummyMax);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do MinMaxBytes_AVX2(@buf1[0], ARRAY_SIZE, dummyMin, dummyMax);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test BitsetPopCount
  WriteLn('BitsetPopCount:');
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyCount := BitsetPopCount_Scalar(@buf1[0], ARRAY_SIZE);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummyCount := BitsetPopCount_AVX2(@buf1[0], ARRAY_SIZE);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test Utf8Validate (ASCII data)
  WriteLn('Utf8Validate (ASCII):');
  // Fill with ASCII data for fair comparison
  for i := 0 to ARRAY_SIZE - 1 do
    buf1[i] := Byte(32 + (i mod 95));  // Printable ASCII
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyBool := Utf8Validate_Scalar(@buf1[0], ARRAY_SIZE);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummyBool := Utf8Validate_AVX2(@buf1[0], ARRAY_SIZE);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test ToLowerAscii
  WriteLn('ToLowerAscii:');
  for i := 0 to ARRAY_SIZE - 1 do
    buf1[i] := Byte(65 + (i mod 26)); // 'A'..'Z' repeated
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do
  begin
    for i := 0 to ARRAY_SIZE - 1 do buf1[i] := Byte(65 + (i mod 26));
    ToLowerAscii_Scalar(@buf1[0], ARRAY_SIZE);
  end;
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do
    begin
      for i := 0 to ARRAY_SIZE - 1 do buf1[i] := Byte(65 + (i mod 26));
      ToLowerAscii_AVX2(@buf1[0], ARRAY_SIZE);
    end;
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;

  // Test AsciiIEqual
  WriteLn('AsciiIEqual:');
  for i := 0 to ARRAY_SIZE - 1 do
  begin
    buf1[i] := Byte(65 + (i mod 26)); // 'A'..'Z'
    buf2[i] := Byte(97 + (i mod 26)); // 'a'..'z'
  end;
  startTime := GetTickCount64;
  for j := 1 to ITERATIONS do dummyBool := AsciiIEqual_Scalar(@buf1[0], @buf2[0], ARRAY_SIZE);
  scalarTime := GetTickCount64 - startTime;
  WriteLn('  Scalar: ', scalarTime:0:0, ' ms');

  if HasAVX2 then
  begin
    startTime := GetTickCount64;
    for j := 1 to ITERATIONS do dummyBool := AsciiIEqual_AVX2(@buf1[0], @buf2[0], ARRAY_SIZE);
    avx2Time := GetTickCount64 - startTime;
    WriteLn('  AVX2:   ', avx2Time:0:0, ' ms (', (scalarTime/avx2Time):0:2, 'x)');
  end;
  WriteLn;
  
  // Prevent unused variable warning
  if dummy then;
  if dummyIdx > 0 then;
  if dummySum > 0 then;
  if dummyCount > 0 then;
  if dummyMin > 0 then;
  if dummyMax > 0 then;
  if dummyBool then;
end;

begin
  WriteLn('=== fafafa.core.simd Test Suite ===');
  WriteLn('Starting SIMD facade function tests...');
  WriteLn;
  
  // Display backend info
  WriteLn('CPU Features:');
  WriteLn('  SSE2: ', HasSSE2);
  WriteLn('  AVX2: ', HasAVX2);
  WriteLn('  Active Backend: ', Ord(GetActiveBackend));
  WriteLn;

  // Create test suite
  testSuite := TTestSuite.Create('SIMD Tests');
  try
    // Add test cases
    testSuite.AddTest(TTestCase_Global.Suite);
    testSuite.AddTest(TTestCase_BackendConsistency.Suite);
    testSuite.AddTest(TTestCase_VectorOps.Suite);
    testSuite.AddTest(TTestCase_LargeData.Suite);
    testSuite.AddTest(TTestCase_UnsignedVectorTypes.Suite);

    // Create test result
    testResult := TTestResult.Create;
    try
      // Run tests
      testSuite.Run(testResult);

      // Display results
      WriteLn;
      WriteLn('=== Test Results ===');
      WriteLn('Tests run: ', testResult.RunTests);
      WriteLn('Failures: ', testResult.NumberOfFailures);
      WriteLn('Errors: ', testResult.NumberOfErrors);

      // Show failures
      if testResult.NumberOfFailures > 0 then
      begin
        WriteLn;
        WriteLn('=== Failures ===');
        for i := 0 to testResult.Failures.Count - 1 do
        begin
          failure := TTestFailure(testResult.Failures[i]);
          WriteLn('  [', i+1, '] ', failure.AsString);
        end;
      end;

      // Show errors
      if testResult.NumberOfErrors > 0 then
      begin
        WriteLn;
        WriteLn('=== Errors ===');
        for i := 0 to testResult.Errors.Count - 1 do
        begin
          failure := TTestFailure(testResult.Errors[i]);
          WriteLn('  [', i+1, '] ', failure.AsString);
        end;
      end;

      if (testResult.NumberOfFailures = 0) and (testResult.NumberOfErrors = 0) then
      begin
        WriteLn('All tests passed!');
        ExitCode := 0;
        
        // Run benchmarks if all tests pass
        WriteLn;
        RunBenchmarks;
      end
      else
      begin
        WriteLn('Some tests failed!');
        ExitCode := 1;
      end;

    finally
      testResult.Free;
    end;
  finally
    testSuite.Free;
  end;

  // Wait for user input in debug mode
  {$IFDEF DEBUG}
  WriteLn('Press Enter to exit...');
  ReadLn;
  {$ENDIF}
end.
