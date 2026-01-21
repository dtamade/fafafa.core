{$CODEPAGE UTF8}
unit Test_ghash_clmul_vs_pure_byte_bench;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF}
  fafafa.core.math,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_CLMUL_vs_PureByte = class(TTestCase)
  published
    procedure Bench_CLMUL_vs_PureByte;
  end;

implementation

{$IFNDEF MSWINDOWS}
function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external 'c' name 'setenv';
function unsetenv(name: PChar): cint; cdecl; external 'c' name 'unsetenv';
{$ENDIF}

function NowUS: Int64;
begin
  Result := Trunc(Now * 24*60*60*1000*1000);
end;

procedure FillSeq(var B: TBytes; Seed: Byte);
var i: Integer;
begin
  for i := 0 to High(B) do B[i] := Seed + i;
end;

procedure SaveEnv(const Name: String; out Old: String);
begin
  Old := SysUtils.GetEnvironmentVariable(Name);
end;

procedure SetEnv(const Name, Value: String);
begin
  {$IFDEF MSWINDOWS}
  if Value = '' then Windows.SetEnvironmentVariable(PChar(Name), nil)
  else Windows.SetEnvironmentVariable(PChar(Name), PChar(Value));
  {$ELSE}
  if Value = '' then unsetenv(PChar(Name))
  else setenv(PChar(Name), PChar(Value), 1);
  {$ENDIF}
end;

procedure RestoreEnv(const Name, Old: String);
begin
  SetEnv(Name, Old);
end;

procedure BenchOnce(const Impl, PureMode: String; EnableExp: Boolean; const iters: Integer; var outUS: Int64);
var
  oldImpl, oldMode, oldExp: String;
  H, AAD, C, Tag: TBytes;
  i: Integer;
  t0, t1: Int64;
  g: IGHash;
begin
  // prepare inputs
  SetLength(H, 16); FillSeq(H, 7);
  SetLength(AAD, 64*1024); FillSeq(AAD, 11);
  SetLength(C,   256*1024); FillSeq(C,   19);

  // save and set env
  SaveEnv('FAFAFA_GHASH_IMPL', oldImpl);
  SaveEnv('FAFAFA_GHASH_PURE_MODE', oldMode);
  SaveEnv('FAFAFA_GHASH_USE_EXPERIMENTAL', oldExp);
  try
    if Impl <> '' then SetEnv('FAFAFA_GHASH_IMPL', Impl);
    if PureMode <> '' then SetEnv('FAFAFA_GHASH_PURE_MODE', PureMode);
    if EnableExp then SetEnv('FAFAFA_GHASH_USE_EXPERIMENTAL', '1');

    // warmup
    g := CreateGHash; g.Init(H); g.Update(AAD); g.Update(C); Tag := g.Finalize(Length(AAD), Length(C));

    // bench
    t0 := NowUS;
    for i := 1 to iters do
    begin
      g := CreateGHash; g.Init(H); g.Update(AAD); g.Update(C); Tag := g.Finalize(Length(AAD), Length(C));
    end;
    t1 := NowUS;
    outUS := t1 - t0;
  finally
    RestoreEnv('FAFAFA_GHASH_USE_EXPERIMENTAL', oldExp);
    RestoreEnv('FAFAFA_GHASH_PURE_MODE', oldMode);
    RestoreEnv('FAFAFA_GHASH_IMPL', oldImpl);
  end;
end;

procedure TTestCase_GHash_CLMUL_vs_PureByte.Bench_CLMUL_vs_PureByte;
var
  env: String; verbose: Boolean;
  iters: Integer;
  dtPure, dtCLMUL: Int64;
  totalBytes: Int64; dtSec: Double; mibps: Double; d: Int64; arr: array[0..2] of Int64; suffix: String;
  sI: String;
begin
  iters := 6;
  // allow override via env
  sI := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_ITERS');
  if (sI <> '') then try iters := StrToInt(sI); except end;
  dtPure := 0; dtCLMUL := 0;
  suffix := '';
  // Always run pure-byte
  BenchOnce('pure', 'byte', False, iters, dtPure);
  AssertTrue(dtPure > 0);
  // Try to run CLMUL; in Debug builds we also flip experimental guard
  BenchOnce('clmul', '', True, iters, dtCLMUL);
  AssertTrue(dtCLMUL > 0);

  // Optional throughput prints
  env := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_VERBOSE');
  verbose := (env <> '') and (env <> '0');
  totalBytes := (Int64(64*1024) + Int64(256*1024)) * Int64(iters);

  if (env = '2') then
  begin
    suffix := ' [median of 3]';
    // median-of-3 for both
    // pure-byte repeats
    arr[0]:=dtPure; BenchOnce('pure','byte',False,iters,d); arr[1]:=d; BenchOnce('pure','byte',False,iters,d); arr[2]:=d;
    // sort (simple 3-element median)
    if arr[0] > arr[1] then begin d := arr[0]; arr[0] := arr[1]; arr[1] := d; end;
    if arr[1] > arr[2] then begin d := arr[1]; arr[1] := arr[2]; arr[2] := d; end;
    if arr[0] > arr[1] then begin d := arr[0]; arr[0] := arr[1]; arr[1] := d; end;
    dtPure := arr[1];
    // clmul repeats
    arr[0]:=dtCLMUL; BenchOnce('clmul','',True,iters,d); arr[1]:=d; BenchOnce('clmul','',True,iters,d); arr[2]:=d;
    if arr[0] > arr[1] then begin d := arr[0]; arr[0] := arr[1]; arr[1] := d; end;
    if arr[1] > arr[2] then begin d := arr[1]; arr[1] := arr[2]; arr[2] := d; end;
    if arr[0] > arr[1] then begin d := arr[0]; arr[0] := arr[1]; arr[1] := d; end;
    dtCLMUL := arr[1];
  end;

  if verbose then
  begin
    // pure-byte
    dtSec := dtPure / 1000000.0;
    if dtSec > 0 then
    begin
      mibps := (totalBytes / 1048576.0) / dtSec;
      WriteLn(Format('GHASH pure-byte: %.1f MiB/s (%d bytes in %.3f s, iters=%d)%s',
        [mibps, totalBytes, dtSec, iters, suffix]));
    end;
    // clmul-requested
    dtSec := dtCLMUL / 1000000.0;
    if dtSec > 0 then
    begin
      mibps := (totalBytes / 1048576.0) / dtSec;
      WriteLn(Format('GHASH clmul-requested: %.1f MiB/s (%d bytes in %.3f s, iters=%d)%s',
        [mibps, totalBytes, dtSec, iters, suffix]));
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_GHash_CLMUL_vs_PureByte);

end.

