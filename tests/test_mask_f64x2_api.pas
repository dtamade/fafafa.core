program test_mask_f64x2_api;

{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.math,
  fafafa.core.simd,
  fafafa.core.simd.dispatch;

var
  AllPassed: Boolean = True;
  TestCount: Integer = 0;

procedure Check(condition: Boolean; const testName: string);
begin
  Inc(TestCount);
  if condition then
    WriteLn('  [PASS] ', testName)
  else
  begin
    WriteLn('  [FAIL] ', testName);
    AllPassed := False;
  end;
end;

procedure TestMask2Operations;
var
  m: TMask2;
begin
  WriteLn('=== TMask2 Operations ===');

  // All bits set
  m := $03;
  Check(Mask2All(m) = True, 'Mask2All($03) = True');
  Check(Mask2Any(m) = True, 'Mask2Any($03) = True');
  Check(Mask2None(m) = False, 'Mask2None($03) = False');
  Check(Mask2PopCount(m) = 2, 'Mask2PopCount($03) = 2');
  Check(Mask2FirstSet(m) = 0, 'Mask2FirstSet($03) = 0');

  // No bits set
  m := $00;
  Check(Mask2All(m) = False, 'Mask2All($00) = False');
  Check(Mask2Any(m) = False, 'Mask2Any($00) = False');
  Check(Mask2None(m) = True, 'Mask2None($00) = True');
  Check(Mask2PopCount(m) = 0, 'Mask2PopCount($00) = 0');
  Check(Mask2FirstSet(m) = -1, 'Mask2FirstSet($00) = -1');

  // One bit set
  m := $02;
  Check(Mask2All(m) = False, 'Mask2All($02) = False');
  Check(Mask2Any(m) = True, 'Mask2Any($02) = True');
  Check(Mask2PopCount(m) = 1, 'Mask2PopCount($02) = 1');
  Check(Mask2FirstSet(m) = 1, 'Mask2FirstSet($02) = 1');
end;

procedure TestMask4Operations;
var
  m: TMask4;
begin
  WriteLn('=== TMask4 Operations ===');

  // All bits set
  m := $0F;
  Check(Mask4All(m) = True, 'Mask4All($0F) = True');
  Check(Mask4PopCount(m) = 4, 'Mask4PopCount($0F) = 4');
  Check(Mask4FirstSet(m) = 0, 'Mask4FirstSet($0F) = 0');

  // Partial bits
  m := $05;  // 0101
  Check(Mask4All(m) = False, 'Mask4All($05) = False');
  Check(Mask4Any(m) = True, 'Mask4Any($05) = True');
  Check(Mask4PopCount(m) = 2, 'Mask4PopCount($05) = 2');
  Check(Mask4FirstSet(m) = 0, 'Mask4FirstSet($05) = 0');

  m := $08;  // 1000
  Check(Mask4FirstSet(m) = 3, 'Mask4FirstSet($08) = 3');
end;

procedure TestMask8Operations;
var
  m: TMask8;
begin
  WriteLn('=== TMask8 Operations ===');

  m := $FF;
  Check(Mask8All(m) = True, 'Mask8All($FF) = True');
  Check(Mask8PopCount(m) = 8, 'Mask8PopCount($FF) = 8');

  m := $AA;  // 10101010
  Check(Mask8PopCount(m) = 4, 'Mask8PopCount($AA) = 4');
  Check(Mask8FirstSet(m) = 1, 'Mask8FirstSet($AA) = 1');
end;

procedure TestMask16Operations;
var
  m: TMask16;
begin
  WriteLn('=== TMask16 Operations ===');

  m := $FFFF;
  Check(Mask16All(m) = True, 'Mask16All($FFFF) = True');
  Check(Mask16PopCount(m) = 16, 'Mask16PopCount($FFFF) = 16');

  m := $0000;
  Check(Mask16None(m) = True, 'Mask16None($0000) = True');
  Check(Mask16FirstSet(m) = -1, 'Mask16FirstSet($0000) = -1');

  m := $8000;  // bit 15 set
  Check(Mask16FirstSet(m) = 15, 'Mask16FirstSet($8000) = 15');
end;

procedure TestF64x2API;
var
  a, b, r: TVecF64x2;
  p: array[0..1] of Double;
  m: TMask2;
begin
  WriteLn('=== F64x2 API ===');

  // Zero
  r := VecF64x2Zero;
  Check((r.d[0] = 0.0) and (r.d[1] = 0.0), 'VecF64x2Zero');

  // Splat
  r := VecF64x2Splat(3.14);
  Check((Abs(r.d[0] - 3.14) < 1e-10) and (Abs(r.d[1] - 3.14) < 1e-10), 'VecF64x2Splat(3.14)');

  // Load/Store
  p[0] := 1.5;
  p[1] := 2.5;
  r := VecF64x2Load(@p[0]);
  Check((r.d[0] = 1.5) and (r.d[1] = 2.5), 'VecF64x2Load');

  r.d[0] := 10.0;
  r.d[1] := 20.0;
  VecF64x2Store(@p[0], r);
  Check((p[0] = 10.0) and (p[1] = 20.0), 'VecF64x2Store');

  // Select
  a.d[0] := 1.0; a.d[1] := 2.0;
  b.d[0] := 3.0; b.d[1] := 4.0;

  m := $00;  // select all from b
  r := VecF64x2Select(m, a, b);
  Check((r.d[0] = 3.0) and (r.d[1] = 4.0), 'VecF64x2Select($00) = b');

  m := $03;  // select all from a
  r := VecF64x2Select(m, a, b);
  Check((r.d[0] = 1.0) and (r.d[1] = 2.0), 'VecF64x2Select($03) = a');

  m := $01;  // select a[0], b[1]
  r := VecF64x2Select(m, a, b);
  Check((r.d[0] = 1.0) and (r.d[1] = 4.0), 'VecF64x2Select($01) = [a0,b1]');

  m := $02;  // select b[0], a[1]
  r := VecF64x2Select(m, a, b);
  Check((r.d[0] = 3.0) and (r.d[1] = 2.0), 'VecF64x2Select($02) = [b0,a1]');
end;

procedure TestF64x2Comparison;
var
  a, b: TVecF64x2;
  m: TMask2;
begin
  WriteLn('=== F64x2 Comparison ===');

  a.d[0] := 1.0; a.d[1] := 3.0;
  b.d[0] := 2.0; b.d[1] := 3.0;

  m := VecF64x2CmpEq(a, b);
  Check((m and $01) = 0, 'CmpEq: a[0]!=b[0]');
  Check((m and $02) <> 0, 'CmpEq: a[1]==b[1]');

  m := VecF64x2CmpLt(a, b);
  Check((m and $01) <> 0, 'CmpLt: a[0]<b[0]');
  Check((m and $02) = 0, 'CmpLt: a[1] not < b[1]');

  // Test Mask operations on comparison result
  a.d[0] := 1.0; a.d[1] := 1.0;
  b.d[0] := 1.0; b.d[1] := 1.0;
  m := VecF64x2CmpEq(a, b);
  Check(Mask2All(m), 'CmpEq all equal -> Mask2All = True');

  a.d[0] := 2.0;
  m := VecF64x2CmpEq(a, b);
  Check(Mask2Any(m), 'CmpEq partial -> Mask2Any = True');
  Check(not Mask2All(m), 'CmpEq partial -> Mask2All = False');
end;

begin
  WriteLn;
  WriteLn('=== P2-2/P2-3 API Tests ===');
  WriteLn('Testing Mask Operations and F64x2 API');
  WriteLn;

  TestMask2Operations;
  TestMask4Operations;
  TestMask8Operations;
  TestMask16Operations;
  TestF64x2API;
  TestF64x2Comparison;

  WriteLn;
  WriteLn('=== Summary ===');
  WriteLn('Tests run: ', TestCount);
  if AllPassed then
  begin
    WriteLn('All tests PASSED!');
    Halt(0);
  end
  else
  begin
    WriteLn('Some tests FAILED!');
    Halt(1);
  end;
end.
