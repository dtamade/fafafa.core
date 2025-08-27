{$CODEPAGE UTF8}
program tests_vecdeque;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  consoletestrunner,
  Test_fafafa_core_collections_vecdeque_clean;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.collections.vecdeque Tests';
  Application.Run;
  Application.Free;
end.
