unit fafafa.core.simd.dispatchslots.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

// Keep parity with the original testcase compilation behavior.
{$R-}{$Q-}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.backend.iface,
  fafafa.core.simd.backend.adapter;

type
  // Full dispatch contract: every function slot must be bound on each selectable backend.
  TTestCase_DispatchAllSlots = class(TTestCase)
  private
    procedure AssertAllDispatchSlotsAssigned(const aBackend: TSimdBackend; const aDispatch: PSimdDispatchTable);
  published
    procedure Test_AllSelectableBackends_AllDispatchSlots_Assigned;
    procedure Test_BackendAdapter_EmptyOps_Fallback_AllDispatchSlots_Assigned;
    procedure Test_BackendAdapter_ActiveBackend_RoundTrip_NoNilAndCorePointersStable;
  end;

implementation

procedure TTestCase_DispatchAllSlots.AssertAllDispatchSlotsAssigned(const aBackend: TSimdBackend; const aDispatch: PSimdDispatchTable);
begin
  AssertNotNull('Dispatch table should be available', aDispatch);

  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddF32x4 should be assigned', Assigned(aDispatch^.AddF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubF32x4 should be assigned', Assigned(aDispatch^.SubF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulF32x4 should be assigned', Assigned(aDispatch^.MulF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DivF32x4 should be assigned', Assigned(aDispatch^.DivF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddF32x8 should be assigned', Assigned(aDispatch^.AddF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubF32x8 should be assigned', Assigned(aDispatch^.SubF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulF32x8 should be assigned', Assigned(aDispatch^.MulF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DivF32x8 should be assigned', Assigned(aDispatch^.DivF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddF64x2 should be assigned', Assigned(aDispatch^.AddF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubF64x2 should be assigned', Assigned(aDispatch^.SubF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulF64x2 should be assigned', Assigned(aDispatch^.MulF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DivF64x2 should be assigned', Assigned(aDispatch^.DivF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI32x4 should be assigned', Assigned(aDispatch^.AddI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI32x4 should be assigned', Assigned(aDispatch^.SubI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulI32x4 should be assigned', Assigned(aDispatch^.MulI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI32x4 should be assigned', Assigned(aDispatch^.AndI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI32x4 should be assigned', Assigned(aDispatch^.OrI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI32x4 should be assigned', Assigned(aDispatch^.XorI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI32x4 should be assigned', Assigned(aDispatch^.NotI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI32x4 should be assigned', Assigned(aDispatch^.AndNotI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI32x4 should be assigned', Assigned(aDispatch^.ShiftLeftI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI32x4 should be assigned', Assigned(aDispatch^.ShiftRightI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightArithI32x4 should be assigned', Assigned(aDispatch^.ShiftRightArithI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI32x4 should be assigned', Assigned(aDispatch^.CmpEqI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI32x4 should be assigned', Assigned(aDispatch^.CmpLtI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI32x4 should be assigned', Assigned(aDispatch^.CmpGtI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI32x4 should be assigned', Assigned(aDispatch^.CmpLeI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI32x4 should be assigned', Assigned(aDispatch^.CmpGeI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI32x4 should be assigned', Assigned(aDispatch^.CmpNeI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI32x4 should be assigned', Assigned(aDispatch^.MinI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI32x4 should be assigned', Assigned(aDispatch^.MaxI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI64x2 should be assigned', Assigned(aDispatch^.AddI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI64x2 should be assigned', Assigned(aDispatch^.SubI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI64x2 should be assigned', Assigned(aDispatch^.AndI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI64x2 should be assigned', Assigned(aDispatch^.OrI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI64x2 should be assigned', Assigned(aDispatch^.XorI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI64x2 should be assigned', Assigned(aDispatch^.NotI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI64x2 should be assigned', Assigned(aDispatch^.AndNotI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI64x2 should be assigned', Assigned(aDispatch^.ShiftLeftI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI64x2 should be assigned', Assigned(aDispatch^.ShiftRightI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightArithI64x2 should be assigned', Assigned(aDispatch^.ShiftRightArithI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI64x2 should be assigned', Assigned(aDispatch^.CmpEqI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI64x2 should be assigned', Assigned(aDispatch^.CmpLtI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI64x2 should be assigned', Assigned(aDispatch^.CmpGtI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI64x2 should be assigned', Assigned(aDispatch^.CmpLeI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI64x2 should be assigned', Assigned(aDispatch^.CmpGeI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI64x2 should be assigned', Assigned(aDispatch^.CmpNeI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI64x2 should be assigned', Assigned(aDispatch^.MinI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI64x2 should be assigned', Assigned(aDispatch^.MaxI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU64x2 should be assigned', Assigned(aDispatch^.AddU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU64x2 should be assigned', Assigned(aDispatch^.SubU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU64x2 should be assigned', Assigned(aDispatch^.AndU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU64x2 should be assigned', Assigned(aDispatch^.OrU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU64x2 should be assigned', Assigned(aDispatch^.XorU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU64x2 should be assigned', Assigned(aDispatch^.NotU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotU64x2 should be assigned', Assigned(aDispatch^.AndNotU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU64x2 should be assigned', Assigned(aDispatch^.CmpEqU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU64x2 should be assigned', Assigned(aDispatch^.CmpLtU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU64x2 should be assigned', Assigned(aDispatch^.CmpGtU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU64x2 should be assigned', Assigned(aDispatch^.MinU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU64x2 should be assigned', Assigned(aDispatch^.MaxU64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddF64x4 should be assigned', Assigned(aDispatch^.AddF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubF64x4 should be assigned', Assigned(aDispatch^.SubF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulF64x4 should be assigned', Assigned(aDispatch^.MulF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DivF64x4 should be assigned', Assigned(aDispatch^.DivF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI32x8 should be assigned', Assigned(aDispatch^.AddI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI32x8 should be assigned', Assigned(aDispatch^.SubI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulI32x8 should be assigned', Assigned(aDispatch^.MulI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI32x8 should be assigned', Assigned(aDispatch^.AndI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI32x8 should be assigned', Assigned(aDispatch^.OrI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI32x8 should be assigned', Assigned(aDispatch^.XorI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI32x8 should be assigned', Assigned(aDispatch^.NotI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI32x8 should be assigned', Assigned(aDispatch^.AndNotI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI32x8 should be assigned', Assigned(aDispatch^.ShiftLeftI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI32x8 should be assigned', Assigned(aDispatch^.ShiftRightI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightArithI32x8 should be assigned', Assigned(aDispatch^.ShiftRightArithI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI32x8 should be assigned', Assigned(aDispatch^.CmpEqI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI32x8 should be assigned', Assigned(aDispatch^.CmpLtI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI32x8 should be assigned', Assigned(aDispatch^.CmpGtI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI32x8 should be assigned', Assigned(aDispatch^.CmpLeI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI32x8 should be assigned', Assigned(aDispatch^.CmpGeI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI32x8 should be assigned', Assigned(aDispatch^.CmpNeI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI32x8 should be assigned', Assigned(aDispatch^.MinI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI32x8 should be assigned', Assigned(aDispatch^.MaxI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI64x4 should be assigned', Assigned(aDispatch^.AddI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI64x4 should be assigned', Assigned(aDispatch^.SubI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI64x4 should be assigned', Assigned(aDispatch^.AndI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI64x4 should be assigned', Assigned(aDispatch^.OrI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI64x4 should be assigned', Assigned(aDispatch^.XorI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI64x4 should be assigned', Assigned(aDispatch^.NotI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI64x4 should be assigned', Assigned(aDispatch^.AndNotI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI64x4 should be assigned', Assigned(aDispatch^.ShiftLeftI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI64x4 should be assigned', Assigned(aDispatch^.ShiftRightI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI64x4 should be assigned', Assigned(aDispatch^.CmpEqI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI64x4 should be assigned', Assigned(aDispatch^.CmpLtI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI64x4 should be assigned', Assigned(aDispatch^.CmpGtI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI64x4 should be assigned', Assigned(aDispatch^.CmpLeI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI64x4 should be assigned', Assigned(aDispatch^.CmpGeI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI64x4 should be assigned', Assigned(aDispatch^.CmpNeI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadI64x4 should be assigned', Assigned(aDispatch^.LoadI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreI64x4 should be assigned', Assigned(aDispatch^.StoreI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatI64x4 should be assigned', Assigned(aDispatch^.SplatI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroI64x4 should be assigned', Assigned(aDispatch^.ZeroI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU32x8 should be assigned', Assigned(aDispatch^.AddU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU32x8 should be assigned', Assigned(aDispatch^.SubU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulU32x8 should be assigned', Assigned(aDispatch^.MulU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU32x8 should be assigned', Assigned(aDispatch^.AndU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU32x8 should be assigned', Assigned(aDispatch^.OrU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU32x8 should be assigned', Assigned(aDispatch^.XorU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU32x8 should be assigned', Assigned(aDispatch^.NotU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotU32x8 should be assigned', Assigned(aDispatch^.AndNotU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftU32x8 should be assigned', Assigned(aDispatch^.ShiftLeftU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightU32x8 should be assigned', Assigned(aDispatch^.ShiftRightU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU32x8 should be assigned', Assigned(aDispatch^.CmpEqU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU32x8 should be assigned', Assigned(aDispatch^.CmpLtU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU32x8 should be assigned', Assigned(aDispatch^.CmpGtU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU32x8 should be assigned', Assigned(aDispatch^.CmpLeU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU32x8 should be assigned', Assigned(aDispatch^.CmpGeU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeU32x8 should be assigned', Assigned(aDispatch^.CmpNeU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU32x8 should be assigned', Assigned(aDispatch^.MinU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU32x8 should be assigned', Assigned(aDispatch^.MaxU32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU64x4 should be assigned', Assigned(aDispatch^.AddU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU64x4 should be assigned', Assigned(aDispatch^.SubU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU64x4 should be assigned', Assigned(aDispatch^.AndU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU64x4 should be assigned', Assigned(aDispatch^.OrU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU64x4 should be assigned', Assigned(aDispatch^.XorU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU64x4 should be assigned', Assigned(aDispatch^.NotU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftU64x4 should be assigned', Assigned(aDispatch^.ShiftLeftU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightU64x4 should be assigned', Assigned(aDispatch^.ShiftRightU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU64x4 should be assigned', Assigned(aDispatch^.CmpEqU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU64x4 should be assigned', Assigned(aDispatch^.CmpLtU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU64x4 should be assigned', Assigned(aDispatch^.CmpGtU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU64x4 should be assigned', Assigned(aDispatch^.CmpLeU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU64x4 should be assigned', Assigned(aDispatch^.CmpGeU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeU64x4 should be assigned', Assigned(aDispatch^.CmpNeU64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RcpF64x4 should be assigned', Assigned(aDispatch^.RcpF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI32x16 should be assigned', Assigned(aDispatch^.AddI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI32x16 should be assigned', Assigned(aDispatch^.SubI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulI32x16 should be assigned', Assigned(aDispatch^.MulI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI32x16 should be assigned', Assigned(aDispatch^.AndI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI32x16 should be assigned', Assigned(aDispatch^.OrI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI32x16 should be assigned', Assigned(aDispatch^.XorI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI32x16 should be assigned', Assigned(aDispatch^.NotI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI32x16 should be assigned', Assigned(aDispatch^.AndNotI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI32x16 should be assigned', Assigned(aDispatch^.ShiftLeftI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI32x16 should be assigned', Assigned(aDispatch^.ShiftRightI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightArithI32x16 should be assigned', Assigned(aDispatch^.ShiftRightArithI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI32x16 should be assigned', Assigned(aDispatch^.CmpEqI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI32x16 should be assigned', Assigned(aDispatch^.CmpLtI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI32x16 should be assigned', Assigned(aDispatch^.CmpGtI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI32x16 should be assigned', Assigned(aDispatch^.CmpLeI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI32x16 should be assigned', Assigned(aDispatch^.CmpGeI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI32x16 should be assigned', Assigned(aDispatch^.CmpNeI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI32x16 should be assigned', Assigned(aDispatch^.MinI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI32x16 should be assigned', Assigned(aDispatch^.MaxI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI64x8 should be assigned', Assigned(aDispatch^.AddI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI64x8 should be assigned', Assigned(aDispatch^.SubI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI64x8 should be assigned', Assigned(aDispatch^.AndI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI64x8 should be assigned', Assigned(aDispatch^.OrI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI64x8 should be assigned', Assigned(aDispatch^.XorI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI64x8 should be assigned', Assigned(aDispatch^.NotI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI64x8 should be assigned', Assigned(aDispatch^.CmpEqI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI64x8 should be assigned', Assigned(aDispatch^.CmpLtI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI64x8 should be assigned', Assigned(aDispatch^.CmpGtI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI64x8 should be assigned', Assigned(aDispatch^.CmpLeI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI64x8 should be assigned', Assigned(aDispatch^.CmpGeI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI64x8 should be assigned', Assigned(aDispatch^.CmpNeI64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU32x16 should be assigned', Assigned(aDispatch^.AddU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU32x16 should be assigned', Assigned(aDispatch^.SubU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulU32x16 should be assigned', Assigned(aDispatch^.MulU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU32x16 should be assigned', Assigned(aDispatch^.AndU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU32x16 should be assigned', Assigned(aDispatch^.OrU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU32x16 should be assigned', Assigned(aDispatch^.XorU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU32x16 should be assigned', Assigned(aDispatch^.NotU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotU32x16 should be assigned', Assigned(aDispatch^.AndNotU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftU32x16 should be assigned', Assigned(aDispatch^.ShiftLeftU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightU32x16 should be assigned', Assigned(aDispatch^.ShiftRightU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU32x16 should be assigned', Assigned(aDispatch^.CmpEqU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU32x16 should be assigned', Assigned(aDispatch^.CmpLtU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU32x16 should be assigned', Assigned(aDispatch^.CmpGtU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU32x16 should be assigned', Assigned(aDispatch^.CmpLeU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU32x16 should be assigned', Assigned(aDispatch^.CmpGeU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeU32x16 should be assigned', Assigned(aDispatch^.CmpNeU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU32x16 should be assigned', Assigned(aDispatch^.MinU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU32x16 should be assigned', Assigned(aDispatch^.MaxU32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU64x8 should be assigned', Assigned(aDispatch^.AddU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU64x8 should be assigned', Assigned(aDispatch^.SubU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU64x8 should be assigned', Assigned(aDispatch^.AndU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU64x8 should be assigned', Assigned(aDispatch^.OrU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU64x8 should be assigned', Assigned(aDispatch^.XorU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU64x8 should be assigned', Assigned(aDispatch^.NotU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftU64x8 should be assigned', Assigned(aDispatch^.ShiftLeftU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightU64x8 should be assigned', Assigned(aDispatch^.ShiftRightU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU64x8 should be assigned', Assigned(aDispatch^.CmpEqU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU64x8 should be assigned', Assigned(aDispatch^.CmpLtU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU64x8 should be assigned', Assigned(aDispatch^.CmpGtU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU64x8 should be assigned', Assigned(aDispatch^.CmpLeU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU64x8 should be assigned', Assigned(aDispatch^.CmpGeU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeU64x8 should be assigned', Assigned(aDispatch^.CmpNeU64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI16x32 should be assigned', Assigned(aDispatch^.AddI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI16x32 should be assigned', Assigned(aDispatch^.SubI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI16x32 should be assigned', Assigned(aDispatch^.AndI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI16x32 should be assigned', Assigned(aDispatch^.OrI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI16x32 should be assigned', Assigned(aDispatch^.XorI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI16x32 should be assigned', Assigned(aDispatch^.NotI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI16x32 should be assigned', Assigned(aDispatch^.AndNotI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI16x32 should be assigned', Assigned(aDispatch^.ShiftLeftI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI16x32 should be assigned', Assigned(aDispatch^.ShiftRightI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightArithI16x32 should be assigned', Assigned(aDispatch^.ShiftRightArithI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI16x32 should be assigned', Assigned(aDispatch^.CmpEqI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI16x32 should be assigned', Assigned(aDispatch^.CmpLtI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI16x32 should be assigned', Assigned(aDispatch^.CmpGtI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI16x32 should be assigned', Assigned(aDispatch^.MinI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI16x32 should be assigned', Assigned(aDispatch^.MaxI16x32));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI8x64 should be assigned', Assigned(aDispatch^.AddI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI8x64 should be assigned', Assigned(aDispatch^.SubI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI8x64 should be assigned', Assigned(aDispatch^.AndI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI8x64 should be assigned', Assigned(aDispatch^.OrI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI8x64 should be assigned', Assigned(aDispatch^.XorI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI8x64 should be assigned', Assigned(aDispatch^.NotI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI8x64 should be assigned', Assigned(aDispatch^.AndNotI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI8x64 should be assigned', Assigned(aDispatch^.CmpEqI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI8x64 should be assigned', Assigned(aDispatch^.CmpLtI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI8x64 should be assigned', Assigned(aDispatch^.CmpGtI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI8x64 should be assigned', Assigned(aDispatch^.MinI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI8x64 should be assigned', Assigned(aDispatch^.MaxI8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU8x64 should be assigned', Assigned(aDispatch^.AddU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU8x64 should be assigned', Assigned(aDispatch^.SubU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU8x64 should be assigned', Assigned(aDispatch^.AndU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU8x64 should be assigned', Assigned(aDispatch^.OrU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU8x64 should be assigned', Assigned(aDispatch^.XorU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU8x64 should be assigned', Assigned(aDispatch^.NotU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU8x64 should be assigned', Assigned(aDispatch^.CmpEqU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU8x64 should be assigned', Assigned(aDispatch^.CmpLtU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU8x64 should be assigned', Assigned(aDispatch^.CmpGtU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU8x64 should be assigned', Assigned(aDispatch^.MinU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU8x64 should be assigned', Assigned(aDispatch^.MaxU8x64));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddF32x16 should be assigned', Assigned(aDispatch^.AddF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubF32x16 should be assigned', Assigned(aDispatch^.SubF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulF32x16 should be assigned', Assigned(aDispatch^.MulF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DivF32x16 should be assigned', Assigned(aDispatch^.DivF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddF64x8 should be assigned', Assigned(aDispatch^.AddF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubF64x8 should be assigned', Assigned(aDispatch^.SubF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulF64x8 should be assigned', Assigned(aDispatch^.MulF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DivF64x8 should be assigned', Assigned(aDispatch^.DivF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqF32x4 should be assigned', Assigned(aDispatch^.CmpEqF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtF32x4 should be assigned', Assigned(aDispatch^.CmpLtF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeF32x4 should be assigned', Assigned(aDispatch^.CmpLeF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtF32x4 should be assigned', Assigned(aDispatch^.CmpGtF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeF32x4 should be assigned', Assigned(aDispatch^.CmpGeF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeF32x4 should be assigned', Assigned(aDispatch^.CmpNeF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqF64x2 should be assigned', Assigned(aDispatch^.CmpEqF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtF64x2 should be assigned', Assigned(aDispatch^.CmpLtF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeF64x2 should be assigned', Assigned(aDispatch^.CmpLeF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtF64x2 should be assigned', Assigned(aDispatch^.CmpGtF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeF64x2 should be assigned', Assigned(aDispatch^.CmpGeF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeF64x2 should be assigned', Assigned(aDispatch^.CmpNeF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqF32x16 should be assigned', Assigned(aDispatch^.CmpEqF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtF32x16 should be assigned', Assigned(aDispatch^.CmpLtF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeF32x16 should be assigned', Assigned(aDispatch^.CmpLeF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtF32x16 should be assigned', Assigned(aDispatch^.CmpGtF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeF32x16 should be assigned', Assigned(aDispatch^.CmpGeF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeF32x16 should be assigned', Assigned(aDispatch^.CmpNeF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqF64x8 should be assigned', Assigned(aDispatch^.CmpEqF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtF64x8 should be assigned', Assigned(aDispatch^.CmpLtF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeF64x8 should be assigned', Assigned(aDispatch^.CmpLeF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtF64x8 should be assigned', Assigned(aDispatch^.CmpGtF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeF64x8 should be assigned', Assigned(aDispatch^.CmpGeF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeF64x8 should be assigned', Assigned(aDispatch^.CmpNeF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqF32x8 should be assigned', Assigned(aDispatch^.CmpEqF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtF32x8 should be assigned', Assigned(aDispatch^.CmpLtF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeF32x8 should be assigned', Assigned(aDispatch^.CmpLeF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtF32x8 should be assigned', Assigned(aDispatch^.CmpGtF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeF32x8 should be assigned', Assigned(aDispatch^.CmpGeF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeF32x8 should be assigned', Assigned(aDispatch^.CmpNeF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqF64x4 should be assigned', Assigned(aDispatch^.CmpEqF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtF64x4 should be assigned', Assigned(aDispatch^.CmpLtF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeF64x4 should be assigned', Assigned(aDispatch^.CmpLeF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtF64x4 should be assigned', Assigned(aDispatch^.CmpGtF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeF64x4 should be assigned', Assigned(aDispatch^.CmpGeF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeF64x4 should be assigned', Assigned(aDispatch^.CmpNeF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AbsF32x4 should be assigned', Assigned(aDispatch^.AbsF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SqrtF32x4 should be assigned', Assigned(aDispatch^.SqrtF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinF32x4 should be assigned', Assigned(aDispatch^.MinF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxF32x4 should be assigned', Assigned(aDispatch^.MaxF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FmaF32x4 should be assigned', Assigned(aDispatch^.FmaF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RcpF32x4 should be assigned', Assigned(aDispatch^.RcpF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RsqrtF32x4 should be assigned', Assigned(aDispatch^.RsqrtF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FloorF32x4 should be assigned', Assigned(aDispatch^.FloorF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CeilF32x4 should be assigned', Assigned(aDispatch^.CeilF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RoundF32x4 should be assigned', Assigned(aDispatch^.RoundF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot TruncF32x4 should be assigned', Assigned(aDispatch^.TruncF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ClampF32x4 should be assigned', Assigned(aDispatch^.ClampF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FmaF64x2 should be assigned', Assigned(aDispatch^.FmaF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FloorF64x2 should be assigned', Assigned(aDispatch^.FloorF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CeilF64x2 should be assigned', Assigned(aDispatch^.CeilF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RoundF64x2 should be assigned', Assigned(aDispatch^.RoundF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot TruncF64x2 should be assigned', Assigned(aDispatch^.TruncF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AbsF64x2 should be assigned', Assigned(aDispatch^.AbsF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SqrtF64x2 should be assigned', Assigned(aDispatch^.SqrtF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinF64x2 should be assigned', Assigned(aDispatch^.MinF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxF64x2 should be assigned', Assigned(aDispatch^.MaxF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ClampF64x2 should be assigned', Assigned(aDispatch^.ClampF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FmaF32x8 should be assigned', Assigned(aDispatch^.FmaF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FloorF32x8 should be assigned', Assigned(aDispatch^.FloorF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CeilF32x8 should be assigned', Assigned(aDispatch^.CeilF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RoundF32x8 should be assigned', Assigned(aDispatch^.RoundF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot TruncF32x8 should be assigned', Assigned(aDispatch^.TruncF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AbsF32x8 should be assigned', Assigned(aDispatch^.AbsF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SqrtF32x8 should be assigned', Assigned(aDispatch^.SqrtF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinF32x8 should be assigned', Assigned(aDispatch^.MinF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxF32x8 should be assigned', Assigned(aDispatch^.MaxF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ClampF32x8 should be assigned', Assigned(aDispatch^.ClampF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FmaF64x4 should be assigned', Assigned(aDispatch^.FmaF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FloorF64x4 should be assigned', Assigned(aDispatch^.FloorF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CeilF64x4 should be assigned', Assigned(aDispatch^.CeilF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RoundF64x4 should be assigned', Assigned(aDispatch^.RoundF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot TruncF64x4 should be assigned', Assigned(aDispatch^.TruncF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FmaF32x16 should be assigned', Assigned(aDispatch^.FmaF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FloorF32x16 should be assigned', Assigned(aDispatch^.FloorF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CeilF32x16 should be assigned', Assigned(aDispatch^.CeilF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RoundF32x16 should be assigned', Assigned(aDispatch^.RoundF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot TruncF32x16 should be assigned', Assigned(aDispatch^.TruncF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FmaF64x8 should be assigned', Assigned(aDispatch^.FmaF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot FloorF64x8 should be assigned', Assigned(aDispatch^.FloorF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CeilF64x8 should be assigned', Assigned(aDispatch^.CeilF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot RoundF64x8 should be assigned', Assigned(aDispatch^.RoundF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot TruncF64x8 should be assigned', Assigned(aDispatch^.TruncF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AbsF64x4 should be assigned', Assigned(aDispatch^.AbsF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SqrtF64x4 should be assigned', Assigned(aDispatch^.SqrtF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinF64x4 should be assigned', Assigned(aDispatch^.MinF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxF64x4 should be assigned', Assigned(aDispatch^.MaxF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ClampF64x4 should be assigned', Assigned(aDispatch^.ClampF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AbsF32x16 should be assigned', Assigned(aDispatch^.AbsF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SqrtF32x16 should be assigned', Assigned(aDispatch^.SqrtF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinF32x16 should be assigned', Assigned(aDispatch^.MinF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxF32x16 should be assigned', Assigned(aDispatch^.MaxF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ClampF32x16 should be assigned', Assigned(aDispatch^.ClampF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AbsF64x8 should be assigned', Assigned(aDispatch^.AbsF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SqrtF64x8 should be assigned', Assigned(aDispatch^.SqrtF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinF64x8 should be assigned', Assigned(aDispatch^.MinF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxF64x8 should be assigned', Assigned(aDispatch^.MaxF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ClampF64x8 should be assigned', Assigned(aDispatch^.ClampF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DotF32x4 should be assigned', Assigned(aDispatch^.DotF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DotF32x3 should be assigned', Assigned(aDispatch^.DotF32x3));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CrossF32x3 should be assigned', Assigned(aDispatch^.CrossF32x3));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LengthF32x4 should be assigned', Assigned(aDispatch^.LengthF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LengthF32x3 should be assigned', Assigned(aDispatch^.LengthF32x3));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NormalizeF32x4 should be assigned', Assigned(aDispatch^.NormalizeF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NormalizeF32x3 should be assigned', Assigned(aDispatch^.NormalizeF32x3));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DotF32x8 should be assigned', Assigned(aDispatch^.DotF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DotF64x2 should be assigned', Assigned(aDispatch^.DotF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot DotF64x4 should be assigned', Assigned(aDispatch^.DotF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceAddF32x4 should be assigned', Assigned(aDispatch^.ReduceAddF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMinF32x4 should be assigned', Assigned(aDispatch^.ReduceMinF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMaxF32x4 should be assigned', Assigned(aDispatch^.ReduceMaxF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMulF32x4 should be assigned', Assigned(aDispatch^.ReduceMulF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceAddF64x2 should be assigned', Assigned(aDispatch^.ReduceAddF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMinF64x2 should be assigned', Assigned(aDispatch^.ReduceMinF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMaxF64x2 should be assigned', Assigned(aDispatch^.ReduceMaxF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMulF64x2 should be assigned', Assigned(aDispatch^.ReduceMulF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceAddF32x8 should be assigned', Assigned(aDispatch^.ReduceAddF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMinF32x8 should be assigned', Assigned(aDispatch^.ReduceMinF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMaxF32x8 should be assigned', Assigned(aDispatch^.ReduceMaxF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMulF32x8 should be assigned', Assigned(aDispatch^.ReduceMulF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceAddF64x4 should be assigned', Assigned(aDispatch^.ReduceAddF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMinF64x4 should be assigned', Assigned(aDispatch^.ReduceMinF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMaxF64x4 should be assigned', Assigned(aDispatch^.ReduceMaxF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMulF64x4 should be assigned', Assigned(aDispatch^.ReduceMulF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceAddF32x16 should be assigned', Assigned(aDispatch^.ReduceAddF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMinF32x16 should be assigned', Assigned(aDispatch^.ReduceMinF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMaxF32x16 should be assigned', Assigned(aDispatch^.ReduceMaxF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMulF32x16 should be assigned', Assigned(aDispatch^.ReduceMulF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceAddF64x8 should be assigned', Assigned(aDispatch^.ReduceAddF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMinF64x8 should be assigned', Assigned(aDispatch^.ReduceMinF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMaxF64x8 should be assigned', Assigned(aDispatch^.ReduceMaxF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ReduceMulF64x8 should be assigned', Assigned(aDispatch^.ReduceMulF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF32x4 should be assigned', Assigned(aDispatch^.LoadF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF32x4Aligned should be assigned', Assigned(aDispatch^.LoadF32x4Aligned));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF32x4 should be assigned', Assigned(aDispatch^.StoreF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF32x4Aligned should be assigned', Assigned(aDispatch^.StoreF32x4Aligned));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatF32x4 should be assigned', Assigned(aDispatch^.SplatF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroF32x4 should be assigned', Assigned(aDispatch^.ZeroF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectF32x4 should be assigned', Assigned(aDispatch^.SelectF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractF32x4 should be assigned', Assigned(aDispatch^.ExtractF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertF32x4 should be assigned', Assigned(aDispatch^.InsertF32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractF64x2 should be assigned', Assigned(aDispatch^.ExtractF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertF64x2 should be assigned', Assigned(aDispatch^.InsertF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractI32x4 should be assigned', Assigned(aDispatch^.ExtractI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertI32x4 should be assigned', Assigned(aDispatch^.InsertI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractI64x2 should be assigned', Assigned(aDispatch^.ExtractI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertI64x2 should be assigned', Assigned(aDispatch^.InsertI64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractF32x8 should be assigned', Assigned(aDispatch^.ExtractF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertF32x8 should be assigned', Assigned(aDispatch^.InsertF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractF64x4 should be assigned', Assigned(aDispatch^.ExtractF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertF64x4 should be assigned', Assigned(aDispatch^.InsertF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractI32x8 should be assigned', Assigned(aDispatch^.ExtractI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertI32x8 should be assigned', Assigned(aDispatch^.InsertI32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractI64x4 should be assigned', Assigned(aDispatch^.ExtractI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertI64x4 should be assigned', Assigned(aDispatch^.InsertI64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractF32x16 should be assigned', Assigned(aDispatch^.ExtractF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertF32x16 should be assigned', Assigned(aDispatch^.InsertF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ExtractI32x16 should be assigned', Assigned(aDispatch^.ExtractI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot InsertI32x16 should be assigned', Assigned(aDispatch^.InsertI32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF64x2 should be assigned', Assigned(aDispatch^.LoadF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF64x2 should be assigned', Assigned(aDispatch^.StoreF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatF64x2 should be assigned', Assigned(aDispatch^.SplatF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroF64x2 should be assigned', Assigned(aDispatch^.ZeroF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF32x8 should be assigned', Assigned(aDispatch^.LoadF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF32x8 should be assigned', Assigned(aDispatch^.StoreF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatF32x8 should be assigned', Assigned(aDispatch^.SplatF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroF32x8 should be assigned', Assigned(aDispatch^.ZeroF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF64x4 should be assigned', Assigned(aDispatch^.LoadF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF64x4 should be assigned', Assigned(aDispatch^.StoreF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatF64x4 should be assigned', Assigned(aDispatch^.SplatF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroF64x4 should be assigned', Assigned(aDispatch^.ZeroF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF32x16 should be assigned', Assigned(aDispatch^.LoadF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF32x16 should be assigned', Assigned(aDispatch^.StoreF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatF32x16 should be assigned', Assigned(aDispatch^.SplatF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroF32x16 should be assigned', Assigned(aDispatch^.ZeroF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot LoadF64x8 should be assigned', Assigned(aDispatch^.LoadF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot StoreF64x8 should be assigned', Assigned(aDispatch^.StoreF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SplatF64x8 should be assigned', Assigned(aDispatch^.SplatF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ZeroF64x8 should be assigned', Assigned(aDispatch^.ZeroF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MemEqual should be assigned', Assigned(aDispatch^.MemEqual));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MemFindByte should be assigned', Assigned(aDispatch^.MemFindByte));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MemDiffRange should be assigned', Assigned(aDispatch^.MemDiffRange));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MemCopy should be assigned', Assigned(aDispatch^.MemCopy));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MemSet should be assigned', Assigned(aDispatch^.MemSet));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MemReverse should be assigned', Assigned(aDispatch^.MemReverse));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SumBytes should be assigned', Assigned(aDispatch^.SumBytes));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinMaxBytes should be assigned', Assigned(aDispatch^.MinMaxBytes));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CountByte should be assigned', Assigned(aDispatch^.CountByte));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Utf8Validate should be assigned', Assigned(aDispatch^.Utf8Validate));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AsciiIEqual should be assigned', Assigned(aDispatch^.AsciiIEqual));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ToLowerAscii should be assigned', Assigned(aDispatch^.ToLowerAscii));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ToUpperAscii should be assigned', Assigned(aDispatch^.ToUpperAscii));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot BytesIndexOf should be assigned', Assigned(aDispatch^.BytesIndexOf));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot BitsetPopCount should be assigned', Assigned(aDispatch^.BitsetPopCount));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot I8x16SatAdd should be assigned', Assigned(aDispatch^.I8x16SatAdd));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot I8x16SatSub should be assigned', Assigned(aDispatch^.I8x16SatSub));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot I16x8SatAdd should be assigned', Assigned(aDispatch^.I16x8SatAdd));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot I16x8SatSub should be assigned', Assigned(aDispatch^.I16x8SatSub));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot U8x16SatAdd should be assigned', Assigned(aDispatch^.U8x16SatAdd));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot U8x16SatSub should be assigned', Assigned(aDispatch^.U8x16SatSub));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot U16x8SatAdd should be assigned', Assigned(aDispatch^.U16x8SatAdd));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot U16x8SatSub should be assigned', Assigned(aDispatch^.U16x8SatSub));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI16x8 should be assigned', Assigned(aDispatch^.AddI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI16x8 should be assigned', Assigned(aDispatch^.SubI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulI16x8 should be assigned', Assigned(aDispatch^.MulI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI16x8 should be assigned', Assigned(aDispatch^.AndI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI16x8 should be assigned', Assigned(aDispatch^.OrI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI16x8 should be assigned', Assigned(aDispatch^.XorI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI16x8 should be assigned', Assigned(aDispatch^.NotI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI16x8 should be assigned', Assigned(aDispatch^.AndNotI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftI16x8 should be assigned', Assigned(aDispatch^.ShiftLeftI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightI16x8 should be assigned', Assigned(aDispatch^.ShiftRightI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightArithI16x8 should be assigned', Assigned(aDispatch^.ShiftRightArithI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI16x8 should be assigned', Assigned(aDispatch^.CmpEqI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI16x8 should be assigned', Assigned(aDispatch^.CmpLtI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI16x8 should be assigned', Assigned(aDispatch^.CmpGtI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI16x8 should be assigned', Assigned(aDispatch^.CmpLeI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI16x8 should be assigned', Assigned(aDispatch^.CmpGeI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI16x8 should be assigned', Assigned(aDispatch^.CmpNeI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI16x8 should be assigned', Assigned(aDispatch^.MinI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI16x8 should be assigned', Assigned(aDispatch^.MaxI16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddI8x16 should be assigned', Assigned(aDispatch^.AddI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubI8x16 should be assigned', Assigned(aDispatch^.SubI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndI8x16 should be assigned', Assigned(aDispatch^.AndI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrI8x16 should be assigned', Assigned(aDispatch^.OrI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorI8x16 should be assigned', Assigned(aDispatch^.XorI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotI8x16 should be assigned', Assigned(aDispatch^.NotI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqI8x16 should be assigned', Assigned(aDispatch^.CmpEqI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtI8x16 should be assigned', Assigned(aDispatch^.CmpLtI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtI8x16 should be assigned', Assigned(aDispatch^.CmpGtI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeI8x16 should be assigned', Assigned(aDispatch^.CmpLeI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeI8x16 should be assigned', Assigned(aDispatch^.CmpGeI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeI8x16 should be assigned', Assigned(aDispatch^.CmpNeI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinI8x16 should be assigned', Assigned(aDispatch^.MinI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxI8x16 should be assigned', Assigned(aDispatch^.MaxI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU32x4 should be assigned', Assigned(aDispatch^.AddU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU32x4 should be assigned', Assigned(aDispatch^.SubU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulU32x4 should be assigned', Assigned(aDispatch^.MulU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU32x4 should be assigned', Assigned(aDispatch^.AndU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU32x4 should be assigned', Assigned(aDispatch^.OrU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU32x4 should be assigned', Assigned(aDispatch^.XorU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU32x4 should be assigned', Assigned(aDispatch^.NotU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotU32x4 should be assigned', Assigned(aDispatch^.AndNotU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftU32x4 should be assigned', Assigned(aDispatch^.ShiftLeftU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightU32x4 should be assigned', Assigned(aDispatch^.ShiftRightU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU32x4 should be assigned', Assigned(aDispatch^.CmpEqU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU32x4 should be assigned', Assigned(aDispatch^.CmpLtU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU32x4 should be assigned', Assigned(aDispatch^.CmpGtU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU32x4 should be assigned', Assigned(aDispatch^.CmpLeU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU32x4 should be assigned', Assigned(aDispatch^.CmpGeU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU32x4 should be assigned', Assigned(aDispatch^.MinU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU32x4 should be assigned', Assigned(aDispatch^.MaxU32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU16x8 should be assigned', Assigned(aDispatch^.AddU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU16x8 should be assigned', Assigned(aDispatch^.SubU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MulU16x8 should be assigned', Assigned(aDispatch^.MulU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU16x8 should be assigned', Assigned(aDispatch^.AndU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU16x8 should be assigned', Assigned(aDispatch^.OrU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU16x8 should be assigned', Assigned(aDispatch^.XorU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU16x8 should be assigned', Assigned(aDispatch^.NotU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftLeftU16x8 should be assigned', Assigned(aDispatch^.ShiftLeftU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot ShiftRightU16x8 should be assigned', Assigned(aDispatch^.ShiftRightU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU16x8 should be assigned', Assigned(aDispatch^.CmpEqU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU16x8 should be assigned', Assigned(aDispatch^.CmpLtU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU16x8 should be assigned', Assigned(aDispatch^.CmpGtU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU16x8 should be assigned', Assigned(aDispatch^.CmpLeU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU16x8 should be assigned', Assigned(aDispatch^.CmpGeU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeU16x8 should be assigned', Assigned(aDispatch^.CmpNeU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU16x8 should be assigned', Assigned(aDispatch^.MinU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU16x8 should be assigned', Assigned(aDispatch^.MaxU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AddU8x16 should be assigned', Assigned(aDispatch^.AddU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SubU8x16 should be assigned', Assigned(aDispatch^.SubU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndU8x16 should be assigned', Assigned(aDispatch^.AndU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot OrU8x16 should be assigned', Assigned(aDispatch^.OrU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot XorU8x16 should be assigned', Assigned(aDispatch^.XorU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot NotU8x16 should be assigned', Assigned(aDispatch^.NotU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpEqU8x16 should be assigned', Assigned(aDispatch^.CmpEqU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLtU8x16 should be assigned', Assigned(aDispatch^.CmpLtU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGtU8x16 should be assigned', Assigned(aDispatch^.CmpGtU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpLeU8x16 should be assigned', Assigned(aDispatch^.CmpLeU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpGeU8x16 should be assigned', Assigned(aDispatch^.CmpGeU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot CmpNeU8x16 should be assigned', Assigned(aDispatch^.CmpNeU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MinU8x16 should be assigned', Assigned(aDispatch^.MinU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot MaxU8x16 should be assigned', Assigned(aDispatch^.MaxU8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask2All should be assigned', Assigned(aDispatch^.Mask2All));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask2Any should be assigned', Assigned(aDispatch^.Mask2Any));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask2None should be assigned', Assigned(aDispatch^.Mask2None));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask2PopCount should be assigned', Assigned(aDispatch^.Mask2PopCount));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask2FirstSet should be assigned', Assigned(aDispatch^.Mask2FirstSet));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask4All should be assigned', Assigned(aDispatch^.Mask4All));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask4Any should be assigned', Assigned(aDispatch^.Mask4Any));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask4None should be assigned', Assigned(aDispatch^.Mask4None));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask4PopCount should be assigned', Assigned(aDispatch^.Mask4PopCount));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask4FirstSet should be assigned', Assigned(aDispatch^.Mask4FirstSet));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask8All should be assigned', Assigned(aDispatch^.Mask8All));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask8Any should be assigned', Assigned(aDispatch^.Mask8Any));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask8None should be assigned', Assigned(aDispatch^.Mask8None));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask8PopCount should be assigned', Assigned(aDispatch^.Mask8PopCount));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask8FirstSet should be assigned', Assigned(aDispatch^.Mask8FirstSet));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask16All should be assigned', Assigned(aDispatch^.Mask16All));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask16Any should be assigned', Assigned(aDispatch^.Mask16Any));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask16None should be assigned', Assigned(aDispatch^.Mask16None));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask16PopCount should be assigned', Assigned(aDispatch^.Mask16PopCount));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot Mask16FirstSet should be assigned', Assigned(aDispatch^.Mask16FirstSet));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectF64x2 should be assigned', Assigned(aDispatch^.SelectF64x2));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectF32x16 should be assigned', Assigned(aDispatch^.SelectF32x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectF64x8 should be assigned', Assigned(aDispatch^.SelectF64x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectI32x4 should be assigned', Assigned(aDispatch^.SelectI32x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectF32x8 should be assigned', Assigned(aDispatch^.SelectF32x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot SelectF64x4 should be assigned', Assigned(aDispatch^.SelectF64x4));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotI8x16 should be assigned', Assigned(aDispatch^.AndNotI8x16));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotU16x8 should be assigned', Assigned(aDispatch^.AndNotU16x8));
  AssertTrue('Backend=' + IntToStr(Ord(aBackend)) + ' slot AndNotU8x16 should be assigned', Assigned(aDispatch^.AndNotU8x16));

end;

procedure TTestCase_DispatchAllSlots.Test_AllSelectableBackends_AllDispatchSlots_Assigned;
const
  BACKENDS: array[0..9] of TSimdBackend = (
    sbScalar, sbSSE2, sbSSE3, sbSSSE3, sbSSE41, sbSSE42, sbAVX2, sbAVX512, sbNEON, sbRISCVV
  );
var
  LBackend: TSimdBackend;
  LChecked: Integer;
  LDispatch: PSimdDispatchTable;
begin
  LChecked := 0;
  try
    for LBackend in BACKENDS do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      AssertEquals('Active backend mismatch', Ord(LBackend), Ord(GetActiveBackend));
      AssertAllDispatchSlotsAssigned(LBackend, LDispatch);
      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  AssertTrue('At least one backend should be checked', LChecked > 0);
end;

procedure TTestCase_DispatchAllSlots.Test_BackendAdapter_EmptyOps_Fallback_AllDispatchSlots_Assigned;
var
  LOps: TSimdBackendOps;
  LTable: TSimdDispatchTable;
begin
  LOps := Default(TSimdBackendOps);
  ClearBackendOps(LOps);
  BackendOpsToDispatchTable(LOps, LTable);
  AssertAllDispatchSlotsAssigned(sbScalar, @LTable);
end;

procedure TTestCase_DispatchAllSlots.Test_BackendAdapter_ActiveBackend_RoundTrip_NoNilAndCorePointersStable;
const
  BACKENDS: array[0..9] of TSimdBackend = (
    sbScalar, sbSSE2, sbSSE3, sbSSSE3, sbSSE41, sbSSE42, sbAVX2, sbAVX512, sbNEON, sbRISCVV
  );
var
  LBackend: TSimdBackend;
  LChecked: Integer;
  LDispatch: PSimdDispatchTable;
  LSourceTable: TSimdDispatchTable;
  LRoundTripTable: TSimdDispatchTable;
  LOps: TSimdBackendOps;
begin
  LChecked := 0;
  try
    for LBackend in BACKENDS do
    begin
      if not IsBackendRegistered(LBackend) then
        Continue;
      if not TrySetActiveBackend(LBackend) then
        Continue;

      LDispatch := GetDispatchTable;
      AssertNotNull('Dispatch table should be available', LDispatch);
      AssertEquals('Active backend mismatch', Ord(LBackend), Ord(GetActiveBackend));

      LSourceTable := LDispatch^;
      LOps := Default(TSimdBackendOps);
      DispatchTableToBackendOps(LSourceTable, LOps);
      BackendOpsToDispatchTable(LOps, LRoundTripTable);
      AssertAllDispatchSlotsAssigned(LBackend, @LRoundTripTable);

      AssertEquals('Roundtrip backend field mismatch', Ord(LSourceTable.Backend), Ord(LRoundTripTable.Backend));
      AssertEquals('Roundtrip BackendInfo.Backend mismatch', Ord(LSourceTable.BackendInfo.Backend), Ord(LRoundTripTable.BackendInfo.Backend));
      AssertEquals('Roundtrip BackendInfo.Name mismatch', LSourceTable.BackendInfo.Name, LRoundTripTable.BackendInfo.Name);
      AssertEquals('Roundtrip BackendInfo.Description mismatch', LSourceTable.BackendInfo.Description, LRoundTripTable.BackendInfo.Description);
      AssertEquals('Roundtrip BackendInfo.Available mismatch',
        LSourceTable.BackendInfo.Available, LRoundTripTable.BackendInfo.Available);
      AssertEquals('Roundtrip BackendInfo.Priority mismatch',
        LSourceTable.BackendInfo.Priority, LRoundTripTable.BackendInfo.Priority);
      AssertTrue('Roundtrip BackendInfo.Capabilities mismatch',
        LSourceTable.BackendInfo.Capabilities = LRoundTripTable.BackendInfo.Capabilities);
      AssertTrue('BackendInfo.Name should stay non-empty for registered backend',
        LRoundTripTable.BackendInfo.Name <> '');

      // Contract smoke: representative core slots must keep exact function-pointer identity.
      AssertTrue('AddF32x4 pointer changed after roundtrip', LSourceTable.AddF32x4 = LRoundTripTable.AddF32x4);
      AssertTrue('MulF32x4 pointer changed after roundtrip', LSourceTable.MulF32x4 = LRoundTripTable.MulF32x4);
      AssertTrue('RoundF32x4 pointer changed after roundtrip', LSourceTable.RoundF32x4 = LRoundTripTable.RoundF32x4);
      AssertTrue('TruncF32x4 pointer changed after roundtrip', LSourceTable.TruncF32x4 = LRoundTripTable.TruncF32x4);
      AssertTrue('AddI32x4 pointer changed after roundtrip', LSourceTable.AddI32x4 = LRoundTripTable.AddI32x4);
      AssertTrue('AndI32x4 pointer changed after roundtrip', LSourceTable.AndI32x4 = LRoundTripTable.AndI32x4);
      AssertTrue('LoadF32x4 pointer changed after roundtrip', LSourceTable.LoadF32x4 = LRoundTripTable.LoadF32x4);
      AssertTrue('StoreF32x4 pointer changed after roundtrip', LSourceTable.StoreF32x4 = LRoundTripTable.StoreF32x4);
      AssertTrue('MemEqual pointer changed after roundtrip', LSourceTable.MemEqual = LRoundTripTable.MemEqual);
      AssertTrue('BitsetPopCount pointer changed after roundtrip', LSourceTable.BitsetPopCount = LRoundTripTable.BitsetPopCount);

      Inc(LChecked);
    end;
  finally
    ResetToAutomaticBackend;
  end;

  AssertTrue('At least one backend should be checked', LChecked > 0);
end;

initialization
  RegisterTest(TTestCase_DispatchAllSlots);

end.
