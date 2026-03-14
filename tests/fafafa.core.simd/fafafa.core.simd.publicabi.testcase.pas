unit fafafa.core.simd.publicabi.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.api;

type
  TTestCase_PublicAbi = class(TTestCase)
  published
    procedure Test_PublicApi_Table_IsBound_And_Metadata_IsPresent;
    procedure Test_PublicApi_Table_Refreshes_AfterBackendSwitch;
    procedure Test_PublicApi_BackendPodInfo_Flags_AreSelfConsistent;
    procedure Test_PublicApi_DataPlane_Parity;
  end;

implementation

procedure TTestCase_PublicAbi.Test_PublicApi_Table_IsBound_And_Metadata_IsPresent;
var
  LApi: PFafafaSimdPublicApi;
begin
  LApi := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil', LApi);
  AssertEquals('StructSize should match record size',
    SizeOf(TFafafaSimdPublicApi), LApi^.StructSize);
  AssertEquals('ABI major should match getter',
    GetSimdAbiVersionMajor, LApi^.AbiVersionMajor);
  AssertEquals('ABI minor should match getter',
    GetSimdAbiVersionMinor, LApi^.AbiVersionMinor);
  AssertTrue('ABI signature hi should be non-zero', LApi^.AbiSignatureHi <> 0);
  AssertTrue('ABI signature lo should be non-zero', LApi^.AbiSignatureLo <> 0);
  AssertEquals('Active backend id should match current backend',
    Ord(GetCurrentBackend), Integer(LApi^.ActiveBackendId));
  AssertTrue('MemEqual function pointer should be bound', Assigned(LApi^.MemEqual));
  AssertTrue('MemFindByte function pointer should be bound', Assigned(LApi^.MemFindByte));
  AssertTrue('MemDiffRange function pointer should be bound', Assigned(LApi^.MemDiffRange));
  AssertTrue('SumBytes function pointer should be bound', Assigned(LApi^.SumBytes));
  AssertTrue('CountByte function pointer should be bound', Assigned(LApi^.CountByte));
  AssertTrue('BitsetPopCount function pointer should be bound', Assigned(LApi^.BitsetPopCount));
  AssertTrue('Utf8Validate function pointer should be bound', Assigned(LApi^.Utf8Validate));
  AssertTrue('AsciiIEqual function pointer should be bound', Assigned(LApi^.AsciiIEqual));
  AssertTrue('BytesIndexOf function pointer should be bound', Assigned(LApi^.BytesIndexOf));
  AssertTrue('MemCopy function pointer should be bound', Assigned(LApi^.MemCopy));
  AssertTrue('MemSet function pointer should be bound', Assigned(LApi^.MemSet));
  AssertTrue('ToLowerAscii function pointer should be bound', Assigned(LApi^.ToLowerAscii));
  AssertTrue('ToUpperAscii function pointer should be bound', Assigned(LApi^.ToUpperAscii));
  AssertTrue('MemReverse function pointer should be bound', Assigned(LApi^.MemReverse));
  AssertTrue('MinMaxBytes function pointer should be bound', Assigned(LApi^.MinMaxBytes));
end;

procedure TTestCase_PublicAbi.Test_PublicApi_Table_Refreshes_AfterBackendSwitch;
var
  LApi: PFafafaSimdPublicApi;
  LOriginalBackend: TSimdBackend;
  LOriginalDispatchable: TSimdBackend;
  LDispatchable: TSimdBackendArray;
  LTargetBackend: TSimdBackend;
  LFoundDifferent: Boolean;
  LIndex: Integer;
begin
  LApi := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil', LApi);
  LOriginalBackend := GetCurrentBackend;
  LOriginalDispatchable := GetBestDispatchableBackend;

  LDispatchable := GetDispatchableBackendList;
  LTargetBackend := LOriginalBackend;
  LFoundDifferent := False;
  for LIndex := 0 to High(LDispatchable) do
    if LDispatchable[LIndex] <> LOriginalBackend then
    begin
      LTargetBackend := LDispatchable[LIndex];
      LFoundDifferent := True;
      Break;
    end;

  try
    AssertTrue('TrySetActiveBackend(sbScalar) should succeed', TrySetActiveBackend(sbScalar));
    AssertEquals('Public API active backend should refresh to Scalar',
      Ord(sbScalar), Integer(GetSimdPublicApi^.ActiveBackendId));

    if LFoundDifferent then
    begin
      AssertTrue('TrySetActiveBackend(target) should succeed', TrySetActiveBackend(LTargetBackend));
      AssertEquals('Public API active backend should refresh to target backend',
        Ord(LTargetBackend), Integer(GetSimdPublicApi^.ActiveBackendId));
    end;
  finally
    ResetToAutomaticBackend;
  end;

  AssertEquals('Public API active backend should refresh after reset-to-auto',
    Ord(GetCurrentBackend), Integer(GetSimdPublicApi^.ActiveBackendId));
  AssertEquals('ResetToAutomaticBackend should restore best dispatchable backend',
    Ord(LOriginalDispatchable), Ord(GetCurrentBackend));
end;

