{$CODEPAGE UTF8}
unit Test_aes_ctr_vectors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.bytes, // HexToBytes, BytesToHex
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto.cipher.aes.ctr,
  fafafa.core.crypto.utils;

type
  TBytes = fafafa.core.crypto.interfaces.TBytes;

  TTestCase_AES_CTR = class(TTestCase)
  published
    procedure Test_AES256_CTR_Roundtrip_Empty_Short_Long;
    procedure Test_AES128_CTR_Stream_Equivalence_Split;
    procedure Test_AES192_CTR_InvalidNonceLength_Raises;
    procedure Test_AES256_CTR_MustSetNonceBeforeProcess_Raises;
    procedure Test_AES128_CTR_Randomized_Splits_Equivalence;
    procedure Test_AES256_CTR_CrossCall_Boundary_Patterns;
  end;

implementation

procedure TTestCase_AES_CTR.Test_AES256_CTR_Roundtrip_Empty_Short_Long;
var
  ctr1, ctr2: IAESCTR;
  key, nonce, pt, ct, rt: TBytes;
begin
  key   := HexToBytes('000102030405060708090A0B0C0D0E0F' +
                      '101112131415161718191A1B1C1D1E1F');
  nonce := HexToBytes('000102030405060708090A0B'); // 12 bytes

  // case 1: empty
  ctr1 := CreateAESCTR(32);
  ctr1.SetKey(key);
  ctr1.SetNonceAndCounter(nonce, 1);
  SetLength(pt, 0);
  ct := ctr1.Process(pt);
  // decrypt with fresh instance (same params)
  ctr2 := CreateAESCTR(32);
  ctr2.SetKey(key);
  ctr2.SetNonceAndCounter(nonce, 1);
  rt := ctr2.Process(ct);
  AssertEquals('AES-256 CTR roundtrip(empty) mismatch', 0, Length(rt));

  // case 2: short (6 bytes)
  pt := HexToBytes('001122334455');
  ctr1 := CreateAESCTR(32);
  ctr1.SetKey(key);
  ctr1.SetNonceAndCounter(nonce, 1);
  ct := ctr1.Process(pt);
  ctr2 := CreateAESCTR(32);
  ctr2.SetKey(key);
  ctr2.SetNonceAndCounter(nonce, 1);
  rt := ctr2.Process(ct);
  AssertEquals('AES-256 CTR roundtrip(short) length', Length(pt), Length(rt));
  AssertTrue('AES-256 CTR roundtrip(short) content',
    UpperCase(BytesToHex(pt)) = UpperCase(BytesToHex(rt)));

  // case 3: long (40 bytes -> crosses block boundary)
  pt := HexToBytes('000102030405060708090A0B0C0D0E0F' +
                   '101112131415161718191A1B1C1D1E1F' +
                   '20212223');
  ctr1 := CreateAESCTR(32);
  ctr1.SetKey(key);
  ctr1.SetNonceAndCounter(nonce, 1);
  ct := ctr1.Process(pt);
  ctr2 := CreateAESCTR(32);
  ctr2.SetKey(key);
  ctr2.SetNonceAndCounter(nonce, 1);
  rt := ctr2.Process(ct);
  AssertEquals('AES-256 CTR roundtrip(long) length', Length(pt), Length(rt));
  AssertTrue('AES-256 CTR roundtrip(long) content',
    UpperCase(BytesToHex(pt)) = UpperCase(BytesToHex(rt)));
end;

procedure TTestCase_AES_CTR.Test_AES128_CTR_Stream_Equivalence_Split;
var
  ctrA, ctrB: IAESCTR;
  key, nonce, pt, p1, p2, outAll, outSplit, tmp: TBytes;
  split: Integer;
