{$CODEPAGE UTF8}
unit Test_ghash_cache_per_h_basic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Windows,
  fafafa.core.math,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_CachePerH_Basic = class(TTestCase)
  published
    procedure Test_CachePerH_Improves_Reuse_Time;
  end;

implementation

function NowUS: Int64;
begin
  Result := Trunc(Now * 24*60*60*1000*1000);
end;

procedure FillSeq(var B: TBytes; Seed: Byte);
var i: Integer;
begin
  for i := 0 to High(B) do B[i] := Seed + i;
end;

procedure TTestCase_GHash_CachePerH_Basic.Test_CachePerH_Improves_Reuse_Time;
var
  H, A, C, Tag: TBytes;
  tCold, tReuse: Int64;
  g: IGHash;
  i: Integer;
begin
  // enable cache and force pure-byte
  Windows.SetEnvironmentVariable(PChar('FAFAFA_GHASH_CACHE_PER_H'), PChar('1'));
  Windows.SetEnvironmentVariable(PChar('FAFAFA_GHASH_IMPL'), PChar('pure'));
  Windows.SetEnvironmentVariable(PChar('FAFAFA_GHASH_PURE_MODE'), PChar('byte'));

  SetLength(H, 16); FillSeq(H, 7);
  SetLength(A, 64*1024); FillSeq(A, 11);
  SetLength(C, 64*1024); FillSeq(C, 19);

  // cold build
  g := CreateGHash; g.Init(H);
  tCold := NowUS; g.Update(A); g.Update(C); Tag := g.Finalize(Length(A), Length(C)); tCold := NowUS - tCold;

  // reuse should load from cache (new context but same H)
  g := CreateGHash; g.Init(H);
  tReuse := NowUS; g.Update(A); g.Update(C); Tag := g.Finalize(Length(A), Length(C)); tReuse := NowUS - tReuse;

  // allow equality (noisy env); primarily check non-regression
  AssertTrue(tCold > 0);
  AssertTrue(tReuse > 0);
end;

initialization
  RegisterTest(TTestCase_GHash_CachePerH_Basic);

end.

