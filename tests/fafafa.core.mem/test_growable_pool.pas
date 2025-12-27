{
  Test suite for fafafa.core.mem.pool.fixed.growable

  Tests:
  - Basic Acquire/Release
  - Auto growth behavior
  - Invalid pointer detection
  - Reset functionality
  - ShrinkTo capacity reduction
  - Growth kinds (Linear/Geometric)
}
unit test_growable_pool;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.mem.pool.fixed.growable;

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

procedure Test_BasicAcquireRelease;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  P1, P2, P3: Pointer;
  Ok: Boolean;
begin
  WriteLn('=== Test_BasicAcquireRelease ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 64;
  Config.InitialCapacity := 10;
  Config.GrowthKind := gkLinear;
  Config.GrowthStep := 10;

  Pool := TGrowingFixedPool.Create(Config);
  try
    Check(Pool.TotalCapacity = 10, 'Initial capacity = 10');
    Check(Pool.AllocatedCount = 0, 'Initial allocated = 0');
    Check(Pool.FreeCount = 10, 'Initial free = 10');

    Ok := Pool.Acquire(P1);
    Check(Ok and (P1 <> nil), 'Acquire P1 succeeds');
    Check(Pool.AllocatedCount = 1, 'Allocated = 1 after P1');

    Ok := Pool.Acquire(P2);
    Check(Ok and (P2 <> nil), 'Acquire P2 succeeds');
    Check(P1 <> P2, 'P1 <> P2');

    Ok := Pool.Acquire(P3);
    Check(Ok and (P3 <> nil), 'Acquire P3 succeeds');

    Pool.Release(P2);
    Check(Pool.AllocatedCount = 2, 'Allocated = 2 after release P2');

    Pool.Release(P1);
    Pool.Release(P3);
    Check(Pool.AllocatedCount = 0, 'Allocated = 0 after release all');
  finally
    Pool.Free;
  end;
end;

procedure Test_AutoGrowth;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  Ptrs: array[0..99] of Pointer;
  I: Integer;
  Ok: Boolean;
begin
  WriteLn('=== Test_AutoGrowth ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 32;
  Config.InitialCapacity := 5;
  Config.GrowthKind := gkLinear;
  Config.GrowthStep := 5;

  Pool := TGrowingFixedPool.Create(Config);
  try
    Check(Pool.TotalCapacity = 5, 'Initial capacity = 5');

    // Allocate more than initial capacity
    for I := 0 to 19 do
    begin
      Ok := Pool.Acquire(Ptrs[I]);
      if not Ok then
        Break;
    end;

    Check(Pool.AllocatedCount = 20, 'Allocated 20 blocks');
    Check(Pool.TotalCapacity >= 20, 'Capacity grew to >= 20');
    Check(Pool.ArenaCount > 1, 'Multiple arenas created');

    // Release all
    for I := 0 to 19 do
      Pool.Release(Ptrs[I]);

    Check(Pool.AllocatedCount = 0, 'All released');
  finally
    Pool.Free;
  end;
end;

procedure Test_InvalidPointerDetection;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  P: Pointer;
  ExceptionRaised: Boolean;
begin
  WriteLn('=== Test_InvalidPointerDetection ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 64;
  Config.InitialCapacity := 10;

  Pool := TGrowingFixedPool.Create(Config);
  try
    // Test nil pointer (should be safe)
    ExceptionRaised := False;
    try
      Pool.Release(nil);
    except
      ExceptionRaised := True;
    end;
    Check(not ExceptionRaised, 'Release(nil) is safe');

    // Test invalid pointer
    ExceptionRaised := False;
    try
      P := Pointer($DEADBEEF);
      Pool.Release(P);
    except
      on E: EGrowingFixedPoolInvalidPointer do
        ExceptionRaised := True;
    end;
    Check(ExceptionRaised, 'Invalid pointer raises exception');

    // Test misaligned pointer
    Pool.Acquire(P);
    ExceptionRaised := False;
    try
      Pool.Release(Pointer(PtrUInt(P) + 1)); // Misaligned
    except
      on E: EGrowingFixedPoolInvalidPointer do
        ExceptionRaised := True;
    end;
    Check(ExceptionRaised, 'Misaligned pointer raises exception');

    Pool.Release(P);
  finally
    Pool.Free;
  end;
end;

procedure Test_Reset;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  Ptrs: array[0..9] of Pointer;
  I: Integer;
begin
  WriteLn('=== Test_Reset ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 64;
  Config.InitialCapacity := 10;

  Pool := TGrowingFixedPool.Create(Config);
  try
    // Allocate some blocks
    for I := 0 to 4 do
      Pool.Acquire(Ptrs[I]);

    Check(Pool.AllocatedCount = 5, 'Allocated 5 blocks');

    Pool.Reset;

    Check(Pool.AllocatedCount = 0, 'Allocated = 0 after reset');
    Check(Pool.FreeCount = Pool.TotalCapacity, 'All blocks free after reset');

    // Can allocate again
    for I := 0 to 9 do
      Pool.Acquire(Ptrs[I]);

    Check(Pool.AllocatedCount = 10, 'Can allocate 10 after reset');
  finally
    Pool.Free;
  end;
end;

procedure Test_ShrinkTo;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  Ptrs: array[0..49] of Pointer;
  I: Integer;
  CapBefore, CapAfter: SizeUInt;
  Freed: SizeUInt;
begin
  WriteLn('=== Test_ShrinkTo ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 64;
  Config.InitialCapacity := 10;
  Config.GrowthKind := gkLinear;
  Config.GrowthStep := 10;

  Pool := TGrowingFixedPool.Create(Config);
  try
    // Grow pool
    for I := 0 to 49 do
      Pool.Acquire(Ptrs[I]);

    Check(Pool.TotalCapacity >= 50, 'Capacity >= 50 after allocation');

    // Release all
    for I := 0 to 49 do
      Pool.Release(Ptrs[I]);

    CapBefore := Pool.TotalCapacity;
    Freed := Pool.ShrinkTo(20);

    CapAfter := Pool.TotalCapacity;
    Check(CapAfter <= CapBefore, 'Capacity reduced after shrink');
    Check(CapAfter >= 20, 'Capacity >= min requested');
    Check(Freed > 0, 'Some blocks freed');
  finally
    Pool.Free;
  end;
end;

procedure Test_MaxCapacity;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  Ptrs: array[0..99] of Pointer;
  I: Integer;
  Ok: Boolean;
  AllocCount: Integer;
begin
  WriteLn('=== Test_MaxCapacity ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 64;
  Config.InitialCapacity := 10;
  Config.MaxCapacity := 25;
  Config.GrowthKind := gkLinear;
  Config.GrowthStep := 10;

  Pool := TGrowingFixedPool.Create(Config);
  try
    AllocCount := 0;
    for I := 0 to 99 do
    begin
      Ok := Pool.Acquire(Ptrs[I]);
      if Ok then
        Inc(AllocCount)
      else
        Break;
    end;

    Check(Pool.TotalCapacity <= 25, 'Capacity respects MaxCapacity');
    Check(AllocCount = 25, 'Allocated exactly MaxCapacity blocks');
  finally
    Pool.Free;
  end;
end;

procedure Test_GeometricGrowth;
var
  Config: TGrowingFixedPoolConfig;
  Pool: TGrowingFixedPool;
  P: Pointer;
  I: Integer;
  Cap1, Cap2: SizeUInt;
begin
  WriteLn('=== Test_GeometricGrowth ===');

  Config := Default(TGrowingFixedPoolConfig);
  Config.BlockSize := 64;
  Config.InitialCapacity := 8;
  Config.GrowthKind := gkGeometric;
  Config.GrowthFactor := 2.0;

  Pool := TGrowingFixedPool.Create(Config);
  try
    Cap1 := Pool.TotalCapacity;
    Check(Cap1 = 8, 'Initial capacity = 8');

    // Exhaust initial capacity
    for I := 0 to 7 do
      Pool.Acquire(P);

    // Force growth
    Pool.Acquire(P);
    Cap2 := Pool.TotalCapacity;

    Check(Cap2 > Cap1, 'Capacity grew after exhaustion');
    // Geometric growth should roughly double
    Check(Cap2 >= Cap1 * 2, 'Geometric growth doubled capacity');
  finally
    Pool.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  TGrowingFixedPool Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_BasicAcquireRelease;
  Test_AutoGrowth;
  Test_InvalidPointerDetection;
  Test_Reset;
  Test_ShrinkTo;
  Test_MaxCapacity;
  Test_GeometricGrowth;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
