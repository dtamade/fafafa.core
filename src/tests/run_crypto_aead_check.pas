program run_crypto_aead_check;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.crypto;

function LE32Local(const B: TBytes; Ofs: Integer): LongWord; inline;
var p: PByte;
begin
  if (Ofs>=0) and (Ofs+3<Length(B)) then begin
    p := @B[Ofs];
    Result := LongWord(p^) or (LongWord((p+1)^) shl 8) or (LongWord((p+2)^) shl 16) or (LongWord((p+3)^) shl 24);
  end else Result := 0;
end;

procedure ST32Local(var B: TBytes; Ofs: Integer; V: LongWord); inline;
begin
  B[Ofs] := Byte(V);
  B[Ofs+1] := Byte(V shr 8);
  B[Ofs+2] := Byte(V shr 16);
  B[Ofs+3] := Byte(V shr 24);
end;

function RotL32Local(x: LongWord; n: LongWord): LongWord; inline;
begin
  Result := (x shl n) or (x shr (32 - n));
end;

procedure QuarterRoundLocal(var S: array of LongWord; a,b,c,d: Integer); inline;
begin
  Inc(S[a], S[b]); S[d] := S[d] xor S[a]; S[d] := RotL32Local(S[d],16);
  Inc(S[c], S[d]); S[b] := S[b] xor S[c]; S[b] := RotL32Local(S[b],12);
  Inc(S[a], S[b]); S[d] := S[d] xor S[a]; S[d] := RotL32Local(S[d],8);
  Inc(S[c], S[d]); S[b] := S[b] xor S[c]; S[b] := RotL32Local(S[b],7);
end;

function DebugChaCha20Block_LE131415(const Key, Nonce: TBytes; Counter: LongWord): TBytes;
var S,W: array[0..15] of LongWord; I: Integer;
begin
  // constants
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  for I := 0 to 7 do S[4+I] := LE32Local(Key, I*4);
  S[12] := Counter;
  S[13] := LE32Local(Nonce, 0);
  S[14] := LE32Local(Nonce, 4);
  S[15] := LE32Local(Nonce, 8);
  W := S;
  for I := 1 to 10 do begin
    QuarterRoundLocal(W,0,4,8,12);
    QuarterRoundLocal(W,1,5,9,13);
    QuarterRoundLocal(W,2,6,10,14);
    QuarterRoundLocal(W,3,7,11,15);
    QuarterRoundLocal(W,0,5,10,15);
    QuarterRoundLocal(W,1,6,11,12);
    QuarterRoundLocal(W,2,7,8,13);
    QuarterRoundLocal(W,3,4,9,14);
  end;
  SetLength(Result, 64);
  for I := 0 to 15 do begin
    W[I] := W[I] + S[I];
    ST32Local(Result, I*4, W[I]);
  end;
end;

function DebugChaCha20Block_LE151413(const Key, Nonce: TBytes; Counter: LongWord): TBytes;
var S,W: array[0..15] of LongWord; I: Integer;
begin
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  for I := 0 to 7 do S[4+I] := LE32Local(Key, I*4);
  S[12] := Counter;
  S[15] := LE32Local(Nonce, 0);
  S[14] := LE32Local(Nonce, 4);
  S[13] := LE32Local(Nonce, 8);
  W := S;
  for I := 1 to 10 do begin
    QuarterRoundLocal(W,0,4,8,12);
    QuarterRoundLocal(W,1,5,9,13);
    QuarterRoundLocal(W,2,6,10,14);
    QuarterRoundLocal(W,3,7,11,15);
    QuarterRoundLocal(W,0,5,10,15);
    QuarterRoundLocal(W,1,6,11,12);
    QuarterRoundLocal(W,2,7,8,13);
    QuarterRoundLocal(W,3,4,9,14);
  end;
  SetLength(Result, 64);
  for I := 0 to 15 do begin
    W[I] := W[I] + S[I];
    ST32Local(Result, I*4, W[I]);
  end;
end;

function StateChecksumLocal(const W: array of LongWord): LongWord;
var i: Integer; acc: QWord;
begin
  acc := 0;
  for i := 0 to 15 do acc := (acc + W[i]) and $FFFFFFFF;
  Result := LongWord(acc) xor ((LongWord(acc) shl 13) or (LongWord(acc) shr 19));
end;

