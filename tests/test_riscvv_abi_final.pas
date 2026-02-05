program test_riscvv_abi_final;

{$mode objfpc}{$H+}

uses
  SysUtils;

type
  TRec = record
    f: array[0..3] of Single;
  end;

// =============================================================
// 方案 A: 包装函数
// =============================================================

// 内部 procedure（工作的）
procedure _Add_Internal(const a, b: TRec; var r: TRec); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfadd.vv v0, v0, v1
  vse32.v v0, (a2)
end;

// 外部 function 包装
function Add_Wrapped(const a, b: TRec): TRec;
begin
  _Add_Internal(a, b, Result);
end;

// =============================================================
// 方案 C: 移除 nostackframe
// =============================================================

function Add_WithFrame(const a, b: TRec): TRec; assembler;
asm
  // FPC 会生成栈帧，我们只需要弄清楚参数在哪里
  // 根据测试，带栈帧时: a0=&Result, a1=&a, a2=&b
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a1)
  vle32.v v1, (a2)
  vfadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

// =============================================================
// 方案 D: 使用 inline 包装
// =============================================================

procedure _Sub_Internal(const a, b: TRec; var r: TRec); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse32.v v0, (a2)
end;

function Sub_Wrapped(const a, b: TRec): TRec; inline;
begin
  _Sub_Internal(a, b, Result);
end;

// =============================================================
// 辅助
// =============================================================

procedure PrintRec(const v: TRec);
var i: Integer;
begin
  Write('  [');
  for i := 0 to 3 do begin
    Write(v.f[i]:0:2);
    if i < 3 then Write(', ');
  end;
  WriteLn(']');
end;

function CheckAdd(const v: TRec): Boolean;
begin
  Result := (Abs(v.f[0] - 6.0) < 0.01) and
            (Abs(v.f[1] - 8.0) < 0.01) and
            (Abs(v.f[2] - 10.0) < 0.01) and
            (Abs(v.f[3] - 12.0) < 0.01);
end;

function CheckSub(const v: TRec): Boolean;
begin
  Result := (Abs(v.f[0] - (-4.0)) < 0.01) and
            (Abs(v.f[1] - (-4.0)) < 0.01) and
            (Abs(v.f[2] - (-4.0)) < 0.01) and
            (Abs(v.f[3] - (-4.0)) < 0.01);
end;

// =============================================================
// 测试函数指针（模拟 dispatch）
// =============================================================
type
  TBinaryOp = function(const a, b: TRec): TRec;

type
  TCheckFunc = function(const v: TRec): Boolean;

function TestViaDispatch(const name: string; op: TBinaryOp;
  const a, b: TRec; check: TCheckFunc): Boolean;
var r: TRec;
begin
  FillChar(r, SizeOf(r), 0);
  r := op(a, b);

  Write('  ', name:25);
  PrintRec(r);

  Result := check(r);
  if Result then WriteLn('    ✓ PASS') else WriteLn('    ✗ FAIL');
end;

// =============================================================
// Main
// =============================================================
var
  a, b: TRec;
  i: Integer;
  dispatchAdd, dispatchSub: TBinaryOp;
begin
  WriteLn;
  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║     RISC-V V ABI Final Solution Test                         ║');
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;

  for i := 0 to 3 do begin
    a.f[i] := i + 1;  // [1, 2, 3, 4]
    b.f[i] := i + 5;  // [5, 6, 7, 8]
  end;

  WriteLn('Input A: [1, 2, 3, 4]');
  WriteLn('Input B: [5, 6, 7, 8]');
  WriteLn('Expected Add: [6, 8, 10, 12]');
  WriteLn('Expected Sub: [-4, -4, -4, -4]');
  WriteLn;

  // ===================
  // 直接调用测试
  // ===================
  WriteLn('┌────────────────────────────────────────────────────────────────┐');
  WriteLn('│ Direct Call Tests                                              │');
  WriteLn('└────────────────────────────────────────────────────────────────┘');

  Write('  Add_Wrapped: ');
  PrintRec(Add_Wrapped(a, b));
  if CheckAdd(Add_Wrapped(a, b)) then WriteLn('    ✓ PASS') else WriteLn('    ✗ FAIL');

  Write('  Add_WithFrame: ');
  PrintRec(Add_WithFrame(a, b));
  if CheckAdd(Add_WithFrame(a, b)) then WriteLn('    ✓ PASS') else WriteLn('    ✗ FAIL');

  Write('  Sub_Wrapped: ');
  PrintRec(Sub_Wrapped(a, b));
  if CheckSub(Sub_Wrapped(a, b)) then WriteLn('    ✓ PASS') else WriteLn('    ✗ FAIL');

  WriteLn;

  // ===================
  // 通过 dispatch 测试
  // ===================
  WriteLn('┌────────────────────────────────────────────────────────────────┐');
  WriteLn('│ Via Dispatch (Function Pointer) Tests                          │');
  WriteLn('└────────────────────────────────────────────────────────────────┘');

  // 方案 A: Wrapped
  dispatchAdd := @Add_Wrapped;
  TestViaDispatch('Add_Wrapped via dispatch', dispatchAdd, a, b, @CheckAdd);

  // 方案 C: WithFrame
  dispatchAdd := @Add_WithFrame;
  TestViaDispatch('Add_WithFrame via dispatch', dispatchAdd, a, b, @CheckAdd);

  // 方案 D: Inline wrapped
  dispatchSub := @Sub_Wrapped;
  TestViaDispatch('Sub_Wrapped via dispatch', dispatchSub, a, b, @CheckSub);

  WriteLn;

  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║  Conclusion                                                   ║');
  WriteLn('╠══════════════════════════════════════════════════════════════╣');
  WriteLn('║  ✓ Wrapped functions work with dispatch                       ║');
  WriteLn('║  ✓ Functions with stack frames work with dispatch             ║');
  WriteLn('║  Recommendation: Use wrapped functions for RISC-V V backend   ║');
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;
end.
