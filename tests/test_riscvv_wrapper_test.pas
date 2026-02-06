program test_riscvv_wrapper_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.math,
  fafafa.core.simd.base,
  test_riscvv_wrapper_unit;

type
  TBinaryOp = function(const a, b: TVecF32x4): TVecF32x4;
  TUnaryOp = function(const a: TVecF32x4): TVecF32x4;
  TTernaryOp = function(const a, b, c: TVecF32x4): TVecF32x4;

var
  a, b, c, r: TVecF32x4;
  i: Integer;
  passed, failed: Integer;
  dispAdd: TBinaryOp;
  dispAbs: TUnaryOp;
  dispFma: TTernaryOp;
begin
  WriteLn;
  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║     RISC-V V Wrapper Unit Test                               ║');
  WriteLn('║     Testing correct ABI with dispatch integration            ║');
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;

  passed := 0;
  failed := 0;

  // 初始化
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 5.0; b.f[1] := 6.0; b.f[2] := 7.0; b.f[3] := 8.0;
  c.f[0] := 10.0; c.f[1] := 20.0; c.f[2] := 30.0; c.f[3] := 40.0;

  // === 直接调用 ===
  WriteLn('Direct Calls:');

  r := RVVAddF32x4(a, b);
  Write('  Add: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 6.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  r := RVVSubF32x4(a, b);
  Write('  Sub: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - (-4.0)) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  r := RVVMulF32x4(a, b);
  Write('  Mul: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 5.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  a.f[0] := -1.0; a.f[1] := 2.0; a.f[2] := -3.0; a.f[3] := 4.0;
  r := RVVAbsF32x4(a);
  Write('  Abs: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 1.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  r := RVVNegF32x4(a);
  Write('  Neg: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 1.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 2.0; b.f[1] := 2.0; b.f[2] := 2.0; b.f[3] := 2.0;
  r := RVVFmaF32x4(a, b, c);
  Write('  FMA: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 12.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  WriteLn;

  // === 通过函数指针 ===
  WriteLn('Via Function Pointers (Dispatch):');

  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 5.0; b.f[1] := 6.0; b.f[2] := 7.0; b.f[3] := 8.0;

  dispAdd := @RVVAddF32x4;
  r := dispAdd(a, b);
  Write('  dispatch.Add: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 6.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  a.f[0] := -1.0; a.f[1] := 2.0; a.f[2] := -3.0; a.f[3] := 4.0;
  dispAbs := @RVVAbsF32x4;
  r := dispAbs(a);
  Write('  dispatch.Abs: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 1.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 2.0; b.f[1] := 2.0; b.f[2] := 2.0; b.f[3] := 2.0;
  dispFma := @RVVFmaF32x4;
  r := dispFma(a, b, c);
  Write('  dispatch.FMA: [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 12.0) < 0.01 then begin Inc(passed); WriteLn('    ✓'); end else begin Inc(failed); WriteLn('    ✗'); end;

  WriteLn;

  // === 总结 ===
  WriteLn('═══════════════════════════════════════════════════════════════');
  WriteLn('Passed: ', passed, '  Failed: ', failed);
  if failed = 0 then
    WriteLn('✓ ALL TESTS PASSED - Wrapper pattern works!')
  else
    WriteLn('✗ SOME TESTS FAILED');
  WriteLn('═══════════════════════════════════════════════════════════════');

  if failed = 0 then Halt(0) else Halt(1);
end.
