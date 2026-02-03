{$mode objfpc}{$H+}
program tests_scopedlock;

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  Test_fafafa_core_sync_scopedlock;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'ScopedLock Tests';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
