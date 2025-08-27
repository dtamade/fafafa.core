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
    procedure Test_Free_NilPointer_Raises;
    procedure Test_DoubleFree_Raises;
    procedure Test_Free_InvalidPointer_Raises;
  end;

implementation

{ TTestCase_MemPool_EdgeCases }

procedure TTestCase_MemPool_EdgeCases.Test_Free_NilPointer_Raises;
var
  LPool: TMemPool;
begin
  LPool := TMemPool.Create(16, 2);
  try
    try
      LPool.Free(nil);
      Fail('Expected EMemPoolInvalidPointer to be raised for nil pointer');
    except
      on E: EMemPoolInvalidPointer do ;
      on E: Exception do
        Fail('Unexpected exception type: ' + E.ClassName + ' - ' + E.Message);
    end;
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
    LPool.Free(P); // first free OK
    try
      LPool.Free(P); // second free should raise
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

procedure TTestCase_MemPool_EdgeCases.Test_Free_InvalidPointer_Raises;
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
        LPool.Free(LInvalid);
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

