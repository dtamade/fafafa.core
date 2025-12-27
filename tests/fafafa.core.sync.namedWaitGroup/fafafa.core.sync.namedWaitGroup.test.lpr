program fafafa_core_sync_namedWaitGroup_test;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.sync.namedWaitGroup.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.namedWaitGroup Test Suite';
  Application.Run;
  Application.Free;
end.
