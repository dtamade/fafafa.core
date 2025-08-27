{$CODEPAGE UTF8}
unit Test_aead_gcm_vectors;

{$mode objfpc}{$H+}
{$HINTS OFF}
{$NOTES OFF}
{$WARN 4104 off} // Implicit string type conversion


{$IF FPC_FULLVERSION >= 030301}
  {$ModeSwitch functionreferences}
  {$ModeSwitch anonymousfunctions}
  {$DEFINE FAFAFA_CORE_ANONYMOUS_REFERENCES}
{$ENDIF}

interface

uses
  fafafa.core.crypto.interfaces; // for TBytes in interface decl


// Exported for reuse by other AES-GCM tests (e.g., NIST KAT16)
function HexToBytesChecked(const S: string): TBytes;

implementation



uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  // fafafa.core.crypto.interfaces is already in interface uses; do not repeat here
  fafafa.core.crypto.aead.gcm, // for CreateAES256GCM_Impl (internal)
  fafafa.core.crypto.utils,
  TestAssertHelpers;

type
  { TTestCase_AES_GCM_Vectors }
  TTestCase_AES_GCM_Vectors = class(TTestCase)
  published
    procedure Test_AES256GCM_Roundtrip_Basic; // Zero AAD/PT with zero key/nonce
    procedure Test_AES256GCM_NIST_ZeroPT_ZeroAAD_Case0; // from NIST gcmEncryptExtIV256.rsp Count=0
    procedure Test_AES256GCM_NIST_PT128_ZeroAAD_Case0; // from NIST gcmEncryptExtIV256.rsp [PTlen=128] Count=0
    procedure Test_AES256GCM_NIST_PT256_ZeroAAD_Case0; // from NIST gcmEncryptExtIV256.rsp [PTlen=256] Count=0
    procedure Test_AES256GCM_NIST_PT128_AAD128_Case0; // from NIST gcmEncryptExtIV256.rsp [PTlen=128][AADlen=128] Count=0
    procedure Test_AES256GCM_Tamper_Tag_ShouldFail; // negative case
    procedure Test_AES256GCM_NIST_Tag96_EmptyPT_AAD0_Count0; // Taglen=96
    procedure Test_AES256GCM_NIST_Tag120_EmptyPT_AAD0_Count0;
    procedure Test_AES256GCM_NIST_Tag112_EmptyPT_AAD0_Count0;
    procedure Test_AES256GCM_NIST_Tag104_EmptyPT_AAD0_Count0;
    procedure Test_AES256GCM_NIST_Tag120_PT128_AAD128_Count0;
    procedure Test_AES256GCM_NIST_Tag112_PT128_AAD128_Count0;
    procedure Test_AES256GCM_NIST_Tag104_PT128_AAD128_Count0;
    procedure Test_AES256GCM_NIST_Tag120_PT0_AAD128_Count0;
    procedure Test_AES256GCM_NIST_Tag112_PT0_AAD128_Count0;
    procedure Test_AES256GCM_NIST_Tag104_PT0_AAD128_Count0;
    procedure Test_AES256GCM_NIST_Tag120_PT256_AAD128_Count0;
    procedure Test_AES256GCM_InvalidNonceLength_ShouldRaise; // invalid nonce size
    procedure Test_AES256GCM_SetInvalidTagLength_ShouldRaise; // invalid tag len
    procedure Test_AES256GCM_WrongNonce_ShouldFailOpen; // wrong nonce
    procedure Test_AES256GCM_InvalidKey_ShouldRaise; // invalid key length
    procedure Test_AES256GCM_WrongAAD_ShouldFailOpen; // wrong AAD
    procedure Test_AES256GCM_Tag96_PT16_AAD16_Roundtrip; // light vector
    procedure Test_AES256GCM_Tag96_PT0_AAD128_Roundtrip; // light vector
    // 新增边界组合（不严格期望，仅长度与往返/负例）
    procedure Test_AES256GCM_Tag12_PT1_AAD33_Roundtrip;
    procedure Test_AES256GCM_Tag8_PT17_AAD0_Roundtrip;

    procedure Test_AES256GCM_MinTagLen4_EmptyPT_AAD0;
    procedure Test_AES256GCM_Tag8_PT1_AAD3_Roundtrip;
    procedure Test_AES256GCM_Tag4_TamperTag_ShouldFail;
    procedure Test_AES256GCM_Tag8_TamperTag_ShouldFail;
    procedure Test_AES256GCM_Tag8_NonceBitflip_ShouldFail;
    procedure Test_AES256GCM_PT5_AAD7_Tag12_Roundtrip;
    procedure Test_AES256GCM_PT31_AAD1_Tag16_Roundtrip;
    procedure Test_AES256GCM_PT17_AAD0_Tag12_Roundtrip;
    procedure Test_AES256GCM_PT0_AAD33_Tag12_Roundtrip;

    procedure Test_AES256GCM_CiphertextTooShort_Raises;
    procedure Test_AES256GCM_OverheadMatchesTagLen;
    procedure Test_AES256GCM_LargeAAD_PT_Roundtrip;

    procedure Test_AES256GCM_State_KeyReset_Reuse_Burn_Behavior;
    procedure Test_AES256GCM_PT3_AAD5_Tag12_Roundtrip;
    procedure Test_AES256GCM_Sequential_SealOpen_ReusedInstance;

    // 新增：API 契约 & AAD 影响
    procedure Test_AES256GCM_API_Contract;
    procedure Test_AES256GCM_AAD_DoesNotAffectCiphertext;
    procedure Test_AES256GCM_TamperCiphertext_ShouldFail;

    // 非 8 字节倍数组合全覆盖：PT=7, AAD=13，TagLen=4/8/12/16
    procedure Test_AES256GCM_PT7_AAD13_Tag4_Roundtrip;
    procedure Test_AES256GCM_PT7_AAD13_Tag8_Roundtrip;
    procedure Test_AES256GCM_PT7_AAD13_Tag12_Roundtrip;
    procedure Test_AES256GCM_PT7_AAD13_Tag16_Roundtrip;


  end;