procedure DumpRoundChecksums_LE131415(const Key, Nonce: TBytes; Counter: LongWord);
var S,W: array[0..15] of LongWord; I: Integer; chk: LongWord;
begin
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  for I := 0 to 7 do S[4+I] := LE32Local(Key, I*4);
  S[12] := Counter;
  S[13] := LE32Local(Nonce, 0);
  S[14] := LE32Local(Nonce, 4);
  S[15] := LE32Local(Nonce, 8);
  W := S;
  for I := 1 to 10 do begin
    QuarterRoundLocal(W,0,4,8,12);
    QuarterRoundLocal(W,1,5,9,13);
    QuarterRoundLocal(W,2,6,10,14);
    QuarterRoundLocal(W,3,7,11,15);
    QuarterRoundLocal(W,0,5,10,15);
    QuarterRoundLocal(W,1,6,11,12);
    QuarterRoundLocal(W,2,7,8,13);
    QuarterRoundLocal(W,3,4,9,14);
    chk := StateChecksumLocal(W);
    WriteLn('Round ', I:2, ' checksum (LE 13-14-15): ', IntToHex(chk,8));
  end;
end;

function LE32Ref(const B: TBytes; Ofs: Integer): LongWord;
begin
  Result := LongWord(B[Ofs]) or (LongWord(B[Ofs+1]) shl 8) or (LongWord(B[Ofs+2]) shl 16) or (LongWord(B[Ofs+3]) shl 24);
end;

function RotL32Ref(x: LongWord; n: LongWord): LongWord; inline;
begin
  Result := (x shl n) or (x shr (32 - n));
end;

procedure QuarterRoundRef(var A: array of LongWord; ai,bi,ci,di: Integer);
begin
  Inc(A[ai], A[bi]); A[di] := A[di] xor A[ai]; A[di] := RotL32Ref(A[di], 16);
  Inc(A[ci], A[di]); A[bi] := A[bi] xor A[ci]; A[bi] := RotL32Ref(A[bi], 12);
  Inc(A[ai], A[bi]); A[di] := A[di] xor A[ai]; A[di] := RotL32Ref(A[di], 8);
  Inc(A[ci], A[di]); A[bi] := A[bi] xor A[ci]; A[bi] := RotL32Ref(A[bi], 7);
end;

procedure DumpRoundChecksums_Ref(const Key, Nonce: TBytes; Counter: LongWord);
var S,W: array[0..15] of LongWord; I: Integer; chk: LongWord;
begin
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  for I := 0 to 7 do S[4+I] := LE32Ref(Key, I*4);
  S[12] := Counter;
  S[13] := LE32Ref(Nonce, 0);
  S[14] := LE32Ref(Nonce, 4);
  S[15] := LE32Ref(Nonce, 8);
  W := S;
  for I := 1 to 10 do begin
    QuarterRoundRef(W,0,4,8,12);
    QuarterRoundRef(W,1,5,9,13);
    QuarterRoundRef(W,2,6,10,14);
    QuarterRoundRef(W,3,7,11,15);
    QuarterRoundRef(W,0,5,10,15);
    QuarterRoundRef(W,1,6,11,12);
    QuarterRoundRef(W,2,7,8,13);
    QuarterRoundRef(W,3,4,9,14);
    chk := StateChecksumLocal(W);
    WriteLn('Ref Round ', I:2, ' checksum: ', IntToHex(chk,8));
  end;
end;

procedure DumpInitialStateLE(const Key, Nonce: TBytes; Counter: LongWord);
var S: array[0..15] of LongWord; i: Integer;
begin
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  for i := 0 to 7 do S[4+i] := LE32Ref(Key, i*4);
  S[12] := Counter;
  S[13] := LE32Ref(Nonce,0);
  S[14] := LE32Ref(Nonce,4);
  S[15] := LE32Ref(Nonce,8);
  WriteLn('Init S[12]=',IntToHex(S[12],8),' S[13]=',IntToHex(S[13],8),' S[14]=',IntToHex(S[14],8),' S[15]=',IntToHex(S[15],8));
end;

