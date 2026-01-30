{
  fafafa.core.crypto.hash.xxh3_64 - XXH3-64 纯 Pascal 实现（分步推进）

  当前覆盖：
  - 0..16 / 17..128 / 129..240 / >240 (长报文，默认 secret)
  - 仅 seed=0 的 one-shot 入口（后续会扩展 seed 与 streaming）
}

unit fafafa.core.crypto.hash.xxh3_64;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.crypto.interfaces;

type
  TBytes = fafafa.core.crypto.interfaces.TBytes;
  IHashAlgorithm = fafafa.core.crypto.interfaces.IHashAlgorithm;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EInvalidOperation = fafafa.core.crypto.interfaces.EInvalidOperation;

  // 流式上下文（在线累加实现，seed 仅支持 0）
  TXXH3_64Context = class(TInterfacedObject, IHashAlgorithm)
  private
    FSeed: QWord;
    FTotalLen: QWord;
    FAcc: array[0..7] of QWord;
    FBuf: array[0..63] of Byte; // 64B stripe buffer remainder
    FBufSize: Integer;
    FLastStripe: array[0..63] of Byte; // 保存输入流的最后 64 字节
    FLastStripeSize: Integer;
    FAll: TBytes; // 全量缓冲（确保 <=240 场景与切片等价）
    FFinalized: Boolean;
    FProcessedInBlock: Integer; // 当前 block 中已处理的条带数（0..nbStripesPerBlock-1）
  public
    constructor Create(ASeed: QWord);
    // IHashAlgorithm
    function GetDigestSize: Integer;
    function GetBlockSize: Integer;
    function GetName: string;
    procedure Update(const AData; ASize: Integer);
    function Finalize: TBytes;
    procedure Reset;
    procedure Burn;
  end;

function CreateXXH3_64(ASeed: QWord = 0): IHashAlgorithm;
// 一次性哈希，目前仅支持 seed=0，且长度任意
function XXH3_64Hash(const AData: TBytes; ASeed: QWord = 0): TBytes;

implementation




const
  // 默认 secret（来自 reference/xxHash-dev/xxhash.h 的 XXH3_kSecret，长度 192 字节）
  XXH3_kSecret: array[0..191] of Byte = (
    $B8,$FE,$6C,$39,$23,$A4,$4B,$BE,$7C,$01,$81,$2C,$F7,$21,$AD,$1C,
    $DE,$D4,$6D,$E9,$83,$90,$97,$DB,$72,$40,$A4,$A4,$B7,$B3,$67,$1F,
    $CB,$79,$E6,$4E,$CC,$C0,$E5,$78,$82,$5A,$D0,$7D,$CC,$FF,$72,$21,
    $B8,$08,$46,$74,$F7,$43,$24,$8E,$E0,$35,$90,$E6,$81,$3A,$26,$4C,
    $3C,$28,$52,$BB,$91,$C3,$00,$CB,$88,$D0,$65,$8B,$1B,$53,$2E,$A3,
    $71,$64,$48,$97,$A2,$0D,$F9,$4E,$38,$19,$EF,$46,$A9,$DE,$AC,$D8,
    $A8,$FA,$76,$3F,$E3,$9C,$34,$3F,$F9,$DC,$BB,$C7,$C7,$0B,$4F,$1D,
    $8A,$51,$E0,$4B,$CD,$B4,$59,$31,$C8,$9F,$7E,$C9,$D9,$78,$73,$64,
    $EA,$C5,$AC,$83,$34,$D3,$EB,$C3,$C5,$81,$A0,$FF,$FA,$13,$63,$EB,
    $17,$0D,$DD,$51,$B7,$F0,$DA,$49,$D3,$16,$55,$26,$29,$D4,$68,$9E,
    $2B,$16,$BE,$58,$7D,$47,$A1,$FC,$8F,$F8,$B8,$D1,$7A,$D0,$31,$CE,
    $45,$CB,$3A,$8F,$95,$16,$04,$28,$AF,$D7,$FB,$CA,$BB,$4B,$40,$7E
  );

  PRIME_MX1 = QWord($165667919E3779F9);
  PRIME_MX2 = QWord($9FB21C651E98DF25);
  PRIME64_1 = QWord($9E3779B185EBCA87);
  XXH3_SECRET_SIZE_MIN = 136; // bytes
  XXH3_MIDSIZE_STARTOFFSET = 3;
  XXH3_MIDSIZE_LASTOFFSET  = 17;

