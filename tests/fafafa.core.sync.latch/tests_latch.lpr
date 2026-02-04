{$mode objfpc}{$H+}
program tests_latch;

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  fafafa.core.sync.latch.testcase;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'Latch Tests';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
