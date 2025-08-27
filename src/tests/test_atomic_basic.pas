unit test_atomic_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.atomic;

procedure RegisterAtomicTests;

implementation

procedure Test_Bitwise_Fetch32;
var i, r: Int32;
begin
  i := $0F0F0F0F;
  r := atomic_fetch_and(i, $00F0F0F0, memory_order_seq_cst);
  AssertEquals($0F0F0F0F, r);
  AssertEquals($000F0000 + $00000F00, i); // (0F0F0F0F & 00F0F0F0) = 000F0F00

  r := atomic_fetch_or(i, $000000F0, memory_order_seq_cst);
  AssertEquals($000F0F00, r);
  AssertEquals($000F0FF0, i);

  r := atomic_fetch_xor(i, $0000000F, memory_order_seq_cst);
  AssertEquals($000F0FF0, r);
  AssertEquals($000F0FFF, i);
end;

procedure Test_Bitwise_Fetch64;
var i, r: Int64;
begin
  i := $00FF00FF00FF00FF;
  r := atomic_fetch_and_64(i, $0F0F0F0F0F0F0F0F, memory_order_seq_cst);
  AssertEquals(QWord($00FF00FF00FF00FF), QWord(r));
  AssertEquals(QWord($000F000F000F000F), QWord(i));

  r := atomic_fetch_or_64(i, $F0, memory_order_seq_cst);
  AssertEquals(QWord($000F000F000F000F), QWord(r));
  AssertEquals(QWord($000F000F000F00FF), QWord(i));

  r := atomic_fetch_xor_64(i, $0F, memory_order_seq_cst);
  AssertEquals(QWord($000F000F000F00FF), QWord(r));
  AssertEquals(QWord($000F000F000F00F0), QWord(i));
end;

procedure Test_Pointer_Bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1000));
  oldp := atomic_fetch_add_ptr_bytes(p, 16, memory_order_seq_cst);
  AssertTrue(PtrUInt(oldp) = 1000);
  AssertTrue(PtrUInt(p) = 1016);
  oldp := atomic_fetch_sub_ptr_bytes(p, 8, memory_order_seq_cst);
  AssertTrue(PtrUInt(oldp) = 1016);
  AssertTrue(PtrUInt(p) = 1008);
end;

procedure Test_Atomic_Flag;
var f: atomic_flag;
begin
  f.v := 0;
  AssertFalse(atomic_flag_test_and_set(f, memory_order_seq_cst));
  AssertTrue(atomic_flag_test_and_set(f, memory_order_seq_cst));
  atomic_flag_clear(f, memory_order_seq_cst);
  AssertFalse(atomic_flag_test_and_set(f, memory_order_seq_cst));
end;

procedure Test_Is_Lock_Free;
begin
  AssertTrue(atomic_is_lock_free_32);
  {$IFDEF CPU64}
  AssertTrue(atomic_is_lock_free_64);
  {$ENDIF}
  AssertTrue(atomic_is_lock_free_ptr);
end;

procedure Test_Tagged_Ptr;
var tp, prev, exp, des: tagged_ptr;
begin
  tp := make_tagged_ptr(nil, 1);
  exp := tp;
  des := make_tagged_ptr(nil, 2);
  AssertTrue(atomic_compare_exchange_weak_tagged_ptr(tp, exp, des, memory_order_seq_cst));
  AssertEquals(2, Ord(get_tag(tp)));
  prev := atomic_exchange_tagged_ptr(tp, make_tagged_ptr(nil, 3), memory_order_seq_cst);
  AssertEquals(2, Ord(get_tag(prev)));
  AssertEquals(3, Ord(get_tag(tp)));
end;

procedure RegisterAtomicTests;
begin
  RegisterTest('atomic-basic', @Test_Bitwise_Fetch32);
  RegisterTest('atomic-basic', @Test_Bitwise_Fetch64);
  RegisterTest('atomic-basic', @Test_Pointer_Bytes);
  RegisterTest('atomic-basic', @Test_Atomic_Flag);
  RegisterTest('atomic-basic', @Test_Is_Lock_Free);
  RegisterTest('atomic-basic', @Test_Tagged_Ptr);
end;

end.