function ReadLE32(const P: PByte): UInt32; inline;
begin
  Result := UInt32(P[0]) or (UInt32(P[1]) shl 8) or (UInt32(P[2]) shl 16) or (UInt32(P[3]) shl 24);
end;

function ReadLE64(const P: PByte): QWord; inline;
begin
  Result := QWord(P[0]) or (QWord(P[1]) shl 8) or (QWord(P[2]) shl 16) or (QWord(P[3]) shl 24)
         or (QWord(P[4]) shl 32) or (QWord(P[5]) shl 40) or (QWord(P[6]) shl 48) or (QWord(P[7]) shl 56);
end;

function Swap32(x: UInt32): UInt32; inline;
begin
  Result := ((x and $FF) shl 24) or
            ((x and $FF00) shl 8) or
            ((x shr 8) and $FF00) or
            ((x shr 24) and $FF);
end;

function Swap64(x: QWord): QWord; inline;
begin
  Result := ( (x and QWord($00000000000000FF)) shl 56)
          or ( (x and QWord($000000000000FF00)) shl 40)
          or ( (x and QWord($0000000000FF0000)) shl 24)
          or ( (x and QWord($00000000FF000000)) shl 8)
          or ( (x and QWord($000000FF00000000)) shr 8)
          or ( (x and QWord($0000FF0000000000)) shr 24)
          or ( (x and QWord($00FF000000000000)) shr 40)
          or ( (x and QWord($FF00000000000000)) shr 56);
end;

function XorShift64(v: QWord; Shift: Integer): QWord; inline;
begin
  Result := v xor (v shr Shift);
end;

function RotL64(v: QWord; s: Integer): QWord; inline;
begin
  Result := (v shl s) or (v shr (64 - s));
end;

function XXH64_avalanche(h: QWord): QWord; inline;
begin
  h := h xor (h shr 33);
  h := h * QWord($C2B2AE3D27D4EB4F); // PRIME64_2
  h := h xor (h shr 29);
  h := h * QWord($165667B19E3779F9); // PRIME64_3
  h := h xor (h shr 32);
  Result := h;
end;

function XXH3_avalanche(h: QWord): QWord; inline;
begin
  h := XorShift64(h, 37);
  h := h * PRIME_MX1;
  h := XorShift64(h, 32);
  Result := h;
end;

function XXH3_rrmxmx(h: QWord; L: QWord): QWord; inline;
begin
  h := h xor RotL64(h, 49) xor RotL64(h, 24);
  h := h * PRIME_MX2;
  h := h xor ((h shr 35) + L);
  h := h * PRIME_MX2;
  Result := XorShift64(h, 28);
end;

function Mul128_Fold64(lhs, rhs: QWord): QWord; inline;
var
  a0, a1, b0, b1: QWord;
  p0, p1, p2, p3: QWord;
  mid1, mid2: QWord;
  carryLow: QWord;
  low64, high64: QWord;
begin
  a0 := lhs and $FFFFFFFF;
  a1 := lhs shr 32;
  b0 := rhs and $FFFFFFFF;
  b1 := rhs shr 32;

  p0 := a0 * b0;       // 64-bit
  p1 := a0 * b1;       // up to 64-bit
  p2 := a1 * b0;       // up to 64-bit
  p3 := a1 * b1;       // up to 64-bit

  // assemble low64 with carries from lower 64-bit additions
  mid1 := (p1 and $FFFFFFFF) shl 32;
  mid2 := (p2 and $FFFFFFFF) shl 32;
  low64 := p0 + mid1;
  carryLow := Ord(low64 < p0);
  low64 := low64 + mid2;
  Inc(carryLow, Ord(low64 < mid2));

  // high64 = p3 + (p1>>32) + (p2>>32) + carryLow (natural 64-bit wrap)
  high64 := p3 + (p1 shr 32);
  high64 := high64 + (p2 shr 32);
  high64 := high64 + carryLow;

  Result := high64 xor low64;
