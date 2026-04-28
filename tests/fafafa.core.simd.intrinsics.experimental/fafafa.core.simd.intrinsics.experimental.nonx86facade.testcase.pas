unit fafafa.core.simd.intrinsics.experimental.nonx86facade.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.neon,
  fafafa.core.simd.intrinsics.rvv,
  fafafa.core.simd.intrinsics.sve,
  fafafa.core.simd.intrinsics.sve2,
  fafafa.core.simd.intrinsics.lasx;

type
  TTestCase_NonX86FacadeExperimental = class(TTestCase)
  published
    procedure Test_NeonFallbackSymbolsAndSemantics;
    procedure Test_RvvFallbackSymbolsAndSemantics;
    procedure Test_SveFallbackSymbolsAndSemantics;
    procedure Test_Sve2FallbackSymbolsAndSemantics;
    procedure Test_LasxFallbackSymbolsAndSemantics;
  end;

implementation

type
  TU32x8 = array[0..7] of UInt32;
  TU32x16 = array[0..15] of UInt32;
  TU64x4 = array[0..3] of UInt64;
  PU32x8 = ^TU32x8;
  PU32x16 = ^TU32x16;
  PU64x4 = ^TU64x4;

procedure TTestCase_NonX86FacadeExperimental.Test_NeonFallbackSymbolsAndSemantics;
{$IF defined(CPUARM) or defined(CPUAARCH64)}
var
  LA: TNeon128;
  LB: TNeon128;
  LData128: array[0..3] of UInt32;
  LData64: array[0..1] of UInt32;
  LF32Data128: array[0..3] of Single;
  LF32Data64: array[0..1] of Single;
  LStore128: array[0..3] of UInt32;
  LStore64: array[0..1] of UInt32;
  LVec64: TNeon64;
{$ENDIF}
begin
  {$IF defined(CPUARM) or defined(CPUAARCH64)}
  LData128[0] := 1;
  LData128[1] := 2;
  LData128[2] := 3;
  LData128[3] := 4;
  LF32Data128[0] := 1.5;
  LF32Data128[1] := 2.5;
  LF32Data128[2] := 3.5;
  LF32Data128[3] := 4.5;

  LA := neon_vld1q_u32(@LData128[0]);
  LB := neon_vdupq_n_u32(10);
  AssertEquals('neon_vld1q_u32', QWord(3), QWord(LA.m128i_u32[2]));
  AssertEquals('neon_vdupq_n_u32', QWord(10), QWord(LB.m128i_u32[3]));
  AssertEquals('neon_vaddq_u32', QWord(11), QWord(neon_vaddq_u32(LA, LB).m128i_u32[0]));
  AssertEquals('neon_vsubq_u32', QWord(9), QWord(neon_vsubq_u32(LB, LA).m128i_u32[0]));
  AssertEquals('neon_vmulq_u32', QWord(20), QWord(neon_vmulq_u32(LA, LB).m128i_u32[1]));
  AssertEquals('neon_vandq_u32', QWord(0), QWord(neon_vandq_u32(LA, LB).m128i_u32[0]));
  AssertEquals('neon_vorrq_u32', QWord(11), QWord(neon_vorrq_u32(LA, LB).m128i_u32[0]));
  AssertEquals('neon_veorq_u32', QWord(11), QWord(neon_veorq_u32(LA, LB).m128i_u32[0]));
  AssertEquals('neon_vbicq_u32', QWord(1), QWord(neon_vbicq_u32(LA, LB).m128i_u32[0]));
  AssertEquals('neon_vceqq_u32', QWord($FFFFFFFF), QWord(neon_vceqq_u32(LA, LA).m128i_u32[0]));
  AssertEquals('neon_vcgtq_u32', QWord($FFFFFFFF), QWord(neon_vcgtq_u32(LB, LA).m128i_u32[0]));
  AssertEquals('neon_vmaxq_u32', QWord(10), QWord(neon_vmaxq_u32(LA, LB).m128i_u32[0]));
  AssertEquals('neon_vminq_u32', QWord(1), QWord(neon_vminq_u32(LA, LB).m128i_u32[0]));
  neon_vst1q_u32(LStore128[0], LA);
  AssertEquals('neon_vst1q_u32', QWord(4), QWord(LStore128[3]));

  LA := neon_vld1q_f32(@LF32Data128[0]);
  LB := neon_vdupq_n_f32(2.0);
  AssertEquals('neon_vld1q_f32', 3.5, LA.m128_f32[2], 0.00001);
  AssertEquals('neon_vdupq_n_f32', 2.0, LB.m128_f32[3], 0.00001);
  AssertEquals('neon_vaddq_f32', 3.5, neon_vaddq_f32(LA, LB).m128_f32[0], 0.00001);
  AssertEquals('neon_vsubq_f32', 0.5, neon_vsubq_f32(LA, LB).m128_f32[0], 0.00001);
  AssertEquals('neon_vmulq_f32', 3.0, neon_vmulq_f32(LA, LB).m128_f32[0], 0.00001);
  AssertEquals('neon_vceqq_f32', QWord($FFFFFFFF), QWord(neon_vceqq_f32(LA, LA).m128i_u32[0]));
  AssertEquals('neon_vcgtq_f32', QWord($FFFFFFFF), QWord(neon_vcgtq_f32(LA, LB).m128i_u32[2]));
  AssertEquals('neon_vmaxq_f32', 2.0, neon_vmaxq_f32(LA, LB).m128_f32[0], 0.00001);
  AssertEquals('neon_vminq_f32', 1.5, neon_vminq_f32(LA, LB).m128_f32[0], 0.00001);
  neon_vst1q_f32(LF32Data128[0], LA);

  LData64[0] := 7;
  LData64[1] := 9;
  LF32Data64[0] := 7.5;
  LF32Data64[1] := 9.5;
  LVec64 := neon_vld1_u32(@LData64[0]);
  AssertEquals('neon_vld1_u32', QWord(9), QWord(LVec64.n64_u32[1]));
  LVec64 := neon_vdup_n_u32(12);
  AssertEquals('neon_vdup_n_u32', QWord(12), QWord(LVec64.n64_u32[1]));
  neon_vst1_u32(LStore64[0], LVec64);
  AssertEquals('neon_vst1_u32', QWord(12), QWord(LStore64[1]));
  LVec64 := neon_vld1_f32(@LF32Data64[0]);
  AssertEquals('neon_vld1_f32', 9.5, LVec64.n64_f32[1], 0.00001);
  LVec64 := neon_vdup_n_f32(3.25);
  AssertEquals('neon_vdup_n_f32', 3.25, LVec64.n64_f32[1], 0.00001);
  neon_vst1_f32(LF32Data64[0], LVec64);
  {$ELSE}
  AssertTrue('NEON fallback semantics are checked on ARM/AArch64 builds', True);
  {$ENDIF}
