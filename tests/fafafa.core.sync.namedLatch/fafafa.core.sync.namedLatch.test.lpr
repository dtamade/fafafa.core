program fafafa_core_sync_namedLatch_test;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  fafafa.core.sync.namedLatch.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.namedLatch Test Suite';
  Application.Run;
  Application.Free;
end.
