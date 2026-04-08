{$CODEPAGE UTF8}
program fafafa_core_mem_allocator_foundation_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  test_allocator_foundation_contract,
  test_allocator_foundation_runtime;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var
  LRunner: TTestRunner;
begin
  WriteLn('fafafa.core.mem.allocator.foundation tests');
  WriteLn('==========================================');
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
  LApp.Title := 'fafafa.core.mem.allocator.foundation Tests';
  LApp.Run;
  LApp.Free;
end.