end;

procedure TTestCase_NonX86FacadeExperimental.Test_RvvFallbackSymbolsAndSemantics;
{$IFDEF CPURISCV64}
var
  LA: TRVVVector;
  LB: TRVVVector;
  LC: TRVVVector;
  LData: array[0..3] of UInt32;
  LStore: array[0..3] of UInt32;
{$ENDIF}
begin
  {$IFDEF CPURISCV64}
  LData[0] := 1;
  LData[1] := 2;
  LData[2] := 3;
  LData[3] := 4;
  LA := rvv_vle32_v_u32m1(@LData[0], 4);
  LB := rvv_vmv_v_x_u32m1(10, 4);
  LC := rvv_vadd_vv_u32m1(LA, LB, 4);
  AssertEquals('rvv_vle32_v_u32m1', QWord(3), QWord(PU32x16(@LA)^[2]));
  AssertEquals('rvv_vmv_v_x_u32m1', QWord(10), QWord(PU32x16(@LB)^[3]));
  AssertEquals('rvv_vadd_vv_u32m1', QWord(11), QWord(PU32x16(@LC)^[0]));
  LC := rvv_vmul_vv_u32m1(LA, LB, 4);
  AssertEquals('rvv_vmul_vv_u32m1', QWord(20), QWord(PU32x16(@LC)^[1]));
  LC := rvv_vmadd_vv_u32m1(LA, LB, rvv_vadd_vv_u32m1(LA, LB, 4), 4);
  AssertEquals('rvv_vmadd_vv_u32m1', QWord(31), QWord(PU32x16(@LC)^[1]));
  rvv_vse32_v_u32m1(LStore[0], LC, 4);
  AssertEquals('rvv_vse32_v_u32m1', QWord(14), QWord(LStore[3]));
  {$ELSE}
  AssertTrue('RVV fallback semantics are checked on RISC-V builds', True);
  {$ENDIF}
