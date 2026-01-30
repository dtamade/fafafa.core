{$CODEPAGE UTF8}
unit test_memPool_edgecases;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.memPool,
  fafafa.core.mem.allocator;

type
  { TTestCase_MemPool_EdgeCases }
  TTestCase_MemPool_EdgeCases = class(TTestCase)
  published
    procedure Test_Release_NilPointer_NoOp;
    procedure Test_DoubleFree_Raises;
    procedure Test_Release_InvalidPointer_Raises;
  end;

implementation

{ TTestCase_MemPool_EdgeCases }

procedure TTestCase_MemPool_EdgeCases.Test_Release_NilPointer_NoOp;
var
  LPool: TMemPool;
begin
  LPool := TMemPool.Create(16, 2);
  try
    LPool.ReleasePtr(nil);
    AssertEquals(0, LPool.AllocatedCount);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_MemPool_EdgeCases.Test_DoubleFree_Raises;
var
  LPool: TMemPool;
  P: Pointer;
begin
  LPool := TMemPool.Create(32, 2);
  try
    P := LPool.Alloc;
    AssertNotNull('Allocation should succeed', P);
    LPool.ReleasePtr(P); // first free OK
    try
      LPool.ReleasePtr(P); // second free should raise
      Fail('Expected EMemPoolDoubleFree to be raised on double free');
    except
      on E: EMemPoolDoubleFree do ;
      on E: Exception do
        Fail('Unexpected exception type: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_MemPool_EdgeCases.Test_Release_InvalidPointer_Raises;
var
  LPool: TMemPool;
  LInvalid: Pointer;
begin
  LPool := TMemPool.Create(64, 2);
  try
    // allocate a pointer outside of pool
    LInvalid := GetRtlAllocator.GetMem(8);
    try
      try
        LPool.ReleasePtr(LInvalid);
        Fail('Expected EMemPoolInvalidPointer to be raised for foreign pointer');
      except
        on E: EMemPoolInvalidPointer do ;
        on E: Exception do
          Fail('Unexpected exception type: ' + E.ClassName + ' - ' + E.Message);
      end;
    finally
      GetRtlAllocator.FreeMem(LInvalid);
    end;
  finally
    LPool.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_MemPool_EdgeCases);
end.

