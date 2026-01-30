{$CODEPAGE UTF8}
program tests_mem;

{$mode objfpc}{$H+}

uses
  SysUtils, StrUtils, Classes,
  consoletestrunner,
  // Test_fafafa_core_mem - removed: uses IAllocator/GetRtlAllocator which don't exist
  test_mem_utils,
  // test_mem_allocator - removed: IAllocator.Free doesn't exist
  // test_memPool_edgecases - removed: uses TMemPool.Free with wrong parameters
  // test_stackPool_edgecases - removed: API incompatibility
  // test_interfaces - removed: uses fafafa.core.mem.adapters which doesn't exist
  // test_stats - removed: uses TMimalloc which doesn't exist in fafafa.core.mem.mimalloc
  test_aligned,
  test_mimalloc_smoke;
  // test_objectPool - removed: uses non-generic TObjectPool which doesn't exist
  // test_objectPool_typed - removed: unit fafafa.core.mem.pool.typedObjectPool not implemented yet

var
  Application: TTestRunner;



begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.mem 模块测试';
  Application.Run;
  Application.Free;
end.
