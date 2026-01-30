{
  Tests for TScopedStackPool growth policy.

  Goal: default policy should not auto-grow; allocations beyond capacity
  must fail without invalidating existing pointers.
}
unit test_stackpool_policy;

{$mode objfpc}{$H+}

interface

procedure RunAllTests;

implementation

uses
  SysUtils,
  fafafa.core.mem.stackPool;

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

procedure Test_DefaultPolicy_DoesNotAutoGrow;
var
  Policy: TStackPoolPolicy;
  Pool: TScopedStackPool;
  P1, P2: Pointer;
  I: Integer;
begin
  WriteLn('=== Test_DefaultPolicy_DoesNotAutoGrow ===');

  Policy := TStackPoolPolicy.Default;
  Pool := TScopedStackPool.Create(1024, Policy);
  try
    // fill pattern in first allocation
    P1 := Pool.Alloc(900, 8);
    Check(P1 <> nil, 'First alloc within capacity succeeds');
    for I := 0 to 899 do
      PByte(P1)[I] := I mod 256;

    // this allocation would exceed capacity; should fail when autogrow is off
    P2 := Pool.Alloc(200, 8);
    Check(P2 = nil, 'Allocation beyond capacity returns nil');

    // ensure first allocation remains valid and unchanged
    for I := 0 to 899 do
      Check(PByte(P1)[I] = (I mod 256), Format('Byte %d intact after failed grow', [I]));

    Check(Pool.UsedSize = 900, 'UsedSize unchanged after failed grow');
  finally
    Pool.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  StackPool Policy Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_DefaultPolicy_DoesNotAutoGrow;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
