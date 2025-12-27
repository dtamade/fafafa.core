program test_stackpool_compile;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.mem.stackPool;

var
  Pool: TScopedStackPool;
  Scope: TStackPoolScope;
  AutoScope: TAutoStackPoolScope;
  Policy: TStackPoolPolicy;
  Stats: TStackPoolStatistics;
  P: Pointer;
begin
  WriteLn('Testing TScopedStackPool (formerly TEnhancedStackPool)...');

  // Test Policy class methods
  Policy := TStackPoolPolicy.Default;
  WriteLn('  Default policy created: OK');

  Policy := TStackPoolPolicy.HighPerformance;
  WriteLn('  HighPerformance policy created: OK');

  Policy := TStackPoolPolicy.Debug;
  WriteLn('  Debug policy created: OK');

  // Test basic pool creation
  Policy := TStackPoolPolicy.Default;
  Pool := TScopedStackPool.Create(4096, Policy);
  try
    WriteLn('  TScopedStackPool created: OK');

    // Test allocation
    P := Pool.Alloc(100);
    if P <> nil then
      WriteLn('  Alloc(100) succeeded: OK')
    else
      WriteLn('  Alloc(100) failed: FAIL');

    // Test scope
    Scope := Pool.CreateScope;
    try
      P := Scope.Alloc(256);
      if P <> nil then
        WriteLn('  Scope.Alloc(256) succeeded: OK')
      else
        WriteLn('  Scope.Alloc(256) failed: FAIL');
    finally
      Scope.Free;
    end;
    WriteLn('  Scope freed: OK');

    // Test statistics
    Stats := Pool.GetStatistics;
    WriteLn('  Statistics: TotalAllocations=', Stats.TotalAllocations);

    // Test AllocZeroed
    P := Pool.AllocZeroed(128);
    if P <> nil then
      WriteLn('  AllocZeroed(128) succeeded: OK')
    else
      WriteLn('  AllocZeroed(128) failed: FAIL');

    // Test AllocString
    if Pool.AllocString(50) <> nil then
      WriteLn('  AllocString(50) succeeded: OK')
    else
      WriteLn('  AllocString(50) failed: FAIL');

    // Test PushState/PopState
    if Pool.PushState then
      WriteLn('  PushState succeeded: OK')
    else
      WriteLn('  PushState failed: FAIL');

    if Pool.PopState then
      WriteLn('  PopState succeeded: OK')
    else
      WriteLn('  PopState failed: FAIL');

    // Test auto scope
    AutoScope := TAutoStackPoolScope.Initialize(Pool);
    P := AutoScope.Alloc(64);
    if P <> nil then
      WriteLn('  AutoScope.Alloc(64) succeeded: OK')
    else
      WriteLn('  AutoScope.Alloc(64) failed: FAIL');
    AutoScope.Finalize;
    WriteLn('  AutoScope finalized: OK');

  finally
    Pool.Free;
  end;
  WriteLn('  TScopedStackPool freed: OK');

  // Test deprecated aliases (backward compatibility)
  WriteLn('');
  WriteLn('Testing deprecated aliases...');
  {$WARN 6058 OFF} // Suppress deprecated warning
  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(2048, Policy);
  try
    WriteLn('  TEnhancedStackPool (deprecated alias) created: OK');
  finally
    Pool.Free;
  end;
  {$WARN 6058 ON}

  WriteLn('');
  WriteLn('All compile tests passed!');
end.
