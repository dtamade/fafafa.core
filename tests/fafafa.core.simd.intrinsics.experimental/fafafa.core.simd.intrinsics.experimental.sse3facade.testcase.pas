unit fafafa.core.simd.intrinsics.experimental.sse3facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse3;

type
  TTestCase_Sse3FacadeExperimental = class(TTestCase)
  published
    procedure Test_HorizontalPackedSingleSemantics;
    procedure Test_HorizontalPackedDoubleSemantics;
    procedure Test_AddSubAlternatingSemantics;
    procedure Test_LoadAndDuplicateSemantics;
    procedure Test_MonitorMwait_AreExplicitNoOps;
  end;

implementation

procedure InitM128F32(var aValue: TM128; a0, a1, a2, a3: Single);
begin
  FillChar(aValue, SizeOf(aValue), 0);
  aValue.m128_f32[0] := a0;
  aValue.m128_f32[1] := a1;
  aValue.m128_f32[2] := a2;
  aValue.m128_f32[3] := a3;
end;

procedure InitM128F64(var aValue: TM128; a0, a1: Double);
begin
  FillChar(aValue, SizeOf(aValue), 0);
  aValue.m128d_f64[0] := a0;
  aValue.m128d_f64[1] := a1;
end;

procedure AssertM128F32Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128_f32[LIndex], aActual.m128_f32[LIndex], 0.00001);
end;

procedure AssertM128F64Equal(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), aExpected.m128d_f64[LIndex], aActual.m128d_f64[LIndex], 0.0000000001);
end;

procedure AssertM128DWordsEqual(aTest: TTestCase; const aLabel: string; const aExpected, aActual: TM128);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    aTest.AssertEquals(aLabel + ' lane ' + IntToStr(LIndex), QWord(aExpected.m128i_u32[LIndex]), QWord(aActual.m128i_u32[LIndex]));
end;

procedure TTestCase_Sse3FacadeExperimental.Test_HorizontalPackedSingleSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  InitM128F32(LA, 1.0, 2.5, -4.0, 8.0);
  InitM128F32(LB, 10.0, -3.0, 7.5, 0.5);

  InitM128F32(LExpected, 3.5, 4.0, 7.0, 8.0);
  AssertM128F32Equal(Self, 'sse3_hadd_ps', LExpected, sse3_hadd_ps(LA, LB));

  InitM128F32(LExpected, 1.5, 12.0, -13.0, -7.0);
  AssertM128F32Equal(Self, 'sse3_hsub_ps', LExpected, sse3_hsub_ps(LA, LB));
end;

procedure TTestCase_Sse3FacadeExperimental.Test_HorizontalPackedDoubleSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  InitM128F64(LA, 4.0, 1.25);
  InitM128F64(LB, -2.0, 9.5);

  InitM128F64(LExpected, 5.25, 7.5);
  AssertM128F64Equal(Self, 'sse3_hadd_pd', LExpected, sse3_hadd_pd(LA, LB));

  InitM128F64(LExpected, -2.75, 11.5);
  AssertM128F64Equal(Self, 'sse3_hsub_pd', LExpected, sse3_hsub_pd(LA, LB));
end;

procedure TTestCase_Sse3FacadeExperimental.Test_AddSubAlternatingSemantics;
var
  LA: TM128;
  LB: TM128;
  LExpected: TM128;
begin
  InitM128F32(LA, 9.0, 10.0, -6.0, 4.0);
  InitM128F32(LB, 1.5, 2.0, 3.0, -8.0);
  InitM128F32(LExpected, 7.5, 12.0, -9.0, -4.0);
  AssertM128F32Equal(Self, 'sse3_addsub_ps', LExpected, sse3_addsub_ps(LA, LB));

  InitM128F64(LA, 11.0, -4.0);
  InitM128F64(LB, 2.5, 8.0);
  InitM128F64(LExpected, 8.5, 4.0);
  AssertM128F64Equal(Self, 'sse3_addsub_pd', LExpected, sse3_addsub_pd(LA, LB));
end;

procedure TTestCase_Sse3FacadeExperimental.Test_LoadAndDuplicateSemantics;
var
  LInput: TM128;
  LExpected: TM128;
  LLoaded: TM128;
  LDoubleValue: Double;
begin
  FillChar(LInput, SizeOf(LInput), 0);
  LInput.m128i_u32[0] := $11223344;
  LInput.m128i_u32[1] := $55667788;
  LInput.m128i_u32[2] := $99AABBCC;
  LInput.m128i_u32[3] := $DDEEFF00;

  LLoaded := sse3_lddqu_si128(@LInput);
  AssertM128DWordsEqual(Self, 'sse3_lddqu_si128', LInput, LLoaded);

  InitM128F32(LInput, 1.0, 2.0, 3.0, 4.0);
  InitM128F32(LExpected, 2.0, 2.0, 4.0, 4.0);
  AssertM128F32Equal(Self, 'sse3_movehdup_ps', LExpected, sse3_movehdup_ps(LInput));

  InitM128F32(LExpected, 1.0, 1.0, 3.0, 3.0);
  AssertM128F32Equal(Self, 'sse3_moveldup_ps', LExpected, sse3_moveldup_ps(LInput));

  InitM128F64(LInput, -7.25, 99.0);
  InitM128F64(LExpected, -7.25, -7.25);
  AssertM128F64Equal(Self, 'sse3_movddup_pd', LExpected, sse3_movddup_pd(LInput));

  LDoubleValue := 42.125;
  InitM128F64(LExpected, 42.125, 42.125);
  AssertM128F64Equal(Self, 'sse3_loaddup_pd', LExpected, sse3_loaddup_pd(@LDoubleValue));
end;

procedure TTestCase_Sse3FacadeExperimental.Test_MonitorMwait_AreExplicitNoOps;
var
  LValue: Cardinal;
begin
  LValue := $12345678;

  sse3_monitor(@LValue, $11111111, $22222222);
  sse3_mwait($33333333, $44444444);

  AssertEquals('sse3_monitor/sse3_mwait must not mutate memory in fallback mode', QWord($12345678), QWord(LValue));
end;

initialization
  RegisterTest(TTestCase_Sse3FacadeExperimental);

end.