end;

function XXH3_mix16B(const Data, Secret: PByte; Seed: QWord): QWord; inline;
var
  in_lo, in_hi, keyed_lo, keyed_hi: QWord;
begin
  in_lo := ReadLE64(Data);
  in_hi := ReadLE64(Data + 8);
  keyed_lo := in_lo xor (ReadLE64(Secret) + Seed);
  keyed_hi := in_hi xor (ReadLE64(Secret + 8) - Seed);
  Result := Mul128_Fold64(keyed_lo, keyed_hi);
end;

function XXH3_64_0to0(const Secret: PByte; Seed: QWord): QWord; inline;
var bitflip: QWord;
begin
  // return XXH64_avalanche(seed ^ (READ64(secret+56) ^ READ64(secret+64)))
  bitflip := ReadLE64(Secret + 56) xor ReadLE64(Secret + 64);
  Result := XXH64_avalanche(Seed xor bitflip);
end;

function XXH3_64_1to3(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord; inline;
var c1, c2, c3: Byte; combined: UInt32; bitflip, keyed: QWord;
begin
  // combined = {c1, len, c3, c2} with mapping per spec
  c1 := Data[0];
  c2 := Data[Len shr 1];
  c3 := Data[Len-1];
  combined := (UInt32(c1) shl 16) or (UInt32(c2) shl 24) or (UInt32(c3) shl 0) or (UInt32(Len) shl 8);
  bitflip := (UInt32(ReadLE32(Secret)) xor UInt32(ReadLE32(Secret + 4))) + Seed;
  keyed := QWord(combined) xor bitflip;
  Result := XXH64_avalanche(keyed);
end;

function XXH3_64_4to8(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord; inline;
var input1, input2: UInt32; bitflip, input64, seeded: QWord;
begin
  // seed ^= swap32(seed) << 32 ; (seed=0 -> 无影响)
  seeded := Seed xor (QWord(Swap32(UInt32(Seed))) shl 32);
  input1 := ReadLE32(Data);
  input2 := ReadLE32(Data + Len - 4);
  bitflip := (ReadLE64(Secret + 8) xor ReadLE64(Secret + 16)) - seeded;
  input64 := QWord(input2) + (QWord(input1) shl 32);
  Result := XXH3_rrmxmx(input64 xor bitflip, QWord(Len));
end;

function XXH3_64_9to16(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord; inline;
var bitflip1, bitflip2, input_lo, input_hi, acc: QWord;
begin
  // per spec: 9..16
  bitflip1 := (ReadLE64(Secret + 24) xor ReadLE64(Secret + 32)) + Seed;
  bitflip2 := (ReadLE64(Secret + 40) xor ReadLE64(Secret + 48)) - Seed;
  input_lo := ReadLE64(Data) xor bitflip1;
  input_hi := ReadLE64(Data + Len - 8) xor bitflip2;
  acc := QWord(Len) + Swap64(input_lo) + input_hi + Mul128_Fold64(input_lo, input_hi);
  Result := XXH3_avalanche(acc);
end;

{ TXXH3_64Context }

constructor TXXH3_64Context.Create(ASeed: QWord);
begin
  inherited Create;
  FSeed := ASeed;
  Reset;
end;

function TXXH3_64Context.GetDigestSize: Integer; begin Result := 8; end;
function TXXH3_64Context.GetBlockSize: Integer; begin Result := 64; end;
function TXXH3_64Context.GetName: string; begin Result := 'XXH3-64'; end;

procedure TXXH3_64Context.Reset;
var i: Integer;
begin
  FTotalLen := 0; FBufSize := 0; FFinalized := False; FLastStripeSize := 0; FProcessedInBlock := 0;
  // 初始化 acc 与长路径一致的常量
  FAcc[0] := QWord($9E3779B1); FAcc[1] := QWord($9E3779B185EBCA87); FAcc[2] := QWord($C2B2AE3D27D4EB4F); FAcc[3] := QWord($165667B19E3779F9);
  FAcc[4] := QWord($85EBCA77C2B2AE63); FAcc[5] := QWord($85EBCA6B); FAcc[6] := QWord($27D4EB2F165667C5); FAcc[7] := QWord($9E3779B1);
  FillChar(FBuf[0], SizeOf(FBuf), 0);
  FillChar(FLastStripe[0], SizeOf(FLastStripe), 0);
  SetLength(FAll, 0);
end;


// Global scalar helpers shared by long path and streaming
procedure XXH3_AccumulateStripe(var AccArr: array of QWord; const InPtr, SecPtr: PByte);
var j: SizeInt; data_val, data_key: QWord;
begin
  for j := 0 to High(AccArr) do begin
    data_val := ReadLE64(InPtr + j*8);
    data_key := data_val xor ReadLE64(SecPtr + j*8);
    AccArr[j xor 1] := AccArr[j xor 1] + data_val;
    AccArr[j] := AccArr[j] + ((data_key and $FFFFFFFF) * (data_key shr 32));
  end;
end;

procedure XXH3_ScrambleAcc(var AccArr: array of QWord; const SecPtr: PByte);
var j: SizeInt; acc64: QWord;
begin
  for j := 0 to High(AccArr) do begin
    acc64 := AccArr[j];
    acc64 := acc64 xor (acc64 shr 47);
    acc64 := acc64 xor ReadLE64(SecPtr + j*8);
    acc64 := acc64 * QWord($9E3779B1); // PRIME32_1
    AccArr[j] := acc64;
  end;
end;

procedure TXXH3_64Context.Burn;
var i: Integer;
begin
  FSeed := 0; FTotalLen := 0; FBufSize := 0; FFinalized := True; FLastStripeSize := 0;
  for i := 0 to 7 do FAcc[i] := 0;
  FillChar(FBuf[0], SizeOf(FBuf), 0);
  FillChar(FLastStripe[0], SizeOf(FLastStripe), 0);
  SetLength(FAll, 0);
end;

procedure XXH3_AccumulateBlock(var Acc: array of QWord; const InPtr, SecPtr: PByte; NbStripes: Integer);
var n: Integer;
begin
  for n := 0 to NbStripes-1 do begin
    XXH3_AccumulateStripe(Acc, InPtr + n*64, SecPtr + n*8);
  end;
end;

procedure TXXH3_64Context.Update(const AData; ASize: Integer);
var P: PByte; L, take, nbStripesPerBlock, blockLen, nbStripes: Integer; processed: Integer;
const STRIPE_LEN = 64; SECRET_CONSUME_RATE = 8; SECRET_SIZE_MIN = 136;
begin
  if FFinalized then raise EInvalidOperation.Create('Cannot update finalized XXH3-64 context');
  if ASize <= 0 then Exit;
  // precompute block params for use in buffered completion
  nbStripesPerBlock := (SECRET_SIZE_MIN - STRIPE_LEN) div SECRET_CONSUME_RATE; // 9
  blockLen := STRIPE_LEN * nbStripesPerBlock; // 576

  if FSeed <> 0 then raise EInvalidArgument.Create('XXH3-64 streaming: only seed=0 supported in this phase');
  P := @AData; L := ASize;
  Inc(FTotalLen, QWord(L));

  // 维护全量缓冲（仅用于 len<=240 的 finalize 或测试等价；长路径可选保留最近窗口）
  SetLength(FAll, Length(FAll) + L);
  if L > 0 then Move(P^, FAll[Length(FAll) - L], L);

  // complete pending stripe from buffer
  if (FBufSize > 0) then begin
    take := STRIPE_LEN - FBufSize; if take > L then take := L;
    Move(P^, FBuf[FBufSize], take);
    Inc(FBufSize, take); Inc(P, take); Dec(L, take);
    if FBufSize = STRIPE_LEN then begin
      // 按当前 block 偏移累加该条带
      XXH3_AccumulateStripe(FAcc, @FBuf[0], @XXH3_kSecret[0] + FProcessedInBlock*SECRET_CONSUME_RATE);
      FBufSize := 0;
      Inc(FProcessedInBlock);
      if FProcessedInBlock = nbStripesPerBlock then begin
        XXH3_ScrambleAcc(FAcc, @XXH3_kSecret[0] + blockLen - STRIPE_LEN);
        FProcessedInBlock := 0;
      end;
    end;
  end;

  // bulk stripes
  nbStripesPerBlock := (SECRET_SIZE_MIN - STRIPE_LEN) div SECRET_CONSUME_RATE; // 9
  blockLen := STRIPE_LEN * nbStripesPerBlock; // 576
  processed := FProcessedInBlock;
  while L >= STRIPE_LEN do begin
    // process as many stripes as possible up to a block
    nbStripes := L div STRIPE_LEN;
    if nbStripes > nbStripesPerBlock then nbStripes := nbStripesPerBlock;
    // 记录本批次的最后一个条带，作为候选“全输入的最后 64B”
    Move((P + (nbStripes * STRIPE_LEN - STRIPE_LEN))^, FLastStripe[0], STRIPE_LEN);
    FLastStripeSize := STRIPE_LEN;
    // 累加本批次，按 secret 消耗偏移（延续上个 block 的进度）
    XXH3_AccumulateBlock(FAcc, P, @XXH3_kSecret[0] + processed*SECRET_CONSUME_RATE, nbStripes);
    Inc(P, nbStripes * STRIPE_LEN); Dec(L, nbStripes * STRIPE_LEN);
    Inc(processed, nbStripes);
    if processed = nbStripesPerBlock then begin
      // 区块尾部进行 scramble
      XXH3_ScrambleAcc(FAcc, @XXH3_kSecret[0] + blockLen - STRIPE_LEN);
      processed := 0;
    end;
  end;
  // 更新实例字段，保留 block 进度
  FProcessedInBlock := processed;

  // tail to buffer
  if L > 0 then begin
    // 如果总长度>=64，则用尾部不足 64B 更新 lastStripe 窗口：保留最近 64B
    if FTotalLen >= 64 then begin
      if L >= STRIPE_LEN then begin
        Move(P^, FLastStripe[0], STRIPE_LEN);
        FLastStripeSize := STRIPE_LEN;
      end else begin
        // 把已有尾部向左移动，保持总计 64B，右侧填充新尾部
        if FLastStripeSize < STRIPE_LEN then begin
          // 初次建立窗口，先清零
          FillChar(FLastStripe[0], STRIPE_LEN, 0);
          FLastStripeSize := 0;
        end;
        if L < STRIPE_LEN then begin
          // 滚动窗口：将后 L 字节放在尾部，前部保留最近的 (64-L)
          Move(FLastStripe[L], FLastStripe[0], STRIPE_LEN - L);
          Move(P^, FLastStripe[STRIPE_LEN - L], L);
          FLastStripeSize := STRIPE_LEN;
        end;
      end;
    end else begin
      // 总长度尚不足 64 的场景：直接累积到 lastStripe
      Move(P^, FLastStripe[FLastStripeSize], L);
      Inc(FLastStripeSize, L);
    end;

    Move(P^, FBuf[FBufSize], L);
    Inc(FBufSize, L);
  end;
end;

function XXH3_MergeAccs(const Acc: array of QWord; const Secret: PByte; Start: QWord): QWord;
begin
  Result := XXH3_avalanche(Start
    + Mul128_Fold64(Acc[0] xor ReadLE64(Secret +  0), Acc[1] xor ReadLE64(Secret +  8))
    + Mul128_Fold64(Acc[2] xor ReadLE64(Secret + 16), Acc[3] xor ReadLE64(Secret + 24))
    + Mul128_Fold64(Acc[4] xor ReadLE64(Secret + 32), Acc[5] xor ReadLE64(Secret + 40))
    + Mul128_Fold64(Acc[6] xor ReadLE64(Secret + 48), Acc[7] xor ReadLE64(Secret + 56))
  );
end;

function TXXH3_64Context.Finalize: TBytes;
var h: QWord; secretLastAccStart: Integer; pLastStripe: PByte; tailStripes, nbStripesPerBlock, blockLen: Integer;
begin
  if FFinalized then raise EInvalidOperation.Create('XXH3-64 context already finalized');
  // 为保证与 one-shot 完全一致，当前流式最终直接委托 one-shot（后续可再优化为真流式）
  Result := XXH3_64Hash(FAll, FSeed);
  FFinalized := True;
  Exit;
  // 输出大端
  SetLength(Result, 8);
  Result[0] := Byte((h shr 56) and $FF);
  Result[1] := Byte((h shr 48) and $FF);
  Result[2] := Byte((h shr 40) and $FF);
  Result[3] := Byte((h shr 32) and $FF);
  Result[4] := Byte((h shr 24) and $FF);
  Result[5] := Byte((h shr 16) and $FF);
  Result[6] := Byte((h shr 8) and $FF);
  Result[7] := Byte(h and $FF);
  FFinalized := True;
end;

function CreateXXH3_64(ASeed: QWord): IHashAlgorithm;
begin
  Result := TXXH3_64Context.Create(ASeed);
end;

function XXH3_64_17to128(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord;
var acc: QWord;
begin
  acc := QWord(Len) * PRIME64_1;
  if Len > 32 then begin
    if Len > 64 then begin
      if Len > 96 then begin
        acc := acc + XXH3_mix16B(Data + 48, Secret + 96, Seed);
        acc := acc + XXH3_mix16B(Data + Len - 64, Secret + 112, Seed);
      end;
      acc := acc + XXH3_mix16B(Data + 32, Secret + 64, Seed);
      acc := acc + XXH3_mix16B(Data + Len - 48, Secret + 80, Seed);
    end;
    acc := acc + XXH3_mix16B(Data + 16, Secret + 32, Seed);
    acc := acc + XXH3_mix16B(Data + Len - 32, Secret + 48, Seed);
  end;
  acc := acc + XXH3_mix16B(Data + 0, Secret + 0, Seed);
  acc := acc + XXH3_mix16B(Data + Len - 16, Secret + 16, Seed);
  Result := XXH3_avalanche(acc);
end;

function XXH3_64_129to240(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord;
var acc, acc_end: QWord; nbRounds, i: SizeInt;
begin
  acc := QWord(Len) * PRIME64_1;
  acc_end := 0;
  nbRounds := Len div 16; // number of 16B blocks
  // first 8 rounds at fixed secret offsets
  for i := 0 to 7 do begin
    acc := acc + XXH3_mix16B(Data + (16*i), Secret + (16*i), Seed);
  end;
  // last bytes block with special secret offset
  acc_end := XXH3_mix16B(Data + Len - 16, Secret + (XXH3_SECRET_SIZE_MIN - XXH3_MIDSIZE_LASTOFFSET), Seed);
  // remaining rounds
  for i := 8 to nbRounds-1 do begin
    acc_end := acc_end + XXH3_mix16B(Data + (16*i), Secret + (16*(i-8)) + XXH3_MIDSIZE_STARTOFFSET, Seed);
  end;
  Result := XXH3_avalanche(acc + acc_end);
end;


// forward declaration for long path
function XXH3_64_Long(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord; forward;

function XXH3_64Hash(const AData: TBytes; ASeed: QWord): TBytes;
var
  len: SizeInt;
  h: QWord;
  p: PByte;
// helpers are declared above; forward decls not needed here
begin
  len := Length(AData);
  if len = 0 then begin
    h := XXH3_64_0to0(@XXH3_kSecret[0], ASeed);
  end else begin
    p := @AData[0];
    if len <= 3 then
      h := XXH3_64_1to3(p, len, @XXH3_kSecret[0], ASeed)
    else if len <= 8 then
      h := XXH3_64_4to8(p, len, @XXH3_kSecret[0], ASeed)
    else if len <= 16 then
      h := XXH3_64_9to16(p, len, @XXH3_kSecret[0], ASeed)
    else if len <= 128 then
      h := XXH3_64_17to128(p, len, @XXH3_kSecret[0], ASeed)
    else if len <= 240 then
      h := XXH3_64_129to240(p, len, @XXH3_kSecret[0], ASeed)
    else
      h := XXH3_64_Long(p, len, @XXH3_kSecret[0], ASeed);
  end;
  // 输出大端（MSB-first）
  SetLength(Result, 8);
  Result[0] := Byte((h shr 56) and $FF);
  Result[1] := Byte((h shr 48) and $FF);
  Result[2] := Byte((h shr 40) and $FF);
  Result[3] := Byte((h shr 32) and $FF);
  Result[4] := Byte((h shr 24) and $FF);
  Result[5] := Byte((h shr 16) and $FF);
  Result[6] := Byte((h shr 8) and $FF);
  Result[7] := Byte(h and $FF);
end;

// 长报文路径：>240（条带累加 + scramble + merge）
function XXH3_64_Long(const Data: PByte; Len: SizeInt; const Secret: PByte; Seed: QWord): QWord;
const
  STRIPE_LEN = 64;
  SECRET_CONSUME_RATE = 8;
  ACC_NB = STRIPE_LEN div SizeOf(QWord);
  SECRET_LASTACC_START = 7;
  SECRET_MERGEACCS_START = 11;
var
  acc: array[0..ACC_NB-1] of QWord;
  nbStripesPerBlock, blockLen: SizeInt;
  nbBlocks, nbStripes, n, i: SizeInt;
  p, s: PByte;
  start: QWord;

  procedure AccumulateStripe(var AccArr: array of QWord; const InPtr, SecPtr: PByte);
  begin
    XXH3_AccumulateStripe(AccArr, InPtr, SecPtr);
  end;

  procedure ScrambleAcc(var AccArr: array of QWord; const SecPtr: PByte);
  var j: SizeInt; acc64: QWord;
  begin
    for j := 0 to ACC_NB-1 do begin
      acc64 := AccArr[j];
      acc64 := acc64 xor (acc64 shr 47);
      acc64 := acc64 xor ReadLE64(SecPtr + j*8);
      acc64 := acc64 * QWord($9E3779B1); // PRIME32_1
      AccArr[j] := acc64;
    end;
  end;

  function Mix2Accs(const AccArr: array of QWord; const SecPtr: PByte; Start: SizeInt): QWord;
  begin
    Result := Mul128_Fold64(AccArr[Start] xor ReadLE64(SecPtr), AccArr[Start+1] xor ReadLE64(SecPtr+8));
  end;


begin
  // init acc
  acc[0] := QWord($9E3779B1); acc[1] := QWord($9E3779B185EBCA87); acc[2] := QWord($C2B2AE3D27D4EB4F); acc[3] := QWord($165667B19E3779F9);
  acc[4] := QWord($85EBCA77C2B2AE63); acc[5] := QWord($85EBCA6B); acc[6] := QWord($27D4EB2F165667C5); acc[7] := QWord($9E3779B1);

  nbStripesPerBlock := (XXH3_SECRET_SIZE_MIN - STRIPE_LEN) div SECRET_CONSUME_RATE;
  blockLen := STRIPE_LEN * nbStripesPerBlock;
  nbBlocks := Len div blockLen;
  p := Data;
  s := Secret;

  for n := 0 to nbBlocks-1 do begin
    AccumulateStripe(acc, p + n*blockLen, s);
    for i := 1 to nbStripesPerBlock-1 do begin
      AccumulateStripe(acc, p + n*blockLen + i*STRIPE_LEN, s + i*SECRET_CONSUME_RATE);
    end;
    ScrambleAcc(acc, s + blockLen - STRIPE_LEN);
  end;

  // remaining stripes
  nbStripes := (Len - nbBlocks*blockLen - 1) div STRIPE_LEN;
  s := Secret + nbBlocks*SECRET_CONSUME_RATE;
  for i := 0 to nbStripes-1 do begin
    AccumulateStripe(acc, p + nbBlocks*blockLen + i*STRIPE_LEN, s + i*SECRET_CONSUME_RATE);
  end;

  // last stripe uses special secret position
  AccumulateStripe(acc, p + Len - STRIPE_LEN, Secret + XXH3_SECRET_SIZE_MIN - STRIPE_LEN - SECRET_LASTACC_START);

  // finalize merge
  start := QWord(Len) * PRIME64_1;
  Result := XXH3_avalanche(
      start
      + Mix2Accs(acc, Secret + SECRET_MERGEACCS_START, 0)
      + Mix2Accs(acc, Secret + SECRET_MERGEACCS_START + 16, 2)
      + Mix2Accs(acc, Secret + SECRET_MERGEACCS_START + 32, 4)
      + Mix2Accs(acc, Secret + SECRET_MERGEACCS_START + 48, 6)
    );
end;

end.

