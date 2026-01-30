{$CODEPAGE UTF8}
unit fafafa.core.crypto.xxhash.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto, fafafa.core.crypto.hash.xxhash32;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateXXH32_Defaults;
    procedure Test_XXH32_OneShot_vs_Streaming;
    procedure Test_XXH32_Seed_Changes_Output;
    procedure Test_XXH32_Slicing_Equivalence;
    procedure Test_XXH32_Empty_Vector;
  end;

implementation

function StringToBytes(const S: string): TBytes;
begin
  SetLength(Result, Length(S));
  if Length(S) > 0 then Move(S[1], Result[0], Length(S));
end;

procedure TTestCase_Global.Test_CreateXXH32_Defaults;
var H: IHashAlgorithm;
begin
  H := CreateXXH32; // seed=0
  AssertNotNull('instance', H);
  AssertEquals('digest=4', 4, H.DigestSize);
  AssertEquals('block=16', 16, H.BlockSize);
  AssertEquals('name', 'XXH32', H.Name);
  H.Burn;
end;

procedure TTestCase_Global.Test_XXH32_OneShot_vs_Streaming;
var Data: TBytes; H: IHashAlgorithm; A,B: TBytes;
begin
  Data := StringToBytes('The quick brown fox jumps over the lazy dog');
  A := XXH32Hash(Data, 0);
  H := CreateXXH32(0);
  if Length(Data) > 0 then H.Update(Data[0], Length(Data));
  B := H.Finalize;
  AssertEquals('oneshot==streaming', BytesToHex(A), BytesToHex(B));
end;

procedure TTestCase_Global.Test_XXH32_Seed_Changes_Output;
var Data: TBytes; A,B: TBytes;
begin
  Data := StringToBytes('seed check');
  A := XXH32Hash(Data, 0);
  B := XXH32Hash(Data, 1234567890);
  AssertFalse('different seeds -> different digest (very likely)', BytesToHex(A) = BytesToHex(B));
end;

procedure TTestCase_Global.Test_XXH32_Slicing_Equivalence;
var
  Data: TBytes;
  H: IHashAlgorithm;
  B1, B2: TBytes;
  i: Integer;
  off, step, n: Integer;
  Slices: array[0..4] of Integer = (1,2,3,7,16);
begin
  Data := StringToBytes('abcdefghijklmnopqrstuvwxyz0123456789');
  B1 := XXH32Hash(Data, 0);
  for i := 0 to High(Slices) do
  begin
    H := CreateXXH32(0);
    // 分片更新
    if Length(Data) > 0 then
    begin
      off := 0; step := Slices[i];
      while off < Length(Data) do
      begin
        n := step; if off + n > Length(Data) then n := Length(Data) - off;
        H.Update(Data[off], n);
        Inc(off, n);
      end;
    end;
    B2 := H.Finalize;
    AssertEquals('slice size ' + IntToStr(Slices[i]), BytesToHex(B1), BytesToHex(B2));
  end;
end;

procedure TTestCase_Global.Test_XXH32_Empty_Vector;
var D: TBytes; H: TBytes;
begin
  // XXH32("", seed=0) known value
  SetLength(D, 0);
  H := XXH32Hash(D, 0);
  AssertEquals('xxh32("")', '02cc5d05', BytesToHex(H));
end;

initialization
  RegisterTest(TTestCase_Global);
end.

