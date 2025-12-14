{$CODEPAGE UTF8}
program tests_node;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, fpcunit, testregistry,
  Test_fafafa_core_collections_node;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.
