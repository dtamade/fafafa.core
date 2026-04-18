unit Test_fafafa.core.atomic;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic,
  fafafa.core.atomic.compat;

procedure RegisterAtomicTests;

implementation
 {$PUSH}
 {$WARN 4055 OFF}

// 全局函数族测试
// 位操作 RMW、指针字节加减、atomic_flag、is_lock_free、tagged_ptr

type
  TTestCase_Global = class(TTestCase)
  published
    // RMW 位操作
    procedure Test_atomic_fetch_and_32;
    procedure Test_atomic_fetch_or_32;
    procedure Test_atomic_fetch_xor_32;
    {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
    procedure Test_atomic_fetch_and_64;
    procedure Test_atomic_fetch_or_64;
    procedure Test_atomic_fetch_xor_64;
    {$ENDIF}

    // 指针加减
    procedure Test_atomic_fetch_add_ptr_bytes;
    procedure Test_atomic_fetch_sub_ptr_bytes;

    // 基础 load/store/exchange/compare/inc/dec
    procedure Test_atomic_load_store_32;
    procedure Test_atomic_exchange_ptr;
    procedure Test_atomic_compare_exchange_strong_32;
    procedure Test_atomic_compare_exchange_weak_32;
    procedure Test_atomic_increment_decrement_32;
    {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
    procedure Test_atomic_load_store_64;
    procedure Test_atomic_exchange_64;
    procedure Test_atomic_compare_exchange_strong_64;
    procedure Test_atomic_compare_exchange_weak_64;
    procedure Test_atomic_increment_decrement_64;
    {$ENDIF}

    // 其它
    procedure Test_atomic_flag;
    procedure Test_atomic_is_lock_free;
    procedure Test_atomic_thread_fence_smoke;

    // 更多覆盖
    procedure Test_atomic_load_store_orders_32;
    procedure Test_atomic_load_store_orders_ptr;
    {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
    procedure Test_atomic_load_store_orders_64;
    {$ENDIF}
    procedure Test_atomic_compare_exchange_strong_ptr;
    procedure Test_atomic_compare_exchange_weak_ptr;
    procedure Test_atomic_compare_exchange_strong_ptrint;
    procedure Test_atomic_fetch_sub_ptr_bytes_variant;
    procedure Test_atomic_uint32_fetch_ops;
    procedure Test_atomic_bitmask_variants_32;
    procedure Test_atomic_fetch_add_sub_boundaries_32;
    {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
    procedure Test_atomic_fetch_add_sub_boundaries_64;
    procedure Test_atomic_uint64_fetch_ops;
    {$ENDIF}

    procedure Test_ptruint_pointer_fetch_smoke;
    {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
    procedure Test_uint64_add_sub_fetch_paths;
    procedure Test_uint64_bitwise_boundary_extremes;
    {$ENDIF}

    procedure Test_compare_exchange_expected_writeback_consistency;
    procedure Test_pointer_fetch_add_negative_boundary;
    procedure Test_tagged_ptr_weak_and_exchange;
    procedure Test_tagged_ptr_round_trip_allocated_ptr;
    procedure Test_tagged_ptr_tag_wraparound;
    procedure Test_atomic_compare_exchange_loops_32;
  end;

  TTestCase_Concurrent = class(TTestCase)
  published
    procedure Test_concurrent_fetch_add_32;
    procedure Test_concurrent_bit_or_32;
    procedure Test_concurrent_tagged_ptr_increment_tag;
    procedure Test_concurrent_cas_increment_32;
    procedure Test_thread_fence_visibility;
    procedure Test_seq_cst_total_order_three_threads;
    // ✅ Phase 6: Litmus 测试 - 内存序正确性验证
    procedure Test_litmus_message_passing;      // MP: release/acquire 同步
    procedure Test_litmus_store_buffering;      // SB: seq_cst 全序
    procedure Test_litmus_load_buffering;       // LB: acquire/release 防止重排
    procedure Test_litmus_independent_reads;    // IRIW: 独立读观测一致性
  end;

// ———— Helpers to bridge PtrInt/PtrUInt on 32-bit without overloading conflicts ————

function atomic_fetch_and_ptr(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; inline;
{$IFDEF CPU64}
begin
  Result := atomic_fetch_and(aObj, aArg);
end;
{$ELSE}
var
  LObj32: UInt32 absolute aObj;
  LArg32: UInt32 absolute aArg;
begin
  Result := PtrUInt(atomic_fetch_and(LObj32, LArg32));
end;
{$ENDIF}

function atomic_fetch_or_ptr(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; inline;
{$IFDEF CPU64}
begin
  Result := atomic_fetch_or(aObj, aArg);
end;
{$ELSE}
var
  LObj32: UInt32 absolute aObj;
  LArg32: UInt32 absolute aArg;
begin
  Result := PtrUInt(atomic_fetch_or(LObj32, LArg32));
end;
{$ENDIF}

function atomic_fetch_xor_ptr(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; inline;
{$IFDEF CPU64}
begin
  Result := atomic_fetch_xor(aObj, aArg);
end;
{$ELSE}
var
  LObj32: UInt32 absolute aObj;
  LArg32: UInt32 absolute aArg;
begin
  Result := PtrUInt(atomic_fetch_xor(LObj32, LArg32));
end;
{$ENDIF}

function cas_strong_ptrint(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean; inline;
{$IFDEF CPU64}
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired);
end;
{$ELSE}
var
  LObj32: Int32 absolute aObj;
  LExp32: Int32 absolute aExpected;
  LDes32: Int32 absolute aDesired;
begin
  Result := atomic_compare_exchange_strong(LObj32, LExp32, LDes32);
end;
{$ENDIF}

function cas_strong_ptruint(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean; inline;
{$IFDEF CPU64}
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired);
end;
{$ELSE}
var
  LObj32: UInt32 absolute aObj;
  LExp32: UInt32 absolute aExpected;
  LDes32: UInt32 absolute aDesired;
begin
  Result := atomic_compare_exchange_strong(LObj32, LExp32, LDes32);
end;
{$ENDIF}

// ———— Stress helpers (opt-in via env) ————
//
// Default test suite stays fast.
// Set env FAFAFA_ATOMIC_STRESS=1 to enable longer runs.
// Optional tuning:
//   FAFAFA_ATOMIC_CONCURRENT_FACTOR (default 5)
//   FAFAFA_ATOMIC_LITMUS_FACTOR     (default 20)
//   FAFAFA_ATOMIC_CONCURRENT_NPER   (override per-thread loop count)
//   FAFAFA_ATOMIC_LITMUS_ITERS      (override MP/SB/LB iters)
//   FAFAFA_ATOMIC_LITMUS_IRIW_ITERS (override IRIW iters)

function EnvBool(const Name: string): Boolean;
var
  s: string;
begin
  s := Trim(GetEnvironmentVariable(Name));
  if s = '' then Exit(False);
  s := LowerCase(s);
  Result := (s <> '0') and (s <> 'false') and (s <> 'no') and (s <> 'off');
end;

function EnvPosInt(const Name: string; DefaultValue: Integer): Integer;
var
  s: string;
  v: LongInt;
begin
  s := Trim(GetEnvironmentVariable(Name));
  if (s <> '') and TryStrToInt(s, v) and (v > 0) then
    Exit(v);
  Result := DefaultValue;
end;

function AtomicStressEnabled: Boolean;
begin
  Result := EnvBool('FAFAFA_ATOMIC_STRESS');
end;

function AtomicConcurrentFactor: Integer;
begin
  if AtomicStressEnabled then
    Result := EnvPosInt('FAFAFA_ATOMIC_CONCURRENT_FACTOR', 5)
  else
    Result := 1;
end;

function AtomicLitmusFactor: Integer;
begin
  if AtomicStressEnabled then
    Result := EnvPosInt('FAFAFA_ATOMIC_LITMUS_FACTOR', 20)
  else
    Result := 1;
end;

function ConcurrentNPer(DefaultValue: Integer): Integer;
var
  v: Integer;
begin
  v := EnvPosInt('FAFAFA_ATOMIC_CONCURRENT_NPER', 0);
  if v > 0 then Exit(v);
  Result := DefaultValue * AtomicConcurrentFactor;
end;

function LitmusIters(DefaultValue: Integer): Integer;
var
  v: Integer;
begin
  v := EnvPosInt('FAFAFA_ATOMIC_LITMUS_ITERS', 0);
  if v > 0 then Exit(v);
  Result := DefaultValue * AtomicLitmusFactor;
end;

function LitmusIriwIters(DefaultValue: Integer): Integer;
var
  v: Integer;
begin
  v := EnvPosInt('FAFAFA_ATOMIC_LITMUS_IRIW_ITERS', 0);
  if v > 0 then Exit(v);
  Result := DefaultValue * AtomicLitmusFactor;
end;

// ———— Tests ————

procedure TTestCase_Global.Test_atomic_fetch_and_32;
var i, r: Int32;
begin
  i := $0F0F0F0F;
  r := atomic_fetch_and(i, $00F0F0F0);
  AssertEquals($0F0F0F0F, r);
  AssertEquals(0, i and $FF00FF0F); // 剩余位为0
end;

procedure TTestCase_Global.Test_atomic_fetch_or_32;
var i, r: Int32;
begin
  i := $000F0F00;
  r := atomic_fetch_or(i, $000000F0);
  AssertEquals($000F0F00, r);
  AssertEquals($000F0FF0, i);
end;

procedure TTestCase_Global.Test_atomic_fetch_xor_32;
var i, r: Int32;
begin
  i := $000F0FF0;
  r := atomic_fetch_xor(i, $0000000F);
  AssertEquals($000F0FF0, r);
  AssertEquals($000F0FFF, i);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_atomic_fetch_and_64;
var i, r: Int64;
begin
  i := $00FF00FF00FF00FF;
  r := atomic_fetch_and_64(i, $0F0F0F0F0F0F0F0F);
  AssertEquals(QWord($00FF00FF00FF00FF), QWord(r));
  AssertEquals(QWord($000F000F000F000F), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_or_64;
var i, r: Int64;
begin
  i := $000F000F000F000F;
  r := atomic_fetch_or_64(i, $F0);
  AssertEquals(QWord($000F000F000F000F), QWord(r));
  AssertEquals(QWord($000F000F000F00FF), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_xor_64;
var i, r: Int64;
begin
  i := $000F000F000F00FF;
  r := atomic_fetch_xor_64(i, $0F);
  AssertEquals(QWord($000F000F000F00FF), QWord(r));
  AssertEquals(QWord($000F000F000F00F0), QWord(i));
end;
{$ENDIF}

procedure TTestCase_Global.Test_atomic_fetch_add_ptr_bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1000));
  oldp := atomic_fetch_add(p, PtrInt(16));
  AssertTrue(PtrUInt(oldp) = 1000);
  AssertTrue(PtrUInt(p) = 1016);
end;

procedure TTestCase_Global.Test_atomic_fetch_sub_ptr_bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1016));
  oldp := atomic_fetch_add(p, -PtrInt(8));
  AssertTrue(PtrUInt(oldp) = 1016);
  AssertTrue(PtrUInt(p) = 1008);
end;

procedure TTestCase_Global.Test_atomic_flag;
var f: atomic_flag_t;
begin
  f := 0;
  AssertFalse(atomic_flag_test_and_set(f));
  AssertTrue(atomic_flag_test_and_set(f));
  atomic_flag_clear(f);
  AssertFalse(atomic_flag_test_and_set(f));
end;

procedure TTestCase_Global.Test_atomic_load_store_32;
var v: Int32;
begin
  v := 0;
  atomic_store(v, 123);
  AssertEquals(123, atomic_load(v));
end;

procedure TTestCase_Global.Test_atomic_exchange_ptr;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(100));
  oldp := atomic_exchange(p, Pointer(PtrUInt(200)));
  AssertTrue(PtrUInt(oldp) = 100);
  AssertTrue(PtrUInt(p) = 200);
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_32;
var v, exp: Int32;
begin
  v := 10; exp := 10;
  AssertTrue(atomic_compare_exchange_strong(v, exp, 20));
  AssertEquals(20, v);
  exp := 10;
  AssertFalse(atomic_compare_exchange_strong(v, exp, 30));
  AssertEquals(20, v);
  AssertEquals(20, exp);
end;

procedure TTestCase_Global.Test_atomic_increment_decrement_32;
var v: Int32;
begin
  v := 0;
  AssertEquals(0, atomic_fetch_add(v, 0));
  AssertEquals(0, v);
  AssertEquals(0, atomic_fetch_add(v, 1));
  AssertEquals(1, v);
  AssertEquals(1, atomic_fetch_add(v, 2));
  AssertEquals(3, v);
  AssertEquals(3, atomic_fetch_sub(v, 1));
  AssertEquals(2, v);
  AssertEquals(3, atomic_increment(v));
  AssertEquals(3, v);
  AssertEquals(2, atomic_decrement(v));
  AssertEquals(2, v);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_atomic_load_store_64;
var v: Int64;
begin
  v := 0;
  atomic_store_64(v, 123);
  AssertEquals(QWord(123), QWord(atomic_load_64(v)));
end;

procedure TTestCase_Global.Test_atomic_exchange_64;
var v, oldv: Int64;
begin
  v := 100; oldv := atomic_exchange_64(v, 200);
  AssertEquals(QWord(100), QWord(oldv));
  AssertEquals(QWord(200), QWord(v));
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_64;
var v, exp: Int64;
begin
  v := 10; exp := 10;
  AssertTrue(atomic_compare_exchange_strong_64(v, exp, 20));
  AssertEquals(QWord(20), QWord(v));
  exp := 10;
  AssertFalse(atomic_compare_exchange_strong_64(v, exp, 30));
  AssertEquals(QWord(20), QWord(v));
  AssertEquals(QWord(20), QWord(exp));
end;

// ✅ P0-3 修复: 添加缺失的 Test_atomic_compare_exchange_weak_64 实现
procedure TTestCase_Global.Test_atomic_compare_exchange_weak_64;
var v, exp: Int64;
begin
  v := 10; exp := 10;
  // weak=strong 语义：成功路径
  AssertTrue(atomic_compare_exchange_weak_64(v, exp, 20));
  AssertEquals(QWord(20), QWord(v));
  // 失败路径：预期值不匹配时 expected 会被写回实际旧值
  exp := 10;
  AssertFalse(atomic_compare_exchange_weak_64(v, exp, 30));
  AssertEquals(QWord(20), QWord(v));
  AssertEquals(QWord(20), QWord(exp));
end;
{$ENDIF}


procedure TTestCase_Global.Test_atomic_compare_exchange_weak_32;
var v, exp: Int32;
begin
  v := 10; exp := 10;
  // weak=strong 语义：成功路径
  AssertTrue(atomic_compare_exchange_weak(v, exp, 20));
  AssertEquals(20, v);
  // 失败路径：预期值不匹配时 expected 会被写回实际旧值
  exp := 10;
  AssertFalse(atomic_compare_exchange_weak(v, exp, 30));
  AssertEquals(20, v);
  AssertEquals(20, exp);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_atomic_increment_decrement_64;
var v: Int64;
begin
  v := 0;
  AssertEquals(QWord(0), QWord(atomic_fetch_add_64(v, 0)));
  AssertEquals(QWord(0), QWord(v));
  AssertEquals(QWord(0), QWord(atomic_fetch_add_64(v, 1)));
  AssertEquals(QWord(1), QWord(v));
  AssertEquals(QWord(1), QWord(atomic_fetch_add_64(v, 2)));
  AssertEquals(QWord(3), QWord(v));
  AssertEquals(QWord(3), QWord(atomic_fetch_sub_64(v, 1)));
  AssertEquals(QWord(2), QWord(v));
  AssertEquals(QWord(3), QWord(atomic_increment_64(v)));
  AssertEquals(QWord(3), QWord(v));
  AssertEquals(QWord(2), QWord(atomic_decrement_64(v)));
  AssertEquals(QWord(2), QWord(v));
end;
{$ENDIF}

procedure TTestCase_Global.Test_atomic_load_store_orders_32;
var v: Int32;
begin
  v := 0;
  atomic_store(v, 1, mo_relaxed);
  AssertEquals(1, atomic_load(v, mo_relaxed));
  atomic_store(v, 2, mo_release);
  AssertEquals(2, atomic_load(v, mo_acquire));
  atomic_store(v, 3, mo_seq_cst);
  AssertEquals(3, atomic_load(v, mo_seq_cst));
end;

procedure TTestCase_Global.Test_atomic_load_store_orders_ptr;
var p: Pointer;
begin
  p := nil;
  atomic_store(p, Pointer(PtrUInt(1)), mo_release);
  AssertTrue(PtrUInt(atomic_load(p, mo_acquire)) = 1);
  atomic_store(p, Pointer(PtrUInt(2)), mo_seq_cst);
  AssertTrue(PtrUInt(atomic_load(p, mo_seq_cst)) = 2);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_atomic_load_store_orders_64;
var v: Int64;
begin
  v := 0;
  atomic_store_64(v, 1, mo_relaxed);
  AssertEquals(QWord(1), QWord(atomic_load_64(v, mo_relaxed)));
  atomic_store_64(v, 2, mo_release);
  AssertEquals(QWord(2), QWord(atomic_load_64(v, mo_acquire)));
  atomic_store_64(v, 3, mo_seq_cst);
  AssertEquals(QWord(3), QWord(atomic_load_64(v, mo_seq_cst)));
end;
{$ENDIF}

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_ptr;
var p, exp, des: Pointer;
begin
  p := nil; exp := nil; des := Pointer(PtrUInt(123));
  AssertTrue(atomic_compare_exchange_strong(p, exp, des));
  AssertTrue(PtrUInt(p) = 123);
  exp := nil;
  AssertFalse(atomic_compare_exchange_strong(p, exp, Pointer(PtrUInt(456))));
  AssertTrue(PtrUInt(p) = 123);
  AssertTrue(PtrUInt(exp) = 123);
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_weak_ptr;
var p, exp, des: Pointer;
begin
  p := nil; exp := nil; des := Pointer(PtrUInt(123));
  AssertTrue(atomic_compare_exchange_weak(p, exp, des));
  AssertTrue(PtrUInt(p) = 123);
  exp := nil;
  AssertFalse(atomic_compare_exchange_weak(p, exp, Pointer(PtrUInt(456))));
  AssertTrue(PtrUInt(p) = 123);
  AssertTrue(PtrUInt(exp) = 123);
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_ptrint;
var v, exp: PtrInt;
begin
  v := 10; exp := 10;
  AssertTrue(cas_strong_ptrint(v, exp, 20));
  AssertEquals(20, v);
  exp := 10;
  AssertFalse(cas_strong_ptrint(v, exp, 30));
  AssertEquals(20, v);
  AssertEquals(20, exp);
end;

procedure TTestCase_Global.Test_atomic_fetch_sub_ptr_bytes_variant;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1008));
  oldp := atomic_fetch_sub(p, PtrInt(8));
  AssertTrue(PtrUInt(oldp) = 1008);
  AssertTrue(PtrUInt(p) = 1000);
end;

procedure TTestCase_Global.Test_atomic_uint32_fetch_ops;
var u, r: UInt32;
begin
  u := $FFFF0000;
  r := atomic_fetch_and(u, $0F0F0F0F);
  AssertEquals($FFFF0000, r);
  AssertEquals($0F0F0000, u);
  r := atomic_fetch_or(u, $F0);
  AssertEquals($0F0F0000, r);
  AssertEquals($0F0F00F0, u);
  r := atomic_fetch_xor(u, $FF);
  AssertEquals($0F0F00F0, r);
  AssertEquals($0F0F000F, u);
end;
procedure TTestCase_Global.Test_atomic_bitmask_variants_32;
var v, r: UInt32;
begin
  v := 0; r := atomic_fetch_and(v, UInt32($FFFFFFFF)); AssertEquals(UInt32(0), r); AssertEquals(UInt32(0), v);
  v := UInt32($FFFFFFFF); r := atomic_fetch_and(v, UInt32(0)); AssertEquals(UInt32($FFFFFFFF), r); AssertEquals(UInt32(0), v);
  v := UInt32($80000000); r := atomic_fetch_or(v, UInt32($7FFFFFFF)); AssertEquals(UInt32($80000000), r); AssertEquals(UInt32($FFFFFFFF), v);
  v := UInt32($FFFFFFFF); r := atomic_fetch_xor(v, UInt32($FFFFFFFF)); AssertEquals(UInt32($FFFFFFFF), r); AssertEquals(UInt32(0), v);
end;

procedure TTestCase_Global.Test_atomic_fetch_add_sub_boundaries_32;
var v, old: Int32;
begin
  v := High(Int32)-1; old := atomic_fetch_add(v, 1); AssertEquals(High(Int32)-1, old); AssertEquals(High(Int32), v);
  old := atomic_fetch_sub(v, 1); AssertEquals(High(Int32), old); AssertEquals(High(Int32)-1, v);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_atomic_fetch_add_sub_boundaries_64;
var v: Int64; old: Int64;
begin
  v := High(Int64)-1; old := atomic_fetch_add_64(v, 1); AssertEquals(QWord(High(Int64)-1), QWord(old)); AssertEquals(QWord(High(Int64)), QWord(v));
  old := atomic_fetch_sub_64(v, 1); AssertEquals(QWord(High(Int64)), QWord(old)); AssertEquals(QWord(High(Int64)-1), QWord(v));
end;

procedure TTestCase_Global.Test_atomic_uint64_fetch_ops;
var u, r: UInt64;
begin
  u := QWord($FFFF000000000000); r := atomic_fetch_and_64(u, QWord($0F0F0F0F0F0F0F0F)); AssertEquals(QWord($FFFF000000000000), QWord(r)); AssertEquals(QWord($0F0F000000000000), QWord(u));
  r := atomic_fetch_or_64(u, QWord($F0)); AssertEquals(QWord($0F0F000000000000), QWord(r)); AssertEquals(QWord($0F0F0000000000F0), QWord(u));
  r := atomic_fetch_xor_64(u, QWord($FF)); AssertEquals(QWord($0F0F0000000000F0), QWord(r)); AssertEquals(QWord($0F0F00000000000F), QWord(u));
end;
{$ENDIF}


procedure TTestCase_Global.Test_atomic_thread_fence_smoke;
var x, y: Int32;
begin
  x := 0; y := 0;
  // 这里仅做可编译与基本序语义走通的冒烟测试
  atomic_store(x, 1, mo_release);
  atomic_thread_fence(mo_acquire);
  y := atomic_load(x, mo_acquire);
  AssertTrue(y >= 0);
end;

procedure TTestCase_Global.Test_atomic_is_lock_free;
begin
  AssertTrue(atomic_is_lock_free_32);
  {$IFDEF CPU64}AssertTrue(atomic_is_lock_free_64);{$ENDIF}
  AssertTrue(atomic_is_lock_free_ptr);
end;

procedure TTestCase_Global.Test_tagged_ptr_weak_and_exchange;
var tp, prev, exp, des: atomic_tagged_ptr_t;
begin
  tp := atomic_tagged_ptr(nil, 1);
  exp := tp;
  des := atomic_tagged_ptr(nil, 2);
  AssertTrue(atomic_tagged_ptr_compare_exchange_weak(tp, exp, des));
  AssertEquals(2, Integer(atomic_tagged_ptr_get_tag(tp)));
  prev := atomic_tagged_ptr_exchange(tp, atomic_tagged_ptr(nil, 3));
  AssertEquals(2, Integer(atomic_tagged_ptr_get_tag(prev)));
  AssertEquals(3, Integer(atomic_tagged_ptr_get_tag(tp)));
end;

procedure TTestCase_Global.Test_tagged_ptr_round_trip_allocated_ptr;
var
  p: Pointer;
  tp: atomic_tagged_ptr_t;
begin
  // 仅验证打包/解包不破坏指针值（不解引用）。
  // - x86_64: 高 16 位 tag
  // - 其他平台: 低 TAG_BITS 位 tag（要求指针对齐）
  GetMem(p, 16);
  try
    tp := atomic_tagged_ptr(p, 1);
    AssertTrue(atomic_tagged_ptr_get_ptr(tp) = p);
    AssertEquals(1, Integer(atomic_tagged_ptr_get_tag(tp)));
  finally
    FreeMem(p);
  end;
end;

procedure TTestCase_Global.Test_tagged_ptr_tag_wraparound;
var
  tp: atomic_tagged_ptr_t;
  i: UInt32;
  maxTag, last: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
  // 从接近最大 tag 开始，触发一次回卷。
  // maxTag 的定义取决于平台/实现（x86_64 为 $FFFF；低位 tag 则为 TAG_MASK）。
  maxTag := atomic_tagged_ptr_get_tag(atomic_tagged_ptr(nil, {$IFDEF CPU64}UInt16($FFFF){$ELSE}UInt32($FFFFFFFF){$ENDIF}));
  tp := atomic_tagged_ptr(nil, maxTag - 1);

  // 期望：(max-1) -> max -> 1 -> 2
  for i := 1 to 3 do
    tp := atomic_tagged_ptr(atomic_tagged_ptr_get_ptr(tp), atomic_tagged_ptr_next(tp));

  last := atomic_tagged_ptr_get_tag(tp);
  AssertEquals(Integer(2), Integer(last));
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_loops_32;
var v, exp: Int32; k, succCount, failCount: Integer;
begin
  v := 0; succCount := 0; failCount := 0;
  // 连续成功
  for k := 1 to 10 do begin
    exp := k-1;
    if atomic_compare_exchange_weak(v, exp, k) then Inc(succCount) else Inc(failCount);
  end;
  AssertEquals(10, succCount);
  AssertEquals(0, failCount);
  // 连续失败，expected 应写回旧值
  exp := -1;
  AssertFalse(atomic_compare_exchange_strong(v, exp, 100));
  AssertEquals(10, v);
  AssertEquals(10, exp);
end;

procedure RegisterAtomicTests;
begin
  RegisterTest('fafafa.core.atomic.Global', TTestCase_Global);
  RegisterTest('fafafa.core.atomic.Concurrent', TTestCase_Concurrent);
end;

type
  TInc32Thread = class(TThread)
  private
    FCounter: PInt32;
    FNPer: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Counter: Int32; NPer: Integer);
  end;

  TOr32Thread = class(TThread)
  private
    FBits: PInt32;
    FBitIndex: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Bits: Int32; BitIndex: Integer);
  end;

  TTaggedIncThread = class(TThread)
  private
    FTp: ^atomic_tagged_ptr_t;
    FNPer: Integer;
  protected
    procedure Execute; override;
  published
    // guard fields for test robustness
    // (no code, just to reserve spots to avoid accidental name collisions)
  public
    constructor CreateShared(var Tp: atomic_tagged_ptr_t; NPer: Integer);
  end;

  TCasInc32Thread = class(TThread)
  private
    FValue: PInt32;
    FNPer: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Value: Int32; NPer: Integer);
  end;

  TAtomicStore32Thread = class(TThread)
  private
    FTarget: PInt32;
    FValue: Int32;
    FOrder: memory_order_t;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Target: Int32; Value: Int32; Order: memory_order_t);
  end;

  TWaitUntilEqualsThenStore32Thread = class(TThread)
  private
    FWaitVar: PInt32;
    FWaitValue: Int32;
    FStoreVar: PInt32;
    FStoreValue: Int32;
    FOrder: memory_order_t;
    FMaxIters: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var WaitVar: Int32; WaitValue: Int32; var StoreVar: Int32; StoreValue: Int32;
      Order: memory_order_t; MaxIters: Integer);
  end;

  TWaitUntilNonZeroThenLoad32Thread = class(TThread)
  private
    FWaitVar: PInt32;
    FOutVar: PInt32;
    FOrder: memory_order_t;
    FMaxIters: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var WaitVar: Int32; var OutVar: Int32; Order: memory_order_t; MaxIters: Integer);
  end;

  TStoreThenLoad32Thread = class(TThread)
  private
    FStoreVar: PInt32;
    FStoreValue: Int32;
    FStoreOrder: memory_order_t;
    FLoadVar: PInt32;
    FLoadOrder: memory_order_t;
    FOutVar: PInt32;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var StoreVar: Int32; StoreValue: Int32; StoreOrder: memory_order_t;
      var LoadVar: Int32; LoadOrder: memory_order_t; var OutVar: Int32);
  end;

  TLoadThenStore32Thread = class(TThread)
  private
    FLoadVar: PInt32;
    FLoadOrder: memory_order_t;
    FOutVar: PInt32;
    FStoreVar: PInt32;
    FStoreValue: Int32;
    FStoreOrder: memory_order_t;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var LoadVar: Int32; LoadOrder: memory_order_t; var OutVar: Int32;
      var StoreVar: Int32; StoreValue: Int32; StoreOrder: memory_order_t);
  end;

  TLoadPair32Thread = class(TThread)
  private
    FVar1: PInt32;
    FVar2: PInt32;
    FOrder: memory_order_t;
    FOut1: PInt32;
    FOut2: PInt32;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Var1: Int32; var Var2: Int32; Order: memory_order_t; var Out1: Int32; var Out2: Int32);
  end;

  TMessagePassingWriterThread = class(TThread)
  private
    FData: PInt32;
    FFlag: PInt32;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Data: Int32; var Flag: Int32);
  end;

  TMessagePassingReaderThread = class(TThread)
  private
    FData: PInt32;
    FFlag: PInt32;
    FR1: PInt32;
    FR2: PInt32;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Data: Int32; var Flag: Int32; var R1: Int32; var R2: Int32);
  end;


