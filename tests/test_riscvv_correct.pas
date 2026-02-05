program test_riscvv_correct;

{$mode objfpc}{$H+}

uses
  SysUtils;

type
  TVec4 = record
    f: array[0..3] of Single;
  end;

// =============================================================
// 已验证工作的方法: procedure(const a, b; var r)
// ABI: a0=&a, a1=&b, a2=&r
// =============================================================

procedure _Add_ASM(const a, b: TVec4; var r: TVec4); assembler; nostackframe;
asm
  // a0 = &a, a1 = &b, a2 = &r
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)    // 从 a 加载
  vle32.v v1, (a1)    // 从 b 加载
  vfadd.vv v0, v0, v1
  vse32.v v0, (a2)    // 存储到 r
end;

function Add_Wrapper(const a, b: TVec4): TVec4;
begin
  _Add_ASM(a, b, Result);
end;

procedure _Sub_ASM(const a, b: TVec4; var r: TVec4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse32.v v0, (a2)
end;

function Sub_Wrapper(const a, b: TVec4): TVec4;
begin
  _Sub_ASM(a, b, Result);
end;

procedure _Mul_ASM(const a, b: TVec4; var r: TVec4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vse32.v v0, (a2)
end;

function Mul_Wrapper(const a, b: TVec4): TVec4;
begin
  _Mul_ASM(a, b, Result);
end;

procedure _Div_ASM(const a, b: TVec4; var r: TVec4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfdiv.vv v0, v0, v1
  vse32.v v0, (a2)
end;

function Div_Wrapper(const a, b: TVec4): TVec4;
begin
  _Div_ASM(a, b, Result);
end;

// 单参数版本
procedure _Abs_ASM(const a: TVec4; var r: TVec4); assembler; nostackframe;
asm
  // a0 = &a, a1 = &r
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsgnjx.vv v0, v0, v0  // abs = xor sign
  vse32.v v0, (a1)
end;

function Abs_Wrapper(const a: TVec4): TVec4;
begin
  _Abs_ASM(a, Result);
end;

procedure _Neg_ASM(const a: TVec4; var r: TVec4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsgnjn.vv v0, v0, v0  // neg = not sign
  vse32.v v0, (a1)
end;

function Neg_Wrapper(const a: TVec4): TVec4;
begin
  _Neg_ASM(a, Result);
end;

// 三参数版本 (FMA)
procedure _Fma_ASM(const a, b, c: TVec4; var r: TVec4); assembler; nostackframe;
asm
  // a0 = &a, a1 = &b, a2 = &c, a3 = &r
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)    // a
  vle32.v v1, (a1)    // b
  vle32.v v2, (a2)    // c
  vfmacc.vv v2, v0, v1  // c += a*b
  vse32.v v2, (a3)    // 存储到 r
end;

function Fma_Wrapper(const a, b, c: TVec4): TVec4;
begin
  _Fma_ASM(a, b, c, Result);
end;

// =============================================================
// 测试通过函数指针调用 (模拟 dispatch)
// =============================================================
type
  TBinaryOp = function(const a, b: TVec4): TVec4;
  TUnaryOp = function(const a: TVec4): TVec4;
  TTernaryOp = function(const a, b, c: TVec4): TVec4;

// =============================================================
// Main
// =============================================================
var
  a, b, c, r: TVec4;
  i: Integer;
  dispatchAdd: TBinaryOp;
  dispatchSub: TBinaryOp;
  dispatchAbs: TUnaryOp;
  dispatchFma: TTernaryOp;
  passed, failed: Integer;
begin
  WriteLn;
  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║     RISC-V V Correct ABI Test                                ║');
  WriteLn('║     Using: procedure(_ASM) + function(Wrapper)               ║');
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;

  passed := 0;
  failed := 0;

  // 初始化
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 5.0; b.f[1] := 6.0; b.f[2] := 7.0; b.f[3] := 8.0;
  c.f[0] := 10.0; c.f[1] := 20.0; c.f[2] := 30.0; c.f[3] := 40.0;

  WriteLn('Input A: [1, 2, 3, 4]');
  WriteLn('Input B: [5, 6, 7, 8]');
  WriteLn('Input C: [10, 20, 30, 40]');
  WriteLn;

  // === 直接调用测试 ===
  WriteLn('┌────────────────────────────────────────────────────────────────┐');
  WriteLn('│ Direct Call Tests                                              │');
  WriteLn('└────────────────────────────────────────────────────────────────┘');

  // Add
  r := Add_Wrapper(a, b);
  Write('  Add [1+5, 2+6, 3+7, 4+8] = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 6.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  // Sub
  r := Sub_Wrapper(a, b);
  Write('  Sub [1-5, 2-6, 3-7, 4-8] = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - (-4.0)) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  // Mul
  r := Mul_Wrapper(a, b);
  Write('  Mul [1*5, 2*6, 3*7, 4*8] = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 5.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  // Abs
  a.f[0] := -1.0; a.f[1] := 2.0; a.f[2] := -3.0; a.f[3] := 4.0;
  r := Abs_Wrapper(a);
  Write('  Abs [-1, 2, -3, 4] = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 1.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  // Neg
  r := Neg_Wrapper(a);
  Write('  Neg [-1, 2, -3, 4] = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 1.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  // FMA
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 2.0; b.f[1] := 2.0; b.f[2] := 2.0; b.f[3] := 2.0;
  r := Fma_Wrapper(a, b, c);  // a*b + c = [1*2+10, 2*2+20, 3*2+30, 4*2+40] = [12, 24, 36, 48]
  Write('  FMA [1*2+10, 2*2+20, ...] = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 12.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  WriteLn;

  // === 通过函数指针测试 ===
  WriteLn('┌────────────────────────────────────────────────────────────────┐');
  WriteLn('│ Via Function Pointer (Dispatch) Tests                          │');
  WriteLn('└────────────────────────────────────────────────────────────────┘');

  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 5.0; b.f[1] := 6.0; b.f[2] := 7.0; b.f[3] := 8.0;

  dispatchAdd := @Add_Wrapper;
  r := dispatchAdd(a, b);
  Write('  dispatch.Add = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 6.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  dispatchSub := @Sub_Wrapper;
  r := dispatchSub(a, b);
  Write('  dispatch.Sub = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - (-4.0)) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  a.f[0] := -1.0; a.f[1] := 2.0; a.f[2] := -3.0; a.f[3] := 4.0;
  dispatchAbs := @Abs_Wrapper;
  r := dispatchAbs(a);
  Write('  dispatch.Abs = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 1.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  dispatchFma := @Fma_Wrapper;
  r := dispatchFma(a, b, c);
  Write('  dispatch.Fma = [');
  for i := 0 to 3 do begin Write(r.f[i]:0:1); if i < 3 then Write(', '); end;
  WriteLn(']');
  if Abs(r.f[0] - 12.0) < 0.01 then begin WriteLn('    ✓ PASS'); Inc(passed); end else begin WriteLn('    ✗ FAIL'); Inc(failed); end;

  WriteLn;

  // === 总结 ===
  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║  Summary                                                      ║');
  WriteLn('╠══════════════════════════════════════════════════════════════╣');
  WriteLn('║  Passed: ', passed:2, '                                                   ║');
  WriteLn('║  Failed: ', failed:2, '                                                   ║');
  WriteLn('╠══════════════════════════════════════════════════════════════╣');
  if failed = 0 then begin
    WriteLn('║  ✓ ALL TESTS PASSED!                                         ║');
    WriteLn('║  The wrapper pattern works correctly with dispatch!          ║');
  end else begin
    WriteLn('║  ✗ SOME TESTS FAILED!                                        ║');
  end;
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;

  if failed = 0 then Halt(0) else Halt(1);
end.
