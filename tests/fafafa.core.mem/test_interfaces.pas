{$CODEPAGE UTF8}
unit test_interfaces;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.interfaces,
  fafafa.core.mem.adapters,
  fafafa.core.mem.allocator;

type
  TTestCase_Interfaces = class(TTestCase)
  published
    procedure Test_MemPool_Adapter_Basic;
    procedure Test_StackPool_Adapter_Basic;
    procedure Test_Adapter_Create_With_Nil_Impl_Raises;
    procedure Test_MemPool_Adapter_Free_Nil_Raises;
  end;

implementation

procedure TTestCase_Interfaces.Test_MemPool_Adapter_Basic;
var
  LPool: TMemPool;
  LAdapter: IMemPool;
  LPtr: Pointer;
begin
  LPool := TMemPool.Create(16, 4, GetRtlAllocator);
  try
    LAdapter := TMemPoolAdapter.Create(LPool);
    LPtr := LAdapter.Alloc;
    AssertNotNull('Alloc returns pointer', LPtr);
    LAdapter.Free(LPtr);
    LAdapter.Reset;
    AssertEquals(0, LPool.AllocatedCount);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_Interfaces.Test_StackPool_Adapter_Basic;
var
  LPool: TStackPool;
  LAdapter: IStackPool;
  LPtr: Pointer;
begin
  LPool := TStackPool.Create(1024, GetRtlAllocator);
  try
    LAdapter := TStackPoolAdapter.Create(LPool);
    LPtr := LAdapter.Alloc(32);
    AssertNotNull('Alloc returns pointer', LPtr);
    LAdapter.Reset;
    AssertTrue('After reset is empty', LPool.IsEmpty);
  finally
    LPool.Free;
  end;
end;

procedure TTestCase_Interfaces.Test_Adapter_Create_With_Nil_Impl_Raises;
begin
  AssertException(Exception, procedure begin TMemPoolAdapter.Create(nil); end);
  AssertException(Exception, procedure begin TStackPoolAdapter.Create(nil); end);
end;

procedure TTestCase_Interfaces.Test_MemPool_Adapter_Free_Nil_Raises;
var
  LPool: TMemPool;
  LAdapter: IMemPool;
begin
  LPool := TMemPool.Create(16, 1, GetRtlAllocator);
  try
    LAdapter := TMemPoolAdapter.Create(LPool);
    AssertException(EMemPoolInvalidPointer, procedure begin LAdapter.Free(nil); end);
  finally
    LPool.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_Interfaces);

end.
