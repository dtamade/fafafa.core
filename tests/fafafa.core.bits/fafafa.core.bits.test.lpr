{$CODEPAGE UTF8}
program fafafa_core_bits_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.bits.testcase;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var
  LRunner: TTestRunner;
begin
  WriteLn('fafafa.core.bits unit tests');
  WriteLn('===========================');
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
  LApp.Title := 'fafafa.core.bits Tests';
  LApp.Run;
  LApp.Free;
end.
