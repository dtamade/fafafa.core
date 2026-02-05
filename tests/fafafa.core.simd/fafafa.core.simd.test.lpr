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
  fafafa.core.simd.direct.testcase,
  fafafa.core.simd.concurrent.testcase,  // ✅ Phase 5.4: Concurrent SIMD tests (12 tests)
  fafafa.core.simd.bench,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.api,
  fafafa.core.simd.scalar
  {$IFDEF CPUX86_64}
  , fafafa.core.simd.sse2
  , fafafa.core.simd.avx2
  {$ENDIF}
  ;

var
  testResult: TTestResult;
  testSuite: TTestSuite;
  i: Integer;
  failure: TTestFailure;
  suiteFilters: TStringList;
  doBench: Boolean;
  benchOnly: Boolean;
  pauseAtEnd: Boolean;
  vectorAsmEnabled: Boolean;
  exitEarly: Boolean;
  exitEarlyCode: Integer;
  exitEarlyShowUsage: Boolean;
  exitEarlyListSuites: Boolean;
  exitEarlyError: string;

procedure RunBenchmarks;
var
  Results: TBenchResults;
begin
  Results := fafafa.core.simd.bench.RunAllBenchmarks;
  PrintBenchResults(Results);
end;

procedure PrintUsage;
begin
  WriteLn('Usage: ', ExtractFileName(ParamStr(0)), ' [options]');
  WriteLn('Options:');
  WriteLn('  --suite=<TestCaseClass>[,<TestCaseClass>...]   Run only selected suites (repeatable)');
  WriteLn('  --suite <TestCaseClass>                       Same as above');
  WriteLn('  --list-suites                                 List available suites');
  WriteLn('  --bench                                       Run performance benchmarks after tests');
  WriteLn('  --bench-only                                  Run benchmarks only');
  WriteLn('  --no-bench                                    Do not run benchmarks (default)');
  WriteLn('  --vector-asm                                  Enable experimental SIMD vector ops (unsafe)');
  WriteLn('  --no-vector-asm                               Disable experimental SIMD vector ops (default)');
  WriteLn('  --pause                                       Pause and wait for Enter before exiting');
  WriteLn('  -h, --help                                    Show this help');
end;

procedure PrintAvailableSuites;
begin
  WriteLn('Available suites:');
  WriteLn('  TTestCase_Global');
  {$IFDEF CPUX86_64}
  WriteLn('  TTestCase_BackendConsistency');
  WriteLn('  TTestCase_BackendVectorConsistency');
  {$ENDIF}
  WriteLn('  TTestCase_BackendSmoke');
  {$IFDEF CPUX86_64}
  WriteLn('  TTestCase_AVX512BackendRequirements');
  {$ENDIF}
  {$IFDEF UNIX}
  {$IFDEF CPUX86_64}
  WriteLn('  TTestCase_AVX2VectorAsm');
  WriteLn('  TTestCase_AVX512VectorAsm');
  {$ENDIF}
  {$ENDIF}
  WriteLn('  TTestCase_VectorOps');
  WriteLn('  TTestCase_LargeData');
  WriteLn('  TTestCase_UnsignedVectorTypes');
  WriteLn('  TTestCase_OperatorOverloads');
  WriteLn('  TTestCase_VectorMaskTypes');
  WriteLn('  TTestCase_TypeConversion');
  WriteLn('  TTestCase_Builder');
  WriteLn('  TTestCase_GatherScatter');
  WriteLn('  TTestCase_ShuffleSWizzle');
  WriteLn('  TTestCase_MathFunctions');
  WriteLn('  TTestCase_AdvancedAlgorithms');
  WriteLn('  TTestCase_EdgeCases');
  WriteLn('  TTestCase_Vec512Types');
  WriteLn('  TTestCase_Memutils');
  WriteLn('  TTestCase_RustStyleAliases');
  WriteLn('  TTestCase_SaturatingArithmetic');
  WriteLn('  TTestCase_NarrowIntegerOps');
  WriteLn('  TTestCase_VecI32x8');
  WriteLn('  TTestCase_VecU32x8');
  WriteLn('  TTestCase_VecF32x8');
  WriteLn('  TTestCase_VecF64x4');
  WriteLn('  TTestCase_IEEE754_F64');
  WriteLn('  TTestCase_IEEE754EdgeCases');
  WriteLn('  TTestCase_DispatchAPI');
  WriteLn('  TTestCase_SimdConcurrent');  // ✅ Phase 5.4
end;

procedure AddSuiteFilter(const value: string);
var
  parts: TStringList;
  j: Integer;
  s: string;
begin
  if value = '' then Exit;

  parts := TStringList.Create;
  try
    parts.StrictDelimiter := True;
    parts.Delimiter := ',';
    parts.DelimitedText := value;

    for j := 0 to parts.Count - 1 do
    begin
      s := Trim(parts[j]);
      if s <> '' then
        suiteFilters.Add(s);
    end;
  finally
    parts.Free;
  end;
