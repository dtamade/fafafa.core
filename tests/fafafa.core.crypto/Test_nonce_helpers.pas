{$CODEPAGE UTF8}
unit Test_nonce_helpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.utils;

type
  { TTestCase_Nonce_Helpers }
  TTestCase_Nonce_Helpers = class(TTestCase)
  published
    procedure Test_ComposeGCMNonce12_BigEndianLayout;
    procedure Test_GenerateNonce12_LengthAndLowCollision;
  end;

implementation

function BytesToHex(const B: TBytes): string;
const HEX: array[0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
var i: Integer;
begin
  SetLength(Result, Length(B)*2);
  for i := 0 to High(B) do
  begin
    Result[i*2+1] := HEX[(B[i] shr 4) and $F];
    Result[i*2+2] := HEX[B[i] and $F];
  end;
end;

procedure TTestCase_Nonce_Helpers.Test_ComposeGCMNonce12_BigEndianLayout;
var N: TBytes; inst: UInt32; ctr: UInt64;
begin
  inst := $01020304; // big-endian => 01 02 03 04
  ctr := UInt64($0A0B0C0D0E0F1011); // big-endian
  N := ComposeGCMNonce12(inst, ctr);
  AssertEquals('len', 12, Length(N));
  // instance
  AssertEquals(1, N[0]);
  AssertEquals(2, N[1]);
  AssertEquals(3, N[2]);
  AssertEquals(4, N[3]);
  // counter
  AssertEquals($0A, N[4]);
  AssertEquals($0B, N[5]);
  AssertEquals($0C, N[6]);
  AssertEquals($0D, N[7]);
  AssertEquals($0E, N[8]);
  AssertEquals($0F, N[9]);
  AssertEquals($10, N[10]);
  AssertEquals($11, N[11]);
end;

procedure TTestCase_Nonce_Helpers.Test_GenerateNonce12_LengthAndLowCollision;
const K = 256; // small sample to keep test fast
var i, j: Integer; H: TStringList; n: TBytes; hex: string;
begin
  H := TStringList.Create;
  try
    H.Sorted := True;
    H.Duplicates := dupError;
    for i := 1 to K do
    begin
      n := GenerateNonce12;
      AssertEquals('len', 12, Length(n));
      hex := BytesToHex(n);
      // 插入排序表，若有重复会抛出异常，测试失败
      H.Add(hex);
    end;
    // 粗略检查：样本量 K 下不应出现重复（极小概率）
    AssertEquals('unique count', K, H.Count);
  finally
    H.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Nonce_Helpers);

end.

