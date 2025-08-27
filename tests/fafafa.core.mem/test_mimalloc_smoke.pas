{$CODEPAGE UTF8}
unit test_mimalloc_smoke;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator;

type
  TTestCase_Mimalloc_Smoke = class(TTestCase)
  published
    procedure Test_GetMimallocAllocator_Smoke;
  end;

implementation

procedure TTestCase_Mimalloc_Smoke.Test_GetMimallocAllocator_Smoke;
var
  LAlloc: IAllocator;
  P: Pointer;
begin
  try
    LAlloc := GetMimallocAllocator;
  except
    on E: Exception do
      begin
        // 若动态库不可用，返回失败不应导致整个测试套件失败，这里只做记录
        Fail('GetMimallocAllocator raised: ' + E.ClassName + ': ' + E.Message);
        Exit;
      end;
  end;

  // 基本 smoke：分配/释放
  P := LAlloc.AllocMem(256);
  AssertNotNull('AllocMem(256) should return non-nil', P);
  LAlloc.FreeMem(P);
end;

initialization
  RegisterTest(TTestCase_Mimalloc_Smoke);

end.

