{$CODEPAGE UTF8}
program tests_mem;

{$mode objfpc}{$H+}

uses
  SysUtils, StrUtils, Classes,
  consoletestrunner,
  Test_fafafa_core_mem,
  test_mem_utils,
  test_mem_allocator,
  test_memPool_edgecases,
  test_stackPool_edgecases,
  test_interfaces,
  test_stats,
  test_aligned,
  test_mimalloc_smoke,
  test_objectPool,
  test_objectPool_typed;

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
