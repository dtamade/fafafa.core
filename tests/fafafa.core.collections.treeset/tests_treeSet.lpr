{$CODEPAGE UTF8}
program tests_treeSet;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  consoletestrunner,
  Test_TRBTreeSet_Complete;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.collections.treeSet Tests';
  Application.Run;
  Application.Free;
end.

