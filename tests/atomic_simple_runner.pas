program atomic_simple_runner;

{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.atomic;

procedure AssertTrue(const Msg: string; Cond: Boolean);
begin
  if not Cond then begin
    Writeln('FAIL: ', Msg);
    Halt(1);
  end;
end;

procedure AssertEqI32(const Msg: string; Exp, Act: Int32);
begin
  if Exp <> Act then begin
    Writeln('FAIL: ', Msg, ' exp=', Exp, ' act=', Act);
    Halt(1);
  end;
end;

procedure AssertEqI64(const Msg: string; Exp, Act: Int64);
begin
  if Exp <> Act then begin
    Writeln('FAIL: ', Msg, ' exp=', Exp, ' act=', Act);
    Halt(1);
  end;
end;

function TagOf(const tp: tagged_ptr): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
  Result := get_tag(tp);
end;

var
  i32, r32: Int32;
  i64, r64: Int64;
  p, oldp: Pointer;
  flag: atomic_flag;
  tp, prev, exp, des: tagged_ptr;
  ok: Boolean;
begin
  // bitwise ops 32
  i32 := $0F0F0F0F;
  r32 := atomic_fetch_and(i32, $00F0F0F0, memory_order_seq_cst);
  AssertEqI32('fetch_and32.ret', $0F0F0F0F, r32);
  AssertEqI32('fetch_and32.new', 0, i32);
  r32 := atomic_fetch_or(i32, $000000F0, memory_order_seq_cst);
  AssertEqI32('fetch_or32.ret', 0, r32);
  AssertEqI32('fetch_or32.new', $000000F0, i32);
  r32 := atomic_fetch_xor(i32, $0000000F, memory_order_seq_cst);
  AssertEqI32('fetch_xor32.ret', $000000F0, r32);
  AssertEqI32('fetch_xor32.new', $000000FF, i32);

  // bitwise ops 64
  i64 := $00FF00FF00FF00FF;
  r64 := atomic_fetch_and_64(i64, $0F0F0F0F0F0F0F0F, memory_order_seq_cst);
  AssertEqI64('fetch_and64.ret', Int64($00FF00FF00FF00FF), r64);
  AssertEqI64('fetch_and64.new', Int64($000F000F000F000F), i64);
  r64 := atomic_fetch_or_64(i64, $F0, memory_order_seq_cst);
  AssertEqI64('fetch_or64.ret', Int64($000F000F000F000F), r64);
  AssertEqI64('fetch_or64.new', Int64($000F000F000F00FF), i64);
  r64 := atomic_fetch_xor_64(i64, $0F, memory_order_seq_cst);
  AssertEqI64('fetch_xor64.ret', Int64($000F000F000F00FF), r64);
  AssertEqI64('fetch_xor64.new', Int64($000F000F000F00F0), i64);

  // pointer add/sub bytes
  p := Pointer(PtrUInt(1000));
  oldp := atomic_fetch_add_ptr_bytes(p, 16, memory_order_seq_cst);
  AssertTrue('fetch_add_ptr_bytes.ret', PtrUInt(oldp) = 1000);
  AssertTrue('fetch_add_ptr_bytes.new', PtrUInt(p) = 1016);
  oldp := atomic_fetch_sub_ptr_bytes(p, 8, memory_order_seq_cst);
  AssertTrue('fetch_sub_ptr_bytes.ret', PtrUInt(oldp) = 1016);
  AssertTrue('fetch_sub_ptr_bytes.new', PtrUInt(p) = 1008);

  // atomic_flag
  flag.v := 0;
  AssertTrue('flag first set', not atomic_flag_test_and_set(flag, memory_order_seq_cst));
  AssertTrue('flag second set', atomic_flag_test_and_set(flag, memory_order_seq_cst));
  atomic_flag_clear(flag, memory_order_seq_cst);
  AssertTrue('flag after clear', not atomic_flag_test_and_set(flag, memory_order_seq_cst));

  // is_lock_free
  AssertTrue('is_lock_free_32', atomic_is_lock_free_32);
  {$IFDEF CPU64} AssertTrue('is_lock_free_64', atomic_is_lock_free_64); {$ENDIF}
  AssertTrue('is_lock_free_ptr', atomic_is_lock_free_ptr);

  // tagged_ptr CAS/exchange
  tp := make_tagged_ptr(nil, 1);
  exp := tp; des := make_tagged_ptr(nil, 2);
  ok := atomic_compare_exchange_weak_tagged_ptr(tp, exp, des, memory_order_seq_cst);
  AssertTrue('tagged_ptr weak cas', ok);
  AssertTrue('tagged_ptr tag after cas', TagOf(tp) = 2);
  prev := atomic_exchange_tagged_ptr(tp, make_tagged_ptr(nil, 3), memory_order_seq_cst);
  AssertTrue('tagged_ptr exchange prev', TagOf(prev) = 2);
  AssertTrue('tagged_ptr exchange new', TagOf(tp) = 3);

  Writeln('atomic_simple_runner: OK');
end.