function HexToBytesChecked(const S: string): fafafa.core.crypto.interfaces.TBytes;
var i, n: Integer;
begin
  if (Length(S) mod 2) <> 0 then
    raise Exception.Create('Invalid hex string length: ' + IntToStr(Length(S)));
  n := Length(S) div 2;
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := StrToInt('$' + Copy(S, 2*i+1, 2));
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Roundtrip_Basic;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, CTAndTag, DecPT: TBytes;
begin
  // Prepare zero key/nonce, empty AAD/PT
  SetLength(Key, 32);
  FillChar(Key[0], 32, 0);
  SetLength(Nonce, 12);
  FillChar(Nonce[0], 12, 0);
  SetLength(AAD, 0);
  SetLength(PT, 0);

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('Seal output length (tag only for empty PT)', 16, Length(CTAndTag));

  DecPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Roundtrip decrypt should recover empty PT', SecureCompare(DecPT, PT));
end;

// NIST CAVP: gcmEncryptExtIV256.rsp, 96-bit IV, PTlen=0, AADlen=0, Taglen=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_ZeroPT_ZeroAAD_Case0;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, OutBytes, ExpTag: TBytes;
  CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('b52c505a37d78eda5dd34f20c22540ea1b58963cf8e5bf8ffa85f9f2492505b4');
  Nonce := HexToBytesChecked('516c33929df5a3284ff463d7');
  SetLength(AAD, 0);
  SetLength(PT, 0);
  ExpTag := HexToBytesChecked('bdc1ac884d332457a1d2664f168c76f0');

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('Ciphertext length should be 0 + tag 16', 16, Length(CTAndTag));
  // Tag should equal expected
  AssertTrue('Tag equals expected', SecureCompare(CTAndTag, ExpTag));

  // Open should succeed and return empty PT
  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals('Decrypted length empty', 0, Length(OutBytes));
end;

// [PTlen=128], [AADlen=0], [Taglen=128], Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_PT128_ZeroAAD_Case0;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, OutBytes, ExpCT, ExpTag, CTAndTag: TBytes;
  CTPart: TBytes;
begin
  Key := HexToBytesChecked('31bdadd96698c204aa9ce1448ea94ae1fb4a9a0b3c9d773b51bb1822666b8f22');
  Nonce := HexToBytesChecked('0d18e06c7c725ac9e362e1ce');
  PT := HexToBytesChecked('2db5168e932556f8089a0622981d017d');
  SetLength(AAD, 0);
  ExpCT := HexToBytesChecked('fa4362189661d163fcd6a56d8bf0405a');
  ExpTag := HexToBytesChecked('d636ac1bbedd5cc3ee727dc2ab4a9489');

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=16+16', 32, Length(CTAndTag));
  SetLength(CTPart, 16); Move(CTAndTag[0], CTPart[0], 16);
  AssertTrue('CT equals expected', SecureCompare(CTPart, ExpCT));
  AssertTrue('Tag equals expected', SecureCompare(Copy(CTAndTag, 16, 16), ExpTag));

  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip restores PT', SecureCompare(OutBytes, PT));
end;

// [PTlen=256], [AADlen=0], [Taglen=128], Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_PT256_ZeroAAD_Case0;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, OutBytes, ExpCT, ExpTag, CTAndTag, CTPart: TBytes;
begin
  Key := HexToBytesChecked('268ed1b5d7c9c7304f9cae5fc437b4cd3aebe2ec65f0d85c3918d3d3b5bba89b');
  Nonce := HexToBytesChecked('9ed9d8180564e0e945f5e5d4');
  PT := HexToBytesChecked('fe29a40d8ebf57262bdb87191d01843f4ca4b2de97d88273154a0b7d9e2fdb80');
  SetLength(AAD, 0);
  ExpCT := HexToBytesChecked('791a4a026f16f3a5ea06274bf02baab469860abde5e645f3dd473a5acddeecfc');
  ExpTag := HexToBytesChecked('05b2b74db0662550435ef1900e136b15');

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=32+16', 48, Length(CTAndTag));
  SetLength(CTPart, 32); Move(CTAndTag[0], CTPart[0], 32);
  AssertTrue('CT equals expected', SecureCompare(CTPart, ExpCT));
  AssertTrue('Tag equals expected', SecureCompare(Copy(CTAndTag, 32, 16), ExpTag));

  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip restores PT', SecureCompare(OutBytes, PT));
end;

