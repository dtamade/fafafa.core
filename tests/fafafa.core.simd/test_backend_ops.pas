program test_backend_ops;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.math,
  fafafa.core.simd.base,
  fafafa.core.simd.backend.iface,
  fafafa.core.simd.backend.adapter,
  fafafa.core.simd.dispatch;

var
  ops: TSimdBackendOps;
  a, b, result_: TVecF32x4;
  passCount, failCount: Integer;

procedure Check(const testName: string; passed: Boolean);
begin
  if passed then
  begin
    WriteLn('[PASS] ', testName);
    Inc(passCount);
  end
  else
  begin
    WriteLn('[FAIL] ', testName);
    Inc(failCount);
  end;
end;

begin
  passCount := 0;
  failCount := 0;

  WriteLn('=== TSimdBackendOps Interface Test ===');
  WriteLn;

  // Test 1: FillScalarOps populates backend info
  FillScalarOps(ops);
  Check('FillScalarOps sets Backend = sbScalar', ops.Backend = sbScalar);
  Check('FillScalarOps sets Name = Scalar', ops.BackendInfo.Name = 'Scalar');
  Check('FillScalarOps sets Available = True', ops.BackendInfo.Available);

  // Test 2: ArithmeticF32x4 functions are assigned
  Check('ArithmeticF32x4.Add is assigned', Assigned(ops.ArithmeticF32x4.Add));
  Check('ArithmeticF32x4.Sub is assigned', Assigned(ops.ArithmeticF32x4.Sub));
  Check('ArithmeticF32x4.Mul is assigned', Assigned(ops.ArithmeticF32x4.Mul));
  Check('ArithmeticF32x4.OpDiv is assigned', Assigned(ops.ArithmeticF32x4.OpDiv));

  // Test 3: Functions produce correct results
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 0.5; b.f[1] := 1.0; b.f[2] := 1.5; b.f[3] := 2.0;

  result_ := ops.ArithmeticF32x4.Add(a, b);
  Check('Add: 1.0 + 0.5 = 1.5', Abs(result_.f[0] - 1.5) < 0.0001);
  Check('Add: 2.0 + 1.0 = 3.0', Abs(result_.f[1] - 3.0) < 0.0001);

  result_ := ops.ArithmeticF32x4.Mul(a, b);
  Check('Mul: 2.0 * 1.0 = 2.0', Abs(result_.f[1] - 2.0) < 0.0001);
  Check('Mul: 3.0 * 1.5 = 4.5', Abs(result_.f[2] - 4.5) < 0.0001);

  // Test 4: Facade operations are assigned
  Check('Facade.MemEqual is assigned', Assigned(ops.Facade.MemEqual));
  Check('Facade.SumBytes is assigned', Assigned(ops.Facade.SumBytes));
  Check('Facade.CountByte is assigned', Assigned(ops.Facade.CountByte));

  // Test 5: RegisterBackendOps and GetBackendOps round-trip
  RegisterBackendOps(sbScalar, ops);
  Check('RegisterBackendOps succeeds', IsBackendOpsRegistered(sbScalar));

  WriteLn;
  WriteLn('=== Summary ===');
  WriteLn('Passed: ', passCount);
  WriteLn('Failed: ', failCount);

  if failCount = 0 then
  begin
    WriteLn('All tests PASSED!');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('Some tests FAILED!');
    ExitCode := 1;
  end;
end.
