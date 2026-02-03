{$mode objfpc}{$H+}
program tests_seqlock;

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  Test_fafafa_core_sync_seqlock;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'SeqLock Tests';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
