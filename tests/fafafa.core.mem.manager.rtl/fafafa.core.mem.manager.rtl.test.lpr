{$CODEPAGE UTF8}
program fafafa_core_mem_manager_rtl_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, StrUtils, Classes,
  consoletestrunner,
  test_rtl_manager_allocator;

var
  Application: TTestRunner;

begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.mem.manager.rtl 测试';
  Application.Run;
  Application.Free;
end.

