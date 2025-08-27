{$CODEPAGE UTF8}
program tests_orderedmap;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  consoletestrunner,
  Test_TRBTreeMap_Complete;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.collections.orderedmap Tests';
  Application.Run;
  Application.Free;
end.

