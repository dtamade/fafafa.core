{$CODEPAGE UTF8}
unit Test_ghash_warmup_smoke;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto;

type
  TTestCase_GHash_WarmUp_Smoke = class(TTestCase)
  published
    procedure Test_WarmUp_NoThrow_And_GCM_Consistency;
  end;

implementation

procedure TTestCase_GHash_WarmUp_Smoke.Test_WarmUp_NoThrow_And_GCM_Consistency;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, CT1, CT2: TBytes;
begin
  // Prepare inputs
  Key := HexToBytes('000102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F');
  Nonce := HexToBytes('00112233445566778899AABB');
  SetLength(AAD, 0);
  PT := HexToBytes('01020304');

  // First run (no explicit warmup)
  AEAD := CreateAES256GCM;
  AEAD.SetKey(Key);
  CT1 := AEAD.Seal(Nonce, AAD, PT);

  // Second run (new instance), implicitly triggers WarmUp inside Release builds
  AEAD := CreateAES256GCM;
  AEAD.SetKey(Key);
  CT2 := AEAD.Seal(Nonce, AAD, PT);

  // Consistency
  AssertEquals(Length(CT1), Length(CT2));
  if Length(CT1) <> 0 then
    AssertTrue(CompareByte(CT1[0], CT2[0], Length(CT1)) = 0);
end;

initialization
  RegisterTest(TTestCase_GHash_WarmUp_Smoke);

end.

