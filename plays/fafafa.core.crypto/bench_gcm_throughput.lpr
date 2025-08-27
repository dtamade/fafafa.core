program bench_gcm_throughput;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.crypto, fafafa.core.benchmark;

function GenBytes(n: Integer; v: Byte): TBytes;
begin
  SetLength(Result, n);
  if n>0 then FillChar(Result[0], n, v);
end;

procedure BenchRun(const name: string; size: Integer);
var
  GCM: IAEADCipher;
  Key, Nonce, AAD, PT, CT: TBytes;
  startT, endT: QWord;
  iters, i: Integer;
  ms: Double;
begin
  GCM := CreateAES256GCM; SetLength(Key,32); FillChar(Key[0],32,0); GCM.SetKey(Key);
  Nonce := ComposeGCMNonce12(42, 123);
  AAD := GenBytes(16, $AA); PT := GenBytes(size, $55);
  iters := 100;
  startT := GetTickCount64;
  for i:=1 to iters do CT := GCM.Seal(Nonce, AAD, PT);
  endT := GetTickCount64;
  ms := (endT - startT);
  if ms <= 0 then ms := 1;
  WriteLn(Format('%s: %d bytes x %d iters -> %.2f MB/s',[name,size,iters, (size*iters)/(ms/1000.0)/1024/1024]));
end;

begin
  BenchRun('GCM seal', 0);
  BenchRun('GCM seal', 16);
  BenchRun('GCM seal', 64);
  BenchRun('GCM seal', 1024);
  BenchRun('GCM seal', 16*1024);
  BenchRun('GCM seal', 1024*1024);
end.

