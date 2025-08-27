program minitest_simd_ops;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.api;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure TestMemOps;
var
  ops: TSimdOps;
  a, b: array[0..31] of Byte;
  i: Integer;
  eq1, eq2: LongBool;
begin
  Writeln('T1: SimdOps');
  ops := SimdOps;
  Writeln('T1: init arrays');
  for i:=0 to High(a) do begin a[i] := i; b[i] := i; end;
  Writeln('T1: Equal compare baseline');
  eq1 := MemEqual(@a[0], @b[0], Length(a));
  eq2 := ops.Mem.Equal(@a[0], @b[0], Length(a));
  AssertTrue(eq1=eq2, 'Mem.Equal consistent with global MemEqual');
  // mutate and compare
  Writeln('T1: mutate and compare');
  b[7] := b[7] xor $FF;
  eq1 := MemEqual(@a[0], @b[0], Length(a));
  eq2 := ops.Mem.Equal(@a[0], @b[0], Length(a));
  AssertTrue(eq1=eq2, 'Mem.Equal detects diff consistently');
  // Zero/Fill roundtrip
  Writeln('T1: zero/fill');
  ops.Mem.Zero(@b[0], Length(b));
  ops.Mem.Fill(@b[0], Length(b), 0);
  AssertTrue(MemEqual(@b[0], @b[0], Length(b)), 'Mem.Zero/Fill basic');
end;

procedure TestSearchOps;
var
  ops: TSimdOps;
  hay, ned: array[0..15] of Byte;
  i: Integer;
  idx1, idx2: PtrInt;
begin
  Writeln('T2: SimdOps');
  ops := SimdOps;
  // "hello world"
  Writeln('T2: prepare data');
  FillChar(hay, SizeOf(hay), 0);
  Move(PAnsiChar(AnsiString('hello world'))^, hay[0], 11);
  FillChar(ned, SizeOf(ned), 0);
  Move(PAnsiChar(AnsiString('world'))^, ned[0], 5);
  Writeln('T2: run');
  idx1 := BytesIndexOf(@hay[0], 11, @ned[0], 5);
  idx2 := ops.Search.BytesIndexOf(@hay[0], 11, @ned[0], 5);
  Writeln('T2: idx1=', idx1, ' idx2=', idx2);
  AssertTrue(idx1=idx2, 'Search.BytesIndexOf consistent with global');
  AssertTrue(idx2=6, 'Search.BytesIndexOf basic pos');
end;

procedure TestSearchOpsExtended;
var
  ops: TSimdOps;
  buf: array[0..31] of Byte;
  idx: PtrInt;
  spaces: array[0..2] of Byte;
