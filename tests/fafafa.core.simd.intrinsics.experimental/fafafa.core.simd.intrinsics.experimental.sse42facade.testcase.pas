unit fafafa.core.simd.intrinsics.experimental.sse42facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse42;

type
  TTestCase_Sse42FacadeExperimental = class(TTestCase)
  published
    procedure Test_Crc32CastagnoliSemantics;
    procedure Test_CmpGtEpi64Semantics;
    procedure Test_ExplicitStringEqualAnySubset;
    procedure Test_ImplicitStringEqualAnySubset;
    procedure Test_StringCompareUnsupportedControlsRaise;
  end;

implementation

const
  SSE42_EQUAL_ANY_UBYTE = 0;

procedure FillM128BytesFromString(var aValue: TM128; const aText: AnsiString);
var
  LIndex: Integer;
begin
  FillChar(aValue, SizeOf(aValue), 0);
  for LIndex := 1 to Length(aText) do
  begin
    if LIndex > 16 then
      Break;
    aValue.m128i_u8[LIndex - 1] := Ord(aText[LIndex]);
  end;
end;

procedure AssertM128U64Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m128i_u64[LIndex]), QWord(aActual.m128i_u64[LIndex]));
end;

procedure AssertBitMaskEqual(aTest: TTestCase; const aLabel: string; aExpectedMask: Word; const aActual: TM128);
var
  LIndex: Integer;
begin
  aTest.AssertEquals(aLabel + ' low mask', QWord(aExpectedMask), QWord(aActual.m128i_u16[0]));
  for LIndex := 2 to 15 do
    aTest.AssertEquals(aLabel + ' high byte ' + IntToStr(LIndex), QWord(0), QWord(aActual.m128i_u8[LIndex]));
end;

function ReferenceCrc32CByte(aCRC: Cardinal; aData: Byte): Cardinal;
const
  CRC32C_REFLECTED_POLY = $82F63B78;
var
  LBit: Integer;
begin
  Result := aCRC xor aData;
  for LBit := 0 to 7 do
  begin
    if (Result and 1) <> 0 then
      Result := (Result shr 1) xor CRC32C_REFLECTED_POLY
    else
      Result := Result shr 1;
  end;
end;

function ReferenceCrc32CWord(aCRC: Cardinal; aData: Word): Cardinal;
begin
  Result := ReferenceCrc32CByte(aCRC, Byte(aData));
  Result := ReferenceCrc32CByte(Result, Byte(aData shr 8));
end;

function ReferenceCrc32CDWord(aCRC: Cardinal; aData: Cardinal): Cardinal;
begin
  Result := ReferenceCrc32CByte(aCRC, Byte(aData));
  Result := ReferenceCrc32CByte(Result, Byte(aData shr 8));
  Result := ReferenceCrc32CByte(Result, Byte(aData shr 16));
  Result := ReferenceCrc32CByte(Result, Byte(aData shr 24));
end;

function ReferenceCrc32CQWord(aCRC: Cardinal; aData: QWord): Cardinal;
begin
  Result := ReferenceCrc32CDWord(aCRC, Cardinal(aData));
  Result := ReferenceCrc32CDWord(Result, Cardinal(aData shr 32));
end;

procedure TTestCase_Sse42FacadeExperimental.Test_Crc32CastagnoliSemantics;
var
  LCRC: Cardinal;
  LExpected: Cardinal;
  LIndex: Integer;
  LText: AnsiString;
begin
  LText := '123456789';
  LCRC := $FFFFFFFF;
  for LIndex := 1 to Length(LText) do
    LCRC := sse42_crc32_u8(LCRC, Ord(LText[LIndex]));
  AssertEquals('crc32c standard check vector', QWord($E3069283), QWord(LCRC xor $FFFFFFFF));

  LExpected := ReferenceCrc32CWord($13579BDF, $BEEF);
  AssertEquals('sse42_crc32_u16', QWord(LExpected), QWord(sse42_crc32_u16($13579BDF, $BEEF)));

  LExpected := ReferenceCrc32CDWord($2468ACE0, $89ABCDEF);
  AssertEquals('sse42_crc32_u32', QWord(LExpected), QWord(sse42_crc32_u32($2468ACE0, $89ABCDEF)));

  LExpected := ReferenceCrc32CQWord($CAFEBABE, QWord($0123456789ABCDEF));
  AssertEquals('sse42_crc32_u64', QWord(LExpected), sse42_crc32_u64($00000000CAFEBABE, QWord($0123456789ABCDEF)));
