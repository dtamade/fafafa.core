{
  Safety tests for TFixedPool pointer validation.
}
unit test_fixedpool_guard;

{$mode objfpc}{$H+}

interface

procedure RunAllTests;

implementation

uses
  SysUtils,
  fafafa.core.mem.pool.fixed;

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


procedure Test_InvalidPointer_Raises;
var
  PoolA, PoolB: TFixedPool;
  P: Pointer;
  procedure ReleaseFromOtherPool;
  begin
    PoolB.ReleasePtr(P);
  end;
begin
  WriteLn('=== Test_InvalidPointer_Raises ===');

  PoolA := TFixedPool.Create(64, 4);
  PoolB := TFixedPool.Create(64, 4);
  try
    P := PoolA.Alloc;
    Check(P <> nil, 'Alloc succeeds');
    try
      ReleaseFromOtherPool;
      Check(False, 'ReleasePtr from other pool raises (expected exception)');
    except
      on E: Exception do
        Check(E is EMemFixedPoolInvalidPointer, 'ReleasePtr from other pool raises (got ' + E.ClassName + ')');
    end;
  finally
    PoolA.Free;
    PoolB.Free;
  end;
end;

procedure Test_DoubleFree_Raises;
var
  Pool: TFixedPool;
  P: Pointer;
  procedure DoubleFree;
  begin
    Pool.ReleasePtr(P);
  end;
begin
  WriteLn('=== Test_DoubleFree_Raises ===');

  Pool := TFixedPool.Create(64, 2);
  try
    P := Pool.Alloc;
    Check(P <> nil, 'Alloc succeeds');
    Pool.ReleasePtr(P);
    Check(True, 'First release ok');
    try
      DoubleFree;
      Check(False, 'Second release raises double free (expected exception)');
    except
      on E: Exception do
        Check(E is EMemFixedPoolDoubleFree, 'Second release raises double free (got ' + E.ClassName + ')');
    end;
  finally
    Pool.Free;
  end;
end;

procedure Test_NonPoolPointer_Raises;
var
  Pool: TFixedPool;
  ForeignPtr: Pointer;
  procedure ReleaseForeign;
  begin
    Pool.ReleasePtr(ForeignPtr);
  end;
begin
  WriteLn('=== Test_NonPoolPointer_Raises ===');

  Pool := TFixedPool.Create(64, 2);
  GetMem(ForeignPtr, 64);
  try
    try
      ReleaseForeign;
      Check(False, 'Releasing foreign pointer raises (expected exception)');
    except
      on E: Exception do
        Check(E is EMemFixedPoolInvalidPointer, 'Releasing foreign pointer raises (got ' + E.ClassName + ')');
    end;
  finally
    FreeMem(ForeignPtr);
    Pool.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  FixedPool Guard Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_InvalidPointer_Raises;
  Test_DoubleFree_Raises;
  Test_NonPoolPointer_Raises;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
