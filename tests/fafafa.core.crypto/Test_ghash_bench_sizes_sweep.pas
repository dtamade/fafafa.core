{$CODEPAGE UTF8}
unit Test_ghash_bench_sizes_sweep;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF}
  fafafa.core.math,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_BenchSizesSweep = class(TTestCase)
  published
    procedure Bench_Sizes_Sweep_PureByte_And_CLMUL;
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
  for i := 0 to High(B) do B[i] := Byte((Seed + i) and $FF);
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

procedure BenchOnce(const Impl, PureMode: String; EnableExp: Boolean;
                    const aadLen, cLen, iters: Integer; var outUS: Int64);
var
  oldImpl, oldMode, oldExp: String;
  H, AAD, C, Tag: TBytes;
  i: Integer;
  t0, t1: Int64;
  g: IGHash;
begin
  // prepare inputs
  SetLength(H, 16); FillSeq(H, 7);
  SetLength(AAD, aadLen); if aadLen > 0 then FillSeq(AAD, 11);
  SetLength(C,   cLen);   if cLen   > 0 then FillSeq(C,   19);

  // save and set env
  SaveEnv('FAFAFA_GHASH_IMPL', oldImpl);
  SaveEnv('FAFAFA_GHASH_PURE_MODE', oldMode);
  SaveEnv('FAFAFA_GHASH_USE_EXPERIMENTAL', oldExp);
  try
    if Impl <> '' then SetEnv('FAFAFA_GHASH_IMPL', Impl);
    if PureMode <> '' then SetEnv('FAFAFA_GHASH_PURE_MODE', PureMode);
    if EnableExp then SetEnv('FAFAFA_GHASH_USE_EXPERIMENTAL', '1');

    // warmup
    g := CreateGHash; g.Init(H); if aadLen>0 then g.Update(AAD); if cLen>0 then g.Update(C);
    Tag := g.Finalize(Length(AAD), Length(C));

    // bench
    t0 := NowUS;
    for i := 1 to iters do
    begin
      g := CreateGHash; g.Init(H); if aadLen>0 then g.Update(AAD); if cLen>0 then g.Update(C);
      Tag := g.Finalize(Length(AAD), Length(C));
    end;
    t1 := NowUS;
    outUS := t1 - t0;
  finally
    RestoreEnv('FAFAFA_GHASH_USE_EXPERIMENTAL', oldExp);
    RestoreEnv('FAFAFA_GHASH_PURE_MODE', oldMode);
    RestoreEnv('FAFAFA_GHASH_IMPL', oldImpl);
  end;
end;

procedure PrintThroughput(const LabelName: String; bytesTotal: Int64; dtUS: Int64);
var dtSec, mibps: Double;
begin
  if dtUS <= 0 then Exit;
  dtSec := dtUS / 1000000.0;
  if dtSec <= 0 then Exit;
  mibps := (bytesTotal / 1048576.0) / dtSec;
  WriteLn(Format('%s: %.1f MiB/s (%d bytes in %.3f s)',
    [LabelName, mibps, bytesTotal, dtSec]));
end;

procedure TTestCase_GHash_BenchSizesSweep.Bench_Sizes_Sweep_PureByte_And_CLMUL;
const
  // small / medium / large
  AAD_SIZES: array[0..2] of Integer = (0, 1024, 64*1024);
  CT_SIZES:  array[0..3] of Integer = (1024, 16*1024, 256*1024, 1024*1024);
var
  env: String; verbose: Boolean; sI: String;
  iters: Integer;
  ai, ci: Integer; aadLen, cLen: Integer;
  dtPure, dtClmul: Int64;
  totalBytes: Int64;
begin
  iters := 4;
  // allow override via env
  sI := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_ITERS');
  if (sI <> '') then try iters := StrToInt(sI); except end;
  env := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_VERBOSE');
  verbose := (env <> '') and (env <> '0');

  for ai := 0 to High(AAD_SIZES) do
  begin
    for ci := 0 to High(CT_SIZES) do
    begin
      aadLen := AAD_SIZES[ai]; cLen := CT_SIZES[ci];
      dtPure := 0; dtClmul := 0;

      // pure-byte
      BenchOnce('pure', 'byte', False, aadLen, cLen, iters, dtPure);
      {$IFDEF RUN_BENCH_ASSERTS}
      AssertTrue(dtPure > 0);
      {$ENDIF}

      // clmul-requested (Debug 下自动启用实验开关；Release 按宏选择)
      BenchOnce('clmul', '', True, aadLen, cLen, iters, dtClmul);
      {$IFDEF RUN_BENCH_ASSERTS}
      AssertTrue(dtClmul > 0);
      {$ENDIF}

      if verbose then
      begin
        totalBytes := (Int64(aadLen) + Int64(cLen)) * Int64(iters);
        WriteLn(Format('Sizes: AAD=%d, C=%d (iters=%d)', [aadLen, cLen, iters]));
        PrintThroughput('  GHASH pure-byte', totalBytes, dtPure);
        PrintThroughput('  GHASH clmul-requested', totalBytes, dtClmul);
      end;
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_GHash_BenchSizesSweep);

end.

