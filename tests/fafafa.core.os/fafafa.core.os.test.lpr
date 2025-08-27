program tests_os;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF WINDOWS} Windows, {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, testreport, consoletestrunner,
  fafafa.core.os,
  fafafa.core.os.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.os Tests';
  Application.Run;
  Application.Free;
end.

