unit fafafa.core.simd.intrinsics.sha;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.intrinsics.base;

{
  Experimental status:
  - By default, public APIs raise ENotSupportedException to avoid silent misuse.
  - Define FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS to opt in scalar reference semantics.
  - The opt-in path matches x86 SHA extension lane semantics but is not a tuned backend.
}

// SHA-1 intrinsics
function sha_sha1msg1_epu32(const a, b: TM128): TM128;
function sha_sha1msg2_epu32(const a, b: TM128): TM128;
function sha_sha1nexte_epu32(const a, b: TM128): TM128;
function sha_sha1rnds4_epu32(const a, b: TM128; func: Byte): TM128;

// SHA-256 intrinsics
function sha_sha256msg1_epu32(const a, b: TM128): TM128;
function sha_sha256msg2_epu32(const a, b: TM128): TM128;
function sha_sha256rnds2_epu32(const a, b, k: TM128): TM128;

implementation

uses
  SysUtils;

procedure EnsureExperimentalIntrinsicsEnabled(const aFunctionName: string); inline;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  raise ENotSupportedException.CreateFmt(
    '%s is experimental SHA semantics. Define FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS to opt in.',
    [aFunctionName]
  );
  {$ELSE}
  if aFunctionName = '' then
    ;
  {$ENDIF}
end;

function Add32(aLeft, aRight: DWord): DWord; inline;
begin
  Result := DWord(QWord(aLeft) + QWord(aRight));
end;

function Rol32(aValue: DWord; aCount: Byte): DWord; inline;
var
  LCount: Integer;
begin
  LCount := aCount and 31;
  if LCount = 0 then
    Exit(aValue);
  Result := DWord((QWord(aValue) shl LCount) or (QWord(aValue) shr (32 - LCount)));
end;

function Ror32(aValue: DWord; aCount: Byte): DWord; inline;
var
  LCount: Integer;
begin
  LCount := aCount and 31;
  if LCount = 0 then
    Exit(aValue);
  Result := DWord((QWord(aValue) shr LCount) or (QWord(aValue) shl (32 - LCount)));
end;

function Sha1Choose(aB, aC, aD: DWord): DWord; inline;
begin
  Result := (aB and aC) xor ((not aB) and aD);
end;

function Sha1Parity(aB, aC, aD: DWord): DWord; inline;
begin
  Result := aB xor aC xor aD;
end;

function Sha1Majority(aB, aC, aD: DWord): DWord; inline;
begin
  Result := (aB and aC) xor (aB and aD) xor (aC and aD);
end;

function Sha1RoundLogic(aFunc: Byte; aB, aC, aD: DWord): DWord; inline;
begin
  case (aFunc and 3) of
    0:
      Result := Sha1Choose(aB, aC, aD);
    1, 3:
      Result := Sha1Parity(aB, aC, aD);
  else
    Result := Sha1Majority(aB, aC, aD);
  end;
end;

function Sha1RoundConstant(aFunc: Byte): DWord; inline;
begin
  case (aFunc and 3) of
    0:
      Result := DWord($5A827999);
    1:
      Result := DWord($6ED9EBA1);
    2:
      Result := DWord($8F1BBCDC);
  else
    Result := DWord($CA62C1D6);
  end;
end;

function Sha256Choose(aE, aF, aG: DWord): DWord; inline;
begin
  Result := (aE and aF) xor ((not aE) and aG);
end;

function Sha256Majority(aA, aB, aC: DWord): DWord; inline;
begin
  Result := (aA and aB) xor (aA and aC) xor (aB and aC);
end;

function Sha256SmallSigma0(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 7) xor Ror32(aValue, 18) xor (aValue shr 3);
end;

function Sha256SmallSigma1(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 17) xor Ror32(aValue, 19) xor (aValue shr 10);
end;

function Sha256BigSigma0(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 2) xor Ror32(aValue, 13) xor Ror32(aValue, 22);
end;

function Sha256BigSigma1(aValue: DWord): DWord; inline;
begin
  Result := Ror32(aValue, 6) xor Ror32(aValue, 11) xor Ror32(aValue, 25);
end;

