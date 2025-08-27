program test_atomic_smoke;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.atomic;

function PtrTag(tp: tagged_ptr): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
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
  if (r32 <> $0F0F0F0F) or (i32 <> ($0F0F0F0F and $00F0F0F0)) then begin
    Writeln('FAIL: fetch_and 32'); Halt(1);
  end;
  r32 := atomic_fetch_or(i32, $000000F0, memory_order_seq_cst);
  if (r32 <> ($0F0F0F0F and $00F0F0F0)) or (i32 <> (($0F0F0F0F and $00F0F0F0) or $000000F0)) then begin
    Writeln('FAIL: fetch_or 32'); Halt(1);
  end;
  r32 := atomic_fetch_xor(i32, $0000000F, memory_order_seq_cst);
  if (r32 <> (($0F0F0F0F and $00F0F0F0) or $000000F0)) or (i32 <> (((($0F0F0F0F and $00F0F0F0) or $000000F0)) xor $0000000F)) then begin
    Writeln('FAIL: fetch_xor 32'); Halt(1);
  end;

  // bitwise ops 64
  i64 := $00FF00FF00FF00FF;
  r64 := atomic_fetch_and_64(i64, $0F0F0F0F0F0F0F0F, memory_order_seq_cst);
  if (r64 <> $00FF00FF00FF00FF) or (i64 <> ($00FF00FF00FF00FF and $0F0F0F0F0F0F0F0F)) then begin
    Writeln('FAIL: fetch_and 64'); Halt(1);
  end;
  r64 := atomic_fetch_or_64(i64, $F0, memory_order_seq_cst);
  if (r64 <> ($00FF00FF00FF00FF and $0F0F0F0F0F0F0F0F)) or (i64 <> (($00FF00FF00FF00FF and $0F0F0F0F0F0F0F0F) or $F0)) then begin
    Writeln('FAIL: fetch_or 64'); Halt(1);
  end;
  r64 := atomic_fetch_xor_64(i64, $0F, memory_order_seq_cst);
  if (r64 <> (($00FF00FF00FF00FF and $0F0F0F0F0F0F0F0F) or $F0)) or (i64 <> (((($00FF00FF00FF00FF and $0F0F0F0F0F0F0F0F) or $F0)) xor $0F)) then begin
    Writeln('FAIL: fetch_xor 64'); Halt(1);
  end;

  // pointer add/sub bytes
  p := Pointer(PtrUInt(1000));
  oldp := atomic_fetch_add_ptr_bytes(p, 16, memory_order_seq_cst);
  if (PtrUInt(oldp) <> 1000) or (PtrUInt(p) <> 1016) then begin
    Writeln('FAIL: fetch_add_ptr_bytes'); Halt(1);
  end;
  oldp := atomic_fetch_sub_ptr_bytes(p, 8, memory_order_seq_cst);
  if (PtrUInt(oldp) <> 1016) or (PtrUInt(p) <> 1008) then begin
    Writeln('FAIL: fetch_sub_ptr_bytes'); Halt(1);
  end;

  // atomic_flag
  flag.v := 0;
  if atomic_flag_test_and_set(flag, memory_order_seq_cst) <> False then begin
    Writeln('FAIL: flag first set'); Halt(1);
  end;
  if atomic_flag_test_and_set(flag, memory_order_seq_cst) <> True then begin
    Writeln('FAIL: flag second set'); Halt(1);
  end;
  atomic_flag_clear(flag, memory_order_seq_cst);
  if atomic_flag_test_and_set(flag, memory_order_seq_cst) <> False then begin
    Writeln('FAIL: flag after clear'); Halt(1);
  end;

  // is_lock_free
  if not atomic_is_lock_free_32 then begin Writeln('FAIL: is_lock_free_32'); Halt(1); end;
  {$IFDEF CPU64}
  if not atomic_is_lock_free_64 then begin Writeln('FAIL: is_lock_free_64'); Halt(1); end;
  {$ENDIF}
  if not atomic_is_lock_free_ptr then begin Writeln('FAIL: is_lock_free_ptr'); Halt(1); end;

  // tagged_ptr CAS/exchange
  tp := make_tagged_ptr(nil, 1);
  exp := tp;
  des := make_tagged_ptr(nil, 2);
  ok := atomic_compare_exchange_weak_tagged_ptr(tp, exp, des, memory_order_seq_cst);
  if not ok then begin Writeln('FAIL: tagged_ptr weak cas'); Halt(1); end;
  if PtrTag(tp) <> 2 then begin Writeln('FAIL: tagged_ptr tag after cas'); Halt(1); end;
  prev := atomic_exchange_tagged_ptr(tp, make_tagged_ptr(nil, 3), memory_order_seq_cst);
  if PtrTag(prev) <> 2 then begin Writeln('FAIL: tagged_ptr exchange prev'); Halt(1); end;
  if PtrTag(tp) <> 3 then begin Writeln('FAIL: tagged_ptr exchange new'); Halt(1); end;

  Writeln('OK');
end.