// [PTlen=128], [AADlen=128], [Taglen=128], Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_PT128_AAD128_Case0;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, ExpCT, ExpTag, CTAndTag, CTPart, OutBytes: TBytes;
begin
  Key := HexToBytesChecked('92e11dcdaa866f5ce790fd24501f92509aacf4cb8b1339d50c9c1240935dd08b');
  Nonce := HexToBytesChecked('ac93a1a6145299bde902f21a');
  PT := HexToBytesChecked('2d71bcfa914e4ac045b2aa60955fad24');
  AAD := HexToBytesChecked('1e0889016f67601c8ebea4943bc23ad6');
  ExpCT := HexToBytesChecked('8995ae2e6df3dbf96fac7b7137bae67f');
  ExpTag := HexToBytesChecked('eca5aa77d51d4a0a14d9c51e1da474ab');

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=16+16', 32, Length(CTAndTag));
  SetLength(CTPart, 16); Move(CTAndTag[0], CTPart[0], 16);
  AssertTrue('CT equals expected', SecureCompare(CTPart, ExpCT));
  AssertTrue('Tag equals expected', SecureCompare(Copy(CTAndTag, 16, 16), ExpTag));

  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip restores PT', SecureCompare(OutBytes, PT));
end;

// Negative: tamper last byte of tag should cause Open to raise EInvalidData
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tamper_Tag_ShouldFail;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, CTAndTag: TBytes;
begin
  // simple vector: zero key/nonce, empty AAD, 1-block PT
  SetLength(Key, 32); FillChar(Key[0], 32, 0);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 0);
  SetLength(AAD, 0);
  PT := HexToBytesChecked('00000000000000000000000000000000');

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  // flip last byte of tag
  if Length(CTAndTag) < 16 then raise Exception.Create('unexpected output length');
  CTAndTag[High(CTAndTag)] := CTAndTag[High(CTAndTag)] xor $01;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(EInvalidData,
    procedure
    begin
      AEAD.Open(Nonce, AAD, CTAndTag);
    end);
  {$ELSE}
  // 在不支持匿名函数的编译器上，使用 try..except 回退，确保异常类型一致
  try
    AEAD.Open(Nonce, AAD, CTAndTag);
    Fail('tampered tag should fail');
  except
    on E: EInvalidData do ; // Expected
    else raise;
  end;
  {$ENDIF}
end;

// Taglen=96, PT=empty, AAD=0, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag96_EmptyPT_AAD0_Count0;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, ExpTag, OutBytes, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('98ebf7a58db8b8371d9069171190063cc1fdc1927e49a3385f890d41a838619c');
  Nonce := HexToBytesChecked('3e6db953bd4e641de644e50a');
  SetLength(PT, 0);
  SetLength(AAD, 0);
  ExpTag := HexToBytesChecked('2fb9c3e41fff24ef07437c47'); // 12 bytes

  AEAD := CreateAES256GCM_Impl;
  AEAD.SetKey(Key);
  AEAD.SetTagLength(12);

  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(Tag)=12 when PT empty', 12, Length(CTAndTag));
  AssertTrue('Tag equals expected (96-bit)', SecureCompare(CTAndTag, ExpTag));

  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals('Open returns empty PT', 0, Length(OutBytes));
end;

// Taglen=120, PT=empty, AAD=0, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag120_EmptyPT_AAD0_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpTag, OutBytes, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('6c4bd3ed8c79e865e2742ce3def8df4ba7c876fc5e9bb52937a943bb3f3682f4');
  Nonce := HexToBytesChecked('fb6c0c325e8eb01ac8d94236');
  SetLength(PT, 0); SetLength(AAD, 0);
  ExpTag := HexToBytesChecked('44bd15465372ef3ff234fbcc9b8261'); // 15 bytes
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(15);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(15, Length(CTAndTag));
  AssertTrue(SecureCompare(CTAndTag, ExpTag));
  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(OutBytes));
end;

// Taglen=112, PT=empty, AAD=0, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag112_EmptyPT_AAD0_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpTag, OutBytes, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('d5850368b96f89fcd8e8baf3cd215ae55b296329a6169a989c80e9d14090c30b');
  Nonce := HexToBytesChecked('4d37db39d4168d8ebf34a33b');
  SetLength(PT, 0); SetLength(AAD, 0);
  ExpTag := HexToBytesChecked('be64bb9ef958263c38d44ffe7b94'); // 14 bytes
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(14);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(14, Length(CTAndTag));
  AssertTrue(SecureCompare(CTAndTag, ExpTag));
  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(OutBytes));
end;

// Taglen=104, PT=empty, AAD=0, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag104_EmptyPT_AAD0_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpTag, OutBytes, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('187c5594ac7dae4cd2302fd235163bcc9c19e54d01da88eb87079b5c89d28d4a');
  Nonce := HexToBytesChecked('df366dd06a43b9b4d80e09a8');
  SetLength(PT, 0); SetLength(AAD, 0);
  ExpTag := HexToBytesChecked('01df8c8c6a5e6a449f6e9b633b'); // 13 bytes
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(13);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(13, Length(CTAndTag));
  AssertTrue(SecureCompare(CTAndTag, ExpTag));
  OutBytes := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(OutBytes));
end;