procedure TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_Flags_AreSelfConsistent;
var
  LBackend: TSimdBackend;
  LInfo: TFafafaSimdBackendPodInfo;
  LNamePtr: PAnsiChar;
begin
  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    AssertTrue('TryGetSimdBackendPodInfo should succeed for backend=' + IntToStr(Ord(LBackend)),
      TryGetSimdBackendPodInfo(LBackend, LInfo));
    AssertEquals('StructSize mismatch for backend=' + IntToStr(Ord(LBackend)),
      SizeOf(TFafafaSimdBackendPodInfo), LInfo.StructSize);
    AssertEquals('BackendId mismatch for backend=' + IntToStr(Ord(LBackend)),
      Ord(LBackend), Integer(LInfo.BackendId));

    if IsBackendAvailableOnCPU(LBackend) then
      AssertTrue('supported_on_cpu flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) <> 0)
    else
      AssertTrue('supported_on_cpu flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) = 0);

    if IsBackendRegisteredInBinary(LBackend) then
      AssertTrue('registered flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_REGISTERED) <> 0)
    else
      AssertTrue('registered flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_REGISTERED) = 0);

    if IsBackendDispatchable(LBackend) then
      AssertTrue('dispatchable flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) <> 0)
    else
      AssertTrue('dispatchable flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_DISPATCHABLE) = 0);

    if GetCurrentBackend = LBackend then
      AssertTrue('active flag missing for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) <> 0)
    else
      AssertTrue('active flag should be clear for backend=' + IntToStr(Ord(LBackend)),
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_ACTIVE) = 0);

    if LBackend = sbRISCVV then
      AssertTrue('experimental flag missing for RISCVV',
        (LInfo.Flags and FAF_SIMD_ABI_FLAG_EXPERIMENTAL) <> 0);

    LNamePtr := GetSimdBackendNamePtr(LBackend);
    AssertNotNull('Backend name pointer should not be nil for backend=' + IntToStr(Ord(LBackend)), Pointer(LNamePtr));
    AssertTrue('Backend name should not be empty for backend=' + IntToStr(Ord(LBackend)), LNamePtr^ <> #0);
  end;
end;

procedure TTestCase_PublicAbi.Test_PublicApi_DataPlane_Parity;
var
  LApi: PFafafaSimdPublicApi;
  LA, LB: array[0..31] of Byte;
  LIdx: Integer;
  LSumApi, LSumFacade: UInt64;
  LCountApi, LCountFacade: SizeUInt;
  LPopApi, LPopFacade: SizeUInt;
  LEqApi, LEqFacade: LongBool;
  LFindApi, LFindFacade: PtrInt;
  LDiffApi, LDiffFacade: Boolean;
  LFirstApi, LLastApi: SizeUInt;
  LFirstFacade, LLastFacade: SizeUInt;
  LUtfApi, LUtfFacade: Boolean;
  LAsciiApi, LAsciiFacade: Boolean;
  LBytesApi, LBytesFacade: PtrInt;
  LNeedle: array[0..2] of Byte;
  LUtf8Text: RawByteString;
  LAsciiA, LAsciiB: RawByteString;
  LCopyApi, LCopyFacade: array[0..31] of Byte;
  LFillApi, LFillFacade: array[0..31] of Byte;
  LRevApi, LRevFacade: array[0..7] of Byte;
  LLowerApi, LLowerFacade: RawByteString;
  LUpperApi, LUpperFacade: RawByteString;
  LMinApi, LMaxApi: Byte;
  LMinFacade, LMaxFacade: Byte;
begin
  LApi := GetSimdPublicApi;
  AssertNotNull('Public API table should not be nil', LApi);

  for LIdx := 0 to High(LA) do
  begin
    LA[LIdx] := Byte((LIdx * 7) and $FF);
    LB[LIdx] := LA[LIdx];
  end;
  LB[17] := $AA;

  LEqApi := LApi^.MemEqual(@LA[0], @LA[0], Length(LA));
  LEqFacade := MemEqual(@LA[0], @LA[0], Length(LA));
  AssertEquals('MemEqual parity', LEqFacade, LEqApi);

  LFindApi := LApi^.MemFindByte(@LB[0], Length(LB), $AA);
  LFindFacade := MemFindByte(@LB[0], Length(LB), $AA);
  AssertEquals('MemFindByte parity', LFindFacade, LFindApi);

  LFirstApi := 0;
  LLastApi := 0;
  LFirstFacade := 0;
  LLastFacade := 0;
  LDiffApi := LApi^.MemDiffRange(@LA[0], @LB[0], Length(LA), LFirstApi, LLastApi);
  LDiffFacade := MemDiffRange(@LA[0], @LB[0], Length(LA), LFirstFacade, LLastFacade);
  AssertEquals('MemDiffRange parity(hasDiff)', LDiffFacade, LDiffApi);
  AssertEquals('MemDiffRange parity(firstDiff)', LFirstFacade, LFirstApi);
  AssertEquals('MemDiffRange parity(lastDiff)', LLastFacade, LLastApi);

  LSumApi := LApi^.SumBytes(@LA[0], Length(LA));
  LSumFacade := SumBytes(@LA[0], Length(LA));
  AssertEquals('SumBytes parity', LSumFacade, LSumApi);

  LCountApi := LApi^.CountByte(@LB[0], Length(LB), $AA);
  LCountFacade := CountByte(@LB[0], Length(LB), $AA);
  AssertEquals('CountByte parity', LCountFacade, LCountApi);

  LPopApi := LApi^.BitsetPopCount(@LA[0], Length(LA));
  LPopFacade := BitsetPopCount(@LA[0], Length(LA));
  AssertEquals('BitsetPopCount parity', LPopFacade, LPopApi);

  LUtf8Text := UTF8Encode('simd-测试-123');
  LUtfApi := LApi^.Utf8Validate(@LUtf8Text[1], Length(LUtf8Text));
  LUtfFacade := Utf8Validate(@LUtf8Text[1], Length(LUtf8Text));
  AssertEquals('Utf8Validate parity', LUtfFacade, LUtfApi);

  LAsciiA := 'AbCdEf012';
  LAsciiB := 'aBcDeF012';
  LAsciiApi := LApi^.AsciiIEqual(@LAsciiA[1], @LAsciiB[1], Length(LAsciiA));
  LAsciiFacade := AsciiIEqual(@LAsciiA[1], @LAsciiB[1], Length(LAsciiA));
  AssertEquals('AsciiIEqual parity', LAsciiFacade, LAsciiApi);

  LNeedle[0] := LA[7];
  LNeedle[1] := LA[8];
  LNeedle[2] := LA[9];
  LBytesApi := LApi^.BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  LBytesFacade := BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  AssertEquals('BytesIndexOf parity(hit)', LBytesFacade, LBytesApi);

  LNeedle[0] := $FE;
  LNeedle[1] := $ED;
  LNeedle[2] := $DC;
  LBytesApi := LApi^.BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  LBytesFacade := BytesIndexOf(@LA[0], Length(LA), @LNeedle[0], Length(LNeedle));
  AssertEquals('BytesIndexOf parity(miss)', LBytesFacade, LBytesApi);

  FillChar(LCopyApi[0], SizeOf(LCopyApi), 0);
  FillChar(LCopyFacade[0], SizeOf(LCopyFacade), 0);
  LApi^.MemCopy(@LA[0], @LCopyApi[0], Length(LA));
  MemCopy(@LA[0], @LCopyFacade[0], Length(LA));
  AssertTrue('MemCopy parity', MemEqual(@LCopyApi[0], @LCopyFacade[0], Length(LA)));

  FillChar(LFillApi[0], SizeOf(LFillApi), 0);
  FillChar(LFillFacade[0], SizeOf(LFillFacade), 0);
  LApi^.MemSet(@LFillApi[0], Length(LFillApi), $5A);
  MemSet(@LFillFacade[0], Length(LFillFacade), $5A);
  AssertTrue('MemSet parity', MemEqual(@LFillApi[0], @LFillFacade[0], Length(LFillApi)));

  LLowerApi := 'AbCdEf012';
  LLowerFacade := LLowerApi;
  LApi^.ToLowerAscii(@LLowerApi[1], Length(LLowerApi));
  ToLowerAscii(@LLowerFacade[1], Length(LLowerFacade));
  AssertEquals('ToLowerAscii parity', LLowerFacade, LLowerApi);
  AssertEquals('ToLowerAscii expected', 'abcdef012', LLowerApi);

  LUpperApi := 'AbCdEf012';
  LUpperFacade := LUpperApi;
  LApi^.ToUpperAscii(@LUpperApi[1], Length(LUpperApi));
  ToUpperAscii(@LUpperFacade[1], Length(LUpperFacade));
  AssertEquals('ToUpperAscii parity', LUpperFacade, LUpperApi);
  AssertEquals('ToUpperAscii expected', 'ABCDEF012', LUpperApi);

  LRevApi[0] := 1;
  LRevApi[1] := 2;
  LRevApi[2] := 3;
  LRevApi[3] := 4;
  LRevApi[4] := 5;
  LRevApi[5] := 6;
  LRevApi[6] := 7;
  LRevApi[7] := 8;
  LRevFacade := LRevApi;
  LApi^.MemReverse(@LRevApi[0], Length(LRevApi));
  MemReverse(@LRevFacade[0], Length(LRevFacade));
  AssertTrue('MemReverse parity', MemEqual(@LRevApi[0], @LRevFacade[0], Length(LRevApi)));

  LMinApi := 0;
  LMaxApi := 0;
  LMinFacade := 0;
  LMaxFacade := 0;
  LApi^.MinMaxBytes(@LA[0], Length(LA), LMinApi, LMaxApi);
  MinMaxBytes(@LA[0], Length(LA), LMinFacade, LMaxFacade);
  AssertEquals('MinMaxBytes parity(min)', LMinFacade, LMinApi);
  AssertEquals('MinMaxBytes parity(max)', LMaxFacade, LMaxApi);
end;

initialization
  RegisterTest(TTestCase_PublicAbi);

end.
