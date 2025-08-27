program bench_simd;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Math,
  fafafa.core.simd;

function NowMs: QWord; inline;
begin
  Result := GetTickCount64;
end;

procedure FillRandom(var a: TBytes);
begin
  for var i:=0 to High(a) do a[i] := Random(256);
end;

procedure PrintHdr(const title: string);
begin
  Writeln('--- ', title, ' ---');
  Writeln('SIMD Profile = ', SimdInfo);
end;

procedure BenchMemEqual;
const
  Sizes: array[0..4] of Integer = (64, 1024, 64*1024, 1024*1024, 8*1024*1024);
var
  a,b: TBytes;
  iters, n: Integer;
  sz: Integer;
  t0,t1: QWord;
  bytes: QWord;
  hits: SizeInt = 0;
begin
  PrintHdr('MemEqual');
  for n:=0 to High(Sizes) do
  begin
    sz := Sizes[n];
    SetLength(a, sz); SetLength(b, sz);
    FillRandom(a); b := Copy(a,0,Length(a));
    // make one diff at end to defeat branch prediction sometimes
    b[sz-1] := b[sz-1] xor 1;
    iters := Max(1, (64*1024*1024) div sz);
    t0 := NowMs;
    for var i:=1 to iters do begin
      if MemEqual(@a[0], @b[0], sz) then Inc(hits);
      // flip diff position to mix
      b[sz-1] := b[sz-1] xor 1;
      b[0] := b[0] xor 1;
    end;
    t1 := NowMs;
    bytes := QWord(sz) * QWord(iters);
    Writeln(Format('size=%8d bytes, iters=%7d, time=%5d ms, thr=%.2f MB/s',
      [sz, iters, t1 - t0, bytes / 1.0e6 / ((t1 - t0) / 1000.0 + 1e-9)]));
  end;
  Writeln('hits (ignore): ', hits);
end;

procedure BenchMemFindByte;
const
  Sizes: array[0..3] of Integer = (1024, 64*1024, 1024*1024, 8*1024*1024);
var
  a: TBytes;
  iters, n, sz: Integer;
  t0,t1: QWord;
  bytes: QWord;
  idx: PtrInt;
begin
  PrintHdr('MemFindByte');
  for n:=0 to High(Sizes) do
  begin
    sz := Sizes[n];
    SetLength(a, sz);
    FillByte(a[0], sz, $AA);
    a[sz div 2] := $7E;
    iters := Max(1, (64*1024*1024) div sz);
    t0 := NowMs;
    for var i:=1 to iters do begin
      idx := MemFindByte(@a[0], sz, $7E);
      if idx <> (sz div 2) then Writeln('warn: idx mismatch ', idx);
    end;
    t1 := NowMs;
    bytes := QWord(sz) * QWord(iters);
    Writeln(Format('size=%8d bytes, iters=%7d, time=%5d ms, thr=%.2f MB/s',
      [sz, iters, t1 - t0, bytes / 1.0e6 / ((t1 - t0) / 1000.0 + 1e-9)]));
  end;
end;

procedure BenchMemDiffRange;
const
  Sizes: array[0..2] of Integer = (4096, 256*1024, 4*1024*1024);
var
  a,b: TBytes; sz: Integer; iters: Integer; t0,t1: QWord; r: TDiffRange;
  bytes: QWord;
begin
  PrintHdr('MemDiffRange');
  for var n:=0 to High(Sizes) do
  begin
    sz := Sizes[n];
    SetLength(a, sz); SetLength(b, sz);
    FillRandom(a); b := Copy(a,0,Length(a));
    // introduce differences at random positions
    a[0] := a[0] xor $11; b[sz-1] := b[sz-1] xor $22;
    iters := Max(1, (64*1024*1024) div sz);
    t0 := NowMs;
    for var i:=1 to iters do begin
      r := MemDiffRange(@a[0], @b[0], sz);
      if (r.First<0) or (r.Last<0) or (r.First>r.Last) then Writeln('warn: diff range invalid');
    end;
    t1 := NowMs;
    bytes := QWord(sz) * QWord(iters);
    Writeln(Format('size=%8d bytes, iters=%7d, time=%5d ms, thr=%.2f MB/s',
      [sz, iters, t1 - t0, bytes / 1.0e6 / ((t1 - t0) / 1000.0 + 1e-9)]));
  end;
end;

procedure BenchBitsetPopCount;
var
  bytes: TBytes; bits: SizeUInt; iters: Integer; t0,t1: QWord; acc: SizeUInt = 0;
  totalBits: QWord;
begin
  PrintHdr('BitsetPopCount');
  SetLength(bytes, 1024*1024);
  FillRandom(bytes);
  bits := Length(bytes)*8 - 3; // 留点尾部掩码
  iters := 128;
  t0 := NowMs;
  for var i:=1 to iters do acc += BitsetPopCount(@bytes[0], bits);
  t1 := NowMs;
  totalBits := QWord(bits) * QWord(iters);
  Writeln(Format('bits=%d, iters=%d, time=%d ms, thr=%.2f Gbits/s (acc=%d)',
    [bits, iters, t1 - t0, totalBits / 1.0e9 / ((t1 - t0)/1000.0 + 1e-9), acc]));
end;

procedure BenchUtf8Validate;
var
  ascii: TBytes; mixed: TBytes; iters: Integer; t0,t1: QWord; ok: Boolean;
  bytes: QWord;
