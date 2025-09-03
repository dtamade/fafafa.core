program fafafa.core.sync.recMutex.test.simple;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  Interfaces, Forms, GuiTestRunner, fpcunit, testregistry,
  fafafa.core.sync.recMutex.testcase.simple;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.
