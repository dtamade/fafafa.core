{$CODEPAGE UTF8}
unit Test_ghash_update_chunked_equivalence;

{$mode objfpc}{$H+}

{$PUSH}{$HINTS OFF 5091}{$HINTS OFF 5093}
interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash,
  fafafa.core.crypto.interfaces;

type
  TTestCase_GHASH_Update_Chunked = class(TTestCase)
  published
    procedure Test_Update_Chunked_Equals_Single;
  end;

implementation

procedure TTestCase_GHASH_Update_Chunked.Test_Update_Chunked_Equals_Single;
var
  GH1, GH2: IGHash;
  H, S1, S2, AAD, C: TBytes;
  AAD1, AAD2, C1, C2: TBytes;
  i: Integer;
begin
  // 随机但确定性数据
  SetLength(H, 16);
  for i := 0 to 15 do H[i] := (i * 19 + 5) and $FF;

  SetLength(AAD, 37);
  for i := 0 to High(AAD) do AAD[i] := (i * 7 + 3) and $FF;
  SetLength(C, 65);
  for i := 0 to High(C) do C[i] := (i * 11 + 9) and $FF;

  // 单次 Update
  GH1 := CreateGHash; GH1.Init(H);
  GH1.Update(AAD);
  GH1.Update(C);
  S1 := GH1.Finalize(Length(AAD), Length(C));

  // 分块 Update（不同切分点，覆盖非 16 对齐场景）
  SetLength(AAD1, 13); Move(AAD[0], AAD1[0], 13);
  SetLength(AAD2, Length(AAD) - 13); Move(AAD[13], AAD2[0], Length(AAD2));

  SetLength(C1, 33); Move(C[0], C1[0], 33);
  SetLength(C2, Length(C) - 33); Move(C[33], C2[0], Length(C2));

  GH2 := CreateGHash; GH2.Init(H);
  GH2.Update(AAD1);
  GH2.Update(AAD2);
  GH2.Update(C1);
  GH2.Update(C2);
  S2 := GH2.Finalize(Length(AAD), Length(C));

  AssertEquals('S length', 16, Length(S1));
  AssertEquals('S length', 16, Length(S2));
  AssertTrue('S1 == S2', CompareByte(S1[0], S2[0], 16) = 0);
end;

initialization
  RegisterTest(TTestCase_GHASH_Update_Chunked);

{$POP}
end.

