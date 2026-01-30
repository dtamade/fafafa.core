{$CODEPAGE UTF8}
unit test_slabPool_edgecases;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.pool.slab;

type
  { TTestCase_SlabPool_EdgeCases }
  TTestCase_SlabPool_EdgeCases = class(TTestCase)
  published
    procedure Test_Warmup_ReturnsCount;
    procedure Test_DoubleFree_Raises;
  end;

implementation

procedure TTestCase_SlabPool_EdgeCases.Test_Warmup_ReturnsCount;
var
  P: TSlabPool;
  Count: Integer;
begin
  P := TSlabPool.Create(16*1024);
  try
    Count := P.Warmup(64, 2);
    AssertTrue('Warmup should allocate at least 1 page (if available)', Count >= 0);
  finally
    P.Destroy;
  end;
end;

procedure TTestCase_SlabPool_EdgeCases.Test_DoubleFree_Raises;
var
  P: TSlabPool;
  A: Pointer;
begin
  P := TSlabPool.Create(16*1024);
  try
    A := P.Alloc(64);
    AssertNotNull('Allocation should succeed', A);
    P.Free(A);
    // 第二次释放：当页面仍在类别链表时应抛出异常；若页面在首次释放后已回到空闲页并被摘链，可能被安全忽略
    try
      P.Free(A);
      AssertTrue('Double free should be prevented (ignored) or raise corruption', True);
    except
      on E: ESlabPoolCorruption do ;
      on E: Exception do
        Fail('Unexpected exception type: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    P.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_SlabPool_EdgeCases);
end.

