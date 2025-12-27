program fafafa_core_sync_namedSharedCounter_test;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.sync.namedSharedCounter.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.namedSharedCounter Test Suite';
  Application.Run;
  Application.Free;
end.
