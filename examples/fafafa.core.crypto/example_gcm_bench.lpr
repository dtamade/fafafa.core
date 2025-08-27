program example_gcm_bench;
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto;

function BytesToHex(const B: TBytes): string;
const Hex: PChar = '0123456789abcdef';
var i: Integer;
begin
  SetLength(Result, Length(B)*2);
  for i := 0 to High(B) do
  begin
    Result[2*i+1] := Hex[(B[i] shr 4) and $F];
    Result[2*i+2] := Hex[B[i] and $F];
  end;
end;

procedure BenchOne(const KeyLen, PTLen, TagLen: Integer);
var
  Key, Nonce, AAD, PT, CT: TBytes;
  AEAD: IAEADCipher;
  iter: Integer;
  t0, t1: QWord;
  bytesProc: QWord;
  dt_ms: Double;
  mbps: Double;
begin
  SetLength(Key, KeyLen); FillChar(Key[0], KeyLen, 7);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 9);
  SetLength(AAD, 32); FillChar(AAD[0], 32, 3);
  SetLength(PT, PTLen); FillChar(PT[0], PTLen, 5);

  AEAD := CreateAES256GCM;
  AEAD.SetKey(Key);
  AEAD.SetTagLength(TagLen);

  // warmup
  for iter := 1 to 50 do CT := AEAD.Seal(Nonce, AAD, PT);

  // timed
  bytesProc := 0;
  t0 := GetTickCount64;
  for iter := 1 to 1000 do
  begin
    CT := AEAD.Seal(Nonce, AAD, PT);
    Inc(bytesProc, Length(PT));
  end;
  t1 := GetTickCount64;

  dt_ms := (t1 - t0);
  if dt_ms = 0 then dt_ms := 1; // avoid div-by-zero on fast runs
  mbps := (bytesProc / 1024.0 / 1024.0) / (dt_ms / 1000.0);

  Writeln(Format('AES-256-GCM Tag=%d PT=%dB: %.2f MB/s (processed=%d MB, %d iters)',
    [TagLen, PTLen, mbps, bytesProc div (1024*1024), 1000]));
end;

var L: array[0..5] of Integer = (0, 16, 64, 256, 1024, 4096);
    TagLens: array[0..1] of Integer = (12,16);
    i, j: Integer;
begin
  Writeln('GCM micro-benchmark (UTF-8)…');
  for j := 0 to High(TagLens) do
    for i := 0 to High(L) do
      BenchOne(32, L[i], TagLens[j]);
end.

