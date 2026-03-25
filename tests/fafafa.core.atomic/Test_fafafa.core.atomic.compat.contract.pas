unit Test_fafafa.core.atomic.compat.contract;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic,
  fafafa.core.atomic.compat;

procedure RegisterAtomicCompatContractTests;

implementation

type
  TTestCase_AtomicCompatContract = class(TTestCase)
  published
    procedure Test_api_compat_compile_contract;
    procedure Test_api_compat_runtime_smoke;
  end;

procedure TTestCase_AtomicCompatContract.Test_api_compat_compile_contract;
var
  p, expP, rP: Pointer;
  tp, expTp: atomic_tagged_ptr_t;
  tag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
  nextTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
  ok: Boolean;
begin
  // Pointer RMW/arith legacy overloads (intended to be compat-only in v3)
  p := nil;
  rP := atomic_fetch_add(p, Pointer(PtrUInt(8)));
  rP := atomic_fetch_sub(p, Pointer(PtrUInt(8)));
  rP := atomic_fetch_and(p, Pointer(PtrUInt(1)));
  rP := atomic_fetch_or(p, Pointer(PtrUInt(1)));
  rP := atomic_fetch_xor(p, Pointer(PtrUInt(1)));
  rP := atomic_increment(p);
  rP := atomic_decrement(p);

  // Tagged pointer C11-like naming legacy wrappers (compat-only in v3)
  tag := 0;
  nextTag := 1;
  tp := make_atomic_tagged_ptr_t(nil, nextTag);
  tp := atomic_load_atomic_tagged_ptr_t(tp, mo_acquire);
  atomic_store_atomic_tagged_ptr_t(tp, tp, mo_release);

  expTp := tp;
  ok := atomic_compare_exchange_strong_atomic_tagged_ptr_t(tp, expTp, tp);

  // Pointer compat load/store + CAS helper
  expP := rP;
  rP := atomic_load_ptr(p, mo_acquire);
  atomic_store_ptr(p, rP, mo_release);
  ok := ok or atomic_compare_exchange_strong_ptr(p, expP, rP);

  // silence unused warnings
  if ok and (p <> nil) then
    p := p;
end;

procedure TTestCase_AtomicCompatContract.Test_api_compat_runtime_smoke;
var
  p: Pointer;
  oldP: Pointer;
  expP: Pointer;
  tagged: atomic_tagged_ptr_t;
  loaded: atomic_tagged_ptr_t;
  expectedTagged: atomic_tagged_ptr_t;
  ok: Boolean;
begin
  p := Pointer(PtrUInt(16));

  oldP := atomic_fetch_add(p, Pointer(PtrUInt(8)));
  CheckEquals(PtrUInt(16), PtrUInt(oldP));
  CheckEquals(PtrUInt(24), PtrUInt(p));

  oldP := atomic_fetch_sub(p, Pointer(PtrUInt(4)));
  CheckEquals(PtrUInt(24), PtrUInt(oldP));
  CheckEquals(PtrUInt(20), PtrUInt(p));

  atomic_store_ptr(p, Pointer(PtrUInt(64)), mo_release);
  CheckEquals(PtrUInt(64), PtrUInt(atomic_load_ptr(p, mo_acquire)));

  expP := Pointer(PtrUInt(64));
  ok := atomic_compare_exchange_strong_ptr(p, expP, Pointer(PtrUInt(96)));
  CheckTrue(ok, 'compat pointer CAS should succeed');
  CheckEquals(PtrUInt(96), PtrUInt(p));

  tagged := make_atomic_tagged_ptr_t(Pointer(PtrUInt(128)), 1);
  loaded := atomic_load_atomic_tagged_ptr_t(tagged, mo_acquire);
  CheckEquals(PtrUInt(128), PtrUInt(atomic_tagged_ptr_get_ptr(loaded)));
  CheckEquals(1, atomic_tagged_ptr_get_tag(loaded));

  expectedTagged := loaded;
  ok := atomic_compare_exchange_strong_atomic_tagged_ptr_t(
    tagged,
    expectedTagged,
    make_atomic_tagged_ptr_t(Pointer(PtrUInt(256)), 2)
  );
  CheckTrue(ok, 'compat tagged CAS should succeed');
  CheckEquals(PtrUInt(256), PtrUInt(atomic_tagged_ptr_get_ptr(tagged)));
  CheckEquals(2, atomic_tagged_ptr_get_tag(tagged));
end;

procedure RegisterAtomicCompatContractTests;
begin
  RegisterTest('fafafa.core.atomic.compat.contract', TTestCase_AtomicCompatContract);
end;

end.
