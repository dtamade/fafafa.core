{$CODEPAGE UTF8}
unit Test_ghash_precompute_coldstart_bench;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF}
  fafafa.core.math,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_PrecomputeColdstartBench = class(TTestCase)
  published
    procedure Bench_PureByte_Coldstart_vs_Reused;
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
  for i := 0 to High(B) do B[i] := Seed + i;
end;

procedure TTestCase_GHash_PrecomputeColdstartBench.Bench_PureByte_Coldstart_vs_Reused;
  // enable per-H cache to highlight reuse benefit

  // note: env enabling of per-H cache removed to avoid Windows unit dependency in Release build tests


var
  env: String; verbose: Boolean; useMedian: Boolean;
  H, A, C, Tag: TBytes;
  g: IGHash; i: Integer;
  t0, t1: Int64; coldUS, reuseUS: Int64; arr: array[0..2] of Int64; tmp: Int64; j: Integer;
  bytesTotal: Int64; dtSec, mibps: Double; sfx: string;
begin
  env := SysUtils.GetEnvironmentVariable('FAFAFA_BENCH_VERBOSE');
  verbose := (env <> '') and (env <> '0');
  useMedian := (env = '2');

  // inputs
  SetLength(H, 16); FillSeq(H, 7);
  SetLength(A, 32*1024); FillSeq(A, 11);
  SetLength(C, 128*1024); FillSeq(C, 19);

  // force pure-byte
  {$IFDEF MSWINDOWS}
  Windows.SetEnvironmentVariable('FAFAFA_GHASH_IMPL', 'pure');
  Windows.SetEnvironmentVariable('FAFAFA_GHASH_PURE_MODE', 'byte');
  {$ELSE}
  setenv('FAFAFA_GHASH_IMPL', 'pure', 1);
  setenv('FAFAFA_GHASH_PURE_MODE', 'byte', 1);
  {$ENDIF}

  // coldstart: new context, first run builds tables
  if useMedian then
  begin
    for j := 0 to 2 do
    begin
      g := CreateGHash; g.Init(H); t0 := NowUS; g.Update(A); g.Update(C); Tag := g.Finalize(Length(A), Length(C)); t1 := NowUS; arr[j] := t1 - t0;
    end;
    // sort and pick median
    if arr[0] > arr[1] then begin tmp := arr[0]; arr[0] := arr[1]; arr[1] := tmp; end;
    if arr[1] > arr[2] then begin tmp := arr[1]; arr[1] := arr[2]; arr[2] := tmp; end;
    if arr[0] > arr[1] then begin tmp := arr[0]; arr[0] := arr[1]; arr[1] := tmp; end;
    coldUS := arr[1];
  end
  else
  begin
    g := CreateGHash; g.Init(H); t0 := NowUS; g.Update(A); g.Update(C); Tag := g.Finalize(Length(A), Length(C)); t1 := NowUS; coldUS := t1 - t0;
  end;

  // reused: reuse same context to avoid rebuild
  g := CreateGHash; g.Init(H);
  if useMedian then
  begin
    for j := 0 to 2 do
    begin
      t0 := NowUS; g.Update(A); g.Update(C); Tag := g.Finalize(Length(A), Length(C)); t1 := NowUS; arr[j] := t1 - t0;
    end;
    // sort
    if arr[0] > arr[1] then begin tmp := arr[0]; arr[0] := arr[1]; arr[1] := tmp; end;
    if arr[1] > arr[2] then begin tmp := arr[1]; arr[1] := arr[2]; arr[2] := tmp; end;
    if arr[0] > arr[1] then begin tmp := arr[0]; arr[0] := arr[1]; arr[1] := tmp; end;
    reuseUS := arr[1];
  end
  else
  begin
    t0 := NowUS; g.Update(A); g.Update(C); Tag := g.Finalize(Length(A), Length(C)); t1 := NowUS; reuseUS := t1 - t0;
  end;

  if verbose then
  begin
    bytesTotal := Length(A) + Length(C);
    sfx := '';
    if useMedian then sfx := ' [median of 3]';
    dtSec := coldUS / 1000000.0; if dtSec>0 then begin mibps := (bytesTotal/1048576.0)/dtSec; WriteLn(Format('GHASH pure-byte coldstart: %.1f MiB/s (%d bytes in %.3f s)%s',[mibps, bytesTotal, dtSec, sfx])); end;
    dtSec := reuseUS / 1000000.0; if dtSec>0 then begin mibps := (bytesTotal/1048576.0)/dtSec; WriteLn(Format('GHASH pure-byte reused:    %.1f MiB/s (%d bytes in %.3f s)%s',[mibps, bytesTotal, dtSec, sfx])); end;
  end;

  // basic sanity
  AssertTrue(coldUS > 0);
  AssertTrue(reuseUS > 0);
end;

initialization
  RegisterTest(TTestCase_GHash_PrecomputeColdstartBench);

end.

