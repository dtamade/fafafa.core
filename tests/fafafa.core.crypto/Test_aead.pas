{$CODEPAGE UTF8}
unit Test_aead;

{$mode objfpc}{$H+}

{+
  AEAD tests skeleton for IAEADCipher (AES-256-GCM planned)
  - Disabled by default; enable with: -dFAFAFA_CORE_AEAD_TESTS
  - While implementation is pending, you can also define:
      -dFAFAFA_CORE_AEAD_EXPECT_NOTSUPPORTED
    to assert factory raises ENotSupported.
+}

interface

implementation

{$IFDEF FAFAFA_CORE_AEAD_TESTS}

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.utils, // for Hex helpers if needed
  TestAssertHelpers;

type
  { TTestCase_IAEADCipherVectors }
  TTestCase_IAEADCipherVectors = class(TTestCase)
  private
    procedure ExpectCreateAES256GCM;
  published
    procedure Test_AES256GCM_Vectors;
  end;

type
  TAEADVector = record
    Name: string;
    KeyHex: string;
    NonceHex: string;
    AADHex: string;
    PlainHex: string;
    CipherHex: string;
    TagHex: string;
  end;

// NOTE:
// - Fill with official AES-256-GCM vectors (NIST SP 800-38D/GCMVS KAT) before enabling functional assertions
// - These are placeholders; ExpectedCT assertions remain commented out until we wire real vectors
// References:
// - NIST SP 800-38D (GCM)
// - NIST CAVP GCMVS KAT files (AES-256, 96-bit IV)
// - RFC 5116, RFC 8439 (AEAD concepts)
const
  GCM_VECTORS: array[0..3] of TAEADVector = (
    (
      Name: 'NIST-PLACEHOLDER: Empty AAD, Empty PT (AES-256, 96-bit IV)';
      KeyHex: '0000000000000000000000000000000000000000000000000000000000000000';
      NonceHex: '000000000000000000000000';
      AADHex: '';
      PlainHex: '';
      CipherHex: '';
      TagHex: ''
    ),
    (
      Name: 'NIST-PLACEHOLDER: Empty AAD, 1-block PT (16 bytes zeros)';
      KeyHex: '0000000000000000000000000000000000000000000000000000000000000000';
      NonceHex: '000000000000000000000000';
      AADHex: '';
      PlainHex: '00000000000000000000000000000000';
      CipherHex: '';
      TagHex: ''
    ),
    (
      Name: 'NIST-PLACEHOLDER: Non-empty AAD (8 bytes), Empty PT';
      KeyHex: '0000000000000000000000000000000000000000000000000000000000000000';
      NonceHex: '000000000000000000000000';
      AADHex: '0001020304050607';
      PlainHex: '';
      CipherHex: '';
      TagHex: ''
    ),
    (
      Name: 'NIST-PLACEHOLDER: Non-empty AAD (12 bytes), Short PT (7 bytes)';
      KeyHex: '0000000000000000000000000000000000000000000000000000000000000000';
      NonceHex: '000000000000000000000000';
      AADHex: '000102030405060708090A0B';
      PlainHex: '11223344556677';
      CipherHex: '';
      TagHex: ''
    )
  );

procedure TTestCase_IAEADCipherVectors.ExpectCreateAES256GCM;
begin
  // This should raise until AES-256-GCM is implemented
  CreateAES256GCM;
end;

procedure TTestCase_IAEADCipherVectors.Test_AES256GCM_Vectors;
var
  AEAD: IAEADCipher;
  V: TAEADVector;
  I: Integer;
  Key, Nonce, AAD, Plain, OutCT, OutPT, ExpectedCT, Tag: TBytes;
begin
{$IFDEF FAFAFA_CORE_AEAD_EXPECT_NOTSUPPORTED}
  AssertException('AES-256-GCM not yet implemented', fafafa.core.crypto.ENotSupported,
    @Self.ExpectCreateAES256GCM);
{$ELSE}
  AEAD := CreateAES256GCM;
  // Functional path (requires real vectors); keep structure ready
  for I := Low(GCM_VECTORS) to High(GCM_VECTORS) do
  begin
    V := GCM_VECTORS[I];
    Key := fafafa.core.crypto.HexToBytes(V.KeyHex);
    Nonce := fafafa.core.crypto.HexToBytes(V.NonceHex);
    AAD := fafafa.core.crypto.HexToBytes(V.AADHex);
    Plain := fafafa.core.crypto.HexToBytes(V.PlainHex);

    AEAD.SetKey(Key);
    OutCT := AEAD.Seal(Nonce, AAD, Plain);

    // When vectors are filled:
    // ExpectedCT := fafafa.core.crypto.HexToBytes(V.CipherHex + V.TagHex);
    // AssertTrue(V.Name + ' cipher mismatch',
    //   fafafa.core.crypto.SecureCompare(OutCT, ExpectedCT));

    OutPT := AEAD.Open(Nonce, AAD, OutCT);
    AssertTrue(V.Name + ' decrypt roundtrip mismatch',
      fafafa.core.crypto.SecureCompare(OutPT, Plain));
  end;
{$ENDIF}
end;

initialization
  RegisterTest(TTestCase_IAEADCipherVectors);

{$ENDIF} // FAFAFA_CORE_AEAD_TESTS

end.