begin
  Writeln('T2x: SimdOps');
  ops := SimdOps;
  // FindEOL: CRLF
  Writeln('T2x: CRLF');
  FillChar(buf, SizeOf(buf), 0);
  Move(PAnsiChar(AnsiString('abc'+#13#10+'def'))^, buf[0], 7);
  idx := ops.Search.FindEOL(@buf[0], 7);
  Writeln('T2x: idx=', idx);
  AssertTrue(idx=3, 'FindEOL CRLF');
  // FindEOL: LF only
  Writeln('T2x: LF');
  FillChar(buf, SizeOf(buf), 0);
  Move(PAnsiChar(AnsiString('abc'+#10+'def'))^, buf[0], 7);
  idx := ops.Search.FindEOL(@buf[0], 7);
  Writeln('T2x: idx=', idx);
  AssertTrue(idx=3, 'FindEOL LF');
  // FindFirstNotOf: spaces
  Writeln('T2x: NotOf spaces');
  spaces[0] := Ord(' '); spaces[1] := Ord(#9); spaces[2] := Ord(#13);
  FillChar(buf, SizeOf(buf), 0);
  Move(PAnsiChar(AnsiString('  '#9'hello'))^, buf[0], 8);
  idx := ops.Search.FindFirstNotOf(@buf[0], 8, @spaces[0], 3);
  Writeln('T2x: idx=', idx);
  AssertTrue(idx=3, 'FindFirstNotOf spaces');
end;

procedure TestSearchOpsEdges;
var
  ops: TSimdOps;
  buf: array[0..1023] of Byte;
  setbuf: array[0..3] of Byte;
  idx: PtrInt;
begin
  ops := SimdOps;
  // len=0 + nil
  idx := ops.Search.FindEOL(nil, 0);
  AssertTrue(idx=-1, 'FindEOL nil,0');
  idx := ops.Search.FindFirstNotOf(nil, 0, nil, 0);
  AssertTrue(idx=-1, 'FindFirstNotOf nil,0');
  // CR only
  FillChar(buf, SizeOf(buf), 0);
  buf[0] := Ord(#13);
  idx := ops.Search.FindEOL(@buf[0], 1);
  AssertTrue(idx=-1, 'FindEOL CR-only returns -1');
  // no EOL
  FillChar(buf, 64, Ord('a'));
  idx := ops.Search.FindEOL(@buf[0], 64);
  AssertTrue(idx=-1, 'FindEOL no-EOL');
  // long buffer, EOL at 900
  FillChar(buf, SizeOf(buf), Ord('x'));
  buf[900] := Ord(#10);
  idx := ops.Search.FindEOL(@buf[0], 1000);
  AssertTrue(idx=900, 'FindEOL long buffer');
  // unaligned pointer
  FillChar(buf, 64, Ord('a'));
  buf[10] := Ord(#10);
  idx := ops.Search.FindEOL(@buf[1], 20);
  AssertTrue(idx=9, 'FindEOL unaligned');
  // FindFirstNotOf: empty set
  FillChar(buf, 8, Ord('a'));
  idx := ops.Search.FindFirstNotOf(@buf[0], 8, nil, 0);
  AssertTrue(idx=0, 'FindFirstNotOf empty set returns 0');
  // entire-in-set → -1
  setbuf[0] := Ord('a'); setbuf[1] := Ord('b'); setbuf[2] := Ord('c'); setbuf[3] := Ord('x');
  FillChar(buf, 8, Ord('a'));
  idx := ops.Search.FindFirstNotOf(@buf[0], 8, @setbuf[0], 4);
  AssertTrue(idx=-1, 'FindFirstNotOf all-in-set');
  // first-not-of at pos 3
  buf[0] := Ord('a'); buf[1] := Ord('b'); buf[2] := Ord('c'); buf[3] := Ord('Z');
  idx := ops.Search.FindFirstNotOf(@buf[0], 8, @setbuf[0], 3);
  AssertTrue(idx=3, 'FindFirstNotOf pos 3');
end;

procedure TestSearchOpsPrefix;
var
  ops: TSimdOps;
  hay: array[0..31] of Byte;
  ned: array[0..31] of Byte;
  ok: Boolean;
begin
  ops := SimdOps;
  FillChar(hay, SizeOf(hay), 0);
  Move(PAnsiChar(AnsiString('HelloWorld'))^, hay[0], 10);
  FillChar(ned, SizeOf(ned), 0);
  // StartsWith
  Move(PAnsiChar(AnsiString('Hello'))^, ned[0], 5);
  ok := ops.Search.StartsWith(@hay[0], 10, @ned[0], 5);
  AssertTrue(ok, 'StartsWith basic');
  // StartsWithI
  FillChar(ned, SizeOf(ned), 0);
  Move(PAnsiChar(AnsiString('hello'))^, ned[0], 5);
  ok := ops.Search.StartsWithI(@hay[0], 10, @ned[0], 5);
  AssertTrue(ok, 'StartsWithI icase');
  // zero-length needle
  ok := ops.Search.StartsWith(@hay[0], 10, @ned[0], 0);
  AssertTrue(ok, 'StartsWith empty needle true');
  // nlen>len false
  ok := ops.Search.StartsWith(@hay[0], 3, @ned[0], 5);
  AssertTrue(not ok, 'StartsWith nlen>len false');
  // unaligned hay
  ok := ops.Search.StartsWith(@hay[1], 9, @ned[0], 4); // 'ello'
  AssertTrue(ok, 'StartsWith unaligned');
end;

procedure TestTextOps;
var
  ops: TSimdOps;
  s1, s2: AnsiString;
  buf1, buf2: array[0..7] of Byte;
  i: Integer;
  ok1, ok2: LongBool;
begin
  ops := SimdOps;
  s1 := 'AbCdEfG'; s2 := 'abcdefg';
  FillChar(buf1, SizeOf(buf1), 0); FillChar(buf2, SizeOf(buf2), 0);
  Move(PAnsiChar(s1)^, buf1[0], Length(s1));
  Move(PAnsiChar(s2)^, buf2[0], Length(s2));
  ok1 := AsciiIEqual(@buf1[0], @buf2[0], Length(s2));
  ok2 := ops.Text.AsciiEqualIgnoreCase(@buf1[0], @buf2[0], Length(s2));
  AssertTrue(ok1=ok2, 'Text.AsciiIEqual consistent with global');
end;

begin
  try
    Writeln('RUN: TestMemOps'); TestMemOps;
    Writeln('RUN: TestSearchOps'); TestSearchOps;
    Writeln('RUN: TestSearchOpsExtended'); TestSearchOpsExtended;
    Writeln('RUN: TestSearchOpsEdges'); TestSearchOpsEdges;
    Writeln('RUN: TestSearchOpsPrefix'); TestSearchOpsPrefix;
    Writeln('RUN: TestTextOps'); TestTextOps;
    Writeln('OK: minitest_simd_ops passed.');
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