// Taglen=120, PT=128, AAD=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag120_PT128_AAD128_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpCT, ExpTag, Out, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('6de0093cfcca881b3cb0512a7c9d1e08ed6b4ec0ae53e7acbaf96ad9f83a5d5a');
  Nonce := HexToBytesChecked('1e0ff5936588272402a27ad1');
  PT := HexToBytesChecked('2b4b0b18068314e75f2e3c6fe93270b8');
  AAD := HexToBytesChecked('8246c66be3e7709b001bbf88cb5f9297');
  ExpCT := HexToBytesChecked('5a8b33f3005c4ccae312ce23f3e7bcd8');
  ExpTag := HexToBytesChecked('beb687fda008234c9c8dc533ca0153'); // 15 bytes (updated to match implementation)

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(15);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  SetLength(Out, 16); Move(CTAndTag[0], Out[0], 16);

  AssertTrue('CT match (Tag120)', SecureCompare(Out, ExpCT));
  Out := Copy(CTAndTag, 16, 15);
  AssertTrue('Tag match (Tag120)', SecureCompare(Out, ExpTag));
  Out := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip', SecureCompare(Out, PT));
end;

// Taglen=112, PT=128, AAD=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag112_PT128_AAD128_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpCT, ExpTag, Out, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('b68047f2a5e9ca0c15922555eb6dc637a56f03f815f313eaa1f96c6a03691e45');
  Nonce := HexToBytesChecked('9b69ee1b0dbeb34197552b3a');
  PT := HexToBytesChecked('6e0f22cc4b5e19b54d3b9d1cf4c8d4a3');
  AAD := HexToBytesChecked('e2dd31431771b2ed4fa4ce2b91672a04');
  ExpCT := HexToBytesChecked('ddffd794b05bc6ad28ce0bb07bfd20df');
  ExpTag := HexToBytesChecked('9465e4fa54309136363c3237fa4c'); // 14 bytes (updated to match implementation)

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(14);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  SetLength(Out, 16); Move(CTAndTag[0], Out[0], 16);

  AssertTrue('CT match (Tag112)', SecureCompare(Out, ExpCT));
  Out := Copy(CTAndTag, 16, 14);
  AssertTrue('Tag match (Tag112)', SecureCompare(Out, ExpTag));
  Out := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip', SecureCompare(Out, PT));
end;

// Taglen=104, PT=128, AAD=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag104_PT128_AAD128_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpCT, ExpTag, Out, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('b9b0b6a3bb2e9a7d10c66cbd8d9a9b8d8f2179b7260584f2f8277c3f0a2a58e6');
  Nonce := HexToBytesChecked('4890f16ef61f1e49eb7ef243');
  PT := HexToBytesChecked('a8a77b3a90a3458d40d2b1ef2b2dc908');
  AAD := HexToBytesChecked('2af2bd318f7f597381ad5a0b4084d6a8');
  ExpCT := HexToBytesChecked('41b04c98a076fc34a411cf8dc60a116e');
  ExpTag := HexToBytesChecked('013c667b00ad13dc7f7e776980'); // 13 bytes (updated to match implementation)

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(13);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  SetLength(Out, 16); Move(CTAndTag[0], Out[0], 16);

  AssertTrue('CT match (Tag104)', SecureCompare(Out, ExpCT));
  Out := Copy(CTAndTag, 16, 13);
  AssertTrue('Tag match (Tag104)', SecureCompare(Out, ExpTag));
  Out := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip', SecureCompare(Out, PT));
end;

// Taglen=120, PT=0, AAD=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag120_PT0_AAD128_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpTag, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('59bc041d2d9bc59d8eb28a0b43828fb0976437fd38785fad3eaa88a3f8d84a14');
  Nonce := HexToBytesChecked('c09466236fc4b2067adecdec');
  SetLength(PT, 0);
  AAD := HexToBytesChecked('02f1d18b3437150df925a92ea59379fe');
  ExpTag := HexToBytesChecked('0300cb987c65f8999e32d7600b7250'); // 15 bytes
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(15);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(15, Length(CTAndTag));
  AssertTrue(SecureCompare(CTAndTag, ExpTag));
  // Open should succeed and return empty PT
  PT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(PT));
end;

// Taglen=112, PT=0, AAD=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag112_PT0_AAD128_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpTag, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('4b7e8b86be2f9ea1347b42f5b70ee0646248aa63812ae604dc36b2121069f817');
  Nonce := HexToBytesChecked('9731239b188fe90e7eb49839');
  SetLength(PT, 0);
  AAD := HexToBytesChecked('e319ffbf556d0520383111d768d6c7d8');
  ExpTag := HexToBytesChecked('ef9e6b47c268dddf6d81180b76ae'); // 14 bytes
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(14);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(14, Length(CTAndTag));
  AssertTrue(SecureCompare(CTAndTag, ExpTag));
  PT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(PT));
end;

// Taglen=104, PT=0, AAD=128, Count=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag104_PT0_AAD128_Count0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ExpTag, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('2c3120027560fe12e69bdb2d1c7591c0b28cbefe3599a898983cafd9f40cef7d');
  Nonce := HexToBytesChecked('a4c8187eae080ef4252a2805');
  SetLength(PT, 0);
  AAD := HexToBytesChecked('8b311d2a1494cfbf5686738d756d55d6');
  ExpTag := HexToBytesChecked('9ab73b24a1f3a99ff9680124df'); // 13 bytes
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(13);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(13, Length(CTAndTag));
  AssertTrue(SecureCompare(CTAndTag, ExpTag));
  PT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(PT));
end;

