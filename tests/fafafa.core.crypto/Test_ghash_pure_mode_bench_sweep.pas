{$CODEPAGE UTF8}
unit Test_ghash_pure_mode_bench_sweep;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF}
  fafafa.core.math,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_PureMode_BenchSweep = class(TTestCase)
  published
    procedure Bench_Sweep_PureModes;
  end;

implementation

{$IFNDEF MSWINDOWS}
function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external 'c' name 'setenv';
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

procedure RunOnce(const Mode: String; const iters: Integer; var outUS: Int64);
var
  H, AAD, C, Tag: TBytes;
  i: Integer;
  t0, t1: Int64;
  g: IGHash;
begin
  // prepare buffers
  SetLength(H, 16); FillSeq(H, 7);
  SetLength(AAD, 64*1024); FillSeq(AAD, 11);
  SetLength(C,   256*1024); FillSeq(C,   19);

  // set mode (DEBUG 构建下生效)
  {$IFDEF MSWINDOWS}
  Windows.SetEnvironmentVariable('FAFAFA_GHASH_PURE_MODE', PChar(Mode));
  {$ELSE}
  setenv('FAFAFA_GHASH_PURE_MODE', PChar(Mode), 1);
  {$ENDIF}

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
end;

procedure TTestCase_GHash_PureMode_BenchSweep.Bench_Sweep_PureModes;
var
  modes: array[0..2] of String = ('bit','nibble','byte');
  i, iters: Integer; dt: Int64;
  env: String; vlevel: Integer;
  totalBytes: Int64; dtSec, mibps: Double;
  dts: array[0..2] of Int64; j: Integer; tmp: Int64; sI: String; suffix: String;
begin
  iters := 6;
  // allow override via env

  sI := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_ITERS');
  if (sI <> '') then try iters := StrToInt(sI); except end;
  env := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_VERBOSE');
  if (env = '') or (env = '0') then vlevel := 0
  else if env = '2' then vlevel := 2
  else vlevel := 1;

  for i := 0 to High(modes) do
  begin
    if vlevel >= 2 then suffix := ' [median of 3]' else suffix := '';
    if vlevel >= 2 then
    begin
      for j := 0 to 2 do begin RunOnce(modes[i], iters, dts[j]); AssertTrue(dts[j] > 0); end;
      // sort 3 values
      if dts[0] > dts[1] then begin tmp := dts[0]; dts[0] := dts[1]; dts[1] := tmp; end;
      if dts[1] > dts[2] then begin tmp := dts[1]; dts[1] := dts[2]; dts[2] := tmp; end;
      if dts[0] > dts[1] then begin tmp := dts[0]; dts[0] := dts[1]; dts[1] := tmp; end;
      dt := dts[1];
    end
    else
    begin
      RunOnce(modes[i], iters, dt);
      AssertTrue(dt > 0);
    end;

    if vlevel >= 1 then
    begin
      totalBytes := (Int64(64*1024) + Int64(256*1024)) * Int64(iters);
      dtSec := dt / 1000000.0;
      if dtSec > 0 then
      begin
        mibps := (totalBytes / 1048576.0) / dtSec;
        WriteLn(Format('GHASH pure-%s: %.1f MiB/s (%d bytes in %.3f s, iters=%d)%s',
          [modes[i], mibps, totalBytes, dtSec, iters, suffix]));
      end;
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_GHash_PureMode_BenchSweep);

end.

