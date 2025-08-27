unit fafafa.core.crypto.xxhash64.added;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, fpcunit, testregistry, fafafa.core.crypto;

type
  TTestCase_Global_XXH64 = class(TTestCase)
  published
    procedure Test_CreateXXH64_Defaults;
    procedure Test_XXH64_OneShot_vs_Streaming;
    procedure Test_XXH64_Slicing_Equivalence;
    procedure Test_XXH64_Empty_Vector;
  end;

implementation

function StringToBytes(const S: string): TBytes;
begin
  SetLength(Result, Length(S));
  if Length(S) > 0 then Move(S[1], Result[0], Length(S));
end;

procedure TTestCase_Global_XXH64.Test_CreateXXH64_Defaults;
var H: IHashAlgorithm;
begin
  H := CreateXXH64; // seed=0
  AssertNotNull('instance', H);
  AssertEquals(8, H.DigestSize);
  AssertEquals(32, H.BlockSize);
  AssertEquals('XXH64', H.Name);
  H.Burn;
end;

procedure TTestCase_Global_XXH64.Test_XXH64_OneShot_vs_Streaming;
var Data: TBytes; H: IHashAlgorithm; A,B: TBytes;
begin
  Data := StringToBytes('The quick brown fox jumps over the lazy dog');
  A := XXH64Hash(Data, 0);
  H := CreateXXH64(0);
  if Length(Data) > 0 then H.Update(Data[0], Length(Data));
  B := H.Finalize;
  AssertEquals(BytesToHex(A), BytesToHex(B));
end;

procedure TTestCase_Global_XXH64.Test_XXH64_Slicing_Equivalence;
var Data: TBytes; H: IHashAlgorithm; B1,B2: TBytes;
    i, off, step, n: Integer;
    Slices: array[0..4] of Integer = (1,2,3,7,32);
begin
  Data := StringToBytes('abcdefghijklmnopqrstuvwxyz0123456789');
  B1 := XXH64Hash(Data, 0);
  for i := 0 to High(Slices) do
  begin
    H := CreateXXH64(0);
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

procedure TTestCase_Global_XXH64.Test_XXH64_Empty_Vector;
var D: TBytes; H: TBytes;
begin
  // XXH64("", seed=0) known value: ef46db3751d8e999
  SetLength(D, 0);
  H := XXH64Hash(D, 0);


  AssertEquals('xxh64("")', 'ef46db3751d8e999', BytesToHex(H));
end;



initialization
  RegisterTest(TTestCase_Global_XXH64);
end.