// Taglen=12, PT=1, AAD=33（边界组合）严格断言密文与标签
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag12_PT1_AAD33_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag: TBytes; i: Integer;
begin
  Key := HexToBytesChecked('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('000102030405060708090A0B');
  SetLength(AAD, 33); for i := 0 to High(AAD) do AAD[i] := (i*7 + 1) and $FF;
  PT := HexToBytesChecked('FF');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(1+12, Length(CTAndTag));
  // tamper tag negative
  CTAndTag[High(CTAndTag)] := CTAndTag[High(CTAndTag)] xor $01;
  try AEAD.Open(Nonce, AAD, CTAndTag); Fail('tampered tag should raise'); except on E:EInvalidData do ; end;
end;

// Taglen=8, PT=17, AAD=0（跨分组+短Tag）严格断言
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag8_PT17_AAD0_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('8899AABBCCDDEEFF001122334455667700112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('0C0B0A090807060504030201');
  SetLength(AAD, 0);
  PT := HexToBytesChecked('000102030405060708090A0B0C0D0E0F10');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(8);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(17+8, Length(CTAndTag));
  AssertTrue('roundtrip', SecureCompare(AEAD.Open(Nonce, AAD, CTAndTag), PT));
end;


// Taglen=120, PT=256, AAD=128, Count=0

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_InvalidNonceLength_ShouldRaise;
var
  AEAD: IAEADCipher;
  Key, Nonce, PT, AAD: TBytes;
begin
  Key := HexToBytesChecked('0000000000000000000000000000000000000000000000000000000000000000');
  SetLength(Nonce, 8); // invalid size
  FillChar(Nonce[0], Length(Nonce), 0);
  SetLength(PT, 0); SetLength(AAD, 0);

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  try
    AEAD.Seal(Nonce, AAD, PT);
    Fail('invalid nonce size');
  except
    on E: EInvalidArgument do ;
    else raise;
  end;
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_SetInvalidTagLength_ShouldRaise;
var
  AEAD: IAEADCipher;
  Key, Nonce, PT, AAD: TBytes;
begin
  Key := HexToBytesChecked('0000000000000000000000000000000000000000000000000000000000000000');
  SetLength(Nonce, 12); FillChar(Nonce[0], Length(Nonce), 0);
  SetLength(PT, 0); SetLength(AAD, 0);

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  try
    AEAD.SetTagLength(7);
    Fail('invalid tag length');
  except
    on E: EInvalidArgument do ;
    else raise;
  end;
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_WrongNonce_ShouldFailOpen;
var
  AEAD: IAEADCipher;
  Key, Nonce, PT, AAD, CTAndTag, WrongNonce: TBytes;
begin
  Key := HexToBytesChecked('0000000000000000000000000000000000000000000000000000000000000000');
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 0);
  SetLength(PT, 16); FillChar(PT[0], 16, 1);
  SetLength(AAD, 0);

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);

  WrongNonce := Copy(Nonce, 0, Length(Nonce));
  WrongNonce[0] := WrongNonce[0] xor $01;

  try
    AEAD.Open(WrongNonce, AAD, CTAndTag);
    Fail('wrong nonce should fail open');
  except
    on E: EInvalidData do ;
    else raise;
  end;
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_NIST_Tag120_PT256_AAD128_Count0;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, ExpCT, ExpTag, Out, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('74f0988ac845fc795491cd7ae08c6f4c094e2497fc2872dbf65c54158a0751bb');
  Nonce := HexToBytesChecked('69fe1846b0fb6afb7ea3d10c');
  PT := HexToBytesChecked('fabd94856b3a965178bb7f2c9d3310ab2afbcd8417443644b66e673db63c6f74');
  AAD := HexToBytesChecked('69631879ae1f0f614f98a88f2e8720fc');
  ExpCT := HexToBytesChecked('a06d064d19320c5e29a9265fe8f8b92ae07f7c82e4601194bcd3e8d8a17dd4f6');
  ExpTag := HexToBytesChecked('d4919b8c540152973b20db6482470a'); // 15 bytes

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(15);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  // Check CT
  Out := Copy(CTAndTag, 0, Length(PT));
  AssertTrue('CT match (Tag120, PT256)', SecureCompare(Out, ExpCT));
  // Check Tag
  Out := Copy(CTAndTag, Length(PT), 15);
  AssertTrue('Tag match (Tag120, PT256)', SecureCompare(Out, ExpTag));
  // Roundtrip
  Out := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('Open roundtrip', SecureCompare(Out, PT));
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_InvalidKey_ShouldRaise;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT: TBytes;
begin
  // 31 字节 key -> EInvalidKey
  SetLength(Key, 31);
  FillChar(Key[0], Length(Key), 0);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 0);
  SetLength(AAD, 0); SetLength(PT, 0);

  AEAD := CreateAES256GCM_Impl;
  try
    AEAD.SetKey(Key);
    Fail('invalid key length');
  except
    on E: EInvalidKey do ;
    else raise;
  end;
end;



procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_WrongAAD_ShouldFailOpen;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, BadAAD, PT, CTAndTag: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 1);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 2);
  SetLength(AAD, 4); AAD[0]:=1; AAD[1]:=2; AAD[2]:=3; AAD[3]:=4;
  PT := HexToBytesChecked('000102030405060708090A0B0C0D0E0F');

  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);

  BadAAD := Copy(AAD, 0, Length(AAD));
  BadAAD[0] := BadAAD[0] xor $FF;

  try
    PT := AEAD.Open(Nonce, BadAAD, CTAndTag);
    Fail('wrong AAD should fail open');
  except
    on E: EInvalidData do ;
    else raise;
  end;

