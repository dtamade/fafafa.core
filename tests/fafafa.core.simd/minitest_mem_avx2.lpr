program minitest_mem_avx2;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.mem,
  fafafa.core.simd.types;

procedure AssertTrue(name: string; cond: Boolean);
begin
  if not cond then begin
    Writeln('FAIL ', name);
    Halt(1);
  end;
end;

procedure AssertEqI(const name: string; a, b: PtrInt);
begin
  if a<>b then begin
    Writeln('FAIL ', name, ': ', a, ' <> ', b);
    Halt(1);
  end;
end;

procedure TestMemEqualAndDiff;
var
  prof: string;
  a, b: array[0..255] of Byte;
  i: Integer;
  eqA, eqS: LongBool;
  drA, drS: TDiffRange;
begin
  prof := SimdInfo;
  Writeln('SimdInfo=', prof);
  if Pos('AVX2', prof) = 0 then begin
    Writeln('SKIP: profile=', prof);
    Exit;
  end;
  Writeln('CHECK: after profile check');
  // dry-run minimal AVX2 calls
  AssertTrue('E0', MemEqual_AVX2(nil, nil, 0) = MemEqual_SSE2(nil, nil, 0));
  Writeln('E0 OK');
  AssertTrue('D0', (MemDiffRange_AVX2(nil, nil, 0).First = MemDiffRange_SSE2(nil, nil, 0).First));
  Writeln('D0 OK');
  // base equal
  Writeln('CASE: base equal');
  for i:=0 to High(a) do begin a[i] := i and $FF; b[i] := a[i]; end;
  eqA := MemEqual_AVX2(@a[0], @b[0], 256);
  eqS := MemEqual_SSE2(@a[0], @b[0], 256);
  AssertTrue('eq base', eqA = eqS);
  drA := MemDiffRange_AVX2(@a[0], @b[0], 256);
  drS := MemDiffRange_SSE2(@a[0], @b[0], 256);
  AssertEqI('dr base first', drA.First, drS.First);
  AssertEqI('dr base last', drA.Last, drS.Last);
  // first diff
  Writeln('CASE: first diff');
  b[0] := b[0] xor $FF;
  eqA := MemEqual_AVX2(@a[0], @b[0], 256);
  eqS := MemEqual_SSE2(@a[0], @b[0], 256);
  AssertTrue('eq first diff', eqA = eqS);
  drA := MemDiffRange_AVX2(@a[0], @b[0], 256);
  drS := MemDiffRange_SSE2(@a[0], @b[0], 256);
  AssertEqI('dr first diff first', drA.First, drS.First);
  AssertEqI('dr first diff last', drA.Last, drS.Last);
  // mid diff
  Writeln('CASE: mid diff');
  b[0] := a[0];
  b[123] := b[123] xor $FF;
  eqA := MemEqual_AVX2(@a[0], @b[0], 200);
  eqS := MemEqual_SSE2(@a[0], @b[0], 200);
  AssertTrue('eq mid diff', eqA = eqS);
  drA := MemDiffRange_AVX2(@a[0], @b[0], 200);
  drS := MemDiffRange_SSE2(@a[0], @b[0], 200);
  AssertEqI('dr mid diff first', drA.First, drS.First);
  AssertEqI('dr mid diff last', drA.Last, drS.Last);
  // tail diff
  Writeln('CASE: tail diff');
  b[123] := a[123];
  b[199] := b[199] xor $FF;
  eqA := MemEqual_AVX2(@a[0], @b[0], 200);
  eqS := MemEqual_SSE2(@a[0], @b[0], 200);
  AssertTrue('eq tail diff', eqA = eqS);
  drA := MemDiffRange_AVX2(@a[0], @b[0], 200);
  drS := MemDiffRange_SSE2(@a[0], @b[0], 200);
  AssertEqI('dr tail diff first', drA.First, drS.First);
  AssertEqI('dr tail diff last', drA.Last, drS.Last);
  // unaligned base
  Writeln('CASE: unaligned');
  for i:=0 to 127 do begin a[i] := (i*3) and $FF; b[i] := a[i]; end;
  b[7] := b[7] xor $AA;
  eqA := MemEqual_AVX2(@a[1], @b[1], 127);
  eqS := MemEqual_SSE2(@a[1], @b[1], 127);
  AssertTrue('eq unaligned', eqA = eqS);
  drA := MemDiffRange_AVX2(@a[1], @b[1], 127);
  drS := MemDiffRange_SSE2(@a[1], @b[1], 127);
  AssertEqI('dr unaligned first', drA.First, drS.First);
  AssertEqI('dr unaligned last', drA.Last, drS.Last);
  // zero length
  Writeln('CASE: zero len');
  eqA := MemEqual_AVX2(nil, nil, 0);
  eqS := MemEqual_SSE2(nil, nil, 0);
  AssertTrue('eq zero len', eqA = eqS);
  drA := MemDiffRange_AVX2(nil, nil, 0);
  drS := MemDiffRange_SSE2(nil, nil, 0);
  AssertEqI('dr zero len first', drA.First, drS.First);
  AssertEqI('dr zero len last', drA.Last, drS.Last);
  Writeln('OK: minitest_mem_avx2');
end;

begin
  try
    TestMemEqualAndDiff;
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

