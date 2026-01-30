{
  Test suite for fafafa.core.mem.stackPool (Scoped Stack Pool)

  Tests:
  - Basic allocation
  - Scope management (RAII)
  - State stack (PushState/PopState)
  - Statistics tracking
  - Auto growth
  - Aligned allocation
  - Zeroed allocation

  Note: Tests use deprecated type aliases (TEnhancedStackPool, TStackScope, etc.)
        for backward compatibility. New code should use TScopedStackPool,
        TStackPoolScope, etc.
}
unit test_enhanced_stackpool;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.mem.stackPool;  // Changed from enhancedStackPool

procedure RunAllTests;

implementation

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  Inc(TestCount);
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('  [PASS] ', TestName);
  end
  else
    WriteLn('  [FAIL] ', TestName);
end;

procedure Test_BasicAllocation;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  P1, P2: Pointer;
begin
  WriteLn('=== Test_BasicAllocation ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    P1 := Pool.Alloc(100);
    Check(P1 <> nil, 'Alloc 100 bytes');

    P2 := Pool.Alloc(200);
    Check(P2 <> nil, 'Alloc 200 bytes');
    Check(P2 <> P1, 'Different pointers');

    Check(Pool.UsedSize > 0, 'UsedSize > 0');
  finally
    Pool.Free;
  end;
end;

procedure Test_ScopeManagement;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Scope: TStackScope;
  UsedBefore, UsedAfter: SizeUInt;
  P: Pointer;
begin
  WriteLn('=== Test_ScopeManagement ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    UsedBefore := Pool.UsedSize;

    Scope := Pool.CreateScope;
    try
      P := Scope.Alloc(512);
      Check(P <> nil, 'Scope Alloc succeeds');
      Check(Pool.UsedSize > UsedBefore, 'UsedSize increased in scope');
    finally
      Scope.Free;
    end;

    UsedAfter := Pool.UsedSize;
    Check(UsedAfter = UsedBefore, 'UsedSize restored after scope');
  finally
    Pool.Free;
  end;
end;

procedure Test_NestedScopes;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Scope1, Scope2: TStackScope;
  Used0, Used1, Used2: SizeUInt;
begin
  WriteLn('=== Test_NestedScopes ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(8192, Policy);
  try
    Used0 := Pool.UsedSize;

    Scope1 := Pool.CreateScope;
    Scope1.Alloc(256);
    Used1 := Pool.UsedSize;
    Check(Used1 > Used0, 'Scope1 increased usage');

    Scope2 := Pool.CreateScope;
    Scope2.Alloc(256);
    Used2 := Pool.UsedSize;
    Check(Used2 > Used1, 'Scope2 increased usage');

    Scope2.Free;
    Check(Pool.UsedSize <= Used1, 'Scope2 released usage');

    Scope1.Free;
    Check(Pool.UsedSize = Used0, 'Scope1 released usage');
  finally
    Pool.Free;
  end;
end;

procedure Test_StateStack;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Used0, Used1: SizeUInt;
  Ok: Boolean;
begin
  WriteLn('=== Test_StateStack ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    Used0 := Pool.UsedSize;

    Ok := Pool.PushState;
    Check(Ok, 'PushState succeeds');
    Check(Pool.GetStateStackDepth = 1, 'State depth = 1');

    Pool.Alloc(512);
    Used1 := Pool.UsedSize;
    Check(Used1 > Used0, 'Allocation increased usage');

    Ok := Pool.PopState;
    Check(Ok, 'PopState succeeds');
    Check(Pool.UsedSize = Used0, 'PopState restored usage');
    Check(Pool.GetStateStackDepth = 0, 'State depth = 0');
  finally
    Pool.Free;
  end;
end;

procedure Test_Statistics;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Stats: TStackPoolStatistics;
begin
  WriteLn('=== Test_Statistics ===');

  Policy := CreateDefaultStackPolicy;
  Policy.EnableStatistics := True;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    Pool.Alloc(100);
    Pool.Alloc(200);
    Pool.Alloc(300);

    Stats := Pool.GetStatistics;
    Check(Stats.TotalAllocations = 3, 'TotalAllocations = 3');
    Check(Stats.TotalBytes >= 600, 'TotalBytes >= 600');
    Check(Stats.CurrentUsage > 0, 'CurrentUsage > 0');
    Check(Stats.PeakUsage > 0, 'PeakUsage > 0');
  finally
    Pool.Free;
  end;
end;

procedure Test_AllocZeroed;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  P: PByte;
  I: Integer;
  AllZero: Boolean;
begin
  WriteLn('=== Test_AllocZeroed ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    P := Pool.AllocZeroed(256);
    Check(P <> nil, 'AllocZeroed succeeds');

    AllZero := True;
    for I := 0 to 255 do
    begin
      if P[I] <> 0 then
      begin
        AllZero := False;
        Break;
      end;
    end;
    Check(AllZero, 'Memory is zeroed');
  finally
    Pool.Free;
  end;
end;

procedure Test_AllocAligned;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  P: Pointer;
begin
  WriteLn('=== Test_AllocAligned ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    P := Pool.AllocAligned(100, 16);
    Check(P <> nil, 'AllocAligned 16 succeeds');
    Check((PtrUInt(P) mod 16) = 0, 'Aligned to 16 bytes');

    P := Pool.AllocAligned(100, 32);
    Check(P <> nil, 'AllocAligned 32 succeeds');
    Check((PtrUInt(P) mod 32) = 0, 'Aligned to 32 bytes');

    P := Pool.AllocAligned(100, 64);
    Check(P <> nil, 'AllocAligned 64 succeeds');
    Check((PtrUInt(P) mod 64) = 0, 'Aligned to 64 bytes');
  finally
    Pool.Free;
  end;
end;

procedure Test_AllocString;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  S: PChar;
begin
  WriteLn('=== Test_AllocString ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    S := Pool.AllocString(100);
    Check(S <> nil, 'AllocString succeeds');
    Check(S[0] = #0, 'String is null-terminated');

    StrCopy(S, 'Hello, World!');
    Check(StrLen(S) = 13, 'Can use as string');
  finally
    Pool.Free;
  end;
end;

procedure Test_AllocArray;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Arr: PInteger;
  I: Integer;
begin
  WriteLn('=== Test_AllocArray ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    Arr := Pool.AllocArray(SizeOf(Integer), 10);
    Check(Arr <> nil, 'AllocArray succeeds');

    // Array should be zeroed
    for I := 0 to 9 do
      Check(Arr[I] = 0, Format('Arr[%d] = 0', [I]));

    // Can write and read
    for I := 0 to 9 do
      Arr[I] := I * 10;

    for I := 0 to 9 do
      Check(Arr[I] = I * 10, Format('Arr[%d] = %d', [I, I * 10]));
  finally
    Pool.Free;
  end;
end;

procedure Test_HighPerformancePolicy;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Stats: TStackPoolStatistics;
begin
  WriteLn('=== Test_HighPerformancePolicy ===');

  Policy := CreateHighPerformanceStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    Pool.Alloc(100);
    Pool.Alloc(200);

    Stats := Pool.GetStatistics;
    // Stats should be zero since EnableStatistics = False
    Check(Stats.TotalAllocations = 0, 'No stats in high-perf mode');
  finally
    Pool.Free;
  end;
end;

procedure Test_AutoStackScope;
var
  Policy: TStackPoolPolicy;
  Pool: TEnhancedStackPool;
  Scope: TAutoStackScope;
  UsedBefore, UsedDuring, UsedAfter: SizeUInt;
  P: Pointer;
begin
  WriteLn('=== Test_AutoStackScope ===');

  Policy := CreateDefaultStackPolicy;
  Pool := TEnhancedStackPool.Create(4096, Policy);
  try
    UsedBefore := Pool.UsedSize;

    Scope := TAutoStackScope.Initialize(Pool);
    P := Scope.Alloc(256);
    Check(P <> nil, 'AutoScope Alloc succeeds');
    Check(Scope.Active, 'Scope is active');

    UsedDuring := Pool.UsedSize;
    Check(UsedDuring > UsedBefore, 'Memory used in scope');

    Scope.Finalize;
    UsedAfter := Pool.UsedSize;
    Check(UsedAfter = UsedBefore, 'Memory freed after finalize');
    Check(not Scope.Active, 'Scope is inactive');
  finally
    Pool.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TEnhancedStackPool Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_BasicAllocation;
  Test_ScopeManagement;
  Test_NestedScopes;
  Test_StateStack;
  Test_Statistics;
  Test_AllocZeroed;
  Test_AllocAligned;
  Test_AllocString;
  Test_AllocArray;
  Test_HighPerformancePolicy;
  Test_AutoStackScope;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
