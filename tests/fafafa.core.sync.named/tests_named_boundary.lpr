program tests_named_boundary;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.named.boundary.testcase;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.sync.named Boundary Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
