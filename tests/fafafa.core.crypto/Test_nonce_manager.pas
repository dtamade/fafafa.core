{$CODEPAGE UTF8}
unit Test_nonce_manager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto;

type
  { TTestCase_NonceManager }
  TTestCase_NonceManager = class(TTestCase)
  published
    procedure Test_NextGCMNonce12_MonotonicAndLayout;
    procedure Test_GenerateUniqueRandomNonce12_NoDuplicates_SmallSample;
    procedure Test_SeenAndAdd_Semantics;
  end;

implementation

procedure TTestCase_NonceManager.Test_NextGCMNonce12_MonotonicAndLayout;
var
  NM: INonceManager;
  N1, N2: TBytes;
begin
  NM := CreateNonceManager($01020304, 0);
  N1 := NM.NextGCMNonce12;
  N2 := NM.NextGCMNonce12;
  AssertEquals('len1', 12, Length(N1));
  AssertEquals('len2', 12, Length(N2));
  // 布局检查：前4字节 = 实例ID，后8字节为计数器（大端）
  AssertEquals(1, N1[0]); AssertEquals(2, N1[1]); AssertEquals(3, N1[2]); AssertEquals(4, N1[3]);
  AssertEquals(0, N1[4]); AssertEquals(0, N1[5]); AssertEquals(0, N1[6]); AssertEquals(0, N1[7]);
  AssertEquals(0, N1[8]); AssertEquals(0, N1[9]); AssertEquals(0, N1[10]); AssertEquals(0, N1[11]);
  AssertEquals(1, N2[11]); // 计数器自增，末字节从 0x00 -> 0x01
end;

procedure TTestCase_NonceManager.Test_GenerateUniqueRandomNonce12_NoDuplicates_SmallSample;
const K = 128;
var
  i: Integer; NM: INonceManager; S: TStringList; hex: string; n: TBytes;

  function BytesToHex(const B: TBytes): string;
  const HEX: array[0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  var j: Integer;
  begin
    SetLength(Result, Length(B)*2);
    for j := 0 to High(B) do
    begin
      Result[j*2+1] := HEX[(B[j] shr 4) and $F];
      Result[j*2+2] := HEX[B[j] and $F];
    end;
  end;
begin
  NM := CreateNonceManager(0, 0, 256);
  S := TStringList.Create;
  try
    S.Sorted := True;
    S.Duplicates := dupError;
    for i := 1 to K do
    begin
      n := NM.GenerateUniqueRandomNonce12;
      AssertEquals('len', 12, Length(n));
      hex := BytesToHex(n);
      S.Add(hex);
    end;
    AssertEquals('unique count', K, S.Count);
  finally
    S.Free;
  end;
end;

procedure TTestCase_NonceManager.Test_SeenAndAdd_Semantics;
var
  NM: INonceManager; N: TBytes; Already: Boolean;
begin
  NM := CreateNonceManager;
  SetLength(N, 12);
  FillChar(N[0], 12, 0);
  Already := NM.SeenAndAdd(N);
  AssertFalse('first time', Already);
  Already := NM.SeenAndAdd(N);
  AssertTrue('second time should be seen', Already);
end;

initialization
  RegisterTest(TTestCase_NonceManager);

end.