begin
  // AES-128 key and 12-byte nonce
  key   := HexToBytes('2B7E151628AED2A6ABF7158809CF4F3C');
  nonce := HexToBytes('F0F1F2F3F4F5F6F7F8F9FAFB');
  pt    := HexToBytes(
             // 64 bytes (4 blocks), reuse NIST ECB PT for convenience
             '6BC1BEE22E409F96E93D7E117393172A' +
             'AE2D8A571E03AC9C9EB76FAC45AF8E51' +
             '30C81C46A35CE411E5FBC1191A0A52EF' +
             'F69F2445DF4F9B17AD2B417BE66C3710');

  // Whole processing
  ctrA := CreateAESCTR(16);
  ctrA.SetKey(key);
  ctrA.SetNonceAndCounter(nonce, 1);
  outAll := ctrA.Process(pt);

  // Split processing should be equivalent (counter continues)
  split := 20; // arbitrary split not on block boundary
  SetLength(p1, split);
  Move(pt[0], p1[0], split);
  SetLength(p2, Length(pt) - split);
  if Length(p2) > 0 then Move(pt[split], p2[0], Length(p2));

  ctrB := CreateAESCTR(16);
  ctrB.SetKey(key);
  ctrB.SetNonceAndCounter(nonce, 1);
  outSplit := ctrB.Process(p1);
  tmp := ctrB.Process(p2);
  // concatenate
  if Length(tmp) > 0 then begin
    SetLength(outSplit, Length(outSplit) + Length(tmp));
    Move(tmp[0], outSplit[Length(outSplit) - Length(tmp)], Length(tmp));
  end;

  AssertEquals('AES-128 CTR split equivalence length', Length(outAll), Length(outSplit));
  AssertTrue('AES-128 CTR split equivalence content',
    UpperCase(BytesToHex(outAll)) = UpperCase(BytesToHex(outSplit)));

end;


procedure TTestCase_AES_CTR.Test_AES128_CTR_Randomized_Splits_Equivalence;
var
  ctrWhole, ctrSplit: IAESCTR;
  key, nonce, pt, outWhole, outPart, tmp: TBytes;
  totalLen, splitPos, step, pos, i: Integer;
begin
  // Fixed key/nonce; randomized lengths/steps are controlled but deterministic
  key   := HexToBytes('2B7E151628AED2A6ABF7158809CF4F3C');
  nonce := HexToBytes('F0F1F2F3F4F5F6F7F8F9FAFB');

  // Sweep a few payload sizes and split strategies
  for totalLen in [0, 1, 2, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129] do
  begin
    // prepare plaintext 0..(totalLen-1)
    SetLength(pt, totalLen);
    for i := 0 to totalLen - 1 do pt[i] := Byte(i and $FF);

    // whole output
    ctrWhole := CreateAESCTR(16);
    ctrWhole.SetKey(key);
    ctrWhole.SetNonceAndCounter(nonce, 1);
    outWhole := ctrWhole.Process(pt);

    // 1) two-way split at many positions
    for splitPos in [0, 1, 2, 15, 16, 17, 31, 32, totalLen] do
    begin
      if (splitPos < 0) or (splitPos > totalLen) then Continue;
      ctrSplit := CreateAESCTR(16);
      ctrSplit.SetKey(key);
      ctrSplit.SetNonceAndCounter(nonce, 1);

      // first chunk
      if splitPos > 0 then begin
        SetLength(tmp, splitPos);
        Move(pt[0], tmp[0], splitPos);
        outPart := ctrSplit.Process(tmp);
      end else SetLength(outPart, 0);

      // second chunk
      if splitPos < totalLen then begin
        SetLength(tmp, totalLen - splitPos);
        Move(pt[splitPos], tmp[0], totalLen - splitPos);
        tmp := ctrSplit.Process(tmp);
        if Length(tmp) > 0 then begin
          SetLength(outPart, Length(outPart) + Length(tmp));
          Move(tmp[0], outPart[Length(outPart) - Length(tmp)], Length(tmp));
        end;
      end;

      AssertEquals('AES-128 CTR two-way split length', Length(outWhole), Length(outPart));
      AssertTrue('AES-128 CTR two-way split content',
        UpperCase(BytesToHex(outWhole)) = UpperCase(BytesToHex(outPart)));
    end;

    // 2) iterative single/multi-byte steps (e.g., 1,3,5,... or 15,17,3,...) across boundaries
    for step in [1, 3, 5, 7, 15, 16, 17] do
    begin
      ctrSplit := CreateAESCTR(16);
      ctrSplit.SetKey(key);
      ctrSplit.SetNonceAndCounter(nonce, 1);
      SetLength(outPart, 0);

      pos := 0;
      while pos < totalLen do begin
        i := step;
        if pos + i > totalLen then i := totalLen - pos;
        SetLength(tmp, i);
        if i > 0 then Move(pt[pos], tmp[0], i);
        tmp := ctrSplit.Process(tmp);
        if Length(tmp) > 0 then begin
          SetLength(outPart, Length(outPart) + Length(tmp));
          Move(tmp[0], outPart[Length(outPart) - Length(tmp)], Length(tmp));
        end;
        Inc(pos, i);
      end;

      AssertEquals('AES-128 CTR stepped split length', Length(outWhole), Length(outPart));
      AssertTrue('AES-128 CTR stepped split content',
        UpperCase(BytesToHex(outWhole)) = UpperCase(BytesToHex(outPart)));
    end;
  end;
