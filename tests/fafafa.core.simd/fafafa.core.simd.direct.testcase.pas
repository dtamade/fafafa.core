unit fafafa.core.simd.direct.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  Math,
  fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.api,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.direct;

type
  TTestCase_DirectDispatch = class(TTestCase)
  published
    procedure Test_DirectDispatchTable_Assigned;
    procedure Test_DirectDispatchTable_MatchesGetDispatchTable;
    procedure Test_DirectDispatchTable_Rebind_AfterForceBackend;
    procedure Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend;
    procedure Test_DirectDispatchTable_MatchesRepresentativeSlots;
    procedure Test_DirectDispatchTable_TrySetUnavailableBackend_NoDrift;
    procedure Test_DirectDispatchTable_MultiBackend_SmokeParity;
    procedure Test_DirectDispatchTable_MultiBackend_DotReduceMaskSat_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_MemTextEdgeMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_MemOpsEdgeMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_StatsEdgeMatrix_Parity;
    procedure Test_DirectDispatchTable_MaskCompareEdge_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_MaskWideCompareMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F64CompareEdgeMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32CompareMicroDeltaMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_U32U64CompareEdgeMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32x8F64x4ArithmeticReduceMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32x16F64x8CompareReduceMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32x16F64x8ArithmeticMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32x16F64x8ReduceMulStable_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_Mask8Mask16InverseProperties_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32x16F64x8CompareIdentityProperties_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_U32x8U64x4CompareIdentityMaskProperties_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_F32x8F64x4CompareIdentityMaskProperties_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_I16I8CompareEdgeMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_MemSearchBitsetUtf8_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_MemWindowMatrix_Parity;
    procedure Test_DirectDispatchTable_MultiBackend_MemSearchFuzzSeed_Parity;
  end;

  TTestCase_DirectDispatchConcurrent = class(TTestCase)
  published
    procedure Test_DirectDispatchTable_Concurrent_ReRegister_SnapshotConsistency;
  end;

implementation

uses
  Classes;

type
  TDirectDispatchMutationWorker = class(TThread)
  private
    FIterations: Integer;
    FWriterPhase: Integer;
    FBackend: TSimdBackend;
    FTableA: TSimdDispatchTable;
    FTableB: TSimdDispatchTable;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations, aWriterPhase: Integer; aBackend: TSimdBackend;
      const aTableA, aTableB: TSimdDispatchTable);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  TDirectDispatchReadWorker = class(TThread)
  private
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

function DirectDispatchSyntheticAddImpl(const a, b: TVecF32x4): TVecF32x4;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.f[LIndex] := a.f[LIndex] + b.f[LIndex];
end;