end;

function ShouldRunSuite(const suiteName: string): Boolean;
begin
  if (suiteFilters = nil) or (suiteFilters.Count = 0) then
    Exit(True);
  Result := suiteFilters.IndexOf(suiteName) >= 0;
end;

procedure ParseArgs;
var
  argIndex: Integer;
  arg, value: string;
begin
  doBench := False;
  benchOnly := False;
  pauseAtEnd := False;
  vectorAsmEnabled := False;

  exitEarly := False;
  exitEarlyCode := 0;
  exitEarlyShowUsage := False;
  exitEarlyListSuites := False;
  exitEarlyError := '';

  suiteFilters := TStringList.Create;
  suiteFilters.CaseSensitive := False;

  argIndex := 1;
  while argIndex <= ParamCount do
  begin
    arg := ParamStr(argIndex);

    if arg = '--bench' then
      doBench := True
    else if arg = '--no-bench' then
      doBench := False
    else if arg = '--bench-only' then
    begin
      doBench := True;
      benchOnly := True;
    end
    else if (arg = '--help') or (arg = '-h') then
    begin
      exitEarly := True;
      exitEarlyCode := 0;
      exitEarlyShowUsage := True;
      Exit;
    end
    else if arg = '--list-suites' then
    begin
      exitEarly := True;
      exitEarlyCode := 0;
      exitEarlyListSuites := True;
      Exit;
    end
    else if arg = '--pause' then
      pauseAtEnd := True
    else if arg = '--vector-asm' then
      vectorAsmEnabled := True
    else if arg = '--no-vector-asm' then
      vectorAsmEnabled := False
    else if arg = '--suite' then
    begin
      Inc(argIndex);
      if argIndex > ParamCount then
      begin
        exitEarly := True;
        exitEarlyCode := 2;
        exitEarlyShowUsage := True;
        exitEarlyError := 'Error: --suite requires a value';
        Exit;
      end;
      AddSuiteFilter(ParamStr(argIndex));
    end
    else if Copy(arg, 1, 8) = '--suite=' then
    begin
      value := Copy(arg, 9, MaxInt);
      AddSuiteFilter(value);
    end
    else
    begin
      exitEarly := True;
      exitEarlyCode := 2;
      exitEarlyShowUsage := True;
      exitEarlyError := 'Unknown argument: ' + arg;
      Exit;
    end;

    Inc(argIndex);
  end;
end;