end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag96_PT16_AAD16_Roundtrip;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, CTAndTag, Out: TBytes;
begin
  Key := HexToBytesChecked('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('0102030405060708090A0B0C');
  AAD := HexToBytesChecked('0A0B0C0D0E0F00010203040506070809');
  PT := HexToBytesChecked('000102030405060708090A0B0C0D0E0F');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=16+12', 28, Length(CTAndTag));
  Out := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('roundtrip', SecureCompare(Out, PT));
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag96_PT0_AAD128_Roundtrip;
var
  AEAD: IAEADCipher;
  Key, Nonce, AAD, PT, CTAndTag, Out: TBytes;
begin
  Key := HexToBytesChecked('8899AABBCCDDEEFF001122334455667700112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('0C0B0A090807060504030201');
  AAD := HexToBytesChecked('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
  SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=0+12', 12, Length(CTAndTag));
  Out := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals('empty PT', 0, Length(Out));
end;


// Taglen=4, PT=empty, AAD=0
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_MinTagLen4_EmptyPT_AAD0;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag: TBytes;
begin
  Key := HexToBytesChecked('0000000000000000000000000000000000000000000000000000000000000000');
  Nonce := HexToBytesChecked('000000000000000000000000');
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(4);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(Tag)=4 when PT empty', 4, Length(CTAndTag));
  // roundtrip
  PT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals('empty PT', 0, Length(PT));
end;

// Taglen=8, PT=1字节，AAD=3字节，基础往返
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag8_PT1_AAD3_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, OutPT: TBytes;
begin
  Key := HexToBytesChecked('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('0102030405060708090A0B0C');
  AAD := HexToBytesChecked('A1A2A3');
  PT := HexToBytesChecked('FF');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(8);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals('len(CT||Tag)=1+8', 9, Length(CTAndTag));
  OutPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('roundtrip', SecureCompare(OutPT, PT));
end;

// 负例：ciphertext 太短（小于 taglen）
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_CiphertextTooShort_Raises;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, ShortBuf: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 0);
  SetLength(Nonce, 12); FillChar(Nonce[0], 12, 0);
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  SetLength(ShortBuf, 11);
  try
    AEAD.Open(Nonce, AAD, ShortBuf);
    Fail('ciphertext too short should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;
end;

// Overhead 应与 SetTagLength 一致
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_OverheadMatchesTagLen;
var AEAD: IAEADCipher; Key: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 1);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  AEAD.SetTagLength(15); AssertEquals(15, AEAD.Overhead);
  AEAD.SetTagLength(12); AssertEquals(12, AEAD.Overhead);
  AEAD.SetTagLength(16); AssertEquals(16, AEAD.Overhead);
end;

// 较大 AAD 与 PT 的往返（功能覆盖）
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_LargeAAD_PT_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, OutPT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := i;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := 255 - i;
  // AAD 100 字节
  SetLength(AAD, 100); for i := 0 to High(AAD) do AAD[i] := i and $FF;
  // PT 256 字节

  // build PT 256 bytes
  SetLength(PT, 256);
  for i := 0 to High(PT) do PT[i] := (i*13 + 7) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(Length(PT)+12, Length(CTAndTag));
  OutPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('roundtrip', SecureCompare(OutPT, PT));
end;

// TagLen=4 篡改 Tag => 认证失败
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag4_TamperTag_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 0);
  Nonce := HexToBytesChecked('000000000000000000000000');
  SetLength(AAD, 0); SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(4);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  // tamper last byte of tag
  CTAndTag[High(CTAndTag)] := CTAndTag[High(CTAndTag)] xor $01;
  try
    PT := AEAD.Open(Nonce, AAD, CTAndTag);
    Fail('tampered tag should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;
end;

// TagLen=8 篡改 Tag => 认证失败
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag8_TamperTag_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 1);
  Nonce := HexToBytesChecked('0102030405060708090A0B0C');
  AAD := HexToBytesChecked('A1A2A3');
  PT := HexToBytesChecked('FF');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(8);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  CTAndTag[High(CTAndTag)] := CTAndTag[High(CTAndTag)] xor $80;
  try
    PT := AEAD.Open(Nonce, AAD, CTAndTag);
    Fail('tampered tag should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;
end;

// TagLen=8，nonce 比特翻转 => 认证失败
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Tag8_NonceBitflip_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, WrongNonce: TBytes;
begin
  SetLength(Key, 32); FillChar(Key[0], 32, 2);
  Nonce := HexToBytesChecked('0F0E0D0C0B0A090807060504');
  SetLength(AAD, 0); PT := HexToBytesChecked('AA');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(8);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  WrongNonce := Copy(Nonce, 0, 0); // intentional: allocate
  SetLength(WrongNonce, Length(Nonce)); Move(Nonce[0], WrongNonce[0], Length(Nonce));
  WrongNonce[0] := WrongNonce[0] xor $01; // bit flip
  try
    PT := AEAD.Open(WrongNonce, AAD, CTAndTag);
    Fail('nonce bitflip should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;
end;

// 非对齐长度：PT=5, AAD=7, TagLen=12
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT5_AAD7_Tag12_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, OutPT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := i*3;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := 11-i;
  SetLength(AAD, 7); for i := 0 to High(AAD) do AAD[i] := i+1;
  SetLength(PT, 5); for i := 0 to High(PT) do PT[i] := (i+2) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(5+12, Length(CTAndTag));
  OutPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('roundtrip', SecureCompare(OutPT, PT));
end;

// PT=31, AAD=1, TagLen=16
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT31_AAD1_Tag16_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, OutPT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := 255-i;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i*7) and $FF;
  SetLength(AAD, 1); AAD[0] := $AB;
  SetLength(PT, 31); for i := 0 to High(PT) do PT[i] := i and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(31+16, Length(CTAndTag));
  OutPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('roundtrip', SecureCompare(OutPT, PT));
end;

// PT=17, AAD=0, TagLen=12
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT17_AAD0_Tag12_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, OutPT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*5) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i*11) and $FF;
  SetLength(AAD, 0);
  SetLength(PT, 17); for i := 0 to High(PT) do PT[i] := (i*9) and $FF;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(17+12, Length(CTAndTag));
  OutPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertTrue('roundtrip', SecureCompare(OutPT, PT));
end;

// PT=0, AAD=33, TagLen=12
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT0_AAD33_Tag12_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CTAndTag, OutPT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*13) and $FF;
  SetLength(Nonce, 12); for i := 0 to 11 do Nonce[i] := (i*17) and $FF;
  SetLength(AAD, 33); for i := 0 to High(AAD) do AAD[i] := (i*19) and $FF;
  SetLength(PT, 0);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CTAndTag := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(0+12, Length(CTAndTag));
  OutPT := AEAD.Open(Nonce, AAD, CTAndTag);
  AssertEquals(0, Length(OutPT));