function sha_sha1msg1_epu32(const a, b: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha1msg1_epu32');
  Result.m128i_u32[0] := a.m128i_u32[0] xor b.m128i_u32[2];
  Result.m128i_u32[1] := a.m128i_u32[1] xor b.m128i_u32[3];
  Result.m128i_u32[2] := a.m128i_u32[2] xor a.m128i_u32[0];
  Result.m128i_u32[3] := a.m128i_u32[3] xor a.m128i_u32[1];
end;

function sha_sha1msg2_epu32(const a, b: TM128): TM128;
var
  LT3: DWord;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha1msg2_epu32');
  LT3 := Rol32(a.m128i_u32[3] xor b.m128i_u32[2], 1);
  Result.m128i_u32[0] := Rol32(LT3 xor a.m128i_u32[0], 1);
  Result.m128i_u32[1] := Rol32(a.m128i_u32[1] xor b.m128i_u32[0], 1);
  Result.m128i_u32[2] := Rol32(a.m128i_u32[2] xor b.m128i_u32[1], 1);
  Result.m128i_u32[3] := LT3;
end;

function sha_sha1nexte_epu32(const a, b: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha1nexte_epu32');
  Result := b;
  Result.m128i_u32[3] := Add32(b.m128i_u32[3], Rol32(a.m128i_u32[3], 30));
end;

function sha_sha1rnds4_epu32(const a, b: TM128; func: Byte): TM128;
var
  LA: DWord;
  LB: DWord;
  LC: DWord;
  LD: DWord;
  LE: DWord;
  LTemp: DWord;
  LWords: array[0..3] of DWord;
  LRound: Integer;
  LRoundLogic: DWord;
  LRoundConstant: DWord;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha1rnds4_epu32');
  LWords[0] := b.m128i_u32[3];
  LWords[1] := b.m128i_u32[2];
  LWords[2] := b.m128i_u32[1];
  LWords[3] := b.m128i_u32[0];

  LD := a.m128i_u32[0];
  LC := a.m128i_u32[1];
  LB := a.m128i_u32[2];
  LA := a.m128i_u32[3];
  LE := 0;
  LRoundConstant := Sha1RoundConstant(func);

  for LRound := 0 to 3 do
  begin
    LRoundLogic := Sha1RoundLogic(func, LB, LC, LD);
    LTemp := Add32(Rol32(LA, 5), LRoundLogic);
    if LRound = 0 then
      LTemp := Add32(LTemp, LWords[LRound])
    else
      LTemp := Add32(LTemp, Add32(LE, LWords[LRound]));
    LTemp := Add32(LTemp, LRoundConstant);

    LE := LD;
    LD := LC;
    LC := Rol32(LB, 30);
    LB := LA;
    LA := LTemp;
  end;

  Result.m128i_u32[0] := LD;
  Result.m128i_u32[1] := LC;
  Result.m128i_u32[2] := LB;
  Result.m128i_u32[3] := LA;
end;

function sha_sha256msg1_epu32(const a, b: TM128): TM128;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha256msg1_epu32');
  Result.m128i_u32[0] := Add32(Sha256SmallSigma0(a.m128i_u32[1]), a.m128i_u32[0]);
  Result.m128i_u32[1] := Add32(Sha256SmallSigma0(a.m128i_u32[2]), a.m128i_u32[1]);
  Result.m128i_u32[2] := Add32(Sha256SmallSigma0(a.m128i_u32[3]), a.m128i_u32[2]);
  Result.m128i_u32[3] := Add32(Sha256SmallSigma0(b.m128i_u32[0]), a.m128i_u32[3]);
end;

function sha_sha256msg2_epu32(const a, b: TM128): TM128;
var
  LO0: DWord;
  LO1: DWord;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha256msg2_epu32');
  LO0 := Add32(Sha256SmallSigma1(b.m128i_u32[2]), a.m128i_u32[0]);
  LO1 := Add32(Sha256SmallSigma1(b.m128i_u32[3]), a.m128i_u32[1]);
  Result.m128i_u32[0] := LO0;
  Result.m128i_u32[1] := LO1;
  Result.m128i_u32[2] := Add32(Sha256SmallSigma1(LO0), a.m128i_u32[2]);
  Result.m128i_u32[3] := Add32(Sha256SmallSigma1(LO1), a.m128i_u32[3]);
end;

function sha_sha256rnds2_epu32(const a, b, k: TM128): TM128;
var
  LA: DWord;
  LB: DWord;
  LC: DWord;
  LD: DWord;
  LE: DWord;
  LF: DWord;
  LG: DWord;
  LH: DWord;
  LT1: DWord;
  LT2: DWord;
  LRound: Integer;
begin
  EnsureExperimentalIntrinsicsEnabled('sha_sha256rnds2_epu32');
  LH := a.m128i_u32[0];
  LG := a.m128i_u32[1];
  LD := a.m128i_u32[2];
  LC := a.m128i_u32[3];
  LF := b.m128i_u32[0];
  LE := b.m128i_u32[1];
  LB := b.m128i_u32[2];
  LA := b.m128i_u32[3];

  for LRound := 0 to 1 do
  begin
    LT1 := Add32(LH, Sha256BigSigma1(LE));
    LT1 := Add32(LT1, Sha256Choose(LE, LF, LG));
    LT1 := Add32(LT1, k.m128i_u32[LRound]);
    LT2 := Add32(Sha256BigSigma0(LA), Sha256Majority(LA, LB, LC));

    LH := LG;
    LG := LF;
    LF := LE;
    LE := Add32(LD, LT1);
    LD := LC;
    LC := LB;
    LB := LA;
    LA := Add32(LT1, LT2);
  end;

  Result.m128i_u32[0] := LF;
  Result.m128i_u32[1] := LE;
  Result.m128i_u32[2] := LB;
  Result.m128i_u32[3] := LA;
end;

end.