procedure TTestCase_Concurrent.Test_concurrent_cas_increment_32;
const
  NThreads = 4;
  DefaultNPer = 4000;
var
  i: Integer;
  v: Int32;
  NPer: Integer;
  th: array of TCasInc32Thread = nil;
begin
  NPer := ConcurrentNPer(DefaultNPer);
  v := 0;
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TCasInc32Thread.CreateShared(v, NPer);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  AssertEquals(NThreads*NPer, v);
end;

procedure TTestCase_Concurrent.Test_thread_fence_visibility;
var x, y: Int32; writer, reader: TThread;
begin
  x := 0; y := 0;
  writer := TAtomicStore32Thread.CreateShared(x, 1, mo_release);
  reader := TWaitUntilNonZeroThenLoad32Thread.CreateShared(x, y, mo_acquire, 100000);
  writer.Start; reader.Start; writer.WaitFor; reader.WaitFor; writer.Free; reader.Free;
  AssertEquals(1, y);
end;

constructor TInc32Thread.CreateShared(var Counter: Int32; NPer: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCounter := @Counter;
  FNPer := NPer;
end;

procedure TInc32Thread.Execute;
var k: Integer;
begin
  for k := 1 to FNPer do
    atomic_fetch_add(FCounter^, 1);
end;

constructor TOr32Thread.CreateShared(var Bits: Int32; BitIndex: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FBits := @Bits;
  FBitIndex := BitIndex;
end;

procedure TOr32Thread.Execute;
begin
  atomic_fetch_or(FBits^, 1 shl FBitIndex);
end;

constructor TTaggedIncThread.CreateShared(var Tp: atomic_tagged_ptr_t; NPer: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTp := @Tp;
  FNPer := NPer;
end;

procedure TTaggedIncThread.Execute;
var k, spins: Integer; exp, des: atomic_tagged_ptr_t;
begin
  for k := 1 to FNPer do
  begin
    spins := 0;
    repeat
      exp := FTp^;
      des := atomic_tagged_ptr(atomic_tagged_ptr_get_ptr(exp), atomic_tagged_ptr_next(exp));
      Inc(spins);
      if (spins and 1023)=0 then TThread.Yield;
      if spins > 1000000 then raise Exception.Create('CAS timeout (tagged_inc)');
    until atomic_tagged_ptr_compare_exchange_weak(FTp^, exp, des);
  end;
end;

constructor TCasInc32Thread.CreateShared(var Value: Int32; NPer: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FValue := @Value;
  FNPer := NPer;
end;

procedure TCasInc32Thread.Execute;
var
  k: Integer;
  exp: Int32;
  spins: Integer;
begin
  for k := 1 to FNPer do
  begin
    spins := 0;
    repeat
      exp := FValue^;
      Inc(spins);
      if (spins and 1023)=0 then TThread.Yield;
      if spins > 1000000 then
        raise Exception.Create('CAS timeout (concurrent_cas_increment_32)');
    until atomic_compare_exchange_weak(FValue^, exp, exp + 1);
  end;
end;

constructor TAtomicStore32Thread.CreateShared(var Target: Int32; Value: Int32; Order: memory_order_t);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTarget := @Target;
  FValue := Value;
  FOrder := Order;
end;

procedure TAtomicStore32Thread.Execute;
begin
  atomic_store(FTarget^, FValue, FOrder);
end;

constructor TWaitUntilEqualsThenStore32Thread.CreateShared(var WaitVar: Int32; WaitValue: Int32;
  var StoreVar: Int32; StoreValue: Int32; Order: memory_order_t; MaxIters: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWaitVar := @WaitVar;
  FWaitValue := WaitValue;
  FStoreVar := @StoreVar;
  FStoreValue := StoreValue;
  FOrder := Order;
  FMaxIters := MaxIters;
end;

procedure TWaitUntilEqualsThenStore32Thread.Execute;
var
  k: Integer;
  v: Int32;
begin
  for k := 1 to FMaxIters do
  begin
    v := atomic_load(FWaitVar^, FOrder);
    if v = FWaitValue then
    begin
      atomic_store(FStoreVar^, FStoreValue, FOrder);
      Exit;
    end;
    if (k and 1023)=0 then TThread.Yield;
  end;
  raise Exception.Create('Wait timeout (wait_until_equals_then_store)');
end;

constructor TWaitUntilNonZeroThenLoad32Thread.CreateShared(var WaitVar: Int32; var OutVar: Int32;
  Order: memory_order_t; MaxIters: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWaitVar := @WaitVar;
  FOutVar := @OutVar;
  FOrder := Order;
  FMaxIters := MaxIters;
end;

procedure TWaitUntilNonZeroThenLoad32Thread.Execute;
var
  k: Integer;
  r: Int32;
begin
  r := 0;
  for k := 1 to FMaxIters do
  begin
    r := atomic_load(FWaitVar^, FOrder);
    if r <> 0 then Break;
    TThread.Yield;
  end;
  if r = 0 then
    raise Exception.Create('Wait timeout (wait_until_nonzero_then_load)');

  FOutVar^ := atomic_load(FWaitVar^, FOrder);
end;

constructor TStoreThenLoad32Thread.CreateShared(var StoreVar: Int32; StoreValue: Int32; StoreOrder: memory_order_t;
  var LoadVar: Int32; LoadOrder: memory_order_t; var OutVar: Int32);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FStoreVar := @StoreVar;
  FStoreValue := StoreValue;
  FStoreOrder := StoreOrder;
  FLoadVar := @LoadVar;
  FLoadOrder := LoadOrder;
  FOutVar := @OutVar;
end;

procedure TStoreThenLoad32Thread.Execute;
begin
  atomic_store(FStoreVar^, FStoreValue, FStoreOrder);
  FOutVar^ := atomic_load(FLoadVar^, FLoadOrder);
end;

constructor TLoadThenStore32Thread.CreateShared(var LoadVar: Int32; LoadOrder: memory_order_t; var OutVar: Int32;
  var StoreVar: Int32; StoreValue: Int32; StoreOrder: memory_order_t);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLoadVar := @LoadVar;
  FLoadOrder := LoadOrder;
  FOutVar := @OutVar;
  FStoreVar := @StoreVar;
  FStoreValue := StoreValue;
  FStoreOrder := StoreOrder;
end;

procedure TLoadThenStore32Thread.Execute;
begin
  FOutVar^ := atomic_load(FLoadVar^, FLoadOrder);
  atomic_store(FStoreVar^, FStoreValue, FStoreOrder);
end;

constructor TLoadPair32Thread.CreateShared(var Var1: Int32; var Var2: Int32; Order: memory_order_t;
  var Out1: Int32; var Out2: Int32);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FVar1 := @Var1;
  FVar2 := @Var2;
  FOrder := Order;
  FOut1 := @Out1;
  FOut2 := @Out2;
end;

procedure TLoadPair32Thread.Execute;
begin
  FOut1^ := atomic_load(FVar1^, FOrder);
  FOut2^ := atomic_load(FVar2^, FOrder);
end;

constructor TMessagePassingWriterThread.CreateShared(var Data: Int32; var Flag: Int32);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FData := @Data;
  FFlag := @Flag;
end;

procedure TMessagePassingWriterThread.Execute;
begin
  atomic_store(FData^, 42, mo_relaxed);
  atomic_store(FFlag^, 1, mo_release);
end;

constructor TMessagePassingReaderThread.CreateShared(var Data: Int32; var Flag: Int32; var R1: Int32; var R2: Int32);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FData := @Data;
  FFlag := @Flag;
  FR1 := @R1;
  FR2 := @R2;
end;

procedure TMessagePassingReaderThread.Execute;
begin
  FR1^ := atomic_load(FFlag^, mo_acquire);
  if FR1^ = 1 then
    FR2^ := atomic_load(FData^, mo_relaxed);
end;

procedure TTestCase_Concurrent.Test_concurrent_fetch_add_32;
const
  NThreads = 4;
  DefaultNPer = 5000;
var
  i: Integer;
  counter: Int32;
  NPer: Integer;
  th: array of TInc32Thread = nil;
begin
  NPer := ConcurrentNPer(DefaultNPer);
  counter := 0;
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TInc32Thread.CreateShared(counter, NPer);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  AssertEquals(NThreads*NPer, counter);
end;

procedure TTestCase_Concurrent.Test_concurrent_bit_or_32;
const NThreads = 8;
var i: Integer; bits: Int32; th: array of TOr32Thread = nil; mask: Int32;
begin
  bits := 0;
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TOr32Thread.CreateShared(bits, i);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  mask := (1 shl NThreads) - 1;
  AssertEquals(mask, bits and mask);
end;

procedure TTestCase_Concurrent.Test_concurrent_tagged_ptr_increment_tag;
const
  NThreads = 4;
  DefaultNPer = 2000;
var
  i, total: Integer;
  NPer: Integer;
  tp, tmp: atomic_tagged_ptr_t;
  th: array of TTaggedIncThread = nil;
  expected: UInt32;
begin
  NPer := ConcurrentNPer(DefaultNPer);
  tp := atomic_tagged_ptr(nil, 0);
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TTaggedIncThread.CreateShared(tp, NPer);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  // 计算期望的 tag（用相同 next 规则模拟 N 次递增）
  total := NThreads * NPer;
  tmp := atomic_tagged_ptr(nil, 0);
  for i := 1 to total do
    tmp := atomic_tagged_ptr(atomic_tagged_ptr_get_ptr(tmp), atomic_tagged_ptr_next(tmp));
  expected := atomic_tagged_ptr_get_tag(tmp);
  AssertEquals(Integer(expected), Integer(atomic_tagged_ptr_get_tag(tp)));
end;



// 内存序对照与桥接余缺
procedure TTestCase_Concurrent.Test_seq_cst_total_order_three_threads;
var a, b, c: Int32; t1, t2, t3: TThread;
begin
  a := 0; b := 0; c := 0;

  t1 := TAtomicStore32Thread.CreateShared(a, 1, mo_seq_cst);
  t2 := TWaitUntilEqualsThenStore32Thread.CreateShared(a, 1, b, 1, mo_seq_cst, 100000);
  t3 := TWaitUntilEqualsThenStore32Thread.CreateShared(b, 1, c, 1, mo_seq_cst, 100000);

  t1.Start; t2.Start; t3.Start;
  t1.WaitFor; t2.WaitFor; t3.WaitFor;
  t1.Free; t2.Free; t3.Free;

  AssertEquals(1, c);
end;

procedure TTestCase_Global.Test_ptruint_pointer_fetch_smoke;
var pu, ru: PtrUInt; pp, rp: Pointer;
begin
  // PtrUInt fetch_and/or/xor
  pu := PtrUInt($FF00); ru := atomic_fetch_and_ptr(pu, PtrUInt($0F0F)); AssertEquals(PtrUInt($FF00), ru); AssertEquals(PtrUInt($0F00), pu);
  ru := atomic_fetch_or_ptr(pu, PtrUInt($00F0)); AssertEquals(PtrUInt($0F00), ru); AssertEquals(PtrUInt($0FF0), pu);
  ru := atomic_fetch_xor_ptr(pu, PtrUInt($00FF)); AssertEquals(PtrUInt($0FF0), ru); AssertEquals(PtrUInt($0F0F), pu);
  // Pointer fetch_and/or/xor 通过整数桥接（不关心位义，只测路径）
  pp := Pointer(PtrUInt($FF00)); rp := atomic_fetch_and(pp, Pointer(PtrUInt($0F0F))); AssertEquals(PtrUInt($FF00), PtrUInt(rp)); AssertEquals(PtrUInt($0F00), PtrUInt(pp));
  rp := atomic_fetch_or(pp, Pointer(PtrUInt($00F0))); AssertEquals(PtrUInt($0F00), PtrUInt(rp)); AssertEquals(PtrUInt($0FF0), PtrUInt(pp));
  rp := atomic_fetch_xor(pp, Pointer(PtrUInt($00FF))); AssertEquals(PtrUInt($0FF0), PtrUInt(rp)); AssertEquals(PtrUInt($0F0F), PtrUInt(pp));
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_uint64_add_sub_fetch_paths;
var u, r: UInt64;
begin
  u := 1; r := atomic_fetch_add_64(u, 2); AssertEquals(QWord(1), QWord(r)); AssertEquals(QWord(3), QWord(u));
  r := atomic_fetch_sub_64(u, 1); AssertEquals(QWord(3), QWord(r)); AssertEquals(QWord(2), QWord(u));
end;

{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure TTestCase_Global.Test_uint64_bitwise_boundary_extremes;
var u, r: UInt64;
begin
  // All 1s -> All 0s via AND
  u := QWord($FFFFFFFFFFFFFFFF); r := atomic_fetch_and_64(u, QWord(0));
  AssertEquals(QWord($FFFFFFFFFFFFFFFF), QWord(r)); AssertEquals(QWord(0), QWord(u));

  // All 0s -> All 1s via OR
  u := QWord(0); r := atomic_fetch_or_64(u, QWord($FFFFFFFFFFFFFFFF));
  AssertEquals(QWord(0), QWord(r)); AssertEquals(QWord($FFFFFFFFFFFFFFFF), QWord(u));

  // All 1s -> All 0s via XOR
  u := QWord($FFFFFFFFFFFFFFFF); r := atomic_fetch_xor_64(u, QWord($FFFFFFFFFFFFFFFF));
  AssertEquals(QWord($FFFFFFFFFFFFFFFF), QWord(r)); AssertEquals(QWord(0), QWord(u));

  // Sign bit flip: 0x8000... <-> 0x7FFF...
  u := QWord($8000000000000000); r := atomic_fetch_xor_64(u, QWord($FFFFFFFFFFFFFFFF));
  AssertEquals(QWord($8000000000000000), QWord(r)); AssertEquals(QWord($7FFFFFFFFFFFFFFF), QWord(u));

  // High/Low boundary: High(Int64) AND with Low mask
  u := QWord($7FFFFFFFFFFFFFFF); r := atomic_fetch_and_64(u, QWord($00000000FFFFFFFF));
  AssertEquals(QWord($7FFFFFFFFFFFFFFF), QWord(r)); AssertEquals(QWord($00000000FFFFFFFF), QWord(u));
end;
{$ENDIF}

procedure TTestCase_Global.Test_compare_exchange_expected_writeback_consistency;
var
  pi: PtrInt; exp_pi: PtrInt;
  pu: PtrUInt; exp_pu: PtrUInt;
  pp: Pointer; exp_pp: Pointer;
  success: Boolean;
begin
  // PtrInt: Success -> Fail -> Success sequence, check expected writeback
  pi := 100; exp_pi := 100; success := atomic_compare_exchange_strong(pi, exp_pi, 200);
  AssertTrue(success); AssertEquals(100, exp_pi); AssertEquals(200, pi);

  exp_pi := 999; success := atomic_compare_exchange_strong(pi, exp_pi, 300); // should fail
  AssertFalse(success); AssertEquals(200, exp_pi); AssertEquals(200, pi); // expected written back

  exp_pi := 200; success := atomic_compare_exchange_strong(pi, exp_pi, 400);
  AssertTrue(success); AssertEquals(200, exp_pi); AssertEquals(400, pi);

  // PtrUInt: similar sequence
  pu := PtrUInt(500); exp_pu := PtrUInt(500); success := atomic_compare_exchange_strong(pu, exp_pu, PtrUInt(600));
  AssertTrue(success); AssertEquals(PtrUInt(500), exp_pu); AssertEquals(PtrUInt(600), pu);

  exp_pu := PtrUInt(777); success := atomic_compare_exchange_strong(pu, exp_pu, PtrUInt(700));
  AssertFalse(success); AssertEquals(PtrUInt(600), exp_pu); AssertEquals(PtrUInt(600), pu);

  // Pointer: cast through PtrUInt for comparison
  pp := Pointer(PtrUInt(1000)); exp_pp := Pointer(PtrUInt(1000));
  success := atomic_compare_exchange_strong(pp, exp_pp, Pointer(PtrUInt(2000)));
  AssertTrue(success); AssertEquals(PtrUInt(1000), PtrUInt(exp_pp)); AssertEquals(PtrUInt(2000), PtrUInt(pp));

  exp_pp := Pointer(PtrUInt(3333)); success := atomic_compare_exchange_strong(pp, exp_pp, Pointer(PtrUInt(4000)));
  AssertFalse(success); AssertEquals(PtrUInt(2000), PtrUInt(exp_pp)); AssertEquals(PtrUInt(2000), PtrUInt(pp));
end;

procedure TTestCase_Global.Test_pointer_fetch_add_negative_boundary;
var p, r: Pointer; offset: PtrInt;
begin
  // Start at a "high" address, subtract to approach zero (but not cross)
  p := Pointer(PtrUInt(10000)); offset := -5000;
  r := atomic_fetch_add(p, offset);
  AssertEquals(PtrUInt(10000), PtrUInt(r)); AssertEquals(PtrUInt(5000), PtrUInt(p));

  // Subtract more to approach zero boundary
  offset := -4999;
  r := atomic_fetch_add(p, offset);
  AssertEquals(PtrUInt(5000), PtrUInt(r)); AssertEquals(PtrUInt(1), PtrUInt(p));

  // Add back to verify bidirectional
  offset := 999;
  r := atomic_fetch_add(p, offset);
  AssertEquals(PtrUInt(1), PtrUInt(r)); AssertEquals(PtrUInt(1000), PtrUInt(p));

  // Test pointer subtraction variant (fetch_sub)
  r := atomic_fetch_sub(p, PtrInt(500));
  AssertEquals(PtrUInt(1000), PtrUInt(r)); AssertEquals(PtrUInt(500), PtrUInt(p));
end;

// 内存序对照与桥接余缺

//┌────────────────────────────────────────────────────────────────────────────┐
//│              Phase 6: Litmus 测试 - 内存序正确性验证                        │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Litmus Test: Message Passing (MP)
// 验证 release/acquire 同步：如果 reader 看到 flag=1，则必须看到 data=42
// 禁止结果: r1=1, r2=0 (看到 flag 但没看到 data)
procedure TTestCase_Concurrent.Test_litmus_message_passing;
const
  DefaultNIterations = 100;  // 默认保持较快
var
  NIterations: Integer;
  data, flag: Int32;
  r1, r2: Int32;
  badCount: Integer;
  iter: Integer;
  writer, reader: TThread;
begin
  NIterations := LitmusIters(DefaultNIterations);
  badCount := 0;

  for iter := 1 to NIterations do
  begin
    data := 0;
    flag := 0;
    r1 := 0;
    r2 := 0;

    writer := TMessagePassingWriterThread.CreateShared(data, flag);
    reader := TMessagePassingReaderThread.CreateShared(data, flag, r1, r2);

    writer.Start;
    reader.Start;
    writer.WaitFor;
    reader.WaitFor;
    writer.Free;
    reader.Free;

    // 如果看到 flag=1 但 data≠42，则内存序错误
    if (r1 = 1) and (r2 <> 42) then
      Inc(badCount);
  end;

  // 在正确的 release/acquire 实现下，badCount 必须为 0
  AssertEquals('MP litmus: release/acquire 同步失败', 0, badCount);
end;

// ✅ Litmus Test: Store Buffering (SB)
// 验证 seq_cst 全序：两个线程各自写后读对方，不能都读到旧值
// 禁止结果: r1=0, r2=0 (两个线程都没看到对方的写)
procedure TTestCase_Concurrent.Test_litmus_store_buffering;
const
  DefaultNIterations = 100;  // 默认保持较快
var
  NIterations: Integer;
  x, y: Int32;
  r1, r2: Int32;
  badCount: Integer;
  iter: Integer;
  t1, t2: TThread;
begin
  NIterations := LitmusIters(DefaultNIterations);
  badCount := 0;

  for iter := 1 to NIterations do
  begin
    x := 0;
    y := 0;
    r1 := -1;
    r2 := -1;

    t1 := TStoreThenLoad32Thread.CreateShared(x, 1, mo_seq_cst, y, mo_seq_cst, r1);
    t2 := TStoreThenLoad32Thread.CreateShared(y, 1, mo_seq_cst, x, mo_seq_cst, r2);

    t1.Start;
    t2.Start;
    t1.WaitFor;
    t2.WaitFor;
    t1.Free;
    t2.Free;

    // seq_cst 保证至少一个线程能看到对方的写
    // 禁止: r1=0 AND r2=0
    if (r1 = 0) and (r2 = 0) then
      Inc(badCount);
  end;

  // 在正确的 seq_cst 实现下，badCount 必须为 0
  AssertEquals('SB litmus: seq_cst 全序失败', 0, badCount);
end;

// ✅ Litmus Test: Load Buffering (LB)
// 验证 acquire/release 防止 load-load 重排
// 两个线程各自读后写，不能都读到对方的写
// 禁止结果: r1=1, r2=1 (两个线程都读到了对方还没写的值)
procedure TTestCase_Concurrent.Test_litmus_load_buffering;
const
  DefaultNIterations = 100;  // 默认保持较快
var
  NIterations: Integer;
  x, y: Int32;
  r1, r2: Int32;
  badCount: Integer;
  iter: Integer;
  t1, t2: TThread;
begin
  NIterations := LitmusIters(DefaultNIterations);
  badCount := 0;

  for iter := 1 to NIterations do
  begin
    x := 0;
    y := 0;
    r1 := -1;
    r2 := -1;

    t1 := TLoadThenStore32Thread.CreateShared(x, mo_acquire, r1, y, 1, mo_release);
    t2 := TLoadThenStore32Thread.CreateShared(y, mo_acquire, r2, x, 1, mo_release);

    t1.Start;
    t2.Start;
    t1.WaitFor;
    t2.WaitFor;
    t1.Free;
    t2.Free;

    // 在因果一致性下，不可能两个线程都读到对方的写
    // 禁止: r1=1 AND r2=1
    if (r1 = 1) and (r2 = 1) then
      Inc(badCount);
  end;

  // 在正确实现下，badCount 必须为 0
  AssertEquals('LB litmus: load-load 重排检测', 0, badCount);
end;

// ✅ Litmus Test: Independent Reads of Independent Writes (IRIW)
// 验证 seq_cst 的全局观测一致性
// 4 个线程：2 个写者，2 个读者
// 两个读者必须以相同顺序观测到两个写者的写入
procedure TTestCase_Concurrent.Test_litmus_independent_reads;
const
  DefaultNIterations = 50;  // 默认保持较快（4线程开销大）
var
  NIterations: Integer;
  x, y: Int32;
  r1, r2, r3, r4: Int32;
  badCount: Integer;
  iter: Integer;
  w1, w2, reader1, reader2: TThread;
begin
  NIterations := LitmusIriwIters(DefaultNIterations);
  badCount := 0;

  for iter := 1 to NIterations do
  begin
    x := 0;
    y := 0;
    r1 := -1; r2 := -1; r3 := -1; r4 := -1;

    // Writer 1: 写 x=1
    w1 := TAtomicStore32Thread.CreateShared(x, 1, mo_seq_cst);

    // Writer 2: 写 y=1
    w2 := TAtomicStore32Thread.CreateShared(y, 1, mo_seq_cst);

    // Reader 1: 先读 x，再读 y
    reader1 := TLoadPair32Thread.CreateShared(x, y, mo_seq_cst, r1, r2);

    // Reader 2: 先读 y，再读 x
    reader2 := TLoadPair32Thread.CreateShared(y, x, mo_seq_cst, r3, r4);

    w1.Start; w2.Start; reader1.Start; reader2.Start;
    w1.WaitFor; w2.WaitFor; reader1.WaitFor; reader2.WaitFor;
    w1.Free; w2.Free; reader1.Free; reader2.Free;

    // seq_cst 保证全局一致的观测顺序
    // 禁止: reader1 看到 x=1,y=0 (x 先于 y) 同时 reader2 看到 y=1,x=0 (y 先于 x)
    // 即: (r1=1, r2=0) AND (r3=1, r4=0) 是禁止的
    if (r1 = 1) and (r2 = 0) and (r3 = 1) and (r4 = 0) then
      Inc(badCount);
  end;

  // 在正确的 seq_cst 实现下，badCount 必须为 0
  AssertEquals('IRIW litmus: seq_cst 全局观测一致性失败', 0, badCount);
end;

{$POP}
end.
