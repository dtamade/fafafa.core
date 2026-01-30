unit Test_fafafa.core.atomic.contract;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic;

procedure RegisterAtomicContractTests;

implementation

type
  TTestCase_AtomicContract = class(TTestCase)
  published
    procedure Test_api_compile_contract;
  end;

procedure TTestCase_AtomicContract.Test_api_compile_contract;
var
  i32, exp32: Int32;
  u32, expu32: UInt32;
  p, expP: Pointer;
  rP: Pointer;
  f: atomic_flag_t;
  tp, expTp: atomic_tagged_ptr_t;
  tag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
  nextTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};

  r32: Int32;
  ru32: UInt32;

  {$IFDEF CPU64}
  pi, expPi: PtrInt;
  pu, expPu: PtrUInt;
  {$ENDIF}

  {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
  i64, exp64: Int64;
  u64, expu64: UInt64;
  r64: Int64;
  ru64: UInt64;
  {$ENDIF}

  ok: Boolean;
  _ignored: Int32;
begin
  // cpu + fences
  cpu_pause;
  atomic_thread_fence(mo_seq_cst);

  // lock-free query
  ok := atomic_is_lock_free_32;
  ok := ok and atomic_is_lock_free_ptr;
  {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
  ok := ok and atomic_is_lock_free_64;
  {$ENDIF}

  // atomic_flag
  f := 0;
  ok := atomic_flag_test_and_set(f);
  ok := atomic_flag_test(f);
  atomic_flag_clear(f);

  // 32-bit load/store/exchange
  i32 := 0;
  atomic_store(i32, 1);
  atomic_store(i32, 2, mo_relaxed);
  r32 := atomic_load(i32);
  r32 := atomic_load(i32, mo_acquire);
  r32 := atomic_exchange(i32, 3);
  r32 := atomic_exchange(i32, 4, mo_seq_cst);

  u32 := 0;
  atomic_store(u32, 1);
  atomic_store(u32, 2, mo_relaxed);
  ru32 := atomic_load(u32);
  ru32 := atomic_load(u32, mo_acquire);
  ru32 := atomic_exchange(u32, 3);
  ru32 := atomic_exchange(u32, 4, mo_seq_cst);

  // pointer load/store/exchange
  p := nil;
  atomic_store(p, Pointer(PtrUInt(16)));
  atomic_store(p, Pointer(PtrUInt(32)), mo_release);
  rP := atomic_load(p);
  rP := atomic_load(p, mo_acquire);
  rP := atomic_exchange(p, Pointer(PtrUInt(64)));
  rP := atomic_exchange(p, Pointer(PtrUInt(128)), mo_seq_cst);

  // CAS (basic + strong/weak, with and without memory orders)
  exp32 := 4;
  ok := atomic_compare_exchange(i32, exp32, 5);
  exp32 := 5;
  ok := atomic_compare_exchange_strong(i32, exp32, 6);
  exp32 := 6;
  ok := atomic_compare_exchange_strong(i32, exp32, 7, mo_acq_rel, mo_acquire);
  exp32 := 7;
  ok := atomic_compare_exchange_weak(i32, exp32, 8);
  exp32 := 8;
  ok := atomic_compare_exchange_weak(i32, exp32, 9, mo_acq_rel, mo_acquire);

  expu32 := 4;
  ok := atomic_compare_exchange(u32, expu32, 5);
  expu32 := 5;
  ok := atomic_compare_exchange_strong(u32, expu32, 6);
  expu32 := 6;
  ok := atomic_compare_exchange_strong(u32, expu32, 7, mo_acq_rel, mo_acquire);
  expu32 := 7;
  ok := atomic_compare_exchange_weak(u32, expu32, 8);
  expu32 := 8;
  ok := atomic_compare_exchange_weak(u32, expu32, 9, mo_acq_rel, mo_acquire);

  expP := rP;
  ok := atomic_compare_exchange(p, expP, Pointer(PtrUInt(1)));
  expP := p;
  ok := atomic_compare_exchange_strong(p, expP, Pointer(PtrUInt(2)));
  expP := p;
  ok := atomic_compare_exchange_weak(p, expP, Pointer(PtrUInt(3)));

  // increment/decrement (integral only)
  r32 := atomic_increment(i32);
  r32 := atomic_decrement(i32);
  ru32 := atomic_increment(u32);
  ru32 := atomic_decrement(u32);

  {$IFDEF CPU64}
  // PtrInt/PtrUInt overloads are CPU64-only in fafafa.core.atomic
  pi := 0; expPi := 0;
  atomic_store(pi, 1);
  r32 := Int32(atomic_load(pi));
  ok := atomic_compare_exchange_strong(pi, expPi, 2);
  ok := atomic_compare_exchange_strong(pi, expPi, 3, mo_acq_rel, mo_acquire);
  ok := atomic_compare_exchange_weak(pi, expPi, 4);
  ok := atomic_compare_exchange_weak(pi, expPi, 5, mo_acq_rel, mo_acquire);
  pi := atomic_fetch_add(pi, 1);
  pi := atomic_fetch_sub(pi, 1);
  pi := atomic_fetch_and(pi, 1);
  pi := atomic_fetch_or(pi, 1);
  pi := atomic_fetch_xor(pi, 1);
  pi := atomic_increment(pi);
  pi := atomic_decrement(pi);

  pu := 0; expPu := 0;
  atomic_store(pu, 1);
  ru32 := UInt32(atomic_load(pu));
  ok := atomic_compare_exchange_strong(pu, expPu, 2);
  ok := atomic_compare_exchange_strong(pu, expPu, 3, mo_acq_rel, mo_acquire);
  ok := atomic_compare_exchange_weak(pu, expPu, 4);
  ok := atomic_compare_exchange_weak(pu, expPu, 5, mo_acq_rel, mo_acquire);
  pu := atomic_fetch_add(pu, 1);
  pu := atomic_fetch_sub(pu, 1);
  pu := atomic_fetch_and(pu, 1);
  pu := atomic_fetch_or(pu, 1);
  pu := atomic_fetch_xor(pu, 1);
  pu := atomic_increment(pu);
  pu := atomic_decrement(pu);
  {$ENDIF}

  // fetch_add/sub (32-bit + pointer)
  r32 := atomic_fetch_add(i32, 1);
  r32 := atomic_fetch_add(i32, 1, mo_acq_rel);
  r32 := atomic_fetch_sub(i32, 1);
  r32 := atomic_fetch_sub(i32, 1, mo_acq_rel);

  ru32 := atomic_fetch_add(u32, 1);
  ru32 := atomic_fetch_add(u32, 1, mo_acq_rel);
  ru32 := atomic_fetch_sub(u32, 1);
  ru32 := atomic_fetch_sub(u32, 1, mo_acq_rel);

  // Pointer arithmetic is only supported via byte offsets in v3 main API.
  rP := atomic_fetch_add(p, PtrInt(8));
  rP := atomic_fetch_sub(p, PtrInt(8));

  // fetch_and/or/xor (32-bit)
  r32 := atomic_fetch_and(i32, 1);
  r32 := atomic_fetch_and(i32, 1, mo_acq_rel);
  r32 := atomic_fetch_or(i32, 1);
  r32 := atomic_fetch_or(i32, 1, mo_acq_rel);
  r32 := atomic_fetch_xor(i32, 1);
  r32 := atomic_fetch_xor(i32, 1, mo_acq_rel);

  ru32 := atomic_fetch_and(u32, 1);
  ru32 := atomic_fetch_and(u32, 1, mo_acq_rel);
  ru32 := atomic_fetch_or(u32, 1);
  ru32 := atomic_fetch_or(u32, 1, mo_acq_rel);
  ru32 := atomic_fetch_xor(u32, 1);
  ru32 := atomic_fetch_xor(u32, 1, mo_acq_rel);

  // fetch_max/min/nand (phase 3)
  _ignored := atomic_fetch_max(i32, 1);
  _ignored := atomic_fetch_min(i32, 1, mo_seq_cst);
  _ignored := atomic_fetch_nand(i32, 1);

  {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
  // 64-bit API surface (x86 32-bit also supports these)
  i64 := 0;
  atomic_store_64(i64, 1);
  atomic_store_64(i64, 2, mo_release);
  r64 := atomic_load_64(i64);
  r64 := atomic_load_64(i64, mo_acquire);
  r64 := atomic_exchange_64(i64, 3);
  r64 := atomic_exchange_64(i64, 4, mo_seq_cst);

  u64 := 0;
  atomic_store_64(u64, 1);
  atomic_store_64(u64, 2, mo_release);
  ru64 := atomic_load_64(u64);
  ru64 := atomic_load_64(u64, mo_acquire);
  ru64 := atomic_exchange_64(u64, 3);
  ru64 := atomic_exchange_64(u64, 4, mo_seq_cst);

  exp64 := 4;
  ok := atomic_compare_exchange_64(i64, exp64, 5);
  exp64 := 5;
  ok := atomic_compare_exchange_strong_64(i64, exp64, 6);
  exp64 := 6;
  ok := atomic_compare_exchange_strong_64(i64, exp64, 7, mo_acq_rel, mo_acquire);
  exp64 := 7;
  ok := atomic_compare_exchange_weak_64(i64, exp64, 8);
  exp64 := 8;
  ok := atomic_compare_exchange_weak_64(i64, exp64, 9, mo_acq_rel, mo_acquire);

  expu64 := 4;
  ok := atomic_compare_exchange_64(u64, expu64, 5);
  expu64 := 5;
  ok := atomic_compare_exchange_strong_64(u64, expu64, 6);
  expu64 := 6;
  ok := atomic_compare_exchange_strong_64(u64, expu64, 7, mo_acq_rel, mo_acquire);
  expu64 := 7;
  ok := atomic_compare_exchange_weak_64(u64, expu64, 8);
  expu64 := 8;
  ok := atomic_compare_exchange_weak_64(u64, expu64, 9, mo_acq_rel, mo_acquire);

  r64 := atomic_fetch_add_64(i64, 1);
  r64 := atomic_fetch_add_64(i64, 1, mo_acq_rel);
  r64 := atomic_fetch_sub_64(i64, 1);
  r64 := atomic_fetch_sub_64(i64, 1, mo_acq_rel);
  r64 := atomic_fetch_and_64(i64, 1);
  r64 := atomic_fetch_and_64(i64, 1, mo_acq_rel);
  r64 := atomic_fetch_or_64(i64, 1);
  r64 := atomic_fetch_or_64(i64, 1, mo_acq_rel);
  r64 := atomic_fetch_xor_64(i64, 1);
  r64 := atomic_fetch_xor_64(i64, 1, mo_acq_rel);

  ru64 := atomic_fetch_add_64(u64, 1);
  ru64 := atomic_fetch_add_64(u64, 1, mo_acq_rel);
  ru64 := atomic_fetch_sub_64(u64, 1);
  ru64 := atomic_fetch_sub_64(u64, 1, mo_acq_rel);
  ru64 := atomic_fetch_and_64(u64, 1);
  ru64 := atomic_fetch_and_64(u64, 1, mo_acq_rel);
  ru64 := atomic_fetch_or_64(u64, 1);
  ru64 := atomic_fetch_or_64(u64, 1, mo_acq_rel);
  ru64 := atomic_fetch_xor_64(u64, 1);
  ru64 := atomic_fetch_xor_64(u64, 1, mo_acq_rel);

  r64 := atomic_fetch_max_64(i64, 1);
  r64 := atomic_fetch_min_64(i64, 1, mo_seq_cst);
  r64 := atomic_fetch_nand_64(i64, 1);

  r64 := atomic_increment_64(i64);
  r64 := atomic_decrement_64(i64);
  ru64 := atomic_increment_64(u64);
  ru64 := atomic_decrement_64(u64);
  {$ENDIF}

  // tagged pointer API
  tag := 1;
  tp := atomic_tagged_ptr(p, tag);
  nextTag := atomic_tagged_ptr_next(tp);
  rP := atomic_tagged_ptr_get_ptr(tp);
  tag := atomic_tagged_ptr_get_tag(tp);

  // Default + order-aware load/store
  tp := atomic_tagged_ptr_load(tp);
  tp := atomic_tagged_ptr_load(tp, mo_acquire);
  atomic_tagged_ptr_store(tp, tp);
  atomic_tagged_ptr_store(tp, tp, mo_release);

  // Default + order-aware CAS/exchange
  expTp := tp;
  ok := atomic_tagged_ptr_compare_exchange_strong(tp, expTp, tp);
  expTp := tp;
  ok := atomic_tagged_ptr_compare_exchange_strong(tp, expTp, tp, mo_acq_rel, mo_acquire);

  expTp := tp;
  ok := atomic_tagged_ptr_compare_exchange_weak(tp, expTp, tp);
  expTp := tp;
  ok := atomic_tagged_ptr_compare_exchange_weak(tp, expTp, tp, mo_acq_rel, mo_acquire);

  tp := atomic_tagged_ptr_exchange(tp, tp);
  tp := atomic_tagged_ptr_exchange(tp, tp, mo_seq_cst);

  atomic_tagged_ptr_update(tp, nil);
  atomic_tagged_ptr_update_tag(tp, nextTag);

  // Silence any unused-variable warnings in stricter builds.
  AssertTrue(ok or True);
end;

procedure RegisterAtomicContractTests;
begin
  RegisterTest('fafafa.core.atomic.Contract', TTestCase_AtomicContract);
end;

end.
