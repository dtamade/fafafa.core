{$mode objfpc}{$H+}
program tests_waitgroup;

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  fafafa.core.sync.waitgroup.testcase;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'WaitGroup Tests';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
