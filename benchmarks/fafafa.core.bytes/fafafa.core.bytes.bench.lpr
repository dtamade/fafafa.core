{$CODEPAGE UTF8}
program fafafa.core.bytes.bench;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils, DateUtils,
  fafafa.core.bytes,
  fafafa.core.bytes.buf;

function NowMs: Int64; inline;
begin
  Result := MilliSecondOf(Now);
end;

procedure BenchConcatVsBuilder;
var i: Integer; chunk: TBytes; A,B: TBytes; bb: TBytesBuilder; t0,t1: Int64;
begin
  // 准备 16B 小块，累计 64KB
  SetLength(chunk, 16);
  for i := 0 to High(chunk) do chunk[i] := Byte(i);

  // BytesConcat
  SetLength(A, 0);
  t0 := NowMs;
  for i := 1 to 4096 do A := BytesConcat(A, chunk);
  t1 := NowMs;
  Writeln('Concat(16B x 4096): ', (t1-t0), ' ms, total=', Length(A));

  // Builder.Append
  bb.Init(0);
  t0 := NowMs;
  for i := 1 to 4096 do bb.Append(chunk);
  B := bb.ToBytes;
  t1 := NowMs;
  Writeln('Builder.Append(16B x 4096): ', (t1-t0), ' ms, total=', Length(B));
end;

procedure BenchByteBufGrowth;
var i: Integer; buf: IByteBuf; t0,t1: Int64; chunk: TBytes;
begin
  buf := TByteBufImpl.New(0);
  SetLength(chunk, 4096);
  FillChar(chunk[0], Length(chunk), 1);
  t0 := NowMs;
  for i := 1 to 2048 do buf.WriteBytes(chunk); // ~8MB
  t1 := NowMs;
  Writeln('ByteBuf EnsureWritable growth 8MB: ', (t1-t0), ' ms, final cap=', buf.Capacity);
end;

procedure BenchReadWriteAndCompact;
var buf: IByteBuf; t0,t1: Int64; total: Integer; chunk, tmp: TBytes; i: Integer;
begin
  buf := TByteBufImpl.New(0);
  SetLength(chunk, 1024);
  FillChar(chunk[0], Length(chunk), 2);
  for i := 1 to 1000 do buf.WriteBytes(chunk);
  total := buf.ReadableBytes;
  t0 := NowMs; tmp := buf.ReadBytes(500*1024); t1 := NowMs;
  Writeln('Read 500KB: ', (t1-t0), ' ms');
  t0 := NowMs; buf.Compact; t1 := NowMs;
  Writeln('Compact: ', (t1-t0), ' ms, remaining=', buf.ReadableBytes, '/', total);
end;

begin
  Writeln('=== fafafa.core.bytes/buf microbench (quick) ===');
  BenchConcatVsBuilder;
  BenchByteBufGrowth;
  BenchReadWriteAndCompact;
end.