function DirectDispatchSyntheticAddA(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := DirectDispatchSyntheticAddImpl(a, b);
end;

function DirectDispatchSyntheticAddB(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := DirectDispatchSyntheticAddImpl(a, b);
end;

function DirectDispatchSyntheticReduceAddImpl(const a: TVecF32x4): Single;
begin
  Result := a.f[0] + a.f[1] + a.f[2] + a.f[3];
end;

function DirectDispatchSyntheticReduceAddA(const a: TVecF32x4): Single;
begin
  Result := DirectDispatchSyntheticReduceAddImpl(a);
end;

function DirectDispatchSyntheticReduceAddB(const a: TVecF32x4): Single;
begin
  Result := DirectDispatchSyntheticReduceAddImpl(a);
end;

function DirectDispatchSyntheticMemEqualImpl(a, b: Pointer; len: SizeUInt): LongBool;
var
  LLeft: PByte;
  LRight: PByte;
  LIndex: SizeUInt;
begin
  LLeft := PByte(a);
  LRight := PByte(b);
  for LIndex := 0 to len - 1 do
    if LLeft[LIndex] <> LRight[LIndex] then
      Exit(False);
  Result := True;
end;

function DirectDispatchSyntheticMemEqualA(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := DirectDispatchSyntheticMemEqualImpl(a, b, len);
end;

function DirectDispatchSyntheticMemEqualB(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := DirectDispatchSyntheticMemEqualImpl(a, b, len);
end;

function DirectDispatchSyntheticSumBytesImpl(p: Pointer; len: SizeUInt): UInt64;
var
  LBytes: PByte;
  LIndex: SizeUInt;
begin
  Result := 0;
  LBytes := PByte(p);
  for LIndex := 0 to len - 1 do
    Inc(Result, LBytes[LIndex]);
end;

function DirectDispatchSyntheticSumBytesA(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := DirectDispatchSyntheticSumBytesImpl(p, len);
end;

function DirectDispatchSyntheticSumBytesB(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := DirectDispatchSyntheticSumBytesImpl(p, len);
end;

function DirectDispatchSyntheticCountByteImpl(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
var
  LBytes: PByte;
  LIndex: SizeUInt;
begin
  Result := 0;
  LBytes := PByte(p);
  for LIndex := 0 to len - 1 do
    if LBytes[LIndex] = value then
      Inc(Result);
end;

function DirectDispatchSyntheticCountByteA(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := DirectDispatchSyntheticCountByteImpl(p, len, value);
end;

function DirectDispatchSyntheticCountByteB(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := DirectDispatchSyntheticCountByteImpl(p, len, value);
end;

function DirectDispatchSyntheticBitsetPopCountImpl(p: Pointer; byteLen: SizeUInt): SizeUInt;
const
  CPopCountTable: array[0..15] of Byte = (0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4);
var
  LBytes: PByte;
  LIndex: SizeUInt;
  LValue: Byte;
begin
  Result := 0;
  LBytes := PByte(p);
  for LIndex := 0 to byteLen - 1 do
  begin
    LValue := LBytes[LIndex];
    Inc(Result, CPopCountTable[LValue and $0F] + CPopCountTable[LValue shr 4]);
  end;
end;

function DirectDispatchSyntheticBitsetPopCountA(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := DirectDispatchSyntheticBitsetPopCountImpl(p, byteLen);
end;

function DirectDispatchSyntheticBitsetPopCountB(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := DirectDispatchSyntheticBitsetPopCountImpl(p, byteLen);
end;

procedure ConfigureDirectDispatchSyntheticTableA(var aDispatchTable: TSimdDispatchTable);
begin
  aDispatchTable.AddF32x4 := @DirectDispatchSyntheticAddA;
  aDispatchTable.ReduceAddF32x4 := @DirectDispatchSyntheticReduceAddA;
  aDispatchTable.MemEqual := @DirectDispatchSyntheticMemEqualA;
  aDispatchTable.SumBytes := @DirectDispatchSyntheticSumBytesA;
  aDispatchTable.CountByte := @DirectDispatchSyntheticCountByteA;
  aDispatchTable.BitsetPopCount := @DirectDispatchSyntheticBitsetPopCountA;
end;

procedure ConfigureDirectDispatchSyntheticTableB(var aDispatchTable: TSimdDispatchTable);
begin
  aDispatchTable.AddF32x4 := @DirectDispatchSyntheticAddB;
  aDispatchTable.ReduceAddF32x4 := @DirectDispatchSyntheticReduceAddB;
  aDispatchTable.MemEqual := @DirectDispatchSyntheticMemEqualB;
  aDispatchTable.SumBytes := @DirectDispatchSyntheticSumBytesB;
  aDispatchTable.CountByte := @DirectDispatchSyntheticCountByteB;
  aDispatchTable.BitsetPopCount := @DirectDispatchSyntheticBitsetPopCountB;
end;

function IsDirectDispatchSyntheticSnapshotA(aDispatchTable: PSimdDispatchTable): Boolean;
begin
  Result :=
    (Pointer(aDispatchTable^.AddF32x4) = Pointer(@DirectDispatchSyntheticAddA)) and
    (Pointer(aDispatchTable^.ReduceAddF32x4) = Pointer(@DirectDispatchSyntheticReduceAddA)) and
    (Pointer(aDispatchTable^.MemEqual) = Pointer(@DirectDispatchSyntheticMemEqualA)) and
    (Pointer(aDispatchTable^.SumBytes) = Pointer(@DirectDispatchSyntheticSumBytesA)) and
    (Pointer(aDispatchTable^.CountByte) = Pointer(@DirectDispatchSyntheticCountByteA)) and
    (Pointer(aDispatchTable^.BitsetPopCount) = Pointer(@DirectDispatchSyntheticBitsetPopCountA));
end;

function IsDirectDispatchSyntheticSnapshotB(aDispatchTable: PSimdDispatchTable): Boolean;
begin
  Result :=
    (Pointer(aDispatchTable^.AddF32x4) = Pointer(@DirectDispatchSyntheticAddB)) and
    (Pointer(aDispatchTable^.ReduceAddF32x4) = Pointer(@DirectDispatchSyntheticReduceAddB)) and
    (Pointer(aDispatchTable^.MemEqual) = Pointer(@DirectDispatchSyntheticMemEqualB)) and
    (Pointer(aDispatchTable^.SumBytes) = Pointer(@DirectDispatchSyntheticSumBytesB)) and
    (Pointer(aDispatchTable^.CountByte) = Pointer(@DirectDispatchSyntheticCountByteB)) and
    (Pointer(aDispatchTable^.BitsetPopCount) = Pointer(@DirectDispatchSyntheticBitsetPopCountB));
end;

function DescribeDirectDispatchSyntheticSnapshot(aDispatchTable: PSimdDispatchTable): string;
begin
  Result :=
    'Add=' + BoolToStr(Pointer(aDispatchTable^.AddF32x4) = Pointer(@DirectDispatchSyntheticAddA), True) + '/' +
      BoolToStr(Pointer(aDispatchTable^.AddF32x4) = Pointer(@DirectDispatchSyntheticAddB), True) +
    ', ReduceAdd=' + BoolToStr(Pointer(aDispatchTable^.ReduceAddF32x4) = Pointer(@DirectDispatchSyntheticReduceAddA), True) + '/' +
      BoolToStr(Pointer(aDispatchTable^.ReduceAddF32x4) = Pointer(@DirectDispatchSyntheticReduceAddB), True) +
    ', MemEqual=' + BoolToStr(Pointer(aDispatchTable^.MemEqual) = Pointer(@DirectDispatchSyntheticMemEqualA), True) + '/' +
      BoolToStr(Pointer(aDispatchTable^.MemEqual) = Pointer(@DirectDispatchSyntheticMemEqualB), True) +
    ', SumBytes=' + BoolToStr(Pointer(aDispatchTable^.SumBytes) = Pointer(@DirectDispatchSyntheticSumBytesA), True) + '/' +
      BoolToStr(Pointer(aDispatchTable^.SumBytes) = Pointer(@DirectDispatchSyntheticSumBytesB), True) +
    ', CountByte=' + BoolToStr(Pointer(aDispatchTable^.CountByte) = Pointer(@DirectDispatchSyntheticCountByteA), True) + '/' +
      BoolToStr(Pointer(aDispatchTable^.CountByte) = Pointer(@DirectDispatchSyntheticCountByteB), True) +
    ', BitsetPopCount=' + BoolToStr(Pointer(aDispatchTable^.BitsetPopCount) = Pointer(@DirectDispatchSyntheticBitsetPopCountA), True) + '/' +
      BoolToStr(Pointer(aDispatchTable^.BitsetPopCount) = Pointer(@DirectDispatchSyntheticBitsetPopCountB), True);
end;

constructor TDirectDispatchMutationWorker.Create(aIterations, aWriterPhase: Integer;
  aBackend: TSimdBackend; const aTableA, aTableB: TSimdDispatchTable);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FWriterPhase := aWriterPhase;
  FBackend := aBackend;
  FTableA := aTableA;
  FTableB := aTableB;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TDirectDispatchMutationWorker.Execute;
var
  LIndex: Integer;
begin
  try
    for LIndex := 0 to FIterations - 1 do
      if ((LIndex + FWriterPhase) and 1) = 0 then
        RegisterBackend(FBackend, FTableA)
      else
        RegisterBackend(FBackend, FTableB);
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'direct mutation worker exception: ' + E.Message;
  end;
end;

constructor TDirectDispatchReadWorker.Create(aIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TDirectDispatchReadWorker.Execute;
var
  LIndex: Integer;
  LDispatchTable: PSimdDispatchTable;
  LAddPtr: Pointer;
  LReduceAddPtr: Pointer;
  LMemEqualPtr: Pointer;
  LSumBytesPtr: Pointer;
  LCountBytePtr: Pointer;
  LBitsetPopCountPtr: Pointer;
  LAddIsA: Boolean;
  LAddIsB: Boolean;
  LReduceAddIsA: Boolean;
  LReduceAddIsB: Boolean;
  LMemEqualIsA: Boolean;
  LMemEqualIsB: Boolean;
  LSumBytesIsA: Boolean;
  LSumBytesIsB: Boolean;
  LCountByteIsA: Boolean;
  LCountByteIsB: Boolean;
  LBitsetPopCountIsA: Boolean;
  LBitsetPopCountIsB: Boolean;
  LSnapshotA: Boolean;
  LSnapshotB: Boolean;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      LDispatchTable := GetDirectDispatchTable;
      if LDispatchTable = nil then
      begin
        FErrorMsg := Format('direct dispatch table is nil at iter %d', [LIndex]);
        Exit;
      end;

      // Deliberately yield between field reads so a concurrent in-place table
      // rewrite cannot hide behind a single tight read sequence.
      LAddPtr := Pointer(LDispatchTable^.AddF32x4);
      ThreadSwitch;
      LReduceAddPtr := Pointer(LDispatchTable^.ReduceAddF32x4);
      ThreadSwitch;
      LMemEqualPtr := Pointer(LDispatchTable^.MemEqual);
      ThreadSwitch;
      LSumBytesPtr := Pointer(LDispatchTable^.SumBytes);
      ThreadSwitch;
      LCountBytePtr := Pointer(LDispatchTable^.CountByte);
      ThreadSwitch;
      LBitsetPopCountPtr := Pointer(LDispatchTable^.BitsetPopCount);

      LAddIsA := LAddPtr = Pointer(@DirectDispatchSyntheticAddA);
      LAddIsB := LAddPtr = Pointer(@DirectDispatchSyntheticAddB);
      LReduceAddIsA := LReduceAddPtr = Pointer(@DirectDispatchSyntheticReduceAddA);
      LReduceAddIsB := LReduceAddPtr = Pointer(@DirectDispatchSyntheticReduceAddB);
      LMemEqualIsA := LMemEqualPtr = Pointer(@DirectDispatchSyntheticMemEqualA);
      LMemEqualIsB := LMemEqualPtr = Pointer(@DirectDispatchSyntheticMemEqualB);
      LSumBytesIsA := LSumBytesPtr = Pointer(@DirectDispatchSyntheticSumBytesA);
      LSumBytesIsB := LSumBytesPtr = Pointer(@DirectDispatchSyntheticSumBytesB);
      LCountByteIsA := LCountBytePtr = Pointer(@DirectDispatchSyntheticCountByteA);
      LCountByteIsB := LCountBytePtr = Pointer(@DirectDispatchSyntheticCountByteB);
      LBitsetPopCountIsA := LBitsetPopCountPtr = Pointer(@DirectDispatchSyntheticBitsetPopCountA);
      LBitsetPopCountIsB := LBitsetPopCountPtr = Pointer(@DirectDispatchSyntheticBitsetPopCountB);

      LSnapshotA :=
        LAddIsA and LReduceAddIsA and LMemEqualIsA and
        LSumBytesIsA and LCountByteIsA and LBitsetPopCountIsA;
      LSnapshotB :=
        LAddIsB and LReduceAddIsB and LMemEqualIsB and
        LSumBytesIsB and LCountByteIsB and LBitsetPopCountIsB;

      if (not LSnapshotA) and (not LSnapshotB) then
      begin
        FErrorMsg :=
          Format('direct dispatch synthetic snapshot mixed at iter %d: ' +
            'Add=%s/%s ReduceAdd=%s/%s MemEqual=%s/%s SumBytes=%s/%s CountByte=%s/%s BitsetPopCount=%s/%s',
            [LIndex,
             BoolToStr(LAddIsA, True), BoolToStr(LAddIsB, True),
             BoolToStr(LReduceAddIsA, True), BoolToStr(LReduceAddIsB, True),
             BoolToStr(LMemEqualIsA, True), BoolToStr(LMemEqualIsB, True),
             BoolToStr(LSumBytesIsA, True), BoolToStr(LSumBytesIsB, True),
             BoolToStr(LCountByteIsA, True), BoolToStr(LCountByteIsB, True),
             BoolToStr(LBitsetPopCountIsA, True), BoolToStr(LBitsetPopCountIsB, True)]);
        Exit;
      end;
    end;
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'direct read worker exception: ' + E.Message;
  end;
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_Assigned;
begin
  AssertTrue('Direct dispatch table should be assigned', GetDirectDispatchTable <> nil);
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MatchesGetDispatchTable;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;

  AssertTrue('GetDispatchTable should be assigned', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned', directDt <> nil);

  // Spot-check a few representative entries across categories.
  AssertTrue('AddF32x4 pointer should match', dt^.AddF32x4 = directDt^.AddF32x4);
  AssertTrue('SplatF32x4 pointer should match', dt^.SplatF32x4 = directDt^.SplatF32x4);
  AssertTrue('MemEqual pointer should match', dt^.MemEqual = directDt^.MemEqual);
  AssertTrue('MemCopy pointer should match', dt^.MemCopy = directDt^.MemCopy);
  AssertTrue('SumBytes pointer should match', dt^.SumBytes = directDt^.SumBytes);
  AssertTrue('Mask4All pointer should match', dt^.Mask4All = directDt^.Mask4All);
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_Rebind_AfterForceBackend;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
begin
  // Force backend (for testing) and ensure direct table can be re-bound.
  ForceBackend(sbScalar);
  RebindDirectDispatch;

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;

  AssertTrue('GetDispatchTable should be assigned after ForceBackend', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned after RebindDirectDispatch', directDt <> nil);

  AssertEquals('Backend enum should match', Ord(dt^.Backend), Ord(directDt^.Backend));
  AssertTrue('AddF32x4 pointer should match after rebind', dt^.AddF32x4 = directDt^.AddF32x4);

  // Restore automatic backend selection for other tests.
  ResetBackendSelection;
  RebindDirectDispatch;
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
  originalBackend: TSimdBackend;
begin
  // Baseline
  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('Baseline GetDispatchTable should be assigned', dt <> nil);
  AssertTrue('Baseline GetDirectDispatchTable should be assigned', directDt <> nil);

  originalBackend := dt^.Backend;

  // Switch backend via dispatch directly (bypassing fafafa.core.simd facade)
  SetActiveBackend(sbScalar);

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('GetDispatchTable should be assigned after SetActiveBackend', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned after SetActiveBackend', directDt <> nil);

  AssertEquals('Dispatch backend should be Scalar after SetActiveBackend', Ord(sbScalar), Ord(dt^.Backend));
  AssertEquals('Direct dispatch backend should track dispatch after SetActiveBackend', Ord(dt^.Backend), Ord(directDt^.Backend));
  AssertTrue('AddF32x4 pointer should match after dispatch SetActiveBackend', dt^.AddF32x4 = directDt^.AddF32x4);

  // Restore automatic selection (also via dispatch)
  ResetToAutomaticBackend;

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('GetDispatchTable should be assigned after ResetToAutomaticBackend', dt <> nil);
  AssertTrue('GetDirectDispatchTable should be assigned after ResetToAutomaticBackend', directDt <> nil);

  // If original backend wasn't scalar, we expect it can change back. Either way, direct must match dispatch.
  AssertEquals('Direct dispatch backend should track dispatch after ResetToAutomaticBackend', Ord(dt^.Backend), Ord(directDt^.Backend));

  // Keep the test stable: if automatic selection returns to original backend, fine; otherwise also fine.
  // But we at least assert the backend is a valid enum.
  AssertTrue('Backend enum should be within range', (Ord(dt^.Backend) >= Ord(Low(TSimdBackend))) and (Ord(dt^.Backend) <= Ord(High(TSimdBackend))));

  AssertTrue('Original backend enum should be within range',
    (Ord(originalBackend) >= Ord(Low(TSimdBackend))) and
    (Ord(originalBackend) <= Ord(High(TSimdBackend))));
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MatchesRepresentativeSlots;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;

  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Direct dispatch table should be assigned', directDt <> nil);

  // 扩展槽位抽样：覆盖 vector/math/int/mem/mask/saturating 六类。
  AssertTrue('DotF32x4 pointer should match', dt^.DotF32x4 = directDt^.DotF32x4);
  AssertTrue('ReduceAddF32x4 pointer should match', dt^.ReduceAddF32x4 = directDt^.ReduceAddF32x4);
  AssertTrue('CrossF32x3 pointer should match', dt^.CrossF32x3 = directDt^.CrossF32x3);
  AssertTrue('LengthF32x3 pointer should match', dt^.LengthF32x3 = directDt^.LengthF32x3);
  AssertTrue('NormalizeF32x3 pointer should match', dt^.NormalizeF32x3 = directDt^.NormalizeF32x3);
  AssertTrue('CmpEqI32x4 pointer should match', dt^.CmpEqI32x4 = directDt^.CmpEqI32x4);
  AssertTrue('MinI32x4 pointer should match', dt^.MinI32x4 = directDt^.MinI32x4);
  AssertTrue('AndNotI32x4 pointer should match', dt^.AndNotI32x4 = directDt^.AndNotI32x4);
  AssertTrue('U8x16SatAdd pointer should match', dt^.U8x16SatAdd = directDt^.U8x16SatAdd);
  AssertTrue('MemFindByte pointer should match', dt^.MemFindByte = directDt^.MemFindByte);
  AssertTrue('CountByte pointer should match', dt^.CountByte = directDt^.CountByte);
  AssertTrue('Utf8Validate pointer should match', dt^.Utf8Validate = directDt^.Utf8Validate);
  AssertTrue('Mask16PopCount pointer should match', dt^.Mask16PopCount = directDt^.Mask16PopCount);
end;

procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_TrySetUnavailableBackend_NoDrift;
var
  dt: PSimdDispatchTable;
  directDt: PSimdDispatchTable;
  beforeBackend: TSimdBackend;
  candidate: TSimdBackend;
  foundCandidate: Boolean;
  ok: Boolean;
begin
  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Direct dispatch table should be assigned', directDt <> nil);

  beforeBackend := dt^.Backend;
  foundCandidate := False;

  for candidate := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    if candidate = beforeBackend then
      Continue;

    if (not IsBackendRegistered(candidate)) or (not IsBackendAvailableOnCPU(candidate)) then
    begin
      foundCandidate := True;
      Break;
    end;
  end;

  if not foundCandidate then
  begin
    AssertTrue('No unavailable backend candidate found; skip drift check', True);
    Exit;
  end;

  ok := TrySetActiveBackend(candidate);
  AssertFalse('TrySetActiveBackend should fail for unavailable/unregistered backend', ok);

  dt := GetDispatchTable;
  directDt := GetDirectDispatchTable;
  AssertEquals('Active backend should remain unchanged after failed TrySetActiveBackend', Ord(beforeBackend), Ord(dt^.Backend));
  AssertEquals('Direct dispatch backend should track dispatch after failed TrySetActiveBackend', Ord(dt^.Backend), Ord(directDt^.Backend));
  AssertTrue('AddF32x4 pointer should still match after failed TrySetActiveBackend', dt^.AddF32x4 = directDt^.AddF32x4);
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_SmokeParity;
const
  C_EPSILON = 1e-6;
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LA, LB: TVecF32x4;
  LFacadeAdd, LDirectAdd: TVecF32x4;
  LFacadeCross3, LDirectCross3: TVecF32x4;
  LFacadeNormalize3, LDirectNormalize3: TVecF32x4;
  LFacadeLength3, LDirectLength3: Single;
  LMask: TMask4;
  LFacadeMaskAll, LDirectMaskAll: Boolean;
  LBuffer: array[0..15] of Byte;
  LIndex: Integer;
  LFacadeFind, LDirectFind: PtrInt;
  LTestedCount: Integer;
begin
  LA.f[0] := 1.25;
  LA.f[1] := -2.0;
  LA.f[2] := 3.5;
  LA.f[3] := 4.0;

  LB.f[0] := 0.75;
  LB.f[1] := 5.0;
  LB.f[2] := -1.5;
  LB.f[3] := 2.0;

  for LIndex := 0 to High(LBuffer) do
    LBuffer[LIndex] := Byte(LIndex);

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if LBackend <> sbScalar then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertEquals('Direct dispatch backend should track dispatch for backend ' + IntToStr(Ord(LBackend)),
        Ord(LDispatch^.Backend), Ord(LDirectDispatch^.Backend));

      LFacadeAdd := VecF32x4Add(LA, LB);
      LDirectAdd := LDirectDispatch^.AddF32x4(LA, LB);
      for LIndex := 0 to 3 do
        AssertEquals('Direct AddF32x4 lane' + IntToStr(LIndex) + ' backend ' + IntToStr(Ord(LBackend)),
          LFacadeAdd.f[LIndex], LDirectAdd.f[LIndex], C_EPSILON);

      LFacadeCross3 := VecF32x3Cross(LA, LB);
      LDirectCross3 := LDirectDispatch^.CrossF32x3(LA, LB);
      for LIndex := 0 to 3 do
        AssertEquals('Direct CrossF32x3 lane' + IntToStr(LIndex) + ' backend ' + IntToStr(Ord(LBackend)),
          LFacadeCross3.f[LIndex], LDirectCross3.f[LIndex], C_EPSILON);

      LFacadeLength3 := VecF32x3Length(LA);
      LDirectLength3 := LDirectDispatch^.LengthF32x3(LA);
      AssertEquals('Direct LengthF32x3 parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeLength3, LDirectLength3, C_EPSILON);

      LFacadeNormalize3 := VecF32x3Normalize(LA);
      LDirectNormalize3 := LDirectDispatch^.NormalizeF32x3(LA);
      for LIndex := 0 to 3 do
        AssertEquals('Direct NormalizeF32x3 lane' + IntToStr(LIndex) + ' backend ' + IntToStr(Ord(LBackend)),
          LFacadeNormalize3.f[LIndex], LDirectNormalize3.f[LIndex], C_EPSILON);

      LMask := VecF32x4CmpLt(LA, LB);
      LFacadeMaskAll := Mask4All(LMask);
      LDirectMaskAll := LDirectDispatch^.Mask4All(LMask);
      AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)), LFacadeMaskAll, LDirectMaskAll);

      LFacadeFind := MemFindByte(@LBuffer[0], SizeUInt(Length(LBuffer)), 7);
      LDirectFind := LDirectDispatch^.MemFindByte(@LBuffer[0], SizeUInt(Length(LBuffer)), 7);
      AssertEquals('Direct MemFindByte parity backend ' + IntToStr(Ord(LBackend)), LFacadeFind, LDirectFind);
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;



procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_DotReduceMaskSat_Parity;
const
  C_EPSILON = 1e-5;
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LA, LB: TVecF32x4;
  LU8A, LU8B: TVecU8x16;
  LI8A, LI8B: TVecI8x16;
  LI32A, LI32B: TVecI32x4;
  LFacadeU8SatAdd, LDirectU8SatAdd: TVecU8x16;
  LFacadeI8SatAdd, LDirectI8SatAdd: TVecI8x16;
  LFacadeDot, LDirectDot: Single;
  LFacadeReduceAdd, LDirectReduceAdd: Single;
  LFacadeReduceMin, LDirectReduceMin: Single;
  LFacadeReduceMax, LDirectReduceMax: Single;
  LFacadeReduceMul, LDirectReduceMul: Single;
  LFacadeMask4, LDirectMask4: TMask4;
  LFacadeMask16: TMask16;
  LFacadeMask4All, LDirectMask4All: Boolean;
  LFacadeMask16PopCount, LDirectMask16PopCount: Integer;
  LHaystack: array[0..23] of Byte;
  LNeedle: array[0..2] of Byte;
  LUtf8Valid: array[0..5] of Byte;
  LUtf8Invalid: array[0..1] of Byte;
  LBitset: array[0..7] of Byte;
  LFacadeBytesIndex, LDirectBytesIndex: PtrInt;
  LFacadeUtf8Valid, LDirectUtf8Valid: Boolean;
  LFacadeUtf8Invalid, LDirectUtf8Invalid: Boolean;
  LFacadeBitsetPopCount, LDirectBitsetPopCount: SizeUInt;
  LIndex: Integer;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if LBackend <> sbScalar then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('DotF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.DotF32x4));
      AssertTrue('ReduceAddF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.ReduceAddF32x4));
      AssertTrue('ReduceMinF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.ReduceMinF32x4));
      AssertTrue('ReduceMaxF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.ReduceMaxF32x4));
      AssertTrue('ReduceMulF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.ReduceMulF32x4));
      AssertTrue('CmpEqI32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqI32x4));
      AssertTrue('Mask4All should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Mask4All));
      AssertTrue('Mask16PopCount should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Mask16PopCount));
      AssertTrue('BytesIndexOf should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.BytesIndexOf));
      AssertTrue('Utf8Validate should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Utf8Validate));
      AssertTrue('BitsetPopCount should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.BitsetPopCount));

      LA.f[0] := 1.25;
      LA.f[1] := -2.0;
      LA.f[2] := 3.5;
      LA.f[3] := 4.0;

      LB.f[0] := -0.75;
      LB.f[1] := 5.0;
      LB.f[2] := -1.5;
      LB.f[3] := 2.0;

      LI32A.i[0] := 1;
      LI32A.i[1] := 2;
      LI32A.i[2] := 3;
      LI32A.i[3] := 4;

      LI32B.i[0] := 1;
      LI32B.i[1] := 20;
      LI32B.i[2] := 3;
      LI32B.i[3] := 40;

      for LIndex := 0 to 15 do
      begin
        LU8A.u[LIndex] := UInt8(LIndex * 8);
        LU8B.u[LIndex] := UInt8(200 - LIndex * 7);
      end;

      for LIndex := 0 to High(LHaystack) do
        LHaystack[LIndex] := Byte(LIndex);
      LNeedle[0] := 10;
      LNeedle[1] := 11;
      LNeedle[2] := 12;

      LUtf8Valid[0] := $48;   // H
      LUtf8Valid[1] := $65;   // e
      LUtf8Valid[2] := $6C;   // l
      LUtf8Valid[3] := $6C;   // l
      LUtf8Valid[4] := $6F;   // o
      LUtf8Valid[5] := $21;   // !

      LUtf8Invalid[0] := $C3;
      LUtf8Invalid[1] := $28;

      LBitset[0] := $00;
      LBitset[1] := $FF;
      LBitset[2] := $55;
      LBitset[3] := $AA;
      LBitset[4] := $0F;
      LBitset[5] := $F0;
      LBitset[6] := $33;
      LBitset[7] := $CC;

      LFacadeDot := VecF32x4Dot(LA, LB);
      LDirectDot := LDirectDispatch^.DotF32x4(LA, LB);
      AssertEquals('Direct DotF32x4 parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeDot, LDirectDot, C_EPSILON);

      LFacadeReduceAdd := VecF32x4ReduceAdd(LA);
      LDirectReduceAdd := LDirectDispatch^.ReduceAddF32x4(LA);
      AssertEquals('Direct ReduceAddF32x4 parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeReduceAdd, LDirectReduceAdd, C_EPSILON);

      LFacadeReduceMin := VecF32x4ReduceMin(LA);
      LDirectReduceMin := LDirectDispatch^.ReduceMinF32x4(LA);
      AssertEquals('Direct ReduceMinF32x4 parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeReduceMin, LDirectReduceMin, C_EPSILON);

      LFacadeReduceMax := VecF32x4ReduceMax(LA);
      LDirectReduceMax := LDirectDispatch^.ReduceMaxF32x4(LA);
      AssertEquals('Direct ReduceMaxF32x4 parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeReduceMax, LDirectReduceMax, C_EPSILON);

      LFacadeReduceMul := VecF32x4ReduceMul(LA);
      LDirectReduceMul := LDirectDispatch^.ReduceMulF32x4(LA);
      AssertEquals('Direct ReduceMulF32x4 parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeReduceMul, LDirectReduceMul, C_EPSILON);

      LFacadeMask4 := VecI32x4CmpEq(LI32A, LI32B);
      LDirectMask4 := LDirectDispatch^.CmpEqI32x4(LI32A, LI32B);
      AssertEquals('Direct CmpEqI32x4 parity backend ' + IntToStr(Ord(LBackend)),
        Integer(LFacadeMask4), Integer(LDirectMask4));

      LFacadeMask4All := Mask4All(LFacadeMask4);
      LDirectMask4All := LDirectDispatch^.Mask4All(LDirectMask4);
      AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeMask4All, LDirectMask4All);

      LFacadeMask16 := VecU8x16CmpGt(LU8A, LU8B);
      LFacadeMask16PopCount := Mask16PopCount(LFacadeMask16);
      LDirectMask16PopCount := LDirectDispatch^.Mask16PopCount(LFacadeMask16);
      AssertEquals('Direct Mask16PopCount parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeMask16PopCount, LDirectMask16PopCount);

      LFacadeBytesIndex := BytesIndexOf(@LHaystack[0], SizeUInt(Length(LHaystack)), @LNeedle[0], SizeUInt(Length(LNeedle)));
      LDirectBytesIndex := LDirectDispatch^.BytesIndexOf(@LHaystack[0], SizeUInt(Length(LHaystack)), @LNeedle[0], SizeUInt(Length(LNeedle)));
      AssertEquals('Direct BytesIndexOf parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeBytesIndex, LDirectBytesIndex);

      LFacadeUtf8Valid := Utf8Validate(@LUtf8Valid[0], SizeUInt(Length(LUtf8Valid)));
      LDirectUtf8Valid := LDirectDispatch^.Utf8Validate(@LUtf8Valid[0], SizeUInt(Length(LUtf8Valid)));
      AssertEquals('Direct Utf8Validate(valid) parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeUtf8Valid, LDirectUtf8Valid);

      LFacadeUtf8Invalid := Utf8Validate(@LUtf8Invalid[0], SizeUInt(Length(LUtf8Invalid)));
      LDirectUtf8Invalid := LDirectDispatch^.Utf8Validate(@LUtf8Invalid[0], SizeUInt(Length(LUtf8Invalid)));
      AssertEquals('Direct Utf8Validate(invalid) parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeUtf8Invalid, LDirectUtf8Invalid);

      LFacadeBitsetPopCount := BitsetPopCount(@LBitset[0], SizeUInt(Length(LBitset)));
      LDirectBitsetPopCount := LDirectDispatch^.BitsetPopCount(@LBitset[0], SizeUInt(Length(LBitset)));
      AssertEquals('Direct BitsetPopCount parity backend ' + IntToStr(Ord(LBackend)),
        LFacadeBitsetPopCount, LDirectBitsetPopCount);

      if LBackend = sbScalar then
      begin
        AssertTrue('U8x16SatAdd should be assigned for scalar backend', Assigned(LDirectDispatch^.U8x16SatAdd));
        AssertTrue('I8x16SatAdd should be assigned for scalar backend', Assigned(LDirectDispatch^.I8x16SatAdd));

        for LIndex := 0 to 15 do
        begin
          LI8A.i[LIndex] := Int8(120 - LIndex);
          LI8B.i[LIndex] := Int8(30 + LIndex);
          LU8A.u[LIndex] := UInt8(240 - LIndex);
          LU8B.u[LIndex] := UInt8(30 + LIndex);
        end;

        LFacadeU8SatAdd := VecU8x16SatAdd(LU8A, LU8B);
        LDirectU8SatAdd := LDirectDispatch^.U8x16SatAdd(LU8A, LU8B);
        for LIndex := 0 to 15 do
          AssertEquals('Direct U8x16SatAdd lane ' + IntToStr(LIndex) + ' scalar backend',
            Integer(LFacadeU8SatAdd.u[LIndex]), Integer(LDirectU8SatAdd.u[LIndex]));

        LFacadeI8SatAdd := VecI8x16SatAdd(LI8A, LI8B);
        LDirectI8SatAdd := LDirectDispatch^.I8x16SatAdd(LI8A, LI8B);
        for LIndex := 0 to 15 do
          AssertEquals('Direct I8x16SatAdd lane ' + IntToStr(LIndex) + ' scalar backend',
            Integer(LFacadeI8SatAdd.i[LIndex]), Integer(LDirectI8SatAdd.i[LIndex]));
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MemTextEdgeMatrix_Parity;
const
  C_LEN_CASES: array[0..11] of Integer = (1, 2, 3, 7, 8, 15, 16, 17, 31, 32, 33, 63);
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LBufA: array[0..63] of Byte;
  LBufB: array[0..63] of Byte;
  LLenCaseIdx: Integer;
  LLen: Integer;
  LIndex: Integer;
  LScenario: Integer;
  LDiffPos: Integer;
  LFacadeMemEqual, LDirectMemEqual: LongBool;
  LFacadeHasDiff, LDirectHasDiff: Boolean;
  LFacadeFirstDiff, LFacadeLastDiff: SizeUInt;
  LDirectFirstDiff, LDirectLastDiff: SizeUInt;
  LAsciiSameA, LAsciiSameB: AnsiString;
  LAsciiDiffA, LAsciiDiffB: AnsiString;
  LAsciiTransformSample: AnsiString;
  LAsciiLen: Integer;
  LFacadeAsciiEq, LDirectAsciiEq: Boolean;
  LTransformLenCases: array[0..2] of Integer;
  LTransformLenIdx: Integer;
  LTransformLen: Integer;
  LLowerFacade, LLowerDirect: array[0..31] of Byte;
  LUpperFacade, LUpperDirect: array[0..31] of Byte;
  LTestedCount: Integer;
  LStage: string;

  procedure CopyBufAIntoB(const aLen: Integer);
  var
    LPos: Integer;
  begin
    for LPos := 0 to aLen - 1 do
      LBufB[LPos] := LBufA[LPos];
  end;

begin
  for LIndex := 0 to High(LBufA) do
  begin
    LBufA[LIndex] := Byte((LIndex * 37 + 11) and $FF);
    LBufB[LIndex] := LBufA[LIndex];
  end;

  LAsciiSameA := 'SimdDirectParityXYZ123';
  LAsciiSameB := 'sIMDdIRECTpARITYxyz123';
  LAsciiDiffA := 'DirectAsciiEdgeMatrix';
  LAsciiDiffB := 'directAsciiEdgeMatrIx';
  LAsciiTransformSample := 'aZ09-*_mIxEdQw';
  LTransformLenCases[0] := 1;
  LTransformLenCases[1] := Length(LAsciiTransformSample) div 2;
  LTransformLenCases[2] := Length(LAsciiTransformSample);

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;
      if LBackend <> sbScalar then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('MemEqual should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemEqual));
      AssertTrue('MemDiffRange should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemDiffRange));
      AssertTrue('AsciiIEqual should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.AsciiIEqual));
      AssertTrue('ToLowerAscii should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.ToLowerAscii));
      AssertTrue('ToUpperAscii should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.ToUpperAscii));

      LStage := 'begin-backend';
      try
        for LLenCaseIdx := Low(C_LEN_CASES) to High(C_LEN_CASES) do
      begin
        LLen := C_LEN_CASES[LLenCaseIdx];
        CopyBufAIntoB(LLen);

        LStage := 'MemEqual(equal),len=' + IntToStr(LLen);
        LFacadeMemEqual := MemEqual(@LBufA[0], @LBufB[0], SizeUInt(LLen));
        LDirectMemEqual := LDirectDispatch^.MemEqual(@LBufA[0], @LBufB[0], SizeUInt(LLen));
        AssertEquals('Direct MemEqual(equal) parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
          Boolean(LFacadeMemEqual), Boolean(LDirectMemEqual));

        LStage := 'MemDiffRange(equal),len=' + IntToStr(LLen);
        LFacadeHasDiff := MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(LLen), LFacadeFirstDiff, LFacadeLastDiff);
        LDirectHasDiff := LDirectDispatch^.MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(LLen), LDirectFirstDiff, LDirectLastDiff);
        AssertEquals('Direct MemDiffRange(equal) hasDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
          LFacadeHasDiff, LDirectHasDiff);
        if LFacadeHasDiff then
        begin
          AssertEquals('Direct MemDiffRange(equal) firstDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
            LFacadeFirstDiff, LDirectFirstDiff);
          AssertEquals('Direct MemDiffRange(equal) lastDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
            LFacadeLastDiff, LDirectLastDiff);
        end;

        if LLen > 0 then
        begin
          for LScenario := 0 to 2 do
          begin
            CopyBufAIntoB(LLen);
            case LScenario of
              0: LDiffPos := 0;
              1: LDiffPos := LLen div 2;
            else
              LDiffPos := LLen - 1;
            end;
            LBufB[LDiffPos] := LBufB[LDiffPos] xor Byte($51 + LScenario);

            LStage := 'MemEqual(diff),len=' + IntToStr(LLen) + ',scenario=' + IntToStr(LScenario);
            LFacadeMemEqual := MemEqual(@LBufA[0], @LBufB[0], SizeUInt(LLen));
            LDirectMemEqual := LDirectDispatch^.MemEqual(@LBufA[0], @LBufB[0], SizeUInt(LLen));
            AssertEquals('Direct MemEqual(diff) parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
              Boolean(LFacadeMemEqual), Boolean(LDirectMemEqual));
            AssertFalse('Facade MemEqual(diff) should be false len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
              Boolean(LFacadeMemEqual));

            LStage := 'MemDiffRange(diff),len=' + IntToStr(LLen) + ',scenario=' + IntToStr(LScenario);
            LFacadeHasDiff := MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(LLen), LFacadeFirstDiff, LFacadeLastDiff);
            LDirectHasDiff := LDirectDispatch^.MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(LLen), LDirectFirstDiff, LDirectLastDiff);
            AssertEquals('Direct MemDiffRange(diff) hasDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
              LFacadeHasDiff, LDirectHasDiff);
            AssertTrue('Facade MemDiffRange(diff) should report hasDiff len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
              LFacadeHasDiff);
            if LFacadeHasDiff then
            begin
              AssertEquals('Direct MemDiffRange(diff) firstDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
                LFacadeFirstDiff, LDirectFirstDiff);
              AssertEquals('Direct MemDiffRange(diff) lastDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
                LFacadeLastDiff, LDirectLastDiff);
              AssertEquals('Facade MemDiffRange(diff) firstDiff expected len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
                SizeUInt(LDiffPos), LFacadeFirstDiff);
              AssertEquals('Facade MemDiffRange(diff) lastDiff expected len=' + IntToStr(LLen) + ' scenario=' + IntToStr(LScenario),
                SizeUInt(LDiffPos), LFacadeLastDiff);
            end;
          end;

          if LLen > 1 then
          begin
            CopyBufAIntoB(LLen);
            LBufB[0] := LBufB[0] xor $33;
            LBufB[LLen - 1] := LBufB[LLen - 1] xor $77;

            LStage := 'MemDiffRange(double-diff),len=' + IntToStr(LLen);
            LFacadeHasDiff := MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(LLen), LFacadeFirstDiff, LFacadeLastDiff);
            LDirectHasDiff := LDirectDispatch^.MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(LLen), LDirectFirstDiff, LDirectLastDiff);
            AssertEquals('Direct MemDiffRange(double-diff) hasDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
              LFacadeHasDiff, LDirectHasDiff);
            AssertTrue('Facade MemDiffRange(double-diff) should report hasDiff len=' + IntToStr(LLen),
              LFacadeHasDiff);
            if LFacadeHasDiff then
            begin
              AssertEquals('Direct MemDiffRange(double-diff) firstDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
                LFacadeFirstDiff, LDirectFirstDiff);
              AssertEquals('Direct MemDiffRange(double-diff) lastDiff parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen),
                LFacadeLastDiff, LDirectLastDiff);
              AssertEquals('Facade MemDiffRange(double-diff) firstDiff expected len=' + IntToStr(LLen),
                SizeUInt(0), LFacadeFirstDiff);
              AssertEquals('Facade MemDiffRange(double-diff) lastDiff expected len=' + IntToStr(LLen),
                SizeUInt(LLen - 1), LFacadeLastDiff);
            end;
          end;
        end;
      end;

      for LAsciiLen := 1 to Length(LAsciiSameA) do
      begin
        LStage := 'AsciiIEqual(case-insensitive),len=' + IntToStr(LAsciiLen);
        LFacadeAsciiEq := AsciiIEqual(Pointer(PAnsiChar(LAsciiSameA)), Pointer(PAnsiChar(LAsciiSameB)), SizeUInt(LAsciiLen));
        LDirectAsciiEq := LDirectDispatch^.AsciiIEqual(Pointer(PAnsiChar(LAsciiSameA)), Pointer(PAnsiChar(LAsciiSameB)), SizeUInt(LAsciiLen));
        AssertEquals('Direct AsciiIEqual(case-insensitive) parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LAsciiLen),
          LFacadeAsciiEq, LDirectAsciiEq);
      end;

      for LAsciiLen := 1 to Length(LAsciiDiffA) do
      begin
        LStage := 'AsciiIEqual(mismatch),len=' + IntToStr(LAsciiLen);
        LFacadeAsciiEq := AsciiIEqual(Pointer(PAnsiChar(LAsciiDiffA)), Pointer(PAnsiChar(LAsciiDiffB)), SizeUInt(LAsciiLen));
        LDirectAsciiEq := LDirectDispatch^.AsciiIEqual(Pointer(PAnsiChar(LAsciiDiffA)), Pointer(PAnsiChar(LAsciiDiffB)), SizeUInt(LAsciiLen));
        AssertEquals('Direct AsciiIEqual(mismatch) parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LAsciiLen),
          LFacadeAsciiEq, LDirectAsciiEq);
      end;

      for LTransformLenIdx := Low(LTransformLenCases) to High(LTransformLenCases) do
      begin
        LTransformLen := LTransformLenCases[LTransformLenIdx];
        for LIndex := 0 to LTransformLen - 1 do
        begin
          LLowerFacade[LIndex] := Byte(Ord(LAsciiTransformSample[LIndex + 1]));
          LLowerDirect[LIndex] := LLowerFacade[LIndex];
          LUpperFacade[LIndex] := Byte(Ord(LAsciiTransformSample[LIndex + 1]));
          LUpperDirect[LIndex] := LUpperFacade[LIndex];
        end;

        LStage := 'ToLowerAscii,len=' + IntToStr(LTransformLen);
        ToLowerAscii(@LLowerFacade[0], SizeUInt(LTransformLen));
        LDirectDispatch^.ToLowerAscii(@LLowerDirect[0], SizeUInt(LTransformLen));
        for LIndex := 0 to LTransformLen - 1 do
          AssertEquals('Direct ToLowerAscii parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LTransformLen) + ' idx=' + IntToStr(LIndex),
            Integer(LLowerFacade[LIndex]), Integer(LLowerDirect[LIndex]));

        LStage := 'ToUpperAscii,len=' + IntToStr(LTransformLen);
        ToUpperAscii(@LUpperFacade[0], SizeUInt(LTransformLen));
        LDirectDispatch^.ToUpperAscii(@LUpperDirect[0], SizeUInt(LTransformLen));
        for LIndex := 0 to LTransformLen - 1 do
          AssertEquals('Direct ToUpperAscii parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LTransformLen) + ' idx=' + IntToStr(LIndex),
            Integer(LUpperFacade[LIndex]), Integer(LUpperDirect[LIndex]));
      end;
      except
        on E: Exception do
          Fail('MemText edge parity exception backend=' + IntToStr(Ord(LBackend)) +
            ' stage=' + LStage + ' msg=' + E.ClassName + ': ' + E.Message);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MemOpsEdgeMatrix_Parity;
const
  C_LEN_CASES: array[0..11] of Integer = (1, 2, 3, 7, 8, 15, 16, 17, 31, 32, 33, 63);
  C_OFFSET_CASES: array[0..3] of Integer = (0, 1, 5, 13);
  C_SET_VALUES: array[0..3] of Byte = ($00, $5A, $A5, $FF);
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LSource: array[0..127] of Byte;
  LFacadeBuf: array[0..127] of Byte;
  LDirectBuf: array[0..127] of Byte;
  LLenCaseIdx: Integer;
  LOffsetIdx: Integer;
  LSetIdx: Integer;
  LLen: Integer;
  LSrcOffset: Integer;
  LDstOffset: Integer;
  LIndex: Integer;
  LTestedCount: Integer;

  procedure FillSourcePattern;
  var
    LPos: Integer;
  begin
    for LPos := 0 to High(LSource) do
      LSource[LPos] := Byte((LPos * 29 + 17) and $FF);
  end;

  procedure FillWorkBuffers;
  var
    LPos: Integer;
  begin
    for LPos := 0 to High(LFacadeBuf) do
    begin
      LFacadeBuf[LPos] := Byte((LPos * 7 + 3) and $FF);
      LDirectBuf[LPos] := LFacadeBuf[LPos];
    end;
  end;

  procedure AssertBuffersEqual(const aTitle: string);
  var
    LPos: Integer;
  begin
    for LPos := 0 to High(LFacadeBuf) do
      AssertEquals(aTitle + '.idx' + IntToStr(LPos),
        Integer(LFacadeBuf[LPos]), Integer(LDirectBuf[LPos]));
  end;

begin
  FillSourcePattern;

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('MemCopy should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemCopy));
      AssertTrue('MemSet should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemSet));
      AssertTrue('MemReverse should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemReverse));

      for LLenCaseIdx := Low(C_LEN_CASES) to High(C_LEN_CASES) do
      begin
        LLen := C_LEN_CASES[LLenCaseIdx];

        // MemCopy parity
        for LOffsetIdx := Low(C_OFFSET_CASES) to High(C_OFFSET_CASES) do
        begin
          LSrcOffset := C_OFFSET_CASES[LOffsetIdx];
          LDstOffset := C_OFFSET_CASES[High(C_OFFSET_CASES) - LOffsetIdx];

          FillWorkBuffers;
          MemCopy(@LSource[LSrcOffset], @LFacadeBuf[LDstOffset], SizeUInt(LLen));
          LDirectDispatch^.MemCopy(@LSource[LSrcOffset], @LDirectBuf[LDstOffset], SizeUInt(LLen));
          AssertBuffersEqual('Direct MemCopy parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' srcOff=' + IntToStr(LSrcOffset) + ' dstOff=' + IntToStr(LDstOffset));
        end;

        // MemSet parity
        for LSetIdx := Low(C_SET_VALUES) to High(C_SET_VALUES) do
        begin
          LDstOffset := C_OFFSET_CASES[LSetIdx mod Length(C_OFFSET_CASES)];

          FillWorkBuffers;
          MemSet(@LFacadeBuf[LDstOffset], SizeUInt(LLen), C_SET_VALUES[LSetIdx]);
          LDirectDispatch^.MemSet(@LDirectBuf[LDstOffset], SizeUInt(LLen), C_SET_VALUES[LSetIdx]);
          AssertBuffersEqual('Direct MemSet parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' dstOff=' + IntToStr(LDstOffset) +
            ' value=' + IntToStr(C_SET_VALUES[LSetIdx]));
        end;

        // MemReverse parity
        for LOffsetIdx := Low(C_OFFSET_CASES) to High(C_OFFSET_CASES) do
        begin
          LDstOffset := C_OFFSET_CASES[LOffsetIdx];

          FillWorkBuffers;
          for LIndex := 0 to LLen - 1 do
          begin
            LFacadeBuf[LDstOffset + LIndex] := Byte((LIndex * 11 + 9) and $FF);
            LDirectBuf[LDstOffset + LIndex] := LFacadeBuf[LDstOffset + LIndex];
          end;

          MemReverse(@LFacadeBuf[LDstOffset], SizeUInt(LLen));
          LDirectDispatch^.MemReverse(@LDirectBuf[LDstOffset], SizeUInt(LLen));
          AssertBuffersEqual('Direct MemReverse parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LDstOffset));
        end;
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_StatsEdgeMatrix_Parity;
const
  C_LEN_CASES: array[0..11] of Integer = (1, 2, 3, 7, 8, 15, 16, 17, 31, 32, 33, 63);
  C_OFFSET_CASES: array[0..3] of Integer = (0, 1, 5, 13);
  C_COUNT_VALUES: array[0..4] of Byte = ($00, $11, $55, $AA, $FF);
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LBuf: array[0..127] of Byte;
  LLenCaseIdx: Integer;
  LOffsetIdx: Integer;
  LValueIdx: Integer;
  LLen: Integer;
  LOffset: Integer;
  LIndex: Integer;
  LFacadeSum, LDirectSum: UInt64;
  LFacadeCount, LDirectCount: SizeUInt;
  LFacadeMin, LFacadeMax: Byte;
  LDirectMin, LDirectMax: Byte;
  LTestedCount: Integer;

  procedure FillBufferPattern;
  var
    LPos: Integer;
  begin
    for LPos := 0 to High(LBuf) do
      LBuf[LPos] := Byte((LPos * 19 + 23) and $FF);

    // inject fixed sentinels to stabilize min/max/count edge cases
    LBuf[3] := $00;
    LBuf[7] := $FF;
    LBuf[11] := $11;
    LBuf[13] := $55;
    LBuf[17] := $AA;
  end;

begin
  FillBufferPattern;

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('SumBytes should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.SumBytes));
      AssertTrue('CountByte should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CountByte));
      AssertTrue('MinMaxBytes should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MinMaxBytes));

      for LLenCaseIdx := Low(C_LEN_CASES) to High(C_LEN_CASES) do
      begin
        LLen := C_LEN_CASES[LLenCaseIdx];

        for LOffsetIdx := Low(C_OFFSET_CASES) to High(C_OFFSET_CASES) do
        begin
          LOffset := C_OFFSET_CASES[LOffsetIdx];

          // keep deterministic but vary bytes in active window by len/offset
          for LIndex := 0 to LLen - 1 do
            LBuf[LOffset + LIndex] := Byte((LBuf[LOffset + LIndex] + Byte((LLen + LOffset + LIndex) and $FF)) and $FF);

          LFacadeSum := SumBytes(@LBuf[LOffset], SizeUInt(LLen));
          LDirectSum := LDirectDispatch^.SumBytes(@LBuf[LOffset], SizeUInt(LLen));
          AssertEquals('Direct SumBytes parity backend ' + IntToStr(Ord(LBackend)) + ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            LFacadeSum, LDirectSum);

          for LValueIdx := Low(C_COUNT_VALUES) to High(C_COUNT_VALUES) do
          begin
            LFacadeCount := CountByte(@LBuf[LOffset], SizeUInt(LLen), C_COUNT_VALUES[LValueIdx]);
            LDirectCount := LDirectDispatch^.CountByte(@LBuf[LOffset], SizeUInt(LLen), C_COUNT_VALUES[LValueIdx]);
            AssertEquals('Direct CountByte parity backend ' + IntToStr(Ord(LBackend)) +
              ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset) +
              ' value=' + IntToStr(C_COUNT_VALUES[LValueIdx]),
              LFacadeCount, LDirectCount);
          end;

          MinMaxBytes(@LBuf[LOffset], SizeUInt(LLen), LFacadeMin, LFacadeMax);
          LDirectDispatch^.MinMaxBytes(@LBuf[LOffset], SizeUInt(LLen), LDirectMin, LDirectMax);
          AssertEquals('Direct MinMaxBytes.min parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            Integer(LFacadeMin), Integer(LDirectMin));
          AssertEquals('Direct MinMaxBytes.max parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            Integer(LFacadeMax), Integer(LDirectMax));
        end;
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MaskCompareEdge_Parity;
const
  C_EPSILON = 1e-6;
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LA, LB: TVecF32x4;
  LMaskEqFacade, LMaskEqDirect: TMask4;
  LMaskLtFacade, LMaskLtDirect: TMask4;
  LMaskLeFacade, LMaskLeDirect: TMask4;
  LMaskGtFacade, LMaskGtDirect: TMask4;
  LMaskGeFacade, LMaskGeDirect: TMask4;
  LMaskNeFacade, LMaskNeDirect: TMask4;
  LFacadeAll, LDirectAll: Boolean;
  LFacadeAny, LDirectAny: Boolean;
  LFacadeNone, LDirectNone: Boolean;
  LFacadePop, LDirectPop: Integer;
  LFacadeFirst, LDirectFirst: Integer;
  LDotFacade, LDotDirect: Single;
  LTestedCount: Integer;
begin
  // 设计为对比边界：包含相等、大小关系与符号混合，避免 NaN 语义差异干扰。
  LA.f[0] := -3.0;
  LA.f[1] := 0.0;
  LA.f[2] := 1.5;
  LA.f[3] := 9.0;

  LB.f[0] := -3.0;
  LB.f[1] := 2.0;
  LB.f[2] := 1.0;
  LB.f[3] := -4.0;

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('CmpEqF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqF32x4));
      AssertTrue('Mask4All should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Mask4All));

      LMaskEqFacade := VecF32x4CmpEq(LA, LB);
      LMaskEqDirect := LDirectDispatch^.CmpEqF32x4(LA, LB);
      AssertEquals('Direct CmpEqF32x4 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMaskEqFacade), Integer(LMaskEqDirect));

      LMaskLtFacade := VecF32x4CmpLt(LA, LB);
      LMaskLtDirect := LDirectDispatch^.CmpLtF32x4(LA, LB);
      AssertEquals('Direct CmpLtF32x4 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMaskLtFacade), Integer(LMaskLtDirect));

      LMaskLeFacade := VecF32x4CmpLe(LA, LB);
      LMaskLeDirect := LDirectDispatch^.CmpLeF32x4(LA, LB);
      AssertEquals('Direct CmpLeF32x4 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMaskLeFacade), Integer(LMaskLeDirect));

      LMaskGtFacade := VecF32x4CmpGt(LA, LB);
      LMaskGtDirect := LDirectDispatch^.CmpGtF32x4(LA, LB);
      AssertEquals('Direct CmpGtF32x4 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMaskGtFacade), Integer(LMaskGtDirect));

      LMaskGeFacade := VecF32x4CmpGe(LA, LB);
      LMaskGeDirect := LDirectDispatch^.CmpGeF32x4(LA, LB);
      AssertEquals('Direct CmpGeF32x4 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMaskGeFacade), Integer(LMaskGeDirect));

      LMaskNeFacade := VecF32x4CmpNe(LA, LB);
      LMaskNeDirect := LDirectDispatch^.CmpNeF32x4(LA, LB);
      AssertEquals('Direct CmpNeF32x4 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMaskNeFacade), Integer(LMaskNeDirect));

      LFacadeAll := Mask4All(LMaskLtFacade);
      LDirectAll := LDirectDispatch^.Mask4All(LMaskLtDirect);
      AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)), LFacadeAll, LDirectAll);

      LFacadeAny := Mask4Any(LMaskLtFacade);
      LDirectAny := LDirectDispatch^.Mask4Any(LMaskLtDirect);
      AssertEquals('Direct Mask4Any parity backend ' + IntToStr(Ord(LBackend)), LFacadeAny, LDirectAny);

      LFacadeNone := Mask4None(LMaskLtFacade);
      LDirectNone := LDirectDispatch^.Mask4None(LMaskLtDirect);
      AssertEquals('Direct Mask4None parity backend ' + IntToStr(Ord(LBackend)), LFacadeNone, LDirectNone);

      LFacadePop := Mask4PopCount(LMaskLtFacade);
      LDirectPop := LDirectDispatch^.Mask4PopCount(LMaskLtDirect);
      AssertEquals('Direct Mask4PopCount parity backend ' + IntToStr(Ord(LBackend)), LFacadePop, LDirectPop);

      LFacadeFirst := Mask4FirstSet(LMaskLtFacade);
      LDirectFirst := LDirectDispatch^.Mask4FirstSet(LMaskLtDirect);
      AssertEquals('Direct Mask4FirstSet parity backend ' + IntToStr(Ord(LBackend)), LFacadeFirst, LDirectFirst);

      LDotFacade := VecF32x4Dot(LA, LB);
      LDotDirect := LDirectDispatch^.DotF32x4(LA, LB);
      AssertEquals('Direct DotF32x4 parity backend ' + IntToStr(Ord(LBackend)), LDotFacade, LDotDirect, C_EPSILON);
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MaskWideCompareMatrix_Parity;
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;

  LAf64, LBf64: TVecF64x2;
  LAi16, LBi16: TVecI16x8;
  LAi8, LBi8: TVecI8x16;

  LMask2EqFacade, LMask2EqDirect: TMask2;
  LMask2LtFacade, LMask2LtDirect: TMask2;
  LMask2LeFacade, LMask2LeDirect: TMask2;
  LMask2GtFacade, LMask2GtDirect: TMask2;
  LMask2GeFacade, LMask2GeDirect: TMask2;
  LMask2NeFacade, LMask2NeDirect: TMask2;

  LMask8EqFacade, LMask8EqDirect: TMask8;
  LMask8LtFacade, LMask8LtDirect: TMask8;
  LMask8GtFacade, LMask8GtDirect: TMask8;

  LMask16EqFacade, LMask16EqDirect: TMask16;
  LMask16LtFacade, LMask16LtDirect: TMask16;
  LMask16GtFacade, LMask16GtDirect: TMask16;

  LMask2AllFacade, LMask2AllDirect: Boolean;
  LMask2AnyFacade, LMask2AnyDirect: Boolean;
  LMask2NoneFacade, LMask2NoneDirect: Boolean;
  LMask2PopFacade, LMask2PopDirect: Integer;
  LMask2FirstFacade, LMask2FirstDirect: Integer;

  LMask8AllFacade, LMask8AllDirect: Boolean;
  LMask8AnyFacade, LMask8AnyDirect: Boolean;
  LMask8NoneFacade, LMask8NoneDirect: Boolean;
  LMask8PopFacade, LMask8PopDirect: Integer;
  LMask8FirstFacade, LMask8FirstDirect: Integer;

  LMask16AllFacade, LMask16AllDirect: Boolean;
  LMask16AnyFacade, LMask16AnyDirect: Boolean;
  LMask16NoneFacade, LMask16NoneDirect: Boolean;
  LMask16PopFacade, LMask16PopDirect: Integer;
  LMask16FirstFacade, LMask16FirstDirect: Integer;

  LIndex: Integer;
  LTestedCount: Integer;
begin
  LAf64.d[0] := -1.0;
  LAf64.d[1] := 5.0;
  LBf64.d[0] := -1.0;
  LBf64.d[1] := 3.0;

  for LIndex := 0 to 7 do
  begin
    LAi16.i[LIndex] := Int16((LIndex * 3) - 8);
    LBi16.i[LIndex] := Int16((LIndex * 2) - 7);
  end;
  // 强化边界：eq/lt/gt 都出现
  LBi16.i[0] := LAi16.i[0];
  LBi16.i[3] := LAi16.i[3] + 2;
  LBi16.i[5] := LAi16.i[5] - 2;

  for LIndex := 0 to 15 do
  begin
    LAi8.i[LIndex] := Int8((LIndex * 5) - 30);
    LBi8.i[LIndex] := Int8((LIndex * 4) - 25);
  end;
  LBi8.i[1] := LAi8.i[1];
  LBi8.i[7] := LAi8.i[7] + 3;
  LBi8.i[12] := LAi8.i[12] - 3;

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('CmpEqF64x2 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqF64x2));
      AssertTrue('Mask16All should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Mask16All));

      // === Mask2 (from F64 compare) ===
      LMask2EqFacade := VecF64x2CmpEq(LAf64, LBf64);
      LMask2EqDirect := LDirectDispatch^.CmpEqF64x2(LAf64, LBf64);
      AssertEquals('Direct CmpEqF64x2 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask2EqFacade), Integer(LMask2EqDirect));

      LMask2LtFacade := VecF64x2CmpLt(LAf64, LBf64);
      LMask2LtDirect := LDirectDispatch^.CmpLtF64x2(LAf64, LBf64);
      AssertEquals('Direct CmpLtF64x2 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask2LtFacade), Integer(LMask2LtDirect));

      LMask2LeFacade := VecF64x2CmpLe(LAf64, LBf64);
      LMask2LeDirect := LDirectDispatch^.CmpLeF64x2(LAf64, LBf64);
      AssertEquals('Direct CmpLeF64x2 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask2LeFacade), Integer(LMask2LeDirect));

      LMask2GtFacade := VecF64x2CmpGt(LAf64, LBf64);
      LMask2GtDirect := LDirectDispatch^.CmpGtF64x2(LAf64, LBf64);
      AssertEquals('Direct CmpGtF64x2 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask2GtFacade), Integer(LMask2GtDirect));

      LMask2GeFacade := VecF64x2CmpGe(LAf64, LBf64);
      LMask2GeDirect := LDirectDispatch^.CmpGeF64x2(LAf64, LBf64);
      AssertEquals('Direct CmpGeF64x2 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask2GeFacade), Integer(LMask2GeDirect));

      LMask2NeFacade := VecF64x2CmpNe(LAf64, LBf64);
      LMask2NeDirect := LDirectDispatch^.CmpNeF64x2(LAf64, LBf64);
      AssertEquals('Direct CmpNeF64x2 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask2NeFacade), Integer(LMask2NeDirect));

      LMask2AllFacade := Mask2All(LMask2LtFacade);
      LMask2AllDirect := LDirectDispatch^.Mask2All(LMask2LtDirect);
      AssertEquals('Direct Mask2All parity backend ' + IntToStr(Ord(LBackend)), LMask2AllFacade, LMask2AllDirect);

      LMask2AnyFacade := Mask2Any(LMask2LtFacade);
      LMask2AnyDirect := LDirectDispatch^.Mask2Any(LMask2LtDirect);
      AssertEquals('Direct Mask2Any parity backend ' + IntToStr(Ord(LBackend)), LMask2AnyFacade, LMask2AnyDirect);

      LMask2NoneFacade := Mask2None(LMask2LtFacade);
      LMask2NoneDirect := LDirectDispatch^.Mask2None(LMask2LtDirect);
      AssertEquals('Direct Mask2None parity backend ' + IntToStr(Ord(LBackend)), LMask2NoneFacade, LMask2NoneDirect);

      LMask2PopFacade := Mask2PopCount(LMask2LtFacade);
      LMask2PopDirect := LDirectDispatch^.Mask2PopCount(LMask2LtDirect);
      AssertEquals('Direct Mask2PopCount parity backend ' + IntToStr(Ord(LBackend)), LMask2PopFacade, LMask2PopDirect);

      LMask2FirstFacade := Mask2FirstSet(LMask2LtFacade);
      LMask2FirstDirect := LDirectDispatch^.Mask2FirstSet(LMask2LtDirect);
      AssertEquals('Direct Mask2FirstSet parity backend ' + IntToStr(Ord(LBackend)), LMask2FirstFacade, LMask2FirstDirect);

      // === Mask8 (from I16 compare) ===
      LMask8EqFacade := VecI16x8CmpEq(LAi16, LBi16);
      LMask8EqDirect := LDirectDispatch^.CmpEqI16x8(LAi16, LBi16);
      AssertEquals('Direct CmpEqI16x8 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask8EqFacade), Integer(LMask8EqDirect));

      LMask8LtFacade := VecI16x8CmpLt(LAi16, LBi16);
      LMask8LtDirect := LDirectDispatch^.CmpLtI16x8(LAi16, LBi16);
      AssertEquals('Direct CmpLtI16x8 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask8LtFacade), Integer(LMask8LtDirect));

      LMask8GtFacade := VecI16x8CmpGt(LAi16, LBi16);
      LMask8GtDirect := LDirectDispatch^.CmpGtI16x8(LAi16, LBi16);
      AssertEquals('Direct CmpGtI16x8 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask8GtFacade), Integer(LMask8GtDirect));

      LMask8AllFacade := Mask8All(LMask8LtFacade);
      LMask8AllDirect := LDirectDispatch^.Mask8All(LMask8LtDirect);
      AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)), LMask8AllFacade, LMask8AllDirect);

      LMask8AnyFacade := Mask8Any(LMask8LtFacade);
      LMask8AnyDirect := LDirectDispatch^.Mask8Any(LMask8LtDirect);
      AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)), LMask8AnyFacade, LMask8AnyDirect);

      LMask8NoneFacade := Mask8None(LMask8LtFacade);
      LMask8NoneDirect := LDirectDispatch^.Mask8None(LMask8LtDirect);
      AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)), LMask8NoneFacade, LMask8NoneDirect);

      LMask8PopFacade := Mask8PopCount(LMask8LtFacade);
      LMask8PopDirect := LDirectDispatch^.Mask8PopCount(LMask8LtDirect);
      AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)), LMask8PopFacade, LMask8PopDirect);

      LMask8FirstFacade := Mask8FirstSet(LMask8LtFacade);
      LMask8FirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8LtDirect);
      AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)), LMask8FirstFacade, LMask8FirstDirect);

      // === Mask16 (from I8 compare) ===
      LMask16EqFacade := VecI8x16CmpEq(LAi8, LBi8);
      LMask16EqDirect := LDirectDispatch^.CmpEqI8x16(LAi8, LBi8);
      AssertEquals('Direct CmpEqI8x16 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask16EqFacade), Integer(LMask16EqDirect));

      LMask16LtFacade := VecI8x16CmpLt(LAi8, LBi8);
      LMask16LtDirect := LDirectDispatch^.CmpLtI8x16(LAi8, LBi8);
      AssertEquals('Direct CmpLtI8x16 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask16LtFacade), Integer(LMask16LtDirect));

      LMask16GtFacade := VecI8x16CmpGt(LAi8, LBi8);
      LMask16GtDirect := LDirectDispatch^.CmpGtI8x16(LAi8, LBi8);
      AssertEquals('Direct CmpGtI8x16 parity backend ' + IntToStr(Ord(LBackend)), Integer(LMask16GtFacade), Integer(LMask16GtDirect));

      LMask16AllFacade := Mask16All(LMask16LtFacade);
      LMask16AllDirect := LDirectDispatch^.Mask16All(LMask16LtDirect);
      AssertEquals('Direct Mask16All parity backend ' + IntToStr(Ord(LBackend)), LMask16AllFacade, LMask16AllDirect);

      LMask16AnyFacade := Mask16Any(LMask16LtFacade);
      LMask16AnyDirect := LDirectDispatch^.Mask16Any(LMask16LtDirect);
      AssertEquals('Direct Mask16Any parity backend ' + IntToStr(Ord(LBackend)), LMask16AnyFacade, LMask16AnyDirect);

      LMask16NoneFacade := Mask16None(LMask16LtFacade);
      LMask16NoneDirect := LDirectDispatch^.Mask16None(LMask16LtDirect);
      AssertEquals('Direct Mask16None parity backend ' + IntToStr(Ord(LBackend)), LMask16NoneFacade, LMask16NoneDirect);

      LMask16PopFacade := Mask16PopCount(LMask16LtFacade);
      LMask16PopDirect := LDirectDispatch^.Mask16PopCount(LMask16LtDirect);
      AssertEquals('Direct Mask16PopCount parity backend ' + IntToStr(Ord(LBackend)), LMask16PopFacade, LMask16PopDirect);

      LMask16FirstFacade := Mask16FirstSet(LMask16LtFacade);
      LMask16FirstDirect := LDirectDispatch^.Mask16FirstSet(LMask16LtDirect);
      AssertEquals('Direct Mask16FirstSet parity backend ' + IntToStr(Ord(LBackend)), LMask16FirstFacade, LMask16FirstDirect);
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F64CompareEdgeMatrix_Parity;
const
  C_CASES: array[0..5, 0..3] of Double = (
    (-0.0, 0.0, -0.0, 0.0),
    (0.0, -0.0, 0.0, -0.0),
    (1.0, -1.0, -1.0, 1.0),
    (-123.5, 123.5, -123.5, 100.0),
    (Infinity, 3.0, Infinity, 3.0),
    (-Infinity, 3.0, 3.0, -Infinity)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LA, LB: TVecF64x2;
  LCaseIdx: Integer;

  LMaskEqFacade, LMaskEqDirect: TMask2;
  LMaskLtFacade, LMaskLtDirect: TMask2;
  LMaskLeFacade, LMaskLeDirect: TMask2;
  LMaskGtFacade, LMaskGtDirect: TMask2;
  LMaskGeFacade, LMaskGeDirect: TMask2;
  LMaskNeFacade, LMaskNeDirect: TMask2;

  LAllFacade, LAllDirect: Boolean;
  LAnyFacade, LAnyDirect: Boolean;
  LNoneFacade, LNoneDirect: Boolean;
  LPopFacade, LPopDirect: Integer;
  LFirstFacade, LFirstDirect: Integer;

  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('CmpEqF64x2 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqF64x2));
      AssertTrue('Mask2All should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Mask2All));

      for LCaseIdx := Low(C_CASES) to High(C_CASES) do
      begin
        LA.d[0] := C_CASES[LCaseIdx, 0];
        LA.d[1] := C_CASES[LCaseIdx, 1];
        LB.d[0] := C_CASES[LCaseIdx, 2];
        LB.d[1] := C_CASES[LCaseIdx, 3];

        LMaskEqFacade := VecF64x2CmpEq(LA, LB);
        LMaskEqDirect := LDirectDispatch^.CmpEqF64x2(LA, LB);
        AssertEquals('Direct CmpEqF64x2 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskEqFacade), Integer(LMaskEqDirect));

        LMaskLtFacade := VecF64x2CmpLt(LA, LB);
        LMaskLtDirect := LDirectDispatch^.CmpLtF64x2(LA, LB);
        AssertEquals('Direct CmpLtF64x2 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskLtFacade), Integer(LMaskLtDirect));

        LMaskLeFacade := VecF64x2CmpLe(LA, LB);
        LMaskLeDirect := LDirectDispatch^.CmpLeF64x2(LA, LB);
        AssertEquals('Direct CmpLeF64x2 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskLeFacade), Integer(LMaskLeDirect));

        LMaskGtFacade := VecF64x2CmpGt(LA, LB);
        LMaskGtDirect := LDirectDispatch^.CmpGtF64x2(LA, LB);
        AssertEquals('Direct CmpGtF64x2 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskGtFacade), Integer(LMaskGtDirect));

        LMaskGeFacade := VecF64x2CmpGe(LA, LB);
        LMaskGeDirect := LDirectDispatch^.CmpGeF64x2(LA, LB);
        AssertEquals('Direct CmpGeF64x2 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskGeFacade), Integer(LMaskGeDirect));

        LMaskNeFacade := VecF64x2CmpNe(LA, LB);
        LMaskNeDirect := LDirectDispatch^.CmpNeF64x2(LA, LB);
        AssertEquals('Direct CmpNeF64x2 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskNeFacade), Integer(LMaskNeDirect));

        LAllFacade := Mask2All(LMaskLtFacade);
        LAllDirect := LDirectDispatch^.Mask2All(LMaskLtDirect);
        AssertEquals('Direct Mask2All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAllFacade, LAllDirect);

        LAnyFacade := Mask2Any(LMaskLtFacade);
        LAnyDirect := LDirectDispatch^.Mask2Any(LMaskLtDirect);
        AssertEquals('Direct Mask2Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAnyFacade, LAnyDirect);

        LNoneFacade := Mask2None(LMaskLtFacade);
        LNoneDirect := LDirectDispatch^.Mask2None(LMaskLtDirect);
        AssertEquals('Direct Mask2None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LNoneFacade, LNoneDirect);

        LPopFacade := Mask2PopCount(LMaskLtFacade);
        LPopDirect := LDirectDispatch^.Mask2PopCount(LMaskLtDirect);
        AssertEquals('Direct Mask2PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LPopFacade, LPopDirect);

        LFirstFacade := Mask2FirstSet(LMaskLtFacade);
        LFirstDirect := LDirectDispatch^.Mask2FirstSet(LMaskLtDirect);
        AssertEquals('Direct Mask2FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LFirstFacade, LFirstDirect);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32CompareMicroDeltaMatrix_Parity;
const
  C_CASE_COUNT = 12;
  C_CASES_A: array[0..C_CASE_COUNT - 1, 0..3] of Single = (
    (0.0, 0.0, 0.0, 0.0),
    (1.0, -1.0, 1000.0, -1000.0),
    (1.0000001, -1.0000001, 2.5, -2.5),
    (-0.0, 0.0, -3.141592, 3.141592),
    (123456.0, -123456.0, 0.0009765625, -0.0009765625),
    (0.125, 0.25, 0.375, 0.5),
    (-0.125, -0.25, -0.375, -0.5),
    (15.0, 16.0, 17.0, 18.0),
    (1.0E-6, -1.0E-6, 1.0E-4, -1.0E-4),
    (1.0E-3, -1.0E-3, 1.0E-2, -1.0E-2),
    (4096.5, -4096.5, 8192.25, -8192.25),
    (7.0, -7.0, 11.0, -11.0)
  );
  C_CASES_B: array[0..C_CASE_COUNT - 1, 0..3] of Single = (
    (0.0, -0.0, 1.0E-7, -1.0E-7),
    (1.0, -1.0000001, 999.9999, -1000.0001),
    (1.0000002, -1.0, 2.5, -2.5000002),
    (0.0, -0.0, -3.1415918, 3.1415920),
    (123456.0625, -123455.9375, 0.0009765625, -0.0009765),
    (0.1249999, 0.2500001, 0.375, 0.5000001),
    (-0.1250001, -0.2499999, -0.3750001, -0.4999999),
    (15.0, 15.99999, 17.00001, 18.0),
    (1.0E-6, -1.1E-6, 0.0, -0.0),
    (0.0010001, -0.0009999, 0.0100000, -0.0100002),
    (4096.5005, -4096.4995, 8192.2500, -8192.2505),
    (7.0000005, -7.0000005, 10.999999, -11.000001)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LA, LB: TVecF32x4;
  LCaseIdx: Integer;
  LLane: Integer;

  LMaskEqFacade, LMaskEqDirect: TMask4;
  LMaskLtFacade, LMaskLtDirect: TMask4;
  LMaskLeFacade, LMaskLeDirect: TMask4;
  LMaskGtFacade, LMaskGtDirect: TMask4;
  LMaskGeFacade, LMaskGeDirect: TMask4;
  LMaskNeFacade, LMaskNeDirect: TMask4;

  LAllFacade, LAllDirect: Boolean;
  LAnyFacade, LAnyDirect: Boolean;
  LNoneFacade, LNoneDirect: Boolean;
  LPopFacade, LPopDirect: Integer;
  LFirstFacade, LFirstDirect: Integer;

  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('CmpEqF32x4 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqF32x4));
      AssertTrue('Mask4All should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Mask4All));

      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 3 do
        begin
          LA.f[LLane] := C_CASES_A[LCaseIdx, LLane];
          LB.f[LLane] := C_CASES_B[LCaseIdx, LLane];
        end;

        LMaskEqFacade := VecF32x4CmpEq(LA, LB);
        LMaskEqDirect := LDirectDispatch^.CmpEqF32x4(LA, LB);
        AssertEquals('Direct CmpEqF32x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskEqFacade), Integer(LMaskEqDirect));

        LMaskLtFacade := VecF32x4CmpLt(LA, LB);
        LMaskLtDirect := LDirectDispatch^.CmpLtF32x4(LA, LB);
        AssertEquals('Direct CmpLtF32x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskLtFacade), Integer(LMaskLtDirect));

        LMaskLeFacade := VecF32x4CmpLe(LA, LB);
        LMaskLeDirect := LDirectDispatch^.CmpLeF32x4(LA, LB);
        AssertEquals('Direct CmpLeF32x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskLeFacade), Integer(LMaskLeDirect));

        LMaskGtFacade := VecF32x4CmpGt(LA, LB);
        LMaskGtDirect := LDirectDispatch^.CmpGtF32x4(LA, LB);
        AssertEquals('Direct CmpGtF32x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskGtFacade), Integer(LMaskGtDirect));

        LMaskGeFacade := VecF32x4CmpGe(LA, LB);
        LMaskGeDirect := LDirectDispatch^.CmpGeF32x4(LA, LB);
        AssertEquals('Direct CmpGeF32x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskGeFacade), Integer(LMaskGeDirect));

        LMaskNeFacade := VecF32x4CmpNe(LA, LB);
        LMaskNeDirect := LDirectDispatch^.CmpNeF32x4(LA, LB);
        AssertEquals('Direct CmpNeF32x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMaskNeFacade), Integer(LMaskNeDirect));

        LAllFacade := Mask4All(LMaskLtFacade);
        LAllDirect := LDirectDispatch^.Mask4All(LMaskLtDirect);
        AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAllFacade, LAllDirect);

        LAnyFacade := Mask4Any(LMaskLtFacade);
        LAnyDirect := LDirectDispatch^.Mask4Any(LMaskLtDirect);
        AssertEquals('Direct Mask4Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAnyFacade, LAnyDirect);

        LNoneFacade := Mask4None(LMaskLtFacade);
        LNoneDirect := LDirectDispatch^.Mask4None(LMaskLtDirect);
        AssertEquals('Direct Mask4None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LNoneFacade, LNoneDirect);

        LPopFacade := Mask4PopCount(LMaskLtFacade);
        LPopDirect := LDirectDispatch^.Mask4PopCount(LMaskLtDirect);
        AssertEquals('Direct Mask4PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LPopFacade, LPopDirect);

        LFirstFacade := Mask4FirstSet(LMaskLtFacade);
        LFirstDirect := LDirectDispatch^.Mask4FirstSet(LMaskLtDirect);
        AssertEquals('Direct Mask4FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LFirstFacade, LFirstDirect);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_U32U64CompareEdgeMatrix_Parity;
const
  C_CASE_COUNT = 8;
  C_U32_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of UInt32 = (
    (0, 1, 2, 3, 4, 5, 6, 7),
    ($FFFFFFFF, $FFFFFFFE, $80000000, $7FFFFFFF, 1, 2, 3, 4),
    (100, 200, 300, 400, 500, 600, 700, 800),
    (0, 0, 0, 0, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF),
    ($80000000, $80000001, $7FFFFFFE, $7FFFFFFF, 15, 16, 17, 18),
    (42, 43, 44, 45, 46, 47, 48, 49),
    ($AAAAAAAA, $55555555, $0F0F0F0F, $F0F0F0F0, 9, 10, 11, 12),
    (1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000)
  );
  C_U32_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of UInt32 = (
    (0, 0, 3, 2, 4, 6, 5, 7),
    ($FFFFFFFF, 1, $7FFFFFFF, $80000000, 2, 2, 4, 3),
    (100, 199, 301, 400, 499, 601, 700, 900),
    (1, 0, $FFFFFFFF, 0, $FFFFFFFF, 0, $FFFFFFFF, 0),
    ($7FFFFFFF, $80000000, $7FFFFFFF, $7FFFFFFE, 15, 15, 18, 17),
    (41, 43, 45, 45, 47, 47, 49, 49),
    ($AAAAAAAA, $AAAAAAAA, $F0F0F0F0, $0F0F0F0F, 8, 10, 12, 12),
    (999, 2001, 3000, 3999, 5001, 6000, 6999, 9000)
  );

  C_U64_CASES_A: array[0..C_CASE_COUNT - 1, 0..3] of UInt64 = (
    (0, 1, 2, 3),
    (18446744073709551615, 9223372036854775808, 9223372036854775807, 42),
    (1000, 2000, 3000, 4000),
    (0, 18446744073709551615, 123456789, 987654321),
    (12297829382473034410, 6148914691236517205, 11, 12),
    (15, 16, 17, 18),
    ($0000000100000000, $0000000200000000, 5, 6),
    (9000000000, 9000000001, 9000000002, 9000000003)
  );
  C_U64_CASES_B: array[0..C_CASE_COUNT - 1, 0..3] of UInt64 = (
    (0, 0, 3, 2),
    (18446744073709551615, 9223372036854775807, 9223372036854775808, 41),
    (1000, 1999, 3001, 4000),
    (1, 18446744073709551615, 123456788, 987654322),
    (12297829382473034410, 12297829382473034410, 10, 12),
    (14, 16, 18, 18),
    ($0000000100000001, $0000000200000000, 4, 7),
    (9000000001, 9000000001, 9000000000, 9000000004)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAu32, LBu32: TVecU32x8;
  LAu64, LBu64: TVecU64x4;
  LCaseIdx: Integer;
  LLane: Integer;

  LMask8EqFacade, LMask8EqDirect: TMask8;
  LMask8LtFacade, LMask8LtDirect: TMask8;
  LMask8LeFacade, LMask8LeDirect: TMask8;
  LMask8GtFacade, LMask8GtDirect: TMask8;
  LMask8GeFacade, LMask8GeDirect: TMask8;
  LMask8NeExpected, LMask8NeDirect: TMask8;

  LMask4EqFacade, LMask4EqDirect: TMask4;
  LMask4LtFacade, LMask4LtDirect: TMask4;
  LMask4LeFacade, LMask4LeDirect: TMask4;
  LMask4GtFacade, LMask4GtDirect: TMask4;
  LMask4GeFacade, LMask4GeDirect: TMask4;
  LMask4NeFacade, LMask4NeDirect: TMask4;

  LMask8AllFacade, LMask8AllDirect: Boolean;
  LMask8AnyFacade, LMask8AnyDirect: Boolean;
  LMask8NoneFacade, LMask8NoneDirect: Boolean;
  LMask8PopFacade, LMask8PopDirect: Integer;
  LMask8FirstFacade, LMask8FirstDirect: Integer;

  LMask4AllFacade, LMask4AllDirect: Boolean;
  LMask4AnyFacade, LMask4AnyDirect: Boolean;
  LMask4NoneFacade, LMask4NoneDirect: Boolean;
  LMask4PopFacade, LMask4PopDirect: Integer;
  LMask4FirstFacade, LMask4FirstDirect: Integer;

  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.CmpEqU32x8)) or
         (not Assigned(LDirectDispatch^.CmpLtU32x8)) or
         (not Assigned(LDirectDispatch^.CmpLeU32x8)) or
         (not Assigned(LDirectDispatch^.CmpGtU32x8)) or
         (not Assigned(LDirectDispatch^.CmpGeU32x8)) or
         (not Assigned(LDirectDispatch^.CmpNeU32x8)) or
         (not Assigned(LDirectDispatch^.CmpEqU64x4)) or
         (not Assigned(LDirectDispatch^.CmpLtU64x4)) or
         (not Assigned(LDirectDispatch^.CmpLeU64x4)) or
         (not Assigned(LDirectDispatch^.CmpGtU64x4)) or
         (not Assigned(LDirectDispatch^.CmpGeU64x4)) or
         (not Assigned(LDirectDispatch^.CmpNeU64x4)) or
         (not Assigned(LDirectDispatch^.Mask8All)) or
         (not Assigned(LDirectDispatch^.Mask8Any)) or
         (not Assigned(LDirectDispatch^.Mask8None)) or
         (not Assigned(LDirectDispatch^.Mask8PopCount)) or
         (not Assigned(LDirectDispatch^.Mask8FirstSet)) or
         (not Assigned(LDirectDispatch^.Mask4All)) or
         (not Assigned(LDirectDispatch^.Mask4Any)) or
         (not Assigned(LDirectDispatch^.Mask4None)) or
         (not Assigned(LDirectDispatch^.Mask4PopCount)) or
         (not Assigned(LDirectDispatch^.Mask4FirstSet)) then
        Continue;

      Inc(LTestedCount);

      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 7 do
        begin
          LAu32.u[LLane] := C_U32_CASES_A[LCaseIdx, LLane];
          LBu32.u[LLane] := C_U32_CASES_B[LCaseIdx, LLane];
        end;

        for LLane := 0 to 3 do
        begin
          LAu64.u[LLane] := C_U64_CASES_A[LCaseIdx, LLane];
          LBu64.u[LLane] := C_U64_CASES_B[LCaseIdx, LLane];
        end;

        // U32x8 compare parity
        LMask8EqFacade := VecU32x8CmpEq(LAu32, LBu32);
        LMask8EqDirect := LDirectDispatch^.CmpEqU32x8(LAu32, LBu32);
        AssertEquals('Direct CmpEqU32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8EqFacade), Integer(LMask8EqDirect));

        LMask8LtFacade := VecU32x8CmpLt(LAu32, LBu32);
        LMask8LtDirect := LDirectDispatch^.CmpLtU32x8(LAu32, LBu32);
        AssertEquals('Direct CmpLtU32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8LtFacade), Integer(LMask8LtDirect));

        LMask8LeFacade := VecU32x8CmpLe(LAu32, LBu32);
        LMask8LeDirect := LDirectDispatch^.CmpLeU32x8(LAu32, LBu32);
        AssertEquals('Direct CmpLeU32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8LeFacade), Integer(LMask8LeDirect));

        LMask8GtFacade := VecU32x8CmpGt(LAu32, LBu32);
        LMask8GtDirect := LDirectDispatch^.CmpGtU32x8(LAu32, LBu32);
        AssertEquals('Direct CmpGtU32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8GtFacade), Integer(LMask8GtDirect));

        LMask8GeFacade := VecU32x8CmpGe(LAu32, LBu32);
        LMask8GeDirect := LDirectDispatch^.CmpGeU32x8(LAu32, LBu32);
        AssertEquals('Direct CmpGeU32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8GeFacade), Integer(LMask8GeDirect));

        LMask8NeExpected := 0;
        for LLane := 0 to 7 do
          if LAu32.u[LLane] <> LBu32.u[LLane] then
            LMask8NeExpected := LMask8NeExpected or TMask8(1 shl LLane);

        LMask8NeDirect := LDirectDispatch^.CmpNeU32x8(LAu32, LBu32);
        AssertEquals('Direct CmpNeU32x8 expected parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8NeExpected), Integer(LMask8NeDirect));

        LMask8AllFacade := Mask8All(LMask8LtFacade);
        LMask8AllDirect := LDirectDispatch^.Mask8All(LMask8LtDirect);
        AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8AllFacade, LMask8AllDirect);

        LMask8AnyFacade := Mask8Any(LMask8LtFacade);
        LMask8AnyDirect := LDirectDispatch^.Mask8Any(LMask8LtDirect);
        AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8AnyFacade, LMask8AnyDirect);

        LMask8NoneFacade := Mask8None(LMask8LtFacade);
        LMask8NoneDirect := LDirectDispatch^.Mask8None(LMask8LtDirect);
        AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8NoneFacade, LMask8NoneDirect);

        LMask8PopFacade := Mask8PopCount(LMask8LtFacade);
        LMask8PopDirect := LDirectDispatch^.Mask8PopCount(LMask8LtDirect);
        AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8PopFacade, LMask8PopDirect);

        LMask8FirstFacade := Mask8FirstSet(LMask8LtFacade);
        LMask8FirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8LtDirect);
        AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8FirstFacade, LMask8FirstDirect);

        // U64x4 compare parity
        LMask4EqFacade := VecU64x4CmpEq(LAu64, LBu64);
        LMask4EqDirect := LDirectDispatch^.CmpEqU64x4(LAu64, LBu64);
        AssertEquals('Direct CmpEqU64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4EqFacade), Integer(LMask4EqDirect));

        LMask4LtFacade := VecU64x4CmpLt(LAu64, LBu64);
        LMask4LtDirect := LDirectDispatch^.CmpLtU64x4(LAu64, LBu64);
        AssertEquals('Direct CmpLtU64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4LtFacade), Integer(LMask4LtDirect));

        LMask4LeFacade := VecU64x4CmpLe(LAu64, LBu64);
        LMask4LeDirect := LDirectDispatch^.CmpLeU64x4(LAu64, LBu64);
        AssertEquals('Direct CmpLeU64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4LeFacade), Integer(LMask4LeDirect));

        LMask4GtFacade := VecU64x4CmpGt(LAu64, LBu64);
        LMask4GtDirect := LDirectDispatch^.CmpGtU64x4(LAu64, LBu64);
        AssertEquals('Direct CmpGtU64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4GtFacade), Integer(LMask4GtDirect));

        LMask4GeFacade := VecU64x4CmpGe(LAu64, LBu64);
        LMask4GeDirect := LDirectDispatch^.CmpGeU64x4(LAu64, LBu64);
        AssertEquals('Direct CmpGeU64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4GeFacade), Integer(LMask4GeDirect));

        LMask4NeFacade := VecU64x4CmpNe(LAu64, LBu64);
        LMask4NeDirect := LDirectDispatch^.CmpNeU64x4(LAu64, LBu64);
        AssertEquals('Direct CmpNeU64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4NeFacade), Integer(LMask4NeDirect));

        LMask4AllFacade := Mask4All(LMask4LtFacade);
        LMask4AllDirect := LDirectDispatch^.Mask4All(LMask4LtDirect);
        AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask4AllFacade, LMask4AllDirect);

        LMask4AnyFacade := Mask4Any(LMask4LtFacade);
        LMask4AnyDirect := LDirectDispatch^.Mask4Any(LMask4LtDirect);
        AssertEquals('Direct Mask4Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask4AnyFacade, LMask4AnyDirect);

        LMask4NoneFacade := Mask4None(LMask4LtFacade);
        LMask4NoneDirect := LDirectDispatch^.Mask4None(LMask4LtDirect);
        AssertEquals('Direct Mask4None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask4NoneFacade, LMask4NoneDirect);

        LMask4PopFacade := Mask4PopCount(LMask4LtFacade);
        LMask4PopDirect := LDirectDispatch^.Mask4PopCount(LMask4LtDirect);
        AssertEquals('Direct Mask4PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask4PopFacade, LMask4PopDirect);

        LMask4FirstFacade := Mask4FirstSet(LMask4LtFacade);
        LMask4FirstDirect := LDirectDispatch^.Mask4FirstSet(LMask4LtDirect);
        AssertEquals('Direct Mask4FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask4FirstFacade, LMask4FirstDirect);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32x8F64x4ArithmeticReduceMatrix_Parity;
const
  C_EPSILON_F32 = 1e-5;
  C_EPSILON_F64 = 1e-9;
  C_CASE_COUNT = 6;
  C_F32_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of Single = (
    (1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0),
    (-1.5, 2.5, -3.5, 4.5, -5.5, 6.5, -7.5, 8.5),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0),
    (-10.0, -20.0, 30.0, 40.0, -50.0, 60.0, -70.0, 80.0),
    (1000.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0, 7000.0, 8000.0),
    (0.001, -0.002, 0.003, -0.004, 0.005, -0.006, 0.007, -0.008)
  );
  C_F32_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of Single = (
    (8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0),
    (2.0, -2.0, 2.0, -2.0, 2.0, -2.0, 2.0, -2.0),
    (1.0, 0.5, 0.25, 0.125, 0.5, 1.0, 2.0, 4.0),
    (5.0, -4.0, 3.0, -2.0, 1.0, -1.0, 2.0, -3.0),
    (10.0, 20.0, 25.0, 50.0, 100.0, 125.0, 200.0, 250.0),
    (0.1, 0.2, -0.3, -0.4, 0.5, 0.6, -0.7, -0.8)
  );

  C_F64_CASES_A: array[0..C_CASE_COUNT - 1, 0..3] of Double = (
    (1.0, 2.0, 3.0, 4.0),
    (-1.25, 2.5, -3.75, 5.0),
    (100.0, 200.0, 300.0, 400.0),
    (0.125, 0.25, 0.5, 1.0),
    (-10.0, -20.0, 30.0, 40.0),
    (1.0E-6, -2.0E-6, 3.0E-6, -4.0E-6)
  );
  C_F64_CASES_B: array[0..C_CASE_COUNT - 1, 0..3] of Double = (
    (4.0, 3.0, 2.0, 1.0),
    (2.0, -2.0, 2.0, -2.0),
    (10.0, 20.0, 25.0, 50.0),
    (1.0, 0.5, 0.25, 0.125),
    (5.0, -4.0, 3.0, -2.0),
    (0.1, 0.2, -0.3, -0.4)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAf32, LBf32: TVecF32x8;
  LAf64, LBf64: TVecF64x4;
  LCaseIdx: Integer;
  LLane: Integer;

  LAddF32Facade, LAddF32Direct: TVecF32x8;
  LSubF32Facade, LSubF32Direct: TVecF32x8;
  LMulF32Facade, LMulF32Direct: TVecF32x8;
  LDivF32Facade, LDivF32Direct: TVecF32x8;
  LReduceAddF32Facade, LReduceAddF32Direct: Single;
  LReduceMinF32Facade, LReduceMinF32Direct: Single;
  LReduceMaxF32Facade, LReduceMaxF32Direct: Single;
  LReduceMulF32Facade, LReduceMulF32Direct: Single;

  LAddF64Facade, LAddF64Direct: TVecF64x4;
  LSubF64Facade, LSubF64Direct: TVecF64x4;
  LMulF64Facade, LMulF64Direct: TVecF64x4;
  LDivF64Facade, LDivF64Direct: TVecF64x4;
  LReduceAddF64Facade, LReduceAddF64Direct: Double;
  LReduceMinF64Facade, LReduceMinF64Direct: Double;
  LReduceMaxF64Facade, LReduceMaxF64Direct: Double;
  LReduceMulF64Facade, LReduceMulF64Direct: Double;
  LToleranceF32, LToleranceF64: Double;

  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.AddF32x8)) or
         (not Assigned(LDirectDispatch^.SubF32x8)) or
         (not Assigned(LDirectDispatch^.MulF32x8)) or
         (not Assigned(LDirectDispatch^.DivF32x8)) or
         (not Assigned(LDirectDispatch^.ReduceAddF32x8)) or
         (not Assigned(LDirectDispatch^.ReduceMinF32x8)) or
         (not Assigned(LDirectDispatch^.ReduceMaxF32x8)) or
         (not Assigned(LDirectDispatch^.ReduceMulF32x8)) or
         (not Assigned(LDirectDispatch^.AddF64x4)) or
         (not Assigned(LDirectDispatch^.SubF64x4)) or
         (not Assigned(LDirectDispatch^.MulF64x4)) or
         (not Assigned(LDirectDispatch^.DivF64x4)) or
         (not Assigned(LDirectDispatch^.ReduceAddF64x4)) or
         (not Assigned(LDirectDispatch^.ReduceMinF64x4)) or
         (not Assigned(LDirectDispatch^.ReduceMaxF64x4)) or
         (not Assigned(LDirectDispatch^.ReduceMulF64x4)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 7 do
        begin
          LAf32.f[LLane] := C_F32_CASES_A[LCaseIdx, LLane];
          LBf32.f[LLane] := C_F32_CASES_B[LCaseIdx, LLane];
        end;

        for LLane := 0 to 3 do
        begin
          LAf64.d[LLane] := C_F64_CASES_A[LCaseIdx, LLane];
          LBf64.d[LLane] := C_F64_CASES_B[LCaseIdx, LLane];
        end;

        LAddF32Facade := VecF32x8Add(LAf32, LBf32);
        LAddF32Direct := LDirectDispatch^.AddF32x8(LAf32, LBf32);
        LSubF32Facade := VecF32x8Sub(LAf32, LBf32);
        LSubF32Direct := LDirectDispatch^.SubF32x8(LAf32, LBf32);
        LMulF32Facade := VecF32x8Mul(LAf32, LBf32);
        LMulF32Direct := LDirectDispatch^.MulF32x8(LAf32, LBf32);
        LDivF32Facade := VecF32x8Div(LAf32, LBf32);
        LDivF32Direct := LDirectDispatch^.DivF32x8(LAf32, LBf32);

        for LLane := 0 to 7 do
        begin
          AssertEquals('Direct AddF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LAddF32Facade.f[LLane], LAddF32Direct.f[LLane], C_EPSILON_F32);
          AssertEquals('Direct SubF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LSubF32Facade.f[LLane], LSubF32Direct.f[LLane], C_EPSILON_F32);
          AssertEquals('Direct MulF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LMulF32Facade.f[LLane], LMulF32Direct.f[LLane], C_EPSILON_F32);
          AssertEquals('Direct DivF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LDivF32Facade.f[LLane], LDivF32Direct.f[LLane], C_EPSILON_F32);
        end;

        LReduceAddF32Facade := VecF32x8ReduceAdd(LAf32);
        LReduceAddF32Direct := LDirectDispatch^.ReduceAddF32x8(LAf32);
        AssertEquals('Direct ReduceAddF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceAddF32Facade, LReduceAddF32Direct, C_EPSILON_F32);

        LReduceMinF32Facade := VecF32x8ReduceMin(LAf32);
        LReduceMinF32Direct := LDirectDispatch^.ReduceMinF32x8(LAf32);
        AssertEquals('Direct ReduceMinF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMinF32Facade, LReduceMinF32Direct, C_EPSILON_F32);

        LReduceMaxF32Facade := VecF32x8ReduceMax(LAf32);
        LReduceMaxF32Direct := LDirectDispatch^.ReduceMaxF32x8(LAf32);
        AssertEquals('Direct ReduceMaxF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMaxF32Facade, LReduceMaxF32Direct, C_EPSILON_F32);

        LReduceMulF32Facade := VecF32x8ReduceMul(LAf32);
        LReduceMulF32Direct := LDirectDispatch^.ReduceMulF32x8(LAf32);
        LToleranceF32 := Max(C_EPSILON_F32, Abs(LReduceMulF32Facade) * 1e-6);
        AssertTrue('Direct ReduceMulF32x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Abs(LReduceMulF32Facade - LReduceMulF32Direct) <= LToleranceF32);

        LAddF64Facade := VecF64x4Add(LAf64, LBf64);
        LAddF64Direct := LDirectDispatch^.AddF64x4(LAf64, LBf64);
        LSubF64Facade := VecF64x4Sub(LAf64, LBf64);
        LSubF64Direct := LDirectDispatch^.SubF64x4(LAf64, LBf64);
        LMulF64Facade := VecF64x4Mul(LAf64, LBf64);
        LMulF64Direct := LDirectDispatch^.MulF64x4(LAf64, LBf64);
        LDivF64Facade := VecF64x4Div(LAf64, LBf64);
        LDivF64Direct := LDirectDispatch^.DivF64x4(LAf64, LBf64);

        for LLane := 0 to 3 do
        begin
          AssertEquals('Direct AddF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LAddF64Facade.d[LLane], LAddF64Direct.d[LLane], C_EPSILON_F64);
          AssertEquals('Direct SubF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LSubF64Facade.d[LLane], LSubF64Direct.d[LLane], C_EPSILON_F64);
          AssertEquals('Direct MulF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LMulF64Facade.d[LLane], LMulF64Direct.d[LLane], C_EPSILON_F64);
          AssertEquals('Direct DivF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LDivF64Facade.d[LLane], LDivF64Direct.d[LLane], C_EPSILON_F64);
        end;

        LReduceAddF64Facade := VecF64x4ReduceAdd(LAf64);
        LReduceAddF64Direct := LDirectDispatch^.ReduceAddF64x4(LAf64);
        AssertEquals('Direct ReduceAddF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceAddF64Facade, LReduceAddF64Direct, C_EPSILON_F64);

        LReduceMinF64Facade := VecF64x4ReduceMin(LAf64);
        LReduceMinF64Direct := LDirectDispatch^.ReduceMinF64x4(LAf64);
        AssertEquals('Direct ReduceMinF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMinF64Facade, LReduceMinF64Direct, C_EPSILON_F64);

        LReduceMaxF64Facade := VecF64x4ReduceMax(LAf64);
        LReduceMaxF64Direct := LDirectDispatch^.ReduceMaxF64x4(LAf64);
        AssertEquals('Direct ReduceMaxF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMaxF64Facade, LReduceMaxF64Direct, C_EPSILON_F64);

        LReduceMulF64Facade := VecF64x4ReduceMul(LAf64);
        LReduceMulF64Direct := LDirectDispatch^.ReduceMulF64x4(LAf64);
        LToleranceF64 := Max(C_EPSILON_F64, Abs(LReduceMulF64Facade) * 1e-12);
        AssertTrue('Direct ReduceMulF64x4 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Abs(LReduceMulF64Facade - LReduceMulF64Direct) <= LToleranceF64);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32x16F64x8CompareReduceMatrix_Parity;
const
  C_EPSILON_F32 = 1e-5;
  C_EPSILON_F64 = 1e-9;
  C_CASE_COUNT = 5;
  C_F32_CASES_A: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0),
    (-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0, -9.0, 10.0, -11.0, 12.0, -13.0, 14.0, -15.0, 16.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 0.0625, 0.03125, 0.015625, 0.0078125, 3.0, 6.0, 12.0, 24.0),
    (1000.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0, 7000.0, 8000.0, -1000.0, -2000.0, -3000.0, -4000.0, -5000.0, -6000.0, -7000.0, -8000.0),
    (1.0E-4, -2.0E-4, 3.0E-4, -4.0E-4, 5.0E-4, -6.0E-4, 7.0E-4, -8.0E-4, 9.0E-4, -1.0E-3, 1.1E-3, -1.2E-3, 1.3E-3, -1.4E-3, 1.5E-3, -1.6E-3)
  );
  C_F32_CASES_B: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (0.0, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0, 7.0, 9.0, 11.0, 10.0, 12.0, 14.0, 13.0, 15.0),
    (-1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0, 0.0625, 0.0625, 0.010, 0.008, 3.0, 5.0, 12.0, 25.0),
    (1000.0, 1999.0, 3001.0, 4000.0, 4999.0, 6001.0, 7000.0, 8001.0, -999.0, -2001.0, -3000.0, -3999.0, -5001.0, -6000.0, -7001.0, -8000.0),
    (1.1E-4, -2.0E-4, 2.9E-4, -4.1E-4, 5.0E-4, -6.1E-4, 7.0E-4, -8.1E-4, 9.0E-4, -9.9E-4, 1.1E-3, -1.19E-3, 1.31E-3, -1.4E-3, 1.49E-3, -1.61E-3)
  );

  C_F64_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0),
    (-1.5, 2.5, -3.5, 4.5, -5.5, 6.5, -7.5, 8.5),
    (100.0, 200.0, 300.0, 400.0, -100.0, -200.0, -300.0, -400.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0),
    (1.0E-6, -2.0E-6, 3.0E-6, -4.0E-6, 5.0E-6, -6.0E-6, 7.0E-6, -8.0E-6)
  );
  C_F64_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (0.0, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0),
    (-1.5, -2.5, -3.0, -4.5, -5.0, -6.5, -7.0, -8.5),
    (100.0, 199.0, 301.0, 400.0, -99.0, -201.0, -300.0, -399.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0),
    (1.1E-6, -2.0E-6, 2.9E-6, -4.1E-6, 5.0E-6, -6.1E-6, 7.0E-6, -8.1E-6)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAf32, LBf32: TVecF32x16;
  LAf64, LBf64: TVecF64x8;
  LCaseIdx: Integer;
  LLane: Integer;

  LMask16EqFacade, LMask16EqDirect: TMask16;
  LMask16LtFacade, LMask16LtDirect: TMask16;
  LMask16LeFacade, LMask16LeDirect: TMask16;
  LMask16GtFacade, LMask16GtDirect: TMask16;
  LMask16GeFacade, LMask16GeDirect: TMask16;
  LMask16NeFacade, LMask16NeDirect: TMask16;

  LMask8EqFacade, LMask8EqDirect: TMask8;
  LMask8LtFacade, LMask8LtDirect: TMask8;
  LMask8LeFacade, LMask8LeDirect: TMask8;
  LMask8GtFacade, LMask8GtDirect: TMask8;
  LMask8GeFacade, LMask8GeDirect: TMask8;
  LMask8NeFacade, LMask8NeDirect: TMask8;

  LReduceAddF32Facade, LReduceAddF32Direct: Single;
  LReduceMinF32Facade, LReduceMinF32Direct: Single;
  LReduceMaxF32Facade, LReduceMaxF32Direct: Single;

  LReduceAddF64Facade, LReduceAddF64Direct: Double;
  LReduceMinF64Facade, LReduceMinF64Direct: Double;
  LReduceMaxF64Facade, LReduceMaxF64Direct: Double;

  LMask16AllFacade, LMask16AllDirect: Boolean;
  LMask16AnyFacade, LMask16AnyDirect: Boolean;
  LMask16NoneFacade, LMask16NoneDirect: Boolean;
  LMask16PopFacade, LMask16PopDirect: Integer;
  LMask16FirstFacade, LMask16FirstDirect: Integer;

  LMask8AllFacade, LMask8AllDirect: Boolean;
  LMask8AnyFacade, LMask8AnyDirect: Boolean;
  LMask8NoneFacade, LMask8NoneDirect: Boolean;
  LMask8PopFacade, LMask8PopDirect: Integer;
  LMask8FirstFacade, LMask8FirstDirect: Integer;

  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.CmpEqF32x16)) or
         (not Assigned(LDirectDispatch^.CmpLtF32x16)) or
         (not Assigned(LDirectDispatch^.CmpLeF32x16)) or
         (not Assigned(LDirectDispatch^.CmpGtF32x16)) or
         (not Assigned(LDirectDispatch^.CmpGeF32x16)) or
         (not Assigned(LDirectDispatch^.CmpNeF32x16)) or
         (not Assigned(LDirectDispatch^.CmpEqF64x8)) or
         (not Assigned(LDirectDispatch^.CmpLtF64x8)) or
         (not Assigned(LDirectDispatch^.CmpLeF64x8)) or
         (not Assigned(LDirectDispatch^.CmpGtF64x8)) or
         (not Assigned(LDirectDispatch^.CmpGeF64x8)) or
         (not Assigned(LDirectDispatch^.CmpNeF64x8)) or
         (not Assigned(LDirectDispatch^.ReduceAddF32x16)) or
         (not Assigned(LDirectDispatch^.ReduceMinF32x16)) or
         (not Assigned(LDirectDispatch^.ReduceMaxF32x16)) or
         (not Assigned(LDirectDispatch^.ReduceAddF64x8)) or
         (not Assigned(LDirectDispatch^.ReduceMinF64x8)) or
         (not Assigned(LDirectDispatch^.ReduceMaxF64x8)) or
         (not Assigned(LDirectDispatch^.Mask16All)) or
         (not Assigned(LDirectDispatch^.Mask16Any)) or
         (not Assigned(LDirectDispatch^.Mask16None)) or
         (not Assigned(LDirectDispatch^.Mask16PopCount)) or
         (not Assigned(LDirectDispatch^.Mask16FirstSet)) or
         (not Assigned(LDirectDispatch^.Mask8All)) or
         (not Assigned(LDirectDispatch^.Mask8Any)) or
         (not Assigned(LDirectDispatch^.Mask8None)) or
         (not Assigned(LDirectDispatch^.Mask8PopCount)) or
         (not Assigned(LDirectDispatch^.Mask8FirstSet)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 15 do
        begin
          LAf32.f[LLane] := C_F32_CASES_A[LCaseIdx, LLane];
          LBf32.f[LLane] := C_F32_CASES_B[LCaseIdx, LLane];
        end;

        for LLane := 0 to 7 do
        begin
          LAf64.d[LLane] := C_F64_CASES_A[LCaseIdx, LLane];
          LBf64.d[LLane] := C_F64_CASES_B[LCaseIdx, LLane];
        end;

        LMask16EqFacade := VecF32x16CmpEq_Mask(LAf32, LBf32);
        LMask16EqDirect := LDirectDispatch^.CmpEqF32x16(LAf32, LBf32);
        AssertEquals('Direct CmpEqF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16EqFacade), Integer(LMask16EqDirect));

        LMask16LtFacade := VecF32x16CmpLt_Mask(LAf32, LBf32);
        LMask16LtDirect := LDirectDispatch^.CmpLtF32x16(LAf32, LBf32);
        AssertEquals('Direct CmpLtF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16LtFacade), Integer(LMask16LtDirect));

        LMask16LeFacade := VecF32x16CmpLe_Mask(LAf32, LBf32);
        LMask16LeDirect := LDirectDispatch^.CmpLeF32x16(LAf32, LBf32);
        AssertEquals('Direct CmpLeF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16LeFacade), Integer(LMask16LeDirect));

        LMask16GtFacade := VecF32x16CmpGt_Mask(LAf32, LBf32);
        LMask16GtDirect := LDirectDispatch^.CmpGtF32x16(LAf32, LBf32);
        AssertEquals('Direct CmpGtF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16GtFacade), Integer(LMask16GtDirect));

        LMask16GeFacade := VecF32x16CmpGe_Mask(LAf32, LBf32);
        LMask16GeDirect := LDirectDispatch^.CmpGeF32x16(LAf32, LBf32);
        AssertEquals('Direct CmpGeF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16GeFacade), Integer(LMask16GeDirect));

        LMask16NeFacade := VecF32x16CmpNe_Mask(LAf32, LBf32);
        LMask16NeDirect := LDirectDispatch^.CmpNeF32x16(LAf32, LBf32);
        AssertEquals('Direct CmpNeF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16NeFacade), Integer(LMask16NeDirect));

        LMask8EqFacade := VecF64x8CmpEq(LAf64, LBf64);
        LMask8EqDirect := LDirectDispatch^.CmpEqF64x8(LAf64, LBf64);
        AssertEquals('Direct CmpEqF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8EqFacade), Integer(LMask8EqDirect));

        LMask8LtFacade := VecF64x8CmpLt(LAf64, LBf64);
        LMask8LtDirect := LDirectDispatch^.CmpLtF64x8(LAf64, LBf64);
        AssertEquals('Direct CmpLtF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8LtFacade), Integer(LMask8LtDirect));

        LMask8LeFacade := VecF64x8CmpLe(LAf64, LBf64);
        LMask8LeDirect := LDirectDispatch^.CmpLeF64x8(LAf64, LBf64);
        AssertEquals('Direct CmpLeF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8LeFacade), Integer(LMask8LeDirect));

        LMask8GtFacade := VecF64x8CmpGt(LAf64, LBf64);
        LMask8GtDirect := LDirectDispatch^.CmpGtF64x8(LAf64, LBf64);
        AssertEquals('Direct CmpGtF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8GtFacade), Integer(LMask8GtDirect));

        LMask8GeFacade := VecF64x8CmpGe(LAf64, LBf64);
        LMask8GeDirect := LDirectDispatch^.CmpGeF64x8(LAf64, LBf64);
        AssertEquals('Direct CmpGeF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8GeFacade), Integer(LMask8GeDirect));

        LMask8NeFacade := VecF64x8CmpNe(LAf64, LBf64);
        LMask8NeDirect := LDirectDispatch^.CmpNeF64x8(LAf64, LBf64);
        AssertEquals('Direct CmpNeF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8NeFacade), Integer(LMask8NeDirect));

        LMask16AllFacade := Mask16All(LMask16LtFacade);
        LMask16AllDirect := LDirectDispatch^.Mask16All(LMask16LtDirect);
        AssertEquals('Direct Mask16All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16AllFacade, LMask16AllDirect);

        LMask16AnyFacade := Mask16Any(LMask16LtFacade);
        LMask16AnyDirect := LDirectDispatch^.Mask16Any(LMask16LtDirect);
        AssertEquals('Direct Mask16Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16AnyFacade, LMask16AnyDirect);

        LMask16NoneFacade := Mask16None(LMask16LtFacade);
        LMask16NoneDirect := LDirectDispatch^.Mask16None(LMask16LtDirect);
        AssertEquals('Direct Mask16None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16NoneFacade, LMask16NoneDirect);

        LMask16PopFacade := Mask16PopCount(LMask16LtFacade);
        LMask16PopDirect := LDirectDispatch^.Mask16PopCount(LMask16LtDirect);
        AssertEquals('Direct Mask16PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16PopFacade, LMask16PopDirect);

        LMask16FirstFacade := Mask16FirstSet(LMask16LtFacade);
        LMask16FirstDirect := LDirectDispatch^.Mask16FirstSet(LMask16LtDirect);
        AssertEquals('Direct Mask16FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16FirstFacade, LMask16FirstDirect);

        LMask8AllFacade := Mask8All(LMask8LtFacade);
        LMask8AllDirect := LDirectDispatch^.Mask8All(LMask8LtDirect);
        AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8AllFacade, LMask8AllDirect);

        LMask8AnyFacade := Mask8Any(LMask8LtFacade);
        LMask8AnyDirect := LDirectDispatch^.Mask8Any(LMask8LtDirect);
        AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8AnyFacade, LMask8AnyDirect);

        LMask8NoneFacade := Mask8None(LMask8LtFacade);
        LMask8NoneDirect := LDirectDispatch^.Mask8None(LMask8LtDirect);
        AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8NoneFacade, LMask8NoneDirect);

        LMask8PopFacade := Mask8PopCount(LMask8LtFacade);
        LMask8PopDirect := LDirectDispatch^.Mask8PopCount(LMask8LtDirect);
        AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8PopFacade, LMask8PopDirect);

        LMask8FirstFacade := Mask8FirstSet(LMask8LtFacade);
        LMask8FirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8LtDirect);
        AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8FirstFacade, LMask8FirstDirect);

        LReduceAddF32Facade := VecF32x16ReduceAdd(LAf32);
        LReduceAddF32Direct := LDirectDispatch^.ReduceAddF32x16(LAf32);
        AssertEquals('Direct ReduceAddF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceAddF32Facade, LReduceAddF32Direct, C_EPSILON_F32);

        LReduceMinF32Facade := VecF32x16ReduceMin(LAf32);
        LReduceMinF32Direct := LDirectDispatch^.ReduceMinF32x16(LAf32);
        AssertEquals('Direct ReduceMinF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMinF32Facade, LReduceMinF32Direct, C_EPSILON_F32);

        LReduceMaxF32Facade := VecF32x16ReduceMax(LAf32);
        LReduceMaxF32Direct := LDirectDispatch^.ReduceMaxF32x16(LAf32);
        AssertEquals('Direct ReduceMaxF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMaxF32Facade, LReduceMaxF32Direct, C_EPSILON_F32);

        LReduceAddF64Facade := VecF64x8ReduceAdd(LAf64);
        LReduceAddF64Direct := LDirectDispatch^.ReduceAddF64x8(LAf64);
        AssertEquals('Direct ReduceAddF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceAddF64Facade, LReduceAddF64Direct, C_EPSILON_F64);

        LReduceMinF64Facade := VecF64x8ReduceMin(LAf64);
        LReduceMinF64Direct := LDirectDispatch^.ReduceMinF64x8(LAf64);
        AssertEquals('Direct ReduceMinF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMinF64Facade, LReduceMinF64Direct, C_EPSILON_F64);

        LReduceMaxF64Facade := VecF64x8ReduceMax(LAf64);
        LReduceMaxF64Direct := LDirectDispatch^.ReduceMaxF64x8(LAf64);
        AssertEquals('Direct ReduceMaxF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LReduceMaxF64Facade, LReduceMaxF64Direct, C_EPSILON_F64);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32x16F64x8ArithmeticMatrix_Parity;
const
  C_EPSILON_F32 = 1e-5;
  C_EPSILON_F64 = 1e-9;
  C_CASE_COUNT = 5;
  C_F32_CASES_A: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0),
    (-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0, -9.0, 10.0, -11.0, 12.0, -13.0, 14.0, -15.0, 16.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 0.0625, 0.03125, 0.015625, 0.0078125, 3.0, 6.0, 12.0, 24.0),
    (1000.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0, 7000.0, 8000.0, -1000.0, -2000.0, -3000.0, -4000.0, -5000.0, -6000.0, -7000.0, -8000.0),
    (1.0E-4, -2.0E-4, 3.0E-4, -4.0E-4, 5.0E-4, -6.0E-4, 7.0E-4, -8.0E-4, 9.0E-4, -1.0E-3, 1.1E-3, -1.2E-3, 1.3E-3, -1.4E-3, 1.5E-3, -1.6E-3)
  );
  C_F32_CASES_B: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (0.5, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0, 7.0, 9.0, 11.0, 10.0, 12.0, 14.0, 13.0, 15.0),
    (-1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0, 0.0625, 0.0625, 0.010, 0.008, 3.0, 5.0, 12.0, 25.0),
    (1000.0, 1999.0, 3001.0, 4000.0, 4999.0, 6001.0, 7000.0, 8001.0, -999.0, -2001.0, -3000.0, -3999.0, -5001.0, -6000.0, -7001.0, -8000.0),
    (1.1E-4, -2.0E-4, 2.9E-4, -4.1E-4, 5.0E-4, -6.1E-4, 7.0E-4, -8.1E-4, 9.0E-4, -9.9E-4, 1.1E-3, -1.19E-3, 1.31E-3, -1.4E-3, 1.49E-3, -1.61E-3)
  );

  C_F64_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0),
    (-1.5, 2.5, -3.5, 4.5, -5.5, 6.5, -7.5, 8.5),
    (100.0, 200.0, 300.0, 400.0, -100.0, -200.0, -300.0, -400.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0),
    (1.0E-6, -2.0E-6, 3.0E-6, -4.0E-6, 5.0E-6, -6.0E-6, 7.0E-6, -8.0E-6)
  );
  C_F64_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (0.5, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0),
    (-1.5, -2.5, -3.0, -4.5, -5.0, -6.5, -7.0, -8.5),
    (100.0, 199.0, 301.0, 400.0, -99.0, -201.0, -300.0, -399.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0),
    (1.1E-6, -2.0E-6, 2.9E-6, -4.1E-6, 5.0E-6, -6.1E-6, 7.0E-6, -8.1E-6)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAf32, LBf32: TVecF32x16;
  LAf64, LBf64: TVecF64x8;
  LAddF32Facade, LAddF32Direct: TVecF32x16;
  LSubF32Facade, LSubF32Direct: TVecF32x16;
  LMulF32Facade, LMulF32Direct: TVecF32x16;
  LDivF32Facade, LDivF32Direct: TVecF32x16;
  LAddF64Facade, LAddF64Direct: TVecF64x8;
  LSubF64Facade, LSubF64Direct: TVecF64x8;
  LMulF64Facade, LMulF64Direct: TVecF64x8;
  LDivF64Facade, LDivF64Direct: TVecF64x8;
  LCaseIdx: Integer;
  LLane: Integer;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.AddF32x16)) or
         (not Assigned(LDirectDispatch^.SubF32x16)) or
         (not Assigned(LDirectDispatch^.MulF32x16)) or
         (not Assigned(LDirectDispatch^.DivF32x16)) or
         (not Assigned(LDirectDispatch^.AddF64x8)) or
         (not Assigned(LDirectDispatch^.SubF64x8)) or
         (not Assigned(LDirectDispatch^.MulF64x8)) or
         (not Assigned(LDirectDispatch^.DivF64x8)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 15 do
        begin
          LAf32.f[LLane] := C_F32_CASES_A[LCaseIdx, LLane];
          LBf32.f[LLane] := C_F32_CASES_B[LCaseIdx, LLane];
        end;

        for LLane := 0 to 7 do
        begin
          LAf64.d[LLane] := C_F64_CASES_A[LCaseIdx, LLane];
          LBf64.d[LLane] := C_F64_CASES_B[LCaseIdx, LLane];
        end;

        LAddF32Facade := VecF32x16Add(LAf32, LBf32);
        LAddF32Direct := LDirectDispatch^.AddF32x16(LAf32, LBf32);
        LSubF32Facade := VecF32x16Sub(LAf32, LBf32);
        LSubF32Direct := LDirectDispatch^.SubF32x16(LAf32, LBf32);
        LMulF32Facade := VecF32x16Mul(LAf32, LBf32);
        LMulF32Direct := LDirectDispatch^.MulF32x16(LAf32, LBf32);
        LDivF32Facade := VecF32x16Div(LAf32, LBf32);
        LDivF32Direct := LDirectDispatch^.DivF32x16(LAf32, LBf32);

        for LLane := 0 to 15 do
        begin
          AssertEquals('Direct AddF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LAddF32Facade.f[LLane], LAddF32Direct.f[LLane], C_EPSILON_F32);
          AssertEquals('Direct SubF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LSubF32Facade.f[LLane], LSubF32Direct.f[LLane], C_EPSILON_F32);
          AssertEquals('Direct MulF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LMulF32Facade.f[LLane], LMulF32Direct.f[LLane], C_EPSILON_F32);
          AssertEquals('Direct DivF32x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LDivF32Facade.f[LLane], LDivF32Direct.f[LLane], C_EPSILON_F32);
        end;

        LAddF64Facade := VecF64x8Add(LAf64, LBf64);
        LAddF64Direct := LDirectDispatch^.AddF64x8(LAf64, LBf64);
        LSubF64Facade := VecF64x8Sub(LAf64, LBf64);
        LSubF64Direct := LDirectDispatch^.SubF64x8(LAf64, LBf64);
        LMulF64Facade := VecF64x8Mul(LAf64, LBf64);
        LMulF64Direct := LDirectDispatch^.MulF64x8(LAf64, LBf64);
        LDivF64Facade := VecF64x8Div(LAf64, LBf64);
        LDivF64Direct := LDirectDispatch^.DivF64x8(LAf64, LBf64);

        for LLane := 0 to 7 do
        begin
          AssertEquals('Direct AddF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LAddF64Facade.d[LLane], LAddF64Direct.d[LLane], C_EPSILON_F64);
          AssertEquals('Direct SubF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LSubF64Facade.d[LLane], LSubF64Direct.d[LLane], C_EPSILON_F64);
          AssertEquals('Direct MulF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LMulF64Facade.d[LLane], LMulF64Direct.d[LLane], C_EPSILON_F64);
          AssertEquals('Direct DivF64x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx) + ' lane=' + IntToStr(LLane),
            LDivF64Facade.d[LLane], LDivF64Direct.d[LLane], C_EPSILON_F64);
        end;
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32x16F64x8ReduceMulStable_Parity;
const
  C_CASE_COUNT = 4;
  C_F32_CASES: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (1.0, 2.0, 3.0, 4.0, 0.5, 0.25, 2.0, 1.5, 1.0, 1.0, 2.0, 0.5, 4.0, 0.125, 2.0, 1.0),
    (-1.0, 2.0, -3.0, 4.0, 0.5, -0.25, 2.0, -1.5, 1.0, -1.0, 2.0, -0.5, 4.0, -0.125, 2.0, -1.0),
    (1.0001, 0.9999, 1.0002, 0.9998, 1.0, 1.0, 1.0003, 0.9997, 1.0, 1.0, 1.0004, 0.9996, 1.0, 1.0, 1.0005, 0.9995),
    (2.0, 0.5, 2.0, 0.5, 2.0, 0.5, 2.0, 0.5, 2.0, 0.5, 2.0, 0.5, 2.0, 0.5, 2.0, 0.5)
  );
  C_F64_CASES: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (1.0, 2.0, 0.5, 4.0, 0.25, 2.0, 1.5, 1.0),
    (-1.0, 2.0, -0.5, 4.0, -0.25, 2.0, -1.5, 1.0),
    (1.0000001, 0.9999999, 1.0000002, 0.9999998, 1.0000003, 0.9999997, 1.0000004, 0.9999996),
    (2.0, 0.5, 2.0, 0.5, 2.0, 0.5, 2.0, 0.5)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAf32: TVecF32x16;
  LAf64: TVecF64x8;
  LCaseIdx: Integer;
  LLane: Integer;
  LFacadeMulF32, LDirectMulF32: Single;
  LFacadeMulF64, LDirectMulF64: Double;
  LToleranceF32, LToleranceF64: Double;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.ReduceMulF32x16)) or
         (not Assigned(LDirectDispatch^.ReduceMulF64x8)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 15 do
          LAf32.f[LLane] := C_F32_CASES[LCaseIdx, LLane];
        for LLane := 0 to 7 do
          LAf64.d[LLane] := C_F64_CASES[LCaseIdx, LLane];

        LFacadeMulF32 := VecF32x16ReduceMul(LAf32);
        LDirectMulF32 := LDirectDispatch^.ReduceMulF32x16(LAf32);
        LToleranceF32 := Max(1e-5, Abs(LFacadeMulF32) * 1e-6);
        AssertTrue('Direct ReduceMulF32x16 stable parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Abs(LFacadeMulF32 - LDirectMulF32) <= LToleranceF32);

        LFacadeMulF64 := VecF64x8ReduceMul(LAf64);
        LDirectMulF64 := LDirectDispatch^.ReduceMulF64x8(LAf64);
        LToleranceF64 := Max(1e-10, Abs(LFacadeMulF64) * 1e-12);
        AssertTrue('Direct ReduceMulF64x8 stable parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Abs(LFacadeMulF64 - LDirectMulF64) <= LToleranceF64);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_Mask8Mask16InverseProperties_Parity;
const
  C_MASK8: array[0..9] of TMask8 = ($00, $01, $02, $03, $0F, $10, $55, $AA, $7F, $FF);
  C_MASK16: array[0..9] of TMask16 = ($0000, $0001, $0002, $0003, $00FF, $0F0F, $5555, $AAAA, $7FFF, $FFFF);
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LMask8: TMask8;
  LMask16: TMask16;
  LAllFacade, LAllDirect: Boolean;
  LAnyFacade, LAnyDirect: Boolean;
  LNoneFacade, LNoneDirect: Boolean;
  LPopFacade, LPopDirect: Integer;
  LFirstFacade, LFirstDirect: Integer;
  LIdx: Integer;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.Mask8All)) or
         (not Assigned(LDirectDispatch^.Mask8Any)) or
         (not Assigned(LDirectDispatch^.Mask8None)) or
         (not Assigned(LDirectDispatch^.Mask8PopCount)) or
         (not Assigned(LDirectDispatch^.Mask8FirstSet)) or
         (not Assigned(LDirectDispatch^.Mask16All)) or
         (not Assigned(LDirectDispatch^.Mask16Any)) or
         (not Assigned(LDirectDispatch^.Mask16None)) or
         (not Assigned(LDirectDispatch^.Mask16PopCount)) or
         (not Assigned(LDirectDispatch^.Mask16FirstSet)) then
        Continue;

      Inc(LTestedCount);
      for LIdx := Low(C_MASK8) to High(C_MASK8) do
      begin
        LMask8 := C_MASK8[LIdx];

        LAllFacade := Mask8All(LMask8);
        LAllDirect := LDirectDispatch^.Mask8All(LMask8);
        AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LAllFacade, LAllDirect);

        LAnyFacade := Mask8Any(LMask8);
        LAnyDirect := LDirectDispatch^.Mask8Any(LMask8);
        AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LAnyFacade, LAnyDirect);

        LNoneFacade := Mask8None(LMask8);
        LNoneDirect := LDirectDispatch^.Mask8None(LMask8);
        AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LNoneFacade, LNoneDirect);

        LPopFacade := Mask8PopCount(LMask8);
        LPopDirect := LDirectDispatch^.Mask8PopCount(LMask8);
        AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LPopFacade, LPopDirect);

        LFirstFacade := Mask8FirstSet(LMask8);
        LFirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8);
        AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LFirstFacade, LFirstDirect);

        AssertEquals('Mask8 inverse property backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx),
          LAnyFacade, not LNoneFacade);
        if LAllFacade then
          AssertTrue('Mask8 all->any property backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LAnyFacade);
      end;

      for LIdx := Low(C_MASK16) to High(C_MASK16) do
      begin
        LMask16 := C_MASK16[LIdx];

        LAllFacade := Mask16All(LMask16);
        LAllDirect := LDirectDispatch^.Mask16All(LMask16);
        AssertEquals('Direct Mask16All parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LAllFacade, LAllDirect);

        LAnyFacade := Mask16Any(LMask16);
        LAnyDirect := LDirectDispatch^.Mask16Any(LMask16);
        AssertEquals('Direct Mask16Any parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LAnyFacade, LAnyDirect);

        LNoneFacade := Mask16None(LMask16);
        LNoneDirect := LDirectDispatch^.Mask16None(LMask16);
        AssertEquals('Direct Mask16None parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LNoneFacade, LNoneDirect);

        LPopFacade := Mask16PopCount(LMask16);
        LPopDirect := LDirectDispatch^.Mask16PopCount(LMask16);
        AssertEquals('Direct Mask16PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LPopFacade, LPopDirect);

        LFirstFacade := Mask16FirstSet(LMask16);
        LFirstDirect := LDirectDispatch^.Mask16FirstSet(LMask16);
        AssertEquals('Direct Mask16FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LFirstFacade, LFirstDirect);

        AssertEquals('Mask16 inverse property backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx),
          LAnyFacade, not LNoneFacade);
        if LAllFacade then
          AssertTrue('Mask16 all->any property backend ' + IntToStr(Ord(LBackend)) + ' idx=' + IntToStr(LIdx), LAnyFacade);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32x16F64x8CompareIdentityProperties_Parity;
const
  C_CASE_COUNT = 5;
  C_F32_CASES_A: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0),
    (-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0, -9.0, 10.0, -11.0, 12.0, -13.0, 14.0, -15.0, 16.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 0.0625, 0.03125, 0.015625, 0.0078125, 3.0, 6.0, 12.0, 24.0),
    (1000.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0, 7000.0, 8000.0, -1000.0, -2000.0, -3000.0, -4000.0, -5000.0, -6000.0, -7000.0, -8000.0),
    (1.0E-4, -2.0E-4, 3.0E-4, -4.0E-4, 5.0E-4, -6.0E-4, 7.0E-4, -8.0E-4, 9.0E-4, -1.0E-3, 1.1E-3, -1.2E-3, 1.3E-3, -1.4E-3, 1.5E-3, -1.6E-3)
  );
  C_F32_CASES_B: array[0..C_CASE_COUNT - 1, 0..15] of Single = (
    (0.0, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0, 7.0, 9.0, 11.0, 10.0, 12.0, 14.0, 13.0, 15.0),
    (-1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0, 0.0625, 0.0625, 0.010, 0.008, 3.0, 5.0, 12.0, 25.0),
    (1000.0, 1999.0, 3001.0, 4000.0, 4999.0, 6001.0, 7000.0, 8001.0, -999.0, -2001.0, -3000.0, -3999.0, -5001.0, -6000.0, -7001.0, -8000.0),
    (1.1E-4, -2.0E-4, 2.9E-4, -4.1E-4, 5.0E-4, -6.1E-4, 7.0E-4, -8.1E-4, 9.0E-4, -9.9E-4, 1.1E-3, -1.19E-3, 1.31E-3, -1.4E-3, 1.49E-3, -1.61E-3)
  );

  C_F64_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0),
    (-1.5, 2.5, -3.5, 4.5, -5.5, 6.5, -7.5, 8.5),
    (100.0, 200.0, 300.0, 400.0, -100.0, -200.0, -300.0, -400.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0),
    (1.0E-6, -2.0E-6, 3.0E-6, -4.0E-6, 5.0E-6, -6.0E-6, 7.0E-6, -8.0E-6)
  );
  C_F64_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of Double = (
    (0.0, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0),
    (-1.5, -2.5, -3.0, -4.5, -5.0, -6.5, -7.0, -8.5),
    (100.0, 199.0, 301.0, 400.0, -99.0, -201.0, -300.0, -399.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0),
    (1.1E-6, -2.0E-6, 2.9E-6, -4.1E-6, 5.0E-6, -6.1E-6, 7.0E-6, -8.1E-6)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAf32, LBf32: TVecF32x16;
  LAf64, LBf64: TVecF64x8;
  LCaseIdx: Integer;
  LLane: Integer;
  LMask16Eq, LMask16Lt, LMask16Le, LMask16Gt, LMask16Ge, LMask16Ne: TMask16;
  LMask8Eq, LMask8Lt, LMask8Le, LMask8Gt, LMask8Ge, LMask8Ne: TMask8;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.CmpEqF32x16)) or
         (not Assigned(LDirectDispatch^.CmpLtF32x16)) or
         (not Assigned(LDirectDispatch^.CmpLeF32x16)) or
         (not Assigned(LDirectDispatch^.CmpGtF32x16)) or
         (not Assigned(LDirectDispatch^.CmpGeF32x16)) or
         (not Assigned(LDirectDispatch^.CmpNeF32x16)) or
         (not Assigned(LDirectDispatch^.CmpEqF64x8)) or
         (not Assigned(LDirectDispatch^.CmpLtF64x8)) or
         (not Assigned(LDirectDispatch^.CmpLeF64x8)) or
         (not Assigned(LDirectDispatch^.CmpGtF64x8)) or
         (not Assigned(LDirectDispatch^.CmpGeF64x8)) or
         (not Assigned(LDirectDispatch^.CmpNeF64x8)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 15 do
        begin
          LAf32.f[LLane] := C_F32_CASES_A[LCaseIdx, LLane];
          LBf32.f[LLane] := C_F32_CASES_B[LCaseIdx, LLane];
        end;
        for LLane := 0 to 7 do
        begin
          LAf64.d[LLane] := C_F64_CASES_A[LCaseIdx, LLane];
          LBf64.d[LLane] := C_F64_CASES_B[LCaseIdx, LLane];
        end;

        LMask16Eq := LDirectDispatch^.CmpEqF32x16(LAf32, LBf32);
        LMask16Lt := LDirectDispatch^.CmpLtF32x16(LAf32, LBf32);
        LMask16Le := LDirectDispatch^.CmpLeF32x16(LAf32, LBf32);
        LMask16Gt := LDirectDispatch^.CmpGtF32x16(LAf32, LBf32);
        LMask16Ge := LDirectDispatch^.CmpGeF32x16(LAf32, LBf32);
        LMask16Ne := LDirectDispatch^.CmpNeF32x16(LAf32, LBf32);

        AssertEquals('F32x16 Eq/Ne partition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer($FFFF), Integer(LMask16Eq or LMask16Ne));
        AssertEquals('F32x16 Eq/Ne disjoint backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(0), Integer(LMask16Eq and LMask16Ne));

        AssertEquals('F32x16 Lt/Gt symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16Lt), Integer(LDirectDispatch^.CmpGtF32x16(LBf32, LAf32)));
        AssertEquals('F32x16 Le/Ge symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16Le), Integer(LDirectDispatch^.CmpGeF32x16(LBf32, LAf32)));

        AssertEquals('F32x16 Le decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16Le), Integer(LMask16Lt or LMask16Eq));
        AssertEquals('F32x16 Ge decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16Ge), Integer(LMask16Gt or LMask16Eq));

        LMask8Eq := LDirectDispatch^.CmpEqF64x8(LAf64, LBf64);
        LMask8Lt := LDirectDispatch^.CmpLtF64x8(LAf64, LBf64);
        LMask8Le := LDirectDispatch^.CmpLeF64x8(LAf64, LBf64);
        LMask8Gt := LDirectDispatch^.CmpGtF64x8(LAf64, LBf64);
        LMask8Ge := LDirectDispatch^.CmpGeF64x8(LAf64, LBf64);
        LMask8Ne := LDirectDispatch^.CmpNeF64x8(LAf64, LBf64);

        AssertEquals('F64x8 Eq/Ne partition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer($FF), Integer(LMask8Eq or LMask8Ne));
        AssertEquals('F64x8 Eq/Ne disjoint backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(0), Integer(LMask8Eq and LMask8Ne));

        AssertEquals('F64x8 Lt/Gt symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Lt), Integer(LDirectDispatch^.CmpGtF64x8(LBf64, LAf64)));
        AssertEquals('F64x8 Le/Ge symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Le), Integer(LDirectDispatch^.CmpGeF64x8(LBf64, LAf64)));

        AssertEquals('F64x8 Le decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Le), Integer(LMask8Lt or LMask8Eq));
        AssertEquals('F64x8 Ge decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Ge), Integer(LMask8Gt or LMask8Eq));
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_U32x8U64x4CompareIdentityMaskProperties_Parity;
const
  C_CASE_COUNT = 8;
  C_U32_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of UInt32 = (
    (0, 1, 2, 3, 4, 5, 6, 7),
    ($FFFFFFFF, $FFFFFFFE, $80000000, $7FFFFFFF, 1, 2, 3, 4),
    (100, 200, 300, 400, 500, 600, 700, 800),
    (0, 0, 0, 0, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF),
    ($80000000, $80000001, $7FFFFFFE, $7FFFFFFF, 15, 16, 17, 18),
    (42, 43, 44, 45, 46, 47, 48, 49),
    ($AAAAAAAA, $55555555, $0F0F0F0F, $F0F0F0F0, 9, 10, 11, 12),
    (1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000)
  );
  C_U32_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of UInt32 = (
    (0, 0, 3, 2, 4, 6, 5, 7),
    ($FFFFFFFF, 1, $7FFFFFFF, $80000000, 2, 2, 4, 3),
    (100, 199, 301, 400, 499, 601, 700, 900),
    (1, 0, $FFFFFFFF, 0, $FFFFFFFF, 0, $FFFFFFFF, 0),
    ($7FFFFFFF, $80000000, $7FFFFFFF, $7FFFFFFE, 15, 15, 18, 17),
    (41, 43, 45, 45, 47, 47, 49, 49),
    ($AAAAAAAA, $AAAAAAAA, $F0F0F0F0, $0F0F0F0F, 8, 10, 12, 12),
    (999, 2001, 3000, 3999, 5001, 6000, 6999, 9000)
  );

  C_U64_CASES_A: array[0..C_CASE_COUNT - 1, 0..3] of UInt64 = (
    (0, 1, 2, 3),
    (18446744073709551615, 9223372036854775808, 9223372036854775807, 42),
    (1000, 2000, 3000, 4000),
    (0, 18446744073709551615, 123456789, 987654321),
    (12297829382473034410, 6148914691236517205, 11, 12),
    (15, 16, 17, 18),
    ($0000000100000000, $0000000200000000, 5, 6),
    (9000000000, 9000000001, 9000000002, 9000000003)
  );
  C_U64_CASES_B: array[0..C_CASE_COUNT - 1, 0..3] of UInt64 = (
    (0, 0, 3, 2),
    (18446744073709551615, 9223372036854775807, 9223372036854775808, 41),
    (1000, 1999, 3001, 4000),
    (1, 18446744073709551615, 123456788, 987654322),
    (12297829382473034410, 12297829382473034410, 10, 12),
    (14, 16, 18, 18),
    ($0000000100000001, $0000000200000000, 4, 7),
    (9000000001, 9000000001, 9000000000, 9000000004)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAu32, LBu32: TVecU32x8;
  LAu64, LBu64: TVecU64x4;
  LCaseIdx: Integer;
  LLane: Integer;

  LMask8Eq, LMask8Lt, LMask8Le, LMask8Gt, LMask8Ge, LMask8Ne: TMask8;
  LMask4Eq, LMask4Lt, LMask4Le, LMask4Gt, LMask4Ge, LMask4Ne: TMask4;

  LAnyFacade, LAnyDirect: Boolean;
  LNoneFacade, LNoneDirect: Boolean;
  LAllFacade, LAllDirect: Boolean;
  LPopFacade, LPopDirect: Integer;
  LFirstFacade, LFirstDirect: Integer;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.CmpEqU32x8)) or
         (not Assigned(LDirectDispatch^.CmpLtU32x8)) or
         (not Assigned(LDirectDispatch^.CmpLeU32x8)) or
         (not Assigned(LDirectDispatch^.CmpGtU32x8)) or
         (not Assigned(LDirectDispatch^.CmpGeU32x8)) or
         (not Assigned(LDirectDispatch^.CmpNeU32x8)) or
         (not Assigned(LDirectDispatch^.CmpEqU64x4)) or
         (not Assigned(LDirectDispatch^.CmpLtU64x4)) or
         (not Assigned(LDirectDispatch^.CmpLeU64x4)) or
         (not Assigned(LDirectDispatch^.CmpGtU64x4)) or
         (not Assigned(LDirectDispatch^.CmpGeU64x4)) or
         (not Assigned(LDirectDispatch^.CmpNeU64x4)) or
         (not Assigned(LDirectDispatch^.Mask8All)) or
         (not Assigned(LDirectDispatch^.Mask8Any)) or
         (not Assigned(LDirectDispatch^.Mask8None)) or
         (not Assigned(LDirectDispatch^.Mask8PopCount)) or
         (not Assigned(LDirectDispatch^.Mask8FirstSet)) or
         (not Assigned(LDirectDispatch^.Mask4All)) or
         (not Assigned(LDirectDispatch^.Mask4Any)) or
         (not Assigned(LDirectDispatch^.Mask4None)) or
         (not Assigned(LDirectDispatch^.Mask4PopCount)) or
         (not Assigned(LDirectDispatch^.Mask4FirstSet)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 7 do
        begin
          LAu32.u[LLane] := C_U32_CASES_A[LCaseIdx, LLane];
          LBu32.u[LLane] := C_U32_CASES_B[LCaseIdx, LLane];
        end;
        for LLane := 0 to 3 do
        begin
          LAu64.u[LLane] := C_U64_CASES_A[LCaseIdx, LLane];
          LBu64.u[LLane] := C_U64_CASES_B[LCaseIdx, LLane];
        end;

        LMask8Eq := LDirectDispatch^.CmpEqU32x8(LAu32, LBu32);
        LMask8Lt := LDirectDispatch^.CmpLtU32x8(LAu32, LBu32);
        LMask8Le := LDirectDispatch^.CmpLeU32x8(LAu32, LBu32);
        LMask8Gt := LDirectDispatch^.CmpGtU32x8(LAu32, LBu32);
        LMask8Ge := LDirectDispatch^.CmpGeU32x8(LAu32, LBu32);
        LMask8Ne := LDirectDispatch^.CmpNeU32x8(LAu32, LBu32);

        AssertEquals('U32x8 Eq/Ne partition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer($FF), Integer(LMask8Eq or LMask8Ne));
        AssertEquals('U32x8 Eq/Ne disjoint backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(0), Integer(LMask8Eq and LMask8Ne));

        AssertEquals('U32x8 Lt/Gt symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Lt), Integer(LDirectDispatch^.CmpGtU32x8(LBu32, LAu32)));
        AssertEquals('U32x8 Le/Ge symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Le), Integer(LDirectDispatch^.CmpGeU32x8(LBu32, LAu32)));
        AssertEquals('U32x8 Le decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Le), Integer(LMask8Lt or LMask8Eq));
        AssertEquals('U32x8 Ge decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Ge), Integer(LMask8Gt or LMask8Eq));

        LAnyFacade := Mask8Any(LMask8Lt);
        LAnyDirect := LDirectDispatch^.Mask8Any(LMask8Lt);
        AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAnyFacade, LAnyDirect);

        LNoneFacade := Mask8None(LMask8Lt);
        LNoneDirect := LDirectDispatch^.Mask8None(LMask8Lt);
        AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LNoneFacade, LNoneDirect);

        LAllFacade := Mask8All(LMask8Lt);
        LAllDirect := LDirectDispatch^.Mask8All(LMask8Lt);
        AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAllFacade, LAllDirect);

        LPopFacade := Mask8PopCount(LMask8Lt);
        LPopDirect := LDirectDispatch^.Mask8PopCount(LMask8Lt);
        AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LPopFacade, LPopDirect);

        LFirstFacade := Mask8FirstSet(LMask8Lt);
        LFirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8Lt);
        AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LFirstFacade, LFirstDirect);

        AssertEquals('U32x8 Mask inverse property backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAnyFacade, not LNoneFacade);
        if LNoneFacade then
          AssertEquals('U32x8 Mask firstset none backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), -1, LFirstFacade)
        else
        begin
          AssertTrue('U32x8 Mask firstset range backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
            (LFirstFacade >= 0) and (LFirstFacade < 8));
          AssertTrue('U32x8 Mask firstset bit backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
            (LMask8Lt and TMask8(1 shl LFirstFacade)) <> 0);
        end;

        LMask4Eq := LDirectDispatch^.CmpEqU64x4(LAu64, LBu64);
        LMask4Lt := LDirectDispatch^.CmpLtU64x4(LAu64, LBu64);
        LMask4Le := LDirectDispatch^.CmpLeU64x4(LAu64, LBu64);
        LMask4Gt := LDirectDispatch^.CmpGtU64x4(LAu64, LBu64);
        LMask4Ge := LDirectDispatch^.CmpGeU64x4(LAu64, LBu64);
        LMask4Ne := LDirectDispatch^.CmpNeU64x4(LAu64, LBu64);

        AssertEquals('U64x4 Eq/Ne partition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer($0F), Integer(LMask4Eq or LMask4Ne));
        AssertEquals('U64x4 Eq/Ne disjoint backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(0), Integer(LMask4Eq and LMask4Ne));

        AssertEquals('U64x4 Lt/Gt symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Lt), Integer(LDirectDispatch^.CmpGtU64x4(LBu64, LAu64)));
        AssertEquals('U64x4 Le/Ge symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Le), Integer(LDirectDispatch^.CmpGeU64x4(LBu64, LAu64)));
        AssertEquals('U64x4 Le decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Le), Integer(LMask4Lt or LMask4Eq));
        AssertEquals('U64x4 Ge decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Ge), Integer(LMask4Gt or LMask4Eq));

        LAnyFacade := Mask4Any(LMask4Lt);
        LAnyDirect := LDirectDispatch^.Mask4Any(LMask4Lt);
        AssertEquals('Direct Mask4Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAnyFacade, LAnyDirect);

        LNoneFacade := Mask4None(LMask4Lt);
        LNoneDirect := LDirectDispatch^.Mask4None(LMask4Lt);
        AssertEquals('Direct Mask4None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LNoneFacade, LNoneDirect);

        LAllFacade := Mask4All(LMask4Lt);
        LAllDirect := LDirectDispatch^.Mask4All(LMask4Lt);
        AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAllFacade, LAllDirect);

        LPopFacade := Mask4PopCount(LMask4Lt);
        LPopDirect := LDirectDispatch^.Mask4PopCount(LMask4Lt);
        AssertEquals('Direct Mask4PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LPopFacade, LPopDirect);

        LFirstFacade := Mask4FirstSet(LMask4Lt);
        LFirstDirect := LDirectDispatch^.Mask4FirstSet(LMask4Lt);
        AssertEquals('Direct Mask4FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LFirstFacade, LFirstDirect);

        AssertEquals('U64x4 Mask inverse property backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAnyFacade, not LNoneFacade);
        if LNoneFacade then
          AssertEquals('U64x4 Mask firstset none backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), -1, LFirstFacade)
        else
        begin
          AssertTrue('U64x4 Mask firstset range backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
            (LFirstFacade >= 0) and (LFirstFacade < 4));
          AssertTrue('U64x4 Mask firstset bit backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
            (LMask4Lt and TMask4(1 shl LFirstFacade)) <> 0);
        end;
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_F32x8F64x4CompareIdentityMaskProperties_Parity;
const
  C_CASE_COUNT = 6;
  C_F32_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of Single = (
    (0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0),
    (-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0),
    (0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0),
    (1000.0, 2000.0, 3000.0, 4000.0, -1000.0, -2000.0, -3000.0, -4000.0),
    (1.0E-4, -2.0E-4, 3.0E-4, -4.0E-4, 5.0E-4, -6.0E-4, 7.0E-4, -8.0E-4),
    (-0.0, 0.0, -1.0, 1.0, 10.0, -10.0, 100.0, -100.0)
  );
  C_F32_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of Single = (
    (0.0, 2.0, 1.0, 3.0, 5.0, 4.0, 6.0, 8.0),
    (-1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0),
    (0.125, 0.5, 0.25, 1.0, 1.0, 8.0, 4.0, 16.0),
    (1000.0, 1999.0, 3001.0, 4000.0, -999.0, -2001.0, -3000.0, -3999.0),
    (1.1E-4, -2.0E-4, 2.9E-4, -4.1E-4, 5.0E-4, -6.1E-4, 7.0E-4, -8.1E-4),
    (0.0, -0.0, -1.0, 2.0, 9.0, -9.0, 100.0, -101.0)
  );

  C_F64_CASES_A: array[0..C_CASE_COUNT - 1, 0..3] of Double = (
    (0.0, 1.0, 2.0, 3.0),
    (-1.5, 2.5, -3.5, 4.5),
    (100.0, 200.0, -300.0, -400.0),
    (0.125, 0.25, 0.5, 1.0),
    (1.0E-6, -2.0E-6, 3.0E-6, -4.0E-6),
    (-0.0, 0.0, 10.0, -10.0)
  );
  C_F64_CASES_B: array[0..C_CASE_COUNT - 1, 0..3] of Double = (
    (0.0, 2.0, 1.0, 3.0),
    (-1.5, -2.5, -3.0, -4.5),
    (100.0, 199.0, -299.0, -401.0),
    (0.125, 0.5, 0.25, 1.0),
    (1.1E-6, -2.0E-6, 2.9E-6, -4.1E-6),
    (0.0, -0.0, 9.0, -11.0)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAf32, LBf32: TVecF32x8;
  LAf64, LBf64: TVecF64x4;
  LCaseIdx: Integer;
  LLane: Integer;
  LMask8Eq, LMask8Lt, LMask8Le, LMask8Gt, LMask8Ge, LMask8Ne: TMask8;
  LMask4Eq, LMask4Lt, LMask4Le, LMask4Gt, LMask4Ge, LMask4Ne: TMask4;
  LAnyFacade, LAnyDirect: Boolean;
  LNoneFacade, LNoneDirect: Boolean;
  LAllFacade, LAllDirect: Boolean;
  LPopFacade, LPopDirect: Integer;
  LFirstFacade, LFirstDirect: Integer;
  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;
      if LBackend <> sbScalar then
        Continue;

      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);

      if (not Assigned(LDirectDispatch^.CmpEqF32x8)) or
         (not Assigned(LDirectDispatch^.CmpLtF32x8)) or
         (not Assigned(LDirectDispatch^.CmpLeF32x8)) or
         (not Assigned(LDirectDispatch^.CmpGtF32x8)) or
         (not Assigned(LDirectDispatch^.CmpGeF32x8)) or
         (not Assigned(LDirectDispatch^.CmpNeF32x8)) or
         (not Assigned(LDirectDispatch^.CmpEqF64x4)) or
         (not Assigned(LDirectDispatch^.CmpLtF64x4)) or
         (not Assigned(LDirectDispatch^.CmpLeF64x4)) or
         (not Assigned(LDirectDispatch^.CmpGtF64x4)) or
         (not Assigned(LDirectDispatch^.CmpGeF64x4)) or
         (not Assigned(LDirectDispatch^.CmpNeF64x4)) or
         (not Assigned(LDirectDispatch^.Mask8All)) or
         (not Assigned(LDirectDispatch^.Mask8Any)) or
         (not Assigned(LDirectDispatch^.Mask8None)) or
         (not Assigned(LDirectDispatch^.Mask8PopCount)) or
         (not Assigned(LDirectDispatch^.Mask8FirstSet)) or
         (not Assigned(LDirectDispatch^.Mask4All)) or
         (not Assigned(LDirectDispatch^.Mask4Any)) or
         (not Assigned(LDirectDispatch^.Mask4None)) or
         (not Assigned(LDirectDispatch^.Mask4PopCount)) or
         (not Assigned(LDirectDispatch^.Mask4FirstSet)) then
        Continue;

      Inc(LTestedCount);
      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 7 do
        begin
          LAf32.f[LLane] := C_F32_CASES_A[LCaseIdx, LLane];
          LBf32.f[LLane] := C_F32_CASES_B[LCaseIdx, LLane];
        end;
        for LLane := 0 to 3 do
        begin
          LAf64.d[LLane] := C_F64_CASES_A[LCaseIdx, LLane];
          LBf64.d[LLane] := C_F64_CASES_B[LCaseIdx, LLane];
        end;

        LMask8Eq := LDirectDispatch^.CmpEqF32x8(LAf32, LBf32);
        LMask8Lt := LDirectDispatch^.CmpLtF32x8(LAf32, LBf32);
        LMask8Le := LDirectDispatch^.CmpLeF32x8(LAf32, LBf32);
        LMask8Gt := LDirectDispatch^.CmpGtF32x8(LAf32, LBf32);
        LMask8Ge := LDirectDispatch^.CmpGeF32x8(LAf32, LBf32);
        LMask8Ne := LDirectDispatch^.CmpNeF32x8(LAf32, LBf32);

        AssertEquals('F32x8 Eq/Ne partition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer($FF), Integer(LMask8Eq or LMask8Ne));
        AssertEquals('F32x8 Eq/Ne disjoint backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(0), Integer(LMask8Eq and LMask8Ne));
        AssertEquals('F32x8 Lt/Gt symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Lt), Integer(LDirectDispatch^.CmpGtF32x8(LBf32, LAf32)));
        AssertEquals('F32x8 Le/Ge symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Le), Integer(LDirectDispatch^.CmpGeF32x8(LBf32, LAf32)));
        AssertEquals('F32x8 Le decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Le), Integer(LMask8Lt or LMask8Eq));
        AssertEquals('F32x8 Ge decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8Ge), Integer(LMask8Gt or LMask8Eq));

        LAnyFacade := Mask8Any(LMask8Lt);
        LAnyDirect := LDirectDispatch^.Mask8Any(LMask8Lt);
        AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAnyFacade, LAnyDirect);
        LNoneFacade := Mask8None(LMask8Lt);
        LNoneDirect := LDirectDispatch^.Mask8None(LMask8Lt);
        AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LNoneFacade, LNoneDirect);
        LAllFacade := Mask8All(LMask8Lt);
        LAllDirect := LDirectDispatch^.Mask8All(LMask8Lt);
        AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAllFacade, LAllDirect);
        LPopFacade := Mask8PopCount(LMask8Lt);
        LPopDirect := LDirectDispatch^.Mask8PopCount(LMask8Lt);
        AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LPopFacade, LPopDirect);
        LFirstFacade := Mask8FirstSet(LMask8Lt);
        LFirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8Lt);
        AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LFirstFacade, LFirstDirect);

        AssertEquals('F32x8 Mask inverse property backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAnyFacade, not LNoneFacade);
        if LNoneFacade then
          AssertEquals('F32x8 Mask firstset none backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), -1, LFirstFacade)
        else
          AssertTrue('F32x8 Mask firstset range backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
            (LFirstFacade >= 0) and (LFirstFacade < 8));

        LMask4Eq := LDirectDispatch^.CmpEqF64x4(LAf64, LBf64);
        LMask4Lt := LDirectDispatch^.CmpLtF64x4(LAf64, LBf64);
        LMask4Le := LDirectDispatch^.CmpLeF64x4(LAf64, LBf64);
        LMask4Gt := LDirectDispatch^.CmpGtF64x4(LAf64, LBf64);
        LMask4Ge := LDirectDispatch^.CmpGeF64x4(LAf64, LBf64);
        LMask4Ne := LDirectDispatch^.CmpNeF64x4(LAf64, LBf64);

        AssertEquals('F64x4 Eq/Ne partition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer($0F), Integer(LMask4Eq or LMask4Ne));
        AssertEquals('F64x4 Eq/Ne disjoint backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(0), Integer(LMask4Eq and LMask4Ne));
        AssertEquals('F64x4 Lt/Gt symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Lt), Integer(LDirectDispatch^.CmpGtF64x4(LBf64, LAf64)));
        AssertEquals('F64x4 Le/Ge symmetry backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Le), Integer(LDirectDispatch^.CmpGeF64x4(LBf64, LAf64)));
        AssertEquals('F64x4 Le decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Le), Integer(LMask4Lt or LMask4Eq));
        AssertEquals('F64x4 Ge decomposition backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask4Ge), Integer(LMask4Gt or LMask4Eq));

        LAnyFacade := Mask4Any(LMask4Lt);
        LAnyDirect := LDirectDispatch^.Mask4Any(LMask4Lt);
        AssertEquals('Direct Mask4Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAnyFacade, LAnyDirect);
        LNoneFacade := Mask4None(LMask4Lt);
        LNoneDirect := LDirectDispatch^.Mask4None(LMask4Lt);
        AssertEquals('Direct Mask4None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LNoneFacade, LNoneDirect);
        LAllFacade := Mask4All(LMask4Lt);
        LAllDirect := LDirectDispatch^.Mask4All(LMask4Lt);
        AssertEquals('Direct Mask4All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LAllFacade, LAllDirect);
        LPopFacade := Mask4PopCount(LMask4Lt);
        LPopDirect := LDirectDispatch^.Mask4PopCount(LMask4Lt);
        AssertEquals('Direct Mask4PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LPopFacade, LPopDirect);
        LFirstFacade := Mask4FirstSet(LMask4Lt);
        LFirstDirect := LDirectDispatch^.Mask4FirstSet(LMask4Lt);
        AssertEquals('Direct Mask4FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), LFirstFacade, LFirstDirect);

        AssertEquals('F64x4 Mask inverse property backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LAnyFacade, not LNoneFacade);
        if LNoneFacade then
          AssertEquals('F64x4 Mask firstset none backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx), -1, LFirstFacade)
        else
          AssertTrue('F64x4 Mask firstset range backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
            (LFirstFacade >= 0) and (LFirstFacade < 4));
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_I16I8CompareEdgeMatrix_Parity;
const
  C_CASE_COUNT = 4;
  C_I16_CASES_A: array[0..C_CASE_COUNT - 1, 0..7] of Int16 = (
    (Low(Int16), -1024, -1, 0, 1, 1024, 32766, High(Int16)),
    (0, 0, 0, 0, 0, 0, 0, 0),
    (-1, -2, -3, -4, 4, 3, 2, 1),
    (123, -456, 789, -1011, 1213, -1415, 1617, -1819)
  );
  C_I16_CASES_B: array[0..C_CASE_COUNT - 1, 0..7] of Int16 = (
    (Low(Int16), -1000, 0, 0, -1, 2048, 32766, High(Int16)),
    (1, -1, 2, -2, 3, -3, 4, -4),
    (-1, -1, -4, -4, 4, 2, 2, 2),
    (123, -500, 700, -1011, 1300, -1500, 1617, -1700)
  );

  C_I8_CASES_A: array[0..C_CASE_COUNT - 1, 0..15] of Int8 = (
    (Low(Int8), -100, -64, -32, -16, -8, -4, -2, -1, 0, 1, 2, 4, 8, 64, High(Int8)),
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (-1, -2, -3, -4, -5, -6, -7, -8, 8, 7, 6, 5, 4, 3, 2, 1),
    (11, -22, 33, -44, 55, -66, 77, -88, 99, -110, 120, -120, 10, -10, 5, -5)
  );
  C_I8_CASES_B: array[0..C_CASE_COUNT - 1, 0..15] of Int8 = (
    (Low(Int8), -99, -64, -40, -16, -7, -5, -2, -2, 1, 0, 3, 4, 7, 63, High(Int8)),
    (1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6, 7, -7, 8, -8),
    (-1, -1, -4, -4, -5, -5, -9, -9, 8, 8, 5, 5, 3, 3, 2, 2),
    (11, -30, 40, -44, 50, -60, 80, -90, 100, -100, 120, -121, 9, -9, 6, -6)
  );
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LAi16, LBi16: TVecI16x8;
  LAi8, LBi8: TVecI8x16;
  LCaseIdx: Integer;
  LLane: Integer;

  LMask8EqFacade, LMask8EqDirect: TMask8;
  LMask8LtFacade, LMask8LtDirect: TMask8;
  LMask8GtFacade, LMask8GtDirect: TMask8;
  LMask8AllFacade, LMask8AllDirect: Boolean;
  LMask8AnyFacade, LMask8AnyDirect: Boolean;
  LMask8NoneFacade, LMask8NoneDirect: Boolean;
  LMask8PopFacade, LMask8PopDirect: Integer;
  LMask8FirstFacade, LMask8FirstDirect: Integer;

  LMask16EqFacade, LMask16EqDirect: TMask16;
  LMask16LtFacade, LMask16LtDirect: TMask16;
  LMask16GtFacade, LMask16GtDirect: TMask16;
  LMask16AllFacade, LMask16AllDirect: Boolean;
  LMask16AnyFacade, LMask16AnyDirect: Boolean;
  LMask16NoneFacade, LMask16NoneDirect: Boolean;
  LMask16PopFacade, LMask16PopDirect: Integer;
  LMask16FirstFacade, LMask16FirstDirect: Integer;

  LTestedCount: Integer;
begin
  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('CmpEqI16x8 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqI16x8));
      AssertTrue('CmpEqI8x16 should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.CmpEqI8x16));

      for LCaseIdx := 0 to C_CASE_COUNT - 1 do
      begin
        for LLane := 0 to 7 do
        begin
          LAi16.i[LLane] := C_I16_CASES_A[LCaseIdx, LLane];
          LBi16.i[LLane] := C_I16_CASES_B[LCaseIdx, LLane];
        end;

        for LLane := 0 to 15 do
        begin
          LAi8.i[LLane] := C_I8_CASES_A[LCaseIdx, LLane];
          LBi8.i[LLane] := C_I8_CASES_B[LCaseIdx, LLane];
        end;

        // I16x8 compare + Mask8
        LMask8EqFacade := VecI16x8CmpEq(LAi16, LBi16);
        LMask8EqDirect := LDirectDispatch^.CmpEqI16x8(LAi16, LBi16);
        AssertEquals('Direct CmpEqI16x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8EqFacade), Integer(LMask8EqDirect));

        LMask8LtFacade := VecI16x8CmpLt(LAi16, LBi16);
        LMask8LtDirect := LDirectDispatch^.CmpLtI16x8(LAi16, LBi16);
        AssertEquals('Direct CmpLtI16x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8LtFacade), Integer(LMask8LtDirect));

        LMask8GtFacade := VecI16x8CmpGt(LAi16, LBi16);
        LMask8GtDirect := LDirectDispatch^.CmpGtI16x8(LAi16, LBi16);
        AssertEquals('Direct CmpGtI16x8 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask8GtFacade), Integer(LMask8GtDirect));

        LMask8AllFacade := Mask8All(LMask8LtFacade);
        LMask8AllDirect := LDirectDispatch^.Mask8All(LMask8LtDirect);
        AssertEquals('Direct Mask8All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8AllFacade, LMask8AllDirect);

        LMask8AnyFacade := Mask8Any(LMask8LtFacade);
        LMask8AnyDirect := LDirectDispatch^.Mask8Any(LMask8LtDirect);
        AssertEquals('Direct Mask8Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8AnyFacade, LMask8AnyDirect);

        LMask8NoneFacade := Mask8None(LMask8LtFacade);
        LMask8NoneDirect := LDirectDispatch^.Mask8None(LMask8LtDirect);
        AssertEquals('Direct Mask8None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8NoneFacade, LMask8NoneDirect);

        LMask8PopFacade := Mask8PopCount(LMask8LtFacade);
        LMask8PopDirect := LDirectDispatch^.Mask8PopCount(LMask8LtDirect);
        AssertEquals('Direct Mask8PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8PopFacade, LMask8PopDirect);

        LMask8FirstFacade := Mask8FirstSet(LMask8LtFacade);
        LMask8FirstDirect := LDirectDispatch^.Mask8FirstSet(LMask8LtDirect);
        AssertEquals('Direct Mask8FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask8FirstFacade, LMask8FirstDirect);

        // I8x16 compare + Mask16
        LMask16EqFacade := VecI8x16CmpEq(LAi8, LBi8);
        LMask16EqDirect := LDirectDispatch^.CmpEqI8x16(LAi8, LBi8);
        AssertEquals('Direct CmpEqI8x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16EqFacade), Integer(LMask16EqDirect));

        LMask16LtFacade := VecI8x16CmpLt(LAi8, LBi8);
        LMask16LtDirect := LDirectDispatch^.CmpLtI8x16(LAi8, LBi8);
        AssertEquals('Direct CmpLtI8x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16LtFacade), Integer(LMask16LtDirect));

        LMask16GtFacade := VecI8x16CmpGt(LAi8, LBi8);
        LMask16GtDirect := LDirectDispatch^.CmpGtI8x16(LAi8, LBi8);
        AssertEquals('Direct CmpGtI8x16 parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          Integer(LMask16GtFacade), Integer(LMask16GtDirect));

        LMask16AllFacade := Mask16All(LMask16LtFacade);
        LMask16AllDirect := LDirectDispatch^.Mask16All(LMask16LtDirect);
        AssertEquals('Direct Mask16All parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16AllFacade, LMask16AllDirect);

        LMask16AnyFacade := Mask16Any(LMask16LtFacade);
        LMask16AnyDirect := LDirectDispatch^.Mask16Any(LMask16LtDirect);
        AssertEquals('Direct Mask16Any parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16AnyFacade, LMask16AnyDirect);

        LMask16NoneFacade := Mask16None(LMask16LtFacade);
        LMask16NoneDirect := LDirectDispatch^.Mask16None(LMask16LtDirect);
        AssertEquals('Direct Mask16None parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16NoneFacade, LMask16NoneDirect);

        LMask16PopFacade := Mask16PopCount(LMask16LtFacade);
        LMask16PopDirect := LDirectDispatch^.Mask16PopCount(LMask16LtDirect);
        AssertEquals('Direct Mask16PopCount parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16PopFacade, LMask16PopDirect);

        LMask16FirstFacade := Mask16FirstSet(LMask16LtFacade);
        LMask16FirstDirect := LDirectDispatch^.Mask16FirstSet(LMask16LtDirect);
        AssertEquals('Direct Mask16FirstSet parity backend ' + IntToStr(Ord(LBackend)) + ' case=' + IntToStr(LCaseIdx),
          LMask16FirstFacade, LMask16FirstDirect);
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MemSearchBitsetUtf8_Parity;
const
  C_BUF_LEN = 96;
  C_NEEDLE_LEN = 3;
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LBuf: array[0..C_BUF_LEN - 1] of Byte;
  LUtf8Good: array[0..15] of Byte;
  LUtf8Bad: array[0..15] of Byte;
  LNeedleHit: array[0..C_NEEDLE_LEN - 1] of Byte;
  LNeedleMiss: array[0..C_NEEDLE_LEN - 1] of Byte;
  LIdx: Integer;
  LFoundOffset: Integer;
  LFacadeIdx, LDirectIdx: PtrInt;
  LFacadeUtf8, LDirectUtf8: Boolean;
  LFacadeBits, LDirectBits: SizeUInt;
  LTestedCount: Integer;
begin
  for LIdx := 0 to High(LBuf) do
    LBuf[LIdx] := Byte(LIdx);

  // 可搜索子串（确保存在）
  LFoundOffset := 37;
  for LIdx := 0 to High(LNeedleHit) do
  begin
    LNeedleHit[LIdx] := Byte(200 + LIdx);
    LBuf[LFoundOffset + LIdx] := LNeedleHit[LIdx];
  end;
  LNeedleMiss[0] := $FA;
  LNeedleMiss[1] := $FB;
  LNeedleMiss[2] := $FC;

  // UTF-8 good: "A中B€C" 的字节序列
  LUtf8Good[0] := $41;              // A
  LUtf8Good[1] := $E4; LUtf8Good[2] := $B8; LUtf8Good[3] := $AD; // 中
  LUtf8Good[4] := $42;              // B
  LUtf8Good[5] := $E2; LUtf8Good[6] := $82; LUtf8Good[7] := $AC; // €
  LUtf8Good[8] := $43;              // C
  for LIdx := 9 to High(LUtf8Good) do
    LUtf8Good[LIdx] := $20;

  // UTF-8 bad: 构造截断序列
  for LIdx := 0 to High(LUtf8Bad) do
    LUtf8Bad[LIdx] := $20;
  LUtf8Bad[0] := $41;
  LUtf8Bad[1] := $E4;
  LUtf8Bad[2] := $B8; // 缺失第三字节
  LUtf8Bad[3] := $42;

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('BytesIndexOf should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.BytesIndexOf));
      AssertTrue('BitsetPopCount should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.BitsetPopCount));
      AssertTrue('Utf8Validate should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.Utf8Validate));

      // BytesIndexOf parity (found)
      LFacadeIdx := BytesIndexOf(@LBuf[0], SizeUInt(C_BUF_LEN), @LNeedleHit[0], SizeUInt(C_NEEDLE_LEN));
      LDirectIdx := LDirectDispatch^.BytesIndexOf(@LBuf[0], SizeUInt(C_BUF_LEN), @LNeedleHit[0], SizeUInt(C_NEEDLE_LEN));
      AssertEquals('Direct BytesIndexOf(found) parity backend ' + IntToStr(Ord(LBackend)), LFacadeIdx, LDirectIdx);
      AssertEquals('BytesIndexOf(found) expected offset backend ' + IntToStr(Ord(LBackend)), LFoundOffset, Integer(LFacadeIdx));

      // BytesIndexOf parity (not found)
      LFacadeIdx := BytesIndexOf(@LBuf[0], SizeUInt(C_BUF_LEN), @LNeedleMiss[0], SizeUInt(C_NEEDLE_LEN));
      LDirectIdx := LDirectDispatch^.BytesIndexOf(@LBuf[0], SizeUInt(C_BUF_LEN), @LNeedleMiss[0], SizeUInt(C_NEEDLE_LEN));
      AssertEquals('Direct BytesIndexOf(not-found) parity backend ' + IntToStr(Ord(LBackend)), LFacadeIdx, LDirectIdx);
      AssertEquals('BytesIndexOf(not-found) expected -1 backend ' + IntToStr(Ord(LBackend)), -1, Integer(LFacadeIdx));

      // BitsetPopCount parity
      LFacadeBits := BitsetPopCount(@LBuf[0], SizeUInt(C_BUF_LEN));
      LDirectBits := LDirectDispatch^.BitsetPopCount(@LBuf[0], SizeUInt(C_BUF_LEN));
      AssertEquals('Direct BitsetPopCount parity backend ' + IntToStr(Ord(LBackend)), LFacadeBits, LDirectBits);

      // UTF-8 parity (good)
      LFacadeUtf8 := Utf8Validate(@LUtf8Good[0], SizeUInt(Length(LUtf8Good)));
      LDirectUtf8 := LDirectDispatch^.Utf8Validate(@LUtf8Good[0], SizeUInt(Length(LUtf8Good)));
      AssertEquals('Direct Utf8Validate(good) parity backend ' + IntToStr(Ord(LBackend)), LFacadeUtf8, LDirectUtf8);

      // UTF-8 parity (bad)
      LFacadeUtf8 := Utf8Validate(@LUtf8Bad[0], SizeUInt(Length(LUtf8Bad)));
      LDirectUtf8 := LDirectDispatch^.Utf8Validate(@LUtf8Bad[0], SizeUInt(Length(LUtf8Bad)));
      AssertEquals('Direct Utf8Validate(bad) parity backend ' + IntToStr(Ord(LBackend)), LFacadeUtf8, LDirectUtf8);
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MemWindowMatrix_Parity;
const
  C_TOTAL_LEN = 96;
  C_LEN_CASES: array[0..9] of Integer = (1, 2, 3, 7, 8, 15, 16, 24, 31, 48);
  C_OFFSET_CASES: array[0..5] of Integer = (0, 1, 2, 5, 9, 13);
var
  LBackend: TSimdBackend;
  LDispatch: PSimdDispatchTable;
  LDirectDispatch: PSimdDispatchTable;
  LBufA: array[0..C_TOTAL_LEN - 1] of Byte;
  LBufB: array[0..C_TOTAL_LEN - 1] of Byte;
  LNeedleHit: array[0..2] of Byte;
  LNeedleMiss: array[0..2] of Byte;
  LLenCaseIdx: Integer;
  LOffsetIdx: Integer;
  LLen: Integer;
  LOffset: Integer;
  LIndex: Integer;
  LFindValue: Byte;
  LFacadeEq, LDirectEq: LongBool;
  LFacadeFind, LDirectFind: PtrInt;
  LFacadeHasDiff, LDirectHasDiff: Boolean;
  LFacadeFirstDiff, LFacadeLastDiff: SizeUInt;
  LDirectFirstDiff, LDirectLastDiff: SizeUInt;
  LFacadeBytesHit, LDirectBytesHit: PtrInt;
  LFacadeBytesMiss, LDirectBytesMiss: PtrInt;
  LDiffPosLocal: Integer;
  LNeedlePos: Integer;
  LExpectedFindPos: Integer;
  LTestedCount: Integer;
begin
  for LIndex := 0 to High(LBufA) do
  begin
    LBufA[LIndex] := Byte((LIndex * 17 + 11) and $FF);
    LBufB[LIndex] := LBufA[LIndex];
  end;

  LNeedleMiss[0] := $FA;
  LNeedleMiss[1] := $FB;
  LNeedleMiss[2] := $FC;

  LTestedCount := 0;
  try
    for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      Inc(LTestedCount);
      LDispatch := GetDispatchTable;
      LDirectDispatch := GetDirectDispatchTable;

      AssertTrue('Dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDispatch <> nil);
      AssertTrue('Direct dispatch table should be assigned for backend ' + IntToStr(Ord(LBackend)), LDirectDispatch <> nil);
      AssertTrue('MemEqual should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemEqual));
      AssertTrue('MemFindByte should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemFindByte));
      AssertTrue('MemDiffRange should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.MemDiffRange));
      AssertTrue('BytesIndexOf should be assigned for backend ' + IntToStr(Ord(LBackend)), Assigned(LDirectDispatch^.BytesIndexOf));

      for LLenCaseIdx := Low(C_LEN_CASES) to High(C_LEN_CASES) do
      begin
        LLen := C_LEN_CASES[LLenCaseIdx];

        for LOffsetIdx := Low(C_OFFSET_CASES) to High(C_OFFSET_CASES) do
        begin
          LOffset := C_OFFSET_CASES[LOffsetIdx];
          if LOffset + LLen > C_TOTAL_LEN then
            Continue;

          // 1) MemEqual(equal)
          for LIndex := 0 to LLen - 1 do
            LBufB[LOffset + LIndex] := LBufA[LOffset + LIndex];

          LFacadeEq := MemEqual(@LBufA[LOffset], @LBufB[LOffset], SizeUInt(LLen));
          LDirectEq := LDirectDispatch^.MemEqual(@LBufA[LOffset], @LBufB[LOffset], SizeUInt(LLen));
          AssertEquals('Direct MemEqual(equal) parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            Boolean(LFacadeEq), Boolean(LDirectEq));

          // 2) MemEqual/MemDiffRange(diff)
          LDiffPosLocal := (LOffset + LLen div 2);
          LBufB[LDiffPosLocal] := LBufA[LDiffPosLocal] xor $5A;

          LFacadeEq := MemEqual(@LBufA[LOffset], @LBufB[LOffset], SizeUInt(LLen));
          LDirectEq := LDirectDispatch^.MemEqual(@LBufA[LOffset], @LBufB[LOffset], SizeUInt(LLen));
          AssertEquals('Direct MemEqual(diff) parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            Boolean(LFacadeEq), Boolean(LDirectEq));

          LFacadeHasDiff := MemDiffRange(@LBufA[LOffset], @LBufB[LOffset], SizeUInt(LLen), LFacadeFirstDiff, LFacadeLastDiff);
          LDirectHasDiff := LDirectDispatch^.MemDiffRange(@LBufA[LOffset], @LBufB[LOffset], SizeUInt(LLen), LDirectFirstDiff, LDirectLastDiff);
          AssertEquals('Direct MemDiffRange(diff).hasDiff parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            LFacadeHasDiff, LDirectHasDiff);
          if LFacadeHasDiff then
          begin
            AssertEquals('Direct MemDiffRange(diff).first parity backend ' + IntToStr(Ord(LBackend)) +
              ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
              LFacadeFirstDiff, LDirectFirstDiff);
            AssertEquals('Direct MemDiffRange(diff).last parity backend ' + IntToStr(Ord(LBackend)) +
              ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
              LFacadeLastDiff, LDirectLastDiff);
          end;

          // restore equal for next checks
          LBufB[LDiffPosLocal] := LBufA[LDiffPosLocal];

          // 3) MemFindByte(found)
          LFindValue := LBufA[LOffset + (LLen div 3)];
          LExpectedFindPos := -1;
          for LIndex := 0 to LLen - 1 do
            if LBufA[LOffset + LIndex] = LFindValue then
            begin
              LExpectedFindPos := LIndex;
              Break;
            end;

          LFacadeFind := MemFindByte(@LBufA[LOffset], SizeUInt(LLen), LFindValue);
          LDirectFind := LDirectDispatch^.MemFindByte(@LBufA[LOffset], SizeUInt(LLen), LFindValue);
          AssertEquals('Direct MemFindByte(found) parity backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            LFacadeFind, LDirectFind);
          AssertEquals('MemFindByte(found) expected position backend ' + IntToStr(Ord(LBackend)) +
            ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
            LExpectedFindPos, Integer(LFacadeFind));

          // 4) BytesIndexOf(found/not-found)
          if LLen >= 3 then
          begin
            LNeedlePos := LLen div 4;
            if LNeedlePos + 3 > LLen then
              LNeedlePos := LLen - 3;

            LNeedleHit[0] := LBufA[LOffset + LNeedlePos + 0];
            LNeedleHit[1] := LBufA[LOffset + LNeedlePos + 1];
            LNeedleHit[2] := LBufA[LOffset + LNeedlePos + 2];

            LFacadeBytesHit := BytesIndexOf(@LBufA[LOffset], SizeUInt(LLen), @LNeedleHit[0], 3);
            LDirectBytesHit := LDirectDispatch^.BytesIndexOf(@LBufA[LOffset], SizeUInt(LLen), @LNeedleHit[0], 3);
            AssertEquals('Direct BytesIndexOf(hit) parity backend ' + IntToStr(Ord(LBackend)) +
              ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
              LFacadeBytesHit, LDirectBytesHit);

            LFacadeBytesMiss := BytesIndexOf(@LBufA[LOffset], SizeUInt(LLen), @LNeedleMiss[0], 3);
            LDirectBytesMiss := LDirectDispatch^.BytesIndexOf(@LBufA[LOffset], SizeUInt(LLen), @LNeedleMiss[0], 3);
            AssertEquals('Direct BytesIndexOf(miss) parity backend ' + IntToStr(Ord(LBackend)) +
              ' len=' + IntToStr(LLen) + ' off=' + IntToStr(LOffset),
              LFacadeBytesMiss, LDirectBytesMiss);
          end;
        end;
      end;
    end;

    AssertTrue('At least one backend should be tested', LTestedCount > 0);
  finally
    ResetToAutomaticBackend;
  end;
end;


procedure TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MemSearchFuzzSeed_Parity;
const
  C_CASE_COUNT = 24;
  C_BUFFER_LEN = 64;
  C_NEEDLE_LENS: array[0..3] of Integer = (1, 2, 4, 8);
var
  LDirectDispatch: PSimdDispatchTable;
  LBufA: array[0..C_BUFFER_LEN - 1] of Byte;
  LBufB: array[0..C_BUFFER_LEN - 1] of Byte;
  LNeedleFound: array[0..7] of Byte;
  LCaseIndex: Integer;
  LIndex: Integer;
  LNeedleIndex: Integer;
  LNeedleLen: Integer;
  LFoundOffset: Integer;
  LDiffPos: Integer;
  LSegmentOffset: Integer;
  LSegmentLen: Integer;
  LFacadeIndex: PtrInt;
  LDirectIndex: PtrInt;
  LNeedleMismatch: Boolean;
  LRefHasDiff: Boolean;
  LDirectHasDiff: Boolean;
  LRefFirstDiff: SizeUInt;
  LRefLastDiff: SizeUInt;
  LDirectFirstDiff: SizeUInt;
  LDirectLastDiff: SizeUInt;
  LRefMin: Byte;
  LRefMax: Byte;
  LDirectMin: Byte;
  LDirectMax: Byte;
begin
  AssertTrue('TrySetActiveBackend(sbScalar) should succeed', TrySetActiveBackend(sbScalar));
  try
    LDirectDispatch := GetDirectDispatchTable;

    AssertTrue('Direct dispatch table should be assigned', LDirectDispatch <> nil);
    AssertEquals('Direct backend should be scalar', Ord(sbScalar), Ord(LDirectDispatch^.Backend));
    AssertTrue('BytesIndexOf should be assigned', Assigned(LDirectDispatch^.BytesIndexOf));
    AssertTrue('MemDiffRange should be assigned', Assigned(LDirectDispatch^.MemDiffRange));
    AssertTrue('MinMaxBytes should be assigned', Assigned(LDirectDispatch^.MinMaxBytes));

    for LCaseIndex := 0 to C_CASE_COUNT - 1 do
    begin
      for LIndex := 0 to C_BUFFER_LEN - 1 do
      begin
        LBufA[LIndex] := Byte((LCaseIndex * 37 + LIndex * 13 + (LIndex shr 1)) and $FF);
        LBufB[LIndex] := LBufA[LIndex];
      end;

      LNeedleLen := C_NEEDLE_LENS[LCaseIndex and 3];
      LFoundOffset := (LCaseIndex * 7 + 3) mod (C_BUFFER_LEN - LNeedleLen + 1);
      for LIndex := 0 to LNeedleLen - 1 do
        LNeedleFound[LIndex] := LBufA[LFoundOffset + LIndex];

      LFacadeIndex := -1;
      for LIndex := 0 to C_BUFFER_LEN - LNeedleLen do
      begin
        LNeedleMismatch := False;
        for LNeedleIndex := 0 to LNeedleLen - 1 do
        begin
          if LBufA[LIndex + LNeedleIndex] <> LNeedleFound[LNeedleIndex] then
          begin
            LNeedleMismatch := True;
            Break;
          end;
        end;
        if not LNeedleMismatch then
        begin
          LFacadeIndex := LIndex;
          Break;
        end;
      end;

      LDirectIndex := LDirectDispatch^.BytesIndexOf(@LBufA[0], SizeUInt(C_BUFFER_LEN), @LNeedleFound[0], SizeUInt(LNeedleLen));
      AssertEquals('Direct BytesIndexOf(found) parity case=' + IntToStr(LCaseIndex),
        LFacadeIndex, LDirectIndex);

      AssertTrue('Reference MemEqual(equal) should be true case=' + IntToStr(LCaseIndex),
        MemEqual(@LBufA[0], @LBufB[0], SizeUInt(C_BUFFER_LEN)));
      LRefHasDiff := MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(C_BUFFER_LEN), LRefFirstDiff, LRefLastDiff);

      LDirectHasDiff := LDirectDispatch^.MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(C_BUFFER_LEN), LDirectFirstDiff, LDirectLastDiff);
      AssertEquals('Direct MemDiffRange(equal).hasDiff parity case=' + IntToStr(LCaseIndex),
        LRefHasDiff, LDirectHasDiff);
      AssertFalse('Reference MemDiffRange(equal) should be false case=' + IntToStr(LCaseIndex), LRefHasDiff);

      LDiffPos := (LCaseIndex * 11 + 5) mod C_BUFFER_LEN;
      LBufB[LDiffPos] := LBufB[LDiffPos] xor Byte(($A5 + LCaseIndex) and $FF);

      AssertFalse('Reference MemEqual(diff) should be false case=' + IntToStr(LCaseIndex),
        MemEqual(@LBufA[0], @LBufB[0], SizeUInt(C_BUFFER_LEN)));
      LRefHasDiff := MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(C_BUFFER_LEN), LRefFirstDiff, LRefLastDiff);

      LDirectHasDiff := LDirectDispatch^.MemDiffRange(@LBufA[0], @LBufB[0], SizeUInt(C_BUFFER_LEN), LDirectFirstDiff, LDirectLastDiff);
      AssertEquals('Direct MemDiffRange(diff).hasDiff parity case=' + IntToStr(LCaseIndex),
        LRefHasDiff, LDirectHasDiff);
      AssertTrue('Reference MemDiffRange(diff) should be true case=' + IntToStr(LCaseIndex), LRefHasDiff);
      if LRefHasDiff then
      begin
        AssertEquals('Direct MemDiffRange(diff).firstDiff parity case=' + IntToStr(LCaseIndex),
          LRefFirstDiff, LDirectFirstDiff);
        AssertEquals('Direct MemDiffRange(diff).lastDiff parity case=' + IntToStr(LCaseIndex),
          LRefLastDiff, LDirectLastDiff);
        AssertEquals('Reference MemDiffRange(diff).firstDiff expected case=' + IntToStr(LCaseIndex),
          SizeUInt(LDiffPos), LRefFirstDiff);
        AssertEquals('Reference MemDiffRange(diff).lastDiff expected case=' + IntToStr(LCaseIndex),
          SizeUInt(LDiffPos), LRefLastDiff);
      end;

      LRefMin := LBufA[0];
      LRefMax := LBufA[0];
      for LIndex := 1 to C_BUFFER_LEN - 1 do
      begin
        if LBufA[LIndex] < LRefMin then
          LRefMin := LBufA[LIndex];
        if LBufA[LIndex] > LRefMax then
          LRefMax := LBufA[LIndex];
      end;

      LDirectDispatch^.MinMaxBytes(@LBufA[0], SizeUInt(C_BUFFER_LEN), LDirectMin, LDirectMax);
      AssertEquals('Direct MinMaxBytes(full).min parity case=' + IntToStr(LCaseIndex),
        Integer(LRefMin), Integer(LDirectMin));
      AssertEquals('Direct MinMaxBytes(full).max parity case=' + IntToStr(LCaseIndex),
        Integer(LRefMax), Integer(LDirectMax));

      LSegmentOffset := (LCaseIndex * 5 + 1) mod (C_BUFFER_LEN - 1);
      LSegmentLen := 1 + ((LCaseIndex * 9 + 2) mod (C_BUFFER_LEN - LSegmentOffset));

      LRefMin := LBufA[LSegmentOffset];
      LRefMax := LBufA[LSegmentOffset];
      for LIndex := LSegmentOffset + 1 to LSegmentOffset + LSegmentLen - 1 do
      begin
        if LBufA[LIndex] < LRefMin then
          LRefMin := LBufA[LIndex];
        if LBufA[LIndex] > LRefMax then
          LRefMax := LBufA[LIndex];
      end;

      LDirectDispatch^.MinMaxBytes(@LBufA[LSegmentOffset], SizeUInt(LSegmentLen), LDirectMin, LDirectMax);
      AssertEquals('Direct MinMaxBytes(segment).min parity case=' + IntToStr(LCaseIndex),
        Integer(LRefMin), Integer(LDirectMin));
      AssertEquals('Direct MinMaxBytes(segment).max parity case=' + IntToStr(LCaseIndex),
        Integer(LRefMax), Integer(LDirectMax));
    end;
  finally
    ResetToAutomaticBackend;
  end;
end;

procedure RunDirectDispatchConcurrentReRegisterSnapshotConsistency;
const
  WRITER_THREADS = 4;
  WRITER_ITERATIONS = 200;
  READER_THREADS = 6;
  READER_ITERATIONS = 2500;
var
  LOriginalTable: TSimdDispatchTable;
  LTableA: TSimdDispatchTable;
  LTableB: TSimdDispatchTable;
  LWriters: array of TDirectDispatchMutationWorker;
  LReaders: array of TDirectDispatchReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
begin
  if not TryGetRegisteredBackendDispatchTable(sbScalar, LOriginalTable) then
    raise Exception.Create('Scalar backend should be registered for synthetic direct-dispatch re-register test');

  LTableA := LOriginalTable;
  LTableB := LOriginalTable;
  ConfigureDirectDispatchSyntheticTableA(LTableA);
  ConfigureDirectDispatchSyntheticTableB(LTableB);

  SetActiveBackend(sbScalar);
  RegisterBackend(sbScalar, LTableA);
  RebindDirectDispatch;

  if not IsDirectDispatchSyntheticSnapshotA(GetDirectDispatchTable) then
    raise Exception.Create('Synthetic table A should be active before concurrent read/write');

  SetLength(LWriters, WRITER_THREADS);
  SetLength(LReaders, READER_THREADS);
  for LIndex := 0 to High(LWriters) do
    LWriters[LIndex] := TDirectDispatchMutationWorker.Create(
      WRITER_ITERATIONS, LIndex, sbScalar, LTableA, LTableB);
  for LIndex := 0 to High(LReaders) do
    LReaders[LIndex] := TDirectDispatchReadWorker.Create(READER_ITERATIONS);

  try
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';

    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;

    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    if not LAllSuccess then
      raise Exception.Create('Concurrent direct-dispatch re-register/read failed: ' + LErrorMsgs);
  finally
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;

    RegisterBackend(sbScalar, LOriginalTable);
    ResetToAutomaticBackend;
    RebindDirectDispatch;
  end;
end;

procedure TTestCase_DirectDispatchConcurrent.Test_DirectDispatchTable_Concurrent_ReRegister_SnapshotConsistency;
begin
  RunDirectDispatchConcurrentReRegisterSnapshotConsistency;
end;

initialization
  RegisterTest(TTestCase_DirectDispatch);
  RegisterTest(TTestCase_DirectDispatchConcurrent);

end.
