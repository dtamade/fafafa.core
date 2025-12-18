{$CODEPAGE UTF8}
unit Test_ghash_precomp_bench;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.crypto,
  fafafa.core.crypto.aead.gcm.ghash; // IGHash, CreateGHash

type
  TTestCase_GHash_Precomp_Bench = class(TTestCase)
  published
    procedure Bench_GHash_Pure_Precomp_vs_Baseline;
  end;

implementation

function NowInMicroseconds: Int64;
begin
  Result := Trunc(Now * 24*60*60*1000*1000);
end;

procedure FillBytes(var B: TBytes; Seed: Byte);
var i: Integer;
begin
  for i := 0 to High(B) do B[i] := Seed + i;
end;

procedure TTestCase_GHash_Precomp_Bench.Bench_GHash_Pure_Precomp_vs_Baseline;
var
  H, AAD, C, Tag: TBytes;
  i, iters: Integer;
  t0, t1: Int64;
  ghash: IGHash;
  env: String; verbose: Boolean;
  totalBytes: Int64; dtSec, mibps: Double;
begin
  // 64 KiB AAD + 256 KiB CT = 常见体量
  SetLength(H, 16); FillBytes(H, 7);
  SetLength(AAD, 64*1024); FillBytes(AAD, 11);
  SetLength(C,   256*1024); FillBytes(C,   19);
  iters := 8; // 重复多次降低抖动

  // 先热身
  for i := 1 to 2 do begin
    ghash := CreateGHash; ghash.Init(H); ghash.Update(AAD); ghash.Update(C); Tag := ghash.Finalize(Length(AAD), Length(C));
  end;

  // 计时：多次 GHASH（不做严格统计，仅确认路径可跑通且耗时>0）
  t0 := NowInMicroseconds;
  for i := 1 to iters do begin
    ghash := CreateGHash; ghash.Init(H); ghash.Update(AAD); ghash.Update(C); Tag := ghash.Finalize(Length(AAD), Length(C));
  end;
  t1 := NowInMicroseconds;

  AssertTrue(t1 - t0 > 0);

  // 可选：当设置 FAFAFA_BENCH_VERBOSE 时输出简单吞吐
  env := GetEnvironmentVariable('FAFAFA_BENCH_VERBOSE');
  verbose := (env <> '') and (env <> '0');
  if verbose then
  begin
    totalBytes := (Int64(Length(AAD)) + Int64(Length(C))) * Int64(iters);
    dtSec := (t1 - t0) / 1000000.0;
    if dtSec > 0 then
    begin
      mibps := (totalBytes / 1048576.0) / dtSec;
      WriteLn(Format('GHASH pure-precomp: %.1f MiB/s (%d bytes in %.3f s, iters=%d)',
        [mibps, totalBytes, dtSec, iters]));
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_GHash_Precomp_Bench);

end.