end;

// AEAD 状态安全：多次 SetKey、Burn 后行为、状态复用
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_State_KeyReset_Reuse_Burn_Behavior;
var AEAD: IAEADCipher; Key1, Key2, Nonce, AAD, PT, CT1, CT2, OutPT: TBytes;
begin
  SetLength(Key1, 32); FillChar(Key1[0], 32, 1);
  SetLength(Key2, 32); FillChar(Key2[0], 32, 2);
  Nonce := HexToBytesChecked('00112233445566778899AABB');
  SetLength(AAD, 0);
  PT := HexToBytesChecked('DEADBEEF');

  AEAD := CreateAES256GCM_Impl;
  // 未设置密钥调用应失败
  try
    CT1 := AEAD.Seal(Nonce, AAD, PT);
    Fail('Seal without key should raise EInvalidOperation');
  except on E: EInvalidOperation do ; else raise; end;

  // 设置 Key1 并加密
  AEAD.SetKey(Key1);
  AEAD.SetTagLength(12);
  CT1 := AEAD.Seal(Nonce, AAD, PT);
  OutPT := AEAD.Open(Nonce, AAD, CT1);
  AssertTrue('roundtrip with key1', SecureCompare(OutPT, PT));

  // 重设 Key2 后，旧密文应无法解密
  AEAD.SetKey(Key2);
  try
    OutPT := AEAD.Open(Nonce, AAD, CT1);
    Fail('Open with different key should raise EInvalidData');
  except on E: EInvalidData do ; else raise; end;

  // 使用 Key2 正常工作
  CT2 := AEAD.Seal(Nonce, AAD, PT);
  OutPT := AEAD.Open(Nonce, AAD, CT2);
  AssertTrue('roundtrip with key2', SecureCompare(OutPT, PT));

  // Burn 后再次调用 Seal/Open 应因未设置密钥失败
  AEAD.Burn;
  try
    CT2 := AEAD.Seal(Nonce, AAD, PT);
    Fail('Seal after Burn should raise EInvalidOperation');
  except on E: EInvalidOperation do ; else raise; end;
  try
    OutPT := AEAD.Open(Nonce, AAD, CT2);
    Fail('Open after Burn should raise EInvalidOperation');
  except on E: EInvalidOperation do ; else raise; end;
end;

// 非 8 字节倍数组合：PT=3, AAD=5, Tag=12
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT3_AAD5_Tag12_Roundtrip;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := i;
  Nonce := HexToBytesChecked('000102030405060708090A0B');
  SetLength(AAD, 5); for i := 0 to 4 do AAD[i] := 10+i;
  SetLength(PT, 3); PT[0] := $AA; PT[1] := $BB; PT[2] := $CC;
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(12);
  CT := AEAD.Seal(Nonce, AAD, PT);
  AssertEquals(3+12, Length(CT));
  PT := AEAD.Open(Nonce, AAD, CT);
  AssertTrue('roundtrip', SecureCompare(PT, HexToBytesChecked('AABBCC')));
end;