end;

procedure TTestCase_NonX86FacadeExperimental.Test_SveFallbackSymbolsAndSemantics;
{$IFDEF CPUAARCH64}
var
  LA: TSVEVector;
  LB: TSVEVector;
  LC: TSVEVector;
  LPFalse: TSVEPredicate;
  LPTrue: TSVEPredicate;
  LData: array[0..15] of UInt32;
  LStore: array[0..15] of UInt32;
  LIndex: Integer;
{$ENDIF}
begin
  {$IFDEF CPUAARCH64}
  for LIndex := 0 to 15 do
    LData[LIndex] := LIndex + 1;
  LPTrue := sve_ptrue_b32;
  LPFalse := sve_pfalse_b;
  LA := sve_ld1_u32(LPTrue, @LData[0]);
  LB := sve_add_u32_z(LPTrue, LA, LA);
  AssertTrue('sve_ptrue_b32', LPTrue.pred_mask[15]);
  AssertFalse('sve_pfalse_b', LPFalse.pred_mask[0]);
  AssertEquals('sve_ld1_u32', QWord(4), QWord(PU32x16(@LA)^[3]));
  AssertEquals('sve_add_u32_z', QWord(8), QWord(PU32x16(@LB)^[3]));
  LC := sve_mul_u32_z(LPTrue, LA, LA);
  AssertEquals('sve_mul_u32_z', QWord(16), QWord(PU32x16(@LC)^[3]));
  sve_st1_u32(LPTrue, LStore[0], LB);
  AssertEquals('sve_st1_u32', QWord(8), QWord(LStore[3]));
  LC := sve_add_u32_z(LPFalse, LA, LA);
  AssertEquals('sve_add_u32_z inactive lanes zero', QWord(0), QWord(PU32x16(@LC)^[3]));
  {$ELSE}
  AssertTrue('SVE fallback semantics are checked on AArch64 builds', True);
  {$ENDIF}
end;

procedure TTestCase_NonX86FacadeExperimental.Test_Sve2FallbackSymbolsAndSemantics;
{$IFDEF CPUAARCH64}
var
  LA: TSVEVector;
  LB: TSVEVector;
  LC: TSVEVector;
  LPTrue: TSVEPredicate;
  LIndex: Integer;
{$ENDIF}
begin
  {$IFDEF CPUAARCH64}
  LPTrue := sve_ptrue_b32;
  for LIndex := 0 to 15 do
  begin
    PU32x16(@LA)^[LIndex] := LIndex + 1;
    PU32x16(@LB)^[LIndex] := 2;
  end;
  LC := sve2_addp_u32_z(LPTrue, LA, LB);
  AssertEquals('sve2_addp_u32_z', QWord(3), QWord(PU32x16(@LC)^[0]));
  LC := sve2_maxp_u32_z(LPTrue, LA, LB);
  AssertEquals('sve2_maxp_u32_z', QWord(2), QWord(PU32x16(@LC)^[0]));
  LC := sve2_minp_u32_z(LPTrue, LA, LB);
  AssertEquals('sve2_minp_u32_z', QWord(1), QWord(PU32x16(@LC)^[0]));
  LC := sve2_mul_lane_u32(LA, LA, 2);
  AssertEquals('sve2_mul_lane_u32', QWord(3), QWord(PU32x16(@LC)^[0]));
  {$ELSE}
  AssertTrue('SVE2 fallback semantics are checked on AArch64 builds', True);
  {$ENDIF}
end;

