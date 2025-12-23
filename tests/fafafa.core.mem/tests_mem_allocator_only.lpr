{$CODEPAGE UTF8}
program tests_mem_allocator_only;

{$mode objfpc}{$H+}

uses
  SysUtils, StrUtils, Classes,
  consoletestrunner,
  test_aligned,
  test_fixedpool,
  test_stackpool,
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