procedure DumpPostRoundAndSum_LE(const Key, Nonce: TBytes; Counter: LongWord);
var x,a,summed: array[0..15] of LongWord; I: Integer;
begin
  x[0] := $61707865; x[1] := $3320646E; x[2] := $79622D32; x[3] := $6B206574;
  for I := 0 to 7 do x[4+I] := LE32Ref(Key, I*4);
  x[12] := Counter;
  x[13] := LE32Ref(Nonce, 0);
  x[14] := LE32Ref(Nonce, 4);
  x[15] := LE32Ref(Nonce, 8);
  a := x;
  for I := 1 to 10 do begin
    QuarterRoundRef(a,0,4,8,12);
    QuarterRoundRef(a,1,5,9,13);
    QuarterRoundRef(a,2,6,10,14);
    QuarterRoundRef(a,3,7,11,15);
    QuarterRoundRef(a,0,5,10,15);
    QuarterRoundRef(a,1,6,11,12);
    QuarterRoundRef(a,2,7,8,13);
    QuarterRoundRef(a,3,4,9,14);
  end;
  for I:=0 to 15 do summed[I] := a[I] + x[I];
  WriteLn('PostRound a[0..3]: ', IntToHex(a[0],8),' ',IntToHex(a[1],8),' ',IntToHex(a[2],8),' ',IntToHex(a[3],8));
  WriteLn('Summed   w[0..3]: ', IntToHex(summed[0],8),' ',IntToHex(summed[1],8),' ',IntToHex(summed[2],8),' ',IntToHex(summed[3],8));
  WriteLn('InitCounter,Nonce words LE: ', IntToHex(x[12],8), ' ', IntToHex(x[13],8), ' ', IntToHex(x[14],8), ' ', IntToHex(x[15],8));
end;

procedure DumpFinalStateAndBlockLE(const Key, Nonce: TBytes; Counter: LongWord);
var S,W: array[0..15] of LongWord; I: Integer; Block: array[0..63] of Byte;
begin
  S[0] := $61707865; S[1] := $3320646E; S[2] := $79622D32; S[3] := $6B206574;
  for I := 0 to 7 do S[4+I] := LE32Ref(Key, I*4);
  S[12] := Counter;
  S[13] := LE32Ref(Nonce, 0);
  S[14] := LE32Ref(Nonce, 4);
  S[15] := LE32Ref(Nonce, 8);
  W := S;
  for I := 1 to 10 do begin
    QuarterRoundRef(W,0,4,8,12);
    QuarterRoundRef(W,1,5,9,13);
    QuarterRoundRef(W,2,6,10,14);
    QuarterRoundRef(W,3,7,11,15);
    QuarterRoundRef(W,0,5,10,15);
    QuarterRoundRef(W,1,6,11,12);
    QuarterRoundRef(W,2,7,8,13);
    QuarterRoundRef(W,3,4,9,14);
  end;
  for I:=0 to 15 do W[I] := W[I] + S[I];
  // serialize 64 bytes LE
  for I:=0 to 15 do begin
    Block[I*4+0] := Byte(W[I] and $FF);
    Block[I*4+1] := Byte((W[I] shr 8) and $FF);
    Block[I*4+2] := Byte((W[I] shr 16) and $FF);
    Block[I*4+3] := Byte((W[I] shr 24) and $FF);
  end;
  WriteLn('InitCounter,Nonce words LE: ', IntToHex(S[12],8), ' ', IntToHex(S[13],8), ' ', IntToHex(S[14],8), ' ', IntToHex(S[15],8));
  // print first 16 bytes
  WriteLn('Block[0..15]: ',
    IntToHex(Block[0],2),IntToHex(Block[1],2),IntToHex(Block[2],2),IntToHex(Block[3],2),
    IntToHex(Block[4],2),IntToHex(Block[5],2),IntToHex(Block[6],2),IntToHex(Block[7],2),
    IntToHex(Block[8],2),IntToHex(Block[9],2),IntToHex(Block[10],2),IntToHex(Block[11],2),
    IntToHex(Block[12],2),IntToHex(Block[13],2),IntToHex(Block[14],2),IntToHex(Block[15],2));
end;

function Hex(const S: string): TBytes;
begin
  Result := HexToBytes(S);
end;

procedure AssertEqHex(const Title: string; const B, Exp: TBytes);
begin
  if not SecureCompare(B, Exp) then
  begin
    WriteLn(Title, ' mismatch');
    WriteLn('  got: ', BytesToHex(B));
    WriteLn('  exp: ', BytesToHex(Exp));
    Halt(1);
  end;
end;

