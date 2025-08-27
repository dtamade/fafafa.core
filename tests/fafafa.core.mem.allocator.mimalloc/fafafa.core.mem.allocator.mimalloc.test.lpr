{$CODEPAGE UTF8}
program fafafa_core_mem_allocator_mimalloc_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, StrUtils, Classes,
  consoletestrunner,
  test_mimalloc_allocator;

var
  Application: TTestRunner;

begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.mem.allocator.mimalloc 测试';
  Application.Run;
  Application.Free;
end.

