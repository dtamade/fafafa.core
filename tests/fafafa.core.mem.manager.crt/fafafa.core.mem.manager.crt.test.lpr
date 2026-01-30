{$CODEPAGE UTF8}
program fafafa_core_mem_manager_crt_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, StrUtils, Classes,
  consoletestrunner,
  test_crt_manager_allocator;

var
  Application: TTestRunner;

begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.mem.manager.crt 测试';
  Application.Run;
  Application.Free;
end.