var
  Key, Nonce, AAD, PT, ExpCT, ExpTag, CT, OutFull, Opened: TBytes;
  C: IAEADCipher;
  Raised: Boolean;
  First, i: Integer;
  ExpKS, KS13, KS15, OurKS, OurKS_Seal: TBytes;
  Fail: Boolean;
  // for RFC 8439 §2.4.2 block function test
  RFCKey_Block, RFCNonce_Block, RFCExpBlock, RFCKS: TBytes;
  qa,qb,qc,qd: LongWord;
  ExpW, RefW, LibW: array[0..15] of LongWord;
  j, firstDiff: Integer;

  function RefBlock_LE(const Key, Nonce: TBytes; Ctr: LongWord): TBytes;
  var x: array[0..15] of LongWord; a: array[0..15] of LongWord; j: Integer;

    procedure QR(var a,b,c,d: LongWord); inline;
    begin
      a := a + b; d := d xor a; d := RotL32Local(d,16);
      c := c + d; b := b xor c; b := RotL32Local(b,12);
      a := a + b; d := d xor a; d := RotL32Local(d,8);
      c := c + d; b := b xor c; b := RotL32Local(b,7);
    end;

  begin
    // constants
    x[0] := $61707865; x[1] := $3320646E; x[2] := $79622D32; x[3] := $6B206574;
    // key as 8 LE32
    for j:=0 to 7 do x[4+j] := LE32Local(Key, j*4);
    // counter, nonce LE per word
    x[12] := Ctr;
    x[13] := LE32Local(Nonce, 0);
    x[14] := LE32Local(Nonce, 4);
    x[15] := LE32Local(Nonce, 8);
    // work copy
    for j:=0 to 15 do a[j] := x[j];
    for j:=1 to 10 do begin
      QR(a[0],a[4],a[8],a[12]);
      QR(a[1],a[5],a[9],a[13]);
      QR(a[2],a[6],a[10],a[14]);
      QR(a[3],a[7],a[11],a[15]);
      QR(a[0],a[5],a[10],a[15]);
      QR(a[1],a[6],a[11],a[12]);
      QR(a[2],a[7],a[8],a[13]);
      QR(a[3],a[4],a[9],a[14]);
    end;
    // add and serialize LE
    SetLength(Result, 64);
    for j:=0 to 15 do begin
      a[j] := a[j] + x[j];
      ST32Local(Result, j*4, a[j]);
    end;
  end;

  function RefBlock_BE(const Key, Nonce: TBytes; Ctr: LongWord): TBytes;
  var x: array[0..15] of LongWord; a: array[0..15] of LongWord; j: Integer;
    function BE32Local(const B: TBytes; Ofs: Integer): LongWord; inline;
    begin
      Result := (LongWord(B[Ofs]) shl 24) or (LongWord(B[Ofs+1]) shl 16) or (LongWord(B[Ofs+2]) shl 8) or LongWord(B[Ofs+3]);
    end;
    procedure QR(var a,b,c,d: LongWord); inline;
    begin
      a := a + b; d := d xor a; d := RotL32Local(d,16);
      c := c + d; b := b xor c; b := RotL32Local(b,12);
      a := a + b; d := d xor a; d := RotL32Local(d,8);
      c := c + d; b := b xor c; b := RotL32Local(b,7);
    end;
  begin
    x[0] := $61707865; x[1] := $3320646E; x[2] := $79622D32; x[3] := $6B206574;
    for j:=0 to 7 do x[4+j] := LE32Local(Key, j*4);
    x[12] := Ctr;
    x[13] := BE32Local(Nonce,0);
    x[14] := BE32Local(Nonce,4);
    x[15] := BE32Local(Nonce,8);
    for j:=0 to 15 do a[j] := x[j];
    for j:=1 to 10 do begin
      QR(a[0],a[4],a[8],a[12]);
      QR(a[1],a[5],a[9],a[13]);
      QR(a[2],a[6],a[10],a[14]);
      QR(a[3],a[7],a[11],a[15]);
      QR(a[0],a[5],a[10],a[15]);
      QR(a[1],a[6],a[11],a[12]);
      QR(a[2],a[7],a[8],a[13]);
      QR(a[3],a[4],a[9],a[14]);
    end;
    SetLength(Result, 64);
    for j:=0 to 15 do begin
      a[j] := a[j] + x[j];
      ST32Local(Result, j*4, a[j]);
    end;
  end;

