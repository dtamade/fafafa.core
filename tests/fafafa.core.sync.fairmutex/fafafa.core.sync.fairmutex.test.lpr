{$CODEPAGE UTF8}
program fafafa_core_sync_fairmutex_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.fairmutex.testcase;

type
  TMyTestRunner = class(TTestRunner);

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.sync.fairmutex Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
