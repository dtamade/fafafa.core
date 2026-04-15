unit Test_fafafa.core.atomic.core.contract;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic.core;

procedure RegisterAtomicCoreContractTests;

implementation

type
  TTestCase_AtomicCoreContract = class(TTestCase)
  published
    procedure Test_api_core_compile_contract;
    procedure Test_tagged_ptr_runtime_smoke;
  end;

procedure TTestCase_AtomicCoreContract.Test_api_core_compile_contract;
var
  LPtr: Pointer;
  LTagged: atomic_tagged_ptr_t;
  LRoundTripPtr: Pointer;
  LTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
  LNextTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
  LOrder: memory_order_t;
begin
  LOrder := mo_seq_cst;

  cpu_pause;
  atomic_thread_fence(LOrder);
  atomic_signal_fence(mo_acquire);

  LPtr := Pointer(PtrUInt(64));
  LTag := 1;
  LTagged := atomic_tagged_ptr(LPtr, LTag);
  LRoundTripPtr := atomic_tagged_ptr_get_ptr(LTagged);
  LTag := atomic_tagged_ptr_get_tag(LTagged);
  LNextTag := atomic_tagged_ptr_next(LTagged);

  AssertTrue((LRoundTripPtr = LPtr) or (LNextTag >= LTag));
end;

procedure TTestCase_AtomicCoreContract.Test_tagged_ptr_runtime_smoke;
var
  LPtr: Pointer;
  LTagged: atomic_tagged_ptr_t;
  LMaxTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
  {$IF DEFINED(CPUX86_64)}
  LPtr := Pointer(PtrUInt($1234));
  LTagged := atomic_tagged_ptr(LPtr, 7);
  CheckEquals(PtrUInt(LPtr), PtrUInt(atomic_tagged_ptr_get_ptr(LTagged)));
  CheckEquals(7, atomic_tagged_ptr_get_tag(LTagged));
  CheckEquals(8, atomic_tagged_ptr_next(LTagged));

  LMaxTag := atomic_tagged_ptr_get_tag(atomic_tagged_ptr(nil, UInt16($FFFF)));
  LTagged := atomic_tagged_ptr(nil, LMaxTag);
  CheckEquals(1, atomic_tagged_ptr_next(LTagged));
  {$ELSE}
  LPtr := Pointer(PtrUInt(64));
  LTagged := atomic_tagged_ptr(LPtr, 1);
  CheckEquals(PtrUInt(LPtr), PtrUInt(atomic_tagged_ptr_get_ptr(LTagged)));
  CheckEquals(1, atomic_tagged_ptr_get_tag(LTagged));
  CheckEquals(2, atomic_tagged_ptr_next(LTagged));

  {$IFDEF CPU64}
  LMaxTag := atomic_tagged_ptr_get_tag(atomic_tagged_ptr(nil, UInt16(High(UInt16))));
  {$ELSE}
  LMaxTag := atomic_tagged_ptr_get_tag(atomic_tagged_ptr(nil, UInt32(High(UInt32))));
  {$ENDIF}
  LTagged := atomic_tagged_ptr(nil, LMaxTag);
  CheckEquals(1, atomic_tagged_ptr_next(LTagged));
  {$ENDIF}
end;

procedure RegisterAtomicCoreContractTests;
begin
  RegisterTest('fafafa.core.atomic.core.contract', TTestCase_AtomicCoreContract);
end;

end.