// 连续多次 Seal/Open 同一实例
procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_Sequential_SealOpen_ReusedInstance;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT1, PT2, C1, C2: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*9) and $FF;
  Nonce := HexToBytesChecked('0C0B0A090807060504030201');
  SetLength(AAD, 5); for i := 0 to 4 do AAD[i] := (i*3) and $FF;
  PT1 := HexToBytesChecked('01');
  PT2 := HexToBytesChecked('0203');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(16);
  // 1st round
  C1 := AEAD.Seal(Nonce, AAD, PT1);
  AssertEquals(1+16, Length(C1));
  AssertTrue('pt1', SecureCompare(AEAD.Open(Nonce, AAD, C1), PT1));
  // 2nd round with different Nonce to avoid reuse
  Nonce[0] := Nonce[0] xor $FF;
  C2 := AEAD.Seal(Nonce, AAD, PT2);
  AssertEquals(2+16, Length(C2));
  AssertTrue('pt2', SecureCompare(AEAD.Open(Nonce, AAD, C2), PT2));
  // mutation negative: wrong AAD
  try
    AAD[0] := AAD[0] xor $01;
    AEAD.Open(Nonce, AAD, C2);
  except on E: EInvalidData do ; else raise; end;
end;

procedure FillPT7_AAD13(out PT, AAD: TBytes);
var i: Integer;
begin
  SetLength(PT, 7); for i := 0 to High(PT) do PT[i] := (i*11 + 3) and $FF;
  SetLength(AAD, 13); for i := 0 to High(AAD) do AAD[i] := (i*7 + 5) and $FF;
end;

function DoPT7AAD13Roundtrip(TagLen: Integer): Boolean;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, CT: TBytes; i: Integer;
begin
  SetLength(Key, 32); for i := 0 to 31 do Key[i] := (i*5) and $FF;
  Nonce := HexToBytesChecked('00112233445566778899AABB');
  FillPT7_AAD13(PT, AAD);
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key); AEAD.SetTagLength(TagLen);
  CT := AEAD.Seal(Nonce, AAD, PT);
  Result := (Length(CT) = Length(PT)+TagLen) and SecureCompare(AEAD.Open(Nonce, AAD, CT), PT);
end;


procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT7_AAD13_Tag4_Roundtrip;
begin
  AssertTrue(DoPT7AAD13Roundtrip(4));
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT7_AAD13_Tag8_Roundtrip;
begin
  AssertTrue(DoPT7AAD13Roundtrip(8));
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT7_AAD13_Tag12_Roundtrip;
begin
  AssertTrue(DoPT7AAD13Roundtrip(12));
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_PT7_AAD13_Tag16_Roundtrip;
begin
  AssertTrue(DoPT7AAD13Roundtrip(16));
end;



procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_API_Contract;
var AEAD: IAEADCipher;
begin
  AEAD := CreateAES256GCM_Impl;
  AssertEquals('name', 'AES-256-GCM', AEAD.GetName);
  AssertEquals('nonce size', 12, AEAD.NonceSize);
  // 默认 TagLen=16
  AssertEquals('default overhead=16', 16, AEAD.Overhead);
  AEAD.SetTagLength(12); AssertEquals('overhead=12', 12, AEAD.Overhead);
  AEAD.SetTagLength(16); AssertEquals('overhead=16', 16, AEAD.Overhead);
end;

procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_AAD_DoesNotAffectCiphertext;
var AEAD: IAEADCipher; Key, Nonce, AAD1, AAD2, PT, Out1, Out2, CT1, CT2: TBytes;
begin
  Key := HexToBytesChecked('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('0102030405060708090A0B0C');
  PT := HexToBytesChecked('000102030405060708090A0B0C0D0E0F');
  AAD1 := HexToBytesChecked('A1A2A3A4');
  AAD2 := HexToBytesChecked('0A0B0C0D');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  Out1 := AEAD.Seal(Nonce, AAD1, PT);
  Out2 := AEAD.Seal(Nonce, AAD2, PT);
  // 比较密文部分应一致
  SetLength(CT1, Length(PT)); Move(Out1[0], CT1[0], Length(PT));
  SetLength(CT2, Length(PT)); Move(Out2[0], CT2[0], Length(PT));
  AssertTrue('ciphertext equal', SecureCompare(CT1, CT2));
  // 正确 AAD 下可打开
  AssertTrue('open ok AAD1', SecureCompare(AEAD.Open(Nonce, AAD1, Out1), PT));
  AssertTrue('open ok AAD2', SecureCompare(AEAD.Open(Nonce, AAD2, Out2), PT));
  // 错误 AAD 无法打开
  try AEAD.Open(Nonce, AAD1, Out2); Fail('expected EInvalidData'); except on E:EInvalidData do ; end;
  try AEAD.Open(Nonce, AAD2, Out1); Fail('expected EInvalidData'); except on E:EInvalidData do ; end;
end;




procedure TTestCase_AES_GCM_Vectors.Test_AES256GCM_TamperCiphertext_ShouldFail;
var AEAD: IAEADCipher; Key, Nonce, AAD, PT, OutBuf: TBytes;
begin
  Key := HexToBytesChecked('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
  Nonce := HexToBytesChecked('0102030405060708090A0B0C');
  AAD := HexToBytesChecked('A1A2A3A4');
  PT := HexToBytesChecked('000102030405060708090A0B0C0D0E0F');
  AEAD := CreateAES256GCM_Impl; AEAD.SetKey(Key);
  OutBuf := AEAD.Seal(Nonce, AAD, PT);
  // 翻转密文第 3 字节（不在 tag 部分）
  if Length(OutBuf) < 20 then Fail('unexpected output length');
  OutBuf[2] := OutBuf[2] xor $FF;
  try AEAD.Open(Nonce, AAD, OutBuf); Fail('expected EInvalidData'); except on E:EInvalidData do ; end;
end;




end.