procedure TTestCase_NonX86FacadeExperimental.Test_LasxFallbackSymbolsAndSemantics;
{$IFDEF CPULOONGARCH64}
var
  LA: TLASXVector;
  LB: TLASXVector;
  LC: TLASXVector;
  LData: array[0..7] of UInt32;
  LStore: array[0..7] of UInt32;
  LIndex: Integer;
{$ENDIF}
begin
  {$IFDEF CPULOONGARCH64}
  for LIndex := 0 to 7 do
    LData[LIndex] := LIndex + 1;
  LA := lasx_xvld(@LData[0], 0);
  LB := lasx_xvreplgr2vr_w(10);
  AssertEquals('lasx_xvld', QWord(3), QWord(PU32x8(@LA)^[2]));
  lasx_xvst(LStore[0], LA, 0);
  AssertEquals('lasx_xvst', QWord(4), QWord(LStore[3]));
  AssertEquals('lasx_xvreplgr2vr_w', QWord(10), QWord(PU32x8(@LB)^[7]));
  LC := lasx_xvadd_w(LA, LB);
  AssertEquals('lasx_xvadd_w', QWord(11), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvsub_w(LB, LA);
  AssertEquals('lasx_xvsub_w', QWord(9), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvmul_w(LA, LB);
  AssertEquals('lasx_xvmul_w', QWord(20), QWord(PU32x8(@LC)^[1]));
  LC := lasx_xvand_v(LA, LB);
  AssertEquals('lasx_xvand_v', QWord(0), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvor_v(LA, LB);
  AssertEquals('lasx_xvor_v', QWord(11), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvxor_v(LA, LB);
  AssertEquals('lasx_xvxor_v', QWord(11), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvnor_v(LA, LB);
  AssertEquals('lasx_xvnor_v', QWord(not UInt32(11)), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvseq_w(LA, LA);
  AssertEquals('lasx_xvseq_w', QWord($FFFFFFFF), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvslt_w(LA, LB);
  AssertEquals('lasx_xvslt_w', QWord($FFFFFFFF), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvmax_w(LA, LB);
  AssertEquals('lasx_xvmax_w', QWord(10), QWord(PU32x8(@LC)^[0]));
  LC := lasx_xvmin_w(LA, LB);
  AssertEquals('lasx_xvmin_w', QWord(1), QWord(PU32x8(@LC)^[0]));
  LB := lasx_xvreplgr2vr_d(10);
  AssertEquals('lasx_xvreplgr2vr_d', QWord(10), QWord(PU64x4(@LB)^[3]));
  LC := lasx_xvadd_d(LA, LB);
  AssertEquals('lasx_xvadd_d', QWord(PU64x4(@LA)^[0] + 10), QWord(PU64x4(@LC)^[0]));
  LC := lasx_xvsub_d(LB, LA);
  AssertEquals('lasx_xvsub_d', QWord(10 - PU64x4(@LA)^[0]), QWord(PU64x4(@LC)^[0]));
  LC := lasx_xvmul_d(LA, LB);
  AssertEquals('lasx_xvmul_d', QWord(PU64x4(@LA)^[0] * 10), QWord(PU64x4(@LC)^[0]));
  LC := lasx_xvseq_d(LA, LA);
  AssertEquals('lasx_xvseq_d', QWord($FFFFFFFFFFFFFFFF), QWord(PU64x4(@LC)^[0]));
  LC := lasx_xvslt_d(LA, LB);
  AssertEquals('lasx_xvslt_d', QWord($FFFFFFFFFFFFFFFF), QWord(PU64x4(@LC)^[0]));
  LC := lasx_xvmax_d(LA, LB);
  AssertEquals('lasx_xvmax_d', QWord(10), QWord(PU64x4(@LC)^[0]));
  LC := lasx_xvmin_d(LA, LB);
  AssertEquals('lasx_xvmin_d', QWord(PU64x4(@LA)^[0]), QWord(PU64x4(@LC)^[0]));
  {$ELSE}
  AssertTrue('LASX fallback semantics are checked on LoongArch64 builds', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_NonX86FacadeExperimental);

end.
