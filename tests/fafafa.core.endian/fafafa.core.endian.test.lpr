{$CODEPAGE UTF8}
program fafafa_core_endian_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.endian.testcase;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var
  LRunner: TTestRunner;
begin
  WriteLn('fafafa.core.endian unit tests');
  WriteLn('=============================');
  LRunner := TTestRunner.Create(nil);
  try
    LRunner.Initialize;
    LRunner.Run;
  finally
    LRunner.Free;
  end;
  Terminate;
end;

var
  LApp: TTestApp;
begin
  LApp := TTestApp.Create(nil);
  LApp.Title := 'fafafa.core.endian Tests';
  LApp.Run;
  LApp.Free;
end.