begin
  ParseArgs;

  try
    if exitEarly then
    begin
      if exitEarlyError <> '' then
        WriteLn(exitEarlyError);
      if exitEarlyShowUsage then
        PrintUsage;
      if exitEarlyListSuites then
        PrintAvailableSuites;

      ExitCode := exitEarlyCode;

      if pauseAtEnd then
      begin
        WriteLn('Press Enter to exit...');
        ReadLn;
      end;

      Exit;
    end;

    WriteLn('=== fafafa.core.simd Test Suite ===');
    WriteLn('Starting SIMD facade function tests...');
    WriteLn;

    // Display backend info
    // Apply experimental toggles (must happen before backend selection is queried)
    SetVectorAsmEnabled(vectorAsmEnabled);
    if vectorAsmEnabled then
    begin
      {$IFDEF CPUX86_64}
      // Re-register backends so their dispatch tables reflect the new toggle.
      RegisterSSE2Backend;
      RegisterAVX2Backend;
      {$ENDIF}
    end;

    WriteLn('CPU Features:');
    WriteLn('  SSE2: ', HasSSE2);
    WriteLn('  AVX2: ', HasAVX2);
    WriteLn('  Active Backend: ', Ord(GetActiveBackend));
    WriteLn('  VectorAsm: ', IsVectorAsmEnabled);
    WriteLn('  Benchmarks: ', doBench);
    WriteLn;

    if benchOnly then
    begin
      RunBenchmarks;
      ExitCode := 0;
      Exit;
    end;

    // Create test suite
    testSuite := TTestSuite.Create('SIMD Tests');
    try
      // Add test cases
      if ShouldRunSuite('TTestCase_Global') then
        testSuite.AddTest(TTestCase_Global.Suite);
      {$IFDEF CPUX86_64}
      if ShouldRunSuite('TTestCase_BackendConsistency') then
        testSuite.AddTest(TTestCase_BackendConsistency.Suite);
      if ShouldRunSuite('TTestCase_BackendVectorConsistency') then
        testSuite.AddTest(TTestCase_BackendVectorConsistency.Suite);
      {$ENDIF}
      if ShouldRunSuite('TTestCase_BackendSmoke') then
        testSuite.AddTest(TTestCase_BackendSmoke.Suite);
      {$IFDEF CPUX86_64}
      {$IFDEF SIMD_BACKEND_AVX512}
      if ShouldRunSuite('TTestCase_AVX512BackendRequirements') then
        testSuite.AddTest(TTestCase_AVX512BackendRequirements.Suite);
      {$ENDIF}
      {$ENDIF}
      {$IFDEF UNIX}
      {$IFDEF CPUX86_64}
      if ShouldRunSuite('TTestCase_AVX2VectorAsm') then
        testSuite.AddTest(TTestCase_AVX2VectorAsm.Suite);
      {$IFDEF SIMD_BACKEND_AVX512}
      if ShouldRunSuite('TTestCase_AVX512VectorAsm') then
        testSuite.AddTest(TTestCase_AVX512VectorAsm.Suite);
      {$ENDIF}
      {$ENDIF}
      {$ENDIF}
      if ShouldRunSuite('TTestCase_VectorOps') then
        testSuite.AddTest(TTestCase_VectorOps.Suite);
      if ShouldRunSuite('TTestCase_LargeData') then
        testSuite.AddTest(TTestCase_LargeData.Suite);
      if ShouldRunSuite('TTestCase_UnsignedVectorTypes') then
        testSuite.AddTest(TTestCase_UnsignedVectorTypes.Suite);
      if ShouldRunSuite('TTestCase_OperatorOverloads') then
        testSuite.AddTest(TTestCase_OperatorOverloads.Suite);
      if ShouldRunSuite('TTestCase_VectorMaskTypes') then
        testSuite.AddTest(TTestCase_VectorMaskTypes.Suite);
      if ShouldRunSuite('TTestCase_TypeConversion') then
        testSuite.AddTest(TTestCase_TypeConversion.Suite);
      if ShouldRunSuite('TTestCase_Builder') then
        testSuite.AddTest(TTestCase_Builder.Suite);
      if ShouldRunSuite('TTestCase_GatherScatter') then
        testSuite.AddTest(TTestCase_GatherScatter.Suite);
      if ShouldRunSuite('TTestCase_ShuffleSWizzle') then
        testSuite.AddTest(TTestCase_ShuffleSWizzle.Suite);
      if ShouldRunSuite('TTestCase_MathFunctions') then
        testSuite.AddTest(TTestCase_MathFunctions.Suite);
      if ShouldRunSuite('TTestCase_AdvancedAlgorithms') then
        testSuite.AddTest(TTestCase_AdvancedAlgorithms.Suite);
      if ShouldRunSuite('TTestCase_EdgeCases') then
        testSuite.AddTest(TTestCase_EdgeCases.Suite);
      if ShouldRunSuite('TTestCase_Vec512Types') then
        testSuite.AddTest(TTestCase_Vec512Types.Suite);
      if ShouldRunSuite('TTestCase_Memutils') then
        testSuite.AddTest(TTestCase_Memutils.Suite);
      if ShouldRunSuite('TTestCase_RustStyleAliases') then
        testSuite.AddTest(TTestCase_RustStyleAliases.Suite);
      if ShouldRunSuite('TTestCase_SaturatingArithmetic') then
        testSuite.AddTest(TTestCase_SaturatingArithmetic.Suite);
      if ShouldRunSuite('TTestCase_NarrowIntegerOps') then
        testSuite.AddTest(TTestCase_NarrowIntegerOps.Suite);
      if ShouldRunSuite('TTestCase_VecI32x8') then
        testSuite.AddTest(TTestCase_VecI32x8.Suite);
      if ShouldRunSuite('TTestCase_VecU32x8') then
        testSuite.AddTest(TTestCase_VecU32x8.Suite);
      if ShouldRunSuite('TTestCase_VecF32x8') then
        testSuite.AddTest(TTestCase_VecF32x8.Suite);
      if ShouldRunSuite('TTestCase_VecF64x4') then
        testSuite.AddTest(TTestCase_VecF64x4.Suite);
      if ShouldRunSuite('TTestCase_IEEE754_F64') then
        testSuite.AddTest(TTestCase_IEEE754_F64.Suite);
      if ShouldRunSuite('TTestCase_IEEE754EdgeCases') then
        testSuite.AddTest(TTestCase_IEEE754EdgeCases.Suite);
      if ShouldRunSuite('TTestCase_DispatchAPI') then
        testSuite.AddTest(TTestCase_DispatchAPI.Suite);
      if ShouldRunSuite('TTestCase_SimdConcurrent') then
        testSuite.AddTest(TTestCase_SimdConcurrent.Suite);  // ✅ Phase 5.4

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

        if (suiteFilters <> nil) and (suiteFilters.Count > 0) and (testResult.RunTests = 0) then
        begin
          WriteLn('ERROR: suite filter matched no tests.');
          PrintAvailableSuites;
          ExitCode := 2;
        end
        else if (testResult.NumberOfFailures = 0) and (testResult.NumberOfErrors = 0) then
        begin
          WriteLn('All tests passed!');
          ExitCode := 0;

          if doBench then
          begin
            WriteLn;
            RunBenchmarks;
          end;
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
  finally
    suiteFilters.Free;
  end;

  if pauseAtEnd then
  begin
    WriteLn('Press Enter to exit...');
    ReadLn;
  end;
end.