end;


procedure TTestCase_AES_CTR.Test_AES256_CTR_CrossCall_Boundary_Patterns;
var
  ctrAll, ctrStep: IAESCTR;
  key, nonce, pt, outAll, outStep, tmp: TBytes;
  chunks: array of Integer;
  i, pos, n, total: Integer;
begin
  // AES-256 key and 12-byte nonce
  key   := HexToBytes('000102030405060708090A0B0C0D0E0F' +
                      '101112131415161718191A1B1C1D1E1F');
  nonce := HexToBytes('000102030405060708090A0B');

  // Define sequences that straddle 16B boundaries heavily
  // Example patterns: [15,17,3,1,32,1], [16,16,16,1], [7,9,16,5,19]
  // We’ll generate a payload of the total length and then consume per pattern
  chunks := nil;
  SetLength(chunks, 6);
  chunks[0] := 15; chunks[1] := 17; chunks[2] := 3; chunks[3] := 1; chunks[4] := 32; chunks[5] := 1;

  total := 0; for i := 0 to High(chunks) do Inc(total, chunks[i]);
  SetLength(pt, total);
  for i := 0 to total - 1 do pt[i] := Byte((i * 7 + 3) and $FF);

  // Whole output
  ctrAll := CreateAESCTR(32);
  ctrAll.SetKey(key);
  ctrAll.SetNonceAndCounter(nonce, 1);
  outAll := ctrAll.Process(pt);

  // Chunked output per pattern
  ctrStep := CreateAESCTR(32);
  ctrStep.SetKey(key);
  ctrStep.SetNonceAndCounter(nonce, 1);
  SetLength(outStep, 0);

  pos := 0;
  for i := 0 to High(chunks) do begin
    n := chunks[i];
    if n <= 0 then Continue;
    SetLength(tmp, n);
    Move(pt[pos], tmp[0], n);
    tmp := ctrStep.Process(tmp);
    if Length(tmp) > 0 then begin
      SetLength(outStep, Length(outStep) + Length(tmp));
      Move(tmp[0], outStep[Length(outStep) - Length(tmp)], Length(tmp));
    end;
    Inc(pos, n);
  end;

  AssertEquals('AES-256 CTR cross-call patterns length', Length(outAll), Length(outStep));
  AssertTrue('AES-256 CTR cross-call patterns content',
    UpperCase(BytesToHex(outAll)) = UpperCase(BytesToHex(outStep)));
end;
procedure TTestCase_AES_CTR.Test_AES192_CTR_InvalidNonceLength_Raises;
var
  ctr: IAESCTR;
  key, badNonce: TBytes;
begin
  key      := HexToBytes('8E73B0F7DA0E6452C810F32B809079E5' + '62F8EAD2522C6B7B'); // 24 bytes
  badNonce := HexToBytes('0102030405060708090A0B'); // 11 bytes (invalid)

  ctr := CreateAESCTR(24);
  ctr.SetKey(key);
  try
    ctr.SetNonceAndCounter(badNonce, 1);
    Fail('Expected EInvalidArgument for invalid nonce length');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_AES_CTR.Test_AES256_CTR_MustSetNonceBeforeProcess_Raises;
var
  ctr: IAESCTR;
  key, pt: TBytes;
begin
  key := HexToBytes('603DEB1015CA71BE2B73AEF0857D7781' +
                    '1F352C073B6108D72D9810A30914DFF4');
  pt := HexToBytes('00010203');
  ctr := CreateAESCTR(32);
  ctr.SetKey(key);
  try
    // Not setting nonce/counter should raise
    pt := ctr.Process(pt);
    Fail('Expected EInvalidOperation when nonce/counter not set');
  except
    on E: EInvalidOperation do ;
  end;
end;

initialization
  RegisterTest(TTestCase_AES_CTR);

end.

