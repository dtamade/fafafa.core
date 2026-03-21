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
  fafafa.core.simd.memutils.aliases.testcase,
  fafafa.core.simd.narrowintegerops.testcase,
  fafafa.core.simd.saturating.testcase,
  fafafa.core.simd.veci32x8.testcase,
  fafafa.core.simd.vecu32x8.testcase,
  fafafa.core.simd.vecf32x8.testcase,
  fafafa.core.simd.vecf64x4.testcase,
  fafafa.core.simd.ieee754.testcase,
  fafafa.core.simd.dispatchapi.testcase,
  fafafa.core.simd.dispatchslots.testcase,
  fafafa.core.simd.publicabi.testcase,
  fafafa.core.simd.edgecases.testcase,
  fafafa.core.simd.vec512types.testcase,
  fafafa.core.simd.imageproc.testcase,
  {$IFDEF SIMD_X86_AVAILABLE}
  fafafa.core.simd.direct.testcase,
  {$ENDIF}
  fafafa.core.simd.intrinsics.avx2.testcase,
  fafafa.core.simd.concurrent.testcase,  // ✅ Phase 5.4: Concurrent SIMD tests (12 tests)
  fafafa.core.simd.bench,
  fafafa.core.simd.base,
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

procedure ProcessAllSuites(const aListOnly: Boolean; aTargetSuite: TTestSuite); forward;

procedure RunBenchmarks;
var
  Results: TBenchResults;
  LBackend: TSimdBackend;
begin
  LBackend := GetActiveBackend;
  if (not IsVectorAsmEnabled) and (LBackend in [sbAVX2, sbAVX512, sbNEON, sbRISCVV]) then
  begin
    WriteLn('[BENCH] Note: vector-asm is OFF; vector-op rows may still reflect scalar fallback paths.');
    WriteLn('[BENCH] For backend vector throughput, prefer --bench-only --vector-asm or dedicated bench_*.lpr runners.');
    WriteLn;
  end;
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
  ProcessAllSuites(True, nil);
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

procedure HandleSuite(const aName: string; const aSuite: TTest; const aListOnly: Boolean; aTargetSuite: TTestSuite);
begin
  if aListOnly then
  begin
    WriteLn('  ', aName);
    if aSuite <> nil then
      aSuite.Free;
    Exit;
  end;

  if (aTargetSuite <> nil) and ShouldRunSuite(aName) then
    aTargetSuite.AddTest(aSuite)
  else if aSuite <> nil then
    aSuite.Free;
end;

procedure ProcessAllSuites(const aListOnly: Boolean; aTargetSuite: TTestSuite);
begin
  HandleSuite('TTestCase_ImageProc', TTestCase_ImageProc.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_Global', TTestCase_Global.Suite, aListOnly, aTargetSuite);
  {$IFDEF CPUX86_64}
  HandleSuite('TTestCase_BackendConsistency', TTestCase_BackendConsistency.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_BackendVectorConsistency', TTestCase_BackendVectorConsistency.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_X86BackendPredicates', TTestCase_X86BackendPredicates.Suite, aListOnly, aTargetSuite);
  {$ENDIF}
  HandleSuite('TTestCase_BackendSmoke', TTestCase_BackendSmoke.Suite, aListOnly, aTargetSuite);
  {$IFDEF CPUX86_64}
  {$IFDEF SIMD_BACKEND_AVX512}
  HandleSuite('TTestCase_AVX512BackendRequirements', TTestCase_AVX512BackendRequirements.Suite, aListOnly, aTargetSuite);
  {$ENDIF}
  {$ENDIF}
  {$IFDEF UNIX}
  {$IFDEF CPUX86_64}
  HandleSuite('TTestCase_AVX2VectorAsm', TTestCase_AVX2VectorAsm.Suite, aListOnly, aTargetSuite);
  {$IFDEF SIMD_BACKEND_AVX512}
  HandleSuite('TTestCase_AVX512VectorAsm', TTestCase_AVX512VectorAsm.Suite, aListOnly, aTargetSuite);
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}
  HandleSuite('TTestCase_VectorOps', TTestCase_VectorOps.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_LargeData', TTestCase_LargeData.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_UnsignedVectorTypes', TTestCase_UnsignedVectorTypes.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_OperatorOverloads', TTestCase_OperatorOverloads.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_VectorMaskTypes', TTestCase_VectorMaskTypes.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_TypeConversion', TTestCase_TypeConversion.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_Builder', TTestCase_Builder.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_GatherScatter', TTestCase_GatherScatter.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_ShuffleSWizzle', TTestCase_ShuffleSWizzle.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_MathFunctions', TTestCase_MathFunctions.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_AdvancedAlgorithms', TTestCase_AdvancedAlgorithms.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_EdgeCases', TTestCase_EdgeCases.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_Vec512Types', TTestCase_Vec512Types.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_Memutils', TTestCase_Memutils.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_RustStyleAliases', TTestCase_RustStyleAliases.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_SaturatingArithmetic', TTestCase_SaturatingArithmetic.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_NarrowIntegerOps', TTestCase_NarrowIntegerOps.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_VecI32x8', TTestCase_VecI32x8.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_VecU32x8', TTestCase_VecU32x8.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_VecF32x8', TTestCase_VecF32x8.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_VecF64x4', TTestCase_VecF64x4.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_IEEE754_F64', TTestCase_IEEE754_F64.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_IEEE754EdgeCases', TTestCase_IEEE754EdgeCases.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_AVX2RoundTruncIEEE754', TTestCase_AVX2RoundTruncIEEE754.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_NonX86IEEE754', TTestCase_NonX86IEEE754.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_NonX86BackendParity', TTestCase_NonX86BackendParity.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_DispatchAPI', TTestCase_DispatchAPI.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_X86MaskedFmaContract', TTestCase_X86MaskedFmaContract.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_DispatchAllSlots', TTestCase_DispatchAllSlots.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_PublicAbi', TTestCase_PublicAbi.Suite, aListOnly, aTargetSuite);
  {$IFDEF SIMD_X86_AVAILABLE}
  HandleSuite('TTestCase_DirectDispatch', TTestCase_DirectDispatch.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_DirectDispatchConcurrent', TTestCase_DirectDispatchConcurrent.Suite, aListOnly, aTargetSuite);
  {$ENDIF}
  HandleSuite('TTestCase_AVX2IntrinsicsFallback', TTestCase_AVX2IntrinsicsFallback.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_SimdConcurrent', TTestCase_SimdConcurrent.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_SimdConcurrentPublicAbi', TTestCase_SimdConcurrentPublicAbi.Suite, aListOnly, aTargetSuite);
  HandleSuite('TTestCase_SimdConcurrentFramework', TTestCase_SimdConcurrentFramework.Suite, aListOnly, aTargetSuite);
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
      // Add test cases (single source of truth shared with --list-suites)
      ProcessAllSuites(False, testSuite);

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
