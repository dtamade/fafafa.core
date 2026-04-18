{$CODEPAGE UTF8}
program tests_mem_allocator_only;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  consoletestrunner,
  test_aligned,
  test_fixedpool,
  test_stackpool,
  test_blockpool,
  test_blockpool_batch,
  test_blockpool_growable,
  test_blockpool_sharded,
  test_arena_growable,
  test_memPool_edgecases,
  test_stackPool_edgecases,
  test_stats,
  test_interfaces,
  test_mimalloc_manager_optional_smoke;

var
  Application: TTestRunner;

begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.mem Allocator-only Tests';
  Application.Run;
  Application.Free;
end.