end;

procedure TTestCase_Sse42FacadeExperimental.Test_CmpGtEpi64Semantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  FillChar(LA, SizeOf(LA), 0);
  FillChar(LB, SizeOf(LB), 0);
  FillChar(LExpected, SizeOf(LExpected), 0);

  LA.m128i_i64[0] := -1;
  LA.m128i_i64[1] := 1234567890123;
  LB.m128i_i64[0] := -2;
  LB.m128i_i64[1] := 1234567890123;
  LExpected.m128i_u64[0] := $FFFFFFFFFFFFFFFF;
  LExpected.m128i_u64[1] := 0;

  AssertM128U64Equal(Self, 'sse42_cmpgt_epi64', LExpected, sse42_cmpgt_epi64(LA, LB));
end;

procedure TTestCase_Sse42FacadeExperimental.Test_ExplicitStringEqualAnySubset;
var
  LA: TM128;
  LB: TM128;
  LMask: TM128;
begin
  FillM128BytesFromString(LA, 'abcde');
  FillM128BytesFromString(LB, 'xce');

  LMask := sse42_cmpestrm(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE);
  AssertBitMaskEqual(Self, 'sse42_cmpestrm', (1 shl 2) or (1 shl 4), LMask);
  AssertEquals('sse42_cmpestri first match', 2, sse42_cmpestri(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpestrc should report a non-zero result mask', sse42_cmpestrc(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));
  AssertFalse('sse42_cmpestro should mirror mask bit 0', sse42_cmpestro(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpestrs should report first explicit string shorter than 16 bytes', sse42_cmpestrs(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpestrz should report second explicit string shorter than 16 bytes', sse42_cmpestrz(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));

  FillM128BytesFromString(LB, 'xyz');
  LMask := sse42_cmpestrm(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE);
  AssertBitMaskEqual(Self, 'sse42_cmpestrm no match', 0, LMask);
  AssertEquals('sse42_cmpestri no match', 16, sse42_cmpestri(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));
  AssertFalse('sse42_cmpestrc no match', sse42_cmpestrc(LA, 5, LB, 3, SSE42_EQUAL_ANY_UBYTE));
end;

procedure TTestCase_Sse42FacadeExperimental.Test_ImplicitStringEqualAnySubset;
var
  LA: TM128;
  LB: TM128;
  LMask: TM128;
begin
  FillM128BytesFromString(LA, 'cab');
  FillM128BytesFromString(LB, 'cx');

  LMask := sse42_cmpistrm(LA, LB, SSE42_EQUAL_ANY_UBYTE);
  AssertBitMaskEqual(Self, 'sse42_cmpistrm', 1, LMask);
  AssertEquals('sse42_cmpistri first match', 0, sse42_cmpistri(LA, LB, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpistrc should report a non-zero result mask', sse42_cmpistrc(LA, LB, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpistro should mirror mask bit 0', sse42_cmpistro(LA, LB, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpistrs should report null terminator in first string', sse42_cmpistrs(LA, LB, SSE42_EQUAL_ANY_UBYTE));
  AssertTrue('sse42_cmpistrz should report null terminator in second string', sse42_cmpistrz(LA, LB, SSE42_EQUAL_ANY_UBYTE));
end;

procedure TTestCase_Sse42FacadeExperimental.Test_StringCompareUnsupportedControlsRaise;
var
  LA: TM128;
  LB: TM128;
  LRaised: Boolean;
  LResult: TM128;
begin
  FillM128BytesFromString(LA, 'abc');
  FillM128BytesFromString(LB, 'a');

  LRaised := False;
  try
    LResult := sse42_cmpestrm(LA, 3, LB, 1, 4);
    if LResult.m128i_u8[0] = 255 then
      ;
  except
    on E: ENotSupportedException do
      LRaised := True;
  end;
  AssertTrue('sse42_cmpestrm unsupported controls should raise', LRaised);

  LRaised := False;
  try
    LResult := sse42_cmpistrm(LA, LB, 4);
    if LResult.m128i_u8[0] = 255 then
      ;
  except
    on E: ENotSupportedException do
      LRaised := True;
  end;
  AssertTrue('sse42_cmpistrm unsupported controls should raise', LRaised);
end;

initialization
  RegisterTest(TTestCase_Sse42FacadeExperimental);

end.
