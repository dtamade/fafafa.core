program fafafa_core_sync_namedOnce_test;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.sync.namedOnce.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.namedOnce Test Suite';
  Application.Run;
  Application.Free;
end.
