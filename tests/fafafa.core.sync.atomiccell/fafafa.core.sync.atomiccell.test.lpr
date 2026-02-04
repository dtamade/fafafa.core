{$CODEPAGE UTF8}
program fafafa_core_sync_atomiccell_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry, consoletestrunner,
  TestHelpers_Sync,
  fafafa.core.sync.atomiccell.testcase;

type
  TMyTestRunner = class(TTestRunner);

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.sync.atomiccell Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
