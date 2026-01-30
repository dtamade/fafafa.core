unit test_lookpath_basic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_LookPath_Basic = class(TTestCase)
  published
    procedure Test_LookPath_Finds_Common_Exe;
  end;

implementation

procedure TTestCase_LookPath_Basic.Test_LookPath_Finds_Common_Exe;
var
  P: string;
begin
  {$IFDEF WINDOWS}
  P := LookPath('cmd');
  if P = '' then P := LookPath('cmd.exe');
  {$ELSE}
  P := LookPath('sh');
  {$ENDIF}
  CheckTrue(P <> '', 'LookPath should return a non-empty absolute path');
end;

initialization
  RegisterTest(TTestCase_LookPath_Basic);

end.