begin
  try
    // RFC 8439 §2.1.1 QuarterRound test
    qa := $11111111; qb := $01020304; qc := $9b8d6f43; qd := $01234567;
    // 直接手写一次 QR（保持与 QuarterRoundLocal 相同逻辑）
    qa := qa + qb; qd := qd xor qa; qd := RotL32Local(qd,16);
    qc := qc + qd; qb := qb xor qc; qb := RotL32Local(qb,12);
    qa := qa + qb; qd := qd xor qa; qd := RotL32Local(qd,8);
    qc := qc + qd; qb := qb xor qc; qb := RotL32Local(qb,7);
    if not ((qa=$ea2a92f4) and (qb=$cb1cf8ce) and (qc=$4581472e) and (qd=$5881c4bb)) then begin
      WriteLn('QuarterRound test failed. got=', IntToHex(qa,8),' ',IntToHex(qb,8),' ',IntToHex(qc,8),' ',IntToHex(qd,8));
      Halt(1);
    end else begin
      WriteLn('QuarterRound test passed.');
    end;

    // RFC 8439 Section 2.4.2: ChaCha20 block function (counter=1)
    SetLength(RFCKey_Block, 32);
    for i:=0 to 31 do RFCKey_Block[i] := i; // 00..1f
    RFCNonce_Block := Hex('000000000000004a00000000');
    // expected 64-byte block from RFC
    RFCExpBlock := Hex(
      '10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c72bbbe66ffb3f4e7a877d2f3f'
     +'f08cd1790548002ab29467360d3dd35c9ae8c18ca1e0e29f6dd249823f6b3315');

    // compute reference blocks
    RFCKS := RefBlock_LE(RFCKey_Block, RFCNonce_Block, 1);
    if SecureCompare(RFCKS, RFCExpBlock) then begin
      WriteLn('RFC8439 §2.4.2 block test passed (LE mapping).');
    end else begin
      WriteLn('LE mapping mismatch. our: ', BytesToHex(RFCKS));
      RFCKS := RefBlock_BE(RFCKey_Block, RFCNonce_Block, 1);
      if SecureCompare(RFCKS, RFCExpBlock) then begin
        WriteLn('RFC8439 §2.4.2 block test passed (BE mapping).');
      end else begin
        WriteLn('BE mapping mismatch too. ourBE: ', BytesToHex(RFCKS));
        // 字级对照：拆 16×u32（LE）对比首个分叉
        for j:=0 to 15 do begin
          ExpW[j] := LE32Local(RFCExpBlock, j*4);
          RefW[j] := LE32Local(RefBlock_LE(RFCKey_Block, RFCNonce_Block, 1), j*4);
        end;
        firstDiff := -1;
        for j:=0 to 15 do if RefW[j]<>ExpW[j] then begin firstDiff:=j; break; end;
        if firstDiff<>-1 then
          WriteLn('RefLE vs RFC first word diff at index ',firstDiff,': ref=',IntToHex(RefW[firstDiff],8),' exp=',IntToHex(ExpW[firstDiff],8));
        // Library KS（Seal 路径）字级对照
        SetLength(PT, 64); FillChar(PT[0], 64, 0);
        SetLength(AAD, 0);
        C := CreateChaCha20Poly1305;
        C.SetKey(RFCKey_Block);
        CT := C.Seal(RFCNonce_Block, AAD, PT);
        SetLength(RFCKS, 64);
        for i:=0 to 63 do RFCKS[i] := CT[i] xor PT[i];
        for j:=0 to 15 do LibW[j] := LE32Local(RFCKS, j*4);
        firstDiff := -1;
        for j:=0 to 15 do if LibW[j]<>ExpW[j] then begin firstDiff:=j; break; end;
        if firstDiff<>-1 then
          WriteLn('LibKS vs RFC first word diff at index ',firstDiff,': lib=',IntToHex(LibW[firstDiff],8),' exp=',IntToHex(ExpW[firstDiff],8));
        DumpPostRoundAndSum_LE(RFCKey_Block, RFCNonce_Block, 1);
        WriteLn('Lib KS(seal)  : ', BytesToHex(RFCKS));
        WriteLn('RFC Exp Block : ', BytesToHex(RFCExpBlock));
        Halt(1);
      end;
    end;

    // RFC 8439 Section 2.8.2 test vector
    Key := Hex('1c9240a5eb55d38af333888604f6b5f0473917c1402b80099dca5cbc207075c0');
    Nonce := Hex('000000000000000000000002');
    AAD := Hex('f33388860000000000004e91');
    PT := Hex('4c616469657320616e642047656e746c656d656e206f662074686520636c617373206f66202739393a204966204920636f756c64206f6666657220796f75206f6e6c79206f6e652074697020666f7220746865206675747572652c2073756e73637265656e20776f756c642062652069742e');
    ExpCT := Hex('64a0861575861af460f062c79be643bd5e805cfd345cf389f108670ac76c8cb24c6cfc18755d43eea09ee94e382d26b0bdb7b73c321b0100d4f03b7f355894cf');
    ExpTag := Hex('eead9d67890cbb22392336fea1851f38');

    C := CreateChaCha20Poly1305;
    C.SetKey(Key);

    // keystream diagnostics: expected first 64 bytes = ExpCT XOR PT
    First := Length(PT); if First > 64 then First := 64;
    SetLength(ExpKS, First);
    for i:=0 to First-1 do ExpKS[i] := ExpCT[i] xor PT[i];
    // our keystream from debug block with counter=1
    KS13 := DebugChaCha20Block_LE131415(Key, Nonce, 1);
    KS15 := DebugChaCha20Block_LE151413(Key, Nonce, 1);
    SetLength(OurKS, First);
    if First>0 then Move(KS13[0], OurKS[0], First);
    Fail := False;
    if not SecureCompare(OurKS, ExpKS) then begin
      WriteLn('KS using state[13..15]=nonce[0..8] (LE 13-14-15) mismatch:');
      WriteLn('  our(debug): ', BytesToHex(OurKS));
      WriteLn('  exp:        ', BytesToHex(ExpKS));
      // try alternate mapping
      if First>0 then Move(KS15[0], OurKS[0], First);
      if SecureCompare(OurKS, ExpKS) then begin
        WriteLn('Alternate mapping (15-14-13) matches.');
      end else begin
        WriteLn('Alternate mapping also mismatched.');
        WriteLn('  alt(debug): ', BytesToHex(OurKS));
        // dump per-2-round checksum to localize divergence
        DumpRoundChecksums_LE131415(Key, Nonce, 1);
        DumpRoundChecksums_Ref(Key, Nonce, 1);
      end;
    end;

    // now compute actual CT with real PT
    CT := C.Seal(Nonce, AAD, PT);

    // derive keystream from our Seal path to compare with ExpKS
    SetLength(OurKS_Seal, First);
    for i:=0 to First-1 do OurKS_Seal[i] := CT[i] xor PT[i];
    WriteLn('OurKS(seal): ', BytesToHex(OurKS_Seal));
    if not SecureCompare(OurKS_Seal, ExpKS) then begin
      WriteLn('OurKS(seal) mismatch vs ExpKS.');
      Fail := True;
    end;

    // split CT||Tag
    if Length(CT) <> Length(PT) + 16 then
    begin
      WriteLn('Length check failed: got ', Length(CT), ' expected ', Length(PT)+16);
      Halt(1);
    end;

    SetLength(OutFull, Length(PT));
    if Length(PT) > 0 then Move(CT[0], OutFull[0], Length(PT));
    if not SecureCompare(OutFull, ExpCT) then begin
      WriteLn('Ciphertext mismatch');
      WriteLn('  our: ', BytesToHex(OutFull));
      WriteLn('  exp: ', BytesToHex(ExpCT));
      Fail := True;
    end;

    // extract tag
    SetLength(OutFull, 16);
    if 16 > 0 then Move(CT[Length(PT)], OutFull[0], 16);
    if not SecureCompare(OutFull, ExpTag) then begin
      WriteLn('Tag mismatch');
      WriteLn('  our: ', BytesToHex(OutFull));
      WriteLn('  exp: ', BytesToHex(ExpTag));
      Fail := True;
    end;

    if Fail then begin
      WriteLn('Vector mismatch detected.');
      Halt(1);
    end;

    // sanity print to ensure buffered stdout isn't swallowed
    WriteLn('Vector matched. Proceeding to Open test...');

    // Open should recover PT
    Opened := C.Open(Nonce, AAD, CT);
    if not SecureCompare(Opened, PT) then
    begin
      WriteLn('Open did not recover plaintext');
      Halt(1);
    end;

    // Tamper tag: expect EInvalidData
    CT[High(CT)] := CT[High(CT)] xor $01;
    Raised := False;
    try
      C.Open(Nonce, AAD, CT);
    except
      on E: EInvalidData do Raised := True;
    end;
    if not Raised then
    begin
      WriteLn('Tampered tag did not raise EInvalidData');
      Halt(1);
    end;

    WriteLn('OK: ChaCha20-Poly1305 vector matched and negative case raised as expected.');
    Halt(0);
  except
    on E: Exception do
    begin
      WriteLn('Exception: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

