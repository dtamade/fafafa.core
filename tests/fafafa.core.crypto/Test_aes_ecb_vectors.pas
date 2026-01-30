{$CODEPAGE UTF8}
unit Test_aes_ecb_vectors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto,
  fafafa.core.crypto.cipher.aes; // for CreateAES256

type
  TTestCase_AES_ECB = class(TTestCase)
  published
    procedure Test_AES128_ECB_NISTVectors;
    procedure Test_AES192_ECB_NISTVectors;
    procedure Test_AES256_ECB_NISTVectors;
  end;

implementation

uses fafafa.core.crypto.utils;

const
  // Common plaintext (SP 800-38A, 4 blocks)
  PT_HEX    = '6BC1BEE22E409F96E93D7E117393172A'
              + 'AE2D8A571E03AC9C9EB76FAC45AF8E51'
              + '30C81C46A35CE411E5FBC1191A0A52EF'
              + 'F69F2445DF4F9B17AD2B417BE66C3710';

  // AES-128 ECB (F.1.1)
  KEY128_HEX = '2B7E151628AED2A6ABF7158809CF4F3C';
  CT128_HEX  = '3AD77BB40D7A3660A89ECAF32466EF97'
               + 'F5D3D58503B9699DE785895A96FDBAAF'
               + '43B1CD7F598ECE23881B00E3ED030688'
               + '7B0C785E27E8AD3F8223207104725DD4';

  // AES-192 ECB (F.1.3)
  KEY192_HEX = '8E73B0F7DA0E6452C810F32B809079E5'
               + '62F8EAD2522C6B7B';
  CT192_HEX  = 'BD334F1D6E45F25FF712A214571FA5CC'
               + '974104846D0AD3AD7734ECB3ECEE4EEF'
               + 'EF7AFD2270E2E60ADCE0BA2FACE6444E'
               + '9A4B41BA738D6C72FB16691603C18E0E';

  // AES-256 ECB (F.1.5)
  KEY256_HEX = '603DEB1015CA71BE2B73AEF0857D7781'
               + '1F352C073B6108D72D9810A30914DFF4';
  CT256_HEX  = 'F3EED1BDB5D2A03C064B5A7E3DB181F8'
               + '591CCB10D410ED26DC5BA74A31362870'
               + 'B6ED21B99CA6F4F9F153E7B1BEAFED1D'
               + '23304B7A39F9F3FF067D8D8F9E24ECC7';

procedure TTestCase_AES_ECB.Test_AES128_ECB_NISTVectors;
var
  aes: ISymmetricCipher;
  key, pt, got: TBytes;
begin
  aes := CreateAES128;
  key := HexToBytes(KEY128_HEX);
  pt  := HexToBytes(PT_HEX);
  aes.SetKey(key);
  got := aes.Encrypt(pt);
  AssertEquals('AES-128 ECB NIST vector mismatch', UpperCase(CT128_HEX), UpperCase(BytesToHex(got)));
  got := aes.Decrypt(got);
  AssertEquals('AES-128 ECB decrypt mismatch', UpperCase(PT_HEX), UpperCase(BytesToHex(got)));
end;

procedure TTestCase_AES_ECB.Test_AES192_ECB_NISTVectors;
var
  aes: ISymmetricCipher;
  key, pt, got: TBytes;
begin
  aes := CreateAES192;
  key := HexToBytes(KEY192_HEX);
  pt  := HexToBytes(PT_HEX);
  aes.SetKey(key);
  got := aes.Encrypt(pt);
  AssertEquals('AES-192 ECB NIST vector mismatch', UpperCase(CT192_HEX), UpperCase(BytesToHex(got)));
  got := aes.Decrypt(got);
  AssertEquals('AES-192 ECB decrypt mismatch', UpperCase(PT_HEX), UpperCase(BytesToHex(got)));
end;

procedure TTestCase_AES_ECB.Test_AES256_ECB_NISTVectors;
var
  aes: ISymmetricCipher;
  key, pt, got: TBytes;
begin
  aes := CreateAES256;
  key := HexToBytes(KEY256_HEX);
  pt  := HexToBytes(PT_HEX);
  aes.SetKey(key);
  got := aes.Encrypt(pt);
  AssertEquals('AES-256 ECB NIST vector mismatch', UpperCase(CT256_HEX), UpperCase(BytesToHex(got)));
  got := aes.Decrypt(got);
  AssertEquals('AES-256 ECB decrypt mismatch', UpperCase(PT_HEX), UpperCase(BytesToHex(got)));
end;

initialization
  RegisterTest(TTestCase_AES_ECB);

end.