begin
  PrintHdr('Utf8Validate');
  SetLength(ascii, 8*1024*1024);
  for var i:=0 to High(ascii) do ascii[i] := Ord('A') + (i and 15);
  // mixed: mostly ascii with some 2-byte UTF-8 every 64 bytes
  SetLength(mixed, 4*1024*1024);
  var j:=0; while j<Length(mixed) do begin
    for var k:=0 to 63 do begin if j>=Length(mixed) then break; mixed[j]:=Ord('a')+(k and 7); Inc(j); end;
    if j+1<Length(mixed) then begin mixed[j]:=$C3; mixed[j+1]:=$A9; Inc(j,2); end;
  end;
  // ASCII fast path
  iters := 16;
  t0 := NowMs;
  for var i:=1 to iters do begin ok := Utf8Validate(@ascii[0], Length(ascii)); if not ok then Writeln('warn: ascii fail'); end;
  t1 := NowMs;
  bytes := QWord(Length(ascii)) * QWord(iters);
  Writeln(Format('ASCII size=%d, iters=%d, time=%d ms, thr=%.2f MB/s',
    [Length(ascii), iters, t1-t0, bytes/1.0e6/((t1-t0)/1000.0 + 1e-9)]));
  // mixed (will fall back to scalar)
  iters := 8;
  t0 := NowMs;
  for var i:=1 to iters do begin ok := Utf8Validate(@mixed[0], Length(mixed)); if not ok then Writeln('warn: mixed reported false'); end;
  t1 := NowMs;
  bytes := QWord(Length(mixed)) * QWord(iters);
  Writeln(Format('Mixed size=%d, iters=%d, time=%d ms, thr=%.2f MB/s',
    [Length(mixed), iters, t1-t0, bytes/1.0e6/((t1-t0)/1000.0 + 1e-9)]));
end;

procedure BenchIndexOf;
const
  Sizes: array[0..2] of Integer = (64*1024, 512*1024, 4*1024*1024);
  Needles: array[0..4] of Integer = (4, 8, 16, 32, 64);
var
  hay, ned: TBytes; nlen, sz, iters: Integer; t0,t1: QWord; bytes: QWord; pos: Integer; idx: PtrInt;
begin
  PrintHdr('BytesIndexOf');
  for var si:=0 to High(Sizes) do
  begin
    sz := Sizes[si]; SetLength(hay, sz); FillRandom(hay);
    for var ni:=0 to High(Needles) do
    begin
      nlen := Needles[ni]; SetLength(ned, nlen); FillRandom(ned);
      // insert needle at middle
      pos := sz div 2; Move(ned[0], hay[pos], nlen);
      iters := Max(1, (64*1024*1024) div nlen);
      t0 := NowMs;
      for var i:=1 to iters do begin idx := BytesIndexOf(@hay[0], sz, @ned[0], nlen); if idx <> pos then Writeln('warn: idx mismatch'); end;
      t1 := NowMs;
      bytes := QWord(sz) * QWord(iters);
      Writeln(Format('size=%8d, nlen=%2d, iters=%7d, time=%5d ms, thr=%.2f MB/s',
        [sz, nlen, iters, t1-t0, bytes/1.0e6/((t1-t0)/1000.0 + 1e-9)]));
    end;
  end;
end;

procedure BenchAsciiCase;
const
  Sizes: array[0..2] of Integer = (64*1024, 1024*1024, 8*1024*1024);
var
  buf: TBytes; sz, iters: Integer; t0,t1: QWord; bytes: QWord;
begin
  PrintHdr('AsciiCase (ToLower/ToUpper)');
  for var si:=0 to High(Sizes) do
  begin
    sz := Sizes[si];
    SetLength(buf, sz);
    // mix letters and non-letters
    for var i:=0 to High(buf) do
    begin
      case i and 7 of
        0: buf[i] := Ord('A') + (i mod 26);
        1: buf[i] := Ord('a') + (i mod 26);
        2: buf[i] := Ord('Z') - (i mod 26);
        3: buf[i] := Ord('z') - (i mod 26);
        4: buf[i] := Ord('0') + (i mod 10);
        else buf[i] := Ord('@') + (i mod 32);
      end;
    end;
    iters := Max(1, (64*1024*1024) div sz);
    // ToLower
    t0 := NowMs;
    for var i:=1 to iters do ToLowerAscii(@buf[0], sz);
    t1 := NowMs;
    bytes := QWord(sz) * QWord(iters);
    Writeln(Format('ToLower size=%8d, iters=%7d, time=%5d ms, thr=%.2f MB/s',
      [sz, iters, t1-t0, bytes/1.0e6/((t1-t0)/1000.0 + 1e-9)]));
    // ToUpper
    t0 := NowMs;
    for var i:=1 to iters do ToUpperAscii(@buf[0], sz);
    t1 := NowMs;
    Writeln(Format('ToUpper size=%8d, iters=%7d, time=%5d ms, thr=%.2f MB/s',
      [sz, iters, t1-t0, bytes/1.0e6/((t1-t0)/1000.0 + 1e-9)]));
  end;
end;

begin
  Randomize;
  try
    BenchMemEqual;
    BenchMemFindByte;
    BenchMemDiffRange;
    BenchBitsetPopCount;
    BenchUtf8Validate;
    BenchIndexOf;
    BenchAsciiCase;
  except
    on E: Exception do begin Writeln('EXCEPTION: ', E.Message); Halt(2); end;
  end;
end.

